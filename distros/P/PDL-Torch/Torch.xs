#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pdl.h"
#include "pdlcore.h"

#include "torch_bridge.h"

static Core* PDL;
static SV*   CoreSV;

static int pdl_datatype_to_torch(int pdl_dt) {
    switch (pdl_dt) {
        case PDL_B:  return PDL_TORCH_UINT8;
        case PDL_SB: return PDL_TORCH_INT8;
        case PDL_S:  return PDL_TORCH_INT16;
        case PDL_L:  return PDL_TORCH_INT32;
        case PDL_LL: return PDL_TORCH_INT64;
        case PDL_F:  return PDL_TORCH_FLOAT32;
        case PDL_D:  return PDL_TORCH_FLOAT64;
        case PDL_CF: return PDL_TORCH_CFLOAT;
        case PDL_CD: return PDL_TORCH_CDOUBLE;
        default:     return -1;
    }
}

static int torch_dtype_to_pdl(int torch_dt) {
    switch (torch_dt) {
        case PDL_TORCH_UINT8:   return PDL_B;
        case PDL_TORCH_INT8:    return PDL_SB;
        case PDL_TORCH_INT16:   return PDL_S;
        case PDL_TORCH_INT32:   return PDL_L;
        case PDL_TORCH_INT64:   return PDL_LL;
        case PDL_TORCH_FLOAT32: return PDL_F;
        case PDL_TORCH_FLOAT64: return PDL_D;
        case PDL_TORCH_CFLOAT:  return PDL_CF;
        case PDL_TORCH_CDOUBLE: return PDL_CD;
        default:                return -1;
    }
}

static SV* bless_tensor(pTHX_ PdlTorchTensor* t) {
    if (!t) {
        croak("PDL::Torch error: %s", pdl_torch_last_error());
    }
    SV* sv = newSViv(PTR2IV(t));
    SV* ref = newRV_noinc(sv);
    sv_bless(ref, gv_stashpv("PDL::Torch::Tensor", GV_ADD));
    return ref;
}

static PdlTorchTensor* sv_to_tensor(pTHX_ SV* sv) {
    if (!sv_isobject(sv) || !sv_derived_from(sv, "PDL::Torch::Tensor")) {
        croak("Expected a PDL::Torch::Tensor object");
    }
    IV ptr = SvIV(SvRV(sv));
    if (!ptr) {
        croak("PDL::Torch::Tensor has already been destroyed");
    }
    return INT2PTR(PdlTorchTensor*, ptr);
}

MODULE = PDL::Torch    PACKAGE = PDL::Torch

PROTOTYPES: DISABLE

BOOT:
{
    CoreSV = get_sv("PDL::SHARE", FALSE);
    if (!CoreSV) {
        croak("PDL::Torch requires PDL::Core to be loaded first");
    }
    PDL = INT2PTR(Core*, SvIV(CoreSV));
    if (PDL->Version != PDL_CORE_VERSION) {
        croak("PDL::Torch needs to be recompiled against the newly installed PDL");
    }
}

int
cuda_available()
CODE:
    RETVAL = pdl_torch_cuda_is_available();
OUTPUT:
    RETVAL

SV*
_xs_pdl2tensor(SV* pdl_sv, const char* device)
CODE:
    pdl* p = PDL->SvPDLV(pdl_sv);
    PDL->make_physical(p);
    PDL->make_physdims(p);

    int torch_dt = pdl_datatype_to_torch(p->datatype);
    if (torch_dt < 0) {
        croak("Unsupported PDL datatype %d for PDL::Torch", p->datatype);
    }

    int ndims = (int)p->ndims;
    int64_t* dims = NULL;
    if (ndims > 0) {
        Newx(dims, ndims, int64_t);
        /* Reverse PDL column-major dims to Torch row-major dims */
        for (int i = 0; i < ndims; ++i) {
            dims[i] = (int64_t)p->dims[ndims - 1 - i];
        }
    }

    PdlTorchTensor* t = pdl_torch_from_buffer(p->data, torch_dt, dims, ndims, device);
    if (dims) Safefree(dims);

    RETVAL = bless_tensor(aTHX_ t);
OUTPUT:
    RETVAL

SV*
_xs_tensor2pdl(SV* tensor_sv)
CODE:
    PdlTorchTensor* t = sv_to_tensor(aTHX_ tensor_sv);
    int pdl_dt = torch_dtype_to_pdl(pdl_torch_dtype(t));
    if (pdl_dt < 0) {
        croak("Unsupported Torch dtype %d for PDL", pdl_torch_dtype(t));
    }

    int ndims = pdl_torch_ndims(t);
    pdl* p = PDL->pdlnew();
    p->datatype = pdl_dt;

    if (ndims > 0) {
        PDL_Indx* dims = NULL;
        Newx(dims, ndims, PDL_Indx);
        /* Reverse Torch row-major dims back to PDL column-major dims */
        for (int i = 0; i < ndims; ++i) {
            dims[i] = (PDL_Indx)pdl_torch_dim(t, ndims - 1 - i);
        }
        PDL->setdims(p, dims, ndims);
        Safefree(dims);
    } else {
        PDL->setdims(p, NULL, 0);
    }

    PDL->allocdata(p);
    size_t elem_size = PDL->howbig(pdl_dt);
    size_t total_bytes = (size_t)p->nvals * elem_size;
    if (!pdl_torch_to_cpu_buffer(t, p->data, total_bytes)) {
        croak("Failed to copy tensor to PDL: %s", pdl_torch_last_error());
    }

    SV* out = newSV(0);
    PDL->SetSV_PDL(out, p);
    RETVAL = out;
OUTPUT:
    RETVAL

MODULE = PDL::Torch    PACKAGE = PDL::Torch::Tensor

void
DESTROY(SV* self)
CODE:
    if (SvROK(self)) {
        SV* iv = SvRV(self);
        IV ptr = SvIV(iv);
        if (ptr) {
            pdl_torch_free(INT2PTR(PdlTorchTensor*, ptr));
            sv_setiv(iv, 0);
        }
    }

const char*
device(SV* self)
CODE:
    PdlTorchTensor* t = sv_to_tensor(aTHX_ self);
    RETVAL = pdl_torch_device(t);
OUTPUT:
    RETVAL

int
_xs_dtype(SV* self)
CODE:
    PdlTorchTensor* t = sv_to_tensor(aTHX_ self);
    RETVAL = pdl_torch_dtype(t);
OUTPUT:
    RETVAL

void
dims(SV* self)
PPCODE:
    PdlTorchTensor* t = sv_to_tensor(aTHX_ self);
    int ndims = pdl_torch_ndims(t);
    EXTEND(SP, ndims);
    for (int i = 0; i < ndims; ++i) {
        PUSHs(sv_2mortal(newSViv((IV)pdl_torch_dim(t, i))));
    }

SV*
to(SV* self, const char* device)
CODE:
    PdlTorchTensor* t = sv_to_tensor(aTHX_ self);
    RETVAL = bless_tensor(aTHX_ pdl_torch_to_device(t, device));
OUTPUT:
    RETVAL

SV*
_xs_add(SV* a_sv, SV* b_sv)
CODE:
    PdlTorchTensor* a = sv_to_tensor(aTHX_ a_sv);
    PdlTorchTensor* b = sv_to_tensor(aTHX_ b_sv);
    RETVAL = bless_tensor(aTHX_ pdl_torch_add(a, b));
OUTPUT:
    RETVAL

SV*
_xs_sub(SV* a_sv, SV* b_sv)
CODE:
    PdlTorchTensor* a = sv_to_tensor(aTHX_ a_sv);
    PdlTorchTensor* b = sv_to_tensor(aTHX_ b_sv);
    RETVAL = bless_tensor(aTHX_ pdl_torch_sub(a, b));
OUTPUT:
    RETVAL

SV*
_xs_mul(SV* a_sv, SV* b_sv)
CODE:
    PdlTorchTensor* a = sv_to_tensor(aTHX_ a_sv);
    PdlTorchTensor* b = sv_to_tensor(aTHX_ b_sv);
    RETVAL = bless_tensor(aTHX_ pdl_torch_mul(a, b));
OUTPUT:
    RETVAL

SV*
_xs_div(SV* a_sv, SV* b_sv)
CODE:
    PdlTorchTensor* a = sv_to_tensor(aTHX_ a_sv);
    PdlTorchTensor* b = sv_to_tensor(aTHX_ b_sv);
    RETVAL = bless_tensor(aTHX_ pdl_torch_div(a, b));
OUTPUT:
    RETVAL

SV*
_xs_matmul(SV* a_sv, SV* b_sv)
CODE:
    PdlTorchTensor* a = sv_to_tensor(aTHX_ a_sv);
    PdlTorchTensor* b = sv_to_tensor(aTHX_ b_sv);
    RETVAL = bless_tensor(aTHX_ pdl_torch_matmul(a, b));
OUTPUT:
    RETVAL

SV*
sum(SV* self)
CODE:
    PdlTorchTensor* t = sv_to_tensor(aTHX_ self);
    RETVAL = bless_tensor(aTHX_ pdl_torch_sum(t));
OUTPUT:
    RETVAL

SV*
mean(SV* self)
CODE:
    PdlTorchTensor* t = sv_to_tensor(aTHX_ self);
    RETVAL = bless_tensor(aTHX_ pdl_torch_mean(t));
OUTPUT:
    RETVAL

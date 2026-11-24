#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pdl.h"
#include "pdlcore.h"

#include <ggml.h>
#include <ggml-alloc.h>
#include <ggml-backend.h>
#include <string.h>

static Core* PDL;
static SV*   CoreSV;
static ggml_backend_t g_backend = NULL;

static SV* run_ggml_binary_op(pTHX_ SV* a_sv, SV* b_sv, int op_kind) {
    pdl* pa = PDL->SvPDLV(a_sv);
    pdl* pb = PDL->SvPDLV(b_sv);
    PDL->make_physical(pa);
    PDL->make_physdims(pa);
    PDL->make_physical(pb);
    PDL->make_physdims(pb);

    if (pa->datatype != PDL_F || pb->datatype != PDL_F) {
        croak("PDL::GGML requires float (PDL_F) ndarrays");
    }
    if (pa->ndims < 1 || pa->ndims > 2 || pb->ndims < 1 || pb->ndims > 2) {
        croak("PDL::GGML supports 1D or 2D float ndarrays");
    }

    int64_t a0 = (int64_t)pa->dims[0];
    int64_t a1 = pa->ndims == 2 ? (int64_t)pa->dims[1] : 1;
    int64_t b0 = (int64_t)pb->dims[0];
    int64_t b1 = pb->ndims == 2 ? (int64_t)pb->dims[1] : 1;

    struct ggml_init_params params = {
        .mem_size   = ggml_tensor_overhead() * 16 + ggml_graph_overhead(),
        .mem_buffer = NULL,
        .no_alloc   = true,
    };
    struct ggml_context* ctx = ggml_init(params);
    if (!ctx) {
        croak("ggml_init failed");
    }

    struct ggml_tensor* ta = ggml_new_tensor_2d(ctx, GGML_TYPE_F32, a0, a1);
    struct ggml_tensor* tb = ggml_new_tensor_2d(ctx, GGML_TYPE_F32, b0, b1);

    struct ggml_tensor* res = NULL;
    if (op_kind == 0) {
        res = ggml_add(ctx, ta, tb);
    } else if (op_kind == 1) {
        res = ggml_mul(ctx, ta, tb);
    } else {
        /* ggml_mul_mat(a, b) computes a * b^T -> shape (a->ne[1], b->ne[1]) */
        res = ggml_mul_mat(ctx, ta, tb);
    }

    ggml_backend_buffer_t buf = ggml_backend_alloc_ctx_tensors(ctx, g_backend);
    if (!buf) {
        ggml_free(ctx);
        croak("ggml_backend_alloc_ctx_tensors failed");
    }

    ggml_backend_tensor_set(ta, pa->data, 0, (size_t)(a0 * a1) * sizeof(float));
    ggml_backend_tensor_set(tb, pb->data, 0, (size_t)(b0 * b1) * sizeof(float));

    struct ggml_cgraph* gf = ggml_new_graph(ctx);
    ggml_build_forward_expand(gf, res);
    ggml_backend_graph_compute(g_backend, gf);

    pdl* out_pdl = PDL->pdlnew();
    out_pdl->datatype = PDL_F;
    if (res->ne[1] == 1 && pa->ndims == 1 && pb->ndims == 1) {
        PDL_Indx dims[1] = { (PDL_Indx)res->ne[0] };
        PDL->setdims(out_pdl, dims, 1);
    } else {
        PDL_Indx dims[2] = { (PDL_Indx)res->ne[0], (PDL_Indx)res->ne[1] };
        PDL->setdims(out_pdl, dims, 2);
    }
    PDL->allocdata(out_pdl);
    ggml_backend_tensor_get(res, out_pdl->data, 0, (size_t)(res->ne[0] * res->ne[1]) * sizeof(float));

    ggml_backend_buffer_free(buf);
    ggml_free(ctx);

    SV* out = newSV(0);
    PDL->SetSV_PDL(out, out_pdl);
    return out;
}

MODULE = PDL::GGML    PACKAGE = PDL::GGML

PROTOTYPES: DISABLE

BOOT:
{
    CoreSV = get_sv("PDL::SHARE", FALSE);
    if (!CoreSV) {
        croak("PDL::GGML requires PDL::Core to be loaded first");
    }
    PDL = INT2PTR(Core*, SvIV(CoreSV));
    if (PDL->Version != PDL_CORE_VERSION) {
        croak("PDL::GGML needs to be recompiled against the newly installed PDL");
    }
    ggml_backend_load_all();
    g_backend = ggml_backend_init_best();
    if (!g_backend) {
        croak("PDL::GGML failed to initialize any GGML backend");
    }
}

SV*
_xs_add(SV* a_sv, SV* b_sv)
CODE:
    RETVAL = run_ggml_binary_op(aTHX_ a_sv, b_sv, 0);
OUTPUT:
    RETVAL

SV*
_xs_mul(SV* a_sv, SV* b_sv)
CODE:
    RETVAL = run_ggml_binary_op(aTHX_ a_sv, b_sv, 1);
OUTPUT:
    RETVAL

SV*
_xs_mul_mat(SV* a_sv, SV* b_sv)
CODE:
    RETVAL = run_ggml_binary_op(aTHX_ a_sv, b_sv, 2);
OUTPUT:
    RETVAL

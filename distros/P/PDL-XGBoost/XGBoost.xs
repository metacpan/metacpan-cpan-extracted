#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pdl.h"
#include "pdlcore.h"

#include <xgboost/c_api.h>
#include <math.h>

static Core* PDL;
static SV*   CoreSV;

static void check_xgb(int rc, const char* fn) {
    if (rc != 0) {
        croak("PDL::XGBoost %s failed: %s", fn, XGBGetLastError());
    }
}

static DMatrixHandle sv_to_dmatrix(pTHX_ SV* sv) {
    if (!sv_isobject(sv) || !sv_derived_from(sv, "PDL::XGBoost::DMatrix")) {
        croak("Expected a PDL::XGBoost::DMatrix object");
    }
    IV ptr = SvIV(SvRV(sv));
    if (!ptr) {
        croak("PDL::XGBoost::DMatrix has already been destroyed");
    }
    return INT2PTR(DMatrixHandle, ptr);
}

static BoosterHandle sv_to_booster(pTHX_ SV* sv) {
    if (!sv_isobject(sv) || !sv_derived_from(sv, "PDL::XGBoost::Booster")) {
        croak("Expected a PDL::XGBoost::Booster object");
    }
    IV ptr = SvIV(SvRV(sv));
    if (!ptr) {
        croak("PDL::XGBoost::Booster has already been destroyed");
    }
    return INT2PTR(BoosterHandle, ptr);
}

static SV* bless_handle(pTHX_ void* ptr, const char* pkg) {
    SV* iv  = newSViv(PTR2IV(ptr));
    SV* ref = newRV_noinc(iv);
    sv_bless(ref, gv_stashpv(pkg, GV_ADD));
    return ref;
}

MODULE = PDL::XGBoost    PACKAGE = PDL::XGBoost

PROTOTYPES: DISABLE

BOOT:
{
    CoreSV = get_sv("PDL::SHARE", FALSE);
    if (!CoreSV) {
        croak("PDL::XGBoost requires PDL::Core to be loaded first");
    }
    PDL = INT2PTR(Core*, SvIV(CoreSV));
    if (PDL->Version != PDL_CORE_VERSION) {
        croak("PDL::XGBoost needs to be recompiled against the newly installed PDL");
    }
}

SV*
xgboost_version()
CODE:
    int major = 0, minor = 0, patch = 0;
    XGBoostVersion(&major, &minor, &patch);
    RETVAL = newSVpvf("%d.%d.%d", major, minor, patch);
OUTPUT:
    RETVAL

MODULE = PDL::XGBoost    PACKAGE = PDL::XGBoost::DMatrix

SV*
_xs_from_pdl(SV* pdl_sv, float missing)
CODE:
    pdl* p = PDL->SvPDLV(pdl_sv);
    PDL->make_physical(p);
    PDL->make_physdims(p);

    if (p->datatype != PDL_F) {
        croak("PDL::XGBoost::DMatrix requires a float (PDL_F) ndarray");
    }
    if (p->ndims != 2) {
        croak("PDL::XGBoost::DMatrix requires a 2D (cols x rows) ndarray");
    }

    /* PDL stores dims[0]=ncols (fastest), dims[1]=nrows (row-major in memory) */
    bst_ulong ncols = (bst_ulong)p->dims[0];
    bst_ulong nrows = (bst_ulong)p->dims[1];

    DMatrixHandle handle = NULL;
    check_xgb(
        XGDMatrixCreateFromMat((const float*)p->data, nrows, ncols, missing, &handle),
        "XGDMatrixCreateFromMat"
    );
    RETVAL = bless_handle(aTHX_ handle, "PDL::XGBoost::DMatrix");
OUTPUT:
    RETVAL

void
set_label(SV* self, SV* label_sv)
CODE:
    DMatrixHandle dm = sv_to_dmatrix(aTHX_ self);
    pdl* p = PDL->SvPDLV(label_sv);
    PDL->make_physical(p);
    PDL->make_physdims(p);

    if (p->datatype != PDL_F) {
        croak("set_label requires a float (PDL_F) 1D ndarray");
    }
    check_xgb(
        XGDMatrixSetFloatInfo(dm, "label", (const float*)p->data, (bst_ulong)p->nvals),
        "XGDMatrixSetFloatInfo(label)"
    );

UV
num_row(SV* self)
CODE:
    DMatrixHandle dm = sv_to_dmatrix(aTHX_ self);
    bst_ulong n = 0;
    check_xgb(XGDMatrixNumRow(dm, &n), "XGDMatrixNumRow");
    RETVAL = (UV)n;
OUTPUT:
    RETVAL

UV
num_col(SV* self)
CODE:
    DMatrixHandle dm = sv_to_dmatrix(aTHX_ self);
    bst_ulong n = 0;
    check_xgb(XGDMatrixNumCol(dm, &n), "XGDMatrixNumCol");
    RETVAL = (UV)n;
OUTPUT:
    RETVAL

void
DESTROY(SV* self)
CODE:
    if (SvROK(self)) {
        SV* iv = SvRV(self);
        IV ptr = SvIV(iv);
        if (ptr) {
            XGDMatrixFree(INT2PTR(DMatrixHandle, ptr));
            sv_setiv(iv, 0);
        }
    }

MODULE = PDL::XGBoost    PACKAGE = PDL::XGBoost::Booster

SV*
_xs_create(SV* dm_sv)
CODE:
    BoosterHandle booster = NULL;
    if (SvOK(dm_sv)) {
        DMatrixHandle dm = sv_to_dmatrix(aTHX_ dm_sv);
        DMatrixHandle cache[1] = { dm };
        check_xgb(XGBoosterCreate(cache, 1, &booster), "XGBoosterCreate");
    } else {
        check_xgb(XGBoosterCreate(NULL, 0, &booster), "XGBoosterCreate");
    }
    RETVAL = bless_handle(aTHX_ booster, "PDL::XGBoost::Booster");
OUTPUT:
    RETVAL

void
set_param(SV* self, const char* name, const char* value)
CODE:
    BoosterHandle b = sv_to_booster(aTHX_ self);
    check_xgb(XGBoosterSetParam(b, name, value), "XGBoosterSetParam");

void
update(SV* self, SV* dm_sv, int iter)
CODE:
    BoosterHandle b  = sv_to_booster(aTHX_ self);
    DMatrixHandle dm = sv_to_dmatrix(aTHX_ dm_sv);
    check_xgb(XGBoosterUpdateOneIter(b, iter, dm), "XGBoosterUpdateOneIter");

SV*
predict(SV* self, SV* dm_sv)
CODE:
    BoosterHandle b  = sv_to_booster(aTHX_ self);
    DMatrixHandle dm = sv_to_dmatrix(aTHX_ dm_sv);

    bst_ulong out_len = 0;
    const float* out_result = NULL;
    check_xgb(
        XGBoosterPredict(b, dm, 0, 0, 0, &out_len, &out_result),
        "XGBoosterPredict"
    );

    pdl* p = PDL->pdlnew();
    p->datatype = PDL_F;
    PDL_Indx dims[1] = { (PDL_Indx)out_len };
    PDL->setdims(p, dims, 1);
    PDL->allocdata(p);
    if (out_len > 0) {
        Copy(out_result, p->data, out_len, float);
    }

    SV* out = newSV(0);
    PDL->SetSV_PDL(out, p);
    RETVAL = out;
OUTPUT:
    RETVAL

void
save_model(SV* self, const char* path)
CODE:
    BoosterHandle b = sv_to_booster(aTHX_ self);
    check_xgb(XGBoosterSaveModel(b, path), "XGBoosterSaveModel");

void
load_model(SV* self, const char* path)
CODE:
    BoosterHandle b = sv_to_booster(aTHX_ self);
    check_xgb(XGBoosterLoadModel(b, path), "XGBoosterLoadModel");

void
DESTROY(SV* self)
CODE:
    if (SvROK(self)) {
        SV* iv = SvRV(self);
        IV ptr = SvIV(iv);
        if (ptr) {
            XGBoosterFree(INT2PTR(BoosterHandle, ptr));
            sv_setiv(iv, 0);
        }
    }

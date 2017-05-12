#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "xs/compat.h"

#define MY_CXT_KEY "Sub::Disable::_guts" XS_VERSION
typedef struct {
#ifdef USE_ITHREADS
    tTHX owner;
#endif
    HV* disabled_methods;
} my_cxt_t;

START_MY_CXT;

STATIC OP*
disable_function_checker(pTHX_ OP *op, GV *namegv, SV *ckobj) {
    op_free(op);
    return newOP(OP_NULL, 0);
}

STATIC Perl_check_t old_entersub_checker = 0;

STATIC OP*
entersub_checker(pTHX_ OP *o) {
    dMY_CXT;
    if (!HvARRAY(MY_CXT.disabled_methods)) goto end;

    OP* kid = cUNOPo->op_first;
    if (!kid || kid->op_type != OP_PUSHMARK) goto end;

    kid = OpSIBLING(kid);

    if (!kid || kid->op_type != OP_CONST) goto end;
    SV* package = cSVOPx_sv(kid);

    while (OpSIBLING(kid)) {
        kid = OpSIBLING(kid);
    }

    if (kid->op_type != OP_METHOD_NAMED) goto end;
    SV* method = cMETHOPx_meth(kid);
    if (!SvPOK(method)) goto end;

    HE* hent = hv_fetch_ent(MY_CXT.disabled_methods, package, 0, 0);
    if (!hent) goto end;

    AV* needles         = (AV*)HeVAL(hent);
    SV** needle_list    = AvARRAY(needles);
    SSize_t needle_cnt  = AvFILLp(needles);

    while (needle_cnt-- >= 0) {
        SV* needle = *(needle_list++);

        if (SvCUR(needle) != SvCUR(method)) continue;
        if (SvPVX(needle) == SvPVX(method) || memEQ(SvPVX(needle), SvPVX(method), SvCUR(needle))) {
            op_free(o);
            return newOP(OP_NULL, 0);
        }
    }

    end:
    return old_entersub_checker(aTHX_ o);
}

#ifdef COMPAT_OP_CHECKER

STATIC void
compat_wrap_op_checker(Optype opcode, Perl_check_t new_checker, Perl_check_t *old_checker_p) {
#ifdef USE_ITHREADS
    MUTEX_LOCK(&PL_my_ctx_mutex);
#endif

    if (!*old_checker_p) {
        *old_checker_p = PL_check[opcode];
        PL_check[opcode] = new_checker;
    }

#ifdef USE_ITHREADS
    MUTEX_UNLOCK(&PL_my_ctx_mutex);
#endif
}

#endif /* COMPAT_OP_CHECKER */

MODULE = Sub::Disable      PACKAGE = Sub::Disable
PROTOTYPES: DISABLE

BOOT:
{
    MY_CXT_INIT;
    MY_CXT.disabled_methods = newHV();
#ifdef USE_ITHREADS
    MY_CXT.owner = aTHX;
#endif

    wrap_op_checker(OP_ENTERSUB, entersub_checker, &old_entersub_checker);
}

#ifdef USE_ITHREADS

void
CLONE(...)
PPCODE:
{
    tTHX owner;
    HV* cloned;

    {
        dMY_CXT;
        CLONE_PARAMS params = {NULL, 0, MY_CXT.owner};

        cloned = (HV*)sv_dup_inc((SV*)MY_CXT.disabled_methods, &params);
    }

    {
        MY_CXT_CLONE;
        MY_CXT.owner            = aTHX;
        MY_CXT.disabled_methods = cloned;
    }

    XSRETURN_UNDEF;
}

#endif /* USE_ITHREADS */

void
disable_cv_call(SV* cv)
PPCODE:
{
    if (SvROK(cv)) cv = SvRV(cv);
    if (SvTYPE(cv) != SVt_PVCV) croak("Not a CODE reference");

    cv_set_call_checker((CV*)cv, disable_function_checker, cv);
    XSRETURN_UNDEF;
}

void
disable_named_call(SV* package, SV* func)
PPCODE:
{
    HV* stash = gv_stashsv(package, GV_ADD);
    HE* hent = hv_fetch_ent(stash, func, 0, 0);
    GV* glob = hent ? (GV*)HeVAL(hent) : NULL;

    if (!glob || !isGV(glob) || SvFAKE(glob)) {
        if (!glob) glob = (GV*)newSV(0);
        gv_init_sv(glob, stash, func, GV_ADDMULTI);

        if (hent) {
            SvREFCNT_inc_NN((SV*)glob);
            SvREFCNT_dec_NN(HeVAL(hent));
            HeVAL(hent) = (SV*)glob;

        } else {
            if (!hv_store_ent(stash, func, (SV*)glob, 0)) {
                SvREFCNT_dec_NN(glob);
                croak("Can't add a glob to package");
            }
        }
    }

    CV* cv = GvCV(glob);
    if (!cv) {
        cv = (CV*)newSV_type(SVt_PVCV);
        GvCV_set(glob, cv);
        CvGV_set(cv, glob);
    }

    cv_set_call_checker(cv, disable_function_checker, (SV*)cv);

    XSRETURN_UNDEF;
}

void
disable_method_call(SV* package, SV* method)
PPCODE:
{
    dMY_CXT;
    SV* shared_method_sv;

    if (!SvIsCOW_shared_hash(method)) {
        STRLEN len;
        const char* method_buf = SvPV_const(method, len);
        shared_method_sv = newSVpvn_share(method_buf, SvUTF8(method) ? -(I32)len : (I32)len, 0);
    } else {
        shared_method_sv = method;
        share_hek_hek(SvSHARED_HEK_FROM_PV(SvPVX_const(shared_method_sv)));
    }

    SV** svp = hv_common(MY_CXT.disabled_methods, package, NULL, 0, 0, HV_FETCH_LVALUE | HV_FETCH_JUST_SV, NULL, 0);
    if (!SvOK(*svp)) sv_upgrade(*svp, SVt_PVAV);
    av_push((AV*)*svp, shared_method_sv);

    XSRETURN_UNDEF;
}


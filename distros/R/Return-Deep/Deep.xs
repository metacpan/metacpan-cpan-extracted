#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#define PERL_VERSION_DECIMAL(r,v,s) (r*1000000 + v*1000 + s)
#define PERL_DECIMAL_VERSION PERL_VERSION_DECIMAL(PERL_REVISION,PERL_VERSION,PERL_SUBVERSION)
#define PERL_VERSION_GE(r,v,s) (PERL_DECIMAL_VERSION >= PERL_VERSION_DECIMAL(r,v,s))

static Perl_ppaddr_t return_ppaddr;

static OP * my_pp_deep_ret(pTHX){
    dSP; POPs;

    IV depth = SvIV(PL_stack_base[TOPMARK+1]);

    for(SV ** p = PL_stack_base+TOPMARK; p<SP; ++p)
        *p = *(p+1);
    POPs;

    if( depth <= 0 )
        RETURN;

    OP * next_op;
    while( depth-- )
        next_op = return_ppaddr(aTHX);
    RETURNOP(next_op);
}

static OP * deep_ret_check(pTHX_ OP * o, GV * namegv, SV * ckobj){
    o->op_ppaddr = my_pp_deep_ret;
    return o;
}

#if !PERL_VERSION_GE(5,14,0)
static CV* my_deep_ret_cv;
static OP* (*orig_entersub_check)(pTHX_ OP*);
static OP* my_entersub_check(pTHX_ OP* o){
    CV *cv = NULL;
    OP *cvop = OpSIBLING(((OpSIBLING(cUNOPo->op_first)) ? cUNOPo : ((UNOP*)cUNOPo->op_first))->op_first);
    while( OpSIBLING(cvop) )
        cvop = OpSIBLING(cvop);
    if( cvop->op_type == OP_RV2CV && !(o->op_private & OPpENTERSUB_AMPER) ){
        SVOP *tmpop = (SVOP*)((UNOP*)cvop)->op_first;
        switch (tmpop->op_type) {
            case OP_GV: {
                GV *gv = cGVOPx_gv(tmpop);
                cv = GvCVu(gv);
                if (!cv)
                    tmpop->op_private |= OPpEARLY_CV;
            } break;
            case OP_CONST: {
               SV *sv = cSVOPx_sv(tmpop);
               if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV)
                   cv = (CV*)SvRV(sv);
           } break;
        }
        if( cv==my_deep_ret_cv )
            o->op_ppaddr = my_pp_deep_ret;
    }
    return orig_entersub_check(aTHX_ o);
}
#endif

MODULE = Return::Deep		PACKAGE = Return::Deep		

INCLUDE: const-xs.inc

BOOT:
    return_ppaddr = PL_ppaddr[OP_RETURN];
#if PERL_VERSION_GE(5,14,0)
    cv_set_call_checker(get_cv("Return::Deep::deep_ret", TRUE), deep_ret_check, &PL_sv_undef);
#else
    my_deep_ret_cv = get_cv("Return::Deep::deep_ret", TRUE);
    orig_entersub_check = PL_check[OP_ENTERSUB];
    PL_check[OP_ENTERSUB] = my_entersub_check;
#endif

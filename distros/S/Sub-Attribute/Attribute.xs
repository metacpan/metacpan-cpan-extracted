#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define NEED_PL_parser
#include "ppport.h"
#include "mgx.h"

static void
my_qerror(pTHX_ SV *err)
{
    dVAR;
    if (PL_in_eval)
        sv_catsv(ERRSV, err);
    else if (PL_errors)
        sv_catsv(PL_errors, err);
    else
        Perl_warn(aTHX_ "%"SVf, SVfARG(err));
    ++PL_error_count;
}
#undef qerror
#define qerror(msg) my_qerror(aTHX_ msg)


#define PACKAGE "Sub::Attribute"
#define META_ATTR "ATTR_SUB"

#define MY_CXT_KEY PACKAGE "::_guts" XS_VERSION
typedef struct {
    AV* queue;
    I32 debug;
} my_cxt_t;
START_MY_CXT

enum {
    SA_KLASS,
    SA_CODE,
    SA_NAME,
    SA_DATA,
    SA_METHOD
};

static void
apply_handler(pTHX_ pMY_CXT_ AV* const handler){
    SV* const klass        = AvARRAY(handler)[SA_KLASS];
    SV* const code_ref     = AvARRAY(handler)[SA_CODE];
    CV* const cv           = (CV*)SvRV(code_ref);
    SV* const name         = AvARRAY(handler)[SA_NAME];
    SV* const data         = AvARRAY(handler)[SA_DATA];
    SV* const method       = AvARRAY(handler)[SA_METHOD];
    dSP;

    if(sv_true(ERRSV)){ /* dying by bad attributes */
        qerror(ERRSV);
        return;
    }

    assert(CvGV(cv));
    assert(SvTYPE(method) == SVt_PVCV);

    if(MY_CXT.debug){
        warn("apply attribute :%s%s to &%s in %"SVf,
            GvNAME(CvGV((CV*)method)),
            SvOK(data) ? form("(%"SVf")", data) : "",
            GvNAME(CvGV(cv)),
            klass
        );
    }

    PUSHMARK(SP);
    EXTEND(SP, 5);

    PUSHs(klass);
    if(!CvANON(cv)){
        mPUSHs(newRV_inc((SV*)CvGV(cv)));
    }
    else{
        PUSHs(&PL_sv_undef); /* anonymous subroutines */
    }
    PUSHs(code_ref);
    PUSHs(name);
    PUSHs(data);

    PUTBACK;

    PL_stack_sp -= call_sv(method, G_VOID | G_EVAL);

    if(sv_true(ERRSV)){
        SV* const msg = sv_newmortal();
        sv_setpvf(msg, "Can't apply attribute %"SVf" because: %"SVf, name, ERRSV);
        qerror(msg);
    }
}

static int
sa_process_queue(pTHX_ SV* const sv, MAGIC* const mg){
    dMY_CXT;
    SV**       svp = AvARRAY(MY_CXT.queue);
    SV** const end = svp + AvFILLp(MY_CXT.queue) + 1;
    PERL_UNUSED_ARG(sv);
    PERL_UNUSED_ARG(mg);

    ENTER;
    SAVETMPS;

    while(svp != end){
        apply_handler(aTHX_ aMY_CXT_ (AV*)*svp);
        svp++;

        FREETMPS;
    }

    LEAVE;

    av_clear(MY_CXT.queue);
    return 0;
}

static SV*
sa_newSVsv_share(pTHX_ SV* const sv){
    STRLEN len;
    const char* const pv = SvPV_const(sv, len);
    return newSVpvn_share(pv, len, 0U);
}

static MGVTBL hook_scope_vtbl = {
    NULL, /* get */
    NULL, /* set */
    NULL, /* len */
    NULL, /* clear */
    sa_process_queue, /* free */
    NULL, /* copy */
    NULL, /* dup */
#ifdef MGf_LOCAL
    NULL,  /* local */
#endif
};


static MGVTBL attr_handler_vtbl;


MODULE = Sub::Attribute    PACKAGE = Sub::Attribute

PROTOTYPES: DISABLE

BOOT:
{
    const char* const d = PerlEnv_getenv("SUB_ATTRIBUTE_DEBUG");
    MY_CXT_INIT;
    MY_CXT.queue      = newAV();
    MY_CXT.debug      = (d && *d != '\0' && strNE(d, "0"));
}

void
CLONE(...)
CODE:
    MY_CXT_CLONE;
    MY_CXT.queue = newAV();
    PERL_UNUSED_VAR(items);

void
MODIFY_CODE_ATTRIBUTES(SV* klass, CV* code, ...)
PREINIT:
    dMY_CXT;
    HV* const hinthv = GvHVn(PL_hintgv);
    HV* stash;
    MAGIC* mg;
    I32 i;
PPCODE:
    mg = mg_find_by_vtbl((SV*)hinthv, &hook_scope_vtbl);
    if(!mg){
        sv_magicext((SV*)hinthv, NULL, PERL_MAGIC_ext, &hook_scope_vtbl, NULL, 0);
        PL_hints |= HINT_LOCALIZE_HH;
    }
    stash = gv_stashsv(klass, TRUE);
    klass = sa_newSVsv_share(aTHX_ klass);

    for(i = 2; i < items; i++){
        STRLEN attrlen;
        const char* const attr = SvPV_const(ST(i), attrlen);
        const char* data       = strchr(attr, '(');
        STRLEN  datalen        = attrlen - (data - attr) - 2;
        STRLEN const namelen   = data ? (STRLEN)(data - attr) : attrlen;
        GV* meth;

        if(data){
            data++; /* skip '(' */
            while(isSPACE(*data)){
                data++;
                datalen--;
            }
            while(isSPACE(data[datalen-1])){
                datalen--;
            }
        }

        if(strnEQ(attr, META_ATTR, sizeof(META_ATTR))){ /* meta attribute */
            if(!MgFind((SV*)code, &attr_handler_vtbl)){
                sv_magicext(
                    (SV*)code,
                    NULL, PERL_MAGIC_ext, &attr_handler_vtbl,
                    PACKAGE, 0
                );

                if(MY_CXT.debug){
                    warn("install attribute handler %"SVf"\n", PL_subname);
                }
            }
            continue;
        }

        meth = gv_fetchmeth_autoload(stash, attr, namelen, 0 /* special zero */);
        if(meth && MgFind((SV*)GvCV(meth), &attr_handler_vtbl)){
            AV* const handler = newAV();

            av_store(handler, SA_METHOD, SvREFCNT_inc_simple_NN((SV*)GvCV(meth)));
            av_store(handler, SA_KLASS,  SvREFCNT_inc_simple_NN(klass));
            av_store(handler, SA_CODE,   newRV_inc((SV*)code));
            av_store(handler, SA_NAME,   newSVpvn_share(attr, namelen, 0U));

            if(data){
                av_store(handler, SA_DATA,  newSVpvn(data, datalen));
            }

            av_push(MY_CXT.queue, (SV*)handler);
        }
        else{
            if(MY_CXT.debug){
                warn("ignore unrecognized attribute :%"SVf"\n", ST(i));
            }
#if PERL_BCDVERSION < 0x5008009
            /* See RT #53420 */
            {
                const char* const a = SvPV_nolen_const(ST(i));
                if(    strEQ(a, "lvalue")
                    || strEQ(a, "method")
                    || strEQ(a, "locked")
                    || strEQ(a, "unique")
                    || strEQ(a, "shared") ){
                    continue;
                }
            }
#endif
            XPUSHs(ST(i));
        }
    }

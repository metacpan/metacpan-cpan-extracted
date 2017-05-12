#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

static SV * extract_cv(pTHX_ SV * sv){
    HV * st;
    GV * gvp;
    SV * cv = (SV*) sv_2cv(sv, &st, &gvp, 0);

    if (!cv)
        croak("expected a CODE reference for watcher handler");

    return cv;
}

static int watcher_handler(pTHX_ SV * sv, MAGIC * mg){
    dSP;
    SV * handler = mg->mg_obj;

    if( handler ){
        PUSHMARK(SP);
        XPUSHs(sv);
        PUTBACK;

        call_sv(handler, G_VOID | G_DISCARD);
    }

    return 0;
}

static MGVTBL modified_vtbl = {
    0, watcher_handler, 0, 0, 0
};
static MGVTBL destroyed_vtbl = {
    0, 0, 0, 0, watcher_handler
};

static int canceller_handler(pTHX_ SV * canceller, MAGIC * mg){
    SV * target = SvRV(canceller);
    if( SvOK(target) ){
        MAGIC * target_mg = SvMAGIC(target);
        SV * handler_cv = (SV*) mg->mg_ptr;
        while( target_mg ){
            if( target_mg->mg_type==PERL_MAGIC_ext && target_mg->mg_obj == handler_cv ){
#ifdef SvREFCNT_dec_NN
                SvREFCNT_dec_NN(handler_cv);
#else
                SvREFCNT_dec(handler_cv);
#endif
                target_mg->mg_flags &= ~MGf_REFCOUNTED;
                target_mg->mg_obj = NULL;
            }
            target_mg = target_mg->mg_moremagic;
        }
    }
    return 0;
}

static MGVTBL canceller_vtbl = {
    0, 0, 0, 0, canceller_handler
};

void hook_watcher_magic(pTHX_ SV * target, SV * handler, MGVTBL * vtbl){
    dSP;
    SV * handler_cv = extract_cv(aTHX_ handler);
    SvUPGRADE(target, SVt_PVMG);
    sv_magicext(target, handler_cv, PERL_MAGIC_ext, vtbl, NULL, 0);

    if( GIMME_V!=G_VOID ){
        SV * canceller = newRV_inc(target);
        sv_rvweaken(canceller);
        sv_magicext(canceller, NULL, PERL_MAGIC_ext, &canceller_vtbl, (char *)handler_cv, 0);
        PUSHs(sv_2mortal(newRV_noinc(canceller)));
        PUTBACK;
    }
}

MODULE = Scalar::Watcher		PACKAGE = Scalar::Watcher		

INCLUDE: const-xs.inc

void
when_modified(SV * target, SV * handler)
    PROTOTYPE: $&
    PPCODE:
        hook_watcher_magic(aTHX_ target, handler, &modified_vtbl);
        SPAGAIN;

void
when_destroyed(SV * target, SV * handler)
    PROTOTYPE: $&
    PPCODE:
        hook_watcher_magic(aTHX_ target, handler, &destroyed_vtbl);
        SPAGAIN;

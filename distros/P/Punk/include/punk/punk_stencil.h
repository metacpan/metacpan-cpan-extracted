/* punk_stencil.h - Punk::View::Stencil, the shipped view engine, in C.
 *
 * The adapter over Template::Stencil is two array slots and no Perl: the
 * options as registered, and the Template::Stencil object built from them.
 * Rendering goes through Template::Stencil's C ABI (st_abi.h, reached through
 * ExtUtils::Depends), so the path from the dispatcher to the template VM is
 *
 *     punk_views.h -> this XSUB -> abi->render
 *
 * with no Perl frame anywhere in it. The engine object is built once, at boot,
 * through Template::Stencil->new - the one Perl call, in the one place where a
 * bad option should still fail with the rest of the configuration.
 *
 * Perl headers and punk_static.h (punk_closure is not used here, but the file
 * ordering in Punk.xs puts this after it) must be in scope first.
 */

#ifndef PUNK_STENCIL_H
#define PUNK_STENCIL_H

#include "st_abi.h"

enum { PVS_OPTS = 0, PVS_ENGINE = 1 };   /* the object's slots */

static const st_abi *PUNK_ST = NULL;
static int PUNK_ST_TRIED = 0;

/* Resolve (once) Template::Stencil's ABI table, or NULL. PUNK_FAKE_ST_BAD
 * simulates a version mismatch for the guard test. */
static const st_abi *punk_st_try(pTHX) {
    if (!PUNK_ST_TRIED) {
        dSP; int count, ok; IV p = 0;
        PUNK_ST_TRIED = 1;
        ok = pk_require_once(aTHX_ "Template::Stencil", FALSE);
        SPAGAIN;   /* the require may have reallocated the value stack */
        if (ok) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("Template::Stencil::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const st_abi *a = INT2PTR(const st_abi *, p);
                if (a && !getenv("PUNK_FAKE_ST_BAD")
                    && a->abi_version >= ST_ABI_VERSION)
                    PUNK_ST = a;
            }
        }
    }
    return PUNK_ST;
}

/* The table, croaking if it is missing or too old. Template::Stencil 0.02+ is
 * a hard prerequisite, so this is a boot-environment error rather than a
 * per-request fallback - there is no Perl render path to fall back to. */
static const st_abi *punk_st(pTHX) {
    const st_abi *a = punk_st_try(aTHX);
    if (!a)
        croak("Punk::View::Stencil: needs Template::Stencil with a compatible "
              "C ABI (ST_ABI_VERSION %d); upgrade Template::Stencil to 0.02+",
              ST_ABI_VERSION);
    return a;
}

static AV *pvs_av(pTHX_ SV *self) {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
        croak("Punk::View::Stencil: not a view object");
    return (AV *)SvRV(self);
}

static SV *pvs_slot(pTHX_ SV *self, I32 slot) {
    SV **e = av_fetch(pvs_av(aTHX_ self), slot, 0);
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

/* Template::Stencil->new(\%opts) - the single Perl call, at boot. Building the
 * engine here rather than on first render is the point: an option Stencil will
 * not accept fails with the rest of the configuration, not on a request. */
static SV *pvs_build_engine(pTHX_ SV *opts) {
    dSP;
    SV *obj;
    int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    mPUSHs(newSVpvs("Template::Stencil"));
    PUSHs(opts && SvOK(opts) ? opts
                             : sv_2mortal(newRV_noinc((SV *)newHV())));
    PUTBACK;
    count = call_method("new", G_SCALAR);
    SPAGAIN;
    obj = count > 0 ? newSVsv(POPs) : &PL_sv_undef;
    PUTBACK; FREETMPS; LEAVE;
    if (!SvROK(obj))
        croak("Punk::View::Stencil: Template::Stencil->new returned no object");
    return obj;
}

/* One render, entirely in C. Returns the bytes SV (caller owns) or croaks with
 * the template error, which is what the render method did and what Punk::Views
 * turns into a 500 further up. */
static SV *pvs_render(pTHX_ SV *self, SV *tmpl, SV *data, SV *opts) {
    const st_abi *abi = punk_st(aTHX);
    SV  *engine_sv = pvs_slot(aTHX_ self, PVS_ENGINE);
    void *engine;
    SV  *err = NULL, *out;
    HV  *dhv = NULL;

    if (!engine_sv)
        croak("Punk::View::Stencil: this view has no engine");
    /* engine_of on every render, not a cached pointer: an ithread clone drops
     * its engine and rebuilds lazily, so a cached one would dangle. The lookup
     * is a walk of the object's magic chain. */
    engine = abi->engine_of(aTHX_ engine_sv);
    if (!engine)
        croak("Punk::View::Stencil: the engine is not a Template::Stencil "
              "object");

    if (data && SvOK(data)) {
        if (!SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVHV)
            croak("Punk::View::Stencil: render data must be a hashref");
        dhv = (HV *)SvRV(data);
    }
    out = abi->render(aTHX_ engine, tmpl, dhv,
                      (opts && SvOK(opts)) ? opts : NULL, &err);
    if (!out)
        croak_sv(err ? err : sv_2mortal(newSVpvs(
            "Punk::View::Stencil: render failed")));
    return out;
}

#endif /* PUNK_STENCIL_H */

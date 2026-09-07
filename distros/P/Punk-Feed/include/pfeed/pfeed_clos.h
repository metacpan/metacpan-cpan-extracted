#ifndef PFEED_CLOS_H
#define PFEED_CLOS_H

/* Closures, calls into Perl, and the small predicates the rest of this
 * distribution reads options with.
 *
 * This is Punk-Authorisation's pau_closure device (pau/pau_clos.h), which is
 * Punk-TOTP's pp_closure, which is a copy of Punk's private punk_closure: a CV
 * built with newXS carrying captured SVs in PERL_MAGIC_ext. Punk does not
 * export it - pk_abi.h is an observer interface and says so - so a plugin that
 * wants a body with state carries its own.
 *
 * The capture is Punk's own shape, an AV, rather than Authorisation's
 * (cfg, extra) pair: the bodies here capture [app], [app, format] and
 * [app, name, format], which two fixed slots cannot express.
 */

typedef struct { AV *cap; } pfeed_clos_t;

static int pfeed_clos_free(pTHX_ SV *sv, MAGIC *mg)
{
    pfeed_clos_t *c = (pfeed_clos_t *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (c) {
        if (c->cap) SvREFCNT_dec((SV *)c->cap);
        Safefree(c);
    }
    return 0;
}

static MGVTBL pfeed_clos_vtbl = { NULL, NULL, NULL, NULL, pfeed_clos_free,
                                  NULL, NULL, NULL };

/* Takes ownership of cap. */
static SV *pfeed_closure(pTHX_ XSUBADDR_t body, AV *cap)
{
    CV *cv = (CV *)newXS(NULL, body, (char *)__FILE__);
    pfeed_clos_t *c;

    Newxz(c, 1, pfeed_clos_t);
    c->cap = cap;
    sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &pfeed_clos_vtbl, (char *)c, 0);
    return newRV_noinc((SV *)cv);
}

static AV *pfeed_cap_of(pTHX_ CV *cv)
{
    MAGIC *mg = mg_findext((SV *)cv, PERL_MAGIC_ext, &pfeed_clos_vtbl);
    AV *cap = mg ? ((pfeed_clos_t *)mg->mg_ptr)->cap : NULL;
    if (!cap) croak("Punk::Plugin::Feed: a closure lost its capture");
    return cap;
}

/* One capture slot, borrowed. */
static SV *pfeed_cap_slot(pTHX_ CV *cv, SSize_t i)
{
    AV *cap = pfeed_cap_of(aTHX_ cv);
    SV **e = av_fetch(cap, i, 0);
    return (e && *e) ? *e : NULL;
}

/* ---- calling back into Perl -------------------------------------------------
 * Every call hands back a NEW SV (+1) - a copy of the result, undef when there
 * was none - so a caller owns what it holds and mortalises it. */

static SV *pfeed_call_common(pTHX_ SV *inv, const char *meth, SV *code,
                             SV **argv, int argc)
{
    dSP;
    int count, i;
    SV *ret;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, argc + 1);
    if (inv) PUSHs(inv);
    for (i = 0; i < argc; i++) PUSHs(argv[i]);
    PUTBACK;
    if (code)     count = call_sv(code, G_SCALAR);
    else if (inv) count = call_method(meth, G_SCALAR);
    else          count = call_pv(meth, G_SCALAR);
    SPAGAIN;
    if (count > 0) {
        SV *top = POPs;
        ret = newSVsv(top);
    } else {
        ret = newSV(0);
    }
    PUTBACK; FREETMPS; LEAVE;
    return ret;
}

/* $inv->$meth(@argv) */
static SV *pfeed_call(pTHX_ SV *inv, const char *meth, SV **argv, int argc)
{
    return pfeed_call_common(aTHX_ inv, meth, NULL, argv, argc);
}

/* $code->(@argv) in LIST context, under G_EVAL, into a fresh AV.
 *
 * G_EVAL because this is how a section is run, and a section reads a database.
 * A die inside a call made WITHOUT G_EVAL longjmps past the ENTER/SAVETMPS
 * above and leaves the Perl stack short; the damage does not show up where it
 * happened, it shows up later as garbage read out of an unrelated array.
 * JMPENV_PUSH is not a substitute - catching the jump is not the problem,
 * unwinding the stack bookkeeping is, and only G_EVAL does that.
 *
 * On failure *failed is set, ERRSV holds the reason, and the AV is empty.
 */
static AV *pfeed_call_list(pTHX_ SV *code, SV **argv, int argc, int *failed)
{
    dSP;
    int count, i;
    AV *out = newAV();

    *failed = 0;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    if (argc) {
        EXTEND(SP, argc);
        for (i = 0; i < argc; i++) PUSHs(argv[i]);
    }
    PUTBACK;
    count = call_sv(code, G_LIST | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        *failed = 1;
        while (count-- > 0) (void)POPs;
    }
    else {
        /* the stack has them in order and POPs walks back, so fill from the
         * end rather than pushing and reversing afterwards */
        for (i = count - 1; i >= 0; i--) {
            SV *top = POPs;
            (void)av_store(out, i, newSVsv(top));
        }
    }
    PUTBACK; FREETMPS; LEAVE;
    return out;
}

/* $inv->$meth(@argv) under G_EVAL: the value, or NULL with *failed set and the
 * reason in ERRSV.
 *
 * Used where the method being called croaks by design - $app->_resolve_target
 * does, on a target it cannot resolve. Without G_EVAL that croak longjmps past
 * the ENTER/SAVETMPS in pfeed_call_common and leaves the Perl stack short, and
 * the damage surfaces later as garbage read out of an unrelated array. */
static SV *pfeed_try(pTHX_ SV *inv, const char *meth, SV **argv, int argc,
                     int *failed)
{
    dSP;
    int count, i;
    SV *ret = NULL;

    *failed = 0;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, argc + 1);
    PUSHs(inv);
    for (i = 0; i < argc; i++) PUSHs(argv[i]);
    PUTBACK;
    count = call_method(meth, G_SCALAR | G_EVAL);
    SPAGAIN;
    while (count-- > 0) {
        SV *top = POPs;
        if (count == 0 && !ret) ret = newSVsv(top);
    }
    PUTBACK;
    if (SvTRUE(ERRSV)) {
        *failed = 1;
        if (ret) { SvREFCNT_dec(ret); ret = NULL; }
    }
    FREETMPS; LEAVE;
    return ret;
}

/* Does this class or object have that method? An ordinary `can`, so
 * inheritance and AUTOLOAD behave as they would anywhere else. */
static int pfeed_can(pTHX_ SV *obj, const char *meth)
{
    SV *m = sv_2mortal(newSVpv(meth, 0));
    SV *r = sv_2mortal(pfeed_call(aTHX_ obj, "can", &m, 1));
    return (r && SvTRUE(r)) ? 1 : 0;
}

/* ---- predicates and small readers -------------------------------------- */

static int pfeed_is_hash(SV *sv)
{
    return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV;
}

static int pfeed_is_array(SV *sv)
{
    return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV;
}

static int pfeed_is_code(SV *sv)
{
    return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV;
}

/* The Punk::App's own hash. It is a blessed hashref and we want the object,
 * so SvTYPE matching it is the point rather than the trap it usually is. */
static HV *pfeed_app_hv(pTHX_ SV *app)
{
    PERL_UNUSED_CONTEXT;
    return pfeed_is_hash(app) ? (HV *)SvRV(app) : NULL;
}

/* One key of a hash, or NULL. Borrowed, not owned. */
static SV *pfeed_hget(pTHX_ HV *h, const char *k)
{
    SV **e = h ? hv_fetch(h, k, (I32)strlen(k), 0) : NULL;
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

/* A context is a blessed AV; these are its slots. Punk's own layout
 * (punk/punk_context.h), which pk_abi.h exposes as env_of/app_of/stash_of -
 * the accessors it does offer, and the reason this reads the slot directly
 * rather than paying a method call per header.
 *
 * Fixed by Punk's ABI rather than by this file: PCX_ENV moving would be a
 * change pk_abi's version guards would have to announce.
 *
 * $c->origin is deliberately NOT in here. It is reached by method call,
 * because the allowlist logic behind it lives in Punk's private punk_host.h
 * and reimplementing it would be reimplementing a security check. */
enum { PFEED_CX_ENV = 0, PFEED_CX_APP = 1, PFEED_CX_STASH = 4 };

static SV *pfeed_cx_slot(pTHX_ SV *c, I32 slot)
{
    AV *av;
    SV **e;
    if (!(c && SvROK(c) && SvTYPE(SvRV(c)) == SVt_PVAV)) return NULL;
    av = (AV *)SvRV(c);
    e = av_fetch(av, slot, 0);
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

/* One PSGI environment key, borrowed, or NULL. */
static SV *pfeed_env(pTHX_ SV *c, const char *k)
{
    SV *env = pfeed_cx_slot(aTHX_ c, PFEED_CX_ENV);
    if (!pfeed_is_hash(env)) return NULL;
    return pfeed_hget(aTHX_ (HV *)SvRV(env), k);
}

/* An app-hash slot that is an AV, created empty on first ask. */
static AV *pfeed_app_av(pTHX_ HV *h, const char *k)
{
    SV *v = pfeed_hget(aTHX_ h, k);
    if (pfeed_is_array(v)) return (AV *)SvRV(v);
    {
        AV *av = newAV();
        (void)hv_store(h, k, (I32)strlen(k), newRV_noinc((SV *)av), 0);
        return av;
    }
}

#endif /* PFEED_CLOS_H */

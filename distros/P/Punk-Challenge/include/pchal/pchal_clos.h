#ifndef PCHAL_CLOS_H
#define PCHAL_CLOS_H

/* Closures, calls into Perl, and the small predicates the rest of this
 * distribution reads options and the application with.
 *
 * The closure device is Punk-Feed's pfeed_closure, which is a copy of Punk's
 * private punk_closure: a CV built with newXS carrying captured SVs in
 * PERL_MAGIC_ext. Punk does not export it - pk_abi.h is an observer
 * interface and says so - so a plugin that wants a body with state carries
 * its own. The capture is an AV, so a body may capture [app] or [app, bits]
 * with the same device.
 *
 * Must be included after pchal_compat.h.
 */

/* ---- predicates and small readers -------------------------------------- */

static int pchal_is_hash(SV *sv)
{
    return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV;
}

static int pchal_is_array(SV *sv)
{
    return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV;
}

static int pchal_is_code(SV *sv)
{
    return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV;
}

/* The Punk::App's own hash. It is a blessed hashref and we want the object,
 * so SvTYPE matching it is the point rather than the trap it usually is. */
static HV *pchal_app_hv(pTHX_ SV *app)
{
    PERL_UNUSED_CONTEXT;
    return pchal_is_hash(app) ? (HV *)SvRV(app) : NULL;
}

/* One key of a hash, or NULL. Borrowed, not owned. A key holding undef is
 * "not there": an option set to undef is an option left at its default. */
static SV *pchal_hget(pTHX_ HV *h, const char *k)
{
    SV **e = h ? hv_fetch(h, k, (I32)strlen(k), 0) : NULL;
    PERL_UNUSED_CONTEXT;
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

/* An app-hash slot that is an AV, created empty on first ask. */
static AV *pchal_app_av(pTHX_ HV *h, const char *k)
{
    SV *v = pchal_hget(aTHX_ h, k);
    if (pchal_is_array(v)) return (AV *)SvRV(v);
    {
        AV *av = newAV();
        (void)hv_store(h, k, (I32)strlen(k), newRV_noinc((SV *)av), 0);
        return av;
    }
}

/* A context is a blessed AV; this is its environment slot. Punk's own
 * layout (punk/punk_context.h), which pk_abi.h exposes as env_of - the
 * accessor it does offer, and the reason this reads the slot directly rather
 * than paying a method call per header. Fixed by Punk's ABI rather than by
 * this file: the slot moving would be a change pk_abi's version guards would
 * have to announce. */
enum { PCHAL_CX_ENV = 0 };

static SV *pchal_cx_slot(pTHX_ SV *c, I32 slot)
{
    AV *av;
    SV **e;
    PERL_UNUSED_CONTEXT;
    if (!(c && SvROK(c) && SvTYPE(SvRV(c)) == SVt_PVAV)) return NULL;
    av = (AV *)SvRV(c);
    e = av_fetch(av, slot, 0);
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

/* One PSGI environment key, borrowed, or NULL. */
static SV *pchal_env(pTHX_ SV *c, const char *k)
{
    SV *env = pchal_cx_slot(aTHX_ c, PCHAL_CX_ENV);
    if (!pchal_is_hash(env)) return NULL;
    return pchal_hget(aTHX_ (HV *)SvRV(env), k);
}

/* ---- closures ------------------------------------------------------------ */

typedef struct { AV *cap; } pchal_clos_t;

static int pchal_clos_free(pTHX_ SV *sv, MAGIC *mg)
{
    pchal_clos_t *c = (pchal_clos_t *)mg->mg_ptr;
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_VAR(sv);
    if (c) {
        if (c->cap) SvREFCNT_dec((SV *)c->cap);
        Safefree(c);
    }
    return 0;
}

static MGVTBL pchal_clos_vtbl = { NULL, NULL, NULL, NULL, pchal_clos_free,
                                  NULL, NULL, NULL };

/* Takes ownership of cap. */
static SV *pchal_closure(pTHX_ XSUBADDR_t body, AV *cap)
{
    CV *cv = (CV *)newXS(NULL, body, (char *)__FILE__);
    pchal_clos_t *c;

    Newxz(c, 1, pchal_clos_t);
    c->cap = cap;
    sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &pchal_clos_vtbl, (char *)c, 0);
    return newRV_noinc((SV *)cv);
}

static AV *pchal_cap_of(pTHX_ CV *cv)
{
    MAGIC *mg = mg_findext((SV *)cv, PERL_MAGIC_ext, &pchal_clos_vtbl);
    AV *cap = mg ? ((pchal_clos_t *)mg->mg_ptr)->cap : NULL;
    if (!cap) croak("Punk::Plugin::Challenge: a closure lost its capture");
    return cap;
}

/* One capture slot, borrowed. NULL for an empty slot or an undef in it. */
static SV *pchal_cap_slot(pTHX_ CV *cv, SSize_t i)
{
    AV *cap = pchal_cap_of(aTHX_ cv);
    SV **e = av_fetch(cap, i, 0);
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

/* ---- calling back into Perl -------------------------------------------------
 * Every call hands back a NEW SV (+1) - a copy of the result, undef when there
 * was none - so a caller owns what it holds and mortalises it. */

/* $inv->$meth(@argv) */
static SV *pchal_call(pTHX_ SV *inv, const char *meth, SV **argv, int argc)
{
    dSP;
    int count, i;
    SV *ret;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, argc + 1);
    PUSHs(inv);
    for (i = 0; i < argc; i++) PUSHs(argv[i]);
    PUTBACK;
    count = call_method(meth, G_SCALAR);
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

/* $inv->$meth(@argv) in LIST context: the FIRST value returned, or undef.
 * For a method whose first return is the answer and whose others are
 * detail - rate_hit's ($ok, $remaining, $reset) - which a scalar-context
 * call would collapse to the LAST of. */
static SV *pchal_call_first(pTHX_ SV *inv, const char *meth, SV **argv,
                            int argc)
{
    dSP;
    int count, i;
    SV *ret = NULL;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, argc + 1);
    PUSHs(inv);
    for (i = 0; i < argc; i++) PUSHs(argv[i]);
    PUTBACK;
    count = call_method(meth, G_LIST);
    SPAGAIN;
    if (count > 0) {
        SV **first = SP - count + 1;
        ret = newSVsv(*first);
        SP -= count;
    }
    else ret = newSV(0);
    PUTBACK; FREETMPS; LEAVE;
    return ret;
}

/* $inv->$meth(@argv) under G_EVAL: the value, or NULL with *failed set and
 * the reason in ERRSV. For a method that croaks on the network's input -
 * a request body that is not the JSON its Content-Type promised. Without
 * G_EVAL that croak longjmps past the ENTER/SAVETMPS in pchal_call and
 * leaves the Perl stack short, and the damage surfaces later as garbage
 * read out of an unrelated array. */
static SV *pchal_try(pTHX_ SV *inv, const char *meth, SV **argv, int argc,
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

/* $code->(@argv) in scalar context: a new SV. */
static SV *pchal_call_code(pTHX_ SV *code, SV **argv, int argc)
{
    dSP;
    int count, i;
    SV *ret;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, argc);
    for (i = 0; i < argc; i++) PUSHs(argv[i]);
    PUTBACK;
    count = call_sv(code, G_SCALAR);
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

/* Does this class or object have that method? An ordinary `can`, so
 * inheritance and AUTOLOAD behave as they would anywhere else. */
static int pchal_can(pTHX_ SV *obj, const char *meth)
{
    SV *m = sv_2mortal(newSVpv(meth, 0));
    SV *r = sv_2mortal(pchal_call(aTHX_ obj, "can", &m, 1));
    return (r && SvTRUE(r)) ? 1 : 0;
}

#endif /* PCHAL_CLOS_H */

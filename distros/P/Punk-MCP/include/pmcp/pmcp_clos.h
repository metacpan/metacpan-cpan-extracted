/* pmcp_clos.h - closures, and every call this dist makes into Perl.
 *
 * Needs: pmcp.h, pmcp_compat.h.
 *
 * The closure is Punk-Feed's pfeed_closure, which is Punk's private
 * punk_closure: a CV built with newXS carrying an AV of captured SVs in
 * PERL_MAGIC_ext. Punk does not export it, so a plugin carries its own.
 *
 * Every call into Perl goes through pmcp_call. The rules it keeps, in one place
 * so no later header has to remember them:
 *
 *   - With an err slot, the call runs under G_EVAL. A die comes back as a new
 *     SV in *err (+1, the caller owns it) and the value and scope stacks are as
 *     they were. Never JMPENV_PUSH: catching the jump is not the problem,
 *     unwinding the stack bookkeeping is, and only G_EVAL does that (the stack
 *     corruption recorded in plan_maat_mcp 02).
 *   - Without one, a die propagates to the caller's caller. Only for calls
 *     where dying is the intended answer, such as a bad schema at boot.
 *   - The result is copied into a plain SV inside the ENTER/LEAVE window and
 *     handed back +1. A value mortalised inside the window is freed by its
 *     FREETMPS before the caller reads it (the logging trap in project_punk).
 *   - A call into Perl can grow the value stack, and a grown stack is
 *     reallocated. pmcp_call re-reads SP itself, but an XSUB that calls it and
 *     then pushes must re-derive its own: SP = PL_stack_base + ax - 1, not
 *     SPAGAIN, which in a PPCODE leaves SP above the arguments.
 */

#ifndef PMCP_CLOS_H
#define PMCP_CLOS_H

/* ---- closures ------------------------------------------------------------ */

typedef struct { AV *cap; } pmcp_clos_t;

static int pmcp_clos_free(pTHX_ SV *sv, MAGIC *mg)
{
    pmcp_clos_t *c = (pmcp_clos_t *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (c) {
        if (c->cap) SvREFCNT_dec((SV *)c->cap);
        Safefree(c);
    }
    return 0;
}

static MGVTBL pmcp_clos_vtbl = { NULL, NULL, NULL, NULL, pmcp_clos_free,
                                 NULL, NULL, NULL };

/* A code ref whose body is `body` and whose capture is `cap`. Takes ownership
 * of cap. Returns +1. */
static SV *pmcp_closure(pTHX_ XSUBADDR_t body, AV *cap)
{
    CV *cv = (CV *)newXS(NULL, body, (char *)__FILE__);
    pmcp_clos_t *c;

    Newxz(c, 1, pmcp_clos_t);
    c->cap = cap;
    sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &pmcp_clos_vtbl, (char *)c, 0);
    return newRV_noinc((SV *)cv);
}

/* One capture slot, borrowed, or NULL when the slot is empty. */
static SV *pmcp_cap(pTHX_ CV *cv, SSize_t i)
{
    MAGIC *mg = pmcp_mg_findext(aTHX_ (SV *)cv, PERL_MAGIC_ext, &pmcp_clos_vtbl);
    AV *cap = mg ? ((pmcp_clos_t *)mg->mg_ptr)->cap : NULL;
    SV **e;
    if (!cap) croak(PMCP_DIST ": a closure lost its capture");
    e = av_fetch(cap, i, 0);
    return (e && *e) ? *e : NULL;
}

/* The body t/02 builds a closure from: returns its first capture. */
XS_INTERNAL(pmcp_clos_echo)
{
    dXSARGS;
    SV *v = pmcp_cap(aTHX_ cv, 0);
    PERL_UNUSED_VAR(items);
    ST(0) = v ? v : &PL_sv_undef;
    XSRETURN(1);
}

/* ---- calls into Perl ----------------------------------------------------- */

/* The one call site. Exactly one of meth and code is set: meth calls
 * $inv->$meth(@argv), code calls $code->(@argv) with inv, when given, as the
 * first argument. flags is G_SCALAR or G_LIST. G_SCALAR gives the value, or
 * undef when there was none. G_LIST gives an array ref of the values.
 *
 * argv may point into the Perl stack (an XSUB passing &ST(n)). The EXTEND
 * below can reallocate that stack, so the pointers are copied out first.
 *
 * Returns +1. On a caught die returns NULL and sets *err (+1). */
static SV *pmcp_call(pTHX_ SV *inv, const char *meth, SV *code,
                     SV **argv, int argc, I32 flags, SV **err)
{
    dSP;
    I32 count, i;
    SV *ret = NULL;
    SV *small[8];
    SV **args = small;
    /* G_WANT, never a bare bit test: G_SCALAR is 2 and G_LIST is 3, so
     * flags & G_LIST is true for a scalar call. */
    I32 want = ((flags & G_WANT) == G_LIST) ? G_LIST : G_SCALAR;

    if (err) *err = NULL;
    ENTER; SAVETMPS;
    if (argc > (int)(sizeof small / sizeof small[0])) {
        Newx(args, argc, SV *);
        SAVEFREEPV(args);
    }
    for (i = 0; i < argc; i++) args[i] = argv[i];
    PUSHMARK(SP);
    EXTEND(SP, argc + 1);
    if (inv) PUSHs(inv);
    for (i = 0; i < argc; i++) PUSHs(args[i]);
    PUTBACK;

    if (code) count = call_sv(code, want | (err ? G_EVAL : 0));
    else      count = call_method(meth, want | (err ? G_EVAL : 0));
    SPAGAIN;

    if (err && SvTRUE(ERRSV)) {
        while (count-- > 0) (void)POPs;
        *err = newSVsv(ERRSV);
    }
    else if (want == G_LIST) {
        AV *out = newAV();
        if (count > 0) av_extend(out, count - 1);
        for (i = count - 1; i >= 0; i--) {
            SV *top = POPs;
            (void)av_store(out, i, newSVsv(top));
        }
        ret = newRV_noinc((SV *)out);
    }
    else {
        ret = count > 0 ? newSVsv(POPs) : newSV(0);
        while (--count > 0) (void)POPs;
    }

    PUTBACK; FREETMPS; LEAVE;
    return ret;
}

/* $inv->$meth(@argv). See pmcp_call for flags, err and ownership. */
static SV *pmcp_call_method(pTHX_ SV *inv, const char *meth, SV **argv,
                            int argc, I32 flags, SV **err)
{
    return pmcp_call(aTHX_ inv, meth, NULL, argv, argc, flags, err);
}

/* $code->(@argv). See pmcp_call for flags, err and ownership. */
static SV *pmcp_call_sv(pTHX_ SV *code, SV **argv, int argc, I32 flags,
                        SV **err)
{
    return pmcp_call(aTHX_ NULL, NULL, code, argv, argc, flags, err);
}

/* require Module, under G_EVAL. Returns 1, or 0 with *err set (+1) when err is
 * given. A string eval, because require needs a bareword to map :: to /. */
static int pmcp_require(pTHX_ const char *module, SV **err)
{
    SV *src = newSVpvf("require %s; 1", module);
    int ok;

    if (err) *err = NULL;
    ENTER; SAVETMPS;
    (void)eval_sv(src, G_DISCARD | G_EVAL);
    SvREFCNT_dec(src);
    ok = !SvTRUE(ERRSV);
    if (!ok && err) *err = newSVsv(ERRSV);
    FREETMPS; LEAVE;
    return ok;
}

/* ---- predicates ---------------------------------------------------------- */

static int pmcp_is_hash(SV *sv)
{
    return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV;
}

static int pmcp_is_array(SV *sv)
{
    return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV;
}

static int pmcp_is_code(SV *sv)
{
    return sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV;
}

#endif /* PMCP_CLOS_H */

/* punk_future.h - Punk::Future, an async result, in C.
 *
 * A Future.pm-compatible value that runs on the Hyperman worker loop when one
 * is live and blocks (synchronously) anywhere else, so app code can start a
 * timer or defer a response and hand the future back - Punk's dispatcher
 * already awaits any Future-compatible return (then / on_ready / get).
 *
 * Two backends behind one class: PF_LOOP wraps a companion Hyperman::Future
 * (via hm_abi.h) purely as a run_until wait-token and arms timers on the loop;
 * PF_BLOCK is self-contained (a settle + reaction queue, timers that sleep on
 * get). The future *semantics* - state, the reaction queue, then-chaining and
 * the combinators - are one implementation over the struct; the backend only
 * drives settling and awaiting.
 *
 * Built in stages; this file currently covers the core (create / done / fail /
 * state / on_ready|on_done|on_fail / get, block mode).
 *
 * Must be included after punk_context.h (pcx_* call helpers) and
 * punk_wsconn.h (punk_hm, the ABI accessor).
 */

#ifndef PUNK_FUTURE_H
#define PUNK_FUTURE_H

#include <sys/time.h>       /* gettimeofday / select - the block-mode timer */

/* settle states - the same integer values as HM_ABI_PENDING.. so a loop-mode
 * future can mirror its companion's state without translation */
enum { PF_PENDING = 0, PF_DONE = 1, PF_FAILED = 2, PF_CANCELLED = 3 };

/* reaction kinds queued against a pending future */
enum { PFR_ON_READY = 0, PFR_ON_DONE = 1, PFR_ON_FAIL = 2 };

typedef struct punk_future {
    int   state;          /* PF_* */
    int   is_loop;        /* PF_LOOP vs PF_BLOCK */
    AV   *vals;           /* the done values, or the failure values */
    AV   *reactions;      /* flat [kind0, cb0, kind1, cb1, ...], lazily made */

    /* loop backend (stage D) */
    const hm_abi *abi;
    void *loop;
    hm_abi_timer *timer;  /* a live loop timer to cancel on settle/free */
    SV   *self_rv;        /* strong self while a loop driver is pending */

    SV   *on_fire;        /* a defer callback to run when a loop timer fires */
} punk_future;

static void pf_detect(pTHX_ punk_future *pf);   /* stage D: pick the backend */

static punk_future *pf_of(pTHX_ SV *self) {
    if (!SvROK(self) || !SvIOK(SvRV(self)))
        croak("Punk::Future: not a future");
    return (punk_future *)INT2PTR(void *, SvIV(SvRV(self)));
}

static punk_future *pf_new(pTHX) {
    punk_future *pf;
    Newxz(pf, 1, punk_future);
    pf->state = PF_PENDING;
    pf_detect(aTHX_ pf);       /* loop-backed when a worker loop is live */
    return pf;
}

static SV *pf_bless(pTHX_ punk_future *pf, const char *class) {
    return sv_setref_iv(newSV(0), class, PTR2IV(pf));
}

/* call $cb->(@argv), trapping a die (a settled callback must not unwind the
 * loop or the caller); a failure is warned, matching Future's "lost" report. */
static void pf_invoke(pTHX_ SV *cb, SV **argv, int argc) {
    dSP;
    int i;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, argc);
    for (i = 0; i < argc; i++) PUSHs(argv[i]);
    PUTBACK;
    call_sv(cb, G_VOID | G_EVAL | G_DISCARD);
    SPAGAIN;
    if (SvTRUE(ERRSV))
        warn("Punk::Future: callback died: %s", SvPV_nolen(ERRSV));
    PUTBACK; FREETMPS; LEAVE;
}

/* the values to hand a reaction of this kind: on_ready gets [$self], the
 * others get the settled values. Returns argc; fills *argv (borrowed). */
static int pf_react_args(pTHX_ punk_future *pf, SV *self, int kind,
                         SV *self_slot[1], SV ***argv) {
    if (kind == PFR_ON_READY) {
        self_slot[0] = self;
        *argv = self_slot;
        return 1;
    }
    *argv = pf->vals ? AvARRAY(pf->vals) : NULL;
    return pf->vals ? (int)(av_len(pf->vals) + 1) : 0;
}

/* run a single queued reaction if its kind matches the settled state */
static void pf_fire_one(pTHX_ punk_future *pf, SV *self, int kind, SV *cb) {
    int run = (kind == PFR_ON_READY)
           || (kind == PFR_ON_DONE && pf->state == PF_DONE)
           || (kind == PFR_ON_FAIL && pf->state == PF_FAILED);
    if (run) {
        SV *self_slot[1], **argv;
        int argc = pf_react_args(aTHX_ pf, self, kind, self_slot, &argv);
        pf_invoke(aTHX_ cb, argv, argc);
    }
}

/* drain the reaction queue after settling */
static void pf_fire(pTHX_ punk_future *pf, SV *self) {
    AV *q = pf->reactions;
    SSize_t i, n;
    if (!q) return;
    pf->reactions = NULL;              /* detach: reactions added while firing
                                          are fired immediately, not requeued */
    n = av_len(q) + 1;
    for (i = 0; i + 1 < n; i += 2) {
        SV **kp = av_fetch(q, i, 0);
        SV **cp = av_fetch(q, i + 1, 0);
        if (kp && *kp && cp && *cp)
            pf_fire_one(aTHX_ pf, self, (int)SvIV(*kp), *cp);
    }
    SvREFCNT_dec((SV *)q);
}

/* Settle a pending future (no-op if already settled, like the Hyperman ABI).
 * Takes ownership of vals (an AV, or NULL for none). self is borrowed. */
static void pf_settle(pTHX_ punk_future *pf, SV *self, int state, AV *vals) {
    if (pf->state != PF_PENDING) { if (vals) SvREFCNT_dec((SV *)vals); return; }
    pf->state = state;
    pf->vals  = vals ? vals : newAV();
    if (pf->timer && pf->abi && pf->loop) {
        pf->abi->timer_cancel(aTHX_ pf->loop, pf->timer);
        pf->timer = NULL;
    }
    pf_fire(aTHX_ pf, self);
    if (pf->self_rv) { SV *s = pf->self_rv; pf->self_rv = NULL; SvREFCNT_dec(s); }
}

/* register a reaction; fire it at once if the future is already settled */
static void pf_react(pTHX_ punk_future *pf, SV *self, int kind, SV *cb) {
    if (pf->state != PF_PENDING) {
        pf_fire_one(aTHX_ pf, self, kind, cb);
        return;
    }
    if (!pf->reactions) pf->reactions = newAV();
    av_push(pf->reactions, newSViv(kind));
    av_push(pf->reactions, newSVsv(cb));
}

static void pf_free(pTHX_ punk_future *pf) {
    if (!pf) return;
    if (pf->timer && pf->abi && pf->loop)
        pf->abi->timer_cancel(aTHX_ pf->loop, pf->timer);
    if (pf->vals)      SvREFCNT_dec((SV *)pf->vals);
    if (pf->reactions) SvREFCNT_dec((SV *)pf->reactions);
    if (pf->self_rv)   SvREFCNT_dec(pf->self_rv);
    if (pf->on_fire)   SvREFCNT_dec(pf->on_fire);
    Safefree(pf);
}

/* ---- chaining: then / else / followed_by (stage B) ------------------------ *
 * Each returns a new future the callback's result settles; a callback that
 * returns a future is adopted (the new future mirrors it). Reactions are
 * ordinary on_ready callbacks - the chain logic is a captured C closure
 * (punk_static.h's punk_closure), so no new reaction machinery is needed. */

/* settle g (a Punk::Future) with argc borrowed values */
static void pf_settle_argv(pTHX_ SV *g, int state, SV **argv, int argc) {
    AV *v = newAV();
    int i;
    for (i = 0; i < argc; i++) av_push(v, newSVsv(argv[i]));
    pf_settle(aTHX_ pf_of(aTHX_ g), g, state, v);
}

/* blessed and future-compatible (has on_ready)? */
static int pf_is_future(pTHX_ SV *sv) {
    return SvROK(sv) && SvOBJECT(SvRV(sv)) && pcx_can(aTHX_ sv, "on_ready");
}

/* call $cb->(@argv) in list context under a trap; push results onto out.
 * Returns 1 if it died (ERRSV holds the error), else 0. */
static int pf_call_list(pTHX_ SV *cb, SV **argv, int argc, AV *out) {
    dSP; int count, i, died;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, argc);
    for (i = 0; i < argc; i++) PUSHs(argv[i]);
    PUTBACK;
    count = call_sv(cb, G_ARRAY | G_EVAL);
    SPAGAIN;
    died = SvTRUE(ERRSV) ? 1 : 0;
    if (!died) for (i = 0; i < count; i++) av_push(out, newSVsv(SP[1 - count + i]));
    SP -= count; PUTBACK;
    FREETMPS; LEAVE;
    return died;
}

/* when a settled source R is adopted, mirror its outcome into g. Capture [g]. */
XS_INTERNAL(pf_adopt_cb);
XS_INTERNAL(pf_adopt_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *g = *av_fetch(cap, 0, 0);
    SV *R = items > 0 ? ST(0) : &PL_sv_undef;
    SV *isf = pcx_call_meth(aTHX_ R, "is_failed", NULL, 0, 1);
    SV *isd = isf && SvTRUE(isf) ? NULL
              : pcx_call_meth(aTHX_ R, "is_done", NULL, 0, 1);
    if (isf && SvTRUE(isf)) {
        SV *fl = pcx_call_meth(aTHX_ R, "failure", NULL, 0, 1);
        SV *a = fl ? fl : &PL_sv_undef;
        pf_settle_argv(aTHX_ g, PF_FAILED, &a, 1);
        if (fl) SvREFCNT_dec(fl);
    }
    else if (isd && SvTRUE(isd)) {
        dSP; int count, i; AV *out = (AV *)sv_2mortal((SV *)newAV());
        int n, j; SV **av2;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(R); PUTBACK;
        count = call_method("get", G_ARRAY | G_EVAL);
        SPAGAIN;
        if (!SvTRUE(ERRSV))
            for (i = 0; i < count; i++) av_push(out, newSVsv(SP[1 - count + i]));
        SP -= count; PUTBACK; FREETMPS; LEAVE;
        n = (int)(av_len(out) + 1);
        Newx(av2, n > 0 ? n : 1, SV *);
        for (j = 0; j < n; j++) av2[j] = *av_fetch(out, j, 0);
        pf_settle_argv(aTHX_ g, PF_DONE, av2, n);
        Safefree(av2);
    }
    else {
        pf_settle(aTHX_ pf_of(aTHX_ g), g, PF_CANCELLED, NULL);
    }
    if (isf) SvREFCNT_dec(isf);
    if (isd) SvREFCNT_dec(isd);
    XSRETURN_EMPTY;
}

/* g adopts R: register R->on_ready to mirror R into g (fires now if settled) */
static void pf_adopt(pTHX_ SV *g, SV *R) {
    AV *cap = newAV();
    SV *clos, *argv[1], *r;
    av_push(cap, newSVsv(g));
    clos = sv_2mortal(punk_closure(aTHX_ pf_adopt_cb, cap));
    argv[0] = clos;
    r = pcx_call_meth(aTHX_ R, "on_ready", argv, 1, 0);
    if (r) SvREFCNT_dec(r);
}

/* the on_ready reaction a then/else/followed_by installs. Capture
 * [g, on_done|undef, on_fail|undef, mode] (mode 1 = followed_by). */
XS_INTERNAL(pf_chain_cb);
XS_INTERNAL(pf_chain_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *g       = *av_fetch(cap, 0, 0);
    SV *done_cb = *av_fetch(cap, 1, 0);
    SV *fail_cb = *av_fetch(cap, 2, 0);
    int mode    = (int)SvIV(*av_fetch(cap, 3, 0));
    SV *selff = items > 0 ? ST(0) : &PL_sv_undef;
    punk_future *sf = pf_of(aTHX_ selff);
    SV *cb = NULL, **args = NULL, *self_slot[1];
    int argc = 0;

    if (sf->state == PF_CANCELLED) {
        pf_settle(aTHX_ pf_of(aTHX_ g), g, PF_CANCELLED, NULL);
        XSRETURN_EMPTY;
    }
    if (mode == 1) {                              /* followed_by($self) */
        cb = done_cb; self_slot[0] = selff; args = self_slot; argc = 1;
    }
    else if (sf->state == PF_DONE) {
        if (SvOK(done_cb)) {
            cb = done_cb;
            args = sf->vals ? AvARRAY(sf->vals) : NULL;
            argc = sf->vals ? (int)(av_len(sf->vals) + 1) : 0;
        }
        else {                                    /* pass the value through */
            pf_settle_argv(aTHX_ g, PF_DONE,
                sf->vals ? AvARRAY(sf->vals) : NULL,
                sf->vals ? (int)(av_len(sf->vals) + 1) : 0);
            XSRETURN_EMPTY;
        }
    }
    else {                                        /* PF_FAILED */
        if (SvOK(fail_cb)) {
            cb = fail_cb;
            args = sf->vals ? AvARRAY(sf->vals) : NULL;
            argc = sf->vals ? (int)(av_len(sf->vals) + 1) : 0;
        }
        else {                                    /* pass the failure through */
            pf_settle_argv(aTHX_ g, PF_FAILED,
                sf->vals ? AvARRAY(sf->vals) : NULL,
                sf->vals ? (int)(av_len(sf->vals) + 1) : 0);
            XSRETURN_EMPTY;
        }
    }
    {
        AV *out = (AV *)sv_2mortal((SV *)newAV());
        int died = pf_call_list(aTHX_ cb, args, argc, out);
        if (died) {
            SV *e = sv_2mortal(newSVsv(ERRSV));
            pf_settle_argv(aTHX_ g, PF_FAILED, &e, 1);
        }
        else {
            int n = (int)(av_len(out) + 1);
            if (n == 1 && pf_is_future(aTHX_ *av_fetch(out, 0, 0)))
                pf_adopt(aTHX_ g, *av_fetch(out, 0, 0));
            else {
                int j; SV **av2;
                Newx(av2, n > 0 ? n : 1, SV *);
                for (j = 0; j < n; j++) av2[j] = *av_fetch(out, j, 0);
                pf_settle_argv(aTHX_ g, PF_DONE, av2, n);
                Safefree(av2);
            }
        }
    }
    XSRETURN_EMPTY;
}

/* build the derived future and wire the chain reaction; returns g (+1) */
static SV *pf_make_chain(pTHX_ SV *self, SV *done_cb, SV *fail_cb, int mode) {
    punk_future *sf = pf_of(aTHX_ self);
    punk_future *pg = pf_new(aTHX);
    SV *g, *clos;
    AV *cap;
    pg->is_loop = sf->is_loop; pg->abi = sf->abi; pg->loop = sf->loop;
    g = pf_bless(aTHX_ pg, "Punk::Future");
    cap = newAV();
    av_push(cap, newSVsv(g));
    av_push(cap, (done_cb && SvOK(done_cb)) ? newSVsv(done_cb) : newSV(0));
    av_push(cap, (fail_cb && SvOK(fail_cb)) ? newSVsv(fail_cb) : newSV(0));
    av_push(cap, newSViv(mode));
    clos = sv_2mortal(punk_closure(aTHX_ pf_chain_cb, cap));
    pf_react(aTHX_ sf, self, PFR_ON_READY, clos);
    return g;
}

/* ---- combinators: needs_all / needs_any / wait_all / wait_any (stage C) --- *
 * A control AV [ G, mode, remaining, results, inputs, total ] is shared (by
 * ref) across one on_ready reaction per input; each settling input updates it
 * and settles G when the mode's condition is met. G's no-op-if-settled keeps
 * "first wins" races safe. The control holds every input so none is freed while
 * the combinator is pending. */
enum { PFC_NEEDS_ALL = 0, PFC_NEEDS_ANY = 1, PFC_WAIT_ALL = 2, PFC_WAIT_ANY = 3 };

/* input->get in list context (input is settled done); push onto out */
static void pf_get_list(pTHX_ SV *input, AV *out) {
    dSP; int count, i;
    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, 1); PUSHs(input); PUTBACK;
    count = call_method("get", G_ARRAY | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV))
        for (i = 0; i < count; i++) av_push(out, newSVsv(SP[1 - count + i]));
    SP -= count; PUTBACK; FREETMPS; LEAVE;
}

/* one input of a combinator settled; capture [control_ref, index] */
XS_INTERNAL(pf_comb_cb);
XS_INTERNAL(pf_comb_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    AV *ctl = (AV *)SvRV(*av_fetch(cap, 0, 0));
    int idx  = (int)SvIV(*av_fetch(cap, 1, 0));
    SV *G    = *av_fetch(ctl, 0, 0);
    int mode = (int)SvIV(*av_fetch(ctl, 1, 0));
    SV *remsv = *av_fetch(ctl, 2, 0);
    SV *input = items > 0 ? ST(0) : &PL_sv_undef;
    SV *isf = pcx_call_meth(aTHX_ input, "is_failed", NULL, 0, 1);
    int failed = isf && SvTRUE(isf);
    if (isf) SvREFCNT_dec(isf);

    if (mode == PFC_NEEDS_ALL) {
        if (failed) {
            SV *fl = pcx_call_meth(aTHX_ input, "failure", NULL, 0, 1);
            SV *a = fl ? fl : &PL_sv_undef;
            pf_settle_argv(aTHX_ G, PF_FAILED, &a, 1);
            if (fl) SvREFCNT_dec(fl);
        }
        else {
            AV *results = (AV *)SvRV(*av_fetch(ctl, 3, 0));
            AV *v = newAV();
            int rem;
            pf_get_list(aTHX_ input, v);
            (void)av_store(results, idx, newRV_noinc((SV *)v));
            rem = (int)SvIV(remsv) - 1; sv_setiv(remsv, rem);
            if (rem == 0) {
                AV *flat = newAV();
                SSize_t i, n = av_len(results) + 1, j, m;
                for (i = 0; i < n; i++) {
                    SV **rp = av_fetch(results, i, 0);
                    AV *ra = (rp && *rp && SvROK(*rp)) ? (AV *)SvRV(*rp) : NULL;
                    m = ra ? av_len(ra) + 1 : 0;
                    for (j = 0; j < m; j++) av_push(flat, newSVsv(*av_fetch(ra, j, 0)));
                }
                pf_settle(aTHX_ pf_of(aTHX_ G), G, PF_DONE, flat);
            }
        }
    }
    else if (mode == PFC_NEEDS_ANY) {
        if (!failed) {
            AV *v = newAV();
            pf_get_list(aTHX_ input, v);
            pf_settle(aTHX_ pf_of(aTHX_ G), G, PF_DONE, v);
        }
        else {
            int rem = (int)SvIV(remsv) - 1; sv_setiv(remsv, rem);
            if (rem == 0) {
                SV *fl = pcx_call_meth(aTHX_ input, "failure", NULL, 0, 1);
                SV *a = fl ? fl : &PL_sv_undef;
                pf_settle_argv(aTHX_ G, PF_FAILED, &a, 1);
                if (fl) SvREFCNT_dec(fl);
            }
        }
    }
    else if (mode == PFC_WAIT_ALL) {
        int rem = (int)SvIV(remsv) - 1; sv_setiv(remsv, rem);
        if (rem == 0) {
            AV *inputs = (AV *)SvRV(*av_fetch(ctl, 4, 0));
            AV *copy = newAV();
            SSize_t i, n = av_len(inputs) + 1;
            for (i = 0; i < n; i++) av_push(copy, newSVsv(*av_fetch(inputs, i, 0)));
            pf_settle(aTHX_ pf_of(aTHX_ G), G, PF_DONE, copy);
        }
    }
    else {                                        /* PFC_WAIT_ANY */
        SV *a = input;
        pf_settle_argv(aTHX_ G, PF_DONE, &a, 1);
    }
    XSRETURN_EMPTY;
}

/* build a combinator over @inputs (borrowed SV** of length n); returns G (+1).
 * G is created by the caller (so it can pick the backend) and passed in. */
static void pf_combine(pTHX_ SV *G, int mode, SV **inputs, int n) {
    AV *ctl = newAV();
    AV *inav = newAV(), *results = newAV();
    int i, rem;
    for (i = 0; i < n; i++) av_push(inav, newSVsv(inputs[i]));
    rem = (mode == PFC_WAIT_ANY) ? (n ? 1 : 0) : n;
    av_push(ctl, newSVsv(G));                     /* 0 G          */
    av_push(ctl, newSViv(mode));                  /* 1 mode       */
    av_push(ctl, newSViv(rem));                   /* 2 remaining  */
    av_push(ctl, newRV_noinc((SV *)results));     /* 3 results    */
    av_push(ctl, newRV_noinc((SV *)inav));        /* 4 inputs     */
    av_push(ctl, newSViv(n));                     /* 5 total      */
    if (n == 0) {                                 /* degenerate cases */
        if (mode == PFC_NEEDS_ANY)
            pf_settle(aTHX_ pf_of(aTHX_ G), G, PF_FAILED,
                      NULL);                       /* nothing can succeed */
        else
            pf_settle(aTHX_ pf_of(aTHX_ G), G, PF_DONE, newAV());
        SvREFCNT_dec((SV *)ctl);
        return;
    }
    {
        SV *ctl_rv = sv_2mortal(newRV_noinc((SV *)ctl));
        for (i = 0; i < n; i++) {
            AV *cap = newAV();
            SV *clos, *argv[1], *r;
            av_push(cap, newSVsv(ctl_rv));
            av_push(cap, newSViv(i));
            clos = sv_2mortal(punk_closure(aTHX_ pf_comb_cb, cap));
            argv[0] = clos;
            r = pcx_call_meth(aTHX_ inputs[i], "on_ready", argv, 1, 0);
            if (r) SvREFCNT_dec(r);
        }
    }
}

/* ---- loop mode, timers and awaiting (stage D) ----------------------------- *
 * A future is loop-backed when a Hyperman worker loop is live at creation. The
 * loop only drives things: timers arm through the ABI, and get/await pump the
 * loop through a companion Hyperman::Future used purely as a run_until token
 * (the ABI cannot read a future's values back, so the wrapper's own struct
 * stays authoritative). Off-loop a timer just sleeps and settles at once. */

static void pf_detect(pTHX_ punk_future *pf) {
    const hm_abi *A = punk_hm(aTHX);
    void *loop = A ? A->cur_loop(aTHX) : NULL;
    if (loop) { pf->is_loop = 1; pf->abi = A; pf->loop = loop; }
}

static double pf_now(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (double)tv.tv_sec + (double)tv.tv_usec / 1e6;
}
static void pf_sleep(double secs) {
    struct timeval tv;
    if (secs <= 0) return;
    tv.tv_sec  = (long)secs;
    tv.tv_usec = (long)((secs - (double)tv.tv_sec) * 1e6);
    (void)select(0, NULL, NULL, NULL, &tv);
}

/* run $cb->(@args) and settle self with the result: a returned future is
 * adopted, a die fails self, otherwise self is done with the values */
static void pf_run_into(pTHX_ SV *self, SV *cb, SV **args, int argc) {
    AV *out = (AV *)sv_2mortal((SV *)newAV());
    int died = pf_call_list(aTHX_ cb, args, argc, out);
    if (died) {
        SV *e = sv_2mortal(newSVsv(ERRSV));
        pf_settle_argv(aTHX_ self, PF_FAILED, &e, 1);
    }
    else {
        int n = (int)(av_len(out) + 1);
        if (n == 1 && pf_is_future(aTHX_ *av_fetch(out, 0, 0)))
            pf_adopt(aTHX_ self, *av_fetch(out, 0, 0));
        else {
            int j; SV **a;
            Newx(a, n > 0 ? n : 1, SV *);
            for (j = 0; j < n; j++) a[j] = *av_fetch(out, j, 0);
            pf_settle_argv(aTHX_ self, PF_DONE, a, n);
            Safefree(a);
        }
    }
}

/* a loop timer fired: run the defer callback if any, else settle done */
static void pf_timer_cb(pTHX_ void *ud) {
    punk_future *pf = (punk_future *)ud;
    SV *self = pf->self_rv;
    pf->timer = NULL;                       /* it fired; nothing to cancel */
    if (!self) return;
    if (pf->on_fire) pf_run_into(aTHX_ self, pf->on_fire, NULL, 0);
    else             pf_settle(aTHX_ pf, self, PF_DONE, newAV());
}

static void pf_arm_timer(pTHX_ punk_future *pf, SV *self, double secs) {
    pf->self_rv = newSVsv(self);            /* keep alive until it fires */
    pf->timer   = pf->abi->timer(aTHX_ pf->loop, secs, pf_timer_cb, pf);
}

/* settle a companion Hyperman::Future so a run_until awaiting it returns.
 * Capture [ $companion ]. */
XS_INTERNAL(pf_wake_hf_cb);
XS_INTERNAL(pf_wake_hf_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *hf = *av_fetch(cap, 0, 0);
    const hm_abi *A = punk_hm(aTHX);
    PERL_UNUSED_VAR(items);
    if (A && A->is_future(aTHX_ hf)) A->future_done(aTHX_ hf, NULL, 0);
    XSRETURN_EMPTY;
}

/* block until self settles: loop mode pumps via run_until, off-loop it is an
 * error (nothing will settle a pending block-mode future but its own code) */
static void pf_await(pTHX_ SV *self) {
    punk_future *pf = pf_of(aTHX_ self);
    if (pf->state != PF_PENDING) return;
    if (pf->is_loop && pf->abi && pf->loop) {
        SV *hf = pf->abi->future_new(aTHX);
        AV *cap = newAV();
        SV *clos;
        av_push(cap, newSVsv(hf));
        clos = sv_2mortal(punk_closure(aTHX_ pf_wake_hf_cb, cap));
        pf_react(aTHX_ pf, self, PFR_ON_READY, clos);
        if (pf->state == PF_PENDING)
            pf->abi->run_until(aTHX_ pf->loop, hf);
        SvREFCNT_dec(hf);
    }
    else {
        croak("Punk::Future: await on a pending future with no event loop "
              "to drive it");
    }
}

/* a future that settles after secs: a loop timer, or a plain sleep off-loop */
static SV *pf_make_timer(pTHX_ double secs) {
    punk_future *pf = pf_new(aTHX);
    SV *self = pf_bless(aTHX_ pf, "Punk::Future");
    if (pf->is_loop) pf_arm_timer(aTHX_ pf, self, secs);
    else { pf_sleep(secs); pf_settle(aTHX_ pf, self, PF_DONE, newAV()); }
    return self;
}

/* run $cb on the next loop tick (a 0s timer), or now off-loop; the future
 * settles with its result */
static SV *pf_make_defer(pTHX_ SV *cb) {
    punk_future *pf = pf_new(aTHX);
    SV *self = pf_bless(aTHX_ pf, "Punk::Future");
    if (pf->is_loop) { pf->on_fire = newSVsv(cb); pf_arm_timer(aTHX_ pf, self, 0); }
    else             { pf_run_into(aTHX_ self, cb, NULL, 0); }
    return self;
}

#endif /* PUNK_FUTURE_H */

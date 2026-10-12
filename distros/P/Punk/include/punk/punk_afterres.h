/* punk_afterres.h - work that runs after the client has the response.
 *
 *     hook after_response => sub { my ($c, $resp) = @_; ... };
 *     $c->after_response(sub { my ($c, $resp) = @_; ... });
 *
 * `after_dispatch` sees the finalized triplet and may replace it, which means
 * it necessarily runs BEFORE the response is written. There was no phase after
 * it, and on an event loop that is the natural home for the work a request
 * generates but the client is not waiting for: an audit row, a cache warm, a
 * counter, an enqueue. Without one an application either pays for that work
 * inside the response or reaches for a job queue for something that never
 * needed durability.
 *
 * WHEN "after" is:
 *
 *   - `psgix.cleanup` server (the PSGI extension): pushed onto
 *     psgix.cleanup.handlers, which the server runs once the response is
 *     complete. This is the exact promise, and it is the server's to keep.
 *   - a Hyperman worker: a zero-delay loop timer, so the callbacks run on the
 *     next pass of the loop - after the response has been handed to the
 *     kernel, and off the request's own path.
 *   - anywhere else: inline, immediately after the triplet is final. There is
 *     no loop to hand the work to and no server extension to take it, so the
 *     phase still runs in the right ORDER; only the promise that the client is
 *     no longer waiting is one the environment cannot make.
 *
 * A callback that dies is logged through the application's logger and the rest
 * still run: there is no response left to turn into a 500, and a die that
 * vanished silently here would be the worst of both.
 *
 * Must be included after hm_abi.h (the loop timer), punk_static.h
 * (punk_closure) and punk_context.h (which forward-declares pk_after_res).
 */

#ifndef PUNK_AFTERRES_H
#define PUNK_AFTERRES_H

/* Run the callbacks. Each gets ($c, $resp); the response is already gone, so
 * a return value has nowhere to go and is discarded. */
static void pk_ar_run(pTHX_ SV *c, SV *resp, AV *cbs) {
    SSize_t i, n = cbs ? av_len(cbs) + 1 : 0;
    for (i = 0; i < n; i++) {
        SV **cp = av_fetch(cbs, i, 0);
        int died = 0;
        SV *r;
        if (!cp || !*cp || !SvOK(*cp)) continue;
        r = pcx_call2(aTHX_ *cp, c, resp, &died);
        if (r) SvREFCNT_dec(r);
        if (died) {
            /* The logger, not warn: an application that configured logging
             * said where its diagnostics go, and this is a diagnostic. Its
             * own failure is swallowed - there is nothing above to tell. */
            SV *err = sv_2mortal(newSVsv(ERRSV));
            SV *msg = sv_2mortal(newSVpvs("after_response hook died: "));
            SV *log = NULL;
            sv_catsv(msg, err);
            {   /* $c->log, trapped: everything from here down is a
                 * diagnostic, and a diagnostic that dies must not take the
                 * remaining callbacks with it */
                dSP; int count;
                ENTER; SAVETMPS;
                PUSHMARK(SP); EXTEND(SP, 1); PUSHs(c); PUTBACK;
                count = call_method("log", G_SCALAR | G_EVAL);
                SPAGAIN;
                if (count > 0) {
                    SV *l = POPs;
                    if (!SvTRUE(ERRSV) && SvOK(l)) log = newSVsv(l);
                }
                PUTBACK; FREETMPS; LEAVE;
            }
            if (log) {
                dSP;
                ENTER; SAVETMPS;
                PUSHMARK(SP); EXTEND(SP, 2);
                PUSHs(sv_2mortal(log));
                PUSHs(msg);
                PUTBACK;
                (void)call_method("error", G_VOID | G_EVAL | G_DISCARD);
                SPAGAIN;
                PUTBACK; FREETMPS; LEAVE;
            }
        }
    }
}

/* the job, for the two deferred paths */
typedef struct {
    SV *c;
    SV *resp;
    AV *cbs;
} pk_ar_job;

static pk_ar_job *pk_ar_job_new(pTHX_ SV *c, SV *resp, AV *cbs) {
    pk_ar_job *j;
    Newxz(j, 1, pk_ar_job);
    j->c    = SvREFCNT_inc_simple_NN(c);
    j->resp = SvREFCNT_inc_simple_NN(resp);
    j->cbs  = cbs;                          /* takes the +1 */
    return j;
}

static void pk_ar_job_free(pTHX_ pk_ar_job *j) {
    SvREFCNT_dec(j->c);
    SvREFCNT_dec(j->resp);
    SvREFCNT_dec((SV *)j->cbs);
    Safefree(j);
}

static void pk_ar_timer_cb_in(pTHX_ void *ud) {
    pk_ar_job *j = (pk_ar_job *)ud;
    pk_ar_run(aTHX_ j->c, j->resp, j->cbs);
    pk_ar_job_free(aTHX_ j);
}

static void pk_ar_timer_cb(pTHX_ void *ud) {
    PK_LOOP_ENTER;
    pk_ar_timer_cb_in(aTHX_ ud);
    PK_LOOP_LEAVE;
}

/* The psgix.cleanup handler: the server calls it with the env, which this
 * does not need - everything it runs on is in the capture. */
XS_INTERNAL(pk_ar_cleanup_cb);
XS_INTERNAL(pk_ar_cleanup_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV **c   = cap ? av_fetch(cap, 0, 0) : NULL;
    SV **rp  = cap ? av_fetch(cap, 1, 0) : NULL;
    SV **cbs = cap ? av_fetch(cap, 2, 0) : NULL;
    PERL_UNUSED_VAR(items);
    if (c && *c && rp && *rp && cbs && *cbs && SvROK(*cbs))
        pk_ar_run(aTHX_ *c, *rp, (AV *)SvRV(*cbs));
    XSRETURN_EMPTY;
}

/* The callbacks for this response: the application's own hooks first, then
 * anything the request queued, in the order they were registered. Returns a
 * new AV (+1), or NULL when there is nothing to run - which is the answer for
 * every request in an application that uses none of this. */
static AV *pk_ar_collect(pTHX_ SV *c) {
    AV *av = pcx_av(aTHX_ c);
    SV *appsv = pcx_get(aTHX_ av, PCX_APP);
    SV *q = pcx_get(aTHX_ av, PCX_AFTER_RES);
    AV *out = NULL;
    SSize_t i, n;

    if (appsv && SvROK(appsv) && SvTYPE(SvRV(appsv)) == SVt_PVHV) {
        SV **cp = hv_fetchs((HV *)SvRV(appsv), K_AFTER_RES_C, 0);
        if (cp && *cp && SvROK(*cp) && SvTYPE(SvRV(*cp)) == SVt_PVAV) {
            AV *chain = (AV *)SvRV(*cp);
            n = av_len(chain) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(chain, i, 0);
                if (!e || !*e) continue;
                if (!out) out = newAV();
                av_push(out, newSVsv(*e));
            }
        }
    }
    if (q && SvROK(q) && SvTYPE(SvRV(q)) == SVt_PVAV) {
        AV *queue = (AV *)SvRV(q);
        n = av_len(queue) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(queue, i, 0);
            if (!e || !*e) continue;
            if (!out) out = newAV();
            av_push(out, newSVsv(*e));
        }
    }
    return out;
}

/* Called from punk_deliver, once, with the response that is about to be
 * returned to the server. */
static void pk_after_res(pTHX_ SV *c, SV *resp) {
    AV *cbs = pk_ar_collect(aTHX_ c);
    AV *av;
    SV *envsv;

    if (!cbs) return;
    av = pcx_av(aTHX_ c);
    envsv = pcx_get(aTHX_ av, PCX_ENV);

    /* 1. the server's own post-response phase */
    if (envsv && SvROK(envsv) && SvTYPE(SvRV(envsv)) == SVt_PVHV) {
        HV *env = (HV *)SvRV(envsv);
        SV **cl = hv_fetchs(env, "psgix.cleanup", 0);
        if (cl && *cl && SvTRUE(*cl)) {
            SV **hp = hv_fetchs(env, "psgix.cleanup.handlers", 0);
            AV *handlers = NULL;
            if (hp && *hp && SvROK(*hp) && SvTYPE(SvRV(*hp)) == SVt_PVAV)
                handlers = (AV *)SvRV(*hp);
            else {
                handlers = newAV();
                (void)hv_stores(env, "psgix.cleanup.handlers",
                                newRV_noinc((SV *)handlers));
            }
            {
                AV *cap = newAV();
                av_push(cap, newSVsv(c));
                av_push(cap, newSVsv(resp));
                av_push(cap, newRV_noinc((SV *)cbs));   /* takes the +1 */
                av_push(handlers, punk_closure(aTHX_ pk_ar_cleanup_cb, cap));
            }
            return;
        }
    }

    /* 2. the worker's loop */
    {
        const hm_abi *A = punk_hm(aTHX);
        void *loop = (A && A->cur_loop && A->timer) ? A->cur_loop(aTHX) : NULL;
        if (loop) {
            (void)A->timer(aTHX_ loop, 0.0, pk_ar_timer_cb,
                           pk_ar_job_new(aTHX_ c, resp, cbs));
            return;
        }
    }

    /* 3. here, now */
    pk_ar_run(aTHX_ c, resp, cbs);
    SvREFCNT_dec((SV *)cbs);
}

#endif /* PUNK_AFTERRES_H */

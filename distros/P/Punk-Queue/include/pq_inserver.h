#ifndef PQ_INSERVER_H
#define PQ_INSERVER_H

/* pq_inserver.h - the in-server worker: claims on a Hyperman WEB worker's
 * own loop, attached lazily from the plugin's before_dispatch hook (to_app
 * runs in the pre-fork parent, and hm_abi has no post-fork hook).
 *
 * This is the internal seam that replaced the deferred ABI's worker_new:
 * the plugin is same-dist code, so one XSUB call per process attaches the
 * machinery and the hot path (the repeating claim timer) is C from there.
 *
 * The rails, enforced here rather than documented and hoped for:
 *   - a task allowlist is required (the caller croaks without one)
 *   - one job in flight per web worker, hard (the busy flag)
 *   - claims fire only from the timer, never from the request path
 *   - a wall-clock cap: jobs claimed here get their timeout clamped to
 *     it, so perform's loop-timer layer fails a slow future, and the
 *     wall time of every run is measured regardless
 *   - two cap breaches disable the mode in this process, loudly
 *
 * One instance per process, by design: the web worker is the unit.
 *
 * Include after pq_hm.h and pq_queue.h. */

typedef struct pq_inserver {
    SV     *queue;              /* the Punk::Queue, owned              */
    AV     *queues, *tasks;     /* owned                               */
    const hm_abi *A;
    void   *loop;
    double  interval, cap;
    int     busy, breaches, disabled;
} pq_inserver;

static pq_inserver *PQIS = NULL;

static void pq_inserver_tick(pTHX_ void *ud);

static void pq_inserver_arm(pTHX_ pq_inserver *is) {
    if (is->disabled) return;
    (void)is->A->timer(aTHX_ is->loop, is->interval, pq_inserver_tick, is);
}

/* The claim tick. Runs on the loop thread inside the dispatch loop, so
 * everything is trapped (the hm contract: never croak out of a callback)
 * and the re-arm happens FIRST, so a die anywhere below cannot silently
 * stop the mode without tripping the disable path. */
static void pq_inserver_tick(pTHX_ void *ud) {
    pq_inserver *is = (pq_inserver *)ud;
    SV *job = NULL;
    int died = 0;

    pq_inserver_arm(aTHX_ is);
    if (is->busy || is->disabled) return;

    ENTER; SAVETMPS;
    {
        SV *argv[3];
        argv[0] = sv_2mortal(newSViv(0));
        argv[1] = sv_2mortal(newRV_inc((SV *)is->queues));
        argv[2] = sv_2mortal(newRV_inc((SV *)is->tasks));
        job = pq_call_meth_ev(aTHX_ is->queue, "dequeue_ref", argv, 3, 1,
                              &died);
    }

    if (!died && job && SvROK(job)) {
        double t0 = pq_now_local(aTHX), dt;
        is->busy = 1;

        /* clamp the in-memory timeout to the cap, so perform's loop-timer
         * layer enforces it for future-returning tasks; a synchronous
         * blocking task on a loop cannot be stopped by anyone (documented)
         * and is what the breach counter is for */
        {
            HV *jh  = pq_hv(aTHX_ job, "Punk::Queue::Job");
            HV *row = pq_get_hv(aTHX_ jh, "row");
            if (row) {
                SV *t = pq_get(aTHX_ row, "timeout");
                double to = (t && SvOK(t)) ? SvNV(t) : 0.0;
                if (to <= 0 || to > is->cap)
                    (void)hv_stores(row, "timeout", newSVnv(is->cap));
            }
        }

        {
            SV *argv[1], *r;
            argv[0] = job;
            r = pq_call_meth_ev(aTHX_ is->queue, "perform", argv, 1, 1,
                                &died);
            if (r) SvREFCNT_dec(r);
        }

        dt = pq_now_local(aTHX) - t0;
        if (dt > is->cap) {
            is->breaches++;
            warn("Punk::Queue in-server: a job ran %.1fs against a %.1fs "
                 "cap (breach %d of 2)", dt, is->cap, is->breaches);
            if (is->breaches >= 2) {
                is->disabled = 1;
                warn("Punk::Queue in-server: disabled in this process "
                     "after two cap breaches - run punk-queue worker for "
                     "this workload");
            }
        }
        is->busy = 0;
    }
    if (job) SvREFCNT_dec(job);
    FREETMPS; LEAVE;
}

/* Attach, once per process. Returns 1 when armed, 0 when there is no
 * live loop (not a Hyperman worker) - the caller warns and the app keeps
 * serving; in-server is an enhancement, never a requirement. */
static int pq_inserver_attach(pTHX_ SV *queue, HV *opts) {
    const hm_abi *A = pq_hm(aTHX);
    void *loop = A ? A->cur_loop(aTHX) : NULL;
    SV *v;

    if (!loop) return 0;
    if (PQIS) return 1;                    /* one per process */

    PQIS = (pq_inserver *)pq_xcalloc(aTHX_ 1, sizeof(pq_inserver));
    PQIS->queue = SvREFCNT_inc(queue);
    PQIS->A     = A;
    PQIS->loop  = loop;

    PQIS->queues = pq_sql_list(aTHX_ opts ? pq_get(aTHX_ opts, "queues")
                                          : NULL);
    if (av_len(PQIS->queues) < 0)
        av_push(PQIS->queues, newSVpvs("default"));
    SvREFCNT_inc((SV *)PQIS->queues);      /* outlive the mortal scope */

    PQIS->tasks = pq_sql_list(aTHX_ opts ? pq_get(aTHX_ opts, "tasks")
                                         : NULL);
    if (av_len(PQIS->tasks) < 0)
        croak("Punk::Queue: in-server needs a task allowlist");
    SvREFCNT_inc((SV *)PQIS->tasks);

    PQIS->interval = 1.0;
    PQIS->cap      = 5.0;
    if (opts && (v = pq_get(aTHX_ opts, "interval")) && SvOK(v))
        PQIS->interval = SvNV(v) > 0.1 ? SvNV(v) : 0.1;
    if (opts && (v = pq_get(aTHX_ opts, "cap")) && SvOK(v))
        PQIS->cap = SvNV(v) > 0.1 ? SvNV(v) : 0.1;

    pq_inserver_arm(aTHX_ PQIS);
    return 1;
}

#endif /* PQ_INSERVER_H */

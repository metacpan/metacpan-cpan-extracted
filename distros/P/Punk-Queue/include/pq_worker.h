#ifndef PQ_WORKER_H
#define PQ_WORKER_H

/* pq_worker.h - the worker child: register, claim, run, heartbeat, exit.
 *
 * Two execution paths behind one loop body:
 *
 *   - With Hyperman (pq_hm resolves): one Hyperman::Loop->new Perl call at
 *     startup (hm_abi has no loop_new), then jobs run INSIDE a loop timer
 *     callback via run_until. Running them there is the point: cur_loop is
 *     live while the task body executes, so a Punk::Future the task creates
 *     detects the loop and awaits in loop mode - and because the heartbeat
 *     shares the loop, a task that awaits keeps the worker's own timers
 *     firing.
 *
 *   - Without (or with PUNK_QUEUE_NO_HM_ABI=1): a plain C loop sleeping in
 *     poll(2). Fully functional; task-created futures fall back to
 *     Punk::Future's block mode. This is the degraded path t/ forces.
 *
 * Exactly one job in flight per child; the concurrency knob is the
 * supervisor's -j, not per-child parallelism.
 *
 * Phase 3 waits by fixed interval. The horizon query, the decorrelated
 * jitter and the NOTIFY wakeup replace that sleep in phase 5, in this file.
 *
 * Include after pq_hm.h, pq_queue.h. */

#include <poll.h>

/* Signal flags: handlers set these and do nothing else. File-scope because
 * a signal handler cannot carry a context pointer. */
static volatile sig_atomic_t PQW_STOP = 0;

static void pqw_sig_stop(int sig) { (void)sig; PQW_STOP = 1; }

/* The per-run state, carried through the loop callbacks. */
typedef struct pq_worker_run {
    SV *queue;              /* the Punk::Queue, borrowed for the run    */
    SV *backend;            /* borrowed                                 */
    AV *queues, *tasks;     /* mortal-owned by the caller               */
    IV  worker_id;
    IV  max_jobs, jobs_done;
    int oneshot;
    double interval, hb_interval, hb_due, oneshot_deadline;
    int sup_fd;             /* supervision pipe, -1 when absent         */
    /* loop path */
    const hm_abi *A;
    void *loop;
    SV   *loop_sv;
    SV   *tick_future;      /* settled by the timer or a NOTIFY         */
    hm_abi_timer *tick_timer;
    int   timer_fired;
    int   had_work;
    /* wakeup seam (phase 5) */
    int    is_pg;
    SV    *notify_dbh;      /* the dedicated LISTEN connection, or NULL */
    int    notify_fd;       /* its pg_socket, or -1                     */
    int    notify_watched;  /* io_watch installed on notify_fd          */
    int    notify_broken;   /* reconnect on the next pass               */
    int    wake;            /* a NOTIFY arrived: claim now              */
    double sleep_cur;       /* SQLite decorrelated-jitter state         */
    int    stop_cmd;        /* a broadcast said stop: exit after this   */
} pq_worker_run;

#define PQW_JITTER_BASE 0.05

/* Write a supervision line; best-effort, EPIPE means the parent is gone
 * and the TERM that follows will land shortly. */
static void pqw_sup_write(pq_worker_run *w, const char *buf, size_t len) {
    if (w->sup_fd < 0) return;
    while (len) {
        ssize_t n = write(w->sup_fd, buf, len);
        if (n < 0) { if (errno == EINTR) continue; return; }
        buf += n; len -= (size_t)n;
    }
}

/* The claim line carries the job's timeout so the parent can enforce the
 * hard kill without a database read per line. */
static void pqw_sup_claim(pTHX_ pq_worker_run *w, IV id, double timeout) {
    char line[96];
    int n = snprintf(line, sizeof line, "C %ld %.3f %.3f\n",
                     (long)id, pq_now_local(aTHX), timeout);
    if (n > 0) pqw_sup_write(w, line, (size_t)n);
}

static void pqw_sup_done(pq_worker_run *w) {
    pqw_sup_write(w, "D\n", 2);
}

/* Claim and run at most one job. Returns 1 when a job ran. Never croaks:
 * this body runs both from the plain loop and from inside a loop callback,
 * and the hm_abi contract forbids a longjmp out of the latter. Everything
 * that can raise goes through a G_EVAL method call (pq_call_meth_ev) - the
 * same trap discipline the rest of the dist uses, not JMPENV. */
static int pqw_one(pTHX_ pq_worker_run *w) {
    SV *job = NULL;
    int ran = 0, died = 0;

    ENTER; SAVETMPS;

    /* the claim can raise (connection loss); trap and treat as "nothing
     * claimed" - the next pass reconnects via the pool's pid/Active check */
    {
        SV *argv[3];
        argv[0] = sv_2mortal(newSViv(w->worker_id));
        argv[1] = sv_2mortal(newRV_inc((SV *)w->queues));
        argv[2] = sv_2mortal(newRV_inc((SV *)w->tasks));
        job = pq_call_meth_ev(aTHX_ w->queue, "dequeue_ref", argv, 3, 1,
                              &died);
        if (died)
            warn("Punk::Queue worker: claim failed: %s", SvPV_nolen(ERRSV));
    }

    if (job && SvROK(job)) {
        IV id = 0;
        double jt = 0.0;
        { SV *idv = pq_job_field(aTHX_ job, "id"); if (idv) id = SvIV(idv); }
        { SV *tv = pq_job_field(aTHX_ job, "timeout");
          if (tv && SvOK(tv)) jt = SvNV(tv); }
        pqw_sup_claim(aTHX_ w, id, jt);

        /* pq_perform traps the task body itself; the G_EVAL here is for a
         * croak in the settle path (connection loss mid-finish) */
        {
            SV *argv[1], *r;
            argv[0] = job;
            r = pq_call_meth_ev(aTHX_ w->queue, "perform", argv, 1, 1, &died);
            if (r) SvREFCNT_dec(r);
            if (died)
                warn("Punk::Queue worker: perform raised: %s",
                     SvPV_nolen(ERRSV));
        }
        pqw_sup_done(w);
        w->jobs_done++;
        ran = 1;
    }
    if (job) SvREFCNT_dec(job);

    FREETMPS; LEAVE;
    return ran;
}

/* Act on one inbox command. `stop` finishes the current work and exits
 * gracefully; `kill` is documented as its impatient sibling but lands
 * between jobs like everything here - a single-threaded worker cannot
 * interrupt its own running task, and pretending otherwise would be a
 * false promise (the supervisor's hard timeout is the real mid-job
 * killer). `jobs` is accepted and logged rather than rejected: per-child
 * concurrency is fixed at one in this release, but a fleet-wide broadcast
 * must not error on the workers that cannot oblige yet. */
static void pqw_command(pTHX_ pq_worker_run *w, AV *tuple) {
    SV **e = av_fetch(tuple, 0, 0);
    const char *cmd;
    if (!(e && *e && SvOK(*e))) return;
    cmd = SvPV_nolen(*e);
    if (strEQ(cmd, "stop") || strEQ(cmd, "kill")) {
        w->stop_cmd = 1;
    }
    else if (strEQ(cmd, "jobs")) {
        SV **n = av_fetch(tuple, 1, 0);
        warn("Punk::Queue worker %ld: 'jobs' command received (%s); "
             "per-child concurrency is fixed at 1 in this release",
             (long)w->worker_id,
             (n && *n && SvOK(*n)) ? SvPV_nolen(*n) : "no argument");
    }
    /* unknown commands are ignored: a newer punk-queue broadcasting to an
     * older worker is a mixed deployment, not an error */
}

static void pqw_heartbeat(pTHX_ pq_worker_run *w) {
    double now = pq_now_local(aTHX);
    int died = 0;
    SV *argv[2], *r;
    if (now < w->hb_due) return;
    w->hb_due = now + w->hb_interval;
    argv[0] = sv_2mortal(newSViv(w->worker_id));
    argv[1] = &PL_sv_undef;
    r = pq_call_meth_ev(aTHX_ w->backend, "worker_heartbeat", argv, 2, 1,
                        &died);
    if (r) SvREFCNT_dec(r);

    /* drain the broadcast inbox on the same cadence */
    argv[0] = sv_2mortal(newSViv(w->worker_id));
    r = pq_call_meth_ev(aTHX_ w->backend, "receive", argv, 1, 1, &died);
    if (!died && r && SvROK(r) && SvTYPE(SvRV(r)) == SVt_PVAV) {
        AV *cmds = (AV *)SvRV(r);
        SSize_t n = av_len(cmds) + 1, i;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(cmds, i, 0);
            if (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV)
                pqw_command(aTHX_ w, (AV *)SvRV(*e));
        }
    }
    if (r) SvREFCNT_dec(r);
}

static int pqw_should_stop(pTHX_ pq_worker_run *w) {
    if (PQW_STOP) return 1;
    if (w->stop_cmd) return 1;
    if (w->max_jobs && w->jobs_done >= w->max_jobs) return 1;
    if (w->oneshot && w->jobs_done) return 1;
    if (w->oneshot && pq_now_local(aTHX) > w->oneshot_deadline) return 1;
    return 0;
}

/* ---- the LISTEN connection (Pg only) ---------------------------------------
 *
 * A second, dedicated, unpooled DBI handle whose only jobs are LISTEN and
 * being watched. Not the pooled work handle: the read watcher would fire
 * on every claim's own result traffic, which is the mistake the plan says
 * to design out on day one.
 *
 * What the spike established (and the code below leans on): pg_notifies
 * drains pending notifications and returns undef when done; an idle LISTEN
 * connection needs no pokes; server-side termination makes the socket
 * readable (EOF) but pg_notifies then returns undef WITHOUT dying and
 * {Active} stays true - so death is detected as "readable but nothing
 * drained", confirmed by a trapped ping. A reconnected handle has a
 * different fd, so the old watch must be removed and a new one installed. */

static void pqw_notify_teardown(pTHX_ pq_worker_run *w) {
    if (w->notify_watched && w->A && w->loop && w->notify_fd >= 0)
        w->A->io_unwatch(aTHX_ w->loop, w->notify_fd, HM_ABI_READ);
    w->notify_watched = 0;
    if (w->notify_dbh) {
        int died = 0;
        SV *r = pq_call_meth_ev(aTHX_ w->notify_dbh, "disconnect",
                                NULL, 0, 1, &died);
        if (r) SvREFCNT_dec(r);
        SvREFCNT_dec(w->notify_dbh);
        w->notify_dbh = NULL;
    }
    w->notify_fd = -1;
    w->notify_broken = 0;
}

/* Drain pending notifications. Sets w->wake if any arrived; sets
 * notify_broken when the fd was readable but nothing drained and a ping
 * fails - the quiet-EOF shape the spike found. Never croaks. */
static void pqw_notify_drain(pTHX_ pq_worker_run *w, int was_readable) {
    int died = 0, got = 0;
    if (!w->notify_dbh) return;
    for (;;) {
        SV *note = pq_call_meth_ev(aTHX_ w->notify_dbh, "pg_notifies",
                                   NULL, 0, 1, &died);
        int have = !died && note && SvOK(note);
        if (note) SvREFCNT_dec(note);
        if (died) { w->notify_broken = 1; return; }
        if (!have) break;
        got = 1;
        w->wake = 1;
    }
    if (was_readable && !got) {
        SV *r = pq_call_meth_ev(aTHX_ w->notify_dbh, "ping", NULL, 0, 1,
                                &died);
        int alive = !died && r && SvTRUE(r);
        if (r) SvREFCNT_dec(r);
        if (!alive) w->notify_broken = 1;
    }
}

/* The loop-path readiness callback. Must not croak (hm contract). Settles
 * the tick future on any event - a wake claims immediately, and a broken
 * connection needs the main loop awake to reconnect. */
static void pqw_notify_cb(pTHX_ int fd, int mask, void *ud) {
    pq_worker_run *w = (pq_worker_run *)ud;
    PERL_UNUSED_ARG(fd);
    PERL_UNUSED_ARG(mask);
    pqw_notify_drain(aTHX_ w, 1);
    if ((w->wake || w->notify_broken) && w->tick_future && w->A)
        w->A->future_done(aTHX_ w->tick_future, NULL, 0);
}

/* (Re)establish the LISTEN connection: connect with the backend's own
 * dsn/credentials, LISTEN each subscribed queue, fetch pg_socket, and on
 * the loop path watch it. Failure is not fatal - the worker still works,
 * at poll latency - so everything is trapped and a failure just leaves
 * notify_dbh NULL until the next pass. */
static void pqw_notify_ensure(pTHX_ pq_worker_run *w) {
    HV *bh, *o;
    SV *dsn, *user, *pass;
    int died = 0;

    if (!w->is_pg) return;
    if (w->notify_dbh && !w->notify_broken) return;
    pqw_notify_teardown(aTHX_ w);

    bh = pq_hv(aTHX_ w->backend, "Punk::Queue::Backend");
    o  = pq_get_hv(aTHX_ bh, "opts");
    dsn  = o ? pq_get(aTHX_ o, "dsn") : NULL;
    user = o ? pq_get(aTHX_ o, "user") : NULL;
    pass = o ? pq_get(aTHX_ o, "password") : NULL;
    if (!(dsn && SvOK(dsn))) return;      /* dbh-injected queue: no dsn */

    {
        SV *argv[4], *conn;
        HV *attr = newHV();
        (void)hv_stores(attr, "RaiseError", newSViv(1));
        (void)hv_stores(attr, "AutoCommit", newSViv(1));
        (void)hv_stores(attr, "PrintError", newSViv(0));
        (void)hv_stores(attr, "AutoInactiveDestroy", newSViv(1));
        argv[0] = dsn;
        argv[1] = (user && SvOK(user)) ? user : &PL_sv_undef;
        argv[2] = (pass && SvOK(pass)) ? pass : &PL_sv_undef;
        argv[3] = sv_2mortal(newRV_noinc((SV *)attr));
        conn = pq_call_meth_ev(aTHX_ sv_2mortal(newSVpvs("DBI")), "connect",
                               argv, 4, 1, &died);
        if (died || !(conn && SvROK(conn))) {
            if (conn) SvREFCNT_dec(conn);
            return;
        }
        w->notify_dbh = conn;
    }

    /* LISTEN "pq.<queue>" per subscribed queue. The identifier is safe by
     * construction: queue names passed validation at enqueue, and the
     * worker re-checks so a hostile -q argument cannot smuggle a quote. */
    {
        SSize_t nq = av_len(w->queues) + 1, i;
        for (i = 0; i < nq; i++) {
            SV **e = av_fetch(w->queues, i, 0);
            SV *stmt, *argv[1], *r;
            if (!(e && *e) || !pq_name_ok(aTHX_ *e)) continue;
            stmt = sv_2mortal(Perl_newSVpvf(aTHX_ "LISTEN \"pq.%s\"",
                                            SvPV_nolen(*e)));
            argv[0] = stmt;
            r = pq_call_meth_ev(aTHX_ w->notify_dbh, "do", argv, 1, 1,
                                &died);
            if (r) SvREFCNT_dec(r);
            if (died) { pqw_notify_teardown(aTHX_ w); return; }
        }
    }

    {
        SV *fd = pq_attr(aTHX_ w->notify_dbh, "pg_socket");
        w->notify_fd = (fd && SvOK(fd)) ? (int)SvIV(fd) : -1;
    }
    if (w->notify_fd >= 0 && w->A && w->loop) {
        w->A->io_watch(aTHX_ w->loop, w->notify_fd, HM_ABI_READ,
                       pqw_notify_cb, w);
        w->notify_watched = 1;
    }
}

/* ---- how long to sleep -----------------------------------------------------
 *
 * Both backends clamp to the delayed-job horizon, so a delayed job wakes
 * the worker on time however long the interval. On top of that:
 *
 *   Pg: sleep the whole (clamped) interval - NOTIFY provides the wakeup
 *       for new work, so a long interval costs nothing.
 *   SQLite: decorrelated jitter, sleep = min(cap, uniform(base, prev*3)),
 *       cap = min(1s, horizon, interval). The jitter is not decoration: N
 *       children polling one file in lockstep is the pathological case,
 *       and plain doubling keeps them in lockstep. */
static double pqw_sleep_for(pTHX_ pq_worker_run *w) {
    double cap = w->interval;
    {
        int died = 0;
        SV *argv[1], *r;
        argv[0] = sv_2mortal(newRV_inc((SV *)w->queues));
        r = pq_call_meth_ev(aTHX_ w->backend, "_ready_horizon", argv, 1, 1,
                            &died);
        if (!died && r && SvOK(r)) {
            double h = SvNV(r);
            if (h < cap) cap = h < 0.01 ? 0.01 : h;
        }
        if (r) SvREFCNT_dec(r);
    }

    if (w->is_pg) return cap;

    {
        double jcap = cap < 1.0 ? cap : 1.0;
        double hi = w->sleep_cur * 3.0;
        double next;
        if (hi < PQW_JITTER_BASE) hi = PQW_JITTER_BASE;
        next = PQW_JITTER_BASE
             + pq_rand01(aTHX) * (hi - PQW_JITTER_BASE);
        if (next > jcap) next = jcap;
        w->sleep_cur = next;
        return next;
    }
}

/* ---- the loop path ---------------------------------------------------------
 *
 * Jobs run inside this timer callback, on the loop thread, inside
 * run_until - which is what puts a live cur_loop under the task body. The
 * callback drains ready work, heartbeats, then settles the tick future so
 * run_until returns to the outer while, which checks the stop conditions
 * and re-arms.
 *
 * The tick future can be settled by two hands - this timer, or a NOTIFY
 * arriving in pqw_notify_cb - and settling twice is a no-op. What is NOT
 * harmless is the timer handle: it is freed when it fires and must not be
 * cancelled after, so the fired flag decides whether the main loop
 * cancels it. */
static void pqw_tick_cb(pTHX_ void *ud) {
    pq_worker_run *w = (pq_worker_run *)ud;
    w->timer_fired = 1;
    w->tick_timer  = NULL;
    w->had_work = 0;
    while (!pqw_should_stop(aTHX_ w) && pqw_one(aTHX_ w)) {
        w->had_work = 1;
        w->sleep_cur = PQW_JITTER_BASE;
    }
    pqw_heartbeat(aTHX_ w);
    if (w->tick_future)
        w->A->future_done(aTHX_ w->tick_future, NULL, 0);
}

/* A sleep chunk: settle the tick future and nothing else. Long sleeps are
 * built from these so the worker re-checks its stop flag every second -
 * run_until sleeps in the kernel, EINTR is swallowed by the loop, and
 * without the chunking a TERM would wait out the whole dequeue interval
 * (a 60s interval blew the graceful window; t/40 caught it). A chunk
 * costs one timer fire and no database traffic. */
static void pqw_chunk_cb(pTHX_ void *ud) {
    pq_worker_run *w = (pq_worker_run *)ud;
    w->timer_fired = 1;
    w->tick_timer  = NULL;
    if (w->tick_future)
        w->A->future_done(aTHX_ w->tick_future, NULL, 0);
}

/* One run_until pass around a timer. Returns after the timer fires or
 * something else settles the tick future (a NOTIFY, a broken-connection
 * report), cancelling the timer in the latter case. */
static void pqw_loop_wait(pTHX_ pq_worker_run *w, double delay,
                          hm_abi_timer_cb cb) {
    SV *f = w->A->future_new(aTHX);
    w->tick_future = f;
    w->timer_fired = 0;
    w->tick_timer = w->A->timer(aTHX_ w->loop, delay, cb, w);
    w->A->run_until(aTHX_ w->loop, f);
    w->tick_future = NULL;
    if (!w->timer_fired && w->tick_timer)
        w->A->timer_cancel(aTHX_ w->loop, w->tick_timer);
    w->tick_timer = NULL;
    SvREFCNT_dec(f);
}

static void pqw_run_loop(pTHX_ pq_worker_run *w) {
    while (!pqw_should_stop(aTHX_ w)) {
        pqw_notify_ensure(aTHX_ w);

        /* sleep, in interruptible chunks */
        if (!w->had_work && !w->wake && !w->notify_broken) {
            double left = pqw_sleep_for(aTHX_ w);
            while (left > 0 && !pqw_should_stop(aTHX_ w)
                   && !w->wake && !w->notify_broken) {
                double chunk = left < 1.0 ? left : 1.0;
                pqw_loop_wait(aTHX_ w, chunk, pqw_chunk_cb);
                left -= chunk;
                pqw_heartbeat(aTHX_ w);      /* time-gated; long sleeps
                                              * must not starve it */
            }
        }
        if (pqw_should_stop(aTHX_ w)) break;
        if (w->notify_broken) continue;      /* reconnect first */
        w->wake = 0;

        /* the work tick: claims run inside run_until so cur_loop is live
         * under the task bodies */
        pqw_loop_wait(aTHX_ w, 0.0, pqw_tick_cb);
    }
    pqw_notify_teardown(aTHX_ w);
}

/* ---- the poll path ---------------------------------------------------------
 *
 * The same state machine without a loop: poll(2) sleeps, and on Pg the
 * notify fd sits in the pollfd set, so LISTEN works - at identical
 * latency - without Hyperman installed. */

static void pqw_run_poll(pTHX_ pq_worker_run *w) {
    while (!pqw_should_stop(aTHX_ w)) {
        pqw_notify_ensure(aTHX_ w);

        if (pqw_one(aTHX_ w)) {              /* drain without sleeping */
            w->sleep_cur = PQW_JITTER_BASE;
            continue;
        }
        pqw_heartbeat(aTHX_ w);
        if (pqw_should_stop(aTHX_ w)) break;

        {
            int ms = (int)(pqw_sleep_for(aTHX_ w) * 1000.0);
            if (ms < 10) ms = 10;
            /* a signal interrupts the sleep (EINTR), so a TERM lands
             * within one syscall, not one interval */
            if (w->notify_dbh && w->notify_fd >= 0) {
                struct pollfd pfd;
                pfd.fd = w->notify_fd;
                pfd.events = POLLIN;
                pfd.revents = 0;
                if (poll(&pfd, 1, ms) > 0)
                    pqw_notify_drain(aTHX_ w,
                        (pfd.revents & (POLLIN | POLLERR | POLLHUP)) ? 1 : 0);
            }
            else {
                (void)poll(NULL, 0, ms);
            }
        }
        w->wake = 0;                          /* the claim at loop top */
    }
    pqw_notify_teardown(aTHX_ w);
}

/* ---- entry -----------------------------------------------------------------
 *
 * Returns the number of jobs run. The worker object is a blessed hashref
 * {queue, opts}; worker_id is written back onto it so the caller can see
 * which row this run owned. */
static IV pqw_run(pTHX_ SV *self) {
    HV *h = pq_hv(aTHX_ self, "Punk::Queue::Worker");
    SV *queue = pq_get(aTHX_ h, "queue");
    HV *opts = pq_get_hv(aTHX_ h, "opts");
    pq_worker_run w;
    struct sigaction sa, old_term, old_int;
    SV *v;

    if (!(queue && SvROK(queue)))
        croak("Punk::Queue::Worker: no queue - construct via $q->worker");

    memset(&w, 0, sizeof w);
    w.queue   = queue;
    w.backend = pq_backend_of(aTHX_ queue);
    w.sup_fd  = -1;

    w.queues = pq_sql_list(aTHX_ opts ? pq_get(aTHX_ opts, "queues") : NULL);
    if (av_len(w.queues) < 0) av_push(w.queues, newSVpvs("default"));
    w.tasks  = pq_sql_list(aTHX_ opts ? pq_get(aTHX_ opts, "tasks") : NULL);

    /* dequeue_interval, and only a ceiling now: the horizon clamps it for
     * delayed jobs, NOTIFY undercuts it on Pg, and the jitter caps at 1s
     * on SQLite - which is what makes 5s a safe default where phase 3's
     * 0.5s was load-bearing. */
    w.interval    = 5.0;
    w.hb_interval = 10.0;
    w.sleep_cur   = PQW_JITTER_BASE;
    w.notify_fd   = -1;
    if (opts && (v = pq_get(aTHX_ opts, "interval")) && SvOK(v))
        w.interval = SvNV(v) > 0.01 ? SvNV(v) : 0.01;
    if (opts && (v = pq_get(aTHX_ opts, "heartbeat_interval")) && SvOK(v))
        w.hb_interval = SvNV(v);
    if (opts && (v = pq_get(aTHX_ opts, "max_jobs")) && SvOK(v))
        w.max_jobs = SvIV(v);
    if (opts && (v = pq_get(aTHX_ opts, "sup_fd")) && SvOK(v))
        w.sup_fd = (int)SvIV(v);

    {
        const char *one = PerlEnv_getenv("PUNK_QUEUE_ONESHOT");
        if (one && *one && strNE(one, "0")) {
            w.oneshot = 1;
            w.oneshot_deadline = pq_now_local(aTHX) + 10.0;
            if (opts && (v = pq_get(aTHX_ opts, "oneshot_wait")) && SvOK(v))
                w.oneshot_deadline = pq_now_local(aTHX) + SvNV(v);
        }
    }

    /* register before installing handlers, so a TERM during registration
     * still dies loudly rather than being swallowed by a half-set-up run */
    {
        HV *ro = (HV *)sv_2mortal((SV *)newHV());
        SV *qlist = sv_2mortal(newRV_inc((SV *)w.queues));
        (void)hv_stores(ro, "role",   newSVpvs("child"));
        (void)hv_stores(ro, "queues", newSVsv(qlist));
        w.worker_id = pq_register_worker(aTHX_ w.backend, 0, ro);
        (void)hv_stores(h, "worker_id", newSViv(w.worker_id));
    }
    w.hb_due = pq_now_local(aTHX);   /* first pass heartbeats immediately */

    PQW_STOP = 0;
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = pqw_sig_stop;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;                 /* no SA_RESTART: wake the sleep */
    sigaction(SIGTERM, &sa, &old_term);
    sigaction(SIGINT,  &sa, &old_int);

    w.is_pg = pq_is_pg(aTHX_ w.backend);

    /* loop selection */
    w.A = pq_hm(aTHX);
    if (w.A) {
        SV *cls = sv_2mortal(newSVpvs("Hyperman::Loop"));
        int died = 0;
        w.loop_sv = pq_call_meth_ev(aTHX_ cls, "new", NULL, 0, 1, &died);
        if (!died && w.loop_sv && SvROK(w.loop_sv))
            w.loop = w.A->loop_of_sv(aTHX_ w.loop_sv);
        else { w.A = NULL; }         /* degrade to poll */
    }

    if (w.A && w.loop) pqw_run_loop(aTHX_ &w);
    else               pqw_run_poll(aTHX_ &w);

    sigaction(SIGTERM, &old_term, NULL);
    sigaction(SIGINT,  &old_int,  NULL);

    {
        int died = 0;
        SV *argv[1], *r;
        argv[0] = sv_2mortal(newSViv(w.worker_id));
        r = pq_call_meth_ev(aTHX_ w.backend, "unregister_worker", argv, 1, 1,
                            &died);
        if (r) SvREFCNT_dec(r);
    }
    if (w.loop_sv) SvREFCNT_dec(w.loop_sv);

    return w.jobs_done;
}

#endif /* PQ_WORKER_H */

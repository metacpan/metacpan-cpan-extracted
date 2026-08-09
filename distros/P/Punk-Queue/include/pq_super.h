#ifndef PQ_SUPER_H
#define PQ_SUPER_H

/* pq_super.h - the supervisor: fork -j children, keep them alive, take
 * them down cleanly.
 *
 * The parent's database traffic is confined to startup (register the
 * supervisor row, migrate) and the 10s pass (its own heartbeat, and the
 * cron scheduler when enabled) - children own their handles via the
 * pool's pid check. What the parent owns is process lifecycle: respawn
 * with backoff, the supervision pipe each child reports claims on (the
 * hard-kill timeout built on it lands in phase 4), and shutdown.
 *
 * -j N means N child processes, each with its own worker row. A supervisor
 * row with jobs=4 cannot tell you which child is stuck; four child rows
 * can.
 *
 * Include after pq_worker.h. */

#include <sys/wait.h>
#include <fcntl.h>

/* Signal flags. Handlers set these and nothing else; the 1s poll timeout
 * (and EINTR, since SA_RESTART is off) turns them into action. */
static volatile sig_atomic_t PQS_TERM = 0;   /* graceful               */
static volatile sig_atomic_t PQS_QUIT = 0;   /* immediate              */
static volatile sig_atomic_t PQS_HUP  = 0;   /* recycle children       */
static volatile sig_atomic_t PQS_CHLD = 0;   /* reap                   */
static volatile sig_atomic_t PQS_USR2 = 0;   /* status to stderr       */

static void pqs_sig(int sig) {
    switch (sig) {
        case SIGTERM: PQS_TERM = 1; break;
        case SIGINT:  PQS_TERM = 1; break;
        case SIGQUIT: PQS_QUIT = 1; break;
        case SIGHUP:  PQS_HUP  = 1; break;
        case SIGCHLD: PQS_CHLD = 1; break;
        case SIGUSR2: PQS_USR2 = 1; break;
    }
}

typedef struct pqs_slot {
    pid_t  pid;             /* 0 = empty                                */
    int    rfd;             /* our end of the supervision pipe, or -1   */
    double spawned;         /* pq_now_local at fork                     */
    double backoff_until;   /* do not respawn before this               */
    int    backoff_step;    /* index into the schedule                  */
    int    claimed_any;     /* this incarnation claimed at least once   */
    long   current_job;     /* 0 = idle                                 */
    double job_started;
    double job_timeout;     /* 0 = none; from the claim line            */
    char   rbuf[256];       /* partial-line carry for the pipe          */
    size_t rlen;
} pqs_slot;

static const double PQS_BACKOFF[] = { 0.0, 0.5, 1.0, 2.0, 4.0, 8.0, 30.0 };
#define PQS_BACKOFF_MAX 6
#define PQS_STABLE_SECS 60.0

typedef struct pq_super {
    SV      *queue;
    SV      *worker_opts;   /* hashref passed to each child's worker    */
    pqs_slot *slots;
    int      n;
    IV       supervisor_id;
    double   graceful_timeout;
    int      fail_fast;
    int      noclaim_exits;  /* consecutive, across the whole pool      */
    int      shutting_down;
    int      exit_code;
    /* the cron scheduler (phase 9) */
    int      sched_on;
    int      leader;         /* holding the pq.cron.leader lease        */
    double   next_sched;     /* aligned 10s boundary                    */
} pq_super;

/* ---- the supervision pipe (parent side) ------------------------------------
 *
 * The child writes "C <jobid> <epoch>\n" on claim and "D\n" on completion.
 * Phase 3 tracks it (claimed_any feeds the fail-fast escalation; the
 * current-job fields feed SIGUSR2's status line); phase 4's hard timeout
 * kill reads job_started off the same state. */
static void pqs_pipe_drain(pqs_slot *s) {
    for (;;) {
        ssize_t n = read(s->rfd, s->rbuf + s->rlen,
                         sizeof(s->rbuf) - s->rlen - 1);
        char *nl;
        if (n <= 0) break;                       /* EAGAIN or EOF        */
        s->rlen += (size_t)n;
        s->rbuf[s->rlen] = 0;
        while ((nl = strchr(s->rbuf, '\n'))) {
            *nl = 0;
            if (s->rbuf[0] == 'C') {
                long id = 0; double ts = 0, to = 0;
                if (sscanf(s->rbuf + 1, " %ld %lf %lf", &id, &ts, &to) >= 2) {
                    s->current_job = id;
                    s->job_started = ts;
                    s->job_timeout = to;
                    s->claimed_any = 1;
                }
            }
            else if (s->rbuf[0] == 'D') {
                s->current_job = 0;
                s->job_started = 0;
                s->job_timeout = 0;
            }
            s->rlen -= (size_t)(nl + 1 - s->rbuf);
            memmove(s->rbuf, nl + 1, s->rlen + 1);
        }
    }
}

/* ---- children --------------------------------------------------------------
 *
 * The child runs the worker in-process on the queue object built before the
 * fork - the task registry came along with it, and the connection pool's
 * pid check hands the child a fresh handle on first use. After the run it
 * leaves through _exit: the parent's stdio buffers and destructors were
 * duplicated by fork, and flushing or running them twice is how a forked
 * perl corrupts its parent's output. */
static void pqs_spawn(pTHX_ pq_super *sup, int i) {
    pqs_slot *s = &sup->slots[i];
    int fds[2];
    pid_t pid;

    if (pipe(fds) != 0) { s->pid = 0; return; }
    /* parent end non-blocking; child end inherited as-is */
    fcntl(fds[0], F_SETFL, fcntl(fds[0], F_GETFL, 0) | O_NONBLOCK);

    pid = fork();
    if (pid < 0) { close(fds[0]); close(fds[1]); s->pid = 0; return; }

    if (pid == 0) {
        /* child */
        int died = 0;
        SV *worker, *argv[1], *r;
        close(fds[0]);

        /* default signal handling; pqw_run installs its own TERM/INT */
        signal(SIGHUP,  SIG_DFL);
        signal(SIGQUIT, SIG_DFL);
        signal(SIGCHLD, SIG_DFL);
        signal(SIGUSR2, SIG_IGN);

        {
            HV *wh = newHV();
            HV *opts = newHV();
            /* copy the shared worker opts, then add this child's pipe fd */
            if (sup->worker_opts && SvROK(sup->worker_opts)) {
                HV *in = (HV *)SvRV(sup->worker_opts);
                HE *he;
                hv_iterinit(in);
                while ((he = hv_iternext(in)))
                    (void)hv_store_ent(opts, HeSVKEY_force(he),
                                       newSVsv(HeVAL(he)), 0);
            }
            (void)hv_stores(opts, "sup_fd", newSViv(fds[1]));
            (void)hv_stores(wh, "queue", newSVsv(sup->queue));
            (void)hv_stores(wh, "opts",  newRV_noinc((SV *)opts));
            worker = sv_2mortal(newRV_noinc((SV *)wh));
            sv_bless(worker, gv_stashpvs("Punk::Queue::Worker", GV_ADD));
        }

        argv[0] = worker;
        r = pq_call_meth_ev(aTHX_ worker, "run", NULL, 0, 1, &died);
        if (r) SvREFCNT_dec(r);
        if (died)
            fprintf(stderr, "punk-queue worker child: %s",
                    SvPV_nolen(ERRSV));
        close(fds[1]);
        _exit(died ? 1 : 0);
    }

    /* parent */
    close(fds[1]);
    s->pid = pid;
    s->rfd = fds[0];
    s->spawned = pq_now_local(aTHX);
    s->claimed_any = 0;
    s->current_job = 0;
    s->rlen = 0;
}

static void pqs_slot_close(pqs_slot *s) {
    if (s->rfd >= 0) { close(s->rfd); s->rfd = -1; }
    s->pid = 0;
}

/* Reap everything reapable; schedule respawns with backoff. */
static void pqs_reap(pTHX_ pq_super *sup) {
    for (;;) {
        int status = 0;
        pid_t pid = waitpid(-1, &status, WNOHANG);
        int i;
        if (pid <= 0) break;
        for (i = 0; i < sup->n; i++) {
            pqs_slot *s = &sup->slots[i];
            double lived;
            if (s->pid != pid) continue;
            pqs_pipe_drain(s);                    /* final lines         */
            lived = pq_now_local(aTHX) - s->spawned;
            pqs_slot_close(s);

            if (!s->claimed_any) sup->noclaim_exits++;
            else                 sup->noclaim_exits = 0;

            if (lived >= PQS_STABLE_SECS) s->backoff_step = 0;
            else if (s->backoff_step < PQS_BACKOFF_MAX) s->backoff_step++;
            s->backoff_until = pq_now_local(aTHX)
                             + PQS_BACKOFF[s->backoff_step];

            /* Three consecutive exits with no claim across the pool is
             * "the app does not work in the child" - a compile error, a
             * bad dsn - and respawning forever just hides it. */
            if (sup->noclaim_exits >= 3) {
                warn("punk-queue: %d consecutive worker exits without a "
                     "single claim - the worker is failing at startup "
                     "(bad app class or dsn?)%s",
                     sup->noclaim_exits,
                     sup->fail_fast ? "; --fail-fast set, stopping" : "");
                if (sup->fail_fast) {
                    sup->shutting_down = 1;
                    sup->exit_code = 1;
                }
            }
            break;
        }
    }
}

/* ---- the hard timeout ------------------------------------------------------
 *
 * The only timeout layer that is a guarantee. alarm cannot interrupt a
 * blocking C call and a loop timer cannot stop work already running, so
 * past timeout * 1.5 + 5 the parent SIGKILLs the child and settles the job
 * as failed itself. The 1.5 gives the soft layers room to do it politely
 * first; the +5 keeps a 1-second timeout from becoming a hair trigger.
 *
 * This is the one place the parent touches the database after startup: it
 * must, because the child that would have settled the row is the thing
 * being shot. Every call is G_EVAL - a kill must not die. */
static void pqs_hard_kill(pTHX_ pq_super *sup, int i) {
    pqs_slot *s = &sup->slots[i];
    long jid = s->current_job;
    int died = 0;
    IV retries = 0;
    SV *info, *r;
    SV *argv[3];

    warn("punk-queue: job %ld exceeded its timeout (%.1fs) - killing "
         "worker pid %ld", jid, s->job_timeout, (long)s->pid);
    kill(s->pid, SIGKILL);
    s->current_job = 0;             /* one kill per job */
    s->job_timeout = 0;

    argv[0] = sv_2mortal(newSViv((IV)jid));
    info = pq_call_meth_ev(aTHX_ sup->queue, "job_info", argv, 1, 1, &died);
    if (!died && info && SvROK(info)) {
        SV *rv = pq_get(aTHX_ (HV *)SvRV(info), "retries");
        if (rv && SvOK(rv)) retries = SvIV(rv);
    }
    if (info) SvREFCNT_dec(info);
    if (died) return;

    argv[0] = sv_2mortal(newSViv((IV)jid));
    argv[1] = sv_2mortal(newSViv(retries));
    argv[2] = sv_2mortal(newSVpvs(
        "Punk::Queue: job exceeded its timeout and its worker was killed"));
    r = pq_call_meth_ev(aTHX_ sup->queue, "fail_job", argv, 3, 1, &died);
    if (r) SvREFCNT_dec(r);
}

static void pqs_check_timeouts(pTHX_ pq_super *sup) {
    double now = pq_now_local(aTHX);
    int i;
    for (i = 0; i < sup->n; i++) {
        pqs_slot *s = &sup->slots[i];
        if (!s->pid || !s->current_job || s->job_timeout <= 0) continue;
        if (now - s->job_started > s->job_timeout * 1.5 + 5.0)
            pqs_hard_kill(aTHX_ sup, i);
    }
}

/* ---- the 10s pass: heartbeat + the cron scheduler --------------------------
 *
 * The parent's only recurring database traffic, on a 10-second cadence
 * aligned to the wall clock.
 *
 * First its own heartbeat: the supervisor registered a worker row at
 * boot, and a row that never beats reads as stale everywhere that
 * checks proof of life (the admin UI badges anything quiet for 60s;
 * repair's stale-worker pass would eventually reap it). The children
 * beat from their own timers; the parent beats here, scheduler or not.
 *
 * Then the scheduler, when enabled: every supervisor competes for the
 * pq.cron.leader lease, so occurrences fire at :00/:10/... rather than
 * at an arbitrary offset from process start. The holder renews; a loser
 * tries a fresh acquire (the phase-6 lease: one INSERT wins on the
 * unique index). Losing the lease is not an error - a leader that
 * paused past its expiry discovers it here and steps down. The tick's
 * optimistic guard and occurrence dedupe make even a brief double
 * leadership harmless.
 *
 * Everything is a G_EVAL method call: a hiccup (connection trouble, a
 * bad stored expression - which the tick disables itself) must never
 * take the process pool down with it. */
#define PQS_LEADER_LOCK "pq.cron.leader"
#define PQS_LEASE_SECS  30.0

static void pqs_sched_pass(pTHX_ pq_super *sup) {
    double now = pq_now_local(aTHX);
    SV *backend;
    int died = 0;

    if (now < sup->next_sched) return;
    sup->next_sched = (double)(((IV)(now / 10) + 1) * 10);

    backend = pq_backend_of(aTHX_ sup->queue);

    {
        SV *argv[1], *r;
        argv[0] = sv_2mortal(newSViv(sup->supervisor_id));
        r = pq_call_meth_ev(aTHX_ backend, "worker_heartbeat", argv, 1, 1,
                            &died);
        if (r) SvREFCNT_dec(r);
        died = 0;
    }

    if (!sup->sched_on) return;

    if (sup->leader) {
        SV *argv[3], *r;
        argv[0] = sv_2mortal(newSVpvs(PQS_LEADER_LOCK));
        argv[1] = sv_2mortal(newSViv(sup->supervisor_id));
        argv[2] = sv_2mortal(newSVnv(PQS_LEASE_SECS));
        r = pq_call_meth_ev(aTHX_ backend, "renew_lock", argv, 3, 1,
                            &died);
        sup->leader = (!died && r && SvTRUE(r)) ? 1 : 0;
        if (r) SvREFCNT_dec(r);
    }
    if (!sup->leader) {
        HV *o = (HV *)sv_2mortal((SV *)newHV());
        SV *argv[3], *r;
        (void)hv_stores(o, "owner", newSViv(sup->supervisor_id));
        argv[0] = sv_2mortal(newSVpvs(PQS_LEADER_LOCK));
        argv[1] = sv_2mortal(newSVnv(PQS_LEASE_SECS));
        argv[2] = sv_2mortal(newRV_inc((SV *)o));
        r = pq_call_meth_ev(aTHX_ backend, "lock", argv, 3, 1, &died);
        sup->leader = (!died && r && SvTRUE(r)) ? 1 : 0;
        if (r) SvREFCNT_dec(r);
    }
    if (sup->leader) {
        SV *argv[1], *r;
        argv[0] = sv_2mortal(newSViv(100));
        r = pq_call_meth_ev(aTHX_ backend, "_cron_tick", argv, 1, 1,
                            &died);
        if (died)
            warn("punk-queue: cron tick failed: %s", SvPV_nolen(ERRSV));
        if (r) SvREFCNT_dec(r);
    }
}

static void pqs_status(pq_super *sup) {
    int i;
    fprintf(stderr, "punk-queue supervisor: %d slot(s)\n", sup->n);
    for (i = 0; i < sup->n; i++) {
        pqs_slot *s = &sup->slots[i];
        if (s->pid)
            fprintf(stderr, "  [%d] pid %ld %s\n", i, (long)s->pid,
                    s->current_job
                        ? "running a job" : "idle");
        else
            fprintf(stderr, "  [%d] respawning (backoff step %d)\n",
                    i, s->backoff_step);
    }
}

static void pqs_kill_all(pq_super *sup, int sig) {
    int i;
    for (i = 0; i < sup->n; i++)
        if (sup->slots[i].pid) kill(sup->slots[i].pid, sig);
}

static int pqs_alive(pq_super *sup) {
    int i, n = 0;
    for (i = 0; i < sup->n; i++) if (sup->slots[i].pid) n++;
    return n;
}

/* ---- entry -----------------------------------------------------------------
 *
 * Runs until told to stop. Returns the process exit code. */
static int pqs_run(pTHX_ SV *queue, SV *worker_opts, int nworkers,
                   double graceful_timeout, int fail_fast,
                   int scheduler) {
    pq_super sup;
    struct sigaction sa;
    struct sigaction old[6];
    static const int sigs[6] =
        { SIGTERM, SIGINT, SIGQUIT, SIGHUP, SIGCHLD, SIGUSR2 };
    int i;
    SV *backend = pq_backend_of(aTHX_ queue);

    memset(&sup, 0, sizeof sup);
    sup.queue = queue;
    sup.worker_opts = worker_opts;
    sup.n = nworkers > 0 ? nworkers : 1;
    sup.graceful_timeout = graceful_timeout > 0 ? graceful_timeout : 60.0;
    sup.fail_fast = fail_fast;
    sup.sched_on = scheduler;
    sup.slots = (pqs_slot *)pq_xcalloc(aTHX_ (size_t)sup.n, sizeof(pqs_slot));
    for (i = 0; i < sup.n; i++) sup.slots[i].rfd = -1;

    /* the pool row the admin UI sees; jobs=0 says "does not claim" */
    {
        HV *ro = (HV *)sv_2mortal((SV *)newHV());
        (void)hv_stores(ro, "role", newSVpvs("supervisor"));
        (void)hv_stores(ro, "jobs", newSViv(0));
        sup.supervisor_id = pq_register_worker(aTHX_ backend, 0, ro);
    }

    PQS_TERM = PQS_QUIT = PQS_HUP = PQS_CHLD = PQS_USR2 = 0;
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = pqs_sig;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = 0;                  /* no SA_RESTART: EINTR wakes poll */
    for (i = 0; i < 6; i++) sigaction(sigs[i], &sa, &old[i]);

    while (!sup.shutting_down) {
        if (PQS_QUIT) { sup.shutting_down = 1; break; }
        if (PQS_TERM)   sup.shutting_down = 1;
        if (sup.shutting_down) break;

        if (PQS_HUP) {
            PQS_HUP = 0;
            /* children finish their current job and exit 0; the loop
             * respawns them fresh - the zero-downtime recycle */
            pqs_kill_all(&sup, SIGTERM);
        }
        if (PQS_CHLD) { PQS_CHLD = 0; pqs_reap(aTHX_ &sup); }
        if (PQS_USR2) { PQS_USR2 = 0; pqs_status(&sup); }

        for (i = 0; i < sup.n; i++) {
            pqs_slot *s = &sup.slots[i];
            if (!s->pid && pq_now_local(aTHX) >= s->backoff_until)
                pqs_spawn(aTHX_ &sup, i);
        }

        {
            struct pollfd pfds[64];
            int npfd = 0;
            for (i = 0; i < sup.n && npfd < 64; i++) {
                if (sup.slots[i].pid && sup.slots[i].rfd >= 0) {
                    pfds[npfd].fd = sup.slots[i].rfd;
                    pfds[npfd].events = POLLIN;
                    pfds[npfd].revents = 0;
                    npfd++;
                }
            }
            (void)poll(pfds, (nfds_t)npfd, 1000);
            for (i = 0; i < sup.n; i++)
                if (sup.slots[i].pid && sup.slots[i].rfd >= 0)
                    pqs_pipe_drain(&sup.slots[i]);
        }

        pqs_check_timeouts(aTHX_ &sup);
        pqs_sched_pass(aTHX_ &sup);
    }

    /* shutdown: graceful unless QUIT asked for immediate */
    if (PQS_QUIT) {
        pqs_kill_all(&sup, SIGKILL);
        while (pqs_alive(&sup)) { pqs_reap(aTHX_ &sup); poll(NULL, 0, 50); }
    }
    else {
        double deadline = pq_now_local(aTHX) + sup.graceful_timeout;
        pqs_kill_all(&sup, SIGTERM);
        while (pqs_alive(&sup) && pq_now_local(aTHX) < deadline) {
            pqs_reap(aTHX_ &sup);
            poll(NULL, 0, 100);
        }
        if (pqs_alive(&sup)) {
            warn("punk-queue: %d worker(s) outlived the graceful window, "
                 "killing", pqs_alive(&sup));
            pqs_kill_all(&sup, SIGKILL);
            while (pqs_alive(&sup)) { pqs_reap(aTHX_ &sup); poll(NULL, 0, 50); }
        }
    }

    for (i = 0; i < 6; i++) sigaction(sigs[i], &old[i], NULL);
    /* hand the cron lease back so a standby takes over now, not in 30s */
    if (sup.leader) {
        int died = 0;
        SV *argv[2], *r;
        argv[0] = sv_2mortal(newSVpvs(PQS_LEADER_LOCK));
        argv[1] = sv_2mortal(newSViv(sup.supervisor_id));
        r = pq_call_meth_ev(aTHX_ backend, "unlock", argv, 2, 1, &died);
        if (r) SvREFCNT_dec(r);
    }
    {
        int died = 0;
        SV *argv[1], *r;
        argv[0] = sv_2mortal(newSViv(sup.supervisor_id));
        r = pq_call_meth_ev(aTHX_ backend, "unregister_worker", argv, 1, 1,
                            &died);
        if (r) SvREFCNT_dec(r);
    }
    for (i = 0; i < sup.n; i++) pqs_slot_close(&sup.slots[i]);
    safefree(sup.slots);
    return sup.exit_code;
}

#endif /* PQ_SUPER_H */

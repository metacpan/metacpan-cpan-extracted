#ifndef PQ_QUEUE_H
#define PQ_QUEUE_H

/* pq_queue.h - the Punk::Queue object: backend selection, the task
 * registry, and running one job.
 *
 * Punk::Queue is a thin front for a backend plus a table of task bodies.
 * Keeping the two apart is what lets a queue be inspected from a process
 * that has no task code at all - `punk-queue jobs` (phase 3) needs a
 * backend and nothing else, which is why every CLI subcommand can work
 * from --dsn with no app class.
 *
 * Include after pq_backend.h. */

/* The backend object behind a queue. Borrowed. */
static SV *pq_backend_of(pTHX_ SV *self) {
    HV *h = pq_hv(aTHX_ self, "Punk::Queue");
    SV *b = pq_get(aTHX_ h, "backend");
    if (!(b && SvROK(b)))
        croak("Punk::Queue: no backend - construct with "
              "Punk::Queue->new(dsn => ...)");
    return b;
}

/* dsn -> backend class. `backend => 'Foo'` overrides, '+Full::Class'
 * escapes to a literal class name, following the same convention Punk's
 * `views` and `database` keywords use. */
static SV *pq_backend_class(pTHX_ HV *opts) {
    SV *b = opts ? pq_get(aTHX_ opts, "backend") : NULL;
    SV *dsn = opts ? pq_get(aTHX_ opts, "dsn") : NULL;
    STRLEN l;
    const char *s;

    if (b && SvOK(b)) {
        s = SvPV_const(b, l);
        if (l && s[0] == '+') return sv_2mortal(newSVpvn(s + 1, l - 1));
        return sv_2mortal(Perl_newSVpvf(aTHX_ "Punk::Queue::Backend::%s", s));
    }

    if (!(dsn && SvOK(dsn)))
        croak("Punk::Queue: new() needs a dsn (or backend => 'Class')");

    s = SvPV_const(dsn, l);
    if (l >= 11 && memEQ(s, "dbi:SQLite:", 11))
        return sv_2mortal(newSVpvs("Punk::Queue::Backend::SQLite"));
    if (l >= 7 && memEQ(s, "dbi:Pg:", 7))
        return sv_2mortal(newSVpvs("Punk::Queue::Backend::Pg"));

    croak("Punk::Queue: no backend for dsn '%s' - shipped backends are "
          "SQLite and Pg; pass backend => 'Class' for anything else", s);
    return NULL;   /* not reached */
}

/* Load the backend class and instantiate it.
 *
 * A class that defines its own new() gets it called with the option list,
 * which is the seam a third-party backend needs. The shipped backends do
 * not: they are POD-only .pm files over XSUBs, so the default path blesses
 * the option hash directly, and pq_dbi.h reads `opts` off it.
 *
 * Returns +1, caller owns. */
static SV *pq_backend_construct(pTHX_ SV *bclass, HV *opts) {
    SV *loader = sv_2mortal(Perl_newSVpvf(aTHX_ "require %s;", SvPV_nolen(bclass)));
    HV *stash;

    eval_pv(SvPV_nolen(loader), FALSE);
    if (SvTRUE(ERRSV))
        croak("Punk::Queue: cannot load backend %s: %s",
              SvPV_nolen(bclass), SvPV_nolen(ERRSV));

    stash = gv_stashsv(bclass, 0);
    if (stash && gv_fetchmethod_autoload(stash, "new", 0)) {
        SV *argv[1], *obj;
        argv[0] = sv_2mortal(newRV_inc((SV *)opts));
        obj = pq_call_meth(aTHX_ bclass, "new", argv, 1, 1);
        if (!(obj && SvROK(obj))) {
            if (obj) SvREFCNT_dec(obj);
            croak("Punk::Queue: %s->new returned no object",
                  SvPV_nolen(bclass));
        }
        return obj;
    }

    {
        HV *h = newHV();
        SV *rv;
        (void)hv_stores(h, "opts", newRV_inc((SV *)opts));
        /* An externally supplied handle bypasses the pool; carry it
         * through so pq_dbh can find it. */
        {
            SV *dbh = pq_get(aTHX_ opts, "dbh");
            if (dbh && SvROK(dbh)) (void)hv_stores(h, "dbh", newSVsv(dbh));
        }
        rv = newRV_noinc((SV *)h);
        sv_bless(rv, gv_stashsv(bclass, GV_ADD));
        return rv;
    }
}

/* ---- auto-migration --------------------------------------------------------
 *
 * On by default (Minion parity), disabled with auto_migrate => 0.
 *
 * It fires on the first job operation, not in new() and not on
 * introspection: `Punk::Queue->new(...)->schema_version` must be able to
 * report 0 for an unmigrated database, which is exactly what a deploy
 * check wants to ask. Enqueueing into a database with no tables, on the
 * other hand, has no useful reading other than "migrate it".
 *
 * The flag flips before the migrate rather than after, so a failing
 * migration surfaces its own error once instead of being retried on every
 * subsequent call. */
static void pq_ensure_migrated(pTHX_ SV *self) {
    HV *h = pq_hv(aTHX_ self, "Punk::Queue");
    SV *done = pq_get(aTHX_ h, "migrated");
    HV *opts;
    SV *want;

    if (done && SvTRUE(done)) return;

    opts = pq_get_hv(aTHX_ h, "opts");
    want = opts ? pq_get(aTHX_ opts, "auto_migrate") : NULL;
    (void)hv_stores(h, "migrated", newSViv(1));
    if (want && !SvTRUE(want)) return;

    (void)pq_migrate(aTHX_ pq_backend_of(aTHX_ self), 0);
}

/* ---- the task registry ----------------------------------------------------- */

static HV *pq_tasks(pTHX_ SV *self) {
    HV *h = pq_hv(aTHX_ self, "Punk::Queue");
    HV *t = pq_get_hv(aTHX_ h, "tasks");
    if (!t) {
        t = newHV();
        (void)hv_stores(h, "tasks", newRV_noinc((SV *)t));
    }
    return t;
}

/* The body registered for a task name, or NULL. Borrowed. */
static SV *pq_task_body(pTHX_ SV *self, SV *name) {
    HV *t = pq_tasks(aTHX_ self);
    HE *he;
    if (!(name && SvOK(name))) return NULL;
    he = hv_fetch_ent(t, name, 0, 0);
    return he ? HeVAL(he) : NULL;
}

/* ---- defaults --------------------------------------------------------------
 *
 * Per-task and per-queue defaults, merged at enqueue in a fixed
 * precedence: explicit opts, then the task's defaults, then the queue's,
 * then the built-ins. The queue name is resolved AFTER the task defaults
 * merge, so a task whose defaults say `queue => 'mail'` picks up the mail
 * queue's defaults too - the rule an operator would guess.
 *
 * These live on the front object, not in the database: they are
 * application configuration, and two apps sharing one database may
 * legitimately disagree about them. */

static HV *pq_defaults_slot(pTHX_ SV *self, const char *slot) {
    HV *h = pq_hv(aTHX_ self, "Punk::Queue");
    HV *d = pq_get_hv(aTHX_ h, slot);
    if (!d) {
        d = newHV();
        (void)hv_store(h, slot, (I32)strlen(slot),
                       newRV_noinc((SV *)d), 0);
    }
    return d;
}

static void pq_defaults_apply(pTHX_ HV *defaults, SV *name, HV *opts) {
    HE *slot, *he;
    HV *d;
    if (!(name && SvOK(name))) return;
    slot = hv_fetch_ent(defaults, name, 0, 0);
    if (!slot) return;
    d = (SvROK(HeVAL(slot)) && SvTYPE(SvRV(HeVAL(slot))) == SVt_PVHV)
      ? (HV *)SvRV(HeVAL(slot)) : NULL;
    if (!d) return;
    hv_iterinit(d);
    while ((he = hv_iternext(d))) {
        SV *k = HeSVKEY_force(he);
        if (!hv_exists_ent(opts, k, 0))
            (void)hv_store_ent(opts, k, newSVsv(HeVAL(he)), 0);
    }
}

static void pq_merge_defaults(pTHX_ SV *self, SV *task, HV *opts) {
    SV *queue;
    pq_defaults_apply(aTHX_ pq_defaults_slot(aTHX_ self, "task_defaults"),
                      task, opts);
    queue = pq_get(aTHX_ opts, "queue");
    if (!(queue && SvOK(queue))) queue = sv_2mortal(newSVpvs("default"));
    pq_defaults_apply(aTHX_ pq_defaults_slot(aTHX_ self, "queue_defaults"),
                      queue, opts);
}

/* ---- the ALRM handler ------------------------------------------------------
 *
 * The croaking body behind the sync timeout layer. Installed into %SIG
 * around the task call, so Perl's safe signals deliver it between opcodes
 * and the die is caught by perform's G_EVAL like any task failure. */

XS_INTERNAL(pq_alrm_die) {
    dXSARGS;
    PERL_UNUSED_VAR(items);
    PERL_UNUSED_VAR(cv);
    croak("Punk::Queue: job timed out");
}

static SV *pq_alrm_handler(pTHX) {
    static CV *handler = NULL;
    if (!handler)
        handler = newXS("Punk::Queue::__alrm_die", pq_alrm_die, __FILE__);
    return newRV_inc((SV *)handler);
}

/* The on-loop timeout: fail the future, which surfaces through ->get as
 * the job's failure. Must not croak (hm contract), hence the G_EVAL. */
typedef struct pq_perform_to {
    SV *future;
    int fired;
} pq_perform_to;

static void pq_perform_to_cb(pTHX_ void *ud) {
    pq_perform_to *ctx = (pq_perform_to *)ud;
    int died = 0;
    SV *argv[1], *r;
    ctx->fired = 1;
    argv[0] = sv_2mortal(newSVpvs("Punk::Queue: job timed out"));
    r = pq_call_meth_ev(aTHX_ ctx->future, "fail", argv, 1, 1, &died);
    if (r) SvREFCNT_dec(r);
}

/* ---- running one job -------------------------------------------------------
 *
 * Look the task up, call it with ($job, @args) under G_EVAL, and settle the
 * row. A die becomes a failure with the message as the result; a return
 * value becomes the result.
 *
 * The Perl frame appears exactly here, at call_sv, which is the whole
 * argument for doing the surrounding machinery in C: the claim, the decode,
 * the settle and (from phase 3) the heartbeat and timeout timers cost no
 * Perl at all.
 *
 * Timeouts, layer by layer (the plan's honesty clause applies: only the
 * supervisor's SIGKILL is a hard guarantee):
 *   - off-loop, timeout > 0: alarm + a croaking ALRM handler around the
 *     call and any blocking future get. Best effort - safe signals cannot
 *     interrupt a blocking C call.
 *   - on-loop, timeout > 0, the task returned a future: a one-shot hm
 *     timer fails the future, and the failure surfaces through ->get. No
 *     alarm on this path: a die longjmping out of a loop callback would
 *     leave the dispatch loop inconsistent.
 *
 * Returns 1 if the job finished, 0 if it failed. */
static int pq_perform(pTHX_ SV *self, SV *job) {
    SV *backend = pq_backend_of(aTHX_ self);
    HV *jh   = pq_hv(aTHX_ job, "Punk::Queue::Job");
    HV *row  = pq_get_hv(aTHX_ jh, "row");
    SV *name = row ? pq_get(aTHX_ row, "task") : NULL;
    SV *body, *args;
    IV id, retries;
    SV *result = NULL;
    int died = 0;
    double timeout = 0.0;
    const hm_abi *A = pq_hm(aTHX);
    void *loop = A ? A->cur_loop(aTHX) : NULL;
    int used_alarm = 0;
    SV *old_alrm = NULL;

    {
        SV *t = row ? pq_get(aTHX_ row, "timeout") : NULL;
        if (t && SvOK(t)) timeout = SvNV(t);
    }

    if (!row) croak("Punk::Queue: not a job object");
    id      = (pq_get(aTHX_ row, "id")      ? SvIV(pq_get(aTHX_ row, "id"))      : 0);
    retries = (pq_get(aTHX_ row, "retries") ? SvIV(pq_get(aTHX_ row, "retries")) : 0);

    body = pq_task_body(aTHX_ self, name);
    if (!(body && SvROK(body) && SvTYPE(SvRV(body)) == SVt_PVCV)) {
        /* A queue holding jobs for a task this process does not know is
         * normal in a mixed deployment - a rolling deploy, or a worker
         * started with a narrower --task list. Fail the job with a clear
         * message; do not take the process down over it. */
        SV *msg = sv_2mortal(Perl_newSVpvf(aTHX_
                      "Punk::Queue: no task registered for '%s'",
                      (name && SvOK(name)) ? SvPV_nolen(name) : "(undef)"));
        (void)pq_fail_job(aTHX_ backend, id, retries, msg);
        return 0;
    }

    args = pq_get(aTHX_ row, "args");

    if (timeout > 0 && !loop) {
        HV *sig = get_hv("SIG", GV_ADD);
        SV **e = hv_fetchs(sig, "ALRM", 0);
        old_alrm = (e && *e && SvOK(*e)) ? newSVsv(*e) : NULL;
        /* %SIG is magical and hv_store does not run set-magic: without the
         * explicit SvSETMAGIC, Perl never installs the OS handler and the
         * alarm kills the process with default disposition instead of
         * raising our die. */
        e = hv_stores(sig, "ALRM", pq_alrm_handler(aTHX));
        if (e) SvSETMAGIC(*e);
        (void)alarm((unsigned)(timeout + 0.999));
        used_alarm = 1;
    }

    {
        dSP;
        SSize_t n = 0, i;
        AV *av = (args && SvROK(args) && SvTYPE(SvRV(args)) == SVt_PVAV)
                 ? (AV *)SvRV(args) : NULL;
        int count;
        if (av) n = av_len(av) + 1;

        ENTER; SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, n + 1);
        PUSHs(job);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            PUSHs((e && *e) ? *e : &PL_sv_undef);
        }
        PUTBACK;
        count = call_sv(body, G_SCALAR | G_EVAL);
        SPAGAIN;
        /* +1 before FREETMPS, or the value is freed underneath us. */
        if (count > 0) result = SvREFCNT_inc(POPs);
        died = SvTRUE(ERRSV) ? 1 : 0;
        if (died) {
            if (result) { SvREFCNT_dec(result); result = NULL; }
            result = newSVsv(ERRSV);
        }
        PUTBACK; FREETMPS; LEAVE;
    }

    /* A returned future - anything blessed with a get method, the same
     * duck-typing punk_future.h's dispatcher uses - is awaited and its
     * value becomes the result. Inside a worker's loop tick, ->get on a
     * loop-mode future re-enters run_until, so the worker's own timers
     * keep firing while the job awaits; off-loop it blocks, which is the
     * documented degraded behaviour. A get that dies is the job failing. */
    if (!died && result && SvROK(result) && SvOBJECT(SvRV(result))) {
        HV *stash = SvSTASH(SvRV(result));
        if (stash && gv_fetchmethod_autoload(stash, "get", 0)) {
            int gdied = 0;
            SV *got;
            pq_perform_to ctx;
            hm_abi_timer *t = NULL;

            ctx.future = result;
            ctx.fired  = 0;
            if (timeout > 0 && loop)
                t = A->timer(aTHX_ loop, timeout, pq_perform_to_cb, &ctx);

            got = pq_call_meth_ev(aTHX_ result, "get", NULL, 0, 1, &gdied);

            /* never cancel after the fire: the handle is freed then */
            if (t && !ctx.fired) A->timer_cancel(aTHX_ loop, t);

            SvREFCNT_dec(result);
            if (gdied) {
                if (got) SvREFCNT_dec(got);
                result = newSVsv(ERRSV);
                died = 1;
            }
            else {
                result = got ? got : newSV(0);
            }
        }
    }

    if (used_alarm) {
        HV *sig = get_hv("SIG", GV_ADD);
        SV **e;
        (void)alarm(0);
        e = hv_stores(sig, "ALRM", old_alrm ? old_alrm : newSV(0));
        if (e) SvSETMAGIC(*e);
    }

    if (died) (void)pq_fail_job(aTHX_ backend, id, retries, result);
    else      (void)pq_finish_job(aTHX_ backend, id, retries, result);

    if (result) SvREFCNT_dec(result);
    return died ? 0 : 1;
}

#endif /* PQ_QUEUE_H */

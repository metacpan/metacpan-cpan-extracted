#ifndef PQ_BACKEND_H
#define PQ_BACKEND_H

/* pq_backend.h - the shared backend implementation, plus the per-driver
 * dispatch.
 *
 * The split is the point of this file. Everything below the dispatch block
 * is written once and behaves identically on every backend, and the
 * conformance suite (t/lib/PQConform.pm) exists to prove that claim rather
 * than assert it. What a backend genuinely has to do differently is exactly
 * the seven entries dispatched here.
 *
 * If you are adding a third backend: the operations below are the ones you
 * do NOT need to touch.
 *
 * Include after pq_sqlite.h and pq_pg.h. */

/* ---- per-driver dispatch ---------------------------------------------------
 *
 * Dispatch is on the DBI driver name rather than on the class, so a
 * subclass of a shipped backend keeps working, and a hand-written backend
 * that never reaches this file is unaffected. */

static int pq_is_pg(pTHX_ SV *self) {
    return pq_driver_is(aTHX_ pq_dbh(aTHX_ self), "Pg");
}

static double pq_probe_clock(pTHX_ SV *dbh) {
    if (pq_driver_is(aTHX_ dbh, "SQLite")) return pq_sqlite_probe_clock(aTHX_ dbh);
    if (pq_driver_is(aTHX_ dbh, "Pg"))     return pq_pg_probe_clock(aTHX_ dbh);
    /* An unknown driver is not fatal: a zero delta just means "trust the
     * local clock", which is what a single-host deployment has anyway. */
    return 0.0;
}

static void pq_txn_begin_exclusive(pTHX_ SV *self) {
    if (pq_is_pg(aTHX_ self)) pq_pg_begin_exclusive(aTHX_ self);
    else                      pq_sqlite_begin_exclusive(aTHX_ self);
}

/* The plain transaction the state transitions use: no advisory lock - on
 * Pg the migrate lock would serialise every finish across the fleet. */
static void pq_txn_begin(pTHX_ SV *self) {
    if (pq_is_pg(aTHX_ self)) pq_pg_begin(aTHX_ self);
    else                      pq_sqlite_begin_exclusive(aTHX_ self);
}

static void pq_txn_commit(pTHX_ SV *self) {
    if (pq_is_pg(aTHX_ self)) pq_pg_commit(aTHX_ self);
    else                      pq_sqlite_commit(aTHX_ self);
}

static void pq_txn_rollback(pTHX_ SV *self) PERL_UNUSED_DECL;
static void pq_txn_rollback(pTHX_ SV *self) {
    if (pq_is_pg(aTHX_ self)) pq_pg_rollback(aTHX_ self);
    else                      pq_sqlite_rollback(aTHX_ self);
}

static const char *const *pq_migration_steps(pTHX_ SV *self) {
    return pq_is_pg(aTHX_ self) ? pq_pg_steps(aTHX) : pq_sqlite_steps(aTHX);
}

static void pq_check_server_version(pTHX_ SV *self) {
    if (pq_is_pg(aTHX_ self)) pq_pg_check_version(aTHX_ self);
    else                      pq_sqlite_check_version(aTHX_ self);
}

static SV *pq_dequeue(pTHX_ SV *self, IV worker_id, AV *queues, AV *tasks) {
    SV *job = pq_is_pg(aTHX_ self)
            ? pq_pg_dequeue(aTHX_ self, worker_id, queues, tasks)
            : pq_sqlite_dequeue(aTHX_ self, worker_id, queues, tasks);
    if (job && SvROK(job)) {
        HV *row = (HV *)SvRV(job);
        SV *id = pq_get(aTHX_ row, "id");
        SV *rt = pq_get(aTHX_ row, "retries");
        SV *at = pq_get(aTHX_ row, "attempts");
        if (id && SvOK(id))
            pq_log_addf(aTHX_ self, SvIV(id), "info",
                        "claimed by worker %ld (attempt %ld of %ld)",
                        (long)worker_id,
                        (long)((rt && SvOK(rt)) ? SvIV(rt) : 0) + 1,
                        (long)((at && SvOK(at)) ? SvIV(at) : 1));
    }
    return job;
}

static void pq_notify(pTHX_ SV *self, SV *queue, IV id) {
    if (pq_is_pg(aTHX_ self)) pq_pg_notify(aTHX_ self, queue, id);
    else                      pq_sqlite_notify(aTHX_ self, queue, id);
}

/* ---- enqueue ---------------------------------------------------------------
 *
 * opts: queue, priority, delay, attempts, expire, notes, timeout, lax,
 * unique, parents.
 *
 * With parents, the whole enqueue is one transaction and the parent rows
 * are read under a lock (FOR UPDATE on Pg; BEGIN IMMEDIATE covers SQLite):
 * without that, a parent finishing between our read and our commit would
 * decrement children it cannot see yet, and this child would hang forever
 * with parents_left = 1. That interleaving is exactly the drift the
 * conformance battery hunts.
 *
 * A parent id that does not exist is treated as already gone - the same
 * reading Minion takes - so a chain can be enqueued even after early
 * members were removed by retention. */
static IV pq_enqueue(pTHX_ SV *self, SV *task, SV *args, HV *opts) {
    SV *sql, *queue, *notes_json, *args_json, *v;
    SV *unique = NULL;
    AV *bind, *parents = NULL;
    double now, delayed, expires = 0.0, timeout = 0.0;
    int has_expires = 0, has_timeout = 0, lax = 0, in_txn = 0;
    IV priority = 0, attempts = 1, id = 0;

    pq_name_check(aTHX_ task, "task");

    queue = opts ? pq_get(aTHX_ opts, "queue") : NULL;
    if (queue && SvOK(queue)) pq_name_check(aTHX_ queue, "queue");
    else                      queue = sv_2mortal(newSVpvs("default"));

    if (opts) {
        if ((v = pq_get(aTHX_ opts, "priority")) && SvOK(v)) priority = SvIV(v);
        if ((v = pq_get(aTHX_ opts, "attempts")) && SvOK(v)) attempts = SvIV(v);
        if (attempts < 1)
            croak("Punk::Queue: attempts must be at least 1, not %ld",
                  (long)attempts);
        if ((v = pq_get(aTHX_ opts, "lax")) && SvTRUE(v)) lax = 1;
        if ((v = pq_get(aTHX_ opts, "unique")) && SvOK(v)) {
            pq_name_check(aTHX_ v, "unique");
            unique = v;
        }
        if ((v = pq_get(aTHX_ opts, "timeout")) && SvOK(v)) {
            timeout = SvNV(v);
            has_timeout = timeout > 0;
        }
        if ((v = pq_get(aTHX_ opts, "parents")) && SvOK(v)) {
            if (!(SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV))
                croak("Punk::Queue: parents must be an array reference");
            parents = (AV *)SvRV(v);
            if (av_len(parents) < 0) parents = NULL;
        }
    }

    now = pq_now(aTHX_ self);
    delayed = now;
    if (opts) {
        if ((v = pq_get(aTHX_ opts, "delay")) && SvOK(v))
            delayed = now + SvNV(v);
        if ((v = pq_get(aTHX_ opts, "expire")) && SvOK(v)) {
            expires = now + SvNV(v);
            has_expires = 1;
        }
    }

    args_json  = sv_2mortal(pq_json_encode(aTHX_ args, "[]"));
    notes_json = sv_2mortal(pq_json_encode(aTHX_
                     opts ? pq_get(aTHX_ opts, "notes") : NULL, "{}"));

    if (parents) { pq_txn_begin(aTHX_ self); in_txn = 1; }

    sql = pq_sql_new(aTHX_
        "INSERT INTO pq_jobs"
        " (task, args, queue, state, priority, attempts, created, delayed,"
        "  expires, notes, timeout, lax, lock_key)"
        " VALUES (?, ?, ?, 'inactive', ?, ?, ?, ?, ?, ?, ?, ?, ?)");

    bind = pq_binds(aTHX);
    pq_bind_sv(aTHX_ bind, task);
    pq_bind_sv(aTHX_ bind, args_json);
    pq_bind_sv(aTHX_ bind, queue);
    pq_bind_iv(aTHX_ bind, priority);
    pq_bind_iv(aTHX_ bind, attempts);
    pq_bind_nv(aTHX_ bind, now);
    pq_bind_nv(aTHX_ bind, delayed);
    if (has_expires) pq_bind_nv(aTHX_ bind, expires);
    else             pq_bind_undef(aTHX_ bind);
    pq_bind_sv(aTHX_ bind, notes_json);
    if (has_timeout) pq_bind_nv(aTHX_ bind, timeout);
    else             pq_bind_undef(aTHX_ bind);
    pq_bind_iv(aTHX_ bind, lax);
    if (unique) pq_bind_sv(aTHX_ bind, unique);
    else        pq_bind_undef(aTHX_ bind);

    /* The insert is trapped only when `unique` is set: the partial unique
     * index rejecting a second live job with the same key is the expected
     * path there, and the answer is the existing job's id, not an error. */
    {
        int died = 0;
        SV *sth, *errmsg = NULL;
        if (pq_has_returning(aTHX_ self)) pq_sql_cat(aTHX_ sql, " RETURNING id");

        sth = pq_sth(aTHX_ self, sql);   /* mortal, borrowed for this scope */
        {
            SSize_t n = av_len(bind) + 1, i;
            SV **ea = (SV **)pq_xmalloc(aTHX_ sizeof(SV *) * (size_t)n);
            SV *r;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(bind, i, 0);
                ea[i] = (e && *e) ? *e : &PL_sv_undef;
            }
            r = pq_call_meth_ev(aTHX_ sth, "execute", ea, (int)n, 1, &died);
            safefree(ea);
            if (r) SvREFCNT_dec(r);
        }
        if (died) {
            errmsg = sv_2mortal(newSVsv(ERRSV));
            if (in_txn) { pq_txn_rollback(aTHX_ self); in_txn = 0; }
            if (unique) {
                AV *b2 = pq_binds(aTHX), *row;
                pq_bind_sv(aTHX_ b2, unique);
                row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
                    "SELECT id FROM pq_jobs WHERE lock_key = ?"
                    " AND state IN ('inactive', 'active')")), b2);
                if (row) {
                    id = pq_col_iv(aTHX_ row, 0);
                    SvREFCNT_dec((SV *)row);
                    return id;    /* the existing live job */
                }
            }
            croak_sv(errmsg);
        }
        if (pq_has_returning(aTHX_ self)) {
            AV *row = pq_fetchrow(aTHX_ sth);
            if (row) { id = pq_col_iv(aTHX_ row, 0); SvREFCNT_dec((SV *)row); }
            { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
              if (r) SvREFCNT_dec(r); }
        }
        else id = pq_last_insert_id(aTHX_ self);
    }

    if (!id) {
        if (in_txn) pq_txn_rollback(aTHX_ self);
        croak("Punk::Queue: enqueue produced no job id");
    }

    if (parents) {
        SSize_t np = av_len(parents) + 1, i, nseen = 0;
        IV blocking = 0;
        IV *seen = (IV *)pq_xmalloc(aTHX_ sizeof(IV) * (size_t)np);

        for (i = 0; i < np; i++) {
            SV **e = av_fetch(parents, i, 0);
            IV pid_;
            AV *b, *row;
            SV *psql;
            SSize_t k;
            int dupe = 0;
            if (!(e && *e && SvOK(*e))) continue;
            pid_ = SvIV(*e);
            if (pid_ == id) continue;          /* self-dependency is nonsense */

            /* dedupe in C rather than letting the deps PK reject it: an
             * error inside a Pg transaction aborts the whole transaction
             * (the phase-2 lesson), so a trapped constraint violation is
             * not a tool available in here */
            for (k = 0; k < nseen; k++)
                if (seen[k] == pid_) { dupe = 1; break; }
            if (dupe) continue;
            seen[nseen++] = pid_;

            /* lock the parent row while we decide whether it blocks */
            psql = pq_sql_new(aTHX_
                "SELECT state FROM pq_jobs WHERE id = ?");
            if (pq_is_pg(aTHX_ self)) pq_sql_cat(aTHX_ psql, " FOR UPDATE");
            b = pq_binds(aTHX);
            pq_bind_iv(aTHX_ b, pid_);
            row = pq_selectrow(aTHX_ self, psql, b);
            if (!row) continue;                /* gone = already done */

            {
                SV *st = pq_col(aTHX_ row, 0);
                const char *s = SvOK(st) ? SvPV_nolen(st) : "";
                int done = lax ? (strEQ(s, "finished") || strEQ(s, "failed"))
                               : strEQ(s, "finished");
                SvREFCNT_dec((SV *)row);

                /* the dep row records lineage even when not blocking */
                {
                    AV *b2 = pq_binds(aTHX);
                    pq_bind_iv(aTHX_ b2, id);
                    pq_bind_iv(aTHX_ b2, pid_);
                    (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                        "INSERT INTO pq_job_deps (job_id, parent_id)"
                        " VALUES (?, ?)")), b2);
                }
                if (!done) blocking++;
            }
        }
        safefree(seen);

        if (blocking) {
            AV *b = pq_binds(aTHX);
            pq_bind_iv(aTHX_ b, blocking);
            pq_bind_iv(aTHX_ b, id);
            (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                "UPDATE pq_jobs SET parents_left = ? WHERE id = ?")), b);
        }
        pq_txn_commit(aTHX_ self);
    }

    /* Wake a listening worker. After the commit, so on Pg the NOTIFY and
     * the row arrive in the right order (pg_notify inside the transaction
     * would also have worked - delivery is at commit - but emitting after
     * keeps the no-parents autocommit path and the parents path
     * identical). No-op on SQLite. */
    pq_notify(aTHX_ self, queue, id);

    return id;
}

/* ---- reads ----------------------------------------------------------------- */

/* One job as a plain hashref (+1), or NULL when there is no such id.
 * Includes `parents`, the surviving parent ids - the UI's lineage links
 * and the CLI's `job <id>` view both want them, and a second indexed
 * lookup is cheaper than teaching the row decode a join. */
static SV *pq_job_info(pTHX_ SV *self, IV id) {
    AV *bind = pq_binds(aTHX), *row;
    HV *h;
    pq_bind_iv(aTHX_ bind, id);
    row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
        "SELECT " PQ_JOB_COLS " FROM pq_jobs WHERE id = ?")), bind);
    if (!row) return NULL;
    h = pq_job_row_hv(aTHX_ row);
    SvREFCNT_dec((SV *)row);

    {
        AV *parents = newAV();
        SV *sth;
        AV *b2 = pq_binds(aTHX), *prow;
        pq_bind_iv(aTHX_ b2, id);
        sth = pq_sth(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT parent_id FROM pq_job_deps WHERE job_id = ?"
            " ORDER BY parent_id")));
        (void)pq_execute(aTHX_ sth, b2);
        while ((prow = pq_fetchrow(aTHX_ sth))) {
            av_push(parents, newSViv(pq_col_iv(aTHX_ prow, 0)));
            SvREFCNT_dec((SV *)prow);
        }
        { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
          if (r) SvREFCNT_dec(r); }
        (void)hv_stores(h, "parents", newRV_noinc((SV *)parents));
    }
    return newRV_noinc((SV *)h);
}

/* ---- backoff ---------------------------------------------------------------
 *
 * Full jitter: uniform(0, min(cap, base * 2^retries)). Full rather than
 * equal or none, because a burst of jobs that all failed against the same
 * downed dependency must not come back in lockstep. Seeded per process
 * from pid ^ time - unseeded children of one supervisor would jitter
 * identically, which is the lockstep again with extra steps. */
static double pq_rand01(pTHX) {
    static int seeded = 0;
    if (!seeded) {
        seeded = 1;
        srand48((long)PerlProc_getpid() ^ (long)time(NULL));
    }
    return drand48();
}

#define PQ_BACKOFF_BASE_DEFAULT 5.0
#define PQ_BACKOFF_CAP_DEFAULT  3600.0

/* pq_opt_num moved to pq_dbi.h so pq_log.h (included earlier) can gate
 * the lifecycle rows on the `logging` option */

static double pq_backoff_delay(pTHX_ SV *self, IV retries) {
    double base = pq_opt_num(aTHX_ self, "attempts_delay",
                                 PQ_BACKOFF_BASE_DEFAULT);
    double cap  = pq_opt_num(aTHX_ self, "max_backoff",
                                 PQ_BACKOFF_CAP_DEFAULT);
    double d = base;
    IV i;
    for (i = 0; i < retries && d < cap; i++) d *= 2.0;
    if (d > cap) d = cap;
    return pq_rand01(aTHX) * d;
}

/* ---- parents_left maintenance ----------------------------------------------
 *
 * THE correctness risk of the whole design, so the rules live in one place
 * and every mutation goes through this function, inside the transition's
 * transaction:
 *
 *   parent finishes            -> -1 every child
 *   parent fails terminally    -> -1 lax children only (non-lax stay
 *                                 blocked until the parent is retried or
 *                                 removed)
 *   finished parent retried    -> +1 every child (they had counted it done)
 *   failed parent retried      -> +1 lax children only
 *   inactive parent removed    -> -1 every child
 *   failed parent removed      -> -1 non-lax children (lax already got
 *                                 theirs at the fail)
 *   finished parent removed    -> nothing (everyone got theirs)
 *
 * The conformance battery recomputes the truth from pq_job_deps after
 * every transition it performs, so a missed rule here fails loudly there. */

enum { PQ_KIDS_ALL, PQ_KIDS_LAX, PQ_KIDS_NONLAX };

static void pq_children_adjust(pTHX_ SV *self, IV parent_id, IV delta,
                               int which) {
    AV *bind = pq_binds(aTHX);
    SV *sql = pq_sql_new(aTHX_
        "UPDATE pq_jobs SET parents_left = parents_left + ?"
        " WHERE id IN (SELECT job_id FROM pq_job_deps WHERE parent_id = ?)");
    pq_bind_iv(aTHX_ bind, delta);
    pq_bind_iv(aTHX_ bind, parent_id);
    if (which == PQ_KIDS_LAX)    pq_sql_cat(aTHX_ sql, " AND lax = 1");
    if (which == PQ_KIDS_NONLAX) pq_sql_cat(aTHX_ sql, " AND lax = 0");
    (void)pq_do(aTHX_ self, sql, bind);
}

/* The row's (state, attempts) under the retries guard, inside the caller's
 * transaction. Returns 1 and fills the outputs, or 0 when the guard missed. */
static int pq_guarded_peek(pTHX_ SV *self, IV id, IV retries,
                           char *state, size_t statelen, IV *attempts) {
    AV *bind = pq_binds(aTHX), *row;
    pq_bind_iv(aTHX_ bind, id);
    pq_bind_iv(aTHX_ bind, retries);
    row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
        "SELECT state, attempts FROM pq_jobs"
        " WHERE id = ? AND retries = ?")), bind);
    if (!row) return 0;
    {
        SV *st = pq_col(aTHX_ row, 0);
        my_strlcpy(state, SvOK(st) ? SvPV_nolen(st) : "", statelen);
        *attempts = pq_col_iv(aTHX_ row, 1);
    }
    SvREFCNT_dec((SV *)row);
    return 1;
}

/* ---- the transitions -------------------------------------------------------
 *
 * All take the caller's idea of `retries` as an optimistic guard: repair
 * requeues a vanished worker's job by bumping retries, and without the
 * guard the original worker - possibly still alive and about to report -
 * would clobber the new attempt. Minion's trick, and load-bearing.
 *
 * All return 1 when the transition applied, 0 when the guard rejected it.
 * A 0 is information, not an error: the caller lost a race it is allowed
 * to lose. All are transactions, because the job row and its children's
 * counters must move together or the drift check catches us. */

static IV pq_finish_job(pTHX_ SV *self, IV id, IV retries, SV *result) {
    AV *bind = pq_binds(aTHX);
    SV *json = sv_2mortal(pq_json_encode(aTHX_ result, "null"));
    IV took;

    pq_txn_begin(aTHX_ self);
    pq_bind_nv(aTHX_ bind, pq_now(aTHX_ self));
    pq_bind_sv(aTHX_ bind, json);
    pq_bind_iv(aTHX_ bind, id);
    pq_bind_iv(aTHX_ bind, retries);
    took = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
        "UPDATE pq_jobs SET state = 'finished', finished = ?, result = ?"
        " WHERE id = ? AND retries = ? AND state = 'active'")), bind);
    if (took > 0) {
        pq_children_adjust(aTHX_ self, id, -1, PQ_KIDS_ALL);
        pq_log_addf(aTHX_ self, id, "info", "finished");
    }
    pq_txn_commit(aTHX_ self);
    return took > 0 ? 1 : 0;
}

/* fail: backoff-retry when attempts remain, terminal failure when not.
 * The error lands in result either way, so the last failure is visible
 * while the job waits out its backoff. */
static IV pq_fail_job(pTHX_ SV *self, IV id, IV retries, SV *err) {
    SV *json = sv_2mortal(pq_json_encode(aTHX_ err, "null"));
    char state[16];
    IV attempts = 0, took = 0;
    double now;

    pq_txn_begin(aTHX_ self);
    if (!pq_guarded_peek(aTHX_ self, id, retries, state, sizeof state,
                         &attempts)
        || strNE(state, "active")) {
        pq_txn_commit(aTHX_ self);
        return 0;
    }
    now = pq_now(aTHX_ self);

    if (retries + 1 < attempts) {
        double delay = pq_backoff_delay(aTHX_ self, retries);
        AV *bind = pq_binds(aTHX);
        pq_bind_nv(aTHX_ bind, now);
        pq_bind_nv(aTHX_ bind, now + delay);
        pq_bind_sv(aTHX_ bind, json);
        pq_bind_iv(aTHX_ bind, id);
        pq_bind_iv(aTHX_ bind, retries);
        took = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "UPDATE pq_jobs SET state = 'inactive',"
            " retries = retries + 1, retried = ?, delayed = ?,"
            " started = NULL, worker = NULL, result = ?"
            " WHERE id = ? AND retries = ? AND state = 'active'")), bind);
        /* still blocking its children exactly as before: no adjustment */
        if (took > 0) {
            char ebuf[PQ_LOG_ERRMAX];
            pq_log_addf(aTHX_ self, id, "warn",
                        "attempt %ld of %ld failed: %s - retry due in %.1fs",
                        (long)(retries + 1), (long)attempts,
                        pq_log_errpv(aTHX_ err, ebuf, sizeof ebuf),
                        (NV)delay);
        }
    }
    else {
        AV *bind = pq_binds(aTHX);
        pq_bind_nv(aTHX_ bind, now);
        pq_bind_sv(aTHX_ bind, json);
        pq_bind_iv(aTHX_ bind, id);
        pq_bind_iv(aTHX_ bind, retries);
        took = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "UPDATE pq_jobs SET state = 'failed', finished = ?, result = ?"
            " WHERE id = ? AND retries = ? AND state = 'active'")), bind);
        if (took > 0) {
            char ebuf[PQ_LOG_ERRMAX];
            pq_children_adjust(aTHX_ self, id, -1, PQ_KIDS_LAX);
            pq_log_addf(aTHX_ self, id, "error",
                        "failed after %ld of %ld attempts: %s",
                        (long)(retries + 1), (long)attempts,
                        pq_log_errpv(aTHX_ err, ebuf, sizeof ebuf));
        }
    }
    pq_txn_commit(aTHX_ self);
    return took > 0 ? 1 : 0;
}

/* retry_job requeues from ANY state, deliberately - retrying an `active`
 * job is exactly how a stuck job is recovered from the outside: the bump
 * invalidates the running attempt's guard, so whatever the stale worker
 * eventually reports lands on a row that no longer matches. The same
 * guard protects THIS call: two operators retrying at once apply exactly
 * one bump.
 *
 * opts (each optional): delay, priority, queue, attempts. */
static IV pq_retry_job(pTHX_ SV *self, IV id, IV retries, HV *opts) {
    AV *bind = pq_binds(aTHX);
    double now, delay = 0.0;
    char prestate[16];
    IV attempts_col = 0, took;
    SV *sql, *v;

    pq_txn_begin(aTHX_ self);
    if (!pq_guarded_peek(aTHX_ self, id, retries, prestate, sizeof prestate,
                         &attempts_col)) {
        pq_txn_commit(aTHX_ self);
        return 0;
    }
    now = pq_now(aTHX_ self);

    sql = pq_sql_new(aTHX_
        "UPDATE pq_jobs SET state = 'inactive', retries = retries + 1,"
        " retried = ?, delayed = ?, started = NULL, finished = NULL,"
        " worker = NULL, result = NULL");
    if (opts && (v = pq_get(aTHX_ opts, "delay")) && SvOK(v))
        delay = SvNV(v);
    pq_bind_nv(aTHX_ bind, now);
    pq_bind_nv(aTHX_ bind, now + delay);

    if (opts && (v = pq_get(aTHX_ opts, "priority")) && SvOK(v)) {
        pq_sql_cat(aTHX_ sql, ", priority = ?");
        pq_bind_iv(aTHX_ bind, SvIV(v));
    }
    if (opts && (v = pq_get(aTHX_ opts, "queue")) && SvOK(v)) {
        pq_name_check(aTHX_ v, "queue");
        pq_sql_cat(aTHX_ sql, ", queue = ?");
        pq_bind_sv(aTHX_ bind, v);
    }
    if (opts && (v = pq_get(aTHX_ opts, "attempts")) && SvOK(v)) {
        if (SvIV(v) < 1) {
            pq_txn_rollback(aTHX_ self);
            croak("Punk::Queue: attempts must be at least 1, not %ld",
                  (long)SvIV(v));
        }
        pq_sql_cat(aTHX_ sql, ", attempts = ?");
        pq_bind_iv(aTHX_ bind, SvIV(v));
    }

    pq_sql_cat(aTHX_ sql, " WHERE id = ? AND retries = ?");
    pq_bind_iv(aTHX_ bind, id);
    pq_bind_iv(aTHX_ bind, retries);

    took = pq_do(aTHX_ self, sql, bind);
    if (took > 0) {
        /* the children had counted this parent done; block them again */
        if (strEQ(prestate, "finished"))
            pq_children_adjust(aTHX_ self, id, +1, PQ_KIDS_ALL);
        else if (strEQ(prestate, "failed"))
            pq_children_adjust(aTHX_ self, id, +1, PQ_KIDS_LAX);
        pq_log_addf(aTHX_ self, id, "info",
                    delay > 0 ? "retried from '%s' - due in %.1fs"
                              : "retried from '%s'",
                    prestate, (NV)delay);
    }
    pq_txn_commit(aTHX_ self);
    return took > 0 ? 1 : 0;
}

/* remove_job refuses an active job: the worker running it would finish
 * into a void and the supervision bookkeeping would point at a ghost.
 * Retry it first (which strands the running attempt), then remove. Dep
 * rows cascade via the foreign keys - but only after the children's
 * counters are adjusted, because the adjustment needs the dep rows to
 * find them. */
static IV pq_remove_job(pTHX_ SV *self, IV id) {
    char prestate[16];
    IV attempts = 0, took = 0;

    pq_txn_begin(aTHX_ self);
    {
        AV *bind = pq_binds(aTHX), *row;
        pq_bind_iv(aTHX_ bind, id);
        row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT state, attempts FROM pq_jobs WHERE id = ?")), bind);
        if (!row) { pq_txn_commit(aTHX_ self); return 0; }
        {
            SV *st = pq_col(aTHX_ row, 0);
            my_strlcpy(prestate, SvOK(st) ? SvPV_nolen(st) : "",
                       sizeof prestate);
            attempts = pq_col_iv(aTHX_ row, 1);
        }
        SvREFCNT_dec((SV *)row);
        PERL_UNUSED_VAR(attempts);
    }
    if (strEQ(prestate, "active")) {
        pq_txn_commit(aTHX_ self);
        return 0;
    }

    if (strEQ(prestate, "inactive"))
        pq_children_adjust(aTHX_ self, id, -1, PQ_KIDS_ALL);
    else if (strEQ(prestate, "failed"))
        pq_children_adjust(aTHX_ self, id, -1, PQ_KIDS_NONLAX);
    /* finished: every child already got its decrement */

    {
        AV *bind = pq_binds(aTHX);
        pq_bind_iv(aTHX_ bind, id);
        took = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "DELETE FROM pq_jobs WHERE id = ?"
            " AND state IN ('inactive', 'failed', 'finished')")), bind);
    }
    if (took > 0) {
        AV *bind = pq_binds(aTHX);
        pq_bind_iv(aTHX_ bind, id);
        (void)pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "DELETE FROM pq_job_logs WHERE job_id = ?")), bind);
    }
    pq_txn_commit(aTHX_ self);
    return took > 0 ? 1 : 0;
}

/* ---- notes -----------------------------------------------------------------
 *
 * Merge, not replace, and merged in C after an frj decode rather than in
 * SQL - json_patch exists on neither backend in a portable form, and the
 * conformance suite requires byte-identical behaviour. A key set to undef
 * is deleted. Works in any state: progress notes on an active job are the
 * whole point. */
static IV pq_note(pTHX_ SV *self, IV id, HV *merge) {
    AV *bind, *row;
    SV *decoded, *json;
    HV *notes;
    IV took;

    if (!merge) return 0;

    pq_txn_begin(aTHX_ self);
    bind = pq_binds(aTHX);
    pq_bind_iv(aTHX_ bind, id);
    row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
        "SELECT notes FROM pq_jobs WHERE id = ?")), bind);
    if (!row) { pq_txn_commit(aTHX_ self); return 0; }

    decoded = sv_2mortal(pq_json_decode(aTHX_ pq_col(aTHX_ row, 0)));
    SvREFCNT_dec((SV *)row);
    notes = (SvROK(decoded) && SvTYPE(SvRV(decoded)) == SVt_PVHV)
          ? (HV *)SvRV(decoded) : (HV *)sv_2mortal((SV *)newHV());

    {
        HE *he;
        hv_iterinit(merge);
        while ((he = hv_iternext(merge))) {
            SV *val = HeVAL(he);
            if (val && SvOK(val))
                (void)hv_store_ent(notes, HeSVKEY_force(he),
                                   newSVsv(val), 0);
            else
                (void)hv_delete_ent(notes, HeSVKEY_force(he), G_DISCARD, 0);
        }
    }

    json = sv_2mortal(pq_json_encode(aTHX_
               sv_2mortal(newRV_inc((SV *)notes)), "{}"));
    bind = pq_binds(aTHX);
    pq_bind_sv(aTHX_ bind, json);
    pq_bind_iv(aTHX_ bind, id);
    took = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
        "UPDATE pq_jobs SET notes = ? WHERE id = ?")), bind);
    pq_txn_commit(aTHX_ self);
    return took > 0 ? 1 : 0;
}

/* ---- the worker registry ---------------------------------------------------
 *
 * One row per process that claims jobs. `-j 4` is four child processes and
 * four rows (the deliberate departure from Minion), because timeout
 * enforcement and the admin UI want per-child granularity - a supervisor
 * row with jobs=4 cannot tell you which child is stuck. */

static void pq_hostname(char *buf, size_t len) {
#ifdef HAS_GETHOSTNAME
    if (gethostname(buf, (int)len) == 0) { buf[len - 1] = 0; return; }
#endif
    my_strlcpy(buf, "localhost", len);
}

/* Register (or refresh, when id is non-zero) a worker row. Refreshing keeps
 * identity across a reconnect, which matters once the admin UI links jobs
 * to the worker that ran them. opts: role, queues (arrayref), jobs. */
static IV pq_register_worker(pTHX_ SV *self, IV id, HV *opts) {
    double now = pq_now(aTHX_ self);
    SV *role   = opts ? pq_get(aTHX_ opts, "role")   : NULL;
    SV *queues = opts ? pq_get(aTHX_ opts, "queues") : NULL;
    SV *jobs   = opts ? pq_get(aTHX_ opts, "jobs")   : NULL;
    SV *qjson  = sv_2mortal(pq_json_encode(aTHX_ queues, "[]"));

    if (id) {
        AV *b = pq_binds(aTHX);
        pq_bind_nv(aTHX_ b, now);
        pq_bind_sv(aTHX_ b, qjson);
        pq_bind_iv(aTHX_ b, id);
        if (pq_do(aTHX_ self, sv_2mortal(newSVpvs(
                "UPDATE pq_workers SET notified = ?, queues = ?"
                " WHERE id = ?")), b) > 0)
            return id;
        /* the row is gone (repair swept it); fall through and re-register */
    }

    {
        char host[256];
        AV *b = pq_binds(aTHX);
        SV *sql = pq_sql_new(aTHX_
            "INSERT INTO pq_workers"
            " (host, pid, role, queues, jobs, version, started, notified)"
            " VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        pq_hostname(host, sizeof host);
        pq_bind_pv(aTHX_ b, host);
        pq_bind_iv(aTHX_ b, (IV)PerlProc_getpid());
        if (role && SvOK(role)) pq_bind_sv(aTHX_ b, role);
        else                    pq_bind_pv(aTHX_ b, "child");
        pq_bind_sv(aTHX_ b, qjson);
        pq_bind_iv(aTHX_ b, (jobs && SvOK(jobs)) ? SvIV(jobs) : 1);
        pq_bind_pv(aTHX_ b, PQ_VERSION_STRING);
        pq_bind_nv(aTHX_ b, now);
        pq_bind_nv(aTHX_ b, now);

        if (pq_has_returning(aTHX_ self)) {
            AV *row;
            IV got = 0;
            pq_sql_cat(aTHX_ sql, " RETURNING id");
            row = pq_selectrow(aTHX_ self, sql, b);
            if (row) { got = pq_col_iv(aTHX_ row, 0); SvREFCNT_dec((SV *)row); }
            return got;
        }
        (void)pq_do(aTHX_ self, sql, b);
        return pq_last_insert_id(aTHX_ self);
    }
}

static IV pq_unregister_worker(pTHX_ SV *self, IV id) {
    AV *b = pq_binds(aTHX);
    pq_bind_iv(aTHX_ b, id);
    return pq_do(aTHX_ self, sv_2mortal(newSVpvs(
        "DELETE FROM pq_workers WHERE id = ?")), b) > 0 ? 1 : 0;
}

/* The heartbeat: proof of life, and (from phase 6) the inbox drain point.
 * status is stored as JSON for the admin UI; NULL keeps what is there. */
static IV pq_worker_heartbeat(pTHX_ SV *self, IV id, SV *status) {
    AV *b = pq_binds(aTHX);
    SV *sql = pq_sql_new(aTHX_ "UPDATE pq_workers SET notified = ?");
    pq_bind_nv(aTHX_ b, pq_now(aTHX_ self));
    if (status && SvOK(status)) {
        SV *json = sv_2mortal(pq_json_encode(aTHX_ status, "{}"));
        pq_sql_cat(aTHX_ sql, ", status = ?");
        pq_bind_sv(aTHX_ b, json);
    }
    pq_sql_cat(aTHX_ sql, " WHERE id = ?");
    pq_bind_iv(aTHX_ b, id);
    return pq_do(aTHX_ self, sql, b) > 0 ? 1 : 0;
}

/* ---- listing ---------------------------------------------------------------
 *
 * One filter vocabulary - id, state, queue, task, worker - shared verbatim
 * by the CLI (`punk-queue jobs --state failed`), the phase-8 REST API and
 * the admin UI, so an operator never learns three dialects. The WHERE is
 * assembled from this whitelist and nothing else; caller input never
 * reaches the SQL as text. */

static const char *const PQ_JOB_FILTERS[] =
    { "id", "state", "queue", "task", "worker", NULL };

/* The table search: filter key `search` matches a substring against a
 * per-lister whitelist of columns, OR'd. The term is LIKE-escaped and
 * bound - caller input never reaches the SQL as text - and both sides
 * are lower()ed because LIKE is case-insensitive on SQLite but
 * case-sensitive on Pg, and the conformance battery requires one
 * behaviour. Numeric columns join the whitelist as CAST(... AS TEXT). */
static void pq_search_where(pTHX_ SV *where, AV *fbind, int *first,
                            SV *term, const char *const cols[]) {
    STRLEN len, i;
    const char *p = SvPV(term, len);
    SV *pat = sv_2mortal(newSVpvs("%"));
    int j;
    for (i = 0; i < len; i++) {
        char ch = (char)toLOWER((U8)p[i]);
        if (ch == '%' || ch == '_' || ch == '\\')
            sv_catpvs(pat, "\\");
        sv_catpvn(pat, &ch, 1);
    }
    sv_catpvs(pat, "%");
    pq_sql_cat(aTHX_ where, *first ? " WHERE (" : " AND (");
    for (j = 0; cols[j]; j++) {
        if (j) pq_sql_cat(aTHX_ where, " OR ");
        pq_sql_cat(aTHX_ where, "lower(");
        pq_sql_cat(aTHX_ where, cols[j]);
        pq_sql_cat(aTHX_ where, ") LIKE ? ESCAPE '\\'");
        pq_bind_sv(aTHX_ fbind, pat);
    }
    pq_sql_cat(aTHX_ where, ")");
    *first = 0;
}

static void pq_search_filter(pTHX_ SV *where, AV *fbind, int *first,
                             HV *filter, const char *const cols[]) {
    SV *v = filter ? pq_get(aTHX_ filter, "search") : NULL;
    if (v && SvOK(v) && SvCUR(v))
        pq_search_where(aTHX_ where, fbind, first, v, cols);
}

/* Sortable columns are whitelisted exactly as filterable ones are: the
 * ORDER BY is assembled from this table and a fixed asc/desc pair, and
 * caller input never reaches the SQL as text. An unknown column croaks
 * (a typo'd sort is a caller bug), landing as a clean 4xx upstream. */
static const char *const PQ_JOB_SORTS[] =
    { "id", "state", "queue", "task", "worker", "priority", "created",
      NULL };

static SV *pq_list_jobs(pTHX_ SV *self, IV offset, IV limit, HV *filter,
                        SV *sort_col, SV *sort_dir) {
    SV *where = pq_sql_new(aTHX_ "");
    AV *fbind = pq_binds(aTHX);
    HV *out = newHV();
    AV *jobs = newAV();
    int i, first = 1;

    for (i = 0; PQ_JOB_FILTERS[i]; i++) {
        SV *v = filter ? pq_get(aTHX_ filter, PQ_JOB_FILTERS[i]) : NULL;
        if (!(v && SvOK(v))) continue;
        pq_sql_cat(aTHX_ where, first ? " WHERE " : " AND ");
        pq_sql_cat(aTHX_ where, PQ_JOB_FILTERS[i]);
        pq_sql_cat(aTHX_ where, " = ?");
        pq_bind_sv(aTHX_ fbind, v);
        first = 0;
    }
    {
        static const char *const cols[] =
            { "task", "queue", "state", "CAST(id AS TEXT)", NULL };
        pq_search_filter(aTHX_ where, fbind, &first, filter, cols);
    }

    {   /* total first, so paging can show "page 2 of 40" */
        SV *sql = pq_sql_new(aTHX_ "SELECT count(*) FROM pq_jobs");
        AV *row;
        pq_sql_cat_all(aTHX_ sql, where);
        row = pq_selectrow(aTHX_ self, sql, fbind);
        (void)hv_stores(out, "total",
                        newSViv(row ? pq_col_iv(aTHX_ row, 0) : 0));
        if (row) SvREFCNT_dec((SV *)row);
    }

    {
        SV *sql = pq_sql_new(aTHX_ "SELECT " PQ_JOB_COLS " FROM pq_jobs");
        SV *sth;
        AV *bind = pq_binds(aTHX), *row;
        SSize_t n = av_len(fbind) + 1, k;
        for (k = 0; k < n; k++) pq_bind_sv(aTHX_ bind, *av_fetch(fbind, k, 0));
        pq_sql_cat_all(aTHX_ sql, where);
        /* newest first by default: the question is nearly always "what
         * just happened" */
        if (sort_col && SvOK(sort_col)) {
            const char *want = SvPV_nolen(sort_col);
            int i, ok = 0;
            for (i = 0; PQ_JOB_SORTS[i]; i++)
                if (strEQ(want, PQ_JOB_SORTS[i])) { ok = 1; break; }
            if (!ok)
                croak("Punk::Queue: cannot sort jobs by '%s'", want);
            pq_sql_cat(aTHX_ sql, " ORDER BY ");
            pq_sql_cat(aTHX_ sql, want);
            pq_sql_cat(aTHX_ sql,
                (sort_dir && SvOK(sort_dir)
                 && strEQ(SvPV_nolen(sort_dir), "asc"))
                ? " ASC" : " DESC");
            pq_sql_cat(aTHX_ sql, ", id DESC LIMIT ? OFFSET ?");
        }
        else
            pq_sql_cat(aTHX_ sql, " ORDER BY id DESC LIMIT ? OFFSET ?");
        pq_bind_iv(aTHX_ bind, limit  > 0 ? limit  : 50);
        pq_bind_iv(aTHX_ bind, offset > 0 ? offset : 0);

        sth = pq_sth(aTHX_ self, sql);
        (void)pq_execute(aTHX_ sth, bind);
        while ((row = pq_fetchrow(aTHX_ sth))) {
            av_push(jobs, newRV_noinc((SV *)pq_job_row_hv(aTHX_ row)));
            SvREFCNT_dec((SV *)row);
        }
        { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
          if (r) SvREFCNT_dec(r); }
    }

    (void)hv_stores(out, "jobs", newRV_noinc((SV *)jobs));
    return newRV_noinc((SV *)out);
}

/* A worker row -> plain hashref, JSON columns decoded. */
static HV *pq_worker_row_hv(pTHX_ AV *row) {
    HV *h = newHV();
    if (!row) return h;
    pq_hv_set_iv(aTHX_ h, "id",   pq_col_iv(aTHX_ row, 0));
    pq_hv_set_sv(aTHX_ h, "host", pq_col(aTHX_ row, 1));
    pq_hv_set_iv(aTHX_ h, "pid",  pq_col_iv(aTHX_ row, 2));
    pq_hv_set_sv(aTHX_ h, "role", pq_col(aTHX_ row, 3));
    (void)hv_stores(h, "queues", pq_json_decode(aTHX_ pq_col(aTHX_ row, 4)));
    pq_hv_set_iv(aTHX_ h, "jobs", pq_col_iv(aTHX_ row, 5));
    (void)hv_stores(h, "status", pq_json_decode(aTHX_ pq_col(aTHX_ row, 6)));
    pq_hv_set_sv(aTHX_ h, "version", pq_col(aTHX_ row, 8));
    pq_hv_set_nv_or_undef(aTHX_ h, "started",  pq_col(aTHX_ row, 9));
    pq_hv_set_nv_or_undef(aTHX_ h, "notified", pq_col(aTHX_ row, 10));
    return h;
}

static SV *pq_list_workers(pTHX_ SV *self, IV offset, IV limit, HV *filter) {
    SV *where = pq_sql_new(aTHX_ "");
    AV *fbind = pq_binds(aTHX);
    HV *out = newHV();
    AV *ws = newAV();
    SV *v;

    if (filter && (v = pq_get(aTHX_ filter, "role")) && SvOK(v)) {
        pq_sql_cat(aTHX_ where, " WHERE role = ?");
        pq_bind_sv(aTHX_ fbind, v);
    }
    {
        static const char *const cols[] =
            { "host", "role", "CAST(id AS TEXT)", "CAST(pid AS TEXT)",
              NULL };
        int first = !(filter && (v = pq_get(aTHX_ filter, "role"))
                      && SvOK(v));
        pq_search_filter(aTHX_ where, fbind, &first, filter, cols);
    }

    {
        SV *sql = pq_sql_new(aTHX_ "SELECT count(*) FROM pq_workers");
        AV *row;
        pq_sql_cat_all(aTHX_ sql, where);
        row = pq_selectrow(aTHX_ self, sql, fbind);
        (void)hv_stores(out, "total",
                        newSViv(row ? pq_col_iv(aTHX_ row, 0) : 0));
        if (row) SvREFCNT_dec((SV *)row);
    }

    {
        SV *sql = pq_sql_new(aTHX_
            "SELECT id, host, pid, role, queues, jobs, status, inbox,"
            " version, started, notified FROM pq_workers");
        SV *sth;
        AV *bind = pq_binds(aTHX), *row;
        SSize_t n = av_len(fbind) + 1, k;
        for (k = 0; k < n; k++) pq_bind_sv(aTHX_ bind, *av_fetch(fbind, k, 0));
        pq_sql_cat_all(aTHX_ sql, where);
        pq_sql_cat(aTHX_ sql, " ORDER BY id LIMIT ? OFFSET ?");
        pq_bind_iv(aTHX_ bind, limit  > 0 ? limit  : 50);
        pq_bind_iv(aTHX_ bind, offset > 0 ? offset : 0);

        sth = pq_sth(aTHX_ self, sql);
        (void)pq_execute(aTHX_ sth, bind);
        while ((row = pq_fetchrow(aTHX_ sth))) {
            av_push(ws, newRV_noinc((SV *)pq_worker_row_hv(aTHX_ row)));
            SvREFCNT_dec((SV *)row);
        }
        { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
          if (r) SvREFCNT_dec(r); }
    }

    (void)hv_stores(out, "workers", newRV_noinc((SV *)ws));
    return newRV_noinc((SV *)out);
}

/* ---- stats -----------------------------------------------------------------
 *
 * The phase-3 shape: per-state counts, the delayed subset, worker counts,
 * schema version. Phase 6 adds history buckets and rates; the keys here
 * are stable and only ever gain siblings. */

/* one grouped count -> { name => { state => n, ... }, ... } under key */
static void pq_stats_group(pTHX_ SV *self, HV *out, const char *key,
                           const char *sql) {
    SV *sth = pq_sth(aTHX_ self, sv_2mortal(newSVpv(sql, 0)));
    AV *row;
    HV *groups = newHV();
    (void)pq_execute(aTHX_ sth, NULL);
    while ((row = pq_fetchrow(aTHX_ sth))) {
        SV *gn = pq_col(aTHX_ row, 0);
        SV *st = pq_col(aTHX_ row, 1);
        IV  n  = pq_col_iv(aTHX_ row, 2);
        if (SvOK(gn) && SvOK(st)) {
            HE *he = hv_fetch_ent(groups, gn, 1, 0);
            SV *slot = he ? HeVAL(he) : NULL;
            HV *per;
            if (slot && !SvROK(slot)) {
                per = newHV();
                sv_setsv(slot, sv_2mortal(newRV_noinc((SV *)per)));
            }
            else per = slot ? (HV *)SvRV(slot) : NULL;
            if (per)
                (void)hv_store(per, SvPV_nolen(st), SvCUR(st),
                               newSViv(n), 0);
        }
        SvREFCNT_dec((SV *)row);
    }
    { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
      if (r) SvREFCNT_dec(r); }
    (void)hv_store(out, key, (I32)strlen(key),
                   newRV_noinc((SV *)groups), 0);
}

static SV *pq_stats(pTHX_ SV *self) {
    HV *out = newHV();
    double now = pq_now(aTHX_ self);
    IV total = 0;

    (void)hv_stores(out, "inactive_jobs", newSViv(0));
    (void)hv_stores(out, "active_jobs",   newSViv(0));
    (void)hv_stores(out, "failed_jobs",   newSViv(0));
    (void)hv_stores(out, "finished_jobs", newSViv(0));

    {
        SV *sth = pq_sth(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT state, count(*) FROM pq_jobs GROUP BY state")));
        AV *row;
        (void)pq_execute(aTHX_ sth, NULL);
        while ((row = pq_fetchrow(aTHX_ sth))) {
            SV *st = pq_col(aTHX_ row, 0);
            IV  n  = pq_col_iv(aTHX_ row, 1);
            if (SvOK(st)) {
                SV *key = sv_2mortal(Perl_newSVpvf(aTHX_ "%s_jobs",
                                                   SvPV_nolen(st)));
                (void)hv_store_ent(out, key, newSViv(n), 0);
                total += n;
            }
            SvREFCNT_dec((SV *)row);
        }
        { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
          if (r) SvREFCNT_dec(r); }
    }
    (void)hv_stores(out, "total_jobs", newSViv(total));

    {
        AV *b = pq_binds(aTHX), *row;
        pq_bind_nv(aTHX_ b, now);
        row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT count(*) FROM pq_jobs"
            " WHERE state = 'inactive' AND delayed > ?")), b);
        (void)hv_stores(out, "delayed_jobs",
                        newSViv(row ? pq_col_iv(aTHX_ row, 0) : 0));
        if (row) SvREFCNT_dec((SV *)row);
    }

    {
        AV *row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT count(*) FROM pq_workers")), NULL);
        (void)hv_stores(out, "workers",
                        newSViv(row ? pq_col_iv(aTHX_ row, 0) : 0));
        if (row) SvREFCNT_dec((SV *)row);
    }

    /* per-queue and per-task per-state counts, for the UI's breakdown
     * tables: { name => { state => n, ... }, ... } */
    pq_stats_group(aTHX_ self, out, "queues",
        "SELECT queue, state, count(*) FROM pq_jobs GROUP BY queue, state");
    pq_stats_group(aTHX_ self, out, "tasks",
        "SELECT task, state, count(*) FROM pq_jobs GROUP BY task, state");

    /* alive = heartbeat within missing_after; the rest are what repair
     * will sweep */
    {
        AV *b = pq_binds(aTHX), *row;
        pq_bind_nv(aTHX_ b, now - pq_opt_num(aTHX_ self, "missing_after",
                                             1800.0));
        row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT count(*) FROM pq_workers WHERE notified >= ?")), b);
        (void)hv_stores(out, "active_workers",
                        newSViv(row ? pq_col_iv(aTHX_ row, 0) : 0));
        if (row) SvREFCNT_dec((SV *)row);
    }

    /* lifetime enqueue count, approximated by the id sequence: deletes do
     * not shrink it, which is exactly the property a rate needs */
    {
        AV *row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
            "SELECT max(id) FROM pq_jobs")), NULL);
        SV *m = row ? pq_col(aTHX_ row, 0) : NULL;
        (void)hv_stores(out, "enqueued_jobs",
                        newSViv((m && SvOK(m)) ? SvIV(m) : 0));
        if (row) SvREFCNT_dec((SV *)row);
    }

    (void)hv_stores(out, "schema_version",
                    newSViv(pq_schema_version(aTHX_ self)));
    return newRV_noinc((SV *)out);
}

/* ---- history ---------------------------------------------------------------
 *
 * Finished-vs-failed counts in hourly buckets over the last day and daily
 * buckets over the last week, for the phase-8 graph. Sparse: only buckets
 * with data appear, sorted ascending; the UI fills gaps. remove_after
 * trims what can appear (default 2 days), and the POD says so - history
 * reaches only as far back as retention keeps terminal rows.
 *
 * The epoch-truncation expression is the one genuinely divergent piece:
 * CAST truncates on SQLite but ROUNDS on Pg, so Pg uses floor(). Both
 * still bucket identically, which the battery asserts. */

static AV *pq_history_scan(pTHX_ SV *self, double cutoff, IV width) {
    AV *out = newAV();
    SV *sql, *sth;
    AV *bind = pq_binds(aTHX), *row;

    sql = pq_sql_new(aTHX_ "SELECT ");
    if (pq_is_pg(aTHX_ self))
        pq_sql_cat(aTHX_ sql, "(floor(finished / ?) * ?)::bigint");
    else
        pq_sql_cat(aTHX_ sql, "CAST(finished / ? AS INTEGER) * ?");
    pq_sql_cat(aTHX_ sql,
        " AS bucket, state, count(*) FROM pq_jobs"
        " WHERE state IN ('finished', 'failed') AND finished >= ?"
        " GROUP BY bucket, state ORDER BY bucket");

    pq_bind_iv(aTHX_ bind, width);
    pq_bind_iv(aTHX_ bind, width);
    pq_bind_nv(aTHX_ bind, cutoff);

    sth = pq_sth(aTHX_ self, sql);
    (void)pq_execute(aTHX_ sth, bind);
    {
        HV *cur = NULL;
        IV cur_epoch = -1;
        while ((row = pq_fetchrow(aTHX_ sth))) {
            IV epoch = pq_col_iv(aTHX_ row, 0);
            SV *st   = pq_col(aTHX_ row, 1);
            IV cnt   = pq_col_iv(aTHX_ row, 2);
            if (!cur || epoch != cur_epoch) {
                cur = newHV();
                (void)hv_stores(cur, "epoch",    newSViv(epoch));
                (void)hv_stores(cur, "finished", newSViv(0));
                (void)hv_stores(cur, "failed",   newSViv(0));
                av_push(out, newRV_noinc((SV *)cur));
                cur_epoch = epoch;
            }
            if (SvOK(st))
                (void)hv_store(cur, SvPV_nolen(st), SvCUR(st),
                               newSViv(cnt), 0);
            SvREFCNT_dec((SV *)row);
        }
    }
    { SV *r = pq_call_meth(aTHX_ sth, "finish", NULL, 0, 1);
      if (r) SvREFCNT_dec(r); }
    return out;
}

static SV *pq_history(pTHX_ SV *self) {
    HV *out = newHV();
    double now = pq_now(aTHX_ self);
    (void)hv_stores(out, "hourly", newRV_noinc((SV *)
        pq_history_scan(aTHX_ self, now - 86400.0, 3600)));
    (void)hv_stores(out, "daily", newRV_noinc((SV *)
        pq_history_scan(aTHX_ self, now - 604800.0, 86400)));
    return newRV_noinc((SV *)out);
}

/* ---- the sleep horizon -----------------------------------------------------
 *
 * Seconds until the next delayed job in these queues becomes claimable, or
 * -1 when there is none. The idle worker clamps its sleep to this, so a
 * delayed job wakes it at the right moment rather than at the next poll
 * tick - which is what makes a long dequeue_interval safe. */
static double pq_ready_horizon(pTHX_ SV *self, AV *queues) {
    SV *sql;
    AV *bind, *row;
    SSize_t nq = queues ? av_len(queues) + 1 : 0;
    double now, horizon = -1.0;

    if (nq < 1) return -1.0;
    now = pq_now(aTHX_ self);

    sql = pq_sql_new(aTHX_
        "SELECT min(delayed) FROM pq_jobs WHERE state = 'inactive' AND ");
    pq_sql_in(aTHX_ sql, "queue", nq);
    pq_sql_cat(aTHX_ sql, " AND delayed > ?");

    bind = pq_binds(aTHX);
    {
        SSize_t i;
        for (i = 0; i < nq; i++)
            pq_bind_sv(aTHX_ bind, *av_fetch(queues, i, 0));
    }
    pq_bind_nv(aTHX_ bind, now);

    row = pq_selectrow(aTHX_ self, sql, bind);
    if (row) {
        SV *m = pq_col(aTHX_ row, 0);
        if (m && SvOK(m)) {
            horizon = SvNV(m) - now;
            if (horizon < 0) horizon = 0;
        }
        SvREFCNT_dec((SV *)row);
    }
    return horizon;
}

/* Empty every table except pq_migrations. The CLI gates this behind an
 * explicit --yes; the method itself does not second-guess. */
static void pq_reset(pTHX_ SV *self) {
    (void)pq_do_pv(aTHX_ self, "DELETE FROM pq_job_logs");
    (void)pq_do_pv(aTHX_ self, "DELETE FROM pq_job_deps");
    (void)pq_do_pv(aTHX_ self, "DELETE FROM pq_jobs");
    (void)pq_do_pv(aTHX_ self, "DELETE FROM pq_workers");
    (void)pq_do_pv(aTHX_ self, "DELETE FROM pq_locks");
    (void)pq_do_pv(aTHX_ self, "DELETE FROM pq_crons");
}

#endif /* PQ_BACKEND_H */

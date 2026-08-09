#ifndef PQ_SQLITE_H
#define PQ_SQLITE_H

/* pq_sqlite.h - everything about the SQLite backend that Postgres does
 * differently. The shared 70% lives in pq_backend.h; if something appears
 * here that is not genuinely divergent, it is in the wrong file.
 *
 * Include after pq_dbi.h, pq_job.h, pq_migrate.h and pq_migrate_sqlite.h. */

/* Epoch seconds from SQLite's julian day. Probed once per connection so the
 * whole dist can bind its own clock plus a delta. */
static double pq_sqlite_probe_clock(pTHX_ SV *dbh) {
    SV *argv[1], *r;
    double server;
    int died = 0;
    argv[0] = sv_2mortal(newSVpvs(
        "SELECT (julianday('now') - 2440587.5) * 86400.0"));
    r = pq_call_meth_ev(aTHX_ dbh, "selectrow_array", argv, 1, 1, &died);
    if (died || !r || !SvOK(r)) { if (r) SvREFCNT_dec(r); return 0.0; }
    server = SvNV(r);
    SvREFCNT_dec(r);
    /* The delta, not the time: what every later bind adds to its own clock. */
    return server - pq_now_local(aTHX);
}

/* SQLite's DDL and its transactions are both transactional, and BEGIN
 * IMMEDIATE takes RESERVED up front - so two workers booting together
 * serialise at BEGIN rather than deadlocking at COMMIT.
 *
 * These go through do() with AutoCommit left on rather than begin_work,
 * because DBI's begin_work would fight the explicit IMMEDIATE we need. */
static void pq_sqlite_rollback(pTHX_ SV *self);

static void pq_sqlite_begin_exclusive(pTHX_ SV *self) {
    /* Defensive rollback first: if an earlier transition croaked
     * mid-transaction (connection trouble), the handle is still inside it
     * and BEGIN would fail forever after. A rollback with nothing open is
     * trapped and free. */
    pq_sqlite_rollback(aTHX_ self);
    (void)pq_do_pv(aTHX_ self, "BEGIN IMMEDIATE TRANSACTION");
}

static void pq_sqlite_commit(pTHX_ SV *self) {
    (void)pq_do_pv(aTHX_ self, "COMMIT");
}

static void pq_sqlite_rollback(pTHX_ SV *self) {
    int died = 0;
    SV *dbh = pq_dbh(aTHX_ self);
    SV *argv[1], *r;
    argv[0] = sv_2mortal(newSVpvs("ROLLBACK"));
    /* A rollback with no transaction open is not an error worth
     * propagating - it happens on the unwind path where something else
     * already failed, and croaking here would mask that. */
    r = pq_call_meth_ev(aTHX_ dbh, "do", argv, 1, 1, &died);
    if (r) SvREFCNT_dec(r);
}

/* Partial indexes are 3.8.0, and the whole schema depends on them; WAL is
 * mandatory because a reader must not block the claim transaction. Both are
 * checked here so the failure names the cause instead of surfacing as a
 * syntax error inside migration step 1. */
static void pq_sqlite_check_version(pTHX_ SV *self) {
    SV *dbh = pq_dbh(aTHX_ self);
    SV *v = pq_attr(aTHX_ dbh, "sqlite_version");
    int maj = 0, min = 0;

    if (v && SvOK(v)) {
        STRLEN vl;
        const char *s = SvPV_const(v, vl);
        STRLEN i = 0;
        while (i < vl && isDIGIT((U8)s[i])) maj = maj * 10 + (s[i++] - '0');
        if (i < vl && s[i] == '.') {
            i++;
            while (i < vl && isDIGIT((U8)s[i])) min = min * 10 + (s[i++] - '0');
        }
    }
    if (maj && (maj < 3 || (maj == 3 && min < 8)))
        croak("Punk::Queue: SQLite 3.8 or newer is required (partial "
              "indexes); this is %d.%d", maj, min);

    /* WAL is set at connect (pq_after_connect). If it did not take - a
     * read-only directory, a filesystem that cannot do it, :memory: - say
     * so now rather than letting workers contend badly later. */
    {
        AV *row = pq_selectrow(aTHX_ self,
                      sv_2mortal(newSVpvs("PRAGMA journal_mode")), NULL);
        if (row) {
            SV *m = pq_col(aTHX_ row, 0);
            STRLEN ml;
            const char *ms = SvOK(m) ? SvPV_const(m, ml) : "";
            int ok = SvOK(m) && ((ml == 3 && (memEQ(ms, "wal", 3) ||
                                              memEQ(ms, "WAL", 3)))
                                 /* :memory: databases report "memory" and
                                  * cannot do WAL; they are single-process
                                  * by definition, so contention is moot */
                              || (ml == 6 && memEQ(ms, "memory", 6)));
            SvREFCNT_dec((SV *)row);
            if (!ok)
                croak("Punk::Queue: SQLite journal_mode is '%s', not 'wal' - "
                      "a file-backed queue needs WAL so readers do not block "
                      "the claim transaction", ms);
        }
    }
}

static const char *const *pq_sqlite_steps(pTHX) {
    return PQ_SQLITE_UP;
}

/* ---- the claim -------------------------------------------------------------
 *
 * BEGIN IMMEDIATE, select the best candidate, take it with a guarded
 * update, commit. The guard (`AND state='inactive'`) should be redundant
 * under IMMEDIATE - but if it ever is not, a silently duplicated job is the
 * worst possible failure mode for a queue, and the guard turns it into a
 * miss instead. It costs nothing.
 *
 * The wait behaviour is deliberately absent: phase 1 claims once and
 * returns. The horizon query, the jittered backoff and the loop-driven
 * sleep are phase 5, where they can be tested against a real worker. */
static SV *pq_sqlite_dequeue(pTHX_ SV *self, IV worker_id, AV *queues,
                             AV *tasks) {
    SV *sql;
    AV *bind, *row;
    SSize_t nq, nt;
    double now;
    SV *out = NULL;
    IV id, took;

    pq_claim_check(aTHX_ queues);
    nq = av_len(queues) + 1;
    nt = tasks ? av_len(tasks) + 1 : 0;
    now = pq_now(aTHX_ self);

    sql = pq_sql_new(aTHX_ "SELECT " PQ_JOB_COLS
                           " FROM pq_jobs WHERE state = 'inactive' AND ");
    pq_claim_where(aTHX_ sql, nq, nt);
    pq_claim_order(aTHX_ sql);

    bind = pq_binds(aTHX);
    pq_claim_binds(aTHX_ bind, queues, tasks, now);

    pq_sqlite_begin_exclusive(aTHX_ self);

    row = pq_selectrow(aTHX_ self, sql, bind);
    if (!row) { pq_sqlite_commit(aTHX_ self); return NULL; }

    id = pq_col_iv(aTHX_ row, PQ_C_ID);
    {
        AV *ub = pq_binds(aTHX);
        pq_bind_nv(aTHX_ ub, now);
        if (worker_id) pq_bind_iv(aTHX_ ub, worker_id);
        else           pq_bind_undef(aTHX_ ub);
        pq_bind_iv(aTHX_ ub, id);
        took = pq_do(aTHX_ self, sv_2mortal(newSVpvs(
            "UPDATE pq_jobs SET state = 'active', started = ?, worker = ?"
            " WHERE id = ? AND state = 'inactive'")), ub);
    }

    if (took > 0) out = pq_claim_row(aTHX_ row, worker_id, now);
    SvREFCNT_dec((SV *)row);

    pq_sqlite_commit(aTHX_ self);
    return out;   /* NULL when the guarded update took nothing */
}

/* SQLite has no LISTEN/NOTIFY and phase 5 does not invent one - a self-pipe
 * poke would only help a single-process deployment, which is not the case
 * that needs helping. The no-op keeps the backend contract total so callers
 * never have to ask which backend they are on. */
static void pq_sqlite_notify(pTHX_ SV *self, SV *queue, IV id) {
    PERL_UNUSED_ARG(self); PERL_UNUSED_ARG(queue); PERL_UNUSED_ARG(id);
}

#endif /* PQ_SQLITE_H */

#ifndef PQ_PG_H
#define PQ_PG_H

/* pq_pg.h - everything about the PostgreSQL backend that SQLite does
 * differently. The shared claim lives in pq_claim.h and the shared
 * operations in pq_backend.h; anything here that is not genuinely
 * divergent is in the wrong file.
 *
 * Include after pq_dbi.h, pq_job.h, pq_claim.h, pq_migrate.h and
 * pq_migrate_pg.h. */

/* Server time as epoch seconds, probed once per connection. */
static double pq_pg_probe_clock(pTHX_ SV *dbh) {
    SV *argv[1], *r;
    double server;
    int died = 0;
    argv[0] = sv_2mortal(newSVpvs("SELECT extract(epoch from now())"));
    r = pq_call_meth_ev(aTHX_ dbh, "selectrow_array", argv, 1, 1, &died);
    if (died || !r || !SvOK(r)) { if (r) SvREFCNT_dec(r); return 0.0; }
    server = SvNV(r);
    SvREFCNT_dec(r);
    return server - pq_now_local(aTHX);
}

/* ---- transactions ----------------------------------------------------------
 *
 * DBD::Pg tracks transaction state itself, so this goes through begin_work
 * and commit rather than raw BEGIN/COMMIT the way SQLite does - a raw BEGIN
 * with AutoCommit on leaves DBI and the server disagreeing about whether a
 * transaction is open, and the disagreement surfaces much later.
 *
 * The exclusive lock is a transaction-scoped advisory lock, released
 * automatically at commit or rollback, so a process that dies mid-migration
 * cannot leave the fleet wedged. The key is an arbitrary constant; it only
 * has to be the same in every process running this code. */
#define PQ_PG_MIGRATE_LOCK "8273412"

static void pq_pg_rollback(pTHX_ SV *self);

/* A plain transaction, for the state transitions that adjust parents_left
 * alongside the job row. The defensive rollback first is cheap insurance:
 * if an earlier transition croaked mid-transaction (connection loss), the
 * handle is still inside it, and begin_work would fail forever after. */
static void pq_pg_begin(pTHX_ SV *self) {
    SV *dbh = pq_dbh(aTHX_ self);
    SV *r;
    pq_pg_rollback(aTHX_ self);
    r = pq_call_meth(aTHX_ dbh, "begin_work", NULL, 0, 1);
    if (r) SvREFCNT_dec(r);
}

static void pq_pg_begin_exclusive(pTHX_ SV *self) {
    pq_pg_begin(aTHX_ self);
    (void)pq_do_pv(aTHX_ self,
        "SELECT pg_advisory_xact_lock(" PQ_PG_MIGRATE_LOCK ")");
}

static void pq_pg_commit(pTHX_ SV *self) {
    SV *dbh = pq_dbh(aTHX_ self);
    SV *r = pq_call_meth(aTHX_ dbh, "commit", NULL, 0, 1);
    if (r) SvREFCNT_dec(r);
}

static void pq_pg_rollback(pTHX_ SV *self) {
    SV *dbh = pq_dbh(aTHX_ self);
    int died = 0;
    SV *r;
    /* Inside a begin_work transaction AutoCommit reads false; outside,
     * there is nothing to roll back and DBI would warn "rollback
     * ineffective" - a warning eval cannot silence, so ask first. */
    SV *ac = pq_attr(aTHX_ dbh, "AutoCommit");
    if (ac && SvTRUE(ac)) return;
    r = pq_call_meth_ev(aTHX_ dbh, "rollback", NULL, 0, 1, &died);
    if (r) SvREFCNT_dec(r);
}

/* FOR UPDATE SKIP LOCKED is 9.5. The whole claim depends on it, so check
 * here where the message can name the cause rather than letting it surface
 * as a syntax error inside the first dequeue. */
static void pq_pg_check_version(pTHX_ SV *self) {
    AV *row = pq_selectrow(aTHX_ self, sv_2mortal(newSVpvs(
        "SELECT current_setting('server_version_num')")), NULL);
    IV num;
    if (!row) return;
    num = pq_col_iv(aTHX_ row, 0);
    SvREFCNT_dec((SV *)row);
    if (num && num < 90500)
        croak("Punk::Queue: PostgreSQL 9.5 or newer is required "
              "(FOR UPDATE SKIP LOCKED); this server is %ld",
              (long)num);
}

static const char *const *pq_pg_steps(pTHX) {
    return PQ_PG_UP;
}

/* ---- the claim -------------------------------------------------------------
 *
 * One statement, on a connection with AutoCommit on, so the claim is its own
 * transaction and no explicit BEGIN is needed. SKIP LOCKED lets contending
 * workers step over each other's in-flight candidate rows instead of
 * queueing behind them, which is the entire reason this backend scales past
 * one machine.
 *
 * The redundant `AND state = 'inactive'` on the outer UPDATE closes the
 * classic re-evaluation race. Minion omits it; a silently duplicated job is
 * the worst failure a queue has, and the guard costs nothing. */
static SV *pq_pg_dequeue(pTHX_ SV *self, IV worker_id, AV *queues,
                         AV *tasks) {
    SV *sql;
    AV *bind, *row;
    SSize_t nq, nt;
    double now;
    SV *out = NULL;

    pq_claim_check(aTHX_ queues);
    nq = av_len(queues) + 1;
    nt = tasks ? av_len(tasks) + 1 : 0;
    now = pq_now(aTHX_ self);

    sql = pq_sql_new(aTHX_
        "UPDATE pq_jobs SET state = 'active', started = ?, worker = ?"
        " WHERE id = (SELECT id FROM pq_jobs WHERE state = 'inactive' AND ");
    pq_claim_where(aTHX_ sql, nq, nt);
    pq_claim_order(aTHX_ sql);
    pq_sql_cat(aTHX_ sql,
        " FOR UPDATE SKIP LOCKED) AND state = 'inactive'"
        " RETURNING " PQ_JOB_COLS);

    bind = pq_binds(aTHX);
    pq_bind_nv(aTHX_ bind, now);                       /* started */
    if (worker_id) pq_bind_iv(aTHX_ bind, worker_id);  /* worker  */
    else           pq_bind_undef(aTHX_ bind);
    pq_claim_binds(aTHX_ bind, queues, tasks, now);

    row = pq_selectrow(aTHX_ self, sql, bind);
    if (!row) return NULL;

    out = pq_claim_row(aTHX_ row, worker_id, now);
    SvREFCNT_dec((SV *)row);
    return out;
}

/* ---- wakeup ----------------------------------------------------------------
 *
 * Emit only; the LISTEN side is phase 5.
 *
 * pg_notify() rather than a NOTIFY statement, because it takes the channel
 * as a text parameter and so needs no identifier quoting at all - the
 * name-validation rule in pq_sql.h already makes a hostile queue name
 * impossible, and this makes it impossible twice. NOTIFY is delivered at
 * commit, so with AutoCommit on the ordering against the insert is free. */
static void pq_pg_notify(pTHX_ SV *self, SV *queue, IV id) {
    AV *bind = pq_binds(aTHX);
    SV *chan = sv_2mortal(Perl_newSVpvf(aTHX_ "pq.%s", SvPV_nolen(queue)));
    pq_bind_sv(aTHX_ bind, chan);
    pq_bind_iv(aTHX_ bind, id);
    (void)pq_do(aTHX_ self,
        sv_2mortal(newSVpvs("SELECT pg_notify(?, ?::text)")), bind);
}

#endif /* PQ_PG_H */

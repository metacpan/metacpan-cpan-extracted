#ifndef PQ_CLAIM_H
#define PQ_CLAIM_H

/* pq_claim.h - the parts of a claim that are the same on every backend.
 *
 * The two backends claim a job very differently - PostgreSQL does it in one
 * statement with FOR UPDATE SKIP LOCKED and RETURNING, SQLite does
 * select-then-guarded-update inside BEGIN IMMEDIATE - but the *predicate*
 * that decides which job is next, the order the binds go in, and what a
 * claimed row turns into are identical, and must stay identical. A queue
 * whose claim order differs between backends is a queue whose behaviour
 * depends on its deployment.
 *
 * So the divergent files own the transaction shape and the statement
 * skeleton, and this file owns everything inside them. If a difference in
 * claim semantics ever appears between pq_sqlite.h and pq_pg.h, it is a bug
 * in one of them, not a fact about the database.
 *
 * Include after pq_job.h and pq_sql.h, before the per-backend headers. */

/* The shared claim predicate, appended to a statement that has already
 * opened its WHERE with `state = 'inactive' AND `.
 *
 * Order matters for prepare_cached: the text must be byte-identical for a
 * given (nq, nt), which it is, because nothing here depends on the values. */
static void pq_claim_where(pTHX_ SV *sql, SSize_t nq, SSize_t nt) {
    pq_sql_in(aTHX_ sql, "queue", nq);
    if (nt > 0) {
        pq_sql_cat(aTHX_ sql, " AND ");
        pq_sql_in(aTHX_ sql, "task", nt);
    }
    pq_sql_cat(aTHX_ sql,
        " AND delayed <= ? AND parents_left = 0"
        " AND (expires IS NULL OR expires > ?)");
}

/* The ordering. Its own function because "highest priority, then oldest"
 * is a promise to the user, not an implementation detail, and it appears in
 * two statements. `id` is the tiebreaker: it gives FIFO within a priority
 * for free, with no second timestamp column to read. */
static void pq_claim_order(pTHX_ SV *sql) {
    pq_sql_cat(aTHX_ sql, " ORDER BY priority DESC, id LIMIT 1");
}

/* Binds for pq_claim_where, in its placeholder order. */
static void pq_claim_binds(pTHX_ AV *bind, AV *queues, AV *tasks, double now) {
    SSize_t nq = queues ? av_len(queues) + 1 : 0;
    SSize_t nt = tasks  ? av_len(tasks)  + 1 : 0;
    SSize_t i;
    for (i = 0; i < nq; i++) pq_bind_sv(aTHX_ bind, *av_fetch(queues, i, 0));
    for (i = 0; i < nt; i++) pq_bind_sv(aTHX_ bind, *av_fetch(tasks,  i, 0));
    pq_bind_nv(aTHX_ bind, now);      /* delayed <= ? */
    pq_bind_nv(aTHX_ bind, now);      /* expires  > ? */
}

/* A claimed row -> the job hashref the caller gets (+1).
 *
 * The in-memory row is patched to reflect the claim rather than re-read.
 * PostgreSQL's RETURNING gives the post-update row already, SQLite's SELECT
 * gives the pre-update one, and normalising here is what stops that
 * difference reaching the caller. */
static SV *pq_claim_row(pTHX_ AV *row, IV worker_id, double now) {
    HV *h = pq_job_row_hv(aTHX_ row);
    (void)hv_stores(h, "state",   newSVpvs("active"));
    (void)hv_stores(h, "started", newSVnv(now));
    (void)hv_stores(h, "worker",  worker_id ? newSViv(worker_id) : newSV(0));
    return newRV_noinc((SV *)h);
}

/* Both backends need at least one queue to look in, and "none" is a caller
 * bug rather than an empty result - a worker watching no queues would spin
 * forever finding nothing. */
static void pq_claim_check(pTHX_ AV *queues) {
    if (!queues || av_len(queues) < 0)
        croak("Punk::Queue: dequeue needs at least one queue");
}

#endif /* PQ_CLAIM_H */

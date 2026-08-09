#ifndef PQ_JOB_H
#define PQ_JOB_H

/* pq_job.h - the job row: one column list, one positional decode.
 *
 * Every read path (enqueue RETURNING, the dequeue claim, job_info) selects
 * the same columns in the same order and decodes them through the same
 * function. That is deliberate: a positional fetchrow_arrayref is roughly
 * four times cheaper to build than fetchrow_hashref, but positional decoding
 * with three separate column lists is a bug waiting to happen. One list,
 * one decoder, one place to change.
 *
 * Include after pq_dbi.h and pq_frj.h. */

/* The column list grows at the tail only, in step with the migrations -
 * positional decode means an insertion in the middle silently shears every
 * later field. */
#define PQ_JOB_COLS \
    "id, task, args, queue, state, priority, attempts, retries, " \
    "parents_left, lax, created, delayed, started, finished, retried, " \
    "expires, result, notes, worker, lock_key, cron_id, timeout"

enum {
    PQ_C_ID = 0, PQ_C_TASK, PQ_C_ARGS, PQ_C_QUEUE, PQ_C_STATE,
    PQ_C_PRIORITY, PQ_C_ATTEMPTS, PQ_C_RETRIES, PQ_C_PARENTS_LEFT,
    PQ_C_LAX, PQ_C_CREATED, PQ_C_DELAYED, PQ_C_STARTED, PQ_C_FINISHED,
    PQ_C_RETRIED, PQ_C_EXPIRES, PQ_C_RESULT, PQ_C_NOTES, PQ_C_WORKER,
    PQ_C_LOCK_KEY, PQ_C_CRON_ID, PQ_C_TIMEOUT, PQ_C_MAX
};

/* Store a column as-is, or leave the key absent when the column is NULL.
 * Absent rather than undef: `exists $job->{started}` then means "has been
 * claimed", which is a more useful thing to be able to ask than comparing
 * against undef. */
static void pq_hv_set_sv(pTHX_ HV *h, const char *k, SV *v) {
    (void)hv_store(h, k, (I32)strlen(k), newSVsv(v), 0);
}

static void pq_hv_set_iv(pTHX_ HV *h, const char *k, IV v) {
    (void)hv_store(h, k, (I32)strlen(k), newSViv(v), 0);
}

static void pq_hv_set_nv_or_undef(pTHX_ HV *h, const char *k, SV *v) {
    (void)hv_store(h, k, (I32)strlen(k),
                   (v && SvOK(v)) ? newSVnv(SvNV(v)) : newSV(0), 0);
}

/* A fetched row -> a plain hashref, JSON columns decoded. +1, caller owns.
 *
 * Rows are plain hashrefs rather than objects for the same reason
 * Punk::Model's are: they are fast to build, directly JSON-encodable for
 * the REST API in phase 8, and nobody has to learn an accessor API to
 * inspect one at a prompt. */
static HV *pq_job_row_hv(pTHX_ AV *row) {
    HV *h = newHV();
    if (!row) return h;

    pq_hv_set_iv(aTHX_ h, "id",           pq_col_iv(aTHX_ row, PQ_C_ID));
    pq_hv_set_sv(aTHX_ h, "task",         pq_col(aTHX_ row, PQ_C_TASK));
    pq_hv_set_sv(aTHX_ h, "queue",        pq_col(aTHX_ row, PQ_C_QUEUE));
    pq_hv_set_sv(aTHX_ h, "state",        pq_col(aTHX_ row, PQ_C_STATE));
    pq_hv_set_iv(aTHX_ h, "priority",     pq_col_iv(aTHX_ row, PQ_C_PRIORITY));
    pq_hv_set_iv(aTHX_ h, "attempts",     pq_col_iv(aTHX_ row, PQ_C_ATTEMPTS));
    pq_hv_set_iv(aTHX_ h, "retries",      pq_col_iv(aTHX_ row, PQ_C_RETRIES));
    pq_hv_set_iv(aTHX_ h, "parents_left", pq_col_iv(aTHX_ row, PQ_C_PARENTS_LEFT));
    pq_hv_set_iv(aTHX_ h, "lax",          pq_col_iv(aTHX_ row, PQ_C_LAX));

    pq_hv_set_nv_or_undef(aTHX_ h, "created",  pq_col(aTHX_ row, PQ_C_CREATED));
    pq_hv_set_nv_or_undef(aTHX_ h, "delayed",  pq_col(aTHX_ row, PQ_C_DELAYED));
    pq_hv_set_nv_or_undef(aTHX_ h, "started",  pq_col(aTHX_ row, PQ_C_STARTED));
    pq_hv_set_nv_or_undef(aTHX_ h, "finished", pq_col(aTHX_ row, PQ_C_FINISHED));
    pq_hv_set_nv_or_undef(aTHX_ h, "retried",  pq_col(aTHX_ row, PQ_C_RETRIED));
    pq_hv_set_nv_or_undef(aTHX_ h, "expires",  pq_col(aTHX_ row, PQ_C_EXPIRES));

    /* the three JSON columns, decoded in C through the frj ABI */
    (void)hv_stores(h, "args",   pq_json_decode(aTHX_ pq_col(aTHX_ row, PQ_C_ARGS)));
    (void)hv_stores(h, "notes",  pq_json_decode(aTHX_ pq_col(aTHX_ row, PQ_C_NOTES)));
    (void)hv_stores(h, "result", pq_json_decode(aTHX_ pq_col(aTHX_ row, PQ_C_RESULT)));

    {
        SV *w = pq_col(aTHX_ row, PQ_C_WORKER);
        (void)hv_stores(h, "worker", SvOK(w) ? newSViv(SvIV(w)) : newSV(0));
    }
    (void)hv_stores(h, "lock_key", newSVsv(pq_col(aTHX_ row, PQ_C_LOCK_KEY)));
    {
        SV *c = pq_col(aTHX_ row, PQ_C_CRON_ID);
        (void)hv_stores(h, "cron_id", SvOK(c) ? newSViv(SvIV(c)) : newSV(0));
    }
    pq_hv_set_nv_or_undef(aTHX_ h, "timeout", pq_col(aTHX_ row, PQ_C_TIMEOUT));
    return h;
}

/* ---- Punk::Queue::Job ------------------------------------------------------
 *
 * The handle a task body receives. A blessed hashref, not an IV-ref to a
 * malloc'd struct: a job object is constructed once per job run, which
 * already costs a database round trip, so the allocation is noise - and the
 * hashref needs no DESTROY, cannot leak, and can be subclassed by a
 * hand-written runner. The IV-ref pattern earns its keep on per-request
 * objects; this is not one. */

static SV *pq_job_new(pTHX_ SV *queue, HV *row) {
    HV *h = newHV();
    SV *rv;
    (void)hv_stores(h, "queue", newSVsv(queue));
    (void)hv_stores(h, "row",   newRV_inc((SV *)row));
    rv = newRV_noinc((SV *)h);
    sv_bless(rv, gv_stashpvs("Punk::Queue::Job", GV_ADD));
    return rv;
}

/* A field off the job's row. Borrowed, or NULL. */
static SV *pq_job_field(pTHX_ SV *self, const char *k) {
    HV *h = pq_hv(aTHX_ self, "Punk::Queue::Job");
    HV *row = pq_get_hv(aTHX_ h, "row");
    return row ? pq_get(aTHX_ row, k) : NULL;
}

#endif /* PQ_JOB_H */

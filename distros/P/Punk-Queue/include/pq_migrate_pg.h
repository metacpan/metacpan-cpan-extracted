#ifndef PQ_MIGRATE_PG_H
#define PQ_MIGRATE_PG_H

/* The PostgreSQL schema.
 *
 * Deliberately parallel to PQ_SQLITE_UP, statement for statement and index
 * for index, because the conformance suite asserts the two backends behave
 * identically and that is much easier to keep true when the schemas are
 * easy to diff. The differences are exactly four:
 *
 *   BIGSERIAL          vs INTEGER PRIMARY KEY AUTOINCREMENT
 *   DOUBLE PRECISION   vs REAL
 *   BIGINT             vs INTEGER (worker, cron_id, deps)
 *   the pq_jobs_human view, which SQLite has no use for
 *
 * JSON columns are TEXT, not JSONB. That is a choice, not an oversight:
 * JSONB would decode differently from SQLite's TEXT (key order, whitespace,
 * number normalisation), and the whole point of the conformance suite is
 * that a job's payload round-trips identically on both. The queue never
 * queries inside a payload, so JSONB's indexing buys nothing here.
 *
 * APPEND ONLY, and in lockstep with PQ_SQLITE_UP: element N of one array
 * must produce the same logical schema as element N of the other, or
 * pq_migrations means different things on different backends. */

static const char *const PQ_PG_UP[] = {

/* ---- 1 ------------------------------------------------------------------ */
"CREATE TABLE pq_jobs (\n"
"    id           BIGSERIAL PRIMARY KEY,\n"
"    task         TEXT    NOT NULL,\n"
"    args         TEXT    NOT NULL DEFAULT '[]',\n"
"    queue        TEXT    NOT NULL DEFAULT 'default',\n"
"    state        TEXT    NOT NULL DEFAULT 'inactive',\n"
"    priority     INTEGER NOT NULL DEFAULT 0,\n"
"    attempts     INTEGER NOT NULL DEFAULT 1,\n"
"    retries      INTEGER NOT NULL DEFAULT 0,\n"
"    parents_left INTEGER NOT NULL DEFAULT 0,\n"
"    lax          INTEGER NOT NULL DEFAULT 0,\n"
"    created      DOUBLE PRECISION NOT NULL,\n"
"    delayed      DOUBLE PRECISION NOT NULL,\n"
"    started      DOUBLE PRECISION,\n"
"    finished     DOUBLE PRECISION,\n"
"    retried      DOUBLE PRECISION,\n"
"    expires      DOUBLE PRECISION,\n"
"    result       TEXT,\n"
"    notes        TEXT    NOT NULL DEFAULT '{}',\n"
"    worker       BIGINT,\n"
"    lock_key     TEXT,\n"
"    cron_id      BIGINT\n"
")\n"
"-- @@\n"
"CREATE TABLE pq_job_deps (\n"
"    job_id    BIGINT NOT NULL REFERENCES pq_jobs(id) ON DELETE CASCADE,\n"
"    parent_id BIGINT NOT NULL REFERENCES pq_jobs(id) ON DELETE CASCADE,\n"
"    PRIMARY KEY (job_id, parent_id)\n"
")\n"
"-- @@\n"
"CREATE TABLE pq_workers (\n"
"    id       BIGSERIAL PRIMARY KEY,\n"
"    host     TEXT    NOT NULL,\n"
"    pid      INTEGER NOT NULL,\n"
"    role     TEXT    NOT NULL DEFAULT 'child',\n"
"    queues   TEXT    NOT NULL DEFAULT '[]',\n"
"    jobs     INTEGER NOT NULL DEFAULT 1,\n"
"    status   TEXT    NOT NULL DEFAULT '{}',\n"
"    inbox    TEXT    NOT NULL DEFAULT '[]',\n"
"    version  TEXT,\n"
"    started  DOUBLE PRECISION NOT NULL,\n"
"    notified DOUBLE PRECISION NOT NULL\n"
")\n"
"-- @@\n"
"CREATE TABLE pq_locks (\n"
"    id      BIGSERIAL PRIMARY KEY,\n"
"    name    TEXT   NOT NULL,\n"
"    owner   BIGINT,\n"
"    expires DOUBLE PRECISION NOT NULL\n"
")\n"
"-- @@\n"
"CREATE TABLE pq_crons (\n"
"    id       BIGSERIAL PRIMARY KEY,\n"
"    name     TEXT    NOT NULL UNIQUE,\n"
"    expr     TEXT    NOT NULL,\n"
"    task     TEXT    NOT NULL,\n"
"    args     TEXT    NOT NULL DEFAULT '[]',\n"
"    queue    TEXT    NOT NULL DEFAULT 'default',\n"
"    priority INTEGER NOT NULL DEFAULT 0,\n"
"    attempts INTEGER NOT NULL DEFAULT 1,\n"
"    tz       TEXT    NOT NULL DEFAULT 'UTC',\n"
"    catchup  TEXT    NOT NULL DEFAULT 'once',\n"
"    enabled  INTEGER NOT NULL DEFAULT 1,\n"
"    last_run DOUBLE PRECISION,\n"
"    next_run DOUBLE PRECISION NOT NULL,\n"
"    last_job BIGINT,\n"
"    created  DOUBLE PRECISION NOT NULL,\n"
"    updated  DOUBLE PRECISION NOT NULL\n"
")\n"
"-- @@\n"
/* THE index - see PQ_SQLITE_UP for why delayed and parents_left are not
 * in it. */
"CREATE INDEX pq_jobs_ready ON pq_jobs (queue, priority DESC, id)\n"
"    WHERE state = 'inactive'\n"
"-- @@\n"
"CREATE INDEX pq_jobs_delayed ON pq_jobs (delayed) WHERE state = 'inactive'\n"
"-- @@\n"
"CREATE INDEX pq_jobs_gc ON pq_jobs (state, finished)\n"
"-- @@\n"
"CREATE INDEX pq_jobs_expires ON pq_jobs (expires) WHERE state = 'inactive'\n"
"-- @@\n"
"CREATE INDEX pq_jobs_worker ON pq_jobs (worker) WHERE state = 'active'\n"
"-- @@\n"
"CREATE INDEX pq_jobs_task ON pq_jobs (task, state)\n"
"-- @@\n"
"CREATE UNIQUE INDEX pq_jobs_lock_key ON pq_jobs (lock_key)\n"
"    WHERE lock_key IS NOT NULL AND state IN ('inactive', 'active')\n"
"-- @@\n"
"CREATE INDEX pq_deps_parent ON pq_job_deps (parent_id)\n"
"-- @@\n"
"CREATE UNIQUE INDEX pq_locks_name ON pq_locks (name) WHERE owner IS NOT NULL\n"
"-- @@\n"
"CREATE INDEX pq_locks_expires ON pq_locks (expires)\n"
"-- @@\n"
"CREATE INDEX pq_crons_due ON pq_crons (next_run) WHERE enabled = 1\n"
"-- @@\n"
/* Storing epoch seconds buys identical binds and comparisons on both
 * backends, and costs readability at a psql prompt. This view is the
 * apology: SELECT * FROM pq_jobs_human is what a human wants at 3am. */
"CREATE VIEW pq_jobs_human AS SELECT\n"
"    id, task, queue, state, priority, attempts, retries, parents_left,\n"
"    to_timestamp(created)  AS created,\n"
"    to_timestamp(delayed)  AS delayed,\n"
"    to_timestamp(started)  AS started,\n"
"    to_timestamp(finished) AS finished,\n"
"    to_timestamp(retried)  AS retried,\n"
"    to_timestamp(expires)  AS expires,\n"
"    worker, lock_key, cron_id, args, notes, result\n"
"  FROM pq_jobs\n"
,

/* ---- 2 ------------------------------------------------------------------
 * In lockstep with PQ_SQLITE_UP step 2. */
"ALTER TABLE pq_jobs ADD COLUMN timeout DOUBLE PRECISION\n"
,

/* ---- 3 ------------------------------------------------------------------
 * Per-job log lines: the worker's lifecycle events and whatever the task
 * body writes through $job->log. Rows live and die with their job -
 * remove_job, repair's ancient sweep and reset all cascade here. */
"CREATE TABLE pq_job_logs (\n"
"    id      BIGSERIAL PRIMARY KEY,\n"
"    job_id  BIGINT NOT NULL,\n"
"    created DOUBLE PRECISION NOT NULL,\n"
"    level   TEXT NOT NULL DEFAULT 'info',\n"
"    message TEXT NOT NULL\n"
")\n"
"-- @@\n"
"CREATE INDEX pq_job_logs_job ON pq_job_logs (job_id, id)\n"
,

    NULL   /* terminator */
};

#endif /* PQ_MIGRATE_PG_H */

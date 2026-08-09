#ifndef PQ_MIGRATE_SQLITE_H
#define PQ_MIGRATE_SQLITE_H

/* The SQLite schema, as an ordered array of migration steps.
 *
 * String literals in a C header rather than a __DATA__ section, because the
 * .pm files in this dist are POD only and putting DDL in one of them would
 * make it the exception. Each array element is one migration; statements
 * within a migration are separated by a line containing only "-- @@", split
 * by pq_migrate.h.
 *
 * Times are REAL epoch seconds, never a SQLite date string: identical bind
 * values and comparison semantics to Pg's DOUBLE PRECISION, and no driver
 * timestamp parsing anywhere in the C. JSON columns are TEXT and decode
 * through frj.
 *
 * APPEND ONLY. A shipped migration is a contract with every database that
 * has already run it; to change the schema, add a step. */

static const char *const PQ_SQLITE_UP[] = {

/* ---- 1 ------------------------------------------------------------------ */
"CREATE TABLE pq_jobs (\n"
"    id           INTEGER PRIMARY KEY AUTOINCREMENT,\n"
"    task         TEXT    NOT NULL,\n"
"    args         TEXT    NOT NULL DEFAULT '[]',\n"
"    queue        TEXT    NOT NULL DEFAULT 'default',\n"
"    state        TEXT    NOT NULL DEFAULT 'inactive',\n"
"    priority     INTEGER NOT NULL DEFAULT 0,\n"
"    attempts     INTEGER NOT NULL DEFAULT 1,\n"
"    retries      INTEGER NOT NULL DEFAULT 0,\n"
"    parents_left INTEGER NOT NULL DEFAULT 0,\n"
"    lax          INTEGER NOT NULL DEFAULT 0,\n"
"    created      REAL    NOT NULL,\n"
"    delayed      REAL    NOT NULL,\n"
"    started      REAL,\n"
"    finished     REAL,\n"
"    retried      REAL,\n"
"    expires      REAL,\n"
"    result       TEXT,\n"
"    notes        TEXT    NOT NULL DEFAULT '{}',\n"
"    worker       INTEGER,\n"
"    lock_key     TEXT,\n"
"    cron_id      INTEGER\n"
")\n"
"-- @@\n"
"CREATE TABLE pq_job_deps (\n"
"    job_id    INTEGER NOT NULL REFERENCES pq_jobs(id) ON DELETE CASCADE,\n"
"    parent_id INTEGER NOT NULL REFERENCES pq_jobs(id) ON DELETE CASCADE,\n"
"    PRIMARY KEY (job_id, parent_id)\n"
")\n"
"-- @@\n"
"CREATE TABLE pq_workers (\n"
"    id       INTEGER PRIMARY KEY AUTOINCREMENT,\n"
"    host     TEXT    NOT NULL,\n"
"    pid      INTEGER NOT NULL,\n"
"    role     TEXT    NOT NULL DEFAULT 'child',\n"
"    queues   TEXT    NOT NULL DEFAULT '[]',\n"
"    jobs     INTEGER NOT NULL DEFAULT 1,\n"
"    status   TEXT    NOT NULL DEFAULT '{}',\n"
"    inbox    TEXT    NOT NULL DEFAULT '[]',\n"
"    version  TEXT,\n"
"    started  REAL    NOT NULL,\n"
"    notified REAL    NOT NULL\n"
")\n"
"-- @@\n"
"CREATE TABLE pq_locks (\n"
"    id      INTEGER PRIMARY KEY AUTOINCREMENT,\n"
"    name    TEXT   NOT NULL,\n"
"    owner   INTEGER,\n"
"    expires REAL   NOT NULL\n"
")\n"
"-- @@\n"
"CREATE TABLE pq_crons (\n"
"    id       INTEGER PRIMARY KEY AUTOINCREMENT,\n"
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
"    last_run REAL,\n"
"    next_run REAL    NOT NULL,\n"
"    last_job INTEGER,\n"
"    created  REAL    NOT NULL,\n"
"    updated  REAL    NOT NULL\n"
")\n"
"-- @@\n"
/* THE index. Partial on state, so the b-tree only ever holds claimable
 * rows and stays small however large the finished history grows.
 * `delayed` and `parents_left` are deliberately absent: putting `delayed`
 * ahead of `priority` kills the ordered scan, and putting it after does
 * nothing. They filter an already-tiny index. */
"CREATE INDEX pq_jobs_ready ON pq_jobs (queue, priority DESC, id)\n"
"    WHERE state = 'inactive'\n"
"-- @@\n"
/* arms the idle sleep horizon: SELECT min(delayed) ... */
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
/* unique-job dedupe: only live jobs collide, so a finished job does not
 * block a re-enqueue of the same key */
"CREATE UNIQUE INDEX pq_jobs_lock_key ON pq_jobs (lock_key)\n"
"    WHERE lock_key IS NOT NULL AND state IN ('inactive', 'active')\n"
"-- @@\n"
"CREATE INDEX pq_deps_parent ON pq_job_deps (parent_id)\n"
"-- @@\n"
/* the leader-election arbiter: one INSERT wins, the rest get a constraint
 * violation, which removes the count-then-insert race for limit-1 leases */
"CREATE UNIQUE INDEX pq_locks_name ON pq_locks (name) WHERE owner IS NOT NULL\n"
"-- @@\n"
"CREATE INDEX pq_locks_expires ON pq_locks (expires)\n"
"-- @@\n"
"CREATE INDEX pq_crons_due ON pq_crons (next_run) WHERE enabled = 1\n"
,

/* ---- 2 ------------------------------------------------------------------
 * Per-job timeout, seconds; NULL means none. A new column rather than a
 * notes key because the supervisor's hard-kill check reads it on every
 * claim line and phase 8's UI filters on it. */
"ALTER TABLE pq_jobs ADD COLUMN timeout REAL\n"
,

/* ---- 3 ------------------------------------------------------------------
 * Per-job log lines: the worker's lifecycle events and whatever the task
 * body writes through $job->log. Rows live and die with their job -
 * remove_job, repair's ancient sweep and reset all cascade here. */
"CREATE TABLE pq_job_logs (\n"
"    id      INTEGER PRIMARY KEY AUTOINCREMENT,\n"
"    job_id  INTEGER NOT NULL,\n"
"    created REAL    NOT NULL,\n"
"    level   TEXT    NOT NULL DEFAULT 'info',\n"
"    message TEXT    NOT NULL\n"
")\n"
"-- @@\n"
"CREATE INDEX pq_job_logs_job ON pq_job_logs (job_id, id)\n"
,

    NULL   /* terminator */
};

#endif /* PQ_MIGRATE_SQLITE_H */

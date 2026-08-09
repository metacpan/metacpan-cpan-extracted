#ifndef PQ_TIME_H
#define PQ_TIME_H

/* Time in Punk::Queue is epoch seconds as a double, everywhere: the columns
 * are DOUBLE PRECISION on Pg and REAL on SQLite, never TIMESTAMPTZ. That
 * buys identical bind values and identical comparison semantics on both
 * backends, no driver timestamp parsing in C, and a dequeue predicate of
 * `delayed <= ?` with a bound value rather than a server-side now().
 *
 * What it costs is readability in psql, which the pq_jobs_human view
 * mitigates, and it makes clock skew our problem instead of the server's.
 * Hence the delta below.
 *
 * Include after pq_compat.h. */

#ifdef HAS_GETTIMEOFDAY
#  include <sys/time.h>
#endif

/* Wall clock on THIS host, epoch seconds. Not what you bind - see pq_now. */
static double pq_now_local(pTHX) {
#ifdef HAS_GETTIMEOFDAY
    struct timeval tv;
    if (gettimeofday(&tv, NULL) == 0)
        return (double)tv.tv_sec + (double)tv.tv_usec / 1000000.0;
#endif
    return (double)time(NULL);
}

/* ---- clock skew -----------------------------------------------------------
 *
 * Every worker binds its own idea of "now" into delayed/started/expires, and
 * every other worker compares those against its own. Two hosts a minute apart
 * is enough to claim a delayed job early or leave a fresh one sitting, and
 * the symptom ("the job ran an hour before its delay") is baffling from the
 * inside.
 *
 * So each connection probes the server's clock once, stores the difference,
 * and every timestamp this process binds is local + delta. The probe SQL is
 * per-backend (pq_sqlite.h, pq_pg.h); the arithmetic is here.
 *
 * The delta lives in the connection pool slot, so it is re-probed on
 * reconnect and after a fork, which is exactly when it can have changed. */

#define PQ_DELTA_KEY "clock_delta"

/* now, in the database's frame of reference. This is what gets bound. */
static double pq_now_delta(pTHX_ double delta) {
    return pq_now_local(aTHX) + delta;
}

#endif /* PQ_TIME_H */

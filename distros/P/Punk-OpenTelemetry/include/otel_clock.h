/* otel_clock.h - when a span started, and how long it took.
 *
 * OTLP wants unix nanoseconds for BOTH ends of a span, which invites the
 * obvious implementation: read the wall clock twice and write both numbers.
 * That implementation is wrong, and wrong in a way that only shows up in
 * production.
 *
 * The wall clock is not monotonic. NTP steps it, an operator sets it, a VM
 * resumes from a snapshot and it jumps. Between two reads it can move
 * backwards, and a span whose end precedes its start is one collectors
 * variously drop, clamp to zero, or display as a negative duration - none of
 * which is the truth, and all of which happen to the trace that was
 * interesting enough to be looked at.
 *
 * So: the wall clock is read ONCE, at start, to place the span in time. The
 * DURATION is measured on a monotonic clock, which is what monotonic clocks
 * are for, and the end timestamp is derived as start plus elapsed. The span
 * lands at the right absolute moment and always has a non-negative length.
 *
 * Where no monotonic clock exists the wall clock is used for both, and the
 * derived end is clamped to be no earlier than the start. That is the best
 * available answer rather than a good one.
 */

#ifndef OTEL_CLOCK_H
#define OTEL_CLOCK_H

#include <time.h>
#ifndef _WIN32
#  include <sys/time.h>
#endif

/* Wall clock, unix nanoseconds. Where a span sits in time. */
static U64TYPE otel_wall_nanos(void) {
#if defined(CLOCK_REALTIME) && !defined(_WIN32)
    struct timespec ts;
    if (clock_gettime(CLOCK_REALTIME, &ts) == 0)
        return (U64TYPE)ts.tv_sec * 1000000000ULL + (U64TYPE)ts.tv_nsec;
#endif
#ifndef _WIN32
    {
        struct timeval tv;
        if (gettimeofday(&tv, NULL) == 0)
            return (U64TYPE)tv.tv_sec * 1000000000ULL
                 + (U64TYPE)tv.tv_usec * 1000ULL;
    }
#endif
    return (U64TYPE)time(NULL) * 1000000000ULL;
}

/* Monotonic nanoseconds. Not an absolute time - only differences mean
 * anything - which is precisely why it is the right clock for a duration. */
static U64TYPE otel_mono_nanos(void) {
#if defined(OTEL_HAVE_CLOCK_MONOTONIC) && !defined(_WIN32)
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) == 0)
        return (U64TYPE)ts.tv_sec * 1000000000ULL + (U64TYPE)ts.tv_nsec;
#endif
    return otel_wall_nanos();   /* no monotonic clock: see the clamp below */
}

/* The end timestamp for a span that started at (wall, mono).
 *
 * The clamp matters only on a platform with no monotonic clock, where both
 * reads are of the wall clock and the second can legitimately be smaller.
 * A zero-length span is a lie, but it is a smaller lie than a negative one,
 * and it is the one a collector will actually store. */
static U64TYPE otel_end_nanos(U64TYPE start_wall, U64TYPE start_mono) {
    U64TYPE now = otel_mono_nanos();
    if (now < start_mono) return start_wall;
    return start_wall + (now - start_mono);
}

#endif /* OTEL_CLOCK_H */

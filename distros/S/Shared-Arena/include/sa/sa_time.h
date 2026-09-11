#ifndef SA_TIME_H
#define SA_TIME_H

/* sa_time.h - how long to wait, measured in time. Perl-free.
 *
 * ---- an iteration count is not a bound anybody wants ------------------------
 *
 * Rule 5 of this dist says every wait is bounded. The waits WERE bounded, by a
 * spin count, and that is the wrong quantity in both directions at once. Two
 * hundred thousand iterations of a tight loop is under a millisecond on a fast
 * machine - so a process that was merely descheduled at the wrong moment gets
 * abandoned - and two hundred thousand iterations of a loop containing an fstat
 * is two hundred thousand SYSCALLS, which is a core burned to discover that
 * somebody else has not finished yet.
 *
 * A deadline says what was actually meant: wait this long, sleeping rather than
 * spinning, and give up when the time is gone however many turns that took.
 *
 * ---- gettimeofday, and not clock_gettime -----------------------------------
 *
 * clock_gettime is the better clock and it lives in librt on glibc before 2.17,
 * which means a probe, a link flag, and a build that fails on the one machine
 * that has neither. gettimeofday is in libc everywhere this builds and needs
 * none of that.
 *
 * The price is that it is not monotonic: a clock stepped backwards during a
 * wait makes that wait longer. Every caller therefore keeps a generous
 * iteration backstop as well, so the worst a stepped clock can do is turn a
 * bounded wait into a differently bounded one. It cannot turn it into a hang,
 * which is the property rule 5 is actually about.
 */

#ifdef _WIN32
#  include <windows.h>
#else
#  include <sys/time.h>
#  include <time.h>
#endif

#include <stdint.h>

/* Microseconds from some fixed point. Only differences are ever used. */
static uint64_t sa_now_us(void) {
#ifdef _WIN32
    return (uint64_t)GetTickCount64() * 1000u;
#else
    struct timeval tv;
    if (gettimeofday(&tv, NULL) != 0) return 0;
    return (uint64_t)tv.tv_sec * 1000000u + (uint64_t)tv.tv_usec;
#endif
}

/* Sleep, in microseconds. A real sleep and not a spin: a process waiting on
 * somebody else's commit has nothing to do, and burning a core to find that out
 * helps nobody. */
static void sa_stall(uint32_t us) {
#ifdef _WIN32
    Sleep((DWORD)((us + 999) / 1000));
#else
    struct timespec ts;
    ts.tv_sec  = (time_t)(us / 1000000u);
    ts.tv_nsec = (long)((us % 1000000u) * 1000u);
    nanosleep(&ts, NULL);
#endif
}

/* How long a process waits for another one to finish publishing a header it has
 * already begun. Long enough that an ordinary preemption is invisible, short
 * enough that a creator which died mid-header does not hold anybody up. */
#define SA_CREATE_WAIT_US 2000000   /* two seconds */
#define SA_CREATE_POLL_US 200       /* between looks */

#endif /* SA_TIME_H */

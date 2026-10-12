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
 * ---- CLOCK_MONOTONIC where the build found one, gettimeofday where not ------
 *
 * clock_gettime lives in librt on glibc before 2.17, which means a probe, a
 * link flag, and a build that fails on the one machine that has neither. So
 * Makefile.PL probes for CLOCK_MONOTONIC by RUNNING it, bare and then with
 * -lrt, and defines SA_HAVE_MONOTONIC_CLOCK when it answers. gettimeofday is in
 * libc everywhere this builds and stays as the fallback.
 *
 * The fallback is not monotonic: a clock stepped backwards during a wait makes
 * that wait longer. Every caller therefore keeps a generous iteration backstop
 * as well, so the worst a stepped clock can do is turn a bounded wait into a
 * differently bounded one. It cannot turn it into a hang, which is the
 * property rule 5 is actually about.
 *
 * It matters for more than a wait. The rate limiter STORES this clock's reading
 * in the arena beside the tokens, so a step in the clock is a step in every
 * bucket's clock at once. A Linux smoker's wall clock went back about 0.6s
 * between a bucket being emptied and being read, and the bucket read as
 * refilling nothing for 0.6s - correctly, by its own arithmetic, since no time
 * had passed. A monotonic clock cannot be stepped. It is one clock for every
 * process on the machine, and an arena is a shared-memory segment that does
 * not outlive a boot, so a reading one process stores is on the clock the next
 * one reads.
 */

#ifdef _WIN32
#  include <windows.h>
#else
#  include <sys/time.h>
#  include <time.h>
#endif

#include <stdint.h>

/* Microseconds from some fixed point - boot, where the clock is monotonic.
 * Only differences are ever used. */
static uint64_t sa_now_us(void) {
#ifdef _WIN32
    /* QueryPerformanceCounter and not GetTickCount64: the latter is declared
     * only for _WIN32_WINNT >= 0x0600, which perl's own headers do not set, so
     * it compiled as an implicit int and failed at link. This one is declared
     * everywhere, is one counter for every process, and cannot be stepped. The
     * division is split so the product does not overflow after days of uptime. */
    LARGE_INTEGER c, f;
    if (!QueryPerformanceFrequency(&f) || f.QuadPart <= 0) return 0;
    if (!QueryPerformanceCounter(&c)) return 0;
    return (uint64_t)(c.QuadPart / f.QuadPart) * 1000000u
         + (uint64_t)(c.QuadPart % f.QuadPart) * 1000000u / (uint64_t)f.QuadPart;
#else
    struct timeval tv;
#  ifdef SA_HAVE_MONOTONIC_CLOCK
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) == 0)
        return (uint64_t)ts.tv_sec * 1000000u + (uint64_t)(ts.tv_nsec / 1000);
#  endif
    if (gettimeofday(&tv, NULL) != 0) return 0;
    return (uint64_t)tv.tv_sec * 1000000u + (uint64_t)tv.tv_usec;
#endif
}

/* Milliseconds since the epoch. A WALL clock, deliberately, and a different
 * one from sa_now_us above: a deadline is a moment, set by one process, read by
 * another and shown to an operator, and the epoch is the one origin every
 * reader of it agrees on. sa_now_us is a tick for measuring intervals; this is
 * a timestamp for comparing deadlines. A step in it moves every deadline
 * together, which costs at worst one round of early or late expiry - the cache
 * and the map's TTL both accept that, and their tests measure their sleeps on
 * this same clock because of it. */
static uint64_t sa_now_ms(void) {
#ifdef _WIN32
    FILETIME ft;
    ULARGE_INTEGER u;
    GetSystemTimeAsFileTime(&ft);
    u.LowPart  = ft.dwLowDateTime;
    u.HighPart = ft.dwHighDateTime;
    /* 100ns units since 1601; the offset is dropped because only differences
     * and comparisons against each other matter here. */
    return (uint64_t)(u.QuadPart / 10000ULL);
#else
    struct timeval tv;
#  ifdef SA_HAVE_COARSE_CLOCK
    /* A millisecond deadline needs a millisecond clock, and on Linux the
     * coarse one is the kernel's last tick read out of the vDSO with no
     * counter access: about a quarter of gettimeofday's cost, which on a map
     * hit that carries a deadline was most of the hit. Its granularity is a
     * tick, up to four milliseconds, which is one round of early or late
     * expiry - the tolerance every deadline here already carries. Makefile.PL
     * probes for it by running it; the fallback is the clock below. */
    struct timespec ts;
    if (clock_gettime(CLOCK_REALTIME_COARSE, &ts) == 0)
        return (uint64_t)ts.tv_sec * 1000ULL + (uint64_t)(ts.tv_nsec / 1000000);
#  endif
    gettimeofday(&tv, NULL);
    return (uint64_t)tv.tv_sec * 1000ULL + (uint64_t)(tv.tv_usec / 1000);
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

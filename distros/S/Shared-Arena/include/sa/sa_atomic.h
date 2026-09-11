#ifndef SA_ATOMIC_H
#define SA_ATOMIC_H

/* sa_atomic.h - the atomics probe, and the operations the arena is built from.
 *
 * THE PROBE IS OF A FEATURE, NOT A COMPILER VERSION. The __atomic builtins
 * arrived in GCC 4.7, so __GNUC__ alone is the wrong question: asking it that
 * way is what broke a FreeBSD 9 build elsewhere in this workspace, whose base
 * cc is gcc 4.2.1. That compiler has the older __sync family (GCC 4.1), which
 * says everything needed here - a lock test-and-set IS an acquire, a lock
 * release IS a release, and a full barrier either side of a plain aligned word
 * turns it into the acquire load / release store a slot is published with.
 *
 * WINDOWS GETS REAL ATOMICS HERE, and that is a departure from the sibling
 * header in Hyperman, which disables them outright on _WIN32. Its reasoning is
 * that an arena exists to make state exact across a forked pool and Windows has
 * no fork, so per-process state is already exact. That reasoning does not
 * transfer: a named region is the whole point of this dist, and on Windows a
 * named region is the ONLY mode there is. A Windows build that fails open is a
 * Windows build with no product.
 *
 * Only when no family exists at all is the whole thing disabled, and every
 * caller fails open in that case. That is a supported configuration.
 */

#include <stdint.h>
#include <stddef.h>

#if defined(__has_builtin)
#  if __has_builtin(__atomic_load_n)
#    define SA_ATOMIC_GNU 1
#  endif
#endif
#if !defined(SA_ATOMIC_GNU) && defined(__GNUC__) \
    && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 7))
#  define SA_ATOMIC_GNU 1
#endif

#if defined(SA_ATOMIC_GNU)
#  define SA_HAVE_ATOMICS 1
#elif defined(__GNUC__) \
    && (__GNUC__ > 4 || (__GNUC__ == 4 && __GNUC_MINOR__ >= 1))
/* The __sync family. Note for whoever ports this to a 32-bit target: the
 * 64-bit __sync builtins can LINK-fail rather than compile-fail on x86 without
 * -march=i586 or better, so Makefile.PL's probe compiles AND links a 64-bit
 * compare-and-swap. A probe that only compiles would pass here and fail at
 * dlopen, which is the worst place to find out. */
#  define SA_HAVE_ATOMICS 1
#  define SA_ATOMIC_SYNC 1
#elif defined(_MSC_VER)
/* Untested: Strawberry is MinGW, which takes the GNU path above, so no smoker
 * in reach compiles this branch. It is here so an MSVC build is a compile
 * error to fix rather than a silent fail-open. */
#  include <windows.h>
#  include <intrin.h>
#  define SA_HAVE_ATOMICS 1
#  define SA_ATOMIC_MSVC 1
#else
#  define SA_HAVE_ATOMICS 0
#endif

/* ---- A 32-BIT TARGET CANNOT LOAD 64 BITS IN ONE GO -------------------------
 *
 * A naturally aligned 32-bit word is indivisible everywhere this builds. A
 * 64-bit one is NOT: on 32-bit x86 and 32-bit ARM a plain `uint64_t v = *p` is
 * two loads, and a reader can take the low half of one value and the high half
 * of another. Every sequence in the ring and the arena's high-water mark are
 * 64-bit, so a torn read there is a slot address out of thin air.
 *
 * The __atomic family already handles this: on a target that needs one it emits
 * a locked compare-exchange, or calls libatomic. The __sync family has no
 * 64-bit load at all, so where the machine word is narrow the pair below is
 * built out of compare-and-swap instead - which is what makes them atomic
 * rather than merely ordered. Makefile.PL link-probes a 64-bit CAS for exactly
 * this reason, so a target that reaches here has one.
 */
#if defined(UINTPTR_MAX) && UINTPTR_MAX <= 0xFFFFFFFFUL
#  define SA_NARROW_WORD 1
#endif

#define SA_LOCK_STRIPES  64        /* striped spinlocks in the header */
#define SA_SPIN_MAX      100000    /* bounded spin -> fail open       */

#if SA_HAVE_ATOMICS

/* Reads and writes of a naturally aligned 32-bit word cannot tear on any target
 * this builds on, and neither can a 64-bit one where the machine word is that
 * wide. The barrier is what orders them against the other fields of the record
 * they publish, and that is all the __sync spelling has to add. Where the word
 * is narrower, see SA_NARROW_WORD above: the 64-bit pair becomes a CAS. */

static int sa_at_tas(volatile unsigned char *l) {
#if defined(SA_ATOMIC_SYNC)
    return __sync_lock_test_and_set(l, (unsigned char)1) != 0;
#elif defined(SA_ATOMIC_MSVC)
    return _InterlockedExchange8((volatile char *)l, 1) != 0;
#else
    return __atomic_test_and_set(l, __ATOMIC_ACQUIRE) != 0;
#endif
}

static void sa_at_clear(volatile unsigned char *l) {
#if defined(SA_ATOMIC_SYNC)
    __sync_lock_release(l);
#elif defined(SA_ATOMIC_MSVC)
    _InterlockedExchange8((volatile char *)l, 0);
#else
    __atomic_clear(l, __ATOMIC_RELEASE);
#endif
}

/* MemoryBarrier rather than _ReadWriteBarrier on the MSVC path, and the
 * difference is not pedantry: _ReadWriteBarrier stops the COMPILER reordering
 * and emits no instruction, which is enough on x86 and nothing at all on the
 * ARM64 that MSVC also targets. This branch has no smoker, so it takes the
 * spelling that is correct everywhere over the one that is cheaper on the
 * machine nobody here is testing. */
static uint32_t sa_at_load32_acq(volatile uint32_t *p) {
#if defined(SA_ATOMIC_SYNC)
    uint32_t v = *p;
    __sync_synchronize();          /* nothing below may be hoisted above it */
    return v;
#elif defined(SA_ATOMIC_MSVC)
    uint32_t v = *p;
    MemoryBarrier();
    return v;
#else
    return __atomic_load_n(p, __ATOMIC_ACQUIRE);
#endif
}

static void sa_at_store32_rel(volatile uint32_t *p, uint32_t v) {
#if defined(SA_ATOMIC_SYNC)
    __sync_synchronize();          /* the other fields land before this one */
    *p = v;
#elif defined(SA_ATOMIC_MSVC)
    MemoryBarrier();
    *p = v;
#else
    __atomic_store_n(p, v, __ATOMIC_RELEASE);
#endif
}

/* Take the next N and return what this caller now owns, exclusively, across
 * every process sharing the mapping. The bump allocator and the ring's
 * reservation are both this one operation. */
static uint64_t sa_at_fetch_add64(volatile uint64_t *p, uint64_t n) {
#if defined(SA_ATOMIC_SYNC)
    return __sync_fetch_and_add(p, n);
#elif defined(SA_ATOMIC_MSVC)
    return (uint64_t)_InterlockedExchangeAdd64((volatile __int64 *)p,
                                               (__int64)n);
#else
    return __atomic_fetch_add(p, n, __ATOMIC_ACQ_REL);
#endif
}

static uint32_t sa_at_fetch_add32(volatile uint32_t *p, uint32_t n) {
#if defined(SA_ATOMIC_SYNC)
    return __sync_fetch_and_add(p, n);
#elif defined(SA_ATOMIC_MSVC)
    return (uint32_t)_InterlockedExchangeAdd((volatile long *)p, (long)n);
#else
    return __atomic_fetch_add(p, n, __ATOMIC_ACQ_REL);
#endif
}

/* Set bits in a word and return what was there before. A bloom filter is
 * nothing but this: no other operation in this dist needs it, because no other
 * structure lets two processes modify one word without agreeing first. */
static uint64_t sa_at_fetch_or64(volatile uint64_t *p, uint64_t bits) {
#if defined(SA_ATOMIC_SYNC)
    return __sync_fetch_and_or(p, bits);
#elif defined(SA_ATOMIC_MSVC)
    return (uint64_t)_InterlockedOr64((volatile __int64 *)p, (__int64)bits);
#else
    return __atomic_fetch_or(p, bits, __ATOMIC_ACQ_REL);
#endif
}

/* Compare and swap a 64-bit word; 1 if this caller won.
 *
 * A shared cursor is advanced with this and never with a plain fetch-add. A
 * fetch-add cannot be undone: a claimer that adds and then finds it overshot
 * the last published sequence has ALREADY moved the shared cursor past
 * sequences nobody has written, and those records are skipped forever with
 * nothing counted, because nothing noticed. A CAS advances only when the
 * caller both wins the race and is still inside what has been published. */
static int sa_at_cas64(volatile uint64_t *p, uint64_t expect, uint64_t want) {
#if defined(SA_ATOMIC_SYNC)
    return __sync_bool_compare_and_swap(p, expect, want) ? 1 : 0;
#elif defined(SA_ATOMIC_MSVC)
    return _InterlockedCompareExchange64((volatile __int64 *)p, (__int64)want,
                                         (__int64)expect) == (__int64)expect;
#else
    return __atomic_compare_exchange_n(p, &expect, want, 0,
                                       __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)
           ? 1 : 0;
#endif
}

/* The 64-bit pair, DEFINED AFTER THE CAS BECAUSE ON A NARROW WORD THEY ARE ONE.
 *
 * On a 64-bit machine these are a plain aligned access plus the barrier that
 * orders it. On a 32-bit one a plain access is two instructions and can tear,
 * so the load becomes a compare-and-swap against a value it does not expect -
 * which returns the current word whether or not it wins - and the store becomes
 * a CAS loop. Slower, and the only spelling that is correct there. */
static uint64_t sa_at_load64_acq(volatile uint64_t *p) {
#if defined(SA_NARROW_WORD) && defined(SA_ATOMIC_SYNC)
    return __sync_val_compare_and_swap(p, (uint64_t)0, (uint64_t)0);
#elif defined(SA_NARROW_WORD) && defined(SA_ATOMIC_MSVC)
    return (uint64_t)_InterlockedCompareExchange64((volatile __int64 *)p, 0, 0);
#elif defined(SA_ATOMIC_SYNC)
    uint64_t v = *p;
    __sync_synchronize();
    return v;
#elif defined(SA_ATOMIC_MSVC)
    uint64_t v = *p;
    MemoryBarrier();
    return v;
#else
    return __atomic_load_n(p, __ATOMIC_ACQUIRE);
#endif
}

static void sa_at_store64_rel(volatile uint64_t *p, uint64_t v) {
#if defined(SA_NARROW_WORD) && (defined(SA_ATOMIC_SYNC) || defined(SA_ATOMIC_MSVC))
    for (;;) {
        uint64_t old = sa_at_load64_acq(p);
        if (sa_at_cas64(p, old, v)) return;
    }
#elif defined(SA_ATOMIC_SYNC)
    __sync_synchronize();
    *p = v;
#elif defined(SA_ATOMIC_MSVC)
    MemoryBarrier();
    *p = v;
#else
    __atomic_store_n(p, v, __ATOMIC_RELEASE);
#endif
}

static int sa_at_cas32(volatile uint32_t *p, uint32_t expect, uint32_t want) {
#if defined(SA_ATOMIC_SYNC)
    return __sync_bool_compare_and_swap(p, expect, want) ? 1 : 0;
#elif defined(SA_ATOMIC_MSVC)
    return (uint32_t)_InterlockedCompareExchange((volatile long *)p,
                                                 (long)want, (long)expect)
           == expect;
#else
    return __atomic_compare_exchange_n(p, &expect, want, 0,
                                       __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)
           ? 1 : 0;
#endif
}

/* ---- fences, and why a release STORE is not enough -------------------------
 *
 * A release store orders everything BEFORE it against itself. It says nothing
 * about the writes that come after, which are free to become visible to another
 * CPU first. A seqlock writer that stores its sequence and then writes the body
 * therefore has no guarantee the body does not arrive first - and a reader that
 * sees the new body under the old sequence accepts it as whole.
 *
 * That is why the canonical seqlock has a barrier AFTER the opening sequence
 * store and BEFORE the closing one, and a read barrier between the body and the
 * second sequence load. Linux spells them smp_wmb and smp_rmb; these are the
 * same two, over whichever builtin family exists.
 *
 * Getting this wrong is not theoretical and does not show up in a gentle test:
 * it produced whole, well-formed records delivered under a sequence belonging
 * to a different one, about ten times in sixteen thousand, only under real
 * multi-process contention. */

static void sa_at_fence_rel(void) {
#if defined(SA_ATOMIC_SYNC)
    __sync_synchronize();
#elif defined(SA_ATOMIC_MSVC)
    MemoryBarrier();
#else
    __atomic_thread_fence(__ATOMIC_RELEASE);
#endif
}

static void sa_at_fence_acq(void) {
#if defined(SA_ATOMIC_SYNC)
    __sync_synchronize();
#elif defined(SA_ATOMIC_MSVC)
    MemoryBarrier();
#else
    __atomic_thread_fence(__ATOMIC_ACQUIRE);
#endif
}

/* Bounded acquire on a striped lock; 1 if taken, 0 if it gave up. A process
 * that died holding one must not wedge everybody else, so the caller fails
 * open rather than spinning forever. */
static int sa_at_lock(volatile unsigned char *locks, uint64_t h) {
    volatile unsigned char *l = &locks[h % SA_LOCK_STRIPES];
    long spin = 0;
    while (sa_at_tas(l)) {
        if (++spin >= SA_SPIN_MAX) return 0;
    }
    return 1;
}

static void sa_at_unlock(volatile unsigned char *locks, uint64_t h) {
    sa_at_clear(&locks[h % SA_LOCK_STRIPES]);
}

#endif /* SA_HAVE_ATOMICS */

/* FNV-1a 64, for hashing a name onto a lock stripe. Not cryptographic and not
 * meant to be: a collision costs a spin. */
static uint64_t sa_at_fnv(const void *data, size_t len) {
    const unsigned char *p = (const unsigned char *)data;
    uint64_t h = 1469598103934665603ULL;
    size_t i;
    for (i = 0; i < len; i++) { h ^= p[i]; h *= 1099511628211ULL; }
    return h;
}

#endif /* SA_ATOMIC_H */

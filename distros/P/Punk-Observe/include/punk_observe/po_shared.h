/* po_shared.h - the fork-shared arena, and the cardinality cap in it.
 *
 * Cardinality is the failure mode that kills observability backends, and it
 * always arrives the same way: somebody puts a user id, a request id or a
 * full URL into an attribute, and the series count goes from thousands to
 * millions in an afternoon. The limit therefore has to be a HARD CAP enforced
 * at ingest, not a dashboard warning nobody is looking at.
 *
 * With phase 4's content-derived series ids there is no central assigner to
 * hang the counter on, so it lives here: one MAP_SHARED|MAP_ANONYMOUS region,
 * MAPPED BEFORE THE FORK, incremented atomically by every worker.
 *
 * THE ORDER MATTERS AND THE FAILURE IS SILENT. A region mapped AFTER the fork
 * is private per worker: each one counts its own series, the effective limit
 * becomes N times what was configured, and nothing anywhere reports a problem
 * - the operator simply finds the cap did not hold. the tail's ring makes the same
 * point about its own waker descriptors, and calls the symptom "delivery
 * works to some workers", which is the same shape of bug.
 */
#ifndef PO_SHARED_H
#define PO_SHARED_H

#include "punk_observe/po_compat.h"
#include "punk_observe/po_time.h"

#ifndef _WIN32
#  include <sys/mman.h>
#  include <unistd.h>
#endif

#define PO_SHM_MAGIC 0x4D48534Fu     /* "OSHM" */

/* Deliberately small and flat. Anything that needs a variable-size shared
 * structure needs a different mechanism; this is a fixed set of counters. */
typedef struct {
    uint32_t magic;
    uint32_t slots;
    po_u64   pid_at_map;      /* the process that created it, for the guard */
    po_u64   series;          /* distinct series admitted                   */
    po_u64   series_cap;      /* 0 = unlimited                              */
    po_u64   rejected;        /* series refused by the cap                  */
    po_u64   overflow;        /* records attributed to the overflow series  */
    po_u64   records;         /* accepted                                   */
    po_u64   bytes;           /* accepted, for metering                     */

    /* The ingest rate window, HERE rather than in each worker.
     *
     * A per-worker window on a four-worker box is four times the configured
     * limit, and the symptom is a limiter that looks like it is not working
     * rather than like a fork bug. Appended to this struct because the arena
     * is already mapped before the fork and already carries the counters that
     * have to be shared. */
    po_u64   rate_window_start;
    po_u64   rate_records;
    po_u64   rate_bytes;

    po_u64   rate_rejected;

    /* Lines the live tail was lapped past, summed across workers. The
     * per-process counter in Observe.xs is honest only to the one worker
     * that drained; the status page renders in whichever worker got the
     * request, so a number it can trust has to live here. APPENDED - after
     * rate_rejected, which was the tail - like the rate window before it,
     * because the arena is mapped before the fork. */
    po_u64   live_gaps;

    /* The seen-series bloom filter, which is what makes `series` a number
     * rather than a wish.
     *
     * THE COUNTER EXISTED FOR MONTHS AND NOTHING FED IT. A series id is
     * derived - H128 of the canonical label block - precisely so every
     * worker computes it with no authority and no lock, which also means
     * there is no admission event to count: knowing a series is NEW needs
     * the set of ids already seen. A flat page cannot hold a set, but it
     * can hold a bloom filter over one - and with a second region for the
     * REFUSED ids, that is enough for the gate as well as the count.
     * The status page read the counter anyway and showed `0 of 100,000`
     * over a third of a gigabyte of data: an all-clear nobody checked.
     *
     * A false positive reads a genuinely new series as already seen, so the
     * count can run slightly LOW - the safe direction for a figure whose
     * job is warning that a cap is near. Two workers racing the same new id
     * can both count it, so it can also run a worker or two HIGH; the
     * doctrine is po_shared_admit_series's, one field up: a guard rail, not
     * an accounting boundary. What must be exact is that it MOVES.
     * `bloom_words` is written once at map time, before the fork. */
    po_u64   bloom_words;

    /* THE WINDOW, which is what clears the old so the new can load.
     *
     * A bloom filter can only add, so without this the admitted set was
     * append-only for the life of the process: a series that stopped
     * reporting weeks ago - its data long since retained away - still held
     * one of the cap's slots until a restart. Eviction is still never the
     * answer; LIVENESS is. Two admitted generations rotate every window_ns:
     * an active series re-registers itself into the new generation the
     * moment its next record arrives, and a dead one simply never does.
     * `series` counts the current generation, so the page reads "active",
     * not "ever". `rejected` and `overflow` stay monotonic. */
    po_u64   window_ns;
    po_u64   epoch_start;
    po_u64   gen;
} po_shm;

/* Three equal regions after the header: admitted generation A, admitted
 * generation B, refused. Which of A/B is current is gen & 1. */
#define PO_SHM_BLOOM(m)       ((po_u64 *)((char *)(m) + sizeof(po_shm)))
#define PO_SHM_REGION(m, i)   (PO_SHM_BLOOM(m) + (i) * (m)->bloom_words)

typedef struct {
    po_shm *m;
    size_t  len;
    int     ok;
} po_shared;

static int po_shared_init(po_shared *s, po_u64 series_cap) {
#ifndef _WIN32
    void *p;
    po_u64 entries, bloom_bytes;
    memset(s, 0, sizeof(*s));

    /* ~16 bits per expected series at 4 probes keeps the false-positive
     * rate low enough that the undercount is noise. Sized from the cap
     * when there is one; a megabyte's worth when there is not, because a
     * capless install still deserves the number. Anonymous shared pages are
     * allocated on first touch, so a generous size costs address space and
     * not resident memory until the series actually exist. */
    entries = series_cap ? series_cap : 1000000;
    bloom_bytes = entries * 2;                       /* 16 bits per entry */
    bloom_bytes = (bloom_bytes + 4095) & ~(po_u64)4095;
    if (bloom_bytes < 4096) bloom_bytes = 4096;

    s->len = 4096 + (size_t)bloom_bytes * 3;   /* admitted A, B, refused */
    p = mmap(NULL, s->len, PROT_READ | PROT_WRITE,
             MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (p == MAP_FAILED) return 0;
    s->m = (po_shm *)p;
    memset(s->m, 0, sizeof(po_shm));
    s->m->magic       = PO_SHM_MAGIC;
    s->m->pid_at_map  = (po_u64)getpid();
    s->m->series_cap  = series_cap;
    s->m->bloom_words = bloom_bytes / 8;
    /* A day, unless the caller says otherwise. Long enough that a series
     * quiet over a weekend deploy does not churn; short enough that last
     * week's dead pods stop holding cap slots. */
    s->m->window_ns   = 86400ULL * 1000000000ULL;
    s->m->epoch_start = po_now_ns();
    s->ok = 1;
    return 1;
#else
    memset(s, 0, sizeof(*s));
    (void)series_cap;
    return 0;
#endif
}

static void po_shared_free(po_shared *s) {
#ifndef _WIN32
    if (s->m) munmap(s->m, s->len);
#endif
    s->m = NULL; s->ok = 0;
}

/* Admit a series, or refuse it.
 *
 * Returns 1 if the series may be created, 0 if the cap refuses it.
 *
 * OVER THE CAP, THE NEW SERIES IS DROPPED AND THE EXISTING ONES KEEP WORKING.
 * The tempting alternative - evict something to make room - converts a
 * cardinality problem into DATA LOSS on whichever series happens to be least
 * recently used, which is very likely the one somebody has open on a
 * dashboard right now. Dropping the new one is visible, bounded, and
 * attributable; evicting an old one is none of those.
 *
 * The refusal is counted and the records are attributed to a named overflow
 * series, in the shape Punk::OpenTelemetry already uses on the client
 * (otel.metric.overflow), so the data says "you exceeded the cap" rather than
 * going quietly missing. */
static int po_shared_admit_series(po_shared *s) {
    po_u64 cap, cur;
    if (!s->ok || !s->m) return 1;               /* unconfigured: no cap */
    cap = s->m->series_cap;
    if (!cap) { po_atomic_add(&s->m->series, 1); return 1; }

    cur = po_atomic_load(&s->m->series);
    if (cur >= cap) {
        po_atomic_add(&s->m->rejected, 1);
        po_atomic_add(&s->m->overflow, 1);
        return 0;
    }
    /* A racy check-then-increment can overshoot by at most the number of
     * workers, which is bounded and harmless: the cap is a guard rail, not an
     * accounting boundary. Making it exact would need a compare-and-swap loop
     * on the ingest path, and the cost of that is not worth a difference of
     * N series out of a million. What must be exact is that it STOPS. */
    po_atomic_add(&s->m->series, 1);
    return 1;
}

#if defined(PO_HAVE_ATOMICS) && !defined(_WIN32)
/* region 0 = admitted, region 1 = refused. Two sets, because marking a
 * REFUSED id in the admitted bloom would make its next record read as an
 * existing series and sail through the cap it was just refused by. */
static int po_shm_bloom_test(const po_shm *m, int region,
                         po_u64 id_hi, po_u64 id_lo) {
    const po_u64 *bloom = PO_SHM_REGION((po_shm *)m, region);
    int k;
    for (k = 0; k < 4; k++) {
        /* Double hashing: probe_i = hi + i*lo, on the halves the id is. */
        po_u64 bit  = (id_hi + (po_u64)k * id_lo) % (m->bloom_words * 64);
        po_u64 mask = (po_u64)1 << (bit & 63);
        if (!(__atomic_load_n((po_u64 *)&bloom[bit >> 6], __ATOMIC_SEQ_CST)
              & mask)) return 0;
    }
    return 1;
}

static void po_shm_bloom_set(po_shm *m, int region, po_u64 id_hi, po_u64 id_lo) {
    po_u64 *bloom = PO_SHM_REGION(m, region);
    int k;
    for (k = 0; k < 4; k++) {
        po_u64 bit  = (id_hi + (po_u64)k * id_lo) % (m->bloom_words * 64);
        po_u64 mask = (po_u64)1 << (bit & 63);
        (void)__atomic_fetch_or(&bloom[bit >> 6], mask, __ATOMIC_SEQ_CST);
    }
}
#endif

#if defined(PO_HAVE_ATOMICS) && !defined(_WIN32)
/* The rotation itself, taken by whoever wins the epoch CAS. The region that
 * was `previous` becomes `current` and is cleared first; refused is cleared
 * with it, so a series refused last window gets one fresh chance against the
 * freed slots. Workers racing the memset can lose a just-set bit, which
 * costs a recount later - the guard-rail doctrine, again. */
static void po_shm_rotate(po_shm *m) {
    po_u64 next = m->gen + 1;
    memset(PO_SHM_REGION(m, (int)(next & 1)), 0, (size_t)m->bloom_words * 8);
    memset(PO_SHM_REGION(m, 2),               0, (size_t)m->bloom_words * 8);
    po_atomic_store(&m->series, 0);
    __atomic_store_n(&m->gen, next, __ATOMIC_SEQ_CST);
}

static void po_shm_maybe_rotate(po_shm *m) {
    po_u64 now, epoch;
    if (!m->window_ns) return;
    now   = po_now_ns();
    epoch = __atomic_load_n(&m->epoch_start, __ATOMIC_SEQ_CST);
    if (now < epoch || now - epoch < m->window_ns) return;
    /* One winner per window: the CAS on the epoch is the election. */
    if (__atomic_compare_exchange_n(&m->epoch_start, &epoch, now, 0,
                                    __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST))
        po_shm_rotate(m);
}
#endif

/* Force one id into the admitted set, cap or no cap: the overflow series
 * itself has to be admitted or attributing to it would loop. Counts it once. */
static void po_shared_series_force(po_shared *s, po_u64 id_hi, po_u64 id_lo) {
#if defined(PO_HAVE_ATOMICS) && !defined(_WIN32)
    int cur;
    if (!s->ok || !s->m || !s->m->bloom_words) return;
    po_shm_maybe_rotate(s->m);
    cur = (int)(__atomic_load_n(&s->m->gen, __ATOMIC_SEQ_CST) & 1);
    if (po_shm_bloom_test(s->m, cur, id_hi, id_lo)) return;
    po_shm_bloom_set(s->m, cur, id_hi, id_lo);
    po_atomic_add(&s->m->series, 1);
#else
    (void)s; (void)id_hi; (void)id_lo;
#endif
}

/* THE GATE. One series id, one answer:
 *
 *   1  admit - an existing series, or a new one with room under the cap
 *   0  refuse - a new series past the cap; attribute the record to the
 *      overflow series and keep going
 *
 * OVER THE CAP, THE NEW SERIES IS REFUSED AND EVERY EXISTING ONE KEEPS
 * WORKING. Eviction would convert a cardinality problem into data loss on
 * whichever series is least recently used - very likely the one somebody has
 * open on a dashboard during the incident that caused the explosion.
 *
 * `rejected` counts refused SERIES, once each (modulo bloom error);
 * `overflow` counts refused RECORDS, every one, because that is the volume
 * the overflow series carries. Races overshoot by at most the worker count -
 * the guard-rail doctrine one field up. What must be exact is that it STOPS. */
static int po_shared_series_admit(po_shared *s, po_u64 id_hi, po_u64 id_lo) {
#if defined(PO_HAVE_ATOMICS) && !defined(_WIN32)
    po_u64 cap, n;
    int cur, prev;
    if (!s->ok || !s->m || !s->m->bloom_words) return 1;   /* no arena: no gate */

    po_shm_maybe_rotate(s->m);
    cur  = (int)(__atomic_load_n(&s->m->gen, __ATOMIC_SEQ_CST) & 1);
    prev = cur ^ 1;

    if (po_shm_bloom_test(s->m, cur, id_hi, id_lo)) return 1;  /* this window */

    /* ADMITTED LAST WINDOW AND STILL ALIVE: it re-registers into the new
     * generation, uncapped. It was under the cap when it was admitted, and
     * refusing an established series because newcomers filled the window
     * first would be the eviction this design refuses, upside down. */
    if (po_shm_bloom_test(s->m, prev, id_hi, id_lo)) {
        po_shm_bloom_set(s->m, cur, id_hi, id_lo);
        po_atomic_add(&s->m->series, 1);
        return 1;
    }

    if (po_shm_bloom_test(s->m, 2, id_hi, id_lo)) {        /* already refused */
        po_atomic_add(&s->m->overflow, 1);
        return 0;
    }

    cap = s->m->series_cap;
    n   = po_atomic_load(&s->m->series);
    if (!cap || n < cap) {
        po_shm_bloom_set(s->m, cur, id_hi, id_lo);
        po_atomic_add(&s->m->series, 1);
        return 1;
    }

    po_shm_bloom_set(s->m, 2, id_hi, id_lo);
    po_atomic_add(&s->m->rejected, 1);
    po_atomic_add(&s->m->overflow, 1);
    return 0;
#else
    (void)s; (void)id_hi; (void)id_lo;
    return 1;
#endif
}

static void po_shared_record(po_shared *s, po_u64 n, po_u64 bytes) {
    if (!s->ok || !s->m) return;
    po_atomic_add(&s->m->records, n);
    po_atomic_add(&s->m->bytes, bytes);
}

/* Is this actually shared? A test asserts a write in one process is visible
 * in another; this is the cheap self-check for the boot diagnostic. */
static int po_shared_is_shared(const po_shared *s) {
#ifdef PO_HAVE_ATOMICS
    return s->ok && s->m && s->m->magic == PO_SHM_MAGIC;
#else
    /* Without atomics the region is shared but the counters are not safe to
     * increment from several processes. Saying so is better than miscounting
     * quietly, and phase 15 refuses a multi-worker configuration on it. */
    return 0;
#endif
}

#endif /* PO_SHARED_H */

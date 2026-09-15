#ifndef SA_HLL_H
#define SA_HLL_H

/* sa_hll.h - how many DISTINCT, in a few kilobytes. Perl-free.
 *
 * ---- the third question --------------------------------------------------
 *
 * The bloom and cuckoo filters answer "have I seen this key?"; the count-min
 * sketch answers "how often?". Neither answers "HOW MANY DIFFERENT ones?" -
 * distinct visitors today, distinct client addresses behind one token, distinct
 * URLs a crawler touched. A map of every key is unbounded, and counting per
 * worker is wrong by construction: one visitor lands on eight workers and is
 * counted eight times.
 *
 * HyperLogLog is the standard answer. Hash each key; the top p bits pick one of
 * m = 2^p registers, and the register keeps the LONGEST run of leading zeros
 * (plus one) ever seen in the rest of the hash. A run of k leading zeros is a
 * 1-in-2^k event, so the longest run seen is a log-scale witness to how many
 * different values have been hashed, and m registers averaged (harmonically)
 * turn a noisy witness into an estimate with a relative error of about
 * 1.04 / sqrt(m): 0.8% at p = 14, which costs 16 kilobytes.
 *
 * ---- why this is the most shared-memory-shaped tenant in the dist -------
 *
 * The write is register[i] = max(register[i], rank). A MAX is commutative and
 * idempotent: it does not matter in what order eight processes apply theirs,
 * nor if one applies the same one twice, and there is no read-modify-write
 * sequence to tear. So an add is a compare-and-swap on one register and takes
 * no lock, no stripe, no seqlock; two processes racing on one register both
 * land on the larger value. Every other tenant has to reason about ordering;
 * this one has nothing to order.
 *
 * Two sketches MERGE the same way, register by register, so a union is cheap
 * and needs no coordination either.
 *
 * ---- the hash ----------------------------------------------------------
 *
 * The arena's FNV-1a is fine for choosing a stripe and useless here: its low
 * bits avalanche poorly, and the rank is the leading zeros of exactly those
 * bits. So the FNV word goes through a 64-bit finaliser (the murmur3 fmix)
 * before it is split, which is cheap and gives every bit a fair coin.
 *
 * ---- the registers are bytes, the atomics are words ----------------------
 *
 * A register never exceeds 64 - p + 1, so a byte holds it and the sketch stays
 * small, which is its whole point. The portable atomics here are 32- and
 * 64-bit, so the max is done as a CAS on the 32-bit word that contains the
 * byte: read the word, if our byte is already >= rank stop, else swap in the
 * word with that byte raised. A neighbour byte changing underneath us fails
 * the CAS and we re-read: the loop converges because every iteration either
 * stops or raises a byte, and bytes only ever go up.
 *
 * Needs sa_arena.h.
 */

#include <math.h>
#include "sa/sa_arena.h"

#define SA_HLL_MAGIC 0x4C4C4C48u    /* 'H','L','L','L' little-endian */

#define SA_HLL_MIN_P 4
#define SA_HLL_MAX_P 18

typedef struct {
    volatile uint32_t magic;      /* published LAST at init                 */
    uint32_t          p;          /* precision: m = 2^p registers           */
    uint64_t          regs_off;   /* from the SKETCH's base                 */
    volatile unsigned char locks[SA_LOCK_STRIPES];   /* init only          */
} sa_hll_hdr;

#ifndef SA_HLL_FWD
#define SA_HLL_FWD
typedef struct sa_hll sa_hll;
#endif

struct sa_hll {
    sa_region   *arena;
    sa_hll_hdr  *hdr;
    volatile uint32_t *words;     /* the registers, as words for the CAS   */
    uint32_t     p;
    uint64_t     m;               /* 2^p                                    */
};

static uint64_t sa_hll_regs_bytes(uint32_t p) {
    return sa_align_up(((uint64_t)1 << p) + 3u) & ~(uint64_t)3u;
}

static uint64_t sa_hll_bytes(uint32_t p) {
    return sa_align_up((uint64_t)sizeof(sa_hll_hdr)) + sa_hll_regs_bytes(p);
}

/* murmur3's 64-bit finaliser: every input bit affects every output bit. */
static uint64_t sa_hll_mix(uint64_t h) {
    h ^= h >> 33;
    h *= 0xff51afd7ed558ccdULL;
    h ^= h >> 33;
    h *= 0xc4ceb9fe1a85ec53ULL;
    h ^= h >> 33;
    return h;
}

static uint64_t sa_hll_hash(const void *key, size_t klen) {
    return sa_hll_mix(sa_at_fnv(key, klen));
}

/* Leading zeros of a 64-bit word, portable; only called with w != 0. */
static uint32_t sa_hll_clz64(uint64_t w) {
    uint32_t n = 0;
    if (!(w & 0xFFFFFFFF00000000ULL)) { n += 32; w <<= 32; }
    if (!(w & 0xFFFF000000000000ULL)) { n += 16; w <<= 16; }
    if (!(w & 0xFF00000000000000ULL)) { n += 8;  w <<= 8;  }
    if (!(w & 0xF000000000000000ULL)) { n += 4;  w <<= 4;  }
    if (!(w & 0xC000000000000000ULL)) { n += 2;  w <<= 2;  }
    if (!(w & 0x8000000000000000ULL)) { n += 1; }
    return n;
}

#if SA_HAVE_ATOMICS

static sa_hll *sa_hll_bind(sa_region *arena, sa_reg *e, uint32_t p, int *err) {
    sa_hll *h;
    sa_hll_hdr *hd;
    uint64_t hash;

    if (err) *err = SA_E_OK;
    if (!arena || !e) { if (err) *err = SA_E_NOENT; return NULL; }

    hd = (sa_hll_hdr *)sa_ptr_len(arena, e->off, sizeof(sa_hll_hdr));
    if (!hd) { if (err) *err = SA_E_NOENT; return NULL; }

    if (sa_at_load32_acq(&hd->magic) != SA_HLL_MAGIC) {
        hash = sa_at_fnv(e->name, strlen(e->name));
        if (sa_at_lock(hd->locks, hash)) {
            if (sa_at_load32_acq(&hd->magic) != SA_HLL_MAGIC) {
                if (p < SA_HLL_MIN_P || p > SA_HLL_MAX_P
                    || sa_hll_bytes(p) > e->len) {
                    sa_at_unlock(hd->locks, hash);
                    if (err) *err = SA_E_FULL;
                    return NULL;
                }
                memset((void *)hd, 0, (size_t)sa_hll_bytes(p));
                hd->p        = p;
                hd->regs_off = sa_align_up((uint64_t)sizeof(sa_hll_hdr));
                sa_at_store32_rel(&hd->magic, SA_HLL_MAGIC);
            }
            sa_at_unlock(hd->locks, hash);
        }
        if (!sa_wait_magic32(&hd->magic, SA_HLL_MAGIC)) {
            if (err) *err = SA_E_MAGIC;
            return NULL;
        }
    }

    /* The precision in the header is somebody else's number: a header claiming
     * p = 60 would put every register read past the mapping. Check it, and a
     * caller that asked for a precision must have asked for THIS one. */
    if (hd->p < SA_HLL_MIN_P || hd->p > SA_HLL_MAX_P
        || sa_hll_bytes(hd->p) > e->len
        || hd->regs_off != sa_align_up((uint64_t)sizeof(sa_hll_hdr))) {
        if (err) *err = SA_E_SHAPE;
        return NULL;
    }
    if (p && hd->p != p) { if (err) *err = SA_E_SHAPE; return NULL; }

    h = (sa_hll *)calloc(1, sizeof(sa_hll));
    if (!h) { if (err) *err = SA_E_NOMEM; return NULL; }
    h->arena = arena;
    h->hdr   = hd;
    h->words = (volatile uint32_t *)((char *)hd + (size_t)hd->regs_off);
    h->p     = hd->p;
    h->m     = (uint64_t)1 << hd->p;
    return h;
}

static void sa_hll_free(sa_hll *h) { free(h); }

/* Raise register `idx` to at least `rank`. Lock-free; see the header comment
 * for why the CAS is on the containing word. Returns 1 if the register moved,
 * 0 if it was already at least that high - which is what a repeated key is. */
static int sa_hll_raise(sa_hll *h, uint64_t idx, uint32_t rank) {
    volatile uint32_t *w = &h->words[idx >> 2];
    uint32_t shift = (uint32_t)(idx & 3u) * 8u;
    for (;;) {
        uint32_t old = sa_at_load32_acq(w);
        uint32_t cur = (old >> shift) & 0xFFu;
        uint32_t neu;
        if (cur >= rank) return 0;
        neu = (old & ~(0xFFu << shift)) | (rank << shift);
        if (sa_at_cas32(w, old, neu)) return 1;
    }
}

/* Add a key. Returns 1 if the sketch changed, 0 if this key (or one that
 * collides with it) had no effect - NOT a membership answer, only a hint. */
static int sa_hll_add(sa_hll *h, const void *key, size_t klen) {
    uint64_t x, idx, rest;
    uint32_t rank;
    if (!h) return 0;
    x    = sa_hll_hash(key, klen);
    idx  = x >> (64 - h->p);
    rest = (x << h->p) | ((uint64_t)1 << (h->p - 1));   /* cap the run   */
    rank = sa_hll_clz64(rest) + 1;
    return sa_hll_raise(h, idx, rank);
}

/* ---- the estimate ----------------------------------------------------------
 *
 * The original paper's estimator is a harmonic mean with two patches: linear
 * counting below 2.5m, and a raw mean above. The seam between them has a hump
 * - measured here, +1% at n = 3m - which HyperLogLog++ flattens with tables of
 * empirically fitted constants per precision.
 *
 * This is Ertl's estimator (2017) instead. It works from the HISTOGRAM of
 * register values, with two closed-form series (sigma for the empty registers,
 * tau for the saturated ones) that account exactly for the ends of the range
 * that bias the harmonic mean, so there is no seam, no switch, and no table.
 * The two loops each converge in a few dozen iterations. */

static double sa_hll_sigma(double x) {
    double y = 1.0, z = x, zp;
    if (x == 1.0) return HUGE_VAL;          /* every register empty: n = 0   */
    do { x *= x; zp = z; z += x * y; y += y; } while (z != zp);
    return z;
}

static double sa_hll_tau(double x) {
    double y = 1.0, z = 1.0 - x, zp;
    if (x == 0.0 || x == 1.0) return 0.0;
    do { x = sqrt(x); zp = z; y *= 0.5; z -= (1.0 - x) * (1.0 - x) * y; }
    while (z != zp);
    return z / 3.0;
}

static double sa_hll_count(sa_hll *h) {
    uint64_t hist[66];               /* a register holds 0 .. 64 - p + 1    */
    uint64_t i;
    uint32_t q, k;
    double m, z;

    if (!h) return 0.0;
    memset(hist, 0, sizeof hist);
    for (i = 0; i < h->m; i++) {
        uint32_t r = (sa_at_load32_acq(&h->words[i >> 2]) >> ((i & 3u) * 8u))
                     & 0xFFu;
        if (r > 65) r = 65;          /* a corrupt byte cannot index past it */
        hist[r]++;
    }
    m = (double)h->m;
    q = 64 - h->p;
    z = m * sa_hll_tau(1.0 - (double)hist[q + 1] / m);
    for (k = q; k >= 1; k--) z = 0.5 * (z + (double)hist[k]);
    z += m * sa_hll_sigma((double)hist[0] / m);
    return m * m / (2.0 * log(2.0) * z);    /* alpha_inf = 1 / (2 ln 2)   */
}

/* Fold `src` into `dst`: register-wise max. Both must share a precision. The
 * result is the sketch of the UNION of everything either saw. Returns 0 on a
 * precision mismatch, 1 otherwise. */
static int sa_hll_merge(sa_hll *dst, sa_hll *src) {
    uint64_t i;
    if (!dst || !src || dst->p != src->p) return 0;
    for (i = 0; i < src->m; i++) {
        uint32_t r = (sa_at_load32_acq(&src->words[i >> 2]) >> ((i & 3u) * 8u))
                     & 0xFFu;
        if (r) sa_hll_raise(dst, i, r);
    }
    return 1;
}

/* Registers set (non-zero), for a caller wondering how full the sketch is. */
static uint64_t sa_hll_filled(sa_hll *h) {
    uint64_t i, n = 0;
    if (!h) return 0;
    for (i = 0; i < h->m; i++) {
        if ((sa_at_load32_acq(&h->words[i >> 2]) >> ((i & 3u) * 8u)) & 0xFFu)
            n++;
    }
    return n;
}

/* Forget everything. An add racing a reset lands either before it (lost) or
 * after (kept); a sketch is a statistic, and a reset is a moment, not a
 * transaction, so that is the honest answer. */
static void sa_hll_reset(sa_hll *h) {
    uint64_t i, nw;
    if (!h) return;
    nw = (h->m + 3u) >> 2;
    for (i = 0; i < nw; i++) sa_at_store32_rel(&h->words[i], 0);
}

#else /* !SA_HAVE_ATOMICS */

/* No atomics: no sketch. Defined for the ABI table; inert. */
static sa_hll *sa_hll_bind(sa_region *arena, sa_reg *e, uint32_t p, int *err) {
    (void)arena; (void)e; (void)p;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
}
static void sa_hll_free(sa_hll *h) { free(h); }
static int sa_hll_add(sa_hll *h, const void *key, size_t klen) {
    (void)h; (void)key; (void)klen; return 0;
}
static double sa_hll_count(sa_hll *h) { (void)h; return 0.0; }
static int sa_hll_merge(sa_hll *dst, sa_hll *src) { (void)dst; (void)src; return 0; }
static uint64_t sa_hll_filled(sa_hll *h) { (void)h; return 0; }
static void sa_hll_reset(sa_hll *h) { (void)h; }

#endif /* SA_HAVE_ATOMICS */

#endif /* SA_HLL_H */

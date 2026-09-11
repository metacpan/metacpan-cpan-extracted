#ifndef SA_HIST_H
#define SA_HIST_H

/* sa_hist.h - a distribution every process adds to at once. Perl-free.
 *
 * Recording a value is one atomic add to one bucket. There is no merge step and
 * no per-process copy: a hundred workers and one worker write the same array,
 * so a percentile over the whole pool is the same question as a percentile over
 * one of them.
 *
 * ---- why not just keep the values ------------------------------------------
 *
 * Because a distribution is wanted continuously and the values are not. Keeping
 * them means memory proportional to traffic and a sort to answer anything;
 * bucketing means fixed memory and an answer that is already there. What it
 * costs is exactness, and the point of the scheme below is that the inexactness
 * is bounded and known rather than whatever the buckets happened to be.
 *
 * ---- log-linear buckets ----------------------------------------------------
 *
 * Plain powers of two would put 512 and 1000 in one bucket, which is useless
 * for latency: those are different answers. Plain linear buckets fine enough
 * for a microsecond would need millions of them to reach a minute.
 *
 * So each power of two is divided into 2^sigbits linear sub-buckets, which is
 * the scheme HDR histograms use. The relative error of any recorded value is at
 * most 1/2^sigbits - about 6% at the default of four significant bits, about
 * 1.5% at six - and it is the SAME at a microsecond and at an hour. Bucket
 * count grows with the logarithm of the range, so a histogram covering one to
 * a billion at 6% costs a few hundred buckets.
 *
 * Values below 2^sigbits are recorded exactly, because at that size the
 * sub-bucket is one unit wide.
 *
 * ---- what a reader gets ----------------------------------------------------
 *
 * A quantile is read while values are still arriving, and no attempt is made to
 * stop that: the answer describes the histogram as it was walked, which for a
 * distribution is the honest thing and for anything else would not be. Count
 * and sum are read the same way, so a mean computed from them can disagree with
 * the buckets by whatever arrived in between.
 *
 * A quantile is reported as the TOP of the bucket it falls in. For a latency
 * budget that is the useful direction to be wrong in: it never claims the
 * service was faster than it was.
 *
 * Needs sa_arena.h.
 */

#include "sa/sa_arena.h"

#define SA_HIST_MAGIC 0x54534948u    /* 'H','I','S','T' little-endian */

#define SA_HIST_MIN_SIG 1
#define SA_HIST_MAX_SIG 8

typedef struct {
    volatile uint32_t magic;      /* published LAST at init                */
    uint32_t          sigbits;
    uint64_t          max_value;
    uint64_t          nbuckets;
    uint64_t          buckets_off;/* from the HISTOGRAM's base             */
    volatile uint64_t count;
    volatile uint64_t sum;
    volatile uint64_t min;        /* CAS-updated; UINT64_MAX when empty    */
    volatile uint64_t max;
    volatile uint64_t over;       /* values above max_value, counted apart */
    volatile unsigned char locks[SA_LOCK_STRIPES];
} sa_hist_hdr;

typedef struct sa_hist {
    sa_region   *arena;
    sa_hist_hdr *hdr;
    volatile uint64_t *buckets;
    uint64_t     nbuckets;
    uint32_t     sigbits;
    uint64_t     max_value;
} sa_hist;

/* The position of the highest set bit. Written out rather than
 * __builtin_clzll, which is not everywhere this claims to build. */
static uint32_t sa_hist_msb(uint64_t v) {
    uint32_t n = 0;
    if (v >> 32) { v >>= 32; n += 32; }
    if (v >> 16) { v >>= 16; n += 16; }
    if (v >> 8)  { v >>= 8;  n += 8;  }
    if (v >> 4)  { v >>= 4;  n += 4;  }
    if (v >> 2)  { v >>= 2;  n += 2;  }
    if (v >> 1)  {           n += 1;  }
    return n;
}

/* Which bucket a value belongs in.
 *
 * Below 2^sigbits the buckets are one unit wide, so the value IS the index and
 * small values are exact. Above it, the index is the power of two and then the
 * top `sigbits` bits of what is left, which is what makes the relative error
 * constant across the whole range. */
static uint64_t sa_hist_index(uint64_t v, uint32_t sigbits) {
    uint64_t sub = 1ULL << sigbits;
    uint32_t msb, shift;

    if (v < sub) return v;
    msb   = sa_hist_msb(v);
    shift = msb - sigbits;
    return (((uint64_t)shift + 1) << sigbits) + ((v >> shift) & (sub - 1));
}

/* The lowest value that lands in this bucket. */
static uint64_t sa_hist_low(uint64_t idx, uint32_t sigbits) {
    uint64_t sub = 1ULL << sigbits;
    uint64_t shift;
    if (idx < sub) return idx;
    shift = (idx >> sigbits) - 1;
    return ((idx & (sub - 1)) | sub) << shift;
}

/* And the highest. A quantile answers with this, so it is never optimistic. */
static uint64_t sa_hist_high(uint64_t idx, uint32_t sigbits) {
    uint64_t sub = 1ULL << sigbits;
    uint64_t shift;
    if (idx < sub) return idx;
    shift = (idx >> sigbits) - 1;
    return sa_hist_low(idx, sigbits) + (1ULL << shift) - 1;
}

static uint64_t sa_hist_buckets_for(uint64_t max_value, uint32_t sigbits) {
    return sa_hist_index(max_value, sigbits) + 1;
}

static uint64_t sa_hist_bytes(uint64_t max_value, uint32_t sigbits) {
    return sa_align_up((uint64_t)sizeof(sa_hist_hdr))
         + sa_hist_buckets_for(max_value, sigbits) * 8u;
}

static sa_hist *sa_hist_bind(sa_region *arena, sa_reg *e,
                             uint64_t max_value, uint32_t sigbits, int *err)
{
#if !SA_HAVE_ATOMICS
    (void)arena; (void)e; (void)max_value; (void)sigbits;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
#else
    sa_hist *hs;
    sa_hist_hdr *h;
    uint64_t hash;

    if (err) *err = SA_E_OK;
    if (!arena || !e) { if (err) *err = SA_E_NOENT; return NULL; }

    h = (sa_hist_hdr *)sa_ptr_len(arena, e->off, sizeof(sa_hist_hdr));
    if (!h) { if (err) *err = SA_E_NOENT; return NULL; }

    if (sa_at_load32_acq(&h->magic) != SA_HIST_MAGIC) {
        hash = sa_at_fnv(e->name, strlen(e->name));
        if (sa_at_lock(h->locks, hash)) {
            if (sa_at_load32_acq(&h->magic) != SA_HIST_MAGIC) {
                if (!max_value || sigbits < SA_HIST_MIN_SIG
                    || sigbits > SA_HIST_MAX_SIG
                    || sa_hist_bytes(max_value, sigbits) > e->len) {
                    sa_at_unlock(h->locks, hash);
                    if (err) *err = SA_E_FULL;
                    return NULL;
                }
                memset((void *)h, 0,
                       (size_t)sa_hist_bytes(max_value, sigbits));
                h->sigbits     = sigbits;
                h->max_value   = max_value;
                h->nbuckets    = sa_hist_buckets_for(max_value, sigbits);
                h->buckets_off = sa_align_up((uint64_t)sizeof(sa_hist_hdr));
                /* Empty, so the smallest thing recorded wins outright. */
                h->min = (uint64_t)-1;
                sa_at_store64_rel(&h->min, (uint64_t)-1);
                sa_at_store32_rel(&h->magic, SA_HIST_MAGIC);
            }
            sa_at_unlock(h->locks, hash);
        }
        if (!sa_wait_magic32(&h->magic, SA_HIST_MAGIC)) {
            if (err) *err = SA_E_MAGIC;
            return NULL;
        }
    }

    /* THE GEOMETRY IN THE HEADER IS ALSO SOMEBODY ELSE'S NUMBER.
     *
     * The branch above only checks a size when this process is the one doing
     * the INITIALISING. A process that finds the magic already set reads the
     * shape out of the shared header and believed it, so a header claiming
     * four billion slots put every later read past the end of the mapping.
     * sa_reg_ok makes `len` trustworthy; this makes the shape trustworthy. */

    if ((max_value && h->max_value != max_value)
        || (sigbits && h->sigbits != sigbits)) {
        if (err) *err = SA_E_NAME;
        return NULL;
    }

    hs = (sa_hist *)calloc(1, sizeof(sa_hist));
    if (!hs) { if (err) *err = SA_E_NOMEM; return NULL; }
    hs->arena     = arena;
    hs->hdr       = h;
    hs->buckets   = (volatile uint64_t *)((char *)h + (size_t)h->buckets_off);
    hs->nbuckets  = h->nbuckets;
    hs->sigbits   = h->sigbits;
    hs->max_value = h->max_value;
    return hs;
#endif
}

static void sa_hist_free(sa_hist *h) { free(h); }

/* Record a value `n` times.
 *
 * A value above the histogram's ceiling is counted in `over` and NOT clamped
 * into the top bucket. Clamping would let a flood of enormous values masquerade
 * as a busy top bucket, and the quantiles would look plausible while being
 * wrong. Counted separately, an overflow is visible for what it is. */
static void sa_hist_record(sa_hist *h, uint64_t v, uint64_t n) {
#if SA_HAVE_ATOMICS
    sa_hist_hdr *hd = h->hdr;

    if (!n) return;
    if (v > h->max_value) {
        sa_at_fetch_add64(&hd->over, n);
        return;
    }
    sa_at_fetch_add64(&h->buckets[sa_hist_index(v, h->sigbits)], n);
    sa_at_fetch_add64(&hd->count, n);
    sa_at_fetch_add64(&hd->sum, v * n);

    /* min and max are compare-and-swap loops rather than adds, and they are
     * bounded by contention rather than spinning for ever: whoever loses the
     * race re-reads and finds the value is no longer smaller. */
    for (;;) {
        uint64_t cur = sa_at_load64_acq(&hd->min);
        if (v >= cur) break;
        if (sa_at_cas64(&hd->min, cur, v)) break;
    }
    for (;;) {
        uint64_t cur = sa_at_load64_acq(&hd->max);
        if (v <= cur) break;
        if (sa_at_cas64(&hd->max, cur, v)) break;
    }
#else
    (void)h; (void)v; (void)n;
#endif
}

/* The value at a quantile, as the TOP of the bucket it falls in.
 *
 * Walked while values are still arriving, which is deliberate: stopping the
 * world to read a distribution would cost more than the answer is worth, and
 * the answer is a description of a moving thing anyway. */
static uint64_t sa_hist_quantile(sa_hist *h, double q) {
#if SA_HAVE_ATOMICS
    uint64_t total = sa_at_load64_acq(&h->hdr->count);
    uint64_t want, seen = 0, i;

    if (!total) return 0;
    if (q <= 0.0) return sa_at_load64_acq(&h->hdr->min);
    if (q >= 1.0) return sa_at_load64_acq(&h->hdr->max);

    want = (uint64_t)((double)total * q + 0.5);
    if (want < 1) want = 1;

    for (i = 0; i < h->nbuckets; i++) {
        seen += sa_at_load64_acq(&h->buckets[i]);
        if (seen >= want) return sa_hist_high(i, h->sigbits);
    }
    return sa_at_load64_acq(&h->hdr->max);
#else
    (void)h; (void)q;
    return 0;
#endif
}

static void sa_hist_reset(sa_hist *h) {
#if SA_HAVE_ATOMICS
    uint64_t hash = (uint64_t)(uintptr_t)h->hdr;
    uint64_t i;
    if (!sa_at_lock(h->hdr->locks, hash)) return;
    for (i = 0; i < h->nbuckets; i++) sa_at_store64_rel(&h->buckets[i], 0);
    sa_at_store64_rel(&h->hdr->count, 0);
    sa_at_store64_rel(&h->hdr->sum, 0);
    sa_at_store64_rel(&h->hdr->over, 0);
    sa_at_store64_rel(&h->hdr->max, 0);
    sa_at_store64_rel(&h->hdr->min, (uint64_t)-1);
    sa_at_unlock(h->hdr->locks, hash);
#else
    (void)h;
#endif
}

#endif /* SA_HIST_H */

#ifndef SA_BLOOM_H
#define SA_BLOOM_H

/* sa_bloom.h - a set that answers "no" exactly and "yes" probably. Perl-free.
 *
 * A bit array and k hash functions. Adding a key sets k bits; asking about a
 * key tests them. If any is clear the key was definitely never added; if all
 * are set it probably was, and the probability is a number you chose when you
 * sized the filter.
 *
 * ---- why this fits an arena so well ----------------------------------------
 *
 * There is nothing to allocate after the first moment, nothing to free ever,
 * and no way for two processes to disagree about a write: setting a bit is one
 * atomic OR, and two processes setting the same bit both simply set it. It is
 * the only structure here that needs no lock at all, on either side.
 *
 * ---- what it cannot do -----------------------------------------------------
 *
 * NO DELETION. Clearing a bit would clear it for every other key that happens
 * to share it, turning a definite "no" into a wrong one. A filter only fills
 * up; when it is too full, it is replaced.
 *
 * NO COUNT. `estimated_items` is arithmetic on how many bits are set, and it is
 * an estimate that gets worse as the filter saturates.
 *
 * ---- sizing ----------------------------------------------------------------
 *
 * From an expected item count n and an acceptable false-positive rate p, the
 * standard result gives the bits m and the hash count k:
 *
 *     m = -n ln p / (ln 2)^2      k = (m/n) ln 2
 *
 * A filter sized for a million items at one percent needs about 1.2 MB and
 * seven hash probes. Ask for what you expect, not for bits.
 *
 * The rate is what you get AT that item count. Past it the rate climbs, and it
 * climbs quickly, which is why the fill is in the stats and why a caller that
 * cares rotates rather than hoping.
 *
 * ---- two hashes, not k -----------------------------------------------------
 *
 * Computing k independent hashes of every key would be k times the work for no
 * benefit: Kirsch and Mitzenmacher showed that h1 + i*h2 gives the same false
 * positive rate as k independent functions. So there are two, and the rest is
 * arithmetic. h2 is forced odd so the probe sequence cannot get stuck on a
 * subset of the array.
 *
 * Needs sa_arena.h.
 */

#include "sa/sa_arena.h"

#ifndef SA_NO_LIBM
#  include <math.h>
#endif

#define SA_BLOOM_MAGIC 0x4D4F4C42u    /* 'B','L','O','M' little-endian */

#define SA_BLOOM_MAX_K 32

typedef struct {
    volatile uint32_t magic;      /* published LAST at init                */
    uint32_t          nhash;      /* k                                      */
    uint64_t          nbits;      /* m, a multiple of 64                    */
    uint64_t          bits_off;   /* from the FILTER's base                 */
    uint64_t          capacity;   /* the n it was sized for                 */
    volatile uint64_t added;      /* add() calls that set at least one bit  */
    volatile uint64_t seen;       /* add() calls that found every bit set   */
    volatile unsigned char locks[SA_LOCK_STRIPES];
} sa_bloom_hdr;

typedef struct sa_bloom {
    sa_region     *arena;
    sa_bloom_hdr  *hdr;
    volatile uint64_t *words;
    uint64_t       nbits;
    uint64_t       nwords;
    uint32_t       nhash;
} sa_bloom;

/* Round the bits up to a whole number of 64-bit words. */
static uint64_t sa_bloom_words(uint64_t nbits) {
    return (nbits + 63u) / 64u;
}

static uint64_t sa_bloom_bytes(uint64_t nbits) {
    return sa_align_up((uint64_t)sizeof(sa_bloom_hdr))
         + sa_bloom_words(nbits) * 8u;
}

/* The bits and hash count for n items at a false-positive rate p.
 *
 * Falls back to eight bits per item and five hashes where there is no libm,
 * which is roughly p = 0.02 - a working filter rather than none at all, and the
 * build says so at configure time. */
static void sa_bloom_size(uint64_t n, double p, uint64_t *nbits, uint32_t *k) {
    uint64_t m;
    uint32_t kk;

    if (n < 1) n = 1;
#ifdef SA_NO_LIBM
    (void)p;
    m  = n * 8u;
    kk = 5;
#else
    if (!(p > 0.0) || p >= 1.0) p = 0.01;
    {
        double ln2 = 0.6931471805599453;
        double md  = -((double)n) * log(p) / (ln2 * ln2);
        if (md < 64.0) md = 64.0;
        m  = (uint64_t)(md + 0.5);
        kk = (uint32_t)((md / (double)n) * ln2 + 0.5);
    }
#endif
    if (kk < 1) kk = 1;
    if (kk > SA_BLOOM_MAX_K) kk = SA_BLOOM_MAX_K;
    m = sa_bloom_words(m) * 64u;      /* whole words */
    if (nbits) *nbits = m;
    if (k)     *k     = kk;
}

/* The second hash. A finalising mix rather than a second pass over the key: the
 * key has already been read once and reading it again to get an independent
 * value is the cost this avoids. */
static uint64_t sa_bloom_mix(uint64_t h) {
    h ^= h >> 33;
    h *= 0xff51afd7ed558ccdULL;
    h ^= h >> 33;
    h *= 0xc4ceb9fe1a85ec53ULL;
    h ^= h >> 33;
    return h;
}

static sa_bloom *sa_bloom_bind(sa_region *arena, sa_reg *e,
                               uint64_t nbits, uint32_t nhash, int *err)
{
#if !SA_HAVE_ATOMICS
    (void)arena; (void)e; (void)nbits; (void)nhash;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
#else
    sa_bloom *b;
    sa_bloom_hdr *h;
    uint64_t hash;

    if (err) *err = SA_E_OK;
    if (!arena || !e) { if (err) *err = SA_E_NOENT; return NULL; }

    h = (sa_bloom_hdr *)sa_ptr_len(arena, e->off, sizeof(sa_bloom_hdr));
    if (!h) { if (err) *err = SA_E_NOENT; return NULL; }

    if (sa_at_load32_acq(&h->magic) != SA_BLOOM_MAGIC) {
        hash = sa_at_fnv(e->name, strlen(e->name));
        if (sa_at_lock(h->locks, hash)) {
            if (sa_at_load32_acq(&h->magic) != SA_BLOOM_MAGIC) {
                if (!nbits || !nhash || sa_bloom_bytes(nbits) > e->len) {
                    sa_at_unlock(h->locks, hash);
                    if (err) *err = SA_E_FULL;
                    return NULL;
                }
                memset((void *)h, 0, (size_t)sa_bloom_bytes(nbits));
                h->nbits    = nbits;
                h->nhash    = nhash;
                h->bits_off = sa_align_up((uint64_t)sizeof(sa_bloom_hdr));
                sa_at_store32_rel(&h->magic, SA_BLOOM_MAGIC);
            }
            sa_at_unlock(h->locks, hash);
        }
        if (!sa_wait_magic32(&h->magic, SA_BLOOM_MAGIC)) {
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

    if ((nbits && h->nbits != nbits) || (nhash && h->nhash != nhash)) {
        if (err) *err = SA_E_NAME;
        return NULL;
    }

    b = (sa_bloom *)calloc(1, sizeof(sa_bloom));
    if (!b) { if (err) *err = SA_E_NOMEM; return NULL; }
    b->arena  = arena;
    b->hdr    = h;
    b->words  = (volatile uint64_t *)((char *)h + (size_t)h->bits_off);
    b->nbits  = h->nbits;
    b->nwords = sa_bloom_words(h->nbits);
    b->nhash  = h->nhash;
    return b;
#endif
}

static void sa_bloom_free(sa_bloom *b) { free(b); }

/* Add a key. Returns 1 when every bit was ALREADY set - meaning the key had
 * probably been added before - and 0 when this call set at least one.
 *
 * THAT ANSWER IS PER BIT, NOT PER KEY. Two processes adding the same key at the
 * same instant can both be told it was new, because each set some of the bits
 * the other was about to set. For a filter that is harmless; for a caller using
 * this to do a job exactly once it is not, and that caller wants a lock or a
 * compare-and-set, not a bloom filter. */
static int sa_bloom_add(sa_bloom *b, const char *key, uint32_t klen) {
#if !SA_HAVE_ATOMICS
    (void)b; (void)key; (void)klen;
    return 0;
#else
    uint64_t h1 = sa_at_fnv(key, klen);
    uint64_t h2 = sa_bloom_mix(h1) | 1u;   /* odd, so the walk covers */
    uint32_t i;
    int all_set = 1;

    for (i = 0; i < b->nhash; i++) {
        uint64_t bit  = (h1 + (uint64_t)i * h2) % b->nbits;
        uint64_t mask = 1ULL << (bit & 63u);
        uint64_t was  = sa_at_fetch_or64(&b->words[bit >> 6], mask);
        if (!(was & mask)) all_set = 0;
    }

    if (all_set) sa_at_fetch_add64(&b->hdr->seen, 1);
    else         sa_at_fetch_add64(&b->hdr->added, 1);
    return all_set;
#endif
}

/* Has this key probably been added? A 0 is exact; a 1 may be a coincidence. */
static int sa_bloom_check(sa_bloom *b, const char *key, uint32_t klen) {
#if !SA_HAVE_ATOMICS
    (void)b; (void)key; (void)klen;
    return 0;
#else
    uint64_t h1 = sa_at_fnv(key, klen);
    uint64_t h2 = sa_bloom_mix(h1) | 1u;
    uint32_t i;

    for (i = 0; i < b->nhash; i++) {
        uint64_t bit  = (h1 + (uint64_t)i * h2) % b->nbits;
        uint64_t mask = 1ULL << (bit & 63u);
        /* One clear bit is a definite no, and there is no point reading the
         * rest. A miss is the common case in every use this has. */
        if (!(sa_at_load64_acq(&b->words[bit >> 6]) & mask)) return 0;
    }
    return 1;
#endif
}

/* How many bits are set. O(m/64), so it is a question for a status page rather
 * than for a request path. */
static uint64_t sa_bloom_popcount(sa_bloom *b) {
#if !SA_HAVE_ATOMICS
    (void)b;
    return 0;
#else
    uint64_t i, n = 0;
    for (i = 0; i < b->nwords; i++) {
        uint64_t w = sa_at_load64_acq(&b->words[i]);
        /* The SWAR popcount rather than a builtin: __builtin_popcountll is not
         * everywhere, and this is a status query, not a hot path. */
        w = w - ((w >> 1) & 0x5555555555555555ULL);
        w = (w & 0x3333333333333333ULL) + ((w >> 2) & 0x3333333333333333ULL);
        w = (w + (w >> 4)) & 0x0f0f0f0f0f0f0f0fULL;
        n += (w * 0x0101010101010101ULL) >> 56;
    }
    return n;
#endif
}

/* Forget everything.
 *
 * Under the lock, but readers do not take it: a check running concurrently may
 * see some words cleared and some not, and answer either way for a key that is
 * being forgotten. That is exactly what it would have answered a moment either
 * side, so there is nothing to protect it from - but it is the reason this is
 * `reset` and not a transaction. */
static void sa_bloom_reset(sa_bloom *b) {
#if SA_HAVE_ATOMICS
    uint64_t hash = (uint64_t)(uintptr_t)b->hdr;
    uint64_t i;
    if (!sa_at_lock(b->hdr->locks, hash)) return;
    for (i = 0; i < b->nwords; i++) sa_at_store64_rel(&b->words[i], 0);
    sa_at_store64_rel(&b->hdr->added, 0);
    sa_at_store64_rel(&b->hdr->seen, 0);
    sa_at_unlock(b->hdr->locks, hash);
#else
    (void)b;
#endif
}

/* How many distinct keys the set bits suggest. An estimate, and one that gets
 * worse as the filter fills:  n* = -(m/k) ln(1 - X/m). */
static uint64_t sa_bloom_estimate(sa_bloom *b) {
#if defined(SA_NO_LIBM) || !SA_HAVE_ATOMICS
    return sa_bloom_popcount(b) / (b->nhash ? b->nhash : 1);
#else
    uint64_t set = sa_bloom_popcount(b);
    double m = (double)b->nbits, k = (double)b->nhash;
    if (set == 0) return 0;
    if ((double)set >= m) return (uint64_t)-1;    /* saturated */
    return (uint64_t)(-(m / k) * log(1.0 - (double)set / m) + 0.5);
#endif
}

#endif /* SA_BLOOM_H */

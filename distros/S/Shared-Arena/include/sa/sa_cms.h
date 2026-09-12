#ifndef SA_CMS_H
#define SA_CMS_H

/* sa_cms.h - a count-min sketch: how often, in fixed space. Perl-free.
 *
 * ---- the question the other tenants do not answer ---------------------------
 *
 * The bloom filter answers "have I seen this key". The histogram answers "what
 * does the distribution of these numbers look like". Neither answers B<how many
 * times have I seen THIS key>, and that is the question behind every piece of
 * abuse detection: which client is hammering the gateway, which query is being
 * repeated, which key deserves a limit that the others do not.
 *
 * A map would answer it exactly and needs a slot per key. Key cardinality is
 * the one thing an abuse detector cannot bound - the whole problem is that
 * somebody is generating keys - so the exact structure is the one that falls
 * over first.
 *
 * A sketch does not store keys at all. d rows of w counters, each key hashed to
 * one counter per row, every add incrementing all d. The estimate is the
 * SMALLEST of them, because collisions can only ever have added.
 *
 * ---- it overestimates, and it never underestimates ---------------------------
 *
 * That asymmetry is the whole contract, and it is the right way round. A count
 * that can only be too high never MISSES a heavy hitter; it can only accuse a
 * light key of being heavier than it is, and how often it does that is the
 * number you chose when you sized it.
 *
 * With w = e/epsilon and d = ln(1/delta), the estimate exceeds the truth by
 * more than epsilon * N with probability at most delta, where N is the total
 * of everything added. Note what the error is relative to: not the key's own
 * count, but the WHOLE. A sketch sized for one percent on a stream of a million
 * is accurate to ten thousand, which is useless for a key seen twice and
 * exactly right for finding the one seen half a million times.
 *
 * So `total` is in the header and in the stats. An estimate quoted without it
 * is a number with no error bar.
 *
 * ---- why NOT conservative update --------------------------------------------
 *
 * The well-known improvement is to increment only those counters that are at
 * the current minimum, which cuts overestimation substantially. It is refused
 * here, and the reason is this dist rather than the algorithm.
 *
 * Conservative update is read-then-write: read all d, work out the minimum,
 * write back some of them. Two processes doing that at once can each decide a
 * counter needs no increment because the other's is not visible yet, and the
 * counter then ends up short. A sketch that can UNDERESTIMATE has lost the only
 * guarantee it offers - a heavy hitter can hide - and it fails silently,
 * because a low answer looks exactly like a quiet key.
 *
 * A plain increment is one fetch-add per row, needs no lock, cannot be lost,
 * and cannot be corrupted by a process dying between two of them: the worst a
 * crash leaves behind is a key counted in some rows and not others, which reads
 * as a slightly LOWER estimate on a structure that was going to be high anyway.
 *
 * ---- what it cannot do -------------------------------------------------------
 *
 * IT CANNOT LIST ANYTHING. A sketch holds no keys, so it can answer about a key
 * you name and can never tell you which keys exist. "The top ten" is a
 * different structure: a candidate set beside the sketch, which is a Map of the
 * keys currently believed to be heavy, consulted and updated when a key's
 * estimate crosses the smallest of them.
 *
 * IT CANNOT DECREMENT. Subtracting breaks the min estimate the same way
 * conservative update does, and for the same reason. A sketch is reset, or
 * rotated, not decremented.
 *
 * Needs sa_arena.h.
 */

#include "sa/sa_arena.h"

#ifndef SA_NO_LIBM
#  include <math.h>
#endif

#define SA_CMS_MAGIC 0x534D4353u     /* 'S','C','M','S' little-endian */

#define SA_CMS_MAX_ROWS 32

typedef struct {
    volatile uint32_t magic;      /* published LAST at init                  */
    uint32_t          rows;       /* d                                       */
    uint64_t          width;      /* w, a power of two                       */
    uint64_t          cells_off;  /* from the SKETCH's base                  */
    volatile uint64_t total;      /* everything ever added, for the error bar */
    volatile uint64_t adds;       /* add() calls                             */
    volatile unsigned char locks[SA_LOCK_STRIPES];
} sa_cms_hdr;

#ifndef SA_CMS_FWD
#define SA_CMS_FWD
typedef struct sa_cms sa_cms;
#endif

struct sa_cms {
    sa_region  *arena;
    sa_cms_hdr *hdr;
    volatile uint64_t *cells;
    uint32_t    rows;
    uint64_t    width;
    uint64_t    mask;
};

/* Sixty-four bit counters, not thirty-two.
 *
 * A sketch counts a stream, and a stream on a busy gateway passes four billion
 * in a day. A 32-bit counter would need saturating arithmetic to avoid wrapping
 * to nearly zero - which is an underestimate, the one thing this structure
 * promises never to produce - and saturating means a compare-and-swap loop
 * rather than a fetch-add. Eight bytes a cell buys a plain atomic increment and
 * a counter nobody has to think about. */
static uint64_t sa_cms_bytes(uint32_t rows, uint64_t width) {
    return sa_align_up((uint64_t)sizeof(sa_cms_hdr))
         + (uint64_t)rows * width * 8u;
}

static uint64_t sa_cms_pow2(uint64_t n) {
    uint64_t p = 64;
    if (n < 64) return 64;
    while (p < n && p < (uint64_t)1 << 40) p <<= 1;
    return p;
}

/* Rows and width from the two numbers a caller actually has: how much error it
 * will accept as a fraction of the total, and how sure it wants to be.
 *
 *     w = e / epsilon        d = ln(1 / delta)
 *
 * The width is rounded UP to a power of two, so the row index is a mask rather
 * than a division on a path that runs per row per add. Rounding up only reduces
 * epsilon, so the caller gets at least the accuracy it asked for. */
static void sa_cms_size(double epsilon, double confidence,
                        uint32_t *rows, uint64_t *width)
{
    uint64_t w;
    uint32_t d;

#ifdef SA_NO_LIBM
    (void)confidence;
    if (!(epsilon > 0.0) || epsilon >= 1.0) epsilon = 0.01;
    w = (uint64_t)(2.718281828459045 / epsilon + 0.5);
    d = 5;                       /* delta about 0.007 */
#else
    double delta;
    if (!(epsilon > 0.0) || epsilon >= 1.0) epsilon = 0.01;
    if (!(confidence > 0.0) || confidence >= 1.0) confidence = 0.99;
    delta = 1.0 - confidence;
    w = (uint64_t)(2.718281828459045 / epsilon + 0.5);
    {
        double dd = -log(delta);
        if (dd < 1.0) dd = 1.0;
        d = (uint32_t)(dd + 0.999);
    }
#endif
    if (d < 1) d = 1;
    if (d > SA_CMS_MAX_ROWS) d = SA_CMS_MAX_ROWS;
    w = sa_cms_pow2(w);
    if (rows)  *rows  = d;
    if (width) *width = w;
}

/* The second hash. A finalising mix rather than a second pass over the key: the
 * key has been read once already, and reading it again to get an independent
 * value is the cost this avoids. Kirsch and Mitzenmacher: h1 + i*h2 has the
 * same behaviour as d independent functions. */
static uint64_t sa_cms_mix(uint64_t h) {
    h ^= h >> 33;
    h *= 0xff51afd7ed558ccdULL;
    h ^= h >> 33;
    h *= 0xc4ceb9fe1a85ec53ULL;
    h ^= h >> 33;
    return h;
}

static sa_cms *sa_cms_bind(sa_region *arena, sa_reg *e, uint32_t rows,
                           uint64_t width, int *err)
{
#if !SA_HAVE_ATOMICS
    (void)arena; (void)e; (void)rows; (void)width;
    if (err) *err = SA_E_NOATOMICS;
    return NULL;
#else
    sa_cms *s;
    sa_cms_hdr *h;
    uint64_t hash;

    if (err) *err = SA_E_OK;
    if (!arena || !e) { if (err) *err = SA_E_NOENT; return NULL; }

    h = (sa_cms_hdr *)sa_ptr_len(arena, e->off, sizeof(sa_cms_hdr));
    if (!h) { if (err) *err = SA_E_NOENT; return NULL; }

    if (sa_at_load32_acq(&h->magic) != SA_CMS_MAGIC) {
        hash = sa_at_fnv(e->name, strlen(e->name));
        if (sa_at_lock(h->locks, hash)) {
            if (sa_at_load32_acq(&h->magic) != SA_CMS_MAGIC) {
                if (!rows || !width || sa_cms_bytes(rows, width) > e->len) {
                    sa_at_unlock(h->locks, hash);
                    if (err) *err = SA_E_FULL;
                    return NULL;
                }
                memset((void *)h, 0, (size_t)sa_cms_bytes(rows, width));
                h->rows      = rows;
                h->width     = width;
                h->cells_off = sa_align_up((uint64_t)sizeof(sa_cms_hdr));
                sa_at_store32_rel(&h->magic, SA_CMS_MAGIC);
            }
            sa_at_unlock(h->locks, hash);
        }
        if (!sa_wait_magic32(&h->magic, SA_CMS_MAGIC)) {
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

    if ((rows && h->rows != rows) || (width && h->width != width)) {
        if (err) *err = SA_E_SHAPE;
        return NULL;
    }

    s = (sa_cms *)calloc(1, sizeof(sa_cms));
    if (!s) { if (err) *err = SA_E_NOMEM; return NULL; }
    s->arena = arena;
    s->hdr   = h;
    s->cells = (volatile uint64_t *)((char *)h + (size_t)h->cells_off);
    s->rows  = h->rows;
    s->width = h->width;
    s->mask  = h->width - 1;
    return s;
#endif
}

static void sa_cms_free(sa_cms *s) { free(s); }

#if SA_HAVE_ATOMICS

/* Add `n` to a key, and return what the sketch now believes its count to be.
 *
 * The answer is the minimum ACROSS THE ROWS AFTER THIS ADD, which is what a
 * caller asking "has this key just crossed my threshold" wants, and it costs
 * nothing extra: the values are already in hand.
 *
 * One fetch-add per row, no lock, and nothing to undo. A process that dies part
 * way through has counted its key in some rows and not others, which reads back
 * as a slightly lower estimate - never a corrupt one. */
static uint64_t sa_cms_add(sa_cms *s, const char *key, uint32_t klen,
                           uint64_t n)
{
    uint64_t h1, h2, min = 0;
    uint32_t i;

    if (!s || !n) return 0;
    h1 = sa_at_fnv(key, (size_t)klen);
    h2 = sa_cms_mix(h1) | 1u;      /* odd, so the rows cannot coincide */

    for (i = 0; i < s->rows; i++) {
        uint64_t idx = (h1 + (uint64_t)i * h2) & s->mask;
        volatile uint64_t *c = &s->cells[(uint64_t)i * s->width + idx];
        uint64_t was = sa_at_fetch_add64(c, n);
        if (i == 0 || was + n < min) min = was + n;
    }

    sa_at_fetch_add64(&s->hdr->total, n);
    sa_at_fetch_add64(&s->hdr->adds, 1);
    return min;
}

/* What the sketch believes, without adding to it. At most epsilon * total too
 * high, with the confidence it was sized for, and never too low. */
static uint64_t sa_cms_estimate(sa_cms *s, const char *key, uint32_t klen) {
    uint64_t h1, h2, min = 0;
    uint32_t i;

    if (!s) return 0;
    h1 = sa_at_fnv(key, (size_t)klen);
    h2 = sa_cms_mix(h1) | 1u;

    for (i = 0; i < s->rows; i++) {
        uint64_t idx = (h1 + (uint64_t)i * h2) & s->mask;
        uint64_t v = sa_at_load64_acq(&s->cells[(uint64_t)i * s->width + idx]);
        if (i == 0 || v < min) min = v;
    }
    return min;
}

/* Forget everything.
 *
 * Readers are not locked out, so a count running at the same moment may see the
 * sketch half cleared and answer low for a key being forgotten - which is the
 * one direction this structure otherwise never goes. It is the price of a reset
 * that does not stop the world, and a caller rotating two sketches rather than
 * clearing one never pays it. */
static void sa_cms_reset(sa_cms *s) {
    uint64_t i, n;
    if (!s) return;
    n = (uint64_t)s->rows * s->width;
    for (i = 0; i < n; i++) sa_at_store64_rel(&s->cells[i], 0);
    sa_at_store64_rel(&s->hdr->total, 0);
    sa_at_store64_rel(&s->hdr->adds, 0);
}

/* The absolute error bound at the current total: an estimate may be this much
 * too high, and no more, with the confidence the sketch was sized for.
 *
 * epsilon is e/w, so this is arithmetic on the shape rather than a number
 * anybody has to remember. */
static uint64_t sa_cms_error(sa_cms *s) {
    if (!s || !s->width) return 0;
    return (uint64_t)((2.718281828459045 / (double)s->width)
                      * (double)sa_at_load64_acq(&s->hdr->total));
}

#else /* !SA_HAVE_ATOMICS */

/* No atomics, so no sketch: sa_cms_bind refuses. These answer the way the XSUBs
 * do in that build, nothing counted and nothing estimated, so that the op doors
 * and the ABI table have something to point at. */
static uint64_t sa_cms_add(sa_cms *s, const char *key, uint32_t klen,
                           uint64_t n)
{
    (void)s; (void)key; (void)klen; (void)n;
    return 0;
}

static uint64_t sa_cms_estimate(sa_cms *s, const char *key, uint32_t klen) {
    (void)s; (void)key; (void)klen;
    return 0;
}

static void sa_cms_reset(sa_cms *s) { (void)s; }

static uint64_t sa_cms_error(sa_cms *s) { (void)s; return 0; }

#endif /* SA_HAVE_ATOMICS */

#endif /* SA_CMS_H */

/* otel_expo.h - the Base2 exponential bucket histogram.
 *
 * The intricate one, and the only place in this dist where being slightly
 * wrong produces a plausible-looking number rather than an obvious failure.
 *
 * THE IDEA. Bucket boundaries are powers of a base derived from a `scale`:
 *
 *     base = 2 ** (2 ** -scale)
 *
 * so a value lands in bucket index ceil(log_base(value)). Higher scale means
 * finer buckets. Because the boundaries are relative rather than absolute,
 * one configuration covers nanoseconds and hours at the same relative
 * accuracy - which is the entire reason to prefer this over fixed buckets
 * somebody has to guess in advance.
 *
 * TWO MAPPINGS, and both are needed.
 *
 *   scale <= 0: the bucket is decided by the EXPONENT alone, so the mapping
 *               is a shift of the IEEE-754 exponent field. No logarithm, no
 *               floating point error, and fast - which matters, because this
 *               runs per measurement.
 *   scale >  0: a logarithm is unavoidable.
 *
 * AUTO-SCALING. When the populated range outgrows max_size (160 by default)
 * the scale is REDUCED and adjacent buckets merged pairwise. That merge must
 * be exact: a downscale that loses a count is a silently wrong percentile,
 * which is the worst kind of wrong a histogram can be - it looks like data.
 *
 * ZERO, SUBNORMALS, NaN, INFINITY. Zero has its own count (it has no
 * logarithm). NaN is dropped: it is not a measurement. Infinity is dropped
 * for the same reason. Negative values go in the negative range, which exists
 * for instruments that can legitimately record them.
 */

#ifndef OTEL_EXPO_H
#define OTEL_EXPO_H

#include <math.h>

#define OTEL_EXPO_MAX_SIZE   160
#define OTEL_EXPO_MAX_SCALE   20
#define OTEL_EXPO_MIN_SCALE  -10

/* One side (positive or negative) of the histogram: a dense window of bucket
 * counts, with `offset` naming the index of the first. */
typedef struct {
    int   offset;
    int   len;                       /* populated width */
    IV    counts[OTEL_EXPO_MAX_SIZE];
} otel_expo_side;

typedef struct {
    int    scale;
    IV     count;                    /* every recorded value, including zeros */
    double sum, min, max;
    IV     zero_count;
    double zero_threshold;
    otel_expo_side pos, neg;
} otel_expo;

static void otel_expo_init(otel_expo *h, int scale) {
    Zero(h, 1, otel_expo);
    h->scale = scale;
    h->min   =  1.0 / 0.0;           /* +inf, so the first value wins */
    h->max   = -1.0 / 0.0;
    h->pos.offset = h->neg.offset = 0;
}

/* The bucket index for a positive value at a given scale.
 *
 * For scale <= 0 this is exponent arithmetic: frexp gives the base-2 exponent
 * directly, and the bucket is that exponent shifted right by -scale. No
 * logarithm is involved, which is both faster and free of the rounding that
 * makes a value near a boundary land in the wrong bucket.
 *
 * For scale > 0 a logarithm is unavoidable. */
static int otel_expo_index(double v, int scale) {
    if (scale <= 0) {
        int exp2v;
        double frac = frexp(v, &exp2v);
        /* frexp returns [0.5,1), so a value that IS a power of two reports
         * one exponent too high; the boundary is inclusive at the top, so
         * step it back down */
        if (frac == 0.5) exp2v--;
        return (exp2v - 1) >> (-scale);
    }
    {
        double scale_factor = ldexp(1.0 / log(2.0), scale);
        return (int)ceil(log(v) * scale_factor) - 1;
    }
}

/* Halve the resolution of one side: bucket i and i+1 become one.
 *
 * The pairing is over the INDEX SPACE, not the array, which is why the new
 * offset is the old offset arithmetically shifted rather than divided - an
 * offset can be negative, and C division truncates toward zero while the
 * bucket mapping floors. Getting that wrong shifts every bucket by one at
 * negative offsets, which silently reports the wrong percentile. */
static void otel_expo_downscale_side(otel_expo_side *s, int by) {
    IV merged[OTEL_EXPO_MAX_SIZE];
    int i, new_off, new_len;
    if (s->len <= 0 || by <= 0) {
        if (s->len <= 0) s->offset >>= by;
        return;
    }
    new_off = s->offset >> by;                       /* arithmetic shift */
    Zero(merged, OTEL_EXPO_MAX_SIZE, IV);
    new_len = 0;
    for (i = 0; i < s->len; i++) {
        int idx = (s->offset + i) >> by;
        int slot = idx - new_off;
        if (slot < 0 || slot >= OTEL_EXPO_MAX_SIZE) continue;  /* unreachable */
        merged[slot] += s->counts[i];
        if (slot + 1 > new_len) new_len = slot + 1;
    }
    Copy(merged, s->counts, OTEL_EXPO_MAX_SIZE, IV);
    s->offset = new_off;
    s->len    = new_len;
}

static void otel_expo_downscale(otel_expo *h, int by) {
    if (by <= 0) return;
    otel_expo_downscale_side(&h->pos, by);
    otel_expo_downscale_side(&h->neg, by);
    h->scale -= by;
}

/* How much to downscale so that `idx` fits alongside what is already there. */
static int otel_expo_needed(const otel_expo_side *s, int idx) {
    int lo, hi, by = 0;
    if (s->len <= 0) return 0;
    lo = s->offset;
    hi = s->offset + s->len - 1;
    if (idx < lo) lo = idx;
    if (idx > hi) hi = idx;
    while ((hi - lo + 1) > OTEL_EXPO_MAX_SIZE) {
        lo >>= 1;
        hi >>= 1;
        by++;
    }
    return by;
}

static void otel_expo_side_add(otel_expo_side *s, int idx, IV n) {
    int i;
    if (s->len <= 0) {
        s->offset = idx;
        s->len = 1;
        Zero(s->counts, OTEL_EXPO_MAX_SIZE, IV);
        s->counts[0] = n;
        return;
    }
    if (idx < s->offset) {
        int shift = s->offset - idx;
        if (s->len + shift > OTEL_EXPO_MAX_SIZE) return;   /* caller rescaled */
        for (i = s->len - 1; i >= 0; i--) s->counts[i + shift] = s->counts[i];
        for (i = 0; i < shift; i++) s->counts[i] = 0;
        s->offset = idx;
        s->len += shift;
    }
    else if (idx >= s->offset + s->len) {
        int want = idx - s->offset + 1;
        if (want > OTEL_EXPO_MAX_SIZE) return;
        for (i = s->len; i < want; i++) s->counts[i] = 0;
        s->len = want;
    }
    s->counts[idx - s->offset] += n;
}

/* Record one value. */
static void otel_expo_record(otel_expo *h, double v) {
    otel_expo_side *side;
    double av;
    int idx, by;

    if (v != v) return;                       /* NaN is not a measurement */
    if (v ==  1.0 / 0.0 || v == -1.0 / 0.0) return;   /* nor is infinity */

    h->count++;
    h->sum += v;
    if (v < h->min) h->min = v;
    if (v > h->max) h->max = v;

    av = v < 0 ? -v : v;
    if (av <= h->zero_threshold || av == 0.0) { h->zero_count++; return; }

    side = v < 0 ? &h->neg : &h->pos;
    idx  = otel_expo_index(av, h->scale);
    by   = otel_expo_needed(side, idx);
    if (by > 0) {
        otel_expo_downscale(h, by);
        idx = otel_expo_index(av, h->scale);
    }
    otel_expo_side_add(side, idx, 1);
}

/* Merge `src` into `dst`, downscaling the finer one first.
 *
 * This is where delta-to-cumulative conversion lives, and it is the operation
 * most likely to lose a count if the two scales are handled carelessly. */
static void otel_expo_merge(otel_expo *dst, const otel_expo *src) {
    otel_expo tmp;
    const otel_expo *s = src;
    int i;
    if (src->count == 0) return;
    if (dst->count == 0 && dst->pos.len == 0 && dst->neg.len == 0) {
        int keep_thresh = 0;
        double th = dst->zero_threshold;
        *dst = *src;
        if (keep_thresh) dst->zero_threshold = th;
        return;
    }
    if (src->scale > dst->scale) {            /* src is finer: coarsen a copy */
        tmp = *src;
        otel_expo_downscale(&tmp, src->scale - dst->scale);
        s = &tmp;
    }
    else if (dst->scale > src->scale) {
        otel_expo_downscale(dst, dst->scale - src->scale);
    }

    /* Aligning the scales is not enough. The COMBINED index range may be far
     * wider than either input - two histograms of similar shape but different
     * magnitude are exactly the interesting case - and otel_expo_side_add
     * refuses to widen a window past max_size. Without this both would then
     * drop buckets silently, which is the specific failure this whole file
     * exists to avoid. So: work out what the union needs, and coarsen BOTH to
     * it before adding a single count. */
    {
        int by = 0, k;
        for (k = 0; k < 2; k++) {
            const otel_expo_side *ss = k ? &s->neg : &s->pos;
            otel_expo_side *ds = k ? &dst->neg : &dst->pos;
            int lo, hi, need = 0;
            if (ss->len <= 0) continue;
            if (ds->len <= 0) { lo = ss->offset; hi = ss->offset + ss->len - 1; }
            else {
                lo = ds->offset < ss->offset ? ds->offset : ss->offset;
                hi = (ds->offset + ds->len - 1) > (ss->offset + ss->len - 1)
                   ? (ds->offset + ds->len - 1) : (ss->offset + ss->len - 1);
            }
            while ((hi - lo + 1) > OTEL_EXPO_MAX_SIZE) { lo >>= 1; hi >>= 1; need++; }
            if (need > by) by = need;
        }
        if (by > 0) {
            if (s == &tmp) otel_expo_downscale(&tmp, by);
            else { tmp = *src;
                   otel_expo_downscale(&tmp, (src->scale - dst->scale) + by);
                   s = &tmp; }
            otel_expo_downscale(dst, by);
        }
    }
    dst->count += s->count;
    dst->sum   += s->sum;
    dst->zero_count += s->zero_count;
    if (s->min < dst->min) dst->min = s->min;
    if (s->max > dst->max) dst->max = s->max;
    for (i = 0; i < s->pos.len; i++)
        if (s->pos.counts[i])
            otel_expo_side_add(&dst->pos, s->pos.offset + i, s->pos.counts[i]);
    for (i = 0; i < s->neg.len; i++)
        if (s->neg.counts[i])
            otel_expo_side_add(&dst->neg, s->neg.offset + i, s->neg.counts[i]);
}

/* The total of every bucket plus the zeros, for the invariant the tests
 * assert: a downscale or a merge must never change it. */
static IV otel_expo_total(const otel_expo *h) {
    IV n = h->zero_count;
    int i;
    for (i = 0; i < h->pos.len; i++) n += h->pos.counts[i];
    for (i = 0; i < h->neg.len; i++) n += h->neg.counts[i];
    return n;
}

#endif /* OTEL_EXPO_H */

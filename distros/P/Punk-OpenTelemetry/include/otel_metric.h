/* otel_metric.h - the metrics data model.
 *
 * THE THING THAT MAKES METRICS DIFFERENT FROM TRACES: state.
 *
 * A span is created, ended and forgotten. A metric point is accumulated
 * across every export interval for the life of the process, per attribute
 * set, and both of those words are where the trouble is.
 *
 * PER ATTRIBUTE SET means the number of accumulators is the number of
 * distinct attribute combinations the application produces, which is a number
 * the application does not know and an attacker may choose. So there is a
 * CARDINALITY CAP, and past it everything folds into one overflow series
 * marked otel.metric.overflow. Without a cap, one unbounded attribute - a URL
 * path, a user id, a client-supplied header - turns a web server into an
 * out-of-memory incident, and the attribute most likely to do it is exactly
 * the one somebody added to "make the dashboard more useful".
 *
 * FOR THE LIFE OF THE PROCESS means a cumulative series is identified by its
 * resource plus its attributes, and its start timestamp must stay FIXED. If
 * that identity is not unique per process, a collector receives several
 * contradictory monotonic series claiming to be one, and resolves it by
 * resetting, summing, or taking the last write - all three wrong, none of
 * them wrong-looking on a dashboard. That is why service.instance.id must
 * differ per worker, and why this file refuses to be shared across a fork.
 */

#ifndef OTEL_METRIC_H
#define OTEL_METRIC_H

#include "otel_clock.h"
#include "otel_expo.h"
#include "otel_value.h"

/* instrument kinds */
#define OTEL_INSTR_COUNTER        1
#define OTEL_INSTR_UPDOWNCOUNTER  2
#define OTEL_INSTR_HISTOGRAM      3
#define OTEL_INSTR_GAUGE          4

/* aggregations */
#define OTEL_AGG_DROP        0
#define OTEL_AGG_SUM         1
#define OTEL_AGG_LASTVALUE   2
#define OTEL_AGG_HISTOGRAM   3   /* explicit buckets */
#define OTEL_AGG_EXPO        4   /* base-2 exponential */

/* temporality */
#define OTEL_TEMP_CUMULATIVE 1
#define OTEL_TEMP_DELTA      2

#define OTEL_CARDINALITY_MAX 2000
#define OTEL_MAX_BOUNDS       64

/* The conventions' default bucket boundaries for a duration in SECONDS. Not
 * a round-number guess: they are dense where web latencies actually live. */
#define OTEL_DEFAULT_BOUNDS_N 14
static const double OTEL_DEFAULT_BOUNDS[OTEL_DEFAULT_BOUNDS_N] = {
    0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5,
    0.75, 1.0, 2.5, 5.0, 7.5, 10.0
};

/* One exemplar: a raw measurement stapled to a point, carrying the trace it
 * came from. What turns "the p99 is bad" into "here is a trace of one". */
typedef struct {
    double  value;
    U64TYPE time;
    unsigned char trace_id[16];
    unsigned char span_id[8];
    int     has_span;
} otel_exemplar;

#define OTEL_EXEMPLAR_MAX 4

typedef struct otel_point {
    SV     *key;                  /* the serialised attribute set: identity */
    HV     *attrs;                /* +1 owned */
    U64TYPE start_nanos;          /* FIXED for a cumulative series */
    U64TYPE time_nanos;

    double  sum;                  /* Sum / Histogram */
    double  last;                 /* LastValue */
    IV      count;
    double  min, max;
    IV      buckets[OTEL_MAX_BOUNDS + 1];
    otel_expo expo;

    otel_exemplar ex[OTEL_EXEMPLAR_MAX];
    int     n_ex, ex_seen;        /* seen: for reservoir sampling */

    struct otel_point *next;
} otel_point;

typedef struct otel_instrument {
    SV     *name, *description, *unit;
    int     kind, aggregation, temporality;
    double  bounds[OTEL_MAX_BOUNDS];
    int     nbounds;
    otel_point *points;
    int     npoints;
    IV      overflow;             /* attribute sets past the cardinality cap */
    struct otel_instrument *next;
} otel_instrument;

/* ---- attribute-set identity --------------------------------------------- *
 * The key is the sorted key=value pairs, joined. Sorted because two hashes
 * with the same pairs in different orders are the SAME series, and Perl's
 * hash order is randomised - so an unsorted key would split one series into
 * many, per process, at random. */
static SV *otel_attrs_key(pTHX_ HV *attrs) {
    SV *out = newSVpvs("");
    AV *keys;
    SSize_t i, n;
    if (!attrs || !HvUSEDKEYS(attrs)) return out;
    keys = otel_attr_keys(aTHX_ attrs);       /* sorted; shared with the encoder */
    n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV **kp = av_fetch(keys, i, 0);
        HE *e;
        if (!(kp && *kp)) continue;
        if (SvCUR(out)) sv_catpvs(out, "\x1f");   /* a separator no key holds */
        sv_catsv(out, *kp);
        sv_catpvs(out, "\x1e");
        e = hv_fetch_ent(attrs, *kp, 0, 0);
        if (e && HeVAL(e) && SvOK(HeVAL(e))) sv_catsv(out, HeVAL(e));
    }
    return out;
}

static otel_point *otel_point_new(pTHX_ SV *key, HV *attrs) {
    otel_point *p;
    Newxz(p, 1, otel_point);
    p->key   = key;                            /* takes ownership */
    p->attrs = attrs ? (HV *)SvREFCNT_inc((SV *)attrs) : newHV();
    p->start_nanos = otel_wall_nanos();
    p->min =  1.0 / 0.0;
    p->max = -1.0 / 0.0;
    otel_expo_init(&p->expo, 20);
    return p;
}

static void otel_point_free(pTHX_ otel_point *p) {
    if (!p) return;
    if (p->key)   SvREFCNT_dec(p->key);
    if (p->attrs) SvREFCNT_dec((SV *)p->attrs);
    Safefree(p);
}

/* Find or create the point for an attribute set.
 *
 * Past the cardinality cap every further set folds into ONE overflow point,
 * whose single attribute is otel.metric.overflow. The series stops being
 * useful at that moment, which is the intended signal: a metric that has
 * overflowed says so, rather than quietly costing memory until something
 * dies. */
static otel_point *otel_instr_point(pTHX_ otel_instrument *in, HV *attrs) {
    SV *key = otel_attrs_key(aTHX_ attrs);
    otel_point *p;
    STRLEN kl;
    const char *ks = SvPV_const(key, kl);

    for (p = in->points; p; p = p->next) {
        STRLEN pl;
        const char *ps = SvPV_const(p->key, pl);
        if (pl == kl && (kl == 0 || memEQ(ps, ks, kl))) {
            SvREFCNT_dec(key);
            return p;
        }
    }
    if (in->npoints >= OTEL_CARDINALITY_MAX) {
        HV *ov;
        SvREFCNT_dec(key);
        in->overflow++;
        /* reuse the one overflow point, creating it once */
        for (p = in->points; p; p = p->next) {
            STRLEN pl;
            const char *ps = SvPV_const(p->key, pl);
            if (pl == 20 && memEQ(ps, "otel.metric.overflow", 20)) return p;
        }
        ov = newHV();
        (void)hv_stores(ov, "otel.metric.overflow", newSViv(1));
        p = otel_point_new(aTHX_ newSVpvs("otel.metric.overflow"), ov);
        SvREFCNT_dec((SV *)ov);
        p->next = in->points;
        in->points = p;
        return p;
    }
    p = otel_point_new(aTHX_ key, attrs);
    p->next = in->points;
    in->points = p;
    in->npoints++;
    return p;
}

/* ---- exemplars ---------------------------------------------------------- *
 * The default filter is TRACE_BASED: record one only when there is a sampled
 * span in context, because an exemplar whose trace was never recorded is a
 * pointer to nothing. */
static void otel_point_exemplar(otel_point *p, double v, otel_span *span,
                                int bucket) {
    otel_exemplar *slot;
    if (!span) return;                         /* trace_based: no span, none */
    if (bucket >= 0 && bucket < OTEL_EXEMPLAR_MAX) {
        /* aligned-bucket reservoir: one per bucket, so a histogram's
         * exemplars span its range instead of clustering in the busiest
         * bucket */
        slot = &p->ex[bucket];
        if (bucket >= p->n_ex) p->n_ex = bucket + 1;
    }
    else {
        /* simple fixed-size reservoir */
        p->ex_seen++;
        if (p->n_ex < OTEL_EXEMPLAR_MAX) slot = &p->ex[p->n_ex++];
        else {
            int r = (int)(otel_wall_nanos() % (U64TYPE)p->ex_seen);
            if (r >= OTEL_EXEMPLAR_MAX) return;
            slot = &p->ex[r];
        }
    }
    slot->value = v;
    slot->time  = otel_wall_nanos();
    Copy(span->trace_id, slot->trace_id, 16, unsigned char);
    Copy(span->span_id,  slot->span_id,   8, unsigned char);
    slot->has_span = 1;
}

/* ---- recording ---------------------------------------------------------- */

static int otel_bucket_of(const otel_instrument *in, double v) {
    int i;
    for (i = 0; i < in->nbounds; i++) if (v <= in->bounds[i]) return i;
    return in->nbounds;
}

static void otel_instr_record(pTHX_ otel_instrument *in, double v, HV *attrs,
                              otel_span *span) {
    otel_point *p;
    if (!in || in->aggregation == OTEL_AGG_DROP) return;
    p = otel_instr_point(aTHX_ in, attrs);
    p->time_nanos = otel_wall_nanos();

    switch (in->aggregation) {
        case OTEL_AGG_SUM:
            p->sum += v;
            p->count++;
            otel_point_exemplar(p, v, span, -1);
            break;
        case OTEL_AGG_LASTVALUE:
            p->last = v;
            p->count++;
            break;
        case OTEL_AGG_HISTOGRAM: {
            int b = otel_bucket_of(in, v);
            p->sum += v;
            p->count++;
            if (v < p->min) p->min = v;
            if (v > p->max) p->max = v;
            if (b <= OTEL_MAX_BOUNDS) p->buckets[b]++;
            otel_point_exemplar(p, v, span, b);
            break;
        }
        case OTEL_AGG_EXPO:
            otel_expo_record(&p->expo, v);
            p->sum = p->expo.sum;
            p->count = p->expo.count;
            otel_point_exemplar(p, v, span, -1);
            break;
    }
}

/* After a DELTA collection, every accumulator resets and the next interval
 * starts now. Under CUMULATIVE nothing is reset and start_nanos stays put -
 * which is the whole distinction, and the thing a backend notices when it is
 * wrong. */
static void otel_point_reset(otel_point *p) {
    U64TYPE now = otel_wall_nanos();
    int i;
    p->sum = 0;
    p->count = 0;
    p->min =  1.0 / 0.0;
    p->max = -1.0 / 0.0;
    for (i = 0; i <= OTEL_MAX_BOUNDS; i++) p->buckets[i] = 0;
    otel_expo_init(&p->expo, p->expo.scale);
    p->n_ex = p->ex_seen = 0;
    p->start_nanos = now;
}

#endif /* OTEL_METRIC_H */

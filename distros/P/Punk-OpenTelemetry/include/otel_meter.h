/* otel_meter.h - the meter: instruments, views, and collection.
 *
 * VIEWS. A view selects instruments and reshapes what they produce: rename
 * it, drop it, keep only some attribute keys, change the aggregation.
 *
 * The part a naive implementation misses is that SEVERAL views may match one
 * instrument, producing several streams from it - that is the point of views,
 * not an edge case. And two streams that end up with the same name but
 * different units, kinds or aggregations are a CONFLICT: the backend cannot
 * store both under one name, so it stores whichever arrived last, silently.
 * Detecting that and saying so - naming both - is the difference between a
 * misconfiguration you fix in a minute and a dashboard that is subtly wrong
 * for a quarter.
 *
 * Dropping attribute KEYS is the primary tool against cardinality, and is
 * worth reaching for before the cap in otel_metric.h has to do its job.
 */

#ifndef OTEL_METER_H
#define OTEL_METER_H

#include "otel_metric.h"

#define OTEL_MAX_VIEWS 32

typedef struct {
    SV *match;          /* instrument name to select; '*' suffix wildcards */
    SV *name;           /* the output name, or NULL to keep it */
    int aggregation;    /* -1 to keep the instrument's own */
    int has_keys;
    HV *keys;           /* attribute keys to KEEP, when has_keys */
    double bounds[OTEL_MAX_BOUNDS];
    int nbounds;        /* 0 to keep */
} otel_view;

typedef struct {
    otel_instrument *instruments;
    otel_view views[OTEL_MAX_VIEWS];
    int nviews;
    HV *resource;
    SV *scope_name, *scope_version;
    int temporality;    /* the reader's preference */
    IV  conflicts;
    pid_t owner_pid;
} otel_meter;

static otel_meter *otel_meter_new(pTHX) {
    otel_meter *m;
    Newxz(m, 1, otel_meter);
    m->resource = newHV();
    m->temporality = OTEL_TEMP_CUMULATIVE;
    m->owner_pid = getpid();
    return m;
}

static void otel_instr_free(pTHX_ otel_instrument *in) {
    otel_point *p;
    if (!in) return;
    for (p = in->points; p; ) {
        otel_point *n = p->next;
        otel_point_free(aTHX_ p);
        p = n;
    }
    if (in->name)        SvREFCNT_dec(in->name);
    if (in->description) SvREFCNT_dec(in->description);
    if (in->unit)        SvREFCNT_dec(in->unit);
    Safefree(in);
}

static void otel_meter_free(pTHX_ otel_meter *m) {
    otel_instrument *in;
    int i;
    if (!m) return;
    for (in = m->instruments; in; ) {
        otel_instrument *n = in->next;
        otel_instr_free(aTHX_ in);
        in = n;
    }
    for (i = 0; i < m->nviews; i++) {
        if (m->views[i].match) SvREFCNT_dec(m->views[i].match);
        if (m->views[i].name)  SvREFCNT_dec(m->views[i].name);
        if (m->views[i].keys)  SvREFCNT_dec((SV *)m->views[i].keys);
    }
    if (m->resource)      SvREFCNT_dec((SV *)m->resource);
    if (m->scope_name)    SvREFCNT_dec(m->scope_name);
    if (m->scope_version) SvREFCNT_dec(m->scope_version);
    Safefree(m);
}

/* A worker that inherited accumulated points would export the parent's totals
 * as its own - and under cumulative temporality that is not a duplicate, it
 * is a contradictory series under the same identity. Everything resets. */
static void otel_meter_check_fork(pTHX_ otel_meter *m) {
    otel_instrument *in;
    otel_point *p;
    pid_t me = getpid();
    if (m->owner_pid == me) return;
    for (in = m->instruments; in; in = in->next) {
        for (p = in->points; p; p = p->next) otel_point_reset(p);
        in->overflow = 0;
    }
    m->owner_pid = me;
}

static int otel_view_matches(pTHX_ otel_view *v, SV *name) {
    STRLEN ml, nl;
    const char *ms, *ns;
    if (!v->match || !name) return 0;
    ms = SvPV_const(v->match, ml);
    ns = SvPV_const(name, nl);
    if (ml && ms[ml - 1] == '*')                /* prefix wildcard */
        return nl >= ml - 1 && memEQ(ns, ms, ml - 1);
    return ml == nl && memEQ(ns, ms, ml);
}

/* Find or create an instrument, applying any matching views.
 *
 * A conflict - the same output name with a different unit, kind or
 * aggregation - is counted and reported rather than silently resolved,
 * because the silent resolution is "whichever the backend saw last". */
static otel_instrument *otel_meter_instrument(pTHX_ otel_meter *m, SV *name,
                                              int kind, SV *unit,
                                              SV *description) {
    otel_instrument *in;
    int agg, i;
    STRLEN nl;
    const char *ns = SvPV_const(name, nl);

    for (in = m->instruments; in; in = in->next) {
        STRLEN il;
        const char *is = SvPV_const(in->name, il);
        if (il == nl && memEQ(is, ns, nl)) {
            /* same name: is it the same stream? */
            if (in->kind != kind) m->conflicts++;
            else if (unit && in->unit) {
                STRLEN ul, iu;
                const char *us = SvPV_const(unit, ul);
                const char *iv = SvPV_const(in->unit, iu);
                if (ul != iu || !memEQ(us, iv, ul)) m->conflicts++;
            }
            return in;
        }
    }

    agg = (kind == OTEL_INSTR_HISTOGRAM) ? OTEL_AGG_HISTOGRAM
        : (kind == OTEL_INSTR_GAUGE)     ? OTEL_AGG_LASTVALUE
        : OTEL_AGG_SUM;

    Newxz(in, 1, otel_instrument);
    in->name        = newSVsv(name);
    in->unit        = unit ? newSVsv(unit) : NULL;
    in->description = description ? newSVsv(description) : NULL;
    in->kind        = kind;
    in->aggregation = agg;
    in->temporality = m->temporality;
    if (kind == OTEL_INSTR_HISTOGRAM) {
        in->nbounds = OTEL_DEFAULT_BOUNDS_N;
        for (i = 0; i < OTEL_DEFAULT_BOUNDS_N; i++)
            in->bounds[i] = OTEL_DEFAULT_BOUNDS[i];
    }

    /* views, applied in declaration order; the last matching one wins for
     * each property it sets */
    for (i = 0; i < m->nviews; i++) {
        otel_view *v = &m->views[i];
        if (!otel_view_matches(aTHX_ v, name)) continue;
        if (v->name) { SvREFCNT_dec(in->name); in->name = newSVsv(v->name); }
        if (v->aggregation >= 0) in->aggregation = v->aggregation;
        if (v->nbounds) {
            int j;
            in->nbounds = v->nbounds;
            for (j = 0; j < v->nbounds; j++) in->bounds[j] = v->bounds[j];
        }
    }
    in->next = m->instruments;
    m->instruments = in;
    return in;
}

/* Attribute keys a view kept, or the set unchanged when it filtered none.
 * Dropping keys is the primary tool against cardinality. */
static HV *otel_view_filter(pTHX_ otel_meter *m, SV *name, HV *attrs) {
    int i;
    for (i = 0; i < m->nviews; i++) {
        otel_view *v = &m->views[i];
        HV *out;
        HE *he;
        if (!v->has_keys || !otel_view_matches(aTHX_ v, name)) continue;
        out = (HV *)sv_2mortal((SV *)newHV());
        if (attrs) {
            hv_iterinit(attrs);
            while ((he = hv_iternext(attrs))) {
                SV *k = hv_iterkeysv(he);
                if (hv_exists_ent(v->keys, k, 0))
                    (void)hv_store_ent(out, k, newSVsv(HeVAL(he)), 0);
            }
        }
        return out;
    }
    return attrs;
}

/* ---- collection --------------------------------------------------------- *
 * The payload shape mirrors the trace one: resource_metrics -> scope_metrics
 * -> metrics, each metric carrying its data points. The encoder in
 * otel_metric_pb.h turns this into protobuf; keeping the intermediate shape
 * Perl-visible is what lets a test assert temporality and reset behaviour
 * without decoding bytes. */

static SV *otel_point_to_hv(pTHX_ otel_instrument *in, otel_point *p) {
    HV *h = newHV();
    int i;
    (void)hv_stores(h, "attributes", newRV_inc((SV *)p->attrs));
    (void)hv_stores(h, "start_time_unix_nano", newSVuv((UV)p->start_nanos));
    (void)hv_stores(h, "time_unix_nano", newSVuv((UV)p->time_nanos));
    (void)hv_stores(h, "count", newSViv(p->count));

    switch (in->aggregation) {
        case OTEL_AGG_LASTVALUE:
            (void)hv_stores(h, "value", newSVnv(p->last));
            break;
        case OTEL_AGG_HISTOGRAM: {
            AV *bk = newAV(), *bd = newAV();
            for (i = 0; i <= in->nbounds; i++) av_push(bk, newSViv(p->buckets[i]));
            for (i = 0; i < in->nbounds; i++)  av_push(bd, newSVnv(in->bounds[i]));
            (void)hv_stores(h, "sum", newSVnv(p->sum));
            (void)hv_stores(h, "bucket_counts", newRV_noinc((SV *)bk));
            (void)hv_stores(h, "explicit_bounds", newRV_noinc((SV *)bd));
            if (p->count) {
                (void)hv_stores(h, "min", newSVnv(p->min));
                (void)hv_stores(h, "max", newSVnv(p->max));
            }
            break;
        }
        case OTEL_AGG_EXPO: {
            HV *pos = newHV(), *neg = newHV();
            AV *pc = newAV(), *nc = newAV();
            for (i = 0; i < p->expo.pos.len; i++)
                av_push(pc, newSViv(p->expo.pos.counts[i]));
            for (i = 0; i < p->expo.neg.len; i++)
                av_push(nc, newSViv(p->expo.neg.counts[i]));
            (void)hv_stores(pos, "offset", newSViv(p->expo.pos.offset));
            (void)hv_stores(pos, "bucket_counts", newRV_noinc((SV *)pc));
            (void)hv_stores(neg, "offset", newSViv(p->expo.neg.offset));
            (void)hv_stores(neg, "bucket_counts", newRV_noinc((SV *)nc));
            (void)hv_stores(h, "scale", newSViv(p->expo.scale));
            (void)hv_stores(h, "zero_count", newSViv(p->expo.zero_count));
            (void)hv_stores(h, "sum", newSVnv(p->expo.sum));
            (void)hv_stores(h, "positive", newRV_noinc((SV *)pos));
            (void)hv_stores(h, "negative", newRV_noinc((SV *)neg));
            break;
        }
        default:
            (void)hv_stores(h, "value", newSVnv(p->sum));
            (void)hv_stores(h, "sum", newSVnv(p->sum));
            break;
    }

    if (p->n_ex) {
        AV *ex = newAV();
        for (i = 0; i < p->n_ex; i++) {
            HV *e;
            char hex[32];
            if (!p->ex[i].has_span) continue;
            e = newHV();
            (void)hv_stores(e, "value", newSVnv(p->ex[i].value));
            (void)hv_stores(e, "time_unix_nano", newSVuv((UV)p->ex[i].time));
            otel_bytes_to_hex(p->ex[i].trace_id, 16, hex);
            (void)hv_stores(e, "trace_id", newSVpvn(hex, 32));
            otel_bytes_to_hex(p->ex[i].span_id, 8, hex);
            (void)hv_stores(e, "span_id", newSVpvn(hex, 16));
            av_push(ex, newRV_noinc((SV *)e));
        }
        if (av_len(ex) >= 0) (void)hv_stores(h, "exemplars", newRV_noinc((SV *)ex));
        else SvREFCNT_dec((SV *)ex);
    }
    return newRV_noinc((SV *)h);
}

static SV *otel_meter_collect(pTHX_ otel_meter *m) {
    HV *payload, *rm, *sm, *res, *scope;
    AV *rms, *sms, *metrics;
    otel_instrument *in;
    int any = 0;

    metrics = newAV();
    for (in = m->instruments; in; in = in->next) {
        HV *mh;
        AV *pts;
        otel_point *p;
        if (in->aggregation == OTEL_AGG_DROP) continue;
        pts = newAV();
        for (p = in->points; p; p = p->next) {
            if (!p->count && in->aggregation != OTEL_AGG_LASTVALUE) continue;
            av_push(pts, otel_point_to_hv(aTHX_ in, p));
            any = 1;
        }
        if (av_len(pts) < 0) { SvREFCNT_dec((SV *)pts); continue; }
        mh = newHV();
        (void)hv_stores(mh, "name", newSVsv(in->name));
        if (in->unit)        (void)hv_stores(mh, "unit", newSVsv(in->unit));
        if (in->description) (void)hv_stores(mh, "description",
                                             newSVsv(in->description));
        (void)hv_stores(mh, "aggregation", newSViv(in->aggregation));
        (void)hv_stores(mh, "temporality", newSViv(in->temporality));
        (void)hv_stores(mh, "monotonic",
                        newSViv(in->kind == OTEL_INSTR_COUNTER ? 1 : 0));
        (void)hv_stores(mh, "data_points", newRV_noinc((SV *)pts));
        if (in->overflow) (void)hv_stores(mh, "overflow", newSViv(in->overflow));
        av_push(metrics, newRV_noinc((SV *)mh));
    }
    if (!any) { SvREFCNT_dec((SV *)metrics); return NULL; }

    /* DELTA resets every accumulator and restarts the interval; CUMULATIVE
     * leaves both alone. That is the entire distinction. */
    if (m->temporality == OTEL_TEMP_DELTA) {
        otel_point *p;
        for (in = m->instruments; in; in = in->next)
            for (p = in->points; p; p = p->next) otel_point_reset(p);
    }

    scope = newHV();
    if (m->scope_name)    (void)hv_stores(scope, "name", newSVsv(m->scope_name));
    if (m->scope_version) (void)hv_stores(scope, "version",
                                          newSVsv(m->scope_version));
    sm = newHV();
    (void)hv_stores(sm, "scope", newRV_noinc((SV *)scope));
    (void)hv_stores(sm, "metrics", newRV_noinc((SV *)metrics));
    sms = newAV();
    av_push(sms, newRV_noinc((SV *)sm));

    res = newHV();
    (void)hv_stores(res, "attributes", newRV_inc((SV *)m->resource));
    rm = newHV();
    (void)hv_stores(rm, "resource", newRV_noinc((SV *)res));
    (void)hv_stores(rm, "scope_metrics", newRV_noinc((SV *)sms));
    rms = newAV();
    av_push(rms, newRV_noinc((SV *)rm));

    payload = newHV();
    (void)hv_stores(payload, "resource_metrics", newRV_noinc((SV *)rms));
    return newRV_noinc((SV *)payload);
}

#endif /* OTEL_METER_H */


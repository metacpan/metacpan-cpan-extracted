/* otel_signal_pb.h - the metrics and logs message trees, in protobuf.
 *
 * Same two-pass shape as otel_trace.h: a size_ function beside every write_
 * function, agreeing byte for byte, checked by OTEL_PB_CHECK in an author
 * build.
 *
 * Both take the payload the SDK already produces - Meter::collect and the log
 * record list - so nothing has to be reshaped between collecting and sending.
 */

#ifndef OTEL_SIGNAL_PB_H
#define OTEL_SIGNAL_PB_H

#include "otel_pb.h"
#include "otel_proto.h"
#include "otel_trace.h"     /* otel_h / otel_h_hv / otel_h_av / otel_id */
#include "otel_value.h"

/* The internal temporality constants are numbered the OTHER WAY ROUND from
 * the OTLP enum (internal: cumulative 1, delta 2; OTLP: delta 1,
 * cumulative 2). Emitting the internal value would label every series as its
 * opposite, which a backend accepts and then draws completely wrongly. */
static int otel_pb_temporality(IV internal) {
    return internal == 2 /* OTEL_TEMP_DELTA */ ? PB_TEMPORALITY_DELTA
                                               : PB_TEMPORALITY_CUMULATIVE;
}

/* ---- an IV list out of an AV, bounded --------------------------------- */
static int otel_iv_list(pTHX_ AV *av, IV *out, int cap) {
    SSize_t i, n = av ? av_len(av) + 1 : 0;
    int c = 0;
    for (i = 0; i < n && c < cap; i++) {
        SV **e = av_fetch(av, i, 0);
        out[c++] = (e && *e) ? SvIV(*e) : 0;
    }
    return c;
}
static int otel_nv_list(pTHX_ AV *av, double *out, int cap) {
    SSize_t i, n = av ? av_len(av) + 1 : 0;
    int c = 0;
    for (i = 0; i < n && c < cap; i++) {
        SV **e = av_fetch(av, i, 0);
        out[c++] = (e && *e) ? SvNV(*e) : 0;
    }
    return c;
}

#define OTEL_PB_MAX_BUCKETS 256

/* ---- Exemplar ----------------------------------------------------------- */

static size_t otel_pb_exemplar_size(pTHX_ HV *e) {
    size_t n = 0;
    char t16[16], s8[8];
    STRLEN tl, sl;
    if (!e) return 0;
    if (otel_h(aTHX_ e, "time_unix_nano"))
        n += otel_pb_fixed64_size(PB_EXEMPLAR_TIME);
    n += otel_pb_double_size(PB_EXEMPLAR_AS_DOUBLE);
    if (otel_id(aTHX_ e, "span_id", 8, &sl, s8))
        n += otel_pb_bytes_size(PB_EXEMPLAR_SPAN_ID, sl);
    if (otel_id(aTHX_ e, "trace_id", 16, &tl, t16))
        n += otel_pb_bytes_size(PB_EXEMPLAR_TRACE_ID, tl);
    return n;
}

static void otel_pb_exemplar_write(pTHX_ otel_buf *b, HV *e) {
    SV *v;
    char t16[16], s8[8];
    STRLEN tl, sl;
    const char *p;
    if (!e) return;
    if ((v = otel_h(aTHX_ e, "time_unix_nano")))
        otel_pb_fixed64(b, PB_EXEMPLAR_TIME, (U64TYPE)SvUV(v));
    v = otel_h(aTHX_ e, "value");
    otel_pb_double(b, PB_EXEMPLAR_AS_DOUBLE, v ? SvNV(v) : 0);
    if ((p = otel_id(aTHX_ e, "span_id", 8, &sl, s8)))
        otel_pb_bytes(b, PB_EXEMPLAR_SPAN_ID, p, sl);
    if ((p = otel_id(aTHX_ e, "trace_id", 16, &tl, t16)))
        otel_pb_bytes(b, PB_EXEMPLAR_TRACE_ID, p, tl);
}

/* ---- data points -------------------------------------------------------- */

static size_t otel_pb_ndp_size(pTHX_ HV *dp) {
    size_t n = otel_attrs_size(aTHX_ otel_h_hv(aTHX_ dp, "attributes"),
                               PB_NDP_ATTRIBUTES);
    n += otel_pb_fixed64_size(PB_NDP_START_TIME);
    n += otel_pb_fixed64_size(PB_NDP_TIME);
    n += otel_pb_double_size(PB_NDP_AS_DOUBLE);
    {
        AV *ex = otel_h_av(aTHX_ dp, "exemplars");
        SSize_t i, c = ex ? av_len(ex) + 1 : 0;
        for (i = 0; i < c; i++) {
            SV **e = av_fetch(ex, i, 0);
            n += otel_pb_msg_size(PB_NDP_EXEMPLARS,
                     otel_pb_exemplar_size(aTHX_ otel_hv_of(aTHX_ (e?*e:NULL))));
        }
    }
    return n;
}

static void otel_pb_ndp_write(pTHX_ otel_buf *b, HV *dp) {
    SV *v;
    AV *ex;
    SSize_t i, c;
    otel_attrs_write(aTHX_ b, otel_h_hv(aTHX_ dp, "attributes"),
                     PB_NDP_ATTRIBUTES);
    v = otel_h(aTHX_ dp, "start_time_unix_nano");
    otel_pb_fixed64(b, PB_NDP_START_TIME, v ? (U64TYPE)SvUV(v) : 0);
    v = otel_h(aTHX_ dp, "time_unix_nano");
    otel_pb_fixed64(b, PB_NDP_TIME, v ? (U64TYPE)SvUV(v) : 0);
    v = otel_h(aTHX_ dp, "value");
    if (!v) v = otel_h(aTHX_ dp, "sum");
    otel_pb_double(b, PB_NDP_AS_DOUBLE, v ? SvNV(v) : 0);
    ex = otel_h_av(aTHX_ dp, "exemplars");
    c = ex ? av_len(ex) + 1 : 0;
    for (i = 0; i < c; i++) {
        SV **e = av_fetch(ex, i, 0);
        HV *eh = otel_hv_of(aTHX_ (e ? *e : NULL));
        size_t s = otel_pb_exemplar_size(aTHX_ eh), mark;
        otel_pb_msg_head(b, PB_NDP_EXEMPLARS, s);
        mark = b->len;
        otel_pb_exemplar_write(aTHX_ b, eh);
        OTEL_PB_CHECK(b, mark, s, "Exemplar");
    }
}

static size_t otel_pb_hdp_size(pTHX_ HV *dp) {
    IV bk[OTEL_PB_MAX_BUCKETS];
    double bd[OTEL_PB_MAX_BUCKETS];
    int nb = otel_iv_list(aTHX_ otel_h_av(aTHX_ dp, "bucket_counts"),
                          bk, OTEL_PB_MAX_BUCKETS);
    int nd = otel_nv_list(aTHX_ otel_h_av(aTHX_ dp, "explicit_bounds"),
                          bd, OTEL_PB_MAX_BUCKETS);
    size_t n = otel_attrs_size(aTHX_ otel_h_hv(aTHX_ dp, "attributes"),
                               PB_HDP_ATTRIBUTES);
    n += otel_pb_fixed64_size(PB_HDP_START_TIME);
    n += otel_pb_fixed64_size(PB_HDP_TIME);
    n += otel_pb_fixed64_size(PB_HDP_COUNT);
    n += otel_pb_double_size(PB_HDP_SUM);
    if (nb) n += otel_pb_packed_u64_size(PB_HDP_BUCKET_COUNTS, bk, nb);
    if (nd) n += otel_pb_packed_double_size(PB_HDP_EXPLICIT_BOUNDS, nd);
    if (otel_h(aTHX_ dp, "min")) n += otel_pb_double_size(PB_HDP_MIN);
    if (otel_h(aTHX_ dp, "max")) n += otel_pb_double_size(PB_HDP_MAX);
    {
        AV *ex = otel_h_av(aTHX_ dp, "exemplars");
        SSize_t i, c = ex ? av_len(ex) + 1 : 0;
        for (i = 0; i < c; i++) {
            SV **e = av_fetch(ex, i, 0);
            n += otel_pb_msg_size(PB_HDP_EXEMPLARS,
                     otel_pb_exemplar_size(aTHX_ otel_hv_of(aTHX_ (e?*e:NULL))));
        }
    }
    return n;
}

static void otel_pb_hdp_write(pTHX_ otel_buf *b, HV *dp) {
    IV bk[OTEL_PB_MAX_BUCKETS];
    double bd[OTEL_PB_MAX_BUCKETS];
    int nb = otel_iv_list(aTHX_ otel_h_av(aTHX_ dp, "bucket_counts"),
                          bk, OTEL_PB_MAX_BUCKETS);
    int nd = otel_nv_list(aTHX_ otel_h_av(aTHX_ dp, "explicit_bounds"),
                          bd, OTEL_PB_MAX_BUCKETS);
    SV *v;
    AV *ex;
    SSize_t i, c;
    otel_attrs_write(aTHX_ b, otel_h_hv(aTHX_ dp, "attributes"),
                     PB_HDP_ATTRIBUTES);
    v = otel_h(aTHX_ dp, "start_time_unix_nano");
    otel_pb_fixed64(b, PB_HDP_START_TIME, v ? (U64TYPE)SvUV(v) : 0);
    v = otel_h(aTHX_ dp, "time_unix_nano");
    otel_pb_fixed64(b, PB_HDP_TIME, v ? (U64TYPE)SvUV(v) : 0);
    v = otel_h(aTHX_ dp, "count");
    otel_pb_fixed64(b, PB_HDP_COUNT, v ? (U64TYPE)SvUV(v) : 0);
    v = otel_h(aTHX_ dp, "sum");
    otel_pb_double(b, PB_HDP_SUM, v ? SvNV(v) : 0);
    if (nb) otel_pb_packed_u64(b, PB_HDP_BUCKET_COUNTS, bk, nb);
    if (nd) otel_pb_packed_double(b, PB_HDP_EXPLICIT_BOUNDS, bd, nd);
    if ((v = otel_h(aTHX_ dp, "min"))) otel_pb_double(b, PB_HDP_MIN, SvNV(v));
    if ((v = otel_h(aTHX_ dp, "max"))) otel_pb_double(b, PB_HDP_MAX, SvNV(v));
    ex = otel_h_av(aTHX_ dp, "exemplars");
    c = ex ? av_len(ex) + 1 : 0;
    for (i = 0; i < c; i++) {
        SV **e = av_fetch(ex, i, 0);
        HV *eh = otel_hv_of(aTHX_ (e ? *e : NULL));
        size_t s = otel_pb_exemplar_size(aTHX_ eh), mark;
        otel_pb_msg_head(b, PB_HDP_EXEMPLARS, s);
        mark = b->len;
        otel_pb_exemplar_write(aTHX_ b, eh);
        OTEL_PB_CHECK(b, mark, s, "Exemplar");
    }
}

/* the positive/negative Buckets sub-message */
static size_t otel_pb_buckets_size(pTHX_ HV *side) {
    IV bk[OTEL_PB_MAX_BUCKETS];
    int n;
    size_t sz = 0;
    SV *off;
    if (!side) return 0;
    n = otel_iv_list(aTHX_ otel_h_av(aTHX_ side, "bucket_counts"),
                     bk, OTEL_PB_MAX_BUCKETS);
    off = otel_h(aTHX_ side, "offset");
    if (off && SvIV(off)) sz += otel_pb_int32_size(PB_BUCKETS_OFFSET,
                                                   (int)SvIV(off));
    if (n) sz += otel_pb_packed_varint_size(PB_BUCKETS_COUNTS, bk, n);
    return sz;
}
static void otel_pb_buckets_write(pTHX_ otel_buf *b, HV *side) {
    IV bk[OTEL_PB_MAX_BUCKETS];
    int n;
    SV *off;
    if (!side) return;
    n = otel_iv_list(aTHX_ otel_h_av(aTHX_ side, "bucket_counts"),
                     bk, OTEL_PB_MAX_BUCKETS);
    off = otel_h(aTHX_ side, "offset");
    if (off && SvIV(off)) otel_pb_int32(b, PB_BUCKETS_OFFSET, (int)SvIV(off));
    if (n) otel_pb_packed_varint(b, PB_BUCKETS_COUNTS, bk, n);
}

static size_t otel_pb_edp_size(pTHX_ HV *dp) {
    size_t n = otel_attrs_size(aTHX_ otel_h_hv(aTHX_ dp, "attributes"),
                               PB_EDP_ATTRIBUTES);
    HV *pos = otel_h_hv(aTHX_ dp, "positive");
    HV *neg = otel_h_hv(aTHX_ dp, "negative");
    SV *v;
    n += otel_pb_fixed64_size(PB_EDP_START_TIME);
    n += otel_pb_fixed64_size(PB_EDP_TIME);
    n += otel_pb_fixed64_size(PB_EDP_COUNT);
    n += otel_pb_double_size(PB_EDP_SUM);
    if ((v = otel_h(aTHX_ dp, "scale")))
        n += otel_pb_int32_size(PB_EDP_SCALE, (int)SvIV(v));
    if ((v = otel_h(aTHX_ dp, "zero_count")) && SvUV(v))
        n += otel_pb_fixed64_size(PB_EDP_ZERO_COUNT);
    if (pos) n += otel_pb_msg_size(PB_EDP_POSITIVE,
                                   otel_pb_buckets_size(aTHX_ pos));
    if (neg) n += otel_pb_msg_size(PB_EDP_NEGATIVE,
                                   otel_pb_buckets_size(aTHX_ neg));
    return n;
}

static void otel_pb_edp_write(pTHX_ otel_buf *b, HV *dp) {
    HV *pos = otel_h_hv(aTHX_ dp, "positive");
    HV *neg = otel_h_hv(aTHX_ dp, "negative");
    SV *v;
    otel_attrs_write(aTHX_ b, otel_h_hv(aTHX_ dp, "attributes"),
                     PB_EDP_ATTRIBUTES);
    v = otel_h(aTHX_ dp, "start_time_unix_nano");
    otel_pb_fixed64(b, PB_EDP_START_TIME, v ? (U64TYPE)SvUV(v) : 0);
    v = otel_h(aTHX_ dp, "time_unix_nano");
    otel_pb_fixed64(b, PB_EDP_TIME, v ? (U64TYPE)SvUV(v) : 0);
    v = otel_h(aTHX_ dp, "count");
    otel_pb_fixed64(b, PB_EDP_COUNT, v ? (U64TYPE)SvUV(v) : 0);
    v = otel_h(aTHX_ dp, "sum");
    otel_pb_double(b, PB_EDP_SUM, v ? SvNV(v) : 0);
    if ((v = otel_h(aTHX_ dp, "scale")))
        otel_pb_int32(b, PB_EDP_SCALE, (int)SvIV(v));
    if ((v = otel_h(aTHX_ dp, "zero_count")) && SvUV(v))
        otel_pb_fixed64(b, PB_EDP_ZERO_COUNT, (U64TYPE)SvUV(v));
    if (pos) {
        size_t s = otel_pb_buckets_size(aTHX_ pos), mark;
        otel_pb_msg_head(b, PB_EDP_POSITIVE, s);
        mark = b->len;
        otel_pb_buckets_write(aTHX_ b, pos);
        OTEL_PB_CHECK(b, mark, s, "Buckets");
    }
    if (neg) {
        size_t s = otel_pb_buckets_size(aTHX_ neg), mark;
        otel_pb_msg_head(b, PB_EDP_NEGATIVE, s);
        mark = b->len;
        otel_pb_buckets_write(aTHX_ b, neg);
        OTEL_PB_CHECK(b, mark, s, "Buckets");
    }
}

/* ---- Metric ------------------------------------------------------------- */

/* the data-type wrapper a metric's aggregation implies */
static void otel_pb_metric_kind(pTHX_ HV *m, int *field, int *dp_field,
                                int *temporality_field, int *monotonic) {
    IV agg = 0;
    SV *v = otel_h(aTHX_ m, "aggregation");
    if (v) agg = SvIV(v);
    *monotonic = 0;
    switch (agg) {
        case 2:  /* last value -> Gauge, which has no temporality */
            *field = PB_METRIC_GAUGE; *dp_field = PB_GAUGE_DATA_POINTS;
            *temporality_field = 0;
            break;
        case 3:
            *field = PB_METRIC_HISTOGRAM; *dp_field = PB_HIST_DATA_POINTS;
            *temporality_field = PB_HIST_TEMPORALITY;
            break;
        case 4:
            *field = PB_METRIC_EXP_HISTOGRAM; *dp_field = PB_EXPO_DATA_POINTS;
            *temporality_field = PB_EXPO_TEMPORALITY;
            break;
        default:
            *field = PB_METRIC_SUM; *dp_field = PB_SUM_DATA_POINTS;
            *temporality_field = PB_SUM_TEMPORALITY;
            v = otel_h(aTHX_ m, "monotonic");
            *monotonic = (v && SvTRUE(v)) ? 1 : 0;
            break;
    }
}

static size_t otel_pb_dp_size(pTHX_ HV *dp, IV agg) {
    if (agg == 3) return otel_pb_hdp_size(aTHX_ dp);
    if (agg == 4) return otel_pb_edp_size(aTHX_ dp);
    return otel_pb_ndp_size(aTHX_ dp);
}
static void otel_pb_dp_write(pTHX_ otel_buf *b, HV *dp, IV agg) {
    if (agg == 3)      otel_pb_hdp_write(aTHX_ b, dp);
    else if (agg == 4) otel_pb_edp_write(aTHX_ b, dp);
    else               otel_pb_ndp_write(aTHX_ b, dp);
}

static size_t otel_pb_metric_body_size(pTHX_ HV *m) {
    int field, dpf, tf, mono;
    IV agg = otel_h(aTHX_ m, "aggregation")
           ? SvIV(otel_h(aTHX_ m, "aggregation")) : 1;
    AV *dps = otel_h_av(aTHX_ m, "data_points");
    SSize_t i, c = dps ? av_len(dps) + 1 : 0;
    size_t inner = 0;
    otel_pb_metric_kind(aTHX_ m, &field, &dpf, &tf, &mono);
    for (i = 0; i < c; i++) {
        SV **e = av_fetch(dps, i, 0);
        inner += otel_pb_msg_size(dpf,
                     otel_pb_dp_size(aTHX_ otel_hv_of(aTHX_ (e?*e:NULL)), agg));
    }
    if (tf) {
        SV *t = otel_h(aTHX_ m, "temporality");
        inner += otel_pb_int32_size(tf, otel_pb_temporality(t ? SvIV(t) : 1));
    }
    if (mono) inner += otel_pb_bool_size(PB_SUM_IS_MONOTONIC);
    return inner;
}

static size_t otel_pb_metric_size(pTHX_ HV *m) {
    size_t n = 0;
    SV *v;
    int field, dpf, tf, mono;
    if ((v = otel_h(aTHX_ m, "name"))) {
        STRLEN l; (void)SvPV_const(v, l);
        n += otel_pb_bytes_size(PB_METRIC_NAME, l);
    }
    if ((v = otel_h(aTHX_ m, "description"))) {
        STRLEN l; (void)SvPV_const(v, l);
        n += otel_pb_bytes_size(PB_METRIC_DESCRIPTION, l);
    }
    if ((v = otel_h(aTHX_ m, "unit"))) {
        STRLEN l; (void)SvPV_const(v, l);
        n += otel_pb_bytes_size(PB_METRIC_UNIT, l);
    }
    otel_pb_metric_kind(aTHX_ m, &field, &dpf, &tf, &mono);
    n += otel_pb_msg_size(field, otel_pb_metric_body_size(aTHX_ m));
    return n;
}

static void otel_pb_metric_write(pTHX_ otel_buf *b, HV *m) {
    SV *v;
    int field, dpf, tf, mono;
    IV agg = otel_h(aTHX_ m, "aggregation")
           ? SvIV(otel_h(aTHX_ m, "aggregation")) : 1;
    AV *dps;
    SSize_t i, c;
    size_t inner, mark;

    if ((v = otel_h(aTHX_ m, "name"))) {
        STRLEN l; const char *s = SvPV_const(v, l);
        otel_pb_bytes(b, PB_METRIC_NAME, s, l);
    }
    if ((v = otel_h(aTHX_ m, "description"))) {
        STRLEN l; const char *s = SvPV_const(v, l);
        otel_pb_bytes(b, PB_METRIC_DESCRIPTION, s, l);
    }
    if ((v = otel_h(aTHX_ m, "unit"))) {
        STRLEN l; const char *s = SvPV_const(v, l);
        otel_pb_bytes(b, PB_METRIC_UNIT, s, l);
    }
    otel_pb_metric_kind(aTHX_ m, &field, &dpf, &tf, &mono);
    inner = otel_pb_metric_body_size(aTHX_ m);
    otel_pb_msg_head(b, field, inner);
    mark = b->len;

    dps = otel_h_av(aTHX_ m, "data_points");
    c = dps ? av_len(dps) + 1 : 0;
    for (i = 0; i < c; i++) {
        SV **e = av_fetch(dps, i, 0);
        HV *dp = otel_hv_of(aTHX_ (e ? *e : NULL));
        size_t s = otel_pb_dp_size(aTHX_ dp, agg), m2;
        otel_pb_msg_head(b, dpf, s);
        m2 = b->len;
        otel_pb_dp_write(aTHX_ b, dp, agg);
        OTEL_PB_CHECK(b, m2, s, "DataPoint");
    }
    if (tf) {
        SV *t = otel_h(aTHX_ m, "temporality");
        otel_pb_int32(b, tf, otel_pb_temporality(t ? SvIV(t) : 1));
    }
    if (mono) otel_pb_bool(b, PB_SUM_IS_MONOTONIC, 1);
    OTEL_PB_CHECK(b, mark, inner, "Metric body");
}

/* ---- ExportMetricsServiceRequest ---------------------------------------- */

static size_t otel_pb_scopemetrics_size(pTHX_ HV *sm) {
    size_t n = 0;
    HV *sc = otel_h_hv(aTHX_ sm, "scope");
    AV *ms = otel_h_av(aTHX_ sm, "metrics");
    SSize_t i, c;
    if (sc) n += otel_pb_msg_size(PB_SCOPEMETRICS_SCOPE,
                                  otel_scope_size(aTHX_ sc));
    c = ms ? av_len(ms) + 1 : 0;
    for (i = 0; i < c; i++) {
        SV **e = av_fetch(ms, i, 0);
        n += otel_pb_msg_size(PB_SCOPEMETRICS_METRICS,
                 otel_pb_metric_size(aTHX_ otel_hv_of(aTHX_ (e?*e:NULL))));
    }
    {
        SV *url = otel_h(aTHX_ sm, "schema_url");
        if (url) { STRLEN l; (void)SvPV_const(url, l);
                   n += otel_pb_bytes_size(PB_SCOPEMETRICS_SCHEMA_URL, l); }
    }
    return n;
}

static void otel_pb_scopemetrics_write(pTHX_ otel_buf *b, HV *sm) {
    HV *sc = otel_h_hv(aTHX_ sm, "scope");
    AV *ms = otel_h_av(aTHX_ sm, "metrics");
    SSize_t i, c;
    if (sc) {
        size_t s = otel_scope_size(aTHX_ sc), mark;
        otel_pb_msg_head(b, PB_SCOPEMETRICS_SCOPE, s);
        mark = b->len;
        otel_scope_write(aTHX_ b, sc);
        OTEL_PB_CHECK(b, mark, s, "Scope");
    }
    c = ms ? av_len(ms) + 1 : 0;
    for (i = 0; i < c; i++) {
        SV **e = av_fetch(ms, i, 0);
        HV *m = otel_hv_of(aTHX_ (e ? *e : NULL));
        size_t s = otel_pb_metric_size(aTHX_ m), mark;
        otel_pb_msg_head(b, PB_SCOPEMETRICS_METRICS, s);
        mark = b->len;
        otel_pb_metric_write(aTHX_ b, m);
        OTEL_PB_CHECK(b, mark, s, "Metric");
    }
    {
        SV *url = otel_h(aTHX_ sm, "schema_url");
        if (url) { STRLEN l; const char *u = SvPV_const(url, l);
                   otel_pb_bytes(b, PB_SCOPEMETRICS_SCHEMA_URL, u, l); }
    }
}

static size_t otel_pb_resourcemetrics_size(pTHX_ HV *rm) {
    size_t n = 0;
    HV *res = otel_h_hv(aTHX_ rm, "resource");
    AV *sms = otel_h_av(aTHX_ rm, "scope_metrics");
    SV *url = otel_h(aTHX_ rm, "schema_url");
    SSize_t i, c;
    if (res) n += otel_pb_msg_size(PB_RESOURCEMETRICS_RESOURCE,
                                   otel_resource_size(aTHX_ res));
    c = sms ? av_len(sms) + 1 : 0;
    for (i = 0; i < c; i++) {
        SV **e = av_fetch(sms, i, 0);
        n += otel_pb_msg_size(PB_RESOURCEMETRICS_SCOPE_METRICS,
                 otel_pb_scopemetrics_size(aTHX_ otel_hv_of(aTHX_ (e?*e:NULL))));
    }
    if (url) { STRLEN l; (void)SvPV_const(url, l);
               n += otel_pb_bytes_size(PB_RESOURCEMETRICS_SCHEMA_URL, l); }
    return n;
}

static void otel_pb_resourcemetrics_write(pTHX_ otel_buf *b, HV *rm) {
    HV *res = otel_h_hv(aTHX_ rm, "resource");
    AV *sms = otel_h_av(aTHX_ rm, "scope_metrics");
    SV *url = otel_h(aTHX_ rm, "schema_url");
    SSize_t i, c;
    if (res) {
        size_t s = otel_resource_size(aTHX_ res), mark;
        otel_pb_msg_head(b, PB_RESOURCEMETRICS_RESOURCE, s);
        mark = b->len;
        otel_resource_write(aTHX_ b, res);
        OTEL_PB_CHECK(b, mark, s, "Resource");
    }
    c = sms ? av_len(sms) + 1 : 0;
    for (i = 0; i < c; i++) {
        SV **e = av_fetch(sms, i, 0);
        HV *sm = otel_hv_of(aTHX_ (e ? *e : NULL));
        size_t s = otel_pb_scopemetrics_size(aTHX_ sm), mark;
        otel_pb_msg_head(b, PB_RESOURCEMETRICS_SCOPE_METRICS, s);
        mark = b->len;
        otel_pb_scopemetrics_write(aTHX_ b, sm);
        OTEL_PB_CHECK(b, mark, s, "ScopeMetrics");
    }
    if (url) { STRLEN l; const char *s = SvPV_const(url, l);
               otel_pb_bytes(b, PB_RESOURCEMETRICS_SCHEMA_URL, s, l); }
}

static SV *otel_encode_metrics(pTHX_ HV *payload) {
    otel_buf b;
    AV *rms = otel_h_av(aTHX_ payload, "resource_metrics");
    SSize_t i, c = rms ? av_len(rms) + 1 : 0;
    size_t total = 0;
    SV *out;
    for (i = 0; i < c; i++) {
        SV **e = av_fetch(rms, i, 0);
        total += otel_pb_msg_size(PB_EXPORT_METRICS_RESOURCE_METRICS,
                     otel_pb_resourcemetrics_size(aTHX_
                         otel_hv_of(aTHX_ (e ? *e : NULL))));
    }
    otel_buf_init(&b, total ? total : 64);
    for (i = 0; i < c; i++) {
        SV **e = av_fetch(rms, i, 0);
        HV *rm = otel_hv_of(aTHX_ (e ? *e : NULL));
        size_t s = otel_pb_resourcemetrics_size(aTHX_ rm), mark;
        otel_pb_msg_head(&b, PB_EXPORT_METRICS_RESOURCE_METRICS, s);
        mark = b.len;
        otel_pb_resourcemetrics_write(aTHX_ &b, rm);
        OTEL_PB_CHECK(&b, mark, s, "ResourceMetrics");
    }
    out = newSVpvn(b.buf, b.len);
    otel_buf_free(&b);
    return out;
}

/* ---- logs --------------------------------------------------------------- */

static size_t otel_pb_logrecord_size(pTHX_ HV *r) {
    size_t n = 0;
    SV *v;
    char t16[16], s8[8];
    STRLEN tl, sl;
    if (otel_h(aTHX_ r, "time_unix_nano"))
        n += otel_pb_fixed64_size(PB_LOGRECORD_TIME);
    if (otel_h(aTHX_ r, "observed_time_unix_nano"))
        n += otel_pb_fixed64_size(PB_LOGRECORD_OBSERVED_TIME);
    if ((v = otel_h(aTHX_ r, "severity_number")))
        n += otel_pb_int32_size(PB_LOGRECORD_SEVERITY_NUMBER, (int)SvIV(v));
    if ((v = otel_h(aTHX_ r, "severity_text"))) {
        STRLEN l; (void)SvPV_const(v, l);
        n += otel_pb_bytes_size(PB_LOGRECORD_SEVERITY_TEXT, l);
    }
    /* the body is an AnyValue, so a structured body is possible - not only a
     * string, which is what lets a record carry its fields as a map */
    if ((v = otel_h(aTHX_ r, "body")))
        n += otel_pb_msg_size(PB_LOGRECORD_BODY,
                              otel_anyvalue_body_size(aTHX_ v));
    n += otel_attrs_size(aTHX_ otel_h_hv(aTHX_ r, "attributes"),
                         PB_LOGRECORD_ATTRIBUTES);
    if (otel_id(aTHX_ r, "trace_id", 16, &tl, t16))
        n += otel_pb_bytes_size(PB_LOGRECORD_TRACE_ID, tl);
    if (otel_id(aTHX_ r, "span_id", 8, &sl, s8))
        n += otel_pb_bytes_size(PB_LOGRECORD_SPAN_ID, sl);
    return n;
}

static void otel_pb_logrecord_write(pTHX_ otel_buf *b, HV *r) {
    SV *v;
    char t16[16], s8[8];
    STRLEN tl, sl;
    const char *p;
    if ((v = otel_h(aTHX_ r, "time_unix_nano")))
        otel_pb_fixed64(b, PB_LOGRECORD_TIME, (U64TYPE)SvUV(v));
    if ((v = otel_h(aTHX_ r, "observed_time_unix_nano")))
        otel_pb_fixed64(b, PB_LOGRECORD_OBSERVED_TIME, (U64TYPE)SvUV(v));
    if ((v = otel_h(aTHX_ r, "severity_number")))
        otel_pb_int32(b, PB_LOGRECORD_SEVERITY_NUMBER, (int)SvIV(v));
    if ((v = otel_h(aTHX_ r, "severity_text"))) {
        STRLEN l; const char *s = SvPV_const(v, l);
        otel_pb_bytes(b, PB_LOGRECORD_SEVERITY_TEXT, s, l);
    }
    if ((v = otel_h(aTHX_ r, "body"))) {
        size_t s = otel_anyvalue_body_size(aTHX_ v), mark;
        otel_pb_msg_head(b, PB_LOGRECORD_BODY, s);
        mark = b->len;
        otel_anyvalue_body_write(aTHX_ b, v);
        OTEL_PB_CHECK(b, mark, s, "LogRecord.body");
    }
    otel_attrs_write(aTHX_ b, otel_h_hv(aTHX_ r, "attributes"),
                     PB_LOGRECORD_ATTRIBUTES);
    if ((p = otel_id(aTHX_ r, "trace_id", 16, &tl, t16)))
        otel_pb_bytes(b, PB_LOGRECORD_TRACE_ID, p, tl);
    if ((p = otel_id(aTHX_ r, "span_id", 8, &sl, s8)))
        otel_pb_bytes(b, PB_LOGRECORD_SPAN_ID, p, sl);
}

static size_t otel_pb_scopelogs_size(pTHX_ HV *sl) {
    size_t n = 0;
    HV *sc = otel_h_hv(aTHX_ sl, "scope");
    AV *rs = otel_h_av(aTHX_ sl, "log_records");
    SSize_t i, c;
    if (sc) n += otel_pb_msg_size(PB_SCOPELOGS_SCOPE,
                                  otel_scope_size(aTHX_ sc));
    c = rs ? av_len(rs) + 1 : 0;
    for (i = 0; i < c; i++) {
        SV **e = av_fetch(rs, i, 0);
        n += otel_pb_msg_size(PB_SCOPELOGS_RECORDS,
                 otel_pb_logrecord_size(aTHX_ otel_hv_of(aTHX_ (e?*e:NULL))));
    }
    {
        SV *url = otel_h(aTHX_ sl, "schema_url");
        if (url) { STRLEN l; (void)SvPV_const(url, l);
                   n += otel_pb_bytes_size(PB_SCOPELOGS_SCHEMA_URL, l); }
    }
    return n;
}

static void otel_pb_scopelogs_write(pTHX_ otel_buf *b, HV *sl) {
    HV *sc = otel_h_hv(aTHX_ sl, "scope");
    AV *rs = otel_h_av(aTHX_ sl, "log_records");
    SSize_t i, c;
    if (sc) {
        size_t s = otel_scope_size(aTHX_ sc), mark;
        otel_pb_msg_head(b, PB_SCOPELOGS_SCOPE, s);
        mark = b->len;
        otel_scope_write(aTHX_ b, sc);
        OTEL_PB_CHECK(b, mark, s, "Scope");
    }
    c = rs ? av_len(rs) + 1 : 0;
    for (i = 0; i < c; i++) {
        SV **e = av_fetch(rs, i, 0);
        HV *r = otel_hv_of(aTHX_ (e ? *e : NULL));
        size_t s = otel_pb_logrecord_size(aTHX_ r), mark;
        otel_pb_msg_head(b, PB_SCOPELOGS_RECORDS, s);
        mark = b->len;
        otel_pb_logrecord_write(aTHX_ b, r);
        OTEL_PB_CHECK(b, mark, s, "LogRecord");
    }
    {
        SV *url = otel_h(aTHX_ sl, "schema_url");
        if (url) { STRLEN l; const char *u = SvPV_const(url, l);
                   otel_pb_bytes(b, PB_SCOPELOGS_SCHEMA_URL, u, l); }
    }
}

static SV *otel_encode_logs(pTHX_ HV *payload) {
    otel_buf b;
    AV *rls = otel_h_av(aTHX_ payload, "resource_logs");
    SSize_t i, c = rls ? av_len(rls) + 1 : 0;
    size_t total = 0;
    SV *out;

    for (i = 0; i < c; i++) {
        SV **e = av_fetch(rls, i, 0);
        HV *rl = otel_hv_of(aTHX_ (e ? *e : NULL));
        HV *res = otel_h_hv(aTHX_ rl, "resource");
        AV *sls = otel_h_av(aTHX_ rl, "scope_logs");
        size_t inner = 0;
        SSize_t j, d = sls ? av_len(sls) + 1 : 0;
        if (res) inner += otel_pb_msg_size(PB_RESOURCELOGS_RESOURCE,
                                           otel_resource_size(aTHX_ res));
        for (j = 0; j < d; j++) {
            SV **s = av_fetch(sls, j, 0);
            inner += otel_pb_msg_size(PB_RESOURCELOGS_SCOPE_LOGS,
                         otel_pb_scopelogs_size(aTHX_
                             otel_hv_of(aTHX_ (s ? *s : NULL))));
        }
        {
            SV *url = otel_h(aTHX_ rl, "schema_url");
            if (url) { STRLEN l; (void)SvPV_const(url, l);
                       inner += otel_pb_bytes_size(PB_RESOURCELOGS_SCHEMA_URL, l); }
        }
        total += otel_pb_msg_size(PB_EXPORT_LOGS_RESOURCE_LOGS, inner);
    }

    otel_buf_init(&b, total ? total : 64);
    for (i = 0; i < c; i++) {
        SV **e = av_fetch(rls, i, 0);
        HV *rl = otel_hv_of(aTHX_ (e ? *e : NULL));
        HV *res = otel_h_hv(aTHX_ rl, "resource");
        AV *sls = otel_h_av(aTHX_ rl, "scope_logs");
        size_t inner = 0, mark;
        SSize_t j, d = sls ? av_len(sls) + 1 : 0;
        if (res) inner += otel_pb_msg_size(PB_RESOURCELOGS_RESOURCE,
                                           otel_resource_size(aTHX_ res));
        for (j = 0; j < d; j++) {
            SV **s = av_fetch(sls, j, 0);
            inner += otel_pb_msg_size(PB_RESOURCELOGS_SCOPE_LOGS,
                         otel_pb_scopelogs_size(aTHX_
                             otel_hv_of(aTHX_ (s ? *s : NULL))));
        }
        {
            SV *url = otel_h(aTHX_ rl, "schema_url");
            if (url) { STRLEN l; (void)SvPV_const(url, l);
                       inner += otel_pb_bytes_size(PB_RESOURCELOGS_SCHEMA_URL, l); }
        }
        otel_pb_msg_head(&b, PB_EXPORT_LOGS_RESOURCE_LOGS, inner);
        mark = b.len;
        if (res) {
            size_t rs = otel_resource_size(aTHX_ res), m2;
            otel_pb_msg_head(&b, PB_RESOURCELOGS_RESOURCE, rs);
            m2 = b.len;
            otel_resource_write(aTHX_ &b, res);
            OTEL_PB_CHECK(&b, m2, rs, "Resource");
        }
        for (j = 0; j < d; j++) {
            SV **s = av_fetch(sls, j, 0);
            HV *sl = otel_hv_of(aTHX_ (s ? *s : NULL));
            size_t ss = otel_pb_scopelogs_size(aTHX_ sl), m2;
            otel_pb_msg_head(&b, PB_RESOURCELOGS_SCOPE_LOGS, ss);
            m2 = b.len;
            otel_pb_scopelogs_write(aTHX_ &b, sl);
            OTEL_PB_CHECK(&b, m2, ss, "ScopeLogs");
        }
        {
            SV *url = otel_h(aTHX_ rl, "schema_url");
            if (url) { STRLEN l; const char *u = SvPV_const(url, l);
                       otel_pb_bytes(&b, PB_RESOURCELOGS_SCHEMA_URL, u, l); }
        }
        OTEL_PB_CHECK(&b, mark, inner, "ResourceLogs");
    }
    out = newSVpvn(b.buf, b.len);
    otel_buf_free(&b);
    return out;
}

#endif /* OTEL_SIGNAL_PB_H */

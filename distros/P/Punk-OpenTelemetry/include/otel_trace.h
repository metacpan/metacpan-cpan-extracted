/* otel_trace.h - the OTLP trace message tree, in protobuf.
 *
 * ExportTraceServiceRequest
 *   ResourceSpans     resource, scope_spans[], schema_url
 *     Resource        attributes[]
 *     ScopeSpans      scope, spans[], schema_url
 *       Scope         name, version, attributes[]
 *       Span          ids, name, kind, times, attributes[], events[],
 *                     links[], status, flags
 *
 * The input is a Perl hashref shaped for a human to write and for phase 3's
 * span structs to fill in cheaply; see Punk::OpenTelemetry::OTLP for the
 * shape. Everything below is the usual two passes: a size_ function beside
 * each write_ function, agreeing byte for byte.
 */

#ifndef OTEL_TRACE_H
#define OTEL_TRACE_H

#include "otel_pb.h"
#include "otel_proto.h"
#include "otel_value.h"

/* ---- small readers over the input hash ---------------------------------- */

static SV *otel_h(pTHX_ HV *h, const char *k) {
    SV **e = h ? hv_fetch(h, k, (I32)strlen(k), 0) : NULL;
    return (e && *e && SvOK(*e)) ? *e : NULL;
}
static HV *otel_h_hv(pTHX_ HV *h, const char *k) {
    SV *v = otel_h(aTHX_ h, k);
    return (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) ? (HV *)SvRV(v) : NULL;
}
static AV *otel_h_av(pTHX_ HV *h, const char *k) {
    SV *v = otel_h(aTHX_ h, k);
    return (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) ? (AV *)SvRV(v) : NULL;
}
static HV *otel_hv_of(pTHX_ SV *v) {
    return (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) ? (HV *)SvRV(v) : NULL;
}

/* A trace or span id as raw bytes. Accepts the binary form (what the C SDK
 * holds) and the hex form (what a human writes in a test), because getting
 * this wrong is invisible: a 32-character hex string encoded as bytes is a
 * valid-looking id of the wrong length that no collector will join to
 * anything. `want` is the byte length the field requires. */
static const char *otel_id(pTHX_ HV *h, const char *k, STRLEN want,
                           STRLEN *out, char *scratch) {
    SV *v = otel_h(aTHX_ h, k);
    STRLEN l;
    const char *s;
    STRLEN i;
    *out = 0;
    if (!v) return NULL;
    s = SvPV_const(v, l);
    if (l == want) { *out = l; return s; }        /* already bytes */
    if (l == want * 2) {                           /* hex */
        for (i = 0; i < want; i++) {
            int hi = -1, lo = -1, j;
            for (j = 0; j < 2; j++) {
                char c = s[i * 2 + j];
                int d = (c >= '0' && c <= '9') ? c - '0'
                      : (c >= 'a' && c <= 'f') ? c - 'a' + 10
                      : (c >= 'A' && c <= 'F') ? c - 'A' + 10 : -1;
                if (d < 0) return NULL;            /* not hex after all */
                if (j == 0) hi = d; else lo = d;
            }
            scratch[i] = (char)((hi << 4) | lo);
        }
        *out = want;
        return scratch;
    }
    return NULL;                                   /* wrong length: omit it */
}

/* ---- Status ------------------------------------------------------------- */

static size_t otel_status_size(pTHX_ HV *st) {
    size_t n = 0;
    SV *msg, *code;
    if (!st) return 0;
    msg  = otel_h(aTHX_ st, "message");
    code = otel_h(aTHX_ st, "code");
    if (msg) { STRLEN l; (void)SvPV_const(msg, l);
               n += otel_pb_bytes_size(PB_STATUS_MESSAGE, l); }
    /* UNSET is the proto3 default and is never written - which is the point:
     * an instrumentation layer with no opinion must not claim success */
    if (code && SvIV(code) != OTEL_STATUS_UNSET)
        n += otel_pb_int32_size(PB_STATUS_CODE, (int)SvIV(code));
    return n;
}

static void otel_status_write(pTHX_ otel_buf *b, HV *st) {
    SV *msg, *code;
    if (!st) return;
    msg  = otel_h(aTHX_ st, "message");
    code = otel_h(aTHX_ st, "code");
    if (msg) { STRLEN l; const char *s = SvPV_const(msg, l);
               otel_pb_bytes(b, PB_STATUS_MESSAGE, s, l); }
    if (code && SvIV(code) != OTEL_STATUS_UNSET)
        otel_pb_int32(b, PB_STATUS_CODE, (int)SvIV(code));
}

/* ---- Event -------------------------------------------------------------- */

static size_t otel_event_size(pTHX_ HV *ev) {
    size_t n = 0;
    SV *t, *name, *dropped;
    if (!ev) return 0;
    t       = otel_h(aTHX_ ev, "time_unix_nano");
    name    = otel_h(aTHX_ ev, "name");
    dropped = otel_h(aTHX_ ev, "dropped_attributes_count");
    if (t)    n += otel_pb_fixed64_size(PB_EVENT_TIME);
    if (name) { STRLEN l; (void)SvPV_const(name, l);
                n += otel_pb_bytes_size(PB_EVENT_NAME, l); }
    n += otel_attrs_size(aTHX_ otel_h_hv(aTHX_ ev, "attributes"),
                         PB_EVENT_ATTRIBUTES);
    if (dropped && SvUV(dropped))
        n += otel_pb_uint64_size(PB_EVENT_DROPPED_ATTRS, SvUV(dropped));
    return n;
}

static void otel_event_write(pTHX_ otel_buf *b, HV *ev) {
    SV *t, *name, *dropped;
    if (!ev) return;
    t       = otel_h(aTHX_ ev, "time_unix_nano");
    name    = otel_h(aTHX_ ev, "name");
    dropped = otel_h(aTHX_ ev, "dropped_attributes_count");
    if (t)    otel_pb_fixed64(b, PB_EVENT_TIME, (U64TYPE)SvUV(t));
    if (name) { STRLEN l; const char *s = SvPV_const(name, l);
                otel_pb_bytes(b, PB_EVENT_NAME, s, l); }
    otel_attrs_write(aTHX_ b, otel_h_hv(aTHX_ ev, "attributes"),
                     PB_EVENT_ATTRIBUTES);
    if (dropped && SvUV(dropped))
        otel_pb_uint64(b, PB_EVENT_DROPPED_ATTRS, SvUV(dropped));
}

/* ---- Link --------------------------------------------------------------- */

static size_t otel_link_size(pTHX_ HV *ln) {
    size_t n = 0;
    char t16[16], s8[8];
    STRLEN tl, sl;
    SV *ts;
    if (!ln) return 0;
    if (otel_id(aTHX_ ln, "trace_id", 16, &tl, t16))
        n += otel_pb_bytes_size(PB_LINK_TRACE_ID, tl);
    if (otel_id(aTHX_ ln, "span_id", 8, &sl, s8))
        n += otel_pb_bytes_size(PB_LINK_SPAN_ID, sl);
    ts = otel_h(aTHX_ ln, "trace_state");
    if (ts) { STRLEN l; (void)SvPV_const(ts, l);
              n += otel_pb_bytes_size(PB_LINK_TRACE_STATE, l); }
    n += otel_attrs_size(aTHX_ otel_h_hv(aTHX_ ln, "attributes"),
                         PB_LINK_ATTRIBUTES);
    return n;
}

static void otel_link_write(pTHX_ otel_buf *b, HV *ln) {
    char t16[16], s8[8];
    STRLEN tl, sl;
    const char *tid, *sid;
    SV *ts;
    if (!ln) return;
    tid = otel_id(aTHX_ ln, "trace_id", 16, &tl, t16);
    if (tid) otel_pb_bytes(b, PB_LINK_TRACE_ID, tid, tl);
    sid = otel_id(aTHX_ ln, "span_id", 8, &sl, s8);
    if (sid) otel_pb_bytes(b, PB_LINK_SPAN_ID, sid, sl);
    ts = otel_h(aTHX_ ln, "trace_state");
    if (ts) { STRLEN l; const char *s = SvPV_const(ts, l);
              otel_pb_bytes(b, PB_LINK_TRACE_STATE, s, l); }
    otel_attrs_write(aTHX_ b, otel_h_hv(aTHX_ ln, "attributes"),
                     PB_LINK_ATTRIBUTES);
}

/* ---- Span --------------------------------------------------------------- */

static size_t otel_span_size(pTHX_ HV *sp) {
    size_t n = 0;
    char t16[16], s8[8], p8[8];
    STRLEN tl, sl, pl;
    SV *v;
    AV *av;
    SSize_t i, cnt;
    if (!sp) return 0;

    if (otel_id(aTHX_ sp, "trace_id", 16, &tl, t16))
        n += otel_pb_bytes_size(PB_SPAN_TRACE_ID, tl);
    if (otel_id(aTHX_ sp, "span_id", 8, &sl, s8))
        n += otel_pb_bytes_size(PB_SPAN_SPAN_ID, sl);
    if ((v = otel_h(aTHX_ sp, "trace_state"))) {
        STRLEN l; (void)SvPV_const(v, l);
        n += otel_pb_bytes_size(PB_SPAN_TRACE_STATE, l);
    }
    if (otel_id(aTHX_ sp, "parent_span_id", 8, &pl, p8))
        n += otel_pb_bytes_size(PB_SPAN_PARENT_SPAN_ID, pl);
    if ((v = otel_h(aTHX_ sp, "name"))) {
        STRLEN l; (void)SvPV_const(v, l);
        n += otel_pb_bytes_size(PB_SPAN_NAME, l);
    }
    if ((v = otel_h(aTHX_ sp, "kind")) && SvIV(v) != OTEL_KIND_UNSPECIFIED)
        n += otel_pb_int32_size(PB_SPAN_KIND, (int)SvIV(v));
    if (otel_h(aTHX_ sp, "start_time_unix_nano"))
        n += otel_pb_fixed64_size(PB_SPAN_START_TIME);
    if (otel_h(aTHX_ sp, "end_time_unix_nano"))
        n += otel_pb_fixed64_size(PB_SPAN_END_TIME);

    n += otel_attrs_size(aTHX_ otel_h_hv(aTHX_ sp, "attributes"),
                         PB_SPAN_ATTRIBUTES);
    if ((v = otel_h(aTHX_ sp, "dropped_attributes_count")) && SvUV(v))
        n += otel_pb_uint64_size(PB_SPAN_DROPPED_ATTRS, SvUV(v));

    if ((av = otel_h_av(aTHX_ sp, "events"))) {
        cnt = av_len(av) + 1;
        for (i = 0; i < cnt; i++) {
            SV **e = av_fetch(av, i, 0);
            n += otel_pb_msg_size(PB_SPAN_EVENTS,
                     otel_event_size(aTHX_ otel_hv_of(aTHX_ (e ? *e : NULL))));
        }
    }
    if ((v = otel_h(aTHX_ sp, "dropped_events_count")) && SvUV(v))
        n += otel_pb_uint64_size(PB_SPAN_DROPPED_EVENTS, SvUV(v));

    if ((av = otel_h_av(aTHX_ sp, "links"))) {
        cnt = av_len(av) + 1;
        for (i = 0; i < cnt; i++) {
            SV **e = av_fetch(av, i, 0);
            n += otel_pb_msg_size(PB_SPAN_LINKS,
                     otel_link_size(aTHX_ otel_hv_of(aTHX_ (e ? *e : NULL))));
        }
    }
    if ((v = otel_h(aTHX_ sp, "dropped_links_count")) && SvUV(v))
        n += otel_pb_uint64_size(PB_SPAN_DROPPED_LINKS, SvUV(v));

    {
        HV *st = otel_h_hv(aTHX_ sp, "status");
        size_t ssz = otel_status_size(aTHX_ st);
        if (st && ssz) n += otel_pb_msg_size(PB_SPAN_STATUS, ssz);
    }
    if ((v = otel_h(aTHX_ sp, "flags")) && SvUV(v))
        n += otel_pb_uint64_size(PB_SPAN_FLAGS, SvUV(v));
    return n;
}

static void otel_span_write(pTHX_ otel_buf *b, HV *sp) {
    char t16[16], s8[8], p8[8];
    STRLEN tl, sl, pl;
    const char *id;
    SV *v;
    AV *av;
    SSize_t i, cnt;
    if (!sp) return;

    if ((id = otel_id(aTHX_ sp, "trace_id", 16, &tl, t16)))
        otel_pb_bytes(b, PB_SPAN_TRACE_ID, id, tl);
    if ((id = otel_id(aTHX_ sp, "span_id", 8, &sl, s8)))
        otel_pb_bytes(b, PB_SPAN_SPAN_ID, id, sl);
    if ((v = otel_h(aTHX_ sp, "trace_state"))) {
        STRLEN l; const char *s = SvPV_const(v, l);
        otel_pb_bytes(b, PB_SPAN_TRACE_STATE, s, l);
    }
    if ((id = otel_id(aTHX_ sp, "parent_span_id", 8, &pl, p8)))
        otel_pb_bytes(b, PB_SPAN_PARENT_SPAN_ID, id, pl);
    if ((v = otel_h(aTHX_ sp, "name"))) {
        STRLEN l; const char *s = SvPV_const(v, l);
        otel_pb_bytes(b, PB_SPAN_NAME, s, l);
    }
    if ((v = otel_h(aTHX_ sp, "kind")) && SvIV(v) != OTEL_KIND_UNSPECIFIED)
        otel_pb_int32(b, PB_SPAN_KIND, (int)SvIV(v));
    if ((v = otel_h(aTHX_ sp, "start_time_unix_nano")))
        otel_pb_fixed64(b, PB_SPAN_START_TIME, (U64TYPE)SvUV(v));
    if ((v = otel_h(aTHX_ sp, "end_time_unix_nano")))
        otel_pb_fixed64(b, PB_SPAN_END_TIME, (U64TYPE)SvUV(v));

    otel_attrs_write(aTHX_ b, otel_h_hv(aTHX_ sp, "attributes"),
                     PB_SPAN_ATTRIBUTES);
    if ((v = otel_h(aTHX_ sp, "dropped_attributes_count")) && SvUV(v))
        otel_pb_uint64(b, PB_SPAN_DROPPED_ATTRS, SvUV(v));

    if ((av = otel_h_av(aTHX_ sp, "events"))) {
        cnt = av_len(av) + 1;
        for (i = 0; i < cnt; i++) {
            SV **e = av_fetch(av, i, 0);
            HV *ev = otel_hv_of(aTHX_ (e ? *e : NULL));
            size_t esz = otel_event_size(aTHX_ ev);
            size_t mark;
            otel_pb_msg_head(b, PB_SPAN_EVENTS, esz);
            mark = b->len;
            otel_event_write(aTHX_ b, ev);
            OTEL_PB_CHECK(b, mark, esz, "Span.Event");
        }
    }
    if ((v = otel_h(aTHX_ sp, "dropped_events_count")) && SvUV(v))
        otel_pb_uint64(b, PB_SPAN_DROPPED_EVENTS, SvUV(v));

    if ((av = otel_h_av(aTHX_ sp, "links"))) {
        cnt = av_len(av) + 1;
        for (i = 0; i < cnt; i++) {
            SV **e = av_fetch(av, i, 0);
            HV *ln = otel_hv_of(aTHX_ (e ? *e : NULL));
            size_t lsz = otel_link_size(aTHX_ ln);
            size_t mark;
            otel_pb_msg_head(b, PB_SPAN_LINKS, lsz);
            mark = b->len;
            otel_link_write(aTHX_ b, ln);
            OTEL_PB_CHECK(b, mark, lsz, "Span.Link");
        }
    }
    if ((v = otel_h(aTHX_ sp, "dropped_links_count")) && SvUV(v))
        otel_pb_uint64(b, PB_SPAN_DROPPED_LINKS, SvUV(v));

    {
        HV *st = otel_h_hv(aTHX_ sp, "status");
        size_t ssz = otel_status_size(aTHX_ st);
        if (st && ssz) {
            size_t mark;
            otel_pb_msg_head(b, PB_SPAN_STATUS, ssz);
            mark = b->len;
            otel_status_write(aTHX_ b, st);
            OTEL_PB_CHECK(b, mark, ssz, "Span.Status");
        }
    }
    if ((v = otel_h(aTHX_ sp, "flags")) && SvUV(v))
        otel_pb_uint64(b, PB_SPAN_FLAGS, SvUV(v));
}

/* ---- InstrumentationScope ----------------------------------------------- */

static size_t otel_scope_size(pTHX_ HV *sc) {
    size_t n = 0;
    SV *v;
    if (!sc) return 0;
    if ((v = otel_h(aTHX_ sc, "name"))) {
        STRLEN l; (void)SvPV_const(v, l);
        n += otel_pb_bytes_size(PB_SCOPE_NAME, l);
    }
    if ((v = otel_h(aTHX_ sc, "version"))) {
        STRLEN l; (void)SvPV_const(v, l);
        n += otel_pb_bytes_size(PB_SCOPE_VERSION, l);
    }
    n += otel_attrs_size(aTHX_ otel_h_hv(aTHX_ sc, "attributes"),
                         PB_SCOPE_ATTRIBUTES);
    return n;
}

static void otel_scope_write(pTHX_ otel_buf *b, HV *sc) {
    SV *v;
    if (!sc) return;
    if ((v = otel_h(aTHX_ sc, "name"))) {
        STRLEN l; const char *s = SvPV_const(v, l);
        otel_pb_bytes(b, PB_SCOPE_NAME, s, l);
    }
    if ((v = otel_h(aTHX_ sc, "version"))) {
        STRLEN l; const char *s = SvPV_const(v, l);
        otel_pb_bytes(b, PB_SCOPE_VERSION, s, l);
    }
    otel_attrs_write(aTHX_ b, otel_h_hv(aTHX_ sc, "attributes"),
                     PB_SCOPE_ATTRIBUTES);
}

/* ---- ScopeSpans / Resource / ResourceSpans ------------------------------ */

static size_t otel_scopespans_size(pTHX_ HV *ss) {
    size_t n = 0;
    HV *sc = otel_h_hv(aTHX_ ss, "scope");
    AV *spans = otel_h_av(aTHX_ ss, "spans");
    SV *url = otel_h(aTHX_ ss, "schema_url");
    SSize_t i, cnt;
    if (sc) {
        size_t s = otel_scope_size(aTHX_ sc);
        n += otel_pb_msg_size(PB_SCOPESPANS_SCOPE, s);
    }
    if (spans) {
        cnt = av_len(spans) + 1;
        for (i = 0; i < cnt; i++) {
            SV **e = av_fetch(spans, i, 0);
            n += otel_pb_msg_size(PB_SCOPESPANS_SPANS,
                     otel_span_size(aTHX_ otel_hv_of(aTHX_ (e ? *e : NULL))));
        }
    }
    if (url) { STRLEN l; (void)SvPV_const(url, l);
               n += otel_pb_bytes_size(PB_SCOPESPANS_SCHEMA_URL, l); }
    return n;
}

static void otel_scopespans_write(pTHX_ otel_buf *b, HV *ss) {
    HV *sc = otel_h_hv(aTHX_ ss, "scope");
    AV *spans = otel_h_av(aTHX_ ss, "spans");
    SV *url = otel_h(aTHX_ ss, "schema_url");
    SSize_t i, cnt;
    if (sc) {
        size_t s = otel_scope_size(aTHX_ sc), mark;
        otel_pb_msg_head(b, PB_SCOPESPANS_SCOPE, s);
        mark = b->len;
        otel_scope_write(aTHX_ b, sc);
        OTEL_PB_CHECK(b, mark, s, "InstrumentationScope");
    }
    if (spans) {
        cnt = av_len(spans) + 1;
        for (i = 0; i < cnt; i++) {
            SV **e = av_fetch(spans, i, 0);
            HV *sp = otel_hv_of(aTHX_ (e ? *e : NULL));
            size_t ssz = otel_span_size(aTHX_ sp), mark;
            otel_pb_msg_head(b, PB_SCOPESPANS_SPANS, ssz);
            mark = b->len;
            otel_span_write(aTHX_ b, sp);
            OTEL_PB_CHECK(b, mark, ssz, "Span");
        }
    }
    if (url) { STRLEN l; const char *s = SvPV_const(url, l);
               otel_pb_bytes(b, PB_SCOPESPANS_SCHEMA_URL, s, l); }
}

static size_t otel_resource_size(pTHX_ HV *res) {
    if (!res) return 0;
    return otel_attrs_size(aTHX_ otel_h_hv(aTHX_ res, "attributes"),
                           PB_RESOURCE_ATTRIBUTES);
}
static void otel_resource_write(pTHX_ otel_buf *b, HV *res) {
    if (!res) return;
    otel_attrs_write(aTHX_ b, otel_h_hv(aTHX_ res, "attributes"),
                     PB_RESOURCE_ATTRIBUTES);
}

static size_t otel_resourcespans_size(pTHX_ HV *rs) {
    size_t n = 0;
    HV *res = otel_h_hv(aTHX_ rs, "resource");
    AV *sss = otel_h_av(aTHX_ rs, "scope_spans");
    SV *url = otel_h(aTHX_ rs, "schema_url");
    SSize_t i, cnt;
    if (res)
        n += otel_pb_msg_size(PB_RESOURCESPANS_RESOURCE,
                              otel_resource_size(aTHX_ res));
    if (sss) {
        cnt = av_len(sss) + 1;
        for (i = 0; i < cnt; i++) {
            SV **e = av_fetch(sss, i, 0);
            n += otel_pb_msg_size(PB_RESOURCESPANS_SCOPE_SPANS,
                     otel_scopespans_size(aTHX_ otel_hv_of(aTHX_ (e ? *e : NULL))));
        }
    }
    if (url) { STRLEN l; (void)SvPV_const(url, l);
               n += otel_pb_bytes_size(PB_RESOURCESPANS_SCHEMA_URL, l); }
    return n;
}

static void otel_resourcespans_write(pTHX_ otel_buf *b, HV *rs) {
    HV *res = otel_h_hv(aTHX_ rs, "resource");
    AV *sss = otel_h_av(aTHX_ rs, "scope_spans");
    SV *url = otel_h(aTHX_ rs, "schema_url");
    SSize_t i, cnt;
    if (res) {
        size_t s = otel_resource_size(aTHX_ res), mark;
        otel_pb_msg_head(b, PB_RESOURCESPANS_RESOURCE, s);
        mark = b->len;
        otel_resource_write(aTHX_ b, res);
        OTEL_PB_CHECK(b, mark, s, "Resource");
    }
    if (sss) {
        cnt = av_len(sss) + 1;
        for (i = 0; i < cnt; i++) {
            SV **e = av_fetch(sss, i, 0);
            HV *ss = otel_hv_of(aTHX_ (e ? *e : NULL));
            size_t s = otel_scopespans_size(aTHX_ ss), mark;
            otel_pb_msg_head(b, PB_RESOURCESPANS_SCOPE_SPANS, s);
            mark = b->len;
            otel_scopespans_write(aTHX_ b, ss);
            OTEL_PB_CHECK(b, mark, s, "ScopeSpans");
        }
    }
    if (url) { STRLEN l; const char *s = SvPV_const(url, l);
               otel_pb_bytes(b, PB_RESOURCESPANS_SCHEMA_URL, s, l); }
}

/* ---- ExportTraceServiceRequest ------------------------------------------ *
 * The top of the tree. Takes { resource_spans => [ ... ] } and returns the
 * bytes as a new SV (+1 owned). */
static SV *otel_encode_traces(pTHX_ HV *payload) {
    otel_buf b;
    AV *rss = otel_h_av(aTHX_ payload, "resource_spans");
    SSize_t i, cnt = rss ? av_len(rss) + 1 : 0;
    size_t total = 0;
    SV *out;

    for (i = 0; i < cnt; i++) {
        SV **e = av_fetch(rss, i, 0);
        total += otel_pb_msg_size(PB_EXPORT_TRACE_RESOURCE_SPANS,
                     otel_resourcespans_size(aTHX_ otel_hv_of(aTHX_ (e ? *e : NULL))));
    }
    otel_buf_init(&b, total ? total : 64);
    for (i = 0; i < cnt; i++) {
        SV **e = av_fetch(rss, i, 0);
        HV *rs = otel_hv_of(aTHX_ (e ? *e : NULL));
        size_t s = otel_resourcespans_size(aTHX_ rs), mark;
        otel_pb_msg_head(&b, PB_EXPORT_TRACE_RESOURCE_SPANS, s);
        mark = b.len;
        otel_resourcespans_write(aTHX_ &b, rs);
        OTEL_PB_CHECK(&b, mark, s, "ResourceSpans");
    }
    out = newSVpvn(b.buf, b.len);
    otel_buf_free(&b);
    return out;
}

#endif /* OTEL_TRACE_H */

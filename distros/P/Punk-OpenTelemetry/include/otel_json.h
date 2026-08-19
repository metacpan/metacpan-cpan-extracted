/* otel_json.h - OTLP/JSON.
 *
 * The debuggable transport, and the one people paste into a bug report. It is
 * a supported OTLP encoding, not a convenience, so it has to be exactly
 * right - and it is NOT a naive rendering of the protobuf tree. Four rules
 * separate JSON that a collector accepts from JSON that merely looks correct:
 *
 *   1. FIELD NAMES ARE lowerCamelCase. proto3's JSON mapping renames every
 *      field: start_time_unix_nano becomes startTimeUnixNano. A payload with
 *      snake_case keys parses as a message with every field absent, which is
 *      accepted, stored, and empty.
 *
 *   2. trace_id AND span_id ARE HEX, not base64. proto3 maps `bytes` to
 *      base64, and OTLP explicitly overrides it for these two. Base64 ids are
 *      the single most common way a hand-written OTLP/JSON payload silently
 *      joins to nothing.
 *
 *   3. 64-BIT INTEGERS ARE STRINGS. proto3 maps int64/uint64/fixed64 to JSON
 *      strings, because IEEE-754 doubles cannot hold them: a nanosecond
 *      timestamp is ~1.7e18 and loses its last two digits as a JSON number.
 *      Not a portability nicety - the timestamps are wrong.
 *
 *   4. ENUMS ARE NAMES. SPAN_KIND_SERVER, not 2.
 *
 * Values are classified by otel_value_kind, the same function the protobuf
 * encoder uses, so the two cannot disagree about whether something is an int
 * or a string. Only the rendering differs.
 *
 * The output structure is built as ordinary Perl data and handed to
 * File::Raw::JSON. This is the debug path, not the hot one; the protobuf
 * encoder is what runs in production, and duplicating a JSON serialiser to
 * save allocations on a path nobody benchmarks would be the wrong trade.
 */

#ifndef OTEL_JSON_H
#define OTEL_JSON_H

#include "otel_proto.h"
#include "otel_value.h"

/* A 64-bit value as a decimal STRING (rule 3). */
static SV *otel_json_u64(pTHX_ UV v) {
    char buf[24];
    int n = my_snprintf(buf, sizeof buf, "%" UVuf, v);
    return newSVpvn(buf, n);
}

/* Raw bytes as lowercase hex (rule 2). */
static SV *otel_json_hex(pTHX_ const char *p, STRLEN n) {
    static const char H[] = "0123456789abcdef";
    SV *out = newSV(n * 2 + 1);
    STRLEN i;
    char *d;
    SvPOK_on(out);
    d = SvPVX(out);
    for (i = 0; i < n; i++) {
        d[i * 2]     = H[(unsigned char)p[i] >> 4];
        d[i * 2 + 1] = H[(unsigned char)p[i] & 0xf];
    }
    SvCUR_set(out, n * 2);
    d[n * 2] = '\0';
    return out;
}

static const char *otel_json_kind_name(IV k) {
    switch (k) {
        case OTEL_KIND_INTERNAL: return "SPAN_KIND_INTERNAL";
        case OTEL_KIND_SERVER:   return "SPAN_KIND_SERVER";
        case OTEL_KIND_CLIENT:   return "SPAN_KIND_CLIENT";
        case OTEL_KIND_PRODUCER: return "SPAN_KIND_PRODUCER";
        case OTEL_KIND_CONSUMER: return "SPAN_KIND_CONSUMER";
        default:                 return "SPAN_KIND_UNSPECIFIED";
    }
}

static const char *otel_json_status_name(IV c) {
    switch (c) {
        case OTEL_STATUS_OK:    return "STATUS_CODE_OK";
        case OTEL_STATUS_ERROR: return "STATUS_CODE_ERROR";
        default:                return "STATUS_CODE_UNSET";
    }
}

/* ---- AnyValue ----------------------------------------------------------- *
 * { "stringValue": "x" } / { "intValue": "42" } / { "boolValue": true } /
 * { "arrayValue": { "values": [...] } } / { "kvlistValue": { "values": [...] } }
 *
 * Note intValue is a STRING here too: it is an int64 in the schema. */
static SV *otel_json_anyvalue(pTHX_ SV *v);

static AV *otel_json_kvlist(pTHX_ HV *hv) {
    AV *out = newAV();
    AV *keys = otel_attr_keys(aTHX_ hv);   /* sorted, as the protobuf side is */
    SSize_t i, n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV **kp = av_fetch(keys, i, 0);
        HE *e;
        HV *kv;
        if (!(kp && *kp)) continue;
        e  = hv_fetch_ent(hv, *kp, 0, 0);
        kv = newHV();
        (void)hv_stores(kv, "key", newSVsv(*kp));
        (void)hv_stores(kv, "value",
                        otel_json_anyvalue(aTHX_ e ? HeVAL(e) : NULL));
        av_push(out, newRV_noinc((SV *)kv));
    }
    return out;
}

static SV *otel_json_anyvalue(pTHX_ SV *v) {
    HV *o = newHV();
    switch (otel_value_kind(aTHX_ v)) {
        case OTV_NULL:
            break;                          /* {} - nothing set */
        case OTV_BOOL:
            /* a REF to 0 or 1, not a copy of PL_sv_yes: File::Raw::JSON's
             * boolean convention is the scalar ref, and PL_sv_yes serialises
             * as the number 1 - which is a different JSON type and a
             * different thing to a collector */
            (void)hv_stores(o, "boolValue",
                newRV_noinc(newSViv(SvIVX(SvRV(v)) ? 1 : 0)));
            break;
        case OTV_INT:
            (void)hv_stores(o, "intValue", otel_json_u64(aTHX_ (UV)SvIVX(v)));
            break;
        case OTV_DOUBLE:
            (void)hv_stores(o, "doubleValue", newSVnv(SvNVX(v)));
            break;
        case OTV_ARRAY: {
            AV *src = (AV *)SvRV(v);
            AV *vals = newAV();
            HV *wrap = newHV();
            SSize_t i, n = av_len(src) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(src, i, 0);
                av_push(vals, otel_json_anyvalue(aTHX_ (e ? *e : NULL)));
            }
            (void)hv_stores(wrap, "values", newRV_noinc((SV *)vals));
            (void)hv_stores(o, "arrayValue", newRV_noinc((SV *)wrap));
            break;
        }
        case OTV_KVLIST: {
            HV *wrap = newHV();
            (void)hv_stores(wrap, "values",
                newRV_noinc((SV *)otel_json_kvlist(aTHX_ (HV *)SvRV(v))));
            (void)hv_stores(o, "kvlistValue", newRV_noinc((SV *)wrap));
            break;
        }
        default: {
            STRLEN l;
            const char *s = SvPV_const(v, l);
            (void)hv_stores(o, "stringValue", newSVpvn(s, l));
            break;
        }
    }
    return newRV_noinc((SV *)o);
}

/* ---- helpers over the input --------------------------------------------- */

static void otel_json_attrs(pTHX_ HV *dst, HV *src, const char *key) {
    if (!src || !HvUSEDKEYS(src)) return;
    (void)hv_store(dst, key, (I32)strlen(key),
                   newRV_noinc((SV *)otel_json_kvlist(aTHX_ src)), 0);
}

/* copy a string field across under its lowerCamelCase name */
static void otel_json_str(pTHX_ HV *dst, const char *jkey, HV *src,
                          const char *skey) {
    SV *v = otel_h(aTHX_ src, skey);
    if (v) (void)hv_store(dst, jkey, (I32)strlen(jkey), newSVsv(v), 0);
}

/* a nanosecond field, as a decimal string (rule 3) */
static void otel_json_nanos(pTHX_ HV *dst, const char *jkey, HV *src,
                            const char *skey) {
    SV *v = otel_h(aTHX_ src, skey);
    if (v) (void)hv_store(dst, jkey, (I32)strlen(jkey),
                          otel_json_u64(aTHX_ SvUV(v)), 0);
}

/* an id field, as hex (rule 2), accepting bytes or hex in */
static void otel_json_id(pTHX_ HV *dst, const char *jkey, HV *src,
                         const char *skey, STRLEN want) {
    char scratch[16];
    STRLEN got;
    const char *p = otel_id(aTHX_ src, skey, want, &got, scratch);
    if (p) (void)hv_store(dst, jkey, (I32)strlen(jkey),
                          otel_json_hex(aTHX_ p, got), 0);
}

/* ---- the trace tree ----------------------------------------------------- */

static SV *otel_json_span(pTHX_ HV *sp) {
    HV *o = newHV();
    SV *v;
    AV *av;
    if (!sp) return newRV_noinc((SV *)o);

    otel_json_id(aTHX_ o, "traceId", sp, "trace_id", 16);
    otel_json_id(aTHX_ o, "spanId",  sp, "span_id", 8);
    otel_json_str(aTHX_ o, "traceState", sp, "trace_state");
    otel_json_id(aTHX_ o, "parentSpanId", sp, "parent_span_id", 8);
    otel_json_str(aTHX_ o, "name", sp, "name");
    if ((v = otel_h(aTHX_ sp, "kind")))
        (void)hv_stores(o, "kind", newSVpv(otel_json_kind_name(SvIV(v)), 0));
    otel_json_nanos(aTHX_ o, "startTimeUnixNano", sp, "start_time_unix_nano");
    otel_json_nanos(aTHX_ o, "endTimeUnixNano",   sp, "end_time_unix_nano");
    otel_json_attrs(aTHX_ o, otel_h_hv(aTHX_ sp, "attributes"), "attributes");

    if ((av = otel_h_av(aTHX_ sp, "events"))) {
        AV *out = newAV();
        SSize_t i, n = av_len(av) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            HV *ev = otel_hv_of(aTHX_ (e ? *e : NULL));
            HV *jo = newHV();
            if (ev) {
                otel_json_nanos(aTHX_ jo, "timeUnixNano", ev, "time_unix_nano");
                otel_json_str(aTHX_ jo, "name", ev, "name");
                otel_json_attrs(aTHX_ jo, otel_h_hv(aTHX_ ev, "attributes"),
                                "attributes");
            }
            av_push(out, newRV_noinc((SV *)jo));
        }
        (void)hv_stores(o, "events", newRV_noinc((SV *)out));
    }

    if ((av = otel_h_av(aTHX_ sp, "links"))) {
        AV *out = newAV();
        SSize_t i, n = av_len(av) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            HV *ln = otel_hv_of(aTHX_ (e ? *e : NULL));
            HV *jo = newHV();
            if (ln) {
                otel_json_id(aTHX_ jo, "traceId", ln, "trace_id", 16);
                otel_json_id(aTHX_ jo, "spanId",  ln, "span_id", 8);
                otel_json_str(aTHX_ jo, "traceState", ln, "trace_state");
                otel_json_attrs(aTHX_ jo, otel_h_hv(aTHX_ ln, "attributes"),
                                "attributes");
            }
            av_push(out, newRV_noinc((SV *)jo));
        }
        (void)hv_stores(o, "links", newRV_noinc((SV *)out));
    }

    {
        HV *st = otel_h_hv(aTHX_ sp, "status");
        if (st) {
            HV *jo = newHV();
            SV *code = otel_h(aTHX_ st, "code");
            otel_json_str(aTHX_ jo, "message", st, "message");
            if (code)
                (void)hv_stores(jo, "code",
                    newSVpv(otel_json_status_name(SvIV(code)), 0));
            (void)hv_stores(o, "status", newRV_noinc((SV *)jo));
        }
    }
    return newRV_noinc((SV *)o);
}

static SV *otel_json_traces_sv(pTHX_ HV *payload) {
    HV *root = newHV();
    AV *rss  = otel_h_av(aTHX_ payload, "resource_spans");
    AV *out  = newAV();
    SSize_t i, n = rss ? av_len(rss) + 1 : 0;

    for (i = 0; i < n; i++) {
        SV **e = av_fetch(rss, i, 0);
        HV *rs = otel_hv_of(aTHX_ (e ? *e : NULL));
        HV *jrs = newHV();
        HV *res;
        AV *sss;
        if (!rs) { av_push(out, newRV_noinc((SV *)jrs)); continue; }

        if ((res = otel_h_hv(aTHX_ rs, "resource"))) {
            HV *jr = newHV();
            otel_json_attrs(aTHX_ jr, otel_h_hv(aTHX_ res, "attributes"),
                            "attributes");
            (void)hv_stores(jrs, "resource", newRV_noinc((SV *)jr));
        }
        if ((sss = otel_h_av(aTHX_ rs, "scope_spans"))) {
            AV *jss = newAV();
            SSize_t j, m = av_len(sss) + 1;
            for (j = 0; j < m; j++) {
                SV **se = av_fetch(sss, j, 0);
                HV *ss = otel_hv_of(aTHX_ (se ? *se : NULL));
                HV *jo = newHV();
                HV *sc;
                AV *spans;
                if (ss && (sc = otel_h_hv(aTHX_ ss, "scope"))) {
                    HV *jsc = newHV();
                    otel_json_str(aTHX_ jsc, "name", sc, "name");
                    otel_json_str(aTHX_ jsc, "version", sc, "version");
                    otel_json_attrs(aTHX_ jsc,
                        otel_h_hv(aTHX_ sc, "attributes"), "attributes");
                    (void)hv_stores(jo, "scope", newRV_noinc((SV *)jsc));
                }
                if (ss && (spans = otel_h_av(aTHX_ ss, "spans"))) {
                    AV *jsp = newAV();
                    SSize_t k, c = av_len(spans) + 1;
                    for (k = 0; k < c; k++) {
                        SV **pe = av_fetch(spans, k, 0);
                        av_push(jsp, otel_json_span(aTHX_
                                    otel_hv_of(aTHX_ (pe ? *pe : NULL))));
                    }
                    (void)hv_stores(jo, "spans", newRV_noinc((SV *)jsp));
                }
                if (ss) otel_json_str(aTHX_ jo, "schemaUrl", ss, "schema_url");
                av_push(jss, newRV_noinc((SV *)jo));
            }
            (void)hv_stores(jrs, "scopeSpans", newRV_noinc((SV *)jss));
        }
        otel_json_str(aTHX_ jrs, "schemaUrl", rs, "schema_url");
        av_push(out, newRV_noinc((SV *)jrs));
    }
    (void)hv_stores(root, "resourceSpans", newRV_noinc((SV *)out));
    return newRV_noinc((SV *)root);
}

#endif /* OTEL_JSON_H */

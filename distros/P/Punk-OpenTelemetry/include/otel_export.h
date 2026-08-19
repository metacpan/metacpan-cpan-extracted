/* otel_export.h - the OTLP/HTTP transport, in C.
 *
 * Punk::OpenTelemetry::Exporter: endpoint resolution, the response
 * classification, the partial-success readers, the Retry-After parse and the
 * backoff policy. lib/Punk/OpenTelemetry/Exporter.pm is documentation.
 *
 * The object stays a blessed HASH with the same keys it always had - endpoint,
 * endpoints, protocol, headers, timeout, compression, max_retries, ua, stats -
 * because they are part of the interface: an application reads $e->{protocol}
 * and bumps $e->{stats}{dropped}, and a port that quietly turned those into
 * opaque slots would be a rewrite wearing a port's clothes.
 *
 * Needs otel_trace.h (otel_h / otel_h_hv, and the encoder this dispatches to)
 * and otel_json.h. otel_frj() comes from the root XS file.
 */

#ifndef OTEL_EXPORT_H
#define OTEL_EXPORT_H

/* The signal paths appended to a GENERAL endpoint. A per-signal endpoint is
 * used exactly as given; see otel_exp_endpoint_for. */
static const char *otel_exp_signal_path(const char *sig, STRLEN len) {
    if (len == 6 && memEQ(sig, "traces", 6))  return "/v1/traces";
    if (len == 7 && memEQ(sig, "metrics", 7)) return "/v1/metrics";
    if (len == 4 && memEQ(sig, "logs", 4))    return "/v1/logs";
    return "";
}

/* application/x-protobuf or application/json, or NULL for a protocol that is
 * neither - which is how new() knows to refuse it. */
static const char *otel_exp_content_type(const char *p, STRLEN len) {
    if (len == 13 && memEQ(p, "http/protobuf", 13)) return "application/x-protobuf";
    if (len == 9  && memEQ(p, "http/json", 9))      return "application/json";
    return NULL;
}

static int otel_exp_is_json(pTHX_ HV *self) {
    SV *p = otel_h(aTHX_ self, "protocol");
    STRLEN l;
    const char *s;
    if (!p) return 0;
    s = SvPV_const(p, l);
    return (l == 9 && memEQ(s, "http/json", 9));
}

/* The HTTP statuses OTLP says to retry. Everything else is permanent: drop it,
 * count it, and do not spend the next hour asking a collector that has already
 * said no. */
static int otel_exp_retryable(IV status) {
    return status == 429 || status == 502 || status == 503 || status == 504;
}

/* ---- the endpoint ------------------------------------------------------- *
 *
 * The asymmetry here is in the spec and surprises everybody exactly once: a
 * GENERAL endpoint has the signal path appended, while a PER-SIGNAL endpoint
 * is used exactly as given - including its path, and including a path that
 * does not end in /v1/traces. Appending to a per-signal endpoint would break
 * every collector deployed behind a path prefix. Returns a mortal SV, or NULL
 * when nothing is configured. */
static SV *otel_exp_endpoint_for(pTHX_ HV *self, SV *signal) {
    STRLEN sl;
    const char *sp = SvOK(signal) ? SvPV_const(signal, sl) : "";
    HV *eps;
    SV *base;
    STRLEN bl;
    const char *bp;
    SV *out;
    if (!SvOK(signal)) sl = 0;

    eps = otel_h_hv(aTHX_ self, "endpoints");
    if (eps) {
        SV **e = hv_fetch(eps, sp, (I32)sl, 0);
        /* truthiness, as the Perl did: an empty per-signal endpoint is not a
         * configured one and falls through to the general endpoint */
        if (e && *e && SvTRUE(*e)) return sv_2mortal(newSVsv(*e));
    }

    base = otel_h(aTHX_ self, "endpoint");
    if (!base) return NULL;
    bp = SvPV_const(base, bl);
    if (!bl) return NULL;
    while (bl > 0 && bp[bl - 1] == '/') bl--;      /* s{/+$}{} */
    out = sv_2mortal(newSVpvn(bp, bl));
    sv_catpv(out, otel_exp_signal_path(sp, sl));
    return out;
}

/* ---- partial success, protobuf ------------------------------------------ *
 *
 * A minimal protobuf reader for ONE message shape, because there is no general
 * decoder in this dist - the encoder only writes - and this shape is three
 * fields that will not change:
 *
 *   ExportTraceServiceResponse { partial_success = 1 }
 *   ExportTracePartialSuccess  { rejected_spans = 1, error_message = 2 }
 *
 * Every malformed or truncated input stops the walk and yields whatever was
 * gathered before it, exactly as the Perl did. That is not sloppiness: a
 * collector's response is not a place to start dying, and a body we cannot
 * read means "no partial success reported", which is the safe reading. */
typedef struct {
    int    have1, have2;
    UV     v1;                 /* field 1 as a varint  */
    const char *b1; STRLEN b1l;/* field 1 as bytes     */
    const char *b2; STRLEN b2l;/* field 2 as bytes     */
} otel_pbr;

static void otel_pbr_walk(const char *buf, STRLEN len, otel_pbr *out) {
    STRLEN pos = 0;
    Zero(out, 1, otel_pbr);
    while (pos < len) {
        UV tag = 0, field, wire;
        int shift = 0;
        for (;;) {
            unsigned char b;
            if (pos >= len) return;
            b = (unsigned char)buf[pos++];
            tag |= ((UV)(b & 0x7f)) << shift;
            if (!(b & 0x80)) break;
            shift += 7;
            if (shift > 63) return;
        }
        field = tag >> 3;
        wire  = tag & 7;
        if (wire == 0) {
            UV v = 0;
            int s = 0;
            for (;;) {
                unsigned char b;
                if (pos >= len) return;
                b = (unsigned char)buf[pos++];
                v |= ((UV)(b & 0x7f)) << s;
                if (!(b & 0x80)) break;
                s += 7;
                if (s > 63) return;
            }
            if (field == 1) { out->have1 = 1; out->v1 = v; out->b1 = NULL; }
        }
        else if (wire == 2) {
            UV dl = 0;
            int s = 0;
            for (;;) {
                unsigned char b;
                if (pos >= len) return;
                b = (unsigned char)buf[pos++];
                dl |= ((UV)(b & 0x7f)) << s;
                if (!(b & 0x80)) break;
                s += 7;
                if (s > 63) return;
            }
            if (dl > (UV)(len - pos)) return;
            if (field == 1) { out->have1 = 1; out->b1 = buf + pos; out->b1l = (STRLEN)dl; }
            else if (field == 2) { out->have2 = 1; out->b2 = buf + pos; out->b2l = (STRLEN)dl; }
            pos += (STRLEN)dl;
        }
        else if (wire == 1) { if (len - pos < 8) return; pos += 8; }
        else if (wire == 5) { if (len - pos < 4) return; pos += 4; }
        else return;
    }
}

/* { rejected => N, message => $s } as a mortal hashref, or NULL when the body
 * carries no partial_success at all. */
static SV *otel_exp_parse_partial(pTHX_ SV *body) {
    STRLEN len;
    const char *buf;
    otel_pbr top, ps;
    HV *out;
    if (!body || !SvOK(body)) return NULL;
    buf = SvPV_const(body, len);
    if (!len) return NULL;
    otel_pbr_walk(buf, len, &top);
    if (!top.have1 || !top.b1) return NULL;        /* no partial_success */
    otel_pbr_walk(top.b1, top.b1l, &ps);
    out = newHV();
    (void)hv_stores(out, "rejected",
                    newSVuv(ps.have1 && !ps.b1 ? ps.v1 : 0));
    (void)hv_stores(out, "message",
                    ps.have2 ? newSVpvn(ps.b2, ps.b2l) : newSV(0));
    return sv_2mortal(newRV_noinc((SV *)out));
}

/* The same, for OTLP/JSON: { partialSuccess: { rejectedSpans, errorMessage } }.
 * A body that does not decode is not an error here either - same reasoning. */
static SV *otel_exp_parse_partial_json(pTHX_ SV *body) {
    STRLEN len;
    const char *buf;
    SV *decoded;
    HV *top, *ps;
    SV **e;
    HV *out;
    if (!body || !SvOK(body)) return NULL;
    buf = SvPV_const(body, len);
    if (!len) return NULL;
    decoded = otel_frj(aTHX)->decode(aTHX_ buf, len, NULL);
    if (!decoded) return NULL;
    sv_2mortal(decoded);
    top = otel_hv_of(aTHX_ decoded);
    if (!top) return NULL;
    ps = otel_h_hv(aTHX_ top, "partialSuccess");
    if (!ps) return NULL;
    out = newHV();
    e = hv_fetchs(ps, "rejectedSpans", 0);
    (void)hv_stores(out, "rejected",
                    newSVuv((e && *e && SvOK(*e)) ? SvUV(*e) : 0));
    e = hv_fetchs(ps, "errorMessage", 0);
    (void)hv_stores(out, "message",
                    (e && *e && SvOK(*e)) ? newSVsv(*e) : newSV(0));
    return sv_2mortal(newRV_noinc((SV *)out));
}

/* ---- Retry-After -------------------------------------------------------- *
 *
 * Either a delta in seconds or an HTTP date. A collector under load is telling
 * us when to come back; ignoring it is how a fleet turns a slow collector into
 * a dead one. Returns a mortal SV, or NULL for "no usable value". */
static SV *otel_exp_retry_after(pTHX_ SV *headers) {
    SV *v = NULL;
    STRLEN l;
    const char *s;
    STRLEN i;
    int all_digits = 0;

    if (!headers || !SvROK(headers)) return NULL;
    if (SvTYPE(SvRV(headers)) == SVt_PVAV) {
        AV *av = (AV *)SvRV(headers);
        SSize_t j, n = av_len(av) + 1;
        for (j = 0; j + 1 < n; j += 2) {           /* first match wins */
            SV **k = av_fetch(av, j, 0);
            STRLEN kl;
            const char *kp;
            if (!(k && *k && SvOK(*k))) continue;
            kp = SvPV_const(*k, kl);
            if (kl == 11 && strnEQ(kp, "retry-after", 11)) {
                SV **vv = av_fetch(av, j + 1, 0);
                if (vv && *vv) v = *vv;
                break;
            }
            else if (kl == 11) {                   /* case-insensitively */
                STRLEN c;
                int same = 1;
                for (c = 0; c < 11; c++)
                    if (toLOWER(kp[c]) != "retry-after"[c]) { same = 0; break; }
                if (same) {
                    SV **vv = av_fetch(av, j + 1, 0);
                    if (vv && *vv) v = *vv;
                    break;
                }
            }
        }
    }
    else if (SvTYPE(SvRV(headers)) == SVt_PVHV) {
        HV *hv = (HV *)SvRV(headers);
        SV **e = hv_fetchs(hv, "retry-after", 0);
        if (!(e && *e && SvOK(*e))) e = hv_fetchs(hv, "Retry-After", 0);
        if (e && *e) v = *e;
    }
    if (!v || !SvOK(v)) return NULL;

    /* ^\s*\d+\s*$ - digits only, no sign and no decimal, as the Perl was */
    s = SvPV_const(v, l);
    {
        STRLEN a = 0, b = l;
        while (a < b && isSPACE(s[a])) a++;
        while (b > a && isSPACE(s[b - 1])) b--;
        if (b > a) {
            all_digits = 1;
            for (i = a; i < b; i++)
                if (!isDIGIT(s[i])) { all_digits = 0; break; }
        }
        if (all_digits) return sv_2mortal(newSVnv(Atof(s + a)));
    }

    /* an HTTP date, through HTTP::Date if it is there */
    {
        dSP; int count; SV *t = NULL;
        eval_pv("require HTTP::Date;", FALSE);
        SPAGAIN;
        if (SvTRUE(ERRSV)) return NULL;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(v); PUTBACK;
        count = call_pv("HTTP::Date::str2time", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (!SvTRUE(ERRSV) && count > 0) { SV *r = POPs; if (SvOK(r)) t = newSVsv(r); }
        else if (count > 0) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
        if (!t) return NULL;
        sv_2mortal(t);
        if (!SvTRUE(t)) return NULL;
        {
            NV d = SvNV(t) - (NV)time(NULL);
            return sv_2mortal(newSVnv(d > 0 ? d : 0));
        }
    }
}

/* ---- backoff ------------------------------------------------------------ *
 *
 * Exponential from one second to a thirty second ceiling, with FULL JITTER.
 * The jitter is not decoration: a fleet of workers that all failed at the same
 * moment and all back off by the same amount retries in a thundering herd,
 * which is how a collector that was briefly slow stays down.
 *
 * A Retry-After from the server wins outright - including one of 0, which is a
 * collector saying "come back now", not a missing value. */
static NV otel_exp_backoff(pTHX_ IV attempt, SV *retry_after) {
    NV exp;
    if (retry_after && SvOK(retry_after)) return SvNV(retry_after);
    exp = Perl_pow(2.0, (NV)(attempt - 1));
    if (!(exp <= 30.0)) exp = 30.0;      /* also catches a NaN attempt */
    return Drand01() * exp;
}

#endif /* OTEL_EXPORT_H */

MODULE = Punk::OpenTelemetry    PACKAGE = Punk::OpenTelemetry::Propagate

PROTOTYPES: DISABLE

# Context propagation. Every parser here is handed CLIENT-CONTROLLED BYTES on
# the hot path of every request, so none of them allocates based on a length
# the client supplied, and none of them croaks: a malformed header yields no
# context rather than an error, because a 500 for a bad trace header would be
# a denial of service with extra steps.

# extract(\%headers) -> { trace_id, span_id, sampled, flags, debug, format }
# or undef.
#
# %headers is the lowercased header name => value map. The propagators are
# tried in the order named by $order (comma-separated, default
# "tracecontext,baggage"), and a LATER one that finds a valid context
# overrides an earlier one - so "b3,tracecontext" and "tracecontext,b3"
# behave differently and both are reasonable things to configure.
SV *
extract(headers, order = &PL_sv_undef)
        SV *headers
        SV *order
    CODE:
    {
        HV *h;
        otel_ctx ctx, found;
        const char *ord;
        STRLEN ordlen, i;
        const char *fmt = NULL;
        int have = 0;

        if (!(SvROK(headers) && SvTYPE(SvRV(headers)) == SVt_PVHV))
            croak("Punk::OpenTelemetry::Propagate::extract: expected a hashref");
        h = (HV *)SvRV(headers);
        otel_ctx_clear(&found);

        ord = SvOK(order) ? SvPV_const(order, ordlen)
                          : (ordlen = 22, "tracecontext,baggage");

        i = 0;
        while (i <= ordlen) {
            STRLEN start = i, n;
            while (i < ordlen && ord[i] != ',') i++;
            n = i - start;
            while (n && (ord[start] == ' ')) { start++; n--; }
            while (n && (ord[start + n - 1] == ' ')) n--;

            if (n == 12 && memEQ(ord + start, "tracecontext", 12)) {
                SV **v = hv_fetchs(h, "traceparent", 0);
                if (v && *v && SvOK(*v)) {
                    STRLEN l; const char *s = SvPV_const(*v, l);
                    if (otel_w3c_parse(s, l, &ctx)) {
                        found = ctx; have = 1; fmt = "tracecontext";
                    }
                }
            }
            else if (n == 2 && memEQ(ord + start, "b3", 2)) {
                /* the SINGLE header wins when both are present, which is what
                 * the B3 spec says and what Zipkin itself does */
                SV **v = hv_fetchs(h, "b3", 0);
                int got = 0;
                if (v && *v && SvOK(*v)) {
                    STRLEN l; const char *s = SvPV_const(*v, l);
                    got = otel_b3_parse_single(s, l, &ctx);
                }
                if (!got) {
                    SV **t = hv_fetchs(h, "x-b3-traceid", 0);
                    SV **sp = hv_fetchs(h, "x-b3-spanid", 0);
                    SV **sm = hv_fetchs(h, "x-b3-sampled", 0);
                    SV **fl = hv_fetchs(h, "x-b3-flags", 0);
                    STRLEN tl = 0, sl = 0, ml = 0, fll = 0;
                    const char *ts = (t && *t && SvOK(*t)) ? SvPV_const(*t, tl) : NULL;
                    const char *ss = (sp && *sp && SvOK(*sp)) ? SvPV_const(*sp, sl) : NULL;
                    const char *ms = (sm && *sm && SvOK(*sm)) ? SvPV_const(*sm, ml) : NULL;
                    const char *fs = (fl && *fl && SvOK(*fl)) ? SvPV_const(*fl, fll) : NULL;
                    got = otel_b3_parse_multi(ts, tl, ss, sl, ms, ml, fs, fll, &ctx);
                }
                if (got) { found = ctx; have = 1; fmt = "b3"; }
            }
            else if (n == 6 && memEQ(ord + start, "jaeger", 6)) {
                SV **v = hv_fetchs(h, "uber-trace-id", 0);
                if (v && *v && SvOK(*v)) {
                    STRLEN l; const char *s = SvPV_const(*v, l);
                    if (otel_jaeger_parse(s, l, &ctx)) {
                        found = ctx; have = 1; fmt = "jaeger";
                    }
                }
            }
            /* "baggage" is a propagator in the list but carries no trace
             * context; it is extracted separately, by baggage_extract */
            if (i >= ordlen) break;
            i++;
        }

        if (!have) XSRETURN_UNDEF;
        {
            HV *o = newHV();
            char hex[32];
            otel_bytes_to_hex(found.trace_id, 16, hex);
            (void)hv_stores(o, "trace_id", newSVpvn(hex, 32));
            otel_bytes_to_hex(found.span_id, 8, hex);
            (void)hv_stores(o, "span_id", newSVpvn(hex, 16));
            (void)hv_stores(o, "sampled",
                newSViv((found.flags & OTEL_FLAG_SAMPLED) ? 1 : 0));
            (void)hv_stores(o, "flags", newSViv(found.flags));
            (void)hv_stores(o, "debug", newSViv(found.debug));
            (void)hv_stores(o, "format", newSVpv(fmt ? fmt : "", 0));
            RETVAL = newRV_noinc((SV *)o);
        }
    }
    OUTPUT:
        RETVAL

# inject($trace_id, $span_id, $sampled, $order) -> \%headers
#
# Injects EVERY configured format, so one request can carry traceparent and b3
# together for a mixed fleet - which is what makes a migration possible
# without a flag day.
SV *
inject(trace_id, span_id, sampled, order = &PL_sv_undef)
        SV *trace_id
        SV *span_id
        IV sampled
        SV *order
    CODE:
    {
        otel_ctx ctx;
        HV *out = newHV();
        const char *ord;
        STRLEN ordlen, tl, sl, i;
        const char *ts = SvPV_const(trace_id, tl);
        const char *ss = SvPV_const(span_id, sl);
        char buf[64];

        otel_ctx_clear(&ctx);
        if (!otel_hexn(ts, tl, 16, ctx.trace_id)
            || !otel_hexn(ss, sl, 8, ctx.span_id)
            || otel_all_zero(ctx.trace_id, 16)
            || otel_all_zero(ctx.span_id, 8)) {
            /* nothing valid to propagate is not an error - it is a root span
             * that has not started, or a caller passing through */
            RETVAL = newRV_noinc((SV *)out);
        }
        else {
            ctx.flags = sampled ? OTEL_FLAG_SAMPLED : 0;
            ord = SvOK(order) ? SvPV_const(order, ordlen)
                              : (ordlen = 22, "tracecontext,baggage");
            i = 0;
            while (i <= ordlen) {
                STRLEN start = i, n;
                while (i < ordlen && ord[i] != ',') i++;
                n = i - start;
                while (n && ord[start] == ' ') { start++; n--; }
                while (n && ord[start + n - 1] == ' ') n--;

                if (n == 12 && memEQ(ord + start, "tracecontext", 12)) {
                    otel_w3c_format(&ctx, buf);
                    (void)hv_stores(out, "traceparent", newSVpv(buf, 0));
                }
                else if (n == 2 && memEQ(ord + start, "b3", 2)) {
                    otel_b3_format_single(&ctx, buf);
                    (void)hv_stores(out, "b3", newSVpv(buf, 0));
                }
                else if (n == 6 && memEQ(ord + start, "jaeger", 6)) {
                    otel_jaeger_format(&ctx, buf);
                    (void)hv_stores(out, "uber-trace-id", newSVpv(buf, 0));
                }
                if (i >= ordlen) break;
                i++;
            }
            RETVAL = newRV_noinc((SV *)out);
        }
    }
    OUTPUT:
        RETVAL

# tracestate($existing, $key, $value) -> the mutated header.
#
# The changed member moves to the FRONT and everyone else keeps their relative
# order; that ordering is how a downstream vendor knows which system touched
# the trace most recently, and it is the rule implementations get wrong.
SV *
tracestate(existing, key, value)
        SV *existing
        SV *key
        SV *value
    CODE:
    {
        STRLEN el = 0, kl, vl;
        const char *e = SvOK(existing) ? SvPV_const(existing, el) : NULL;
        const char *k = SvPV_const(key, kl);
        const char *v = SvPV_const(value, vl);
        RETVAL = newSVsv(otel_ts_mutate(aTHX_ e, el, k, kl, v, vl));
    }
    OUTPUT:
        RETVAL

# baggage_extract($header) -> \%baggage
SV *
baggage_extract(header)
        SV *header
    CODE:
    {
        STRLEN l = 0;
        const char *s = SvOK(header) ? SvPV_const(header, l) : NULL;
        RETVAL = newRV_noinc((SV *)otel_baggage_parse(aTHX_ s, l));
    }
    OUTPUT:
        RETVAL

# baggage_inject(\%baggage) -> the header value
SV *
baggage_inject(baggage)
        SV *baggage
    CODE:
    {
        HV *h = (SvROK(baggage) && SvTYPE(SvRV(baggage)) == SVt_PVHV)
                ? (HV *)SvRV(baggage) : NULL;
        RETVAL = newSVsv(otel_baggage_format(aTHX_ h));
    }
    OUTPUT:
        RETVAL

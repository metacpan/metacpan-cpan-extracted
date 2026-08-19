/* otel_config.h - the OTEL_* environment surface, and precedence.
 *
 * WHY THIS IS A WHOLE FILE.
 *
 * Nobody configures a telemetry SDK by calling its constructor. They set
 * environment variables, because that is what their deployment tool sets, and
 * because the OTEL_* names are the one part of OpenTelemetry that is the same
 * in every language. An SDK that reads only its own options is an SDK that
 * every operator has to learn separately, and the whole point of the spec's
 * environment surface is that they do not have to.
 *
 * So: roughly thirty variables, parsed here, once, into a plain hash - and
 * then merged under whatever the application declared.
 *
 * THE PRECEDENCE, and what it is based on.
 *
 *   keyword > punk.yml > environment > default
 *
 * The spec defines three configuration interfaces (programmatic, environment
 * variable, declarative file) and says programmatic configuration is the
 * foundation the others "SHOULD be built on top of". It states NO precedence
 * between programmatic and environment configuration. The one precedence rule
 * it does give is about the declarative config file: when
 * OTEL_EXPERIMENTAL_CONFIG_FILE is set, that file takes precedence over all
 * the SDK configuration environment variables.
 *
 * So the order above matches the spec where it speaks (a file beats the
 * environment) and follows its stated principle where it does not
 * (programmatic is the foundation). It is also Punk's own convention, which
 * layers punk.yml under what the app class declared.
 *
 * Note for anyone reading the POD: punk.yml's `otel:` block is NOT the spec's
 * declarative configuration format, and the two must not be conflated.
 *
 * TWO THINGS THAT MUST NOT GO WRONG.
 *
 *   - OTEL_SDK_DISABLED=true has to make the whole thing inert. It is the
 *     switch an operator reaches for at three in the morning, and it is the
 *     one piece of this dist that must not itself fail. It is checked before
 *     anything is built and before a single hook is registered.
 *
 *   - OTEL_EXPORTER_OTLP_HEADERS carries credentials. Every header value is
 *     marked secret here so that the diagnostic, which prints everything
 *     else, cannot print those. A telemetry layer that leaks the token it
 *     authenticates with has done more harm than the telemetry was worth.
 *
 * Needs otel_trace.h (otel_h / otel_h_hv / otel_hv_of) and otel_resource.h
 * (otel_res_parse_env_attrs).
 */

#ifndef OTEL_CONFIG_H
#define OTEL_CONFIG_H

/* An environment variable, or NULL. An EMPTY value is absent, not empty:
 * "OTEL_SERVICE_NAME=" in a compose file means the operator did not set it,
 * and honouring it as a service named "" produces telemetry nothing can find.
 * Mortal SV. */
static SV *otel_cfg_env(pTHX_ const char *name) {
    const char *v = PerlEnv_getenv(name);
    if (!v || !*v) return NULL;
    return sv_2mortal(newSVpv(v, 0));
}

/* The spec's boolean: "true" is true, case-insensitively, and everything else
 * is false. Deliberately not Perl truth - OTEL_SDK_DISABLED=false must not
 * disable the SDK, and it would under any looser rule. */
static int otel_cfg_bool(pTHX_ const char *name, int dflt) {
    SV *v = otel_cfg_env(aTHX_ name);
    STRLEN l;
    const char *p;
    if (!v) return dflt;
    p = SvPV_const(v, l);
    while (l && isSPACE(*p)) { p++; l--; }
    while (l && isSPACE(p[l - 1])) l--;
    return (l == 4 && (p[0] == 't' || p[0] == 'T') && (p[1] == 'r' || p[1] == 'R')
            && (p[2] == 'u' || p[2] == 'U') && (p[3] == 'e' || p[3] == 'E'));
}

/* An integer variable. A value that is not a number is IGNORED rather than
 * taken as zero: OTEL_BSP_MAX_QUEUE_SIZE=lots must not silently become a
 * queue of nothing, which is indistinguishable from the exporter being
 * broken. */
static void otel_cfg_iv(pTHX_ HV *out, const char *key, const char *name,
                        IV dflt) {
    SV *v = otel_cfg_env(aTHX_ name);
    IV iv = dflt;
    if (v) {
        STRLEN l;
        const char *p = SvPV_const(v, l);
        STRLEN i = 0;
        int ok = 0;
        IV acc = 0;
        while (i < l && isSPACE(p[i])) i++;
        for (; i < l && isDIGIT(p[i]); i++) { acc = acc * 10 + (p[i] - '0'); ok = 1; }
        while (i < l && isSPACE(p[i])) i++;
        if (ok && i == l) iv = acc;
    }
    (void)hv_store(out, key, (I32)strlen(key), newSViv(iv), 0);
}

/* A comma-separated list, whitespace around each item eaten, empty items
 * dropped. Stored as an arrayref. */
static void otel_cfg_list(pTHX_ HV *out, const char *key, const char *name,
                          const char *dflt) {
    SV *v = otel_cfg_env(aTHX_ name);
    AV *av = newAV();
    STRLEN l, i = 0;
    const char *p;
    if (v) p = SvPV_const(v, l);
    else if (dflt) { p = dflt; l = strlen(dflt); }
    else { (void)hv_store(out, key, (I32)strlen(key), newRV_noinc((SV *)av), 0);
           return; }

    while (i < l) {
        STRLEN start, end;
        while (i < l && isSPACE(p[i])) i++;
        start = i;
        while (i < l && p[i] != ',') i++;
        end = i;
        if (i < l) i++;
        while (end > start && isSPACE(p[end - 1])) end--;
        if (end > start) av_push(av, newSVpvn(p + start, end - start));
    }
    (void)hv_store(out, key, (I32)strlen(key), newRV_noinc((SV *)av), 0);
}

/* A plain string variable, absent when unset (no key at all, so a later merge
 * can tell "unset" from "set to the default"). */
static void otel_cfg_str(pTHX_ HV *out, const char *key, const char *name,
                         const char *dflt) {
    SV *v = otel_cfg_env(aTHX_ name);
    if (v) (void)hv_store(out, key, (I32)strlen(key), newSVsv(v), 0);
    else if (dflt)
        (void)hv_store(out, key, (I32)strlen(key), newSVpv(dflt, 0), 0);
}

/* Percent-decoding, for header values. The spec carries OTLP headers in the
 * W3C Baggage encoding, so a value containing a comma, an equals or a space
 * arrives percent-encoded, and a token that survives the split but not the
 * decode authenticates against nothing. An invalid escape is left ALONE
 * rather than dropped: a literal '%' in a password is likelier than a
 * deliberate truncation. */
static SV *otel_cfg_pct_decode(pTHX_ SV *in) {
    STRLEN l, i;
    const char *p = SvPV_const(in, l);
    SV *out;
    for (i = 0; i < l; i++) if (p[i] == '%') break;
    if (i == l) return in;                     /* nothing to do */
    out = sv_2mortal(newSVpvn("", 0));
    SvGROW(out, l + 1);
    for (i = 0; i < l; i++) {
        if (p[i] == '%' && i + 2 < l && isXDIGIT(p[i + 1]) && isXDIGIT(p[i + 2])) {
            char b[3];
            b[0] = p[i + 1]; b[1] = p[i + 2]; b[2] = '\0';
            sv_catpvf(out, "%c", (int)strtol(b, NULL, 16));
            i += 2;
        }
        else sv_catpvn(out, p + i, 1);
    }
    return out;
}

/* OTEL_EXPORTER_OTLP_HEADERS and its per-signal forms: key=value pairs in the
 * same comma-separated shape as OTEL_RESOURCE_ATTRIBUTES, with the values
 * percent-decoded.
 *
 * The result is stored under `key` and its NAMES are recorded in `secret_of`
 * - see otel_config_diagnostic. Nothing else in this file needs to know which
 * values are credentials; the one place that prints does. */
static void otel_cfg_headers(pTHX_ HV *out, const char *key, const char *name) {
    SV *v = otel_cfg_env(aTHX_ name);
    HV *h;
    HE *he;
    STRLEN l;
    const char *p;
    if (!v) return;
    h = newHV();
    p = SvPV_const(v, l);
    otel_res_parse_env_attrs(aTHX_ h, p, l);
    hv_iterinit(h);
    while ((he = hv_iternext(h))) {
        SV *val = HeVAL(he);
        SV *dec = otel_cfg_pct_decode(aTHX_ val);
        if (dec != val) sv_setsv(val, dec);
    }
    (void)hv_store(out, key, (I32)strlen(key), newRV_noinc((SV *)h), 0);
}

/* The whole environment surface, as one hash.
 *
 * Read ONCE, at boot. Re-reading %ENV per request would be both slower and
 * wrong: a worker that picked up a mid-flight change would disagree with its
 * siblings, and telemetry that disagrees about its own configuration is worse
 * than telemetry that is uniformly stale. */
static HV *otel_config_from_env(pTHX) {
    HV *out = newHV();
    HV *sub;

    (void)hv_stores(out, "disabled",
                    newSViv(otel_cfg_bool(aTHX_ "OTEL_SDK_DISABLED", 0)));

    /* identity */
    otel_cfg_str(aTHX_ out, "service_name", "OTEL_SERVICE_NAME", NULL);
    {
        SV *ra = otel_cfg_env(aTHX_ "OTEL_RESOURCE_ATTRIBUTES");
        if (ra) {
            HV *h = newHV();
            STRLEN l;
            const char *p = SvPV_const(ra, l);
            otel_res_parse_env_attrs(aTHX_ h, p, l);
            (void)hv_stores(out, "resource_attributes", newRV_noinc((SV *)h));
        }
    }

    /* context propagation. The spec's default is tracecontext AND baggage;
     * a deployment that drops baggage loses it silently, which is why the
     * default is spelled out here rather than left to the propagator. */
    otel_cfg_list(aTHX_ out, "propagators", "OTEL_PROPAGATORS",
                  "tracecontext,baggage");

    /* sampling */
    otel_cfg_str(aTHX_ out, "sampler", "OTEL_TRACES_SAMPLER",
                 "parentbased_always_on");
    otel_cfg_str(aTHX_ out, "sampler_arg", "OTEL_TRACES_SAMPLER_ARG", NULL);

    /* transport. The general endpoint has the signal path APPENDED; a
     * per-signal endpoint is used EXACTLY as given. That asymmetry is the
     * spec's, and it is the single most common thing to get wrong - see
     * otel_export.h, which implements it. */
    otel_cfg_str(aTHX_ out, "endpoint", "OTEL_EXPORTER_OTLP_ENDPOINT", NULL);
    otel_cfg_str(aTHX_ out, "protocol", "OTEL_EXPORTER_OTLP_PROTOCOL",
                 "http/protobuf");
    otel_cfg_str(aTHX_ out, "compression", "OTEL_EXPORTER_OTLP_COMPRESSION",
                 "none");
    otel_cfg_iv(aTHX_ out, "timeout", "OTEL_EXPORTER_OTLP_TIMEOUT", 10000);
    otel_cfg_headers(aTHX_ out, "headers", "OTEL_EXPORTER_OTLP_HEADERS");

    sub = newHV();
    otel_cfg_str(aTHX_ sub, "traces",  "OTEL_EXPORTER_OTLP_TRACES_ENDPOINT",  NULL);
    otel_cfg_str(aTHX_ sub, "metrics", "OTEL_EXPORTER_OTLP_METRICS_ENDPOINT", NULL);
    otel_cfg_str(aTHX_ sub, "logs",    "OTEL_EXPORTER_OTLP_LOGS_ENDPOINT",    NULL);
    if (HvUSEDKEYS(sub)) (void)hv_stores(out, "endpoints", newRV_noinc((SV *)sub));
    else SvREFCNT_dec((SV *)sub);

    sub = newHV();
    otel_cfg_str(aTHX_ sub, "traces",  "OTEL_EXPORTER_OTLP_TRACES_PROTOCOL",  NULL);
    otel_cfg_str(aTHX_ sub, "metrics", "OTEL_EXPORTER_OTLP_METRICS_PROTOCOL", NULL);
    otel_cfg_str(aTHX_ sub, "logs",    "OTEL_EXPORTER_OTLP_LOGS_PROTOCOL",    NULL);
    if (HvUSEDKEYS(sub)) (void)hv_stores(out, "protocols", newRV_noinc((SV *)sub));
    else SvREFCNT_dec((SV *)sub);

    sub = newHV();
    otel_cfg_str(aTHX_ sub, "traces",  "OTEL_EXPORTER_OTLP_TRACES_COMPRESSION",  NULL);
    otel_cfg_str(aTHX_ sub, "metrics", "OTEL_EXPORTER_OTLP_METRICS_COMPRESSION", NULL);
    otel_cfg_str(aTHX_ sub, "logs",    "OTEL_EXPORTER_OTLP_LOGS_COMPRESSION",    NULL);
    if (HvUSEDKEYS(sub)) (void)hv_stores(out, "compressions", newRV_noinc((SV *)sub));
    else SvREFCNT_dec((SV *)sub);

    sub = newHV();
    otel_cfg_headers(aTHX_ sub, "traces",  "OTEL_EXPORTER_OTLP_TRACES_HEADERS");
    otel_cfg_headers(aTHX_ sub, "metrics", "OTEL_EXPORTER_OTLP_METRICS_HEADERS");
    otel_cfg_headers(aTHX_ sub, "logs",    "OTEL_EXPORTER_OTLP_LOGS_HEADERS");
    if (HvUSEDKEYS(sub)) (void)hv_stores(out, "signal_headers", newRV_noinc((SV *)sub));
    else SvREFCNT_dec((SV *)sub);

    /* the batch span processor */
    sub = newHV();
    otel_cfg_iv(aTHX_ sub, "schedule_delay",        "OTEL_BSP_SCHEDULE_DELAY",         5000);
    otel_cfg_iv(aTHX_ sub, "export_timeout",        "OTEL_BSP_EXPORT_TIMEOUT",        30000);
    otel_cfg_iv(aTHX_ sub, "max_queue_size",        "OTEL_BSP_MAX_QUEUE_SIZE",         2048);
    otel_cfg_iv(aTHX_ sub, "max_export_batch_size", "OTEL_BSP_MAX_EXPORT_BATCH_SIZE",   512);
    (void)hv_stores(out, "bsp", newRV_noinc((SV *)sub));

    /* the batch log record processor. Its schedule delay defaults to 1s, not
     * the span processor's 5s - the spec's numbers, and different on purpose:
     * a log people are watching for is worth sending sooner than a span they
     * will look at afterwards. */
    sub = newHV();
    otel_cfg_iv(aTHX_ sub, "schedule_delay",        "OTEL_BLRP_SCHEDULE_DELAY",        1000);
    otel_cfg_iv(aTHX_ sub, "export_timeout",        "OTEL_BLRP_EXPORT_TIMEOUT",       30000);
    otel_cfg_iv(aTHX_ sub, "max_queue_size",        "OTEL_BLRP_MAX_QUEUE_SIZE",        2048);
    otel_cfg_iv(aTHX_ sub, "max_export_batch_size", "OTEL_BLRP_MAX_EXPORT_BATCH_SIZE",  512);
    (void)hv_stores(out, "blrp", newRV_noinc((SV *)sub));

    /* metrics */
    otel_cfg_iv(aTHX_ out, "metric_export_interval", "OTEL_METRIC_EXPORT_INTERVAL", 60000);
    otel_cfg_iv(aTHX_ out, "metric_export_timeout",  "OTEL_METRIC_EXPORT_TIMEOUT",  30000);
    otel_cfg_str(aTHX_ out, "temporality_preference",
                 "OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE", "cumulative");
    otel_cfg_str(aTHX_ out, "exemplar_filter", "OTEL_METRICS_EXEMPLAR_FILTER",
                 "trace_based");

    /* limits. 0 means unlimited for the length limits, which is why they are
     * absent by default rather than set to something enormous. */
    otel_cfg_iv(aTHX_ out, "attribute_count_limit",
                "OTEL_ATTRIBUTE_COUNT_LIMIT", 128);
    otel_cfg_str(aTHX_ out, "attribute_value_length_limit",
                 "OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT", NULL);
    otel_cfg_iv(aTHX_ out, "span_attribute_count_limit",
                "OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT", 128);
    otel_cfg_str(aTHX_ out, "span_attribute_value_length_limit",
                 "OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT", NULL);
    otel_cfg_iv(aTHX_ out, "span_event_count_limit",
                "OTEL_SPAN_EVENT_COUNT_LIMIT", 128);
    otel_cfg_iv(aTHX_ out, "span_link_count_limit",
                "OTEL_SPAN_LINK_COUNT_LIMIT", 128);
    otel_cfg_iv(aTHX_ out, "event_attribute_count_limit",
                "OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT", 128);
    otel_cfg_iv(aTHX_ out, "link_attribute_count_limit",
                "OTEL_LINK_ATTRIBUTE_COUNT_LIMIT", 128);

    return out;
}

/* Merge `src` over `dst`, in place. `src` wins.
 *
 * ONE LEVEL DEEP for a hash value, because the sub-hashes here are namespaces
 * rather than values: an app that sets one per-signal endpoint means "that
 * one", not "and forget whatever the environment said about the other two".
 * An ARRAY replaces wholesale, because a propagator list is a single decision
 * - merging two lists gives an order nobody chose. */
static void otel_config_merge(pTHX_ HV *dst, HV *src) {
    HE *he;
    if (!dst || !src) return;
    hv_iterinit(src);
    while ((he = hv_iternext(src))) {
        STRLEN kl;
        const char *k = HePV(he, kl);
        SV *sv = HeVAL(he);
        SV **have = hv_fetch(dst, k, (I32)kl, 0);
        if (sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV
            && have && *have && SvROK(*have)
            && SvTYPE(SvRV(*have)) == SVt_PVHV) {
            otel_config_merge(aTHX_ (HV *)SvRV(*have), (HV *)SvRV(sv));
            continue;
        }
        (void)hv_store(dst, k, (I32)kl, newSVsv(sv), 0);
    }
}

/* The boot diagnostic.
 *
 * One line, at info, stating: enabled or disabled, the service name, the
 * protocol, the endpoint, the sampler and its argument, and the propagators.
 * Almost every OpenTelemetry support question is answered by those six facts,
 * and almost no SDK prints them - so the first hour of every investigation is
 * spent establishing what the SDK thought it was doing.
 *
 * HEADERS ARE NEVER PRINTED. Not the values, not even truncated: a token with
 * its first eight characters shown is a token in the log. The COUNT is
 * printed, because "did my headers arrive" is a real question and a number
 * answers it without answering anything else. */
static SV *otel_config_diagnostic(pTHX_ HV *cfg) {
    SV *out = sv_2mortal(newSVpvn("", 0));
    SV *v;
    HV *h;
    int nh = 0;

    v = otel_h(aTHX_ cfg, "disabled");
    if (v && SvTRUE(v)) {
        sv_catpvs(out, "OpenTelemetry disabled (OTEL_SDK_DISABLED)");
        return out;
    }
    sv_catpvs(out, "OpenTelemetry enabled");

    v = otel_h(aTHX_ cfg, "service_name");
    sv_catpvf(out, " service=%s",
              (v && SvOK(v)) ? SvPV_nolen(v) : "unknown_service");

    v = otel_h(aTHX_ cfg, "protocol");
    if (v && SvOK(v)) sv_catpvf(out, " protocol=%s", SvPV_nolen(v));

    v = otel_h(aTHX_ cfg, "endpoint");
    sv_catpvf(out, " endpoint=%s", (v && SvOK(v)) ? SvPV_nolen(v) : "(default)");

    v = otel_h(aTHX_ cfg, "sampler");
    if (v && SvOK(v)) {
        SV *arg = otel_h(aTHX_ cfg, "sampler_arg");
        sv_catpvf(out, " sampler=%s", SvPV_nolen(v));
        if (arg && SvOK(arg)) sv_catpvf(out, ":%s", SvPV_nolen(arg));
    }

    {
        AV *av = otel_h_av(aTHX_ cfg, "propagators");
        if (av) {
            SSize_t i, n = av_len(av) + 1;
            sv_catpvs(out, " propagators=");
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                if (!(e && *e)) continue;
                if (i) sv_catpvs(out, ",");
                sv_catsv(out, *e);
            }
        }
    }

    /* the count, never the contents */
    h = otel_h_hv(aTHX_ cfg, "headers");
    if (h) nh += (int)HvUSEDKEYS(h);
    h = otel_h_hv(aTHX_ cfg, "signal_headers");
    if (h) {
        HE *he;
        hv_iterinit(h);
        while ((he = hv_iternext(h))) {
            HV *s = otel_hv_of(aTHX_ HeVAL(he));
            if (s) nh += (int)HvUSEDKEYS(s);
        }
    }
    if (nh) sv_catpvf(out, " headers=%d", nh);

    return out;
}

#endif /* OTEL_CONFIG_H */

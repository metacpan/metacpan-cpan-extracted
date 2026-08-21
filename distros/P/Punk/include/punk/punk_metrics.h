/* punk_metrics.h - a Prometheus /metrics endpoint.
 *
 * WHY, GIVEN Punk::OpenTelemetry EXISTS.
 *
 * They are not substitutes: the difference is push against pull. OpenTelemetry
 * pushes OTLP to a collector somebody has to run. Prometheus scrapes an
 * endpoint, and a scrape needs nothing deployed beside the application. For a
 * great many deployments that is the difference between "metrics exist" and
 * "metrics were a project". They coexist: the same request feeds both, and an
 * application that later adopts a collector keeps its dashboards.
 *
 * CARDINALITY, WHICH IS THE THING MOST OF THESE GET WRONG.
 *
 * A counter labelled with the REQUEST path is the classic monitoring outage:
 * /users/1, /users/2 and a million more each become their own time series,
 * and the scrape target eventually takes the monitoring system down with it.
 *
 * Punk cannot make that mistake, because the compiled route table is the
 * label set. Every route pattern is known at to_app, the set is bounded, and
 * /users/:id is ONE series however many ids exist. That is a real dividend of
 * compiling routes at boot. Anything with no route to name - a 404, a mount -
 * is labelled once as <other>, for exactly the same reason.
 *
 * THE PREFORK TRAP.
 *
 * A scrape hits ONE worker. Whichever worker the listener hands the connection
 * to answers with that worker's counters, so a naive exporter reports one Nth
 * of the traffic and a different Nth every scrape - every graph then wrong in
 * a way that looks like noise.
 *
 * Two ways out. Aggregate through the shared arena, which is correct and costs
 * an atomic per request on a shared cacheline - the exact contention pattern
 * worth measuring before committing, against a request path of about 4.4us.
 * Or export per-worker series with a `worker` label and let Prometheus sum
 * them: no shared state, no contention, honest about what it is.
 *
 * THIS DOES THE SECOND, and says so in the documentation rather than letting
 * an operator discover it from a graph. `sum by (route) (...)` is the cost.
 *
 * Must be included after punk_context.h, pk_abi_impl.h (the accessors),
 * punk_obs.h (the registry), punk_response.h and punk_static.h.
 */

#ifndef PUNK_METRICS_H
#define PUNK_METRICS_H

/* The buckets, chosen ONCE and documented, because changing them later
 * invalidates every histogram already recorded.
 *
 * Not Prometheus's defaults, which start at 5ms. Punk's own dispatch is about
 * 4.4us, so a first bucket of 5ms would put essentially every request into
 * it and the histogram would answer no question anybody asks. These start at
 * half a millisecond and keep the familiar tail. */
static const double PM_BUCKETS[] = {
    0.0005, 0.001, 0.0025, 0.005, 0.01, 0.025, 0.05,
    0.1, 0.25, 0.5, 1, 2.5, 5, 10
};
#define PM_NBUCKETS ((int)(sizeof(PM_BUCKETS) / sizeof(PM_BUCKETS[0])))

/* Per PROCESS, not per application: a worker exports its own counters and
 * Prometheus sums them. Two applications in one process share these, which is
 * what a process-wide exporter means. */
static HV *PM_TOTAL    = NULL;   /* "METHOD\x1Froute\x1Fstatus" => count      */
static HV *PM_HIST     = NULL;   /* "METHOD\x1Froute" => [n, sum, b0..bN-1]   */
static IV  PM_INFLIGHT = 0;
static int PM_OBSERVING = 0;     /* the observers are registered once         */
/* EVERY metrics path registered in this process, not the latest one.
 *
 * It was a single SV, and that was a bug with a very quiet symptom: a second
 * application registering a different path REPLACED it, after which the first
 * application's scrape endpoint silently began counting its own scrapes -
 * for ever, and looking exactly like real traffic. A set, because the answer
 * to "is this a scrape" is about the process, not about the last caller. */
static HV *PM_SKIP     = NULL;   /* path => 1, never counted                  */

#define PM_T0_KEY   "punk.metrics.t0"
#define PM_SKIP_KEY "punk.metrics.skip"

static void pm_init(pTHX) {
    if (!PM_TOTAL) PM_TOTAL = newHV();
    if (!PM_HIST)  PM_HIST  = newHV();
    if (!PM_SKIP)  PM_SKIP  = newHV();
}

/* Is this one of the scrape endpoints? */
static int pm_is_scrape(pTHX_ SV *path) {
    if (!PM_SKIP || !path || !SvOK(path)) return 0;
    return hv_exists_ent(PM_SKIP, path, 0) ? 1 : 0;
}

/* A label value, escaped. Prometheus needs backslash, quote and newline out
 * of the way; a route pattern will not contain them, but a `collect` name or
 * an operation id is not this plugin's to vouch for. */
static void pm_label(pTHX_ SV *out, const char *s, STRLEN len) {
    STRLEN i;
    for (i = 0; i < len; i++) {
        char ch = s[i];
        if      (ch == '\\') sv_catpvs(out, "\\\\");
        else if (ch == '"')  sv_catpvs(out, "\\\"");
        else if (ch == '\n') sv_catpvs(out, "\\n");
        else                 sv_catpvn(out, &ch, 1);
    }
}

/* A metric name Prometheus will accept: [a-zA-Z_:][a-zA-Z0-9_:]*
 *
 * Checked rather than trusted, because ONE bad name does not break one
 * series - it makes the whole scrape unparseable, and every metric the
 * application has disappears at once. */
static int pm_name_ok(const char *s, STRLEN len) {
    STRLEN i;
    if (!s || !len) return 0;
    if (!(isALPHA(s[0]) || s[0] == '_' || s[0] == ':')) return 0;
    for (i = 1; i < len; i++)
        if (!(isALNUM(s[i]) || s[i] == '_' || s[i] == ':')) return 0;
    return 1;
}

/* The route to label this request with.
 *
 * The declared pattern when there is one; the OpenAPI operationId for an api
 * mount, which is bounded the same way; and <other> for everything else. A
 * 404 has no route by definition, and giving it the request path is precisely
 * how the bounded dimension becomes unbounded. */
static SV *pm_route_of(pTHX_ SV *c) {
    SV *r = pk_abi_route_pattern_of(aTHX_ c);
    if (r && SvOK(r) && SvCUR(r)) return r;
    r = pk_abi_operation_of(aTHX_ c);
    if (r && SvOK(r) && SvCUR(r)) return r;
    return NULL;
}

/* REQUEST_METHOD, or "-". */
static const char *pm_method_of(pTHX_ SV *c, STRLEN *len) {
    SV *env = pk_abi_env_of(aTHX_ c);
    SV **m;
    if (env && SvROK(env) && SvTYPE(SvRV(env)) == SVt_PVHV
        && (m = hv_fetchs((HV *)SvRV(env), "REQUEST_METHOD", 0))
        && m && *m && SvOK(*m) && SvCUR(*m))
        return SvPV_const(*m, *len);
    *len = 1;
    return "-";
}

static void pm_bump_total(pTHX_ const char *k, STRLEN kl) {
    SV **e = hv_fetch(PM_TOTAL, k, (I32)kl, 1);
    if (e && *e) sv_setuv(*e, (SvOK(*e) ? SvUV(*e) : 0) + 1);
}

static void pm_bump_hist(pTHX_ const char *k, STRLEN kl, double secs) {
    SV **e = hv_fetch(PM_HIST, k, (I32)kl, 1);
    AV *h;
    int i;
    if (!(e && *e)) return;
    if (!(SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV)) {
        AV *fresh = newAV();
        av_extend(fresh, 2 + PM_NBUCKETS);
        av_store(fresh, 0, newSVuv(0));
        av_store(fresh, 1, newSVnv(0.0));
        for (i = 0; i < PM_NBUCKETS; i++) av_store(fresh, 2 + i, newSVuv(0));
        sv_setsv(*e, sv_2mortal(newRV_noinc((SV *)fresh)));
    }
    h = (AV *)SvRV(*e);
    {
        SV **n = av_fetch(h, 0, 0);
        SV **s = av_fetch(h, 1, 0);
        if (n && *n) sv_setuv(*n, SvUV(*n) + 1);
        if (s && *s) sv_setnv(*s, SvNV(*s) + secs);
    }
    /* Cumulative, which is what a Prometheus histogram means: a request lands
     * in its own bucket AND every wider one. */
    for (i = 0; i < PM_NBUCKETS; i++) {
        if (secs <= PM_BUCKETS[i]) {
            SV **b = av_fetch(h, 2 + i, 0);
            if (b && *b) sv_setuv(*b, SvUV(*b) + 1);
        }
    }
}

/* ---- the observers ---------------------------------------------------------
 *
 * MUST NOT croak: they run inside somebody else's request, and an exporter
 * that can take the application down with it is worse than no exporter. */
static void pm_on_request(pTHX_ SV *c, void *ud) {
    SV *st = pk_abi_stash_of(aTHX_ c);
    HV *sh = (st && SvROK(st) && SvTYPE(SvRV(st)) == SVt_PVHV)
             ? (HV *)SvRV(st) : NULL;
    PERL_UNUSED_ARG(ud);

    /* Is this the scrape itself? Decided HERE, at the one moment it can be
     * decided symmetrically, and recorded for the response side.
     *
     * Routing has not happened yet, so there is no pattern to compare - only
     * the path. That is the whole reason for the stash flag: if the two sides
     * decided independently they could disagree, and the in-flight gauge
     * would then drift by one every time they did.
     *
     * It matters because a scrape is in flight while it renders. Counting it
     * gives an idle server a permanent floor of one, on every dashboard, for
     * ever. */
    {
        SV *env = pk_abi_env_of(aTHX_ c);
        SV **p = (env && SvROK(env) && SvTYPE(SvRV(env)) == SVt_PVHV)
                 ? hv_fetchs((HV *)SvRV(env), "PATH_INFO", 0) : NULL;
        if (p && *p && pm_is_scrape(aTHX_ *p)) {
            if (sh) (void)hv_stores(sh, PM_SKIP_KEY, newSViv(1));
            return;
        }
    }

    PM_INFLIGHT++;
    if (sh) (void)hv_stores(sh, PM_T0_KEY, newSVnv(pc_now(aTHX)));
}

static void pm_on_response(pTHX_ SV *c, SV *response, void *ud) {
    SV *route, *st;
    const char *mp; STRLEN ml;
    IV status;
    double t0 = 0.0, secs;
    SV *key;
    PERL_UNUSED_ARG(ud);

    st = pk_abi_stash_of(aTHX_ c);

    /* The request side already decided, so the two cannot disagree: it never
     * incremented the gauge for this one, and this never decrements it. */
    if (st && SvROK(st) && SvTYPE(SvRV(st)) == SVt_PVHV
        && hv_exists((HV *)SvRV(st), PM_SKIP_KEY,
                     (I32)(sizeof(PM_SKIP_KEY) - 1)))
        return;

    if (PM_INFLIGHT > 0) PM_INFLIGHT--;
    pm_init(aTHX);

    route = pm_route_of(aTHX_ c);

    /* And the same exclusion by route, for a scrape reached through a mount
     * where the path the request carried was not the path this was told. */
    if (route && pm_is_scrape(aTHX_ route)) return;

    mp = pm_method_of(aTHX_ c, &ml);
    status = pk_abi_status_of(aTHX_ response);

    if (st && SvROK(st) && SvTYPE(SvRV(st)) == SVt_PVHV) {
        SV **t = hv_fetchs((HV *)SvRV(st), PM_T0_KEY, 0);
        if (t && *t && SvOK(*t)) t0 = SvNV(*t);
    }
    secs = t0 > 0.0 ? pc_now(aTHX) - t0 : 0.0;
    if (secs < 0.0) secs = 0.0;

    key = sv_2mortal(newSVpvn(mp, ml));
    sv_catpvs(key, "\x1f");
    if (route) sv_catsv(key, route);
    else       sv_catpvs(key, "<other>");

    pm_bump_hist(aTHX_ SvPVX(key), SvCUR(key), secs);

    /* A streaming or detached response has no status to read; -1 rather than
     * a guess, so nobody graphs a 200 that never happened. */
    sv_catpvs(key, "\x1f");
    if (status >= 0) sv_catpvf(key, "%" IVdf, status);
    else             sv_catpvs(key, "-");
    pm_bump_total(aTHX_ SvPVX(key), SvCUR(key));
}

/* ---- rendering ------------------------------------------------------------ */

/* Split a "\x1f"-joined key. */
static const char *pm_field(const char *k, STRLEN kl, int n, STRLEN *len) {
    const char *p = k, *end = k + kl;
    int i = 0;
    while (i < n && p < end) { if (*p++ == '\x1f') i++; }
    { const char *q = p;
      while (q < end && *q != '\x1f') q++;
      *len = (STRLEN)(q - p);
      return p; }
}

static void pm_worker(pTHX_ SV *out) {
    sv_catpvf(out, ",worker=\"%" IVdf "\"", (IV)PerlProc_getpid());
}

/* The sorted keys of an HV, so a scrape is byte-stable between calls and a
 * diff of two shows what changed rather than what moved. */
static AV *pm_sorted_keys(pTHX_ HV *h) {
    AV *keys = (AV *)sv_2mortal((SV *)newAV());
    HE *ent;
    hv_iterinit(h);
    while ((ent = hv_iternext(h))) av_push(keys, newSVsv(hv_iterkeysv(ent)));
    sortsv(AvARRAY(keys), (SSize_t)(av_len(keys) + 1), Perl_sv_cmp);
    return keys;
}

/* Anything an application wants to add, as gauges. This is where the queue's
 * depth and a server's own counters go: reaching into another distribution
 * from here would couple this plugin to versions of things it cannot test
 * against, and an application already has both in scope. */
static void pm_collect(pTHX_ SV *app, SV *out) {
    HV *h = app_hv(aTHX_ app);
    SV *cb = h ? app_get(aTHX_ h, "metrics_collect") : NULL;
    SV *got = NULL;
    HV *gh;
    AV *names;
    SSize_t i, n;

    if (!(cb && SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV)) return;

    {
        dSP; int count;
        ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
        count = call_sv(cb, G_SCALAR | G_EVAL);
        SPAGAIN;
        if (!SvTRUE(ERRSV) && count > 0) got = newSVsv(POPs);
        else if (count > 0)             (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
    }
    if (!got) return;                     /* it died: the scrape goes on */
    sv_2mortal(got);
    if (!(SvROK(got) && SvTYPE(SvRV(got)) == SVt_PVHV)) return;
    gh = (HV *)SvRV(got);

    names = pm_sorted_keys(aTHX_ gh);
    n = av_len(names) + 1;
    for (i = 0; i < n; i++) {
        SV *nm = *av_fetch(names, i, 0);
        HE *he = hv_fetch_ent(gh, nm, 0, 0);
        SV *v = he ? HeVAL(he) : NULL;
        STRLEN nl; const char *np = SvPV_const(nm, nl);
        if (!pm_name_ok(np, nl)) continue;      /* see pm_name_ok */
        if (!(v && SvOK(v)))     continue;
        sv_catpvf(out, "# TYPE %s gauge\n%s{", np, np);
        /* the leading comma of pm_worker would be wrong as the first label */
        sv_catpvf(out, "worker=\"%" IVdf "\"} %s\n",
                  (IV)PerlProc_getpid(), SvPV_nolen(sv_2mortal(newSVnv(SvNV(v)))));
    }
}

/* Whatever each cache is willing to say about itself, as gauges. In-dist, so
 * it can be kept in step.
 *
 * `app->{cache}` is a HASH of name => cache object, not a cache - so every
 * configured cache is reported, labelled with its name. The label set is
 * bounded by the config, which is the same rule the route label follows. */
static void pm_cache(pTHX_ SV *app, SV *out) {
    HV *h = app_hv(aTHX_ app);
    SV *caches = h ? app_get(aTHX_ h, "cache") : NULL;
    HV *ch;
    AV *names;
    SSize_t i, n;

    if (!(caches && SvROK(caches) && SvTYPE(SvRV(caches)) == SVt_PVHV)) return;
    ch = (HV *)SvRV(caches);

    names = pm_sorted_keys(aTHX_ ch);
    n = av_len(names) + 1;
    for (i = 0; i < n; i++) {
        SV *nm = *av_fetch(names, i, 0);
        HE *he = hv_fetch_ent(ch, nm, 0, 0);
        SV *cache = he ? HeVAL(he) : NULL;
        STRLEN nml; const char *nmp = SvPV_const(nm, nml);
        SSize_t j, got;

        if (!(cache && SvROK(cache) && SvOBJECT(SvRV(cache)))) continue;

        /* stats() returns a flat LIST, so it has to be called in list
         * context - pcx_call_meth only offers scalar or void. */
        {
            dSP; int count, k;
            AV *flat = (AV *)sv_2mortal((SV *)newAV());
            ENTER; SAVETMPS; PUSHMARK(SP);
            EXTEND(SP, 1); PUSHs(cache); PUTBACK;
            count = call_method("stats", G_ARRAY | G_EVAL);
            SPAGAIN;
            if (SvTRUE(ERRSV)) count = 0;
            for (k = 0; k < count; k++) av_unshift(flat, 1), av_store(flat, 0, newSVsv(POPs));
            PUTBACK; FREETMPS; LEAVE;

            got = av_len(flat) + 1;
            for (j = 0; j + 1 < got; j += 2) {
                SV **k2 = av_fetch(flat, j, 0);
                SV **v  = av_fetch(flat, j + 1, 0);
                STRLEN kl; const char *kp;
                if (!(k2 && *k2 && v && *v && SvOK(*v))) continue;
                kp = SvPV_const(*k2, kl);
                if (!pm_name_ok(kp, kl)) continue;
                sv_catpvf(out, "punk_cache_%.*s{cache=\"", (int)kl, kp);
                pm_label(aTHX_ out, nmp, nml);
                sv_catpvs(out, "\"");
                pm_worker(aTHX_ out);
                /* NVgf, not a bare "g", and (NV) to match it.
                 *
                 * sv_catpvf is not C printf. Its float conversions take
                 * whatever width the format's length modifier names, and a
                 * bare %g names `double` - so on a long-double or quadmath
                 * perl an NV argument is read as the wrong type off the
                 * varargs and every cache counter here came out as
                 * 8.094771541e-320. NVgf expands to the modifier that perl's
                 * own NV needs, on each of them. */
                sv_catpvf(out, "} %.10" NVgf "\n", (NV)SvNV(*v));
            }
        }
    }
}

/* The whole document. */
static SV *pm_render(pTHX_ SV *app) {
    SV *out = sv_2mortal(newSVpvs(""));
    AV *keys;
    SSize_t i, n;

    pm_init(aTHX);

    sv_catpvs(out,
        "# HELP http_requests_total Requests, by method, declared route and "
        "status.\n"
        "# TYPE http_requests_total counter\n");
    keys = pm_sorted_keys(aTHX_ PM_TOTAL);
    n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV *k = *av_fetch(keys, i, 0);
        STRLEN kl; const char *kp = SvPV_const(k, kl);
        STRLEN ml, rl, sl;
        const char *mp = pm_field(kp, kl, 0, &ml);
        const char *rp = pm_field(kp, kl, 1, &rl);
        const char *sp = pm_field(kp, kl, 2, &sl);
        HE *he = hv_fetch_ent(PM_TOTAL, k, 0, 0);
        sv_catpvs(out, "http_requests_total{method=\"");
        pm_label(aTHX_ out, mp, ml);
        sv_catpvs(out, "\",route=\"");
        pm_label(aTHX_ out, rp, rl);
        sv_catpvs(out, "\",status=\"");
        pm_label(aTHX_ out, sp, sl);
        sv_catpvs(out, "\"");
        pm_worker(aTHX_ out);
        sv_catpvf(out, "} %" UVuf "\n", he ? SvUV(HeVAL(he)) : (UV)0);
    }

    sv_catpvs(out,
        "# HELP http_request_duration_seconds Request duration.\n"
        "# TYPE http_request_duration_seconds histogram\n");
    keys = pm_sorted_keys(aTHX_ PM_HIST);
    n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV *k = *av_fetch(keys, i, 0);
        STRLEN kl; const char *kp = SvPV_const(k, kl);
        STRLEN ml, rl;
        const char *mp = pm_field(kp, kl, 0, &ml);
        const char *rp = pm_field(kp, kl, 1, &rl);
        HE *he = hv_fetch_ent(PM_HIST, k, 0, 0);
        AV *hst = (he && SvROK(HeVAL(he))
                   && SvTYPE(SvRV(HeVAL(he))) == SVt_PVAV)
                  ? (AV *)SvRV(HeVAL(he)) : NULL;
        SV *labels = sv_2mortal(newSVpvs("method=\""));
        int b;
        if (!hst) continue;
        pm_label(aTHX_ labels, mp, ml);
        sv_catpvs(labels, "\",route=\"");
        pm_label(aTHX_ labels, rp, rl);
        sv_catpvs(labels, "\"");
        pm_worker(aTHX_ labels);

        for (b = 0; b < PM_NBUCKETS; b++) {
            SV **cnt = av_fetch(hst, 2 + b, 0);
            sv_catpvf(out, "http_request_duration_seconds_bucket{%s,le=\"%"
                           NVgf "\"} %" UVuf "\n",
                      SvPV_nolen(labels), (NV)PM_BUCKETS[b],
                      cnt && *cnt ? SvUV(*cnt) : (UV)0);
        }
        {
            SV **num = av_fetch(hst, 0, 0);
            SV **sum = av_fetch(hst, 1, 0);
            UV nn = num && *num ? SvUV(*num) : (UV)0;
            sv_catpvf(out, "http_request_duration_seconds_bucket{%s,le=\"+Inf\"} "
                           "%" UVuf "\n", SvPV_nolen(labels), nn);
            sv_catpvf(out, "http_request_duration_seconds_sum{%s} %.6" NVff
                           "\n",
                      SvPV_nolen(labels), sum && *sum ? (NV)SvNV(*sum) : (NV)0);
            sv_catpvf(out, "http_request_duration_seconds_count{%s} %" UVuf "\n",
                      SvPV_nolen(labels), nn);
        }
    }

    sv_catpvs(out,
        "# HELP http_requests_in_flight Requests being served right now.\n"
        "# TYPE http_requests_in_flight gauge\n");
    sv_catpvf(out, "http_requests_in_flight{worker=\"%" IVdf "\"} %" IVdf "\n",
              (IV)PerlProc_getpid(), PM_INFLIGHT);

    pm_cache(aTHX_ app, out);
    pm_collect(aTHX_ app, out);

    return newSVsv(out);
}

XS_INTERNAL(pm_serve_cb);
XS_INTERNAL(pm_serve_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *app = cap ? *av_fetch(cap, 0, 0) : NULL;
    AV *extra = (AV *)sv_2mortal((SV *)newAV());
    PERL_UNUSED_VAR(items);
    av_push(extra, newSVpvs("Cache-Control"));
    av_push(extra, newSVpvs("no-store"));
    ST(0) = sv_2mortal(punk_triplet(aTHX_ 200,
                sv_2mortal(newSVpvs("text/plain; version=0.0.4; charset=utf-8")),
                pm_render(aTHX_ app), extra));
    XSRETURN(1);
}

#endif /* PUNK_METRICS_H */

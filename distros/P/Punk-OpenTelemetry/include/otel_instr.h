/* otel_instr.h - where the spans actually come from.
 *
 * The observers registered with the hooks phase 1 added: Punk's pk_abi
 * request/response and query observers, Fetch's outbound observer, and
 * DBIx::Loop's statement observer. Each turns an event into a span.
 *
 * TWO RULES GOVERN EVERYTHING HERE.
 *
 * 1. THE SAMPLING DECISION COMES FIRST. Attributes are built only after a
 *    span exists. An unsampled request must not pay to assemble strings
 *    nobody will read - which is the whole reason otel_tracer_start returns
 *    NULL rather than a null object, and why every function below begins by
 *    checking for one.
 *
 * 2. http.route IS THE PATTERN OR IT IS ABSENT. Never the path. For a 404,
 *    a 405 or a mounted app, pk_abi's route_pattern_of returns NULL and the
 *    attribute is simply not set. Falling back to url.path there is the exact
 *    substitution that turns a bounded dimension into an unbounded one, and
 *    404 traffic is precisely where a scanner will hand you a million
 *    distinct values.
 */

#ifndef OTEL_INSTR_H
#define OTEL_INSTR_H

#include "pk_abi.h"        /* the observers below are typed by it */
#include "otel_semconv.h"
#include "otel_tracer.h"
#include "otel_w3c.h"

/* Which instrumentation points are live. Each is switchable on its own, so an
 * application drowning in database spans can turn those off without losing
 * its server spans. */
typedef struct {
    int server;
    int client;
    int db;
    int metrics;
    int enabled;         /* the master switch: OTEL_SDK_DISABLED */
    int suppress;        /* re-entrancy guard; see below */
} otel_instr_cfg;

static otel_instr_cfg OTEL_INSTR = { 1, 1, 1, 1, 1, 0 };
static otel_tracer   *OTEL_TRACER = NULL;

/* THE METER IS NOT THE TRACER, and the difference is the whole of the metrics
 * path below.
 *
 * A trace is a SAMPLE of requests. A duration histogram over a sample is not a
 * smaller histogram, it is a wrong one - so everything recorded here happens
 * on EVERY request, including the ones otel_tracer_start declined to build a
 * span for. What an unsampled request still must not pay is attribute
 * assembly, and it does not: the attributes are read on the response side out
 * of values that already exist there. */
static otel_meter *OTEL_METER = NULL;

/* THE RECURSION GUARD.
 *
 * The exporter sends spans over HTTP with Fetch. Fetch is instrumented. So an
 * export produces a client span, which is queued, and exported... The first
 * collector outage would otherwise become an infinite loop of telemetry about
 * failing to send telemetry.
 *
 * Everything the SDK does on its own behalf runs with this set, and every
 * instrumentation point below checks it. */
#define OTEL_SUPPRESSED (OTEL_INSTR.suppress || !OTEL_INSTR.enabled \
                         || !OTEL_TRACER)

static void otel_suppress_begin(void) { OTEL_INSTR.suppress++; }
static void otel_suppress_end(void)   { if (OTEL_INSTR.suppress)
                                            OTEL_INSTR.suppress--; }

/* ---- the per-request span slot ------------------------------------------ *
 * The server span starts in one callback and ends in another, so it has to
 * live somewhere in between. pk_abi hands both callbacks the SAME context and
 * will create its stash on demand, which is exactly the hook it was given for.
 */
#define OTEL_STASH_KEY "punk.otel.span"

/* The request's clock, stashed whatever the sampling decision was. Two
 * integers, no strings, no allocation beyond the SVs the stash needs. */
#define OTEL_CLOCK_KEY "punk.otel.t0"

static void otel_stash_span(pTHX_ const pk_abi *A, SV *c, otel_span *s) {
    SV *st = A->stash_of(aTHX_ c);
    if (!(st && SvROK(st) && SvTYPE(SvRV(st)) == SVt_PVHV)) return;
    (void)hv_store((HV *)SvRV(st), OTEL_STASH_KEY,
                   (I32)(sizeof(OTEL_STASH_KEY) - 1),
                   newSViv(PTR2IV(s)), 0);
}

/* Look, and leave it there. The response side ENDS the span it takes, so
 * taking is right exactly once; a parent lookup happens many times per request
 * and must leave the span where the response side will still find it. */
static otel_span *otel_peek_span(pTHX_ const pk_abi *A, SV *c) {
    SV *st;
    SV **e;
    if (!(A && c)) return NULL;
    st = A->stash_of(aTHX_ c);
    if (!(st && SvROK(st) && SvTYPE(SvRV(st)) == SVt_PVHV)) return NULL;
    e = hv_fetch((HV *)SvRV(st), OTEL_STASH_KEY,
                 (I32)(sizeof(OTEL_STASH_KEY) - 1), 0);
    if (!(e && *e && SvIOK(*e) && SvIV(*e))) return NULL;
    return INT2PTR(otel_span *, SvIV(*e));
}

static void otel_stash_clock(pTHX_ const pk_abi *A, SV *c,
                             U64TYPE wall, U64TYPE mono) {
    SV *st = A->stash_of(aTHX_ c);
    AV *av;
    if (!(st && SvROK(st) && SvTYPE(SvRV(st)) == SVt_PVHV)) return;
    av = newAV();
    av_push(av, newSVuv((UV)wall));
    av_push(av, newSVuv((UV)mono));
    (void)hv_store((HV *)SvRV(st), OTEL_CLOCK_KEY,
                   (I32)(sizeof(OTEL_CLOCK_KEY) - 1),
                   newRV_noinc((SV *)av), 0);
}

/* The duration in SECONDS, which is the unit the conventions name, or -1 when
 * this request was never clocked. */
static double otel_unstash_duration(pTHX_ const pk_abi *A, SV *c) {
    SV *st = A->stash_of(aTHX_ c);
    SV **e;
    AV *av;
    SV **w, **m;
    if (!(st && SvROK(st) && SvTYPE(SvRV(st)) == SVt_PVHV)) return -1;
    e = hv_fetch((HV *)SvRV(st), OTEL_CLOCK_KEY,
                 (I32)(sizeof(OTEL_CLOCK_KEY) - 1), 0);
    if (!(e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV)) return -1;
    av = (AV *)SvRV(*e);
    w = av_fetch(av, 0, 0);
    m = av_fetch(av, 1, 0);
    if (!(w && *w && m && *m)) return -1;
    {
        U64TYPE start_wall = (U64TYPE)SvUV(*w);
        U64TYPE end = otel_end_nanos(start_wall, (U64TYPE)SvUV(*m));
        return (end > start_wall) ? (double)(end - start_wall) / 1e9 : 0.0;
    }
}

static otel_span *otel_unstash_span(pTHX_ const pk_abi *A, SV *c) {
    SV *st = A->stash_of(aTHX_ c);
    SV **e;
    otel_span *s;
    if (!(st && SvROK(st) && SvTYPE(SvRV(st)) == SVt_PVHV)) return NULL;
    e = hv_fetch((HV *)SvRV(st), OTEL_STASH_KEY,
                 (I32)(sizeof(OTEL_STASH_KEY) - 1), 0);
    if (!(e && *e && SvIOK(*e) && SvIV(*e))) return NULL;
    s = INT2PTR(otel_span *, SvIV(*e));
    sv_setiv(*e, 0);          /* taken: a second response event finds nothing */
    return s;
}

/* The span a child should hang off: the server span of the request whose
 * dispatch frame is running right now, or NULL.
 *
 * pk_abi v5. Below it there is no way to ask, and every child is a root - the
 * behaviour this whole release exists to end, kept as the degraded path so an
 * older Punk still works rather than failing to load. */
static otel_span *otel_current_span(pTHX_ const pk_abi *A) {
    SV *c;
    if (!(A && A->abi_version >= 5)) return NULL;
    c = A->current_of(aTHX);
    return c ? otel_peek_span(aTHX_ A, c) : NULL;
}

/* ---- a borrowed env string ---------------------------------------------- */
static const char *otel_env_str(pTHX_ HV *env, const char *k, STRLEN *len) {
    SV **e = env ? hv_fetch(env, k, (I32)strlen(k), 0) : NULL;
    if (e && *e && SvOK(*e)) return SvPV_const(*e, *len);
    *len = 0;
    return NULL;
}

/* ---- the server span ---------------------------------------------------- */

static void otel_on_request(pTHX_ SV *c, void *ud) {
    const pk_abi *A = (const pk_abi *)ud;
    SV *envsv;
    HV *env;
    otel_ctx ctx;
    otel_span *s;
    const char *m, *tp;
    STRLEN ml, tpl;
    SV *name;
    int has_parent = 0;

    if (OTEL_INSTR.suppress || !OTEL_INSTR.enabled) return;

    /* THE CLOCK STARTS BEFORE THE SAMPLING DECISION, AND BEFORE THE SERVER
     * SWITCH.
     *
     * A duration histogram over the sampled requests is not a smaller
     * histogram, it is a wrong one - so every request is clocked, including
     * the ones that get no span at all, and including a process that has
     * turned server SPANS off and kept its metrics. Two integers into the
     * stash the dispatcher has already built.
     *
     * The file's first rule is about not assembling STRINGS for a request
     * nobody will read. None are assembled here, and none on the way out
     * either: the response side reads values that already exist. */
    if (OTEL_METER && OTEL_INSTR.metrics)
        otel_stash_clock(aTHX_ A, c, otel_wall_nanos(), otel_mono_nanos());

    if (!OTEL_TRACER || !OTEL_INSTR.server) return;
    envsv = A->env_of(aTHX_ c);
    env = (envsv && SvROK(envsv) && SvTYPE(SvRV(envsv)) == SVt_PVHV)
          ? (HV *)SvRV(envsv) : NULL;
    if (!env) return;

    /* the inbound context, if any. An unparseable header is absent, not an
     * error, so this can only ever leave us starting a root span. */
    otel_ctx_clear(&ctx);
    tp = otel_env_str(aTHX_ env, "HTTP_TRACEPARENT", &tpl);
    if (tp && otel_w3c_parse(tp, tpl, &ctx)) has_parent = 1;

    /* The span name. At request start the route is NOT known - routing has
     * not happened - so the method alone is the honest name, and the response
     * side upgrades it to "GET /users/:id" once the pattern exists. Naming it
     * after the PATH here would be the cardinality mistake, permanently. */
    m = otel_env_str(aTHX_ env, "REQUEST_METHOD", &ml);
    name = sv_2mortal(newSVpvn(m ? m : "HTTP", m ? ml : 4));

    s = otel_tracer_start(aTHX_ OTEL_TRACER,
                          has_parent ? ctx.trace_id : NULL,
                          has_parent ? ctx.span_id  : NULL,
                          has_parent ? (ctx.flags & OTEL_FLAG_SAMPLED) : 0,
                          name, OTEL_KIND_SERVER);
    if (!s) return;                       /* not sampled: nothing was built */

    /* Everything below happens ONLY for a sampled request. */
    {
        const char *v;
        STRLEN vl;
        const char *canon = otel_sc_method(m, ml);
        SV *k = sv_2mortal(newSVpvs(SC_HTTP_METHOD));
        otel_span_attr(aTHX_ s, k,
            sv_2mortal(newSVpv(canon ? canon : "_OTHER", 0)));
        if (!canon && m) {
            /* an unknown method is bounded to _OTHER, and the raw value kept
             * separately where it cannot become a metric dimension */
            SV *ko = sv_2mortal(newSVpvs(SC_HTTP_METHOD_ORIGINAL));
            otel_span_attr(aTHX_ s, ko, sv_2mortal(newSVpvn(m, ml)));
        }
        if ((v = otel_env_str(aTHX_ env, "PATH_INFO", &vl))) {
            SV *kk = sv_2mortal(newSVpvs(SC_URL_PATH));
            otel_span_attr(aTHX_ s, kk, sv_2mortal(newSVpvn(v, vl)));
        }
        if ((v = otel_env_str(aTHX_ env, "QUERY_STRING", &vl)) && vl) {
            SV *kk = sv_2mortal(newSVpvs(SC_URL_QUERY));
            otel_span_attr(aTHX_ s, kk, sv_2mortal(newSVpvn(v, vl)));
        }
        if ((v = otel_env_str(aTHX_ env, "psgi.url_scheme", &vl))) {
            SV *kk = sv_2mortal(newSVpvs(SC_URL_SCHEME));
            otel_span_attr(aTHX_ s, kk, sv_2mortal(newSVpvn(v, vl)));
        }
        if ((v = otel_env_str(aTHX_ env, "HTTP_USER_AGENT", &vl))) {
            SV *kk = sv_2mortal(newSVpvs(SC_USER_AGENT));
            otel_span_attr(aTHX_ s, kk, sv_2mortal(newSVpvn(v, vl)));
        }
        /* REMOTE_ADDR, which Punk has already rewritten to the real client
         * when a `proxy` policy is configured - so this is the right value
         * for free, and the wrong one (the proxy) when it is not. */
        if ((v = otel_env_str(aTHX_ env, "REMOTE_ADDR", &vl))) {
            SV *kk = sv_2mortal(newSVpvs(SC_CLIENT_ADDRESS));
            otel_span_attr(aTHX_ s, kk, sv_2mortal(newSVpvn(v, vl)));
        }
        if ((v = otel_env_str(aTHX_ env, "SERVER_NAME", &vl))) {
            SV *kk = sv_2mortal(newSVpvs(SC_SERVER_ADDRESS));
            otel_span_attr(aTHX_ s, kk, sv_2mortal(newSVpvn(v, vl)));
        }
    }
    otel_stash_span(aTHX_ A, c, s);
}

/* http.server.request.duration, on EVERY request.
 *
 * The three attributes are the bounded ones and only those. http.route is the
 * declared pattern or it is ABSENT - never url.path, which is the substitution
 * that turns a bounded dimension into an unbounded one, and a metric label is
 * where that costs the most: a scanner's million 404 paths become a million
 * series, and the cardinality cap then drops whatever arrives next.
 *
 * `span` is the exemplar and is NULL for an unsampled request, which is
 * exactly right: the measurement still counts, it just has no trace to point
 * at. */
static void otel_metric_response(pTHX_ const pk_abi *A, SV *c, IV status,
                                 SV *route, otel_span *span) {
    otel_instrument *in;
    HV *attrs;
    double secs;
    SV *env;
    const char *m = NULL;
    STRLEN ml = 0;

    if (!OTEL_METER || !OTEL_INSTR.metrics) return;
    secs = otel_unstash_duration(aTHX_ A, c);
    if (secs < 0) return;                 /* never clocked: nothing to say */

    otel_meter_check_fork(aTHX_ OTEL_METER);
    {
        SV *name = sv_2mortal(newSVpvs(SC_HTTP_SERVER_DURATION));
        SV *unit = sv_2mortal(newSVpvs("s"));
        in = otel_meter_instrument(aTHX_ OTEL_METER, name,
                                   OTEL_INSTR_HISTOGRAM, unit, NULL);
    }
    if (!in) return;

    attrs = (HV *)sv_2mortal((SV *)newHV());
    env = A->env_of(aTHX_ c);
    if (env && SvROK(env) && SvTYPE(SvRV(env)) == SVt_PVHV)
        m = otel_env_str(aTHX_ (HV *)SvRV(env), "REQUEST_METHOD", &ml);
    {
        const char *canon = otel_sc_method(m, ml);
        (void)hv_stores(attrs, SC_HTTP_METHOD,
                        newSVpv(canon ? canon : "_OTHER", 0));
    }
    if (route && SvOK(route))
        (void)hv_stores(attrs, SC_HTTP_ROUTE, newSVsv(route));
    if (status > 0)
        (void)hv_stores(attrs, SC_HTTP_STATUS, newSViv(status));

    otel_instr_record(aTHX_ in, secs,
                      otel_view_filter(aTHX_ OTEL_METER,
                          sv_2mortal(newSVpvs(SC_HTTP_SERVER_DURATION)), attrs),
                      span);
}

static void otel_on_response(pTHX_ SV *c, SV *response, void *ud) {
    const pk_abi *A = (const pk_abi *)ud;
    otel_span *s;
    IV status;
    SV *route, *op;

    if (OTEL_INSTR.suppress || !OTEL_INSTR.enabled) return;

    /* THE METRIC FIRST, because it does not depend on there being a span and
     * must not be skipped with one. The route and status are read once here
     * and handed to both. */
    route  = A->route_pattern_of(aTHX_ c);
    if (!(route && SvOK(route))) {
        SV *o = A->operation_of(aTHX_ c);
        if (o && SvOK(o)) route = o;      /* an API operation is bounded too */
        else route = NULL;
    }
    status = A->status_of(aTHX_ response);

    s = (OTEL_TRACER && OTEL_INSTR.server)
        ? otel_unstash_span(aTHX_ A, c) : NULL;

    otel_metric_response(aTHX_ A, c, status, route, s);

    if (!s) return;                       /* unsampled, or already finished */

    /* http.route is the DECLARED pattern, and absent when there is none.
     * Never url.path - that substitution is how a bounded dimension becomes
     * unbounded, and 404 traffic is where a scanner supplies the million
     * distinct values. Read above, so the span and the metric cannot disagree
     * about what the route was. */
    if (route && SvOK(route)) {
        SV *k = sv_2mortal(newSVpvs(SC_HTTP_ROUTE));
        otel_span_attr(aTHX_ s, k, route);
        /* now the span can be named properly: "GET /users/:id" */
        if (s->name) {
            SV *n = newSVsv(s->name);
            sv_catpvs(n, " ");
            sv_catsv(n, route);
            SvREFCNT_dec(s->name);
            s->name = n;
        }
    }
    else if ((op = A->operation_of(aTHX_ c)) && SvOK(op)) {
        /* an API operation has no route pattern; its operationId is the
         * bounded identifier that plays the same part */
        SV *k = sv_2mortal(newSVpvs(SC_HTTP_ROUTE));
        otel_span_attr(aTHX_ s, k, op);
        if (s->name) {
            SV *n = newSVsv(s->name);
            sv_catpvs(n, " ");
            sv_catsv(n, op);
            SvREFCNT_dec(s->name);
            s->name = n;
        }
    }

    status = A->status_of(aTHX_ response);
    if (status > 0) {
        SV *k = sv_2mortal(newSVpvs(SC_HTTP_STATUS));
        otel_span_attr(aTHX_ s, k, sv_2mortal(newSViv(status)));
        s->status_code = otel_sc_server_status(status);
        if (s->status_code == OTEL_STATUS_ERROR) {
            SV *ek = sv_2mortal(newSVpvs(SC_ERROR_TYPE));
            otel_span_attr(aTHX_ s, ek, sv_2mortal(newSViv(status)));
        }
    }
    otel_span_end(aTHX_ s);
    otel_tracer_enqueue(aTHX_ OTEL_TRACER, s);
    OTEL_TRACER->ended++;
}

/* ---- database spans ----------------------------------------------------- *
 * Both database paths report the same way. The statement text is the PREPARED
 * one - the observers in phase 1 do not pass bind values at all, so this
 * cannot leak the literal data even by accident. */

static otel_span *otel_db_start(pTHX_ const pk_abi *A, const char *sql,
                                STRLEN len, int nbind, const char *system) {
    otel_span *s, *parent;
    char op[32];
    SV *name;
    if (OTEL_SUPPRESSED || !OTEL_INSTR.db) return NULL;

    /* the span is named for the OPERATION, not the statement: a name is a
     * grouping key, and one distinct name per distinct SQL string is another
     * unbounded dimension */
    if (otel_sc_db_operation(sql, len, op, sizeof op))
        name = sv_2mortal(newSVpv(op, 0));
    else
        name = sv_2mortal(newSVpvs("query"));

    /* THE REQUEST THAT ISSUED IT IS THE PARENT.
     *
     * Started with a NULL parent this opened a BRAND NEW TRACE for every
     * statement: the query span was a root, and a store filled up with traces
     * one span long while the request that ran the query sat in a different
     * trace of its own. It is the same fault the outbound client span had, and
     * the same fix, arriving late because the observer is handed no context
     * and until pk_abi v5 there was nowhere to ask.
     *
     * Not a process-global: current_of is live only inside a dispatch frame,
     * so a statement from a queue job or a continuation still reads NULL and
     * is still an honest root. No parent, never the wrong one. */
    parent = otel_current_span(aTHX_ A);
    s = otel_tracer_start(aTHX_ OTEL_TRACER,
                          parent ? parent->trace_id : NULL,
                          parent ? parent->span_id  : NULL,
                          parent ? parent->sampled  : 0,
                          name, OTEL_KIND_CLIENT);
    if (!s) return NULL;
    {
        SV *k = sv_2mortal(newSVpvs(SC_DB_QUERY_TEXT));
        otel_span_attr(aTHX_ s, k, sv_2mortal(newSVpvn(sql, len)));
        if (system) {
            SV *ks = sv_2mortal(newSVpvs(SC_DB_SYSTEM));
            otel_span_attr(aTHX_ s, ks, sv_2mortal(newSVpv(system, 0)));
        }
        if (op[0]) {
            SV *ko = sv_2mortal(newSVpvs(SC_DB_OPERATION));
            otel_span_attr(aTHX_ s, ko, sv_2mortal(newSVpv(op, 0)));
        }
        PERL_UNUSED_VAR(nbind);
    }
    return s;
}

static void otel_db_end(pTHX_ otel_span *s, int ok) {
    if (!s) return;
    if (!ok) s->status_code = OTEL_STATUS_ERROR;
    otel_span_end(aTHX_ s);
    if (OTEL_TRACER) {
        otel_tracer_enqueue(aTHX_ OTEL_TRACER, s);
        OTEL_TRACER->ended++;
    }
    else otel_span_free(aTHX_ s);
}

/* pk_abi's on_query: the shipped Punk::Model::DBI backend, and - since Punk
 * 0.50 - every statement run through its handle, not only the six generated
 * methods. `ud` is the table, so the parent can be looked up. */
static void *otel_on_query(pTHX_ const char *sql, STRLEN len, int nbind,
                           void *ud) {
    return (void *)otel_db_start(aTHX_ (const pk_abi *)ud, sql, len, nbind,
                                 "other_sql");
}

static void otel_on_query_done(pTHX_ void *token, int ok, void *ud) {
    PERL_UNUSED_ARG(ud);
    otel_db_end(aTHX_ (otel_span *)token, ok);
}

#endif /* OTEL_INSTR_H */

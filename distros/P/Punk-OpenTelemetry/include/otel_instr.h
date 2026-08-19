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
    int enabled;         /* the master switch: OTEL_SDK_DISABLED */
    int suppress;        /* re-entrancy guard; see below */
} otel_instr_cfg;

static otel_instr_cfg OTEL_INSTR = { 1, 1, 1, 1, 0 };
static otel_tracer   *OTEL_TRACER = NULL;

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

static void otel_stash_span(pTHX_ const pk_abi *A, SV *c, otel_span *s) {
    SV *st = A->stash_of(aTHX_ c);
    if (!(st && SvROK(st) && SvTYPE(SvRV(st)) == SVt_PVHV)) return;
    (void)hv_store((HV *)SvRV(st), OTEL_STASH_KEY,
                   (I32)(sizeof(OTEL_STASH_KEY) - 1),
                   newSViv(PTR2IV(s)), 0);
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

    if (OTEL_SUPPRESSED || !OTEL_INSTR.server) return;
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

static void otel_on_response(pTHX_ SV *c, SV *response, void *ud) {
    const pk_abi *A = (const pk_abi *)ud;
    otel_span *s;
    IV status;
    SV *route, *op;

    if (!OTEL_TRACER || !OTEL_INSTR.server) return;
    s = otel_unstash_span(aTHX_ A, c);
    if (!s) return;                       /* unsampled, or already finished */

    /* http.route is the DECLARED pattern, and absent when there is none.
     * Never url.path - that substitution is how a bounded dimension becomes
     * unbounded, and 404 traffic is where a scanner supplies the million
     * distinct values. */
    route = A->route_pattern_of(aTHX_ c);
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

static otel_span *otel_db_start(pTHX_ const char *sql, STRLEN len, int nbind,
                                const char *system) {
    otel_span *s;
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

    s = otel_tracer_start(aTHX_ OTEL_TRACER, NULL, NULL, 0, name,
                          OTEL_KIND_CLIENT);
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

/* pk_abi's on_query: the shipped Punk::Model::DBI backend. */
static void *otel_on_query(pTHX_ const char *sql, STRLEN len, int nbind,
                           void *ud) {
    PERL_UNUSED_ARG(ud);
    return (void *)otel_db_start(aTHX_ sql, len, nbind, "other_sql");
}

static void otel_on_query_done(pTHX_ void *token, int ok, void *ud) {
    PERL_UNUSED_ARG(ud);
    otel_db_end(aTHX_ (otel_span *)token, ok);
}

#endif /* OTEL_INSTR_H */

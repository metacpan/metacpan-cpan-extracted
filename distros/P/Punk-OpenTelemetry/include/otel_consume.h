/* otel_consume.h - resolving the ABIs this dist instruments through, and the
 * Fetch client observer that needs them.
 *
 * Punk's pk_abi and Fetch's fetch_abi are both resolved LAZILY and both are
 * OPTIONAL. A process that has loaded neither still gets a working tracer -
 * manual spans, encoders, exporter - and simply has nothing automatic to
 * observe. That is the difference between a telemetry layer and a
 * dependency: this one attaches to what is there.
 *
 * Included after otel_instr.h, which defines the callbacks, and before
 * xs/instrument.xs, which registers them.
 */

#ifndef OTEL_CONSUME_H
#define OTEL_CONSUME_H

#include "fetch_abi.h"   /* pk_abi.h comes in with otel_instr.h */
#include "dbil_abi.h"    /* DBIx::Loop's statement observer */

/* A header name compared without regard to case, because HTTP field names
 * are case-insensitive and a caller writing `TraceParent` has set the header
 * whatever this file thinks of the spelling. Written out rather than reached
 * for through strncasecmp, which is locale-dependent: in a Turkish locale
 * tolower('I') is not 'i'. */
static int otel_ieq(const char *a, const char *b, STRLEN n) {
    STRLEN i;
    for (i = 0; i < n; i++) {
        char x = a[i], y = b[i];
        if (x >= 'A' && x <= 'Z') x = (char)(x - 'A' + 'a');
        if (y >= 'A' && y <= 'Z') y = (char)(y - 'A' + 'a');
        if (x != y) return 0;
    }
    return 1;
}

static const pk_abi    *OTEL_PK = NULL;
static const fetch_abi *OTEL_FT = NULL;
static const dbil_abi  *OTEL_DL = NULL;
static int OTEL_PK_TRIED = 0, OTEL_FT_TRIED = 0, OTEL_DL_TRIED = 0;
static int OTEL_PK_INSTALLED = 0, OTEL_FT_INSTALLED = 0, OTEL_DL_INSTALLED = 0;
/* What the one-and-only registration actually managed, kept so that a LATER
 * install() reports the same answer. Registration is process-global and
 * happens once; a second application asking what is installed was being told
 * only about the server hook, so a test - or an operator - reading the
 * report from any app but the first saw the logs signal as absent when it was
 * running. */
static int OTEL_PK_DB = 0, OTEL_PK_LOGS = 0, OTEL_DL_DB = 0;

/* The shared shape of an optional ABI lookup: require the module, call its
 * _abi_ptr, check the version. A miss is NOT an error - it means that dist is
 * not in this process, and there is simply nothing of its kind to instrument. */
static UV otel_abi_ptr(pTHX_ const char *module, const char *fn) {
    dSP;
    int count;
    UV p = 0;
    SV *req = sv_2mortal(newSVpvf("require %s;", module));
    eval_pv(SvPV_nolen(req), FALSE);
    SPAGAIN;                      /* the require ran Perl; the stack may move */
    if (SvTRUE(ERRSV)) return 0;
    ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
    count = call_pv(fn, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) p = POPu;
    else if (count > 0)             (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    return p;
}

static const pk_abi *otel_pk(pTHX) {
    if (!OTEL_PK && !OTEL_PK_TRIED) {
        UV p;
        OTEL_PK_TRIED = 1;
        p = otel_abi_ptr(aTHX_ "Punk", "Punk::_abi_ptr");
        if (p) {
            const pk_abi *a = INT2PTR(const pk_abi *, p);
            /* >=, not ==: the table only ever grows, so a NEWER Punk is a
             * superset we use a prefix of. Requiring equality would make
             * every Punk release break this dist for no reason. */
            if (a && a->abi_version >= 1) OTEL_PK = a;
        }
    }
    return OTEL_PK;
}

static const fetch_abi *otel_ft(pTHX) {
    if (!OTEL_FT && !OTEL_FT_TRIED) {
        UV p;
        OTEL_FT_TRIED = 1;
        p = otel_abi_ptr(aTHX_ "Fetch", "Fetch::_abi_ptr");
        if (p) {
            const fetch_abi *a = INT2PTR(const fetch_abi *, p);
            /* the outbound observer is v2; an older Fetch has no hook to
             * attach to, so there is nothing to do rather than something to
             * complain about */
            if (a && a->abi_version >= 2) OTEL_FT = a;
        }
    }
    return OTEL_FT;
}

static const dbil_abi *otel_dl(pTHX) {
    if (!OTEL_DL && !OTEL_DL_TRIED) {
        UV p;
        OTEL_DL_TRIED = 1;
        p = otel_abi_ptr(aTHX_ "DBIx::Loop", "DBIx::Loop::_abi_ptr");
        if (p) {
            const dbil_abi *a = INT2PTR(const dbil_abi *, p);
            /* the statement observer is v2 */
            if (a && a->abi_version >= 2) OTEL_DL = a;
        }
    }
    return OTEL_DL;
}

/* ---- DBIx::Loop's statements -------------------------------------------- *
 * The OTHER database path. An application on the async backend generates no
 * pk_abi query traffic at all, so registering only there left a whole class of
 * application with no database spans and nothing to say why - which three
 * comments in this distribution claimed was already handled, and was not.
 *
 * dbil_exec is the one place all three of its backends have in common, and it
 * fires this BEFORE the statement runs, synchronously with the caller. So the
 * dispatch frame is still on the stack and current_of is the request that
 * issued it - an async backend is no obstacle to parenting, because a span's
 * parent is fixed at start and start is never the deferred half. */
static void *otel_dl_start(pTHX_ int is_query, const char *sql, STRLEN len,
                           int nbind, void *ud) {
    PERL_UNUSED_ARG(is_query);
    return (void *)otel_db_start(aTHX_ otel_pk(aTHX), sql, len, nbind,
                                 (const char *)ud);
}

/* Exactly one of res and err is non-NULL; both borrowed. */
static void otel_dl_done(pTHX_ void *token, SV *res, SV *err, void *ud) {
    PERL_UNUSED_ARG(res);
    PERL_UNUSED_ARG(ud);
    otel_db_end(aTHX_ (otel_span *)token, err ? 0 : 1);
}

/* ---- the outbound client observer --------------------------------------- *
 * Two jobs, and the second is the one that makes distributed tracing work at
 * all: measure the call, and INJECT the traceparent so the far side continues
 * this trace instead of starting its own. */

static void *otel_ft_start(pTHX_ const char *method, STRLEN mlen,
                           const char *url, STRLEN ulen, AV *headers,
                           void *ud) {
    otel_span *s;
    SV *name;
    const char *canon;
    PERL_UNUSED_ARG(ud);

    if (OTEL_SUPPRESSED || !OTEL_INSTR.client) return NULL;

    canon = otel_sc_method(method, mlen);
    name = sv_2mortal(newSVpv(canon ? canon : "HTTP", 0));

    /* A `traceparent` THE CALLER ALREADY SET IS THE PARENT.
     *
     * Started with a NULL parent, every outbound call opened a BRAND NEW
     * TRACE: the client span was a root, the header derived from it named
     * that new trace, and the callee's server span joined a trace containing
     * nothing but itself. The visible effect is a store in which every trace
     * is one span long and no service map edge ever crosses a process.
     *
     * A caller that propagated deliberately keeps that precedence: its own
     * header wins, and its call is joined to its own trace rather than
     * silently overridden.
     *
     * WITH NO HEADER, THE REQUEST BEING SERVED IS THE PARENT. This used to say
     * there was no ambient current span to take instead - that two requests
     * are in flight on one worker at any moment and a process-global would
     * attribute one request's calls to the other. That was true of a global
     * that outlived its frame. pk_abi v5's current_of does not: it is saved
     * and restored around the dispatch frame, so a call made from a
     * continuation or a queue job reads NULL and is still a root. The
     * degraded answer is no parent, never the wrong one.
     */
    {
        SSize_t i, n = headers ? (av_len(headers) + 1) : 0;
        otel_ctx in;
        int have = 0;
        otel_ctx_clear(&in);

        for (i = 0; i + 1 < n; i += 2) {
            SV **k = av_fetch(headers, i, 0);
            SV **v = av_fetch(headers, i + 1, 0);
            STRLEN kl, vl;
            const char *kp, *vp;
            if (!k || !*k || !v || !*v) continue;
            kp = SvPV_const(*k, kl);
            if (kl != 11 || !otel_ieq(kp, "traceparent", 11)) continue;
            vp = SvPV_const(*v, vl);
            have = otel_w3c_parse(vp, vl, &in);
            break;
        }

        if (have)
            s = otel_tracer_start(aTHX_ OTEL_TRACER, in.trace_id, in.span_id,
                                  (in.flags & OTEL_FLAG_SAMPLED) ? 1 : 0,
                                  name, OTEL_KIND_CLIENT);
        else {
            otel_span *p = otel_current_span(aTHX_ otel_pk(aTHX));
            s = otel_tracer_start(aTHX_ OTEL_TRACER,
                                  p ? p->trace_id : NULL,
                                  p ? p->span_id  : NULL,
                                  p ? p->sampled  : 0,
                                  name, OTEL_KIND_CLIENT);
        }
    }
    if (!s) return NULL;

    {
        SV *k = sv_2mortal(newSVpvs(SC_HTTP_METHOD));
        otel_span_attr(aTHX_ s, k,
            sv_2mortal(newSVpv(canon ? canon : "_OTHER", 0)));
        if (!canon) {
            SV *ko = sv_2mortal(newSVpvs(SC_HTTP_METHOD_ORIGINAL));
            otel_span_attr(aTHX_ s, ko, sv_2mortal(newSVpvn(method, mlen)));
        }
        /* url.full on a CLIENT span is bounded by what this process calls,
         * not by what a client sends it, so it is safe here in a way the
         * server-side path never is */
        {
            SV *ku = sv_2mortal(newSVpvs(SC_URL_FULL));
            otel_span_attr(aTHX_ s, ku, sv_2mortal(newSVpvn(url, ulen)));
        }
    }

    /* The traceparent. Without this the far side starts a new trace and the
     * two halves of the call are never joined - which is the entire point of
     * the hook Fetch grew.
     *
     * SET IN PLACE WHERE ONE IS ALREADY THERE, never appended beside it. Two
     * `traceparent` headers on one request is not a request with a fallback:
     * it is malformed, the callee picks whichever it picks, and the trace
     * joins up or does not depending on which. The value is REPLACED rather
     * than left alone because the callee should be a child of this client
     * span - which is itself now a child of whatever the caller propagated,
     * so the chain is caller -> client -> callee either way. */
    {
        otel_ctx ctx;
        char buf[56];
        SSize_t i, n = headers ? (av_len(headers) + 1) : 0;
        int replaced = 0;

        otel_ctx_clear(&ctx);
        Copy(s->trace_id, ctx.trace_id, 16, unsigned char);
        Copy(s->span_id,  ctx.span_id,   8, unsigned char);
        ctx.flags = OTEL_FLAG_SAMPLED;    /* the span exists, so it is sampled */
        otel_w3c_format(&ctx, buf);

        for (i = 0; i + 1 < n; i += 2) {
            SV **k = av_fetch(headers, i, 0);
            SV **v = av_fetch(headers, i + 1, 0);
            STRLEN kl;
            const char *kp;
            if (!k || !*k || !v || !*v) continue;
            kp = SvPV_const(*k, kl);
            if (kl != 11 || !otel_ieq(kp, "traceparent", 11)) continue;
            sv_setpv(*v, buf);
            replaced = 1;
            break;
        }
        if (!replaced) {
            av_push(headers, newSVpvs("traceparent"));
            av_push(headers, newSVpv(buf, 0));
        }
    }
    return (void *)s;
}

static void otel_ft_done(pTHX_ void *token, SV *res, SV *err, void *ud) {
    otel_span *s = (otel_span *)token;
    PERL_UNUSED_ARG(ud);
    if (!s) return;

    if (err) {
        /* a timeout, a refused connection, a DNS failure: the endings an
         * instrumented client most wants and the easiest to lose */
        s->status_code = OTEL_STATUS_ERROR;
        if (SvOK(err)) {
            SV *k = sv_2mortal(newSVpvs(SC_ERROR_TYPE));
            otel_span_attr(aTHX_ s, k, err);
        }
    }
    else if (res && OTEL_FT) {
        int status = 0;
        OTEL_FT->res_parts(aTHX_ res, &status, NULL, NULL);
        if (status > 0) {
            SV *k = sv_2mortal(newSVpvs(SC_HTTP_STATUS));
            otel_span_attr(aTHX_ s, k, sv_2mortal(newSViv(status)));
            /* on a CLIENT span a 4xx IS a failure of the call this process
             * made, which is the opposite of the server-side rule */
            s->status_code = otel_sc_client_status(status);
        }
    }
    otel_span_end(aTHX_ s);
    if (OTEL_TRACER) {
        otel_tracer_enqueue(aTHX_ OTEL_TRACER, s);
        OTEL_TRACER->ended++;
    }
    else otel_span_free(aTHX_ s);
}

#endif /* OTEL_CONSUME_H */

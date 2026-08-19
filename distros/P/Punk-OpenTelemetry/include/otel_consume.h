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

static const pk_abi    *OTEL_PK = NULL;
static const fetch_abi *OTEL_FT = NULL;
static int OTEL_PK_TRIED = 0, OTEL_FT_TRIED = 0;
static int OTEL_PK_INSTALLED = 0, OTEL_FT_INSTALLED = 0;

/* The shared shape of an optional ABI lookup: require the module, call its
 * _abi_ptr, check the version. A miss is NOT an error - it means that dist is
 * not in this process, and there is simply nothing of its kind to instrument. */
static IV otel_abi_ptr(pTHX_ const char *module, const char *fn) {
    dSP;
    int count;
    IV p = 0;
    SV *req = sv_2mortal(newSVpvf("require %s;", module));
    eval_pv(SvPV_nolen(req), FALSE);
    SPAGAIN;                      /* the require ran Perl; the stack may move */
    if (SvTRUE(ERRSV)) return 0;
    ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
    count = call_pv(fn, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) p = POPi;
    else if (count > 0)             (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    return p;
}

static const pk_abi *otel_pk(pTHX) {
    if (!OTEL_PK && !OTEL_PK_TRIED) {
        IV p;
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
        IV p;
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
    s = otel_tracer_start(aTHX_ OTEL_TRACER, NULL, NULL, 0, name,
                          OTEL_KIND_CLIENT);
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
     * the hook Fetch grew. */
    {
        otel_ctx ctx;
        char buf[56];
        otel_ctx_clear(&ctx);
        Copy(s->trace_id, ctx.trace_id, 16, unsigned char);
        Copy(s->span_id,  ctx.span_id,   8, unsigned char);
        ctx.flags = OTEL_FLAG_SAMPLED;    /* the span exists, so it is sampled */
        otel_w3c_format(&ctx, buf);
        av_push(headers, newSVpvs("traceparent"));
        av_push(headers, newSVpv(buf, 0));
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

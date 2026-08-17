/* punk_dispatch.h - the Open::API C ABI dispatch path (phase 6).
 *
 * Punk reaches Open::API's router and validator through its public C ABI
 * (oa_abi.h, reached through ExtUtils::Depends). Open::API 0.04+ is a hard
 * prerequisite, so the table is always there - punk_oa croaks if it is not,
 * the same startup-environment error punk_frj raises. There is no Perl
 * fallback.
 *
 * punk_oa_dispatch runs a matched API operation end to end in C: the
 * before-dispatch hooks and the operation's guards (Perl coderefs, via
 * call_sv, still short-circuitable), the body-size and no-handler checks, the
 * raw-input assembly and validation through the ABI, stashing the typed
 * params, and the controller call - returning the controller's value (or an
 * early PSGI triplet) and any die to Punk::App's finish path. The only Perl
 * frames are the hooks, the guards and the controller themselves.
 *
 * Perl headers, punk_response.h (punk_triplet), punk_request.h,
 * punk_context.h (pcx_av and the PCX_* slots) and the punk_frj resolver must
 * be in scope before this file.
 */

#ifndef PUNK_DISPATCH_H
#define PUNK_DISPATCH_H

#include "oa_abi.h"       /* Open::API's public ABI, via ExtUtils::Depends */

#define PD_ERR_413 "{\"errors\":[{\"message\":\"Payload Too Large\"}]}"
#define PD_ERR_501 "{\"errors\":[{\"message\":\"Not Implemented\"}]}"

static const oa_abi *PUNK_OA = NULL;
static int PUNK_OA_TRIED = 0;

/* Resolve (once) Open::API's ABI table, or NULL. PUNK_FAKE_OA_BAD simulates a
 * version mismatch for the guard test. */
static const oa_abi *punk_oa_try(pTHX) {
    if (!PUNK_OA_TRIED) {
        dSP; int count, ok; IV p = 0;
        PUNK_OA_TRIED = 1;
        ok = pk_require_once(aTHX_ "Open::API", FALSE);
        SPAGAIN;   /* the require may have reallocated the value stack */
        if (ok) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("Open::API::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const oa_abi *a = INT2PTR(const oa_abi *, p);
                if (a && !getenv("PUNK_FAKE_OA_BAD")
                    && a->abi_version == OA_ABI_VERSION)
                    PUNK_OA = a;
            }
        }
    }
    return PUNK_OA;
}

/* The ABI table, croaking if it is missing or the version does not match -
 * Open::API 0.04+ is required, so this is a boot-environment error, not a
 * per-request fallback. */
static const oa_abi *punk_oa(pTHX) {
    const oa_abi *a = punk_oa_try(aTHX);
    if (!a)
        croak("Punk: the API path needs Open::API with a compatible C ABI "
              "(OA_ABI_VERSION %d); upgrade Open::API to 0.04+", OA_ABI_VERSION);
    return a;
}

/* The env hashref of a Punk::Context (its env accessor). */
static HV *pd_c_env(pTHX_ SV *c) {
    dSP; HV *env = NULL; int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, 1); PUSHs(c); PUTBACK;
    count = call_method("env", G_SCALAR);
    SPAGAIN;
    if (count > 0) {
        SV *e = POPs;
        if (SvROK(e) && SvTYPE(SvRV(e)) == SVt_PVHV) env = (HV *)SvRV(e);
    }
    PUTBACK; FREETMPS; LEAVE;
    return env;
}

/* Stash the validated params in the context's openapi_params slot.
 *
 * A direct store into the slot, not a call to the accessor:
 * punk_context.h's PCX_* enum is the same slot contract xs/context.xs reads
 * through, so there is nothing a Perl call would add except a frame on the
 * hot path.
 *
 * It used to be call_pv(..., G_VOID), which was wrong in a way worth
 * recording. G_VOID is not G_DISCARD: it calls the sub in void context but
 * still leaves whatever the sub pushed on the stack for the caller to remove,
 * and the accessor pushes the value it just set. Nothing here removed it, so
 * every validated request left one stray SV on the Perl stack. It went
 * unnoticed until the frame unwound: Punk::Mount::OpenAPI::dispatch returns
 * ($ret, $err), so pp_leavesub found three values where two were expected and
 * died copying the extra one ("Bizarre copy of HASH in subroutine exit"),
 * then took the temps stack down with it.
 *
 * Takes ownership of typed_ref (+1), which the slot then holds. */
static void pd_stash(pTHX_ SV *c, SV *typed_ref) {
    AV *av = pcx_av(aTHX_ c);
    if (!av_store(av, PCX_OPENAPI, typed_ref))
        SvREFCNT_dec(typed_ref);        /* the store did not take it */
}

/* Call $code->($c) trapping a die. Returns the result (+1 owned); *died is set
 * when the call croaked (the message is left in ERRSV). */
static SV *pd_call(pTHX_ SV *code, SV *c, int *died) {
    dSP; SV *ret; int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, 1); PUSHs(c); PUTBACK;
    count = call_sv(code, G_SCALAR | G_EVAL);
    SPAGAIN;
    ret = count > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
    PUTBACK; FREETMPS; LEAVE;
    *died = SvTRUE(ERRSV) ? 1 : 0;
    return ret;
}

/* Run a chain of hooks/guards over $c. Returns 1 (with *ret / *err set) when
 * one short-circuits with a reference or dies; 0 to continue. */
static int pd_run_chain(pTHX_ AV *chain, SV *c, SV **ret, SV **err) {
    SSize_t i, n;
    if (!chain) return 0;
    n = av_len(chain) + 1;
    for (i = 0; i < n; i++) {
        SV **cp = av_fetch(chain, i, 0);
        int died = 0;
        SV *r;
        if (!cp || !*cp) continue;
        r = pd_call(aTHX_ *cp, c, &died);
        if (died) { *err = newSVsv(ERRSV); *ret = &PL_sv_undef;
                    SvREFCNT_dec(r); return 1; }
        if (SvROK(r)) { *ret = r; return 1; }   /* short-circuit response */
        SvREFCNT_dec(r);
    }
    return 0;
}

/* Read CONTENT_LENGTH bytes of the request body from the env's psgi.input,
 * rewinding after. Returns an owned SV, or NULL for no body; *cl_out gets the
 * CONTENT_LENGTH. */
static SV *punk_oa_env_body(pTHX_ HV *env, IV *cl_out) {
    SV **in = env ? hv_fetchs(env, "psgi.input", 0) : NULL;
    SV **cl = env ? hv_fetchs(env, "CONTENT_LENGTH", 0) : NULL;
    IV len  = (cl && *cl && SvOK(*cl)) ? SvIV(*cl) : 0;
    if (cl_out) *cl_out = len;
    if (!(in && *in && SvTRUE(*in) && len > 0)) return NULL;
    {
        IO *io = sv_2io(*in);
        PerlIO *fp = io ? IoIFP(io) : NULL;
        SV *raw;
        char *d;
        IV got = 0;
        if (!fp) return NULL;
        raw = newSV(len + 1);
        SvPOK_on(raw);
        d = SvPVX(raw);
        while (got < len) {
            SSize_t n = PerlIO_read(fp, d + got, (Size_t)(len - got));
            if (n <= 0) break;
            got += (IV)n;
        }
        d[got] = '\0';
        SvCUR_set(raw, (STRLEN)got);
        (void)PerlIO_seek(fp, 0, SEEK_SET);
        return raw;
    }
}

/* Assemble the validate_request raw-inputs hash in C from the env and the
 * routed captures: { path => \%caps, query => $qs, header => \%lc,
 * body => $bytes }. HTTP_* -> lowercased dash-separated names, CONTENT_TYPE
 * and a truthy CONTENT_LENGTH folded in, body only when present. Owned (+1). */
static HV *punk_oa_build_raw(pTHX_ HV *env, HV *caps, SV *body, IV cl) {
    HV *raw     = newHV();
    HV *headers = pq_headers(aTHX_ env);   /* punk_request.h, shared with
                                            * Punk::Request::headers */
    SV **e;

    (void)hv_stores(raw, "path", newRV_inc((SV *)caps));
    e = env ? hv_fetchs(env, "QUERY_STRING", 0) : NULL;
    (void)hv_stores(raw, "query",
        (e && *e && SvOK(*e)) ? newSVsv(*e) : newSVpvs(""));

    /* the length actually read, not the one the environment claims - the
     * body was framed by this, and validation should see the same */
    if (cl)
        (void)hv_stores(headers, "content-length", newSViv(cl));
    (void)hv_stores(raw, "header", newRV_noinc((SV *)headers));

    if (body && SvOK(body) && SvCUR(body) > 0)
        (void)hv_stores(raw, "body", newSVsv(body));
    return raw;
}

/* Dispatch one matched operation in C. *out_ret is the controller's return
 * value or an early PSGI triplet (+1 owned, or the immortal undef); *out_err
 * is a die message SV (+1) or the immortal undef. Mirrors the old Perl
 * Punk::Mount::OpenAPI::dispatch exactly. */
static void punk_oa_dispatch(pTHX_ SV *c, AV *before, HV *rec, SV *api,
                             SV *op_id, SV *caps_sv, IV max_body,
                             SV **out_ret, SV **out_err) {
    const oa_abi *A = punk_oa(aTHX);   /* croaks if the ABI is unavailable */
    SV *ret = &PL_sv_undef, *err = &PL_sv_undef;
    SV **codep, **guardsp;
    HV *env, *rawh, *typed, *caps;
    AV *errs;
    SV *body;
    IV cl = 0;
    void *apip, *op;
    int ok, died = 0;

    if (pd_run_chain(aTHX_ before, c, &ret, &err)) goto done;
    guardsp = hv_fetchs(rec, "guards", 0);
    if (guardsp && *guardsp && SvROK(*guardsp)
        && SvTYPE(SvRV(*guardsp)) == SVt_PVAV
        && pd_run_chain(aTHX_ (AV *)SvRV(*guardsp), c, &ret, &err))
        goto done;

    env = pd_c_env(aTHX_ c);
    if (env) {
        SV **e = hv_fetchs(env, "CONTENT_LENGTH", 0);
        cl = (e && *e && SvOK(*e)) ? SvIV(*e) : 0;
    }
    if (max_body > 0 && cl > max_body) {
        ret = punk_triplet(aTHX_ 413, sv_2mortal(newSVpvs("application/json")),
                           newSVpvs(PD_ERR_413), NULL);
        goto done;
    }
    codep = hv_fetchs(rec, "code", 0);
    if (!(codep && *codep && SvOK(*codep))) {
        ret = punk_triplet(aTHX_ 501, sv_2mortal(newSVpvs("application/json")),
                           newSVpvs(PD_ERR_501), NULL);
        goto done;
    }

    caps = (caps_sv && SvROK(caps_sv) && SvTYPE(SvRV(caps_sv)) == SVt_PVHV)
           ? (HV *)SvRV(caps_sv) : (HV *)sv_2mortal((SV *)newHV());
    apip = A->api_of(aTHX_ api);
    op   = apip ? A->op_by_id(aTHX_ apip, op_id) : NULL;
    if (!op) croak("Punk: unknown operationId '%s'", SvPV_nolen(op_id));

    body  = punk_oa_env_body(aTHX_ env, &cl);
    if (body) body = sv_2mortal(body);
    rawh  = punk_oa_build_raw(aTHX_ env, caps, body, cl);
    typed = (HV *)sv_2mortal((SV *)newHV());
    errs  = (AV *)sv_2mortal((SV *)newAV());
    ok = A->validate(aTHX_ apip, op, rawh, typed, errs);
    SvREFCNT_dec((SV *)rawh);
    if (!ok) {
        HV *e = newHV();
        SV *bytes;
        (void)hv_stores(e, "errors", newRV_inc((SV *)errs));
        bytes = punk_frj(aTHX)->encode(aTHX_
                    sv_2mortal(newRV_noinc((SV *)e)), NULL);
        ret = punk_triplet(aTHX_ 400, sv_2mortal(newSVpvs("application/json")),
                           bytes, NULL);
        goto done;
    }

    pd_stash(aTHX_ c, newRV_inc((SV *)typed));   /* pd_stash takes the ref */
    ret = pd_call(aTHX_ *codep, c, &died);
    if (died) { err = newSVsv(ERRSV); SvREFCNT_dec(ret); ret = &PL_sv_undef; }

  done:
    *out_ret = ret;
    *out_err = err;
}

#endif /* PUNK_DISPATCH_H */

#ifndef OA_PLACK_H
#define OA_PLACK_H

/* The PSGI adapter, all in C: $api->to_app(handlers => {...}) returns a PSGI
 * coderef (a magic CV carrying its captures) whose request path is
 * route -> validate -> dispatch -> respond. A handler may return a PSGI
 * triplet, plain data (JSON-encoded as a 200), or - on a non-blocking server
 * (psgi.nonblocking, e.g. Hyperman) - a Future-like object resolving to one
 * of those, which is passed straight through for the server to await. On
 * blocking servers a returned Future is ->get awaited inline. */

/* ---- closures: a CV carrying captured SVs (the rp_closure pattern) -------- */

typedef struct oa_clos { AV *cap; } oa_clos;

static int oa_clos_free(pTHX_ SV *sv, MAGIC *mg) {
    oa_clos *c = (oa_clos *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (c) { if (c->cap) SvREFCNT_dec((SV *)c->cap); Safefree(c); }
    return 0;
}
static MGVTBL oa_clos_vtbl = { NULL, NULL, NULL, NULL, oa_clos_free,
                               NULL, NULL, NULL };

static SV *oa_closure(pTHX_ XSUBADDR_t body, AV *cap) {
    CV *cv = (CV *)newXS(NULL, body, __FILE__);
    oa_clos *c;
    Newxz(c, 1, oa_clos);
    c->cap = cap;                                   /* takes ownership */
    sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &oa_clos_vtbl, (char *)c, 0);
    return newRV_noinc((SV *)cv);
}
static AV *oa_clos_cap(pTHX_ CV *cv) {
    MAGIC *mg = mg_findext((SV *)cv, PERL_MAGIC_ext, &oa_clos_vtbl);
    return mg ? ((oa_clos *)mg->mg_ptr)->cap : NULL;
}

/* ---- JSON responses -------------------------------------------------------- */

/* Encode a Perl value through the frj ABI. The ABI croaks on an unencodable
 * shape, so the encode runs inside the private _frj_encode trampoline (a
 * direct ABI call), invoked on its cached CV with G_EVAL - a bad handler
 * return degrades instead of escaping the request. Mortal SV on success,
 * NULL on failure. OA_ENC_CV is resolved in BOOT (API.xs). */
static SV *oa_json_encode(pTHX_ SV *val) {
    dSP; int count; SV *ret = NULL;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(val); PUTBACK;
    count = call_sv(OA_ENC_CV, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) { SV *r = POPs; if (SvOK(r)) ret = newSVsv(r); }
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    return ret ? sv_2mortal(ret) : NULL;
}

/* [ $status, ['Content-Type','application/json'], [$json] ]  (+1) */
static SV *oa_json_response(pTHX_ int status, SV *val) {
    AV *h = newAV(), *b = newAV(), *r = newAV();
    SV *json = oa_json_encode(aTHX_ val);
    av_push(h, newSVpvs("Content-Type"));
    av_push(h, newSVpvs("application/json"));
    av_push(b, json ? newSVsv(json) : newSVpvs("null"));
    av_push(r, newSViv(status));
    av_push(r, newRV_noinc((SV *)h));
    av_push(r, newRV_noinc((SV *)b));
    return newRV_noinc((SV *)r);
}

/* { errors => \@errs } as a JSON response (+1). errs borrowed. */
static SV *oa_error_response(pTHX_ int status, AV *errs) {
    HV *wrap = newHV();
    SV *rv, *w;
    (void)hv_stores(wrap, "errors", newRV_inc((SV *)errs));
    w  = sv_2mortal(newRV_noinc((SV *)wrap));
    rv = oa_json_response(aTHX_ status, w);
    return rv;
}

/* one-message error response (+1) */
static SV *oa_error_msg(pTHX_ int status, const char *msg) {
    AV *errs = (AV *)sv_2mortal((SV *)newAV());
    HV *e = newHV();
    (void)hv_stores(e, "message", newSVpv(msg, 0));
    av_push(errs, newRV_noinc((SV *)e));
    return oa_error_response(aTHX_ status, errs);
}

/* ---- env access -------------------------------------------------------------- */

static SV *oa_env_get(pTHX_ HV *env, const char *k) {
    SV **e = hv_fetch(env, k, (I32)strlen(k), 0);
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

/* read CONTENT_LENGTH bytes from psgi.input (the rp_read_body pattern) */
static SV *oa_read_body_env(pTHX_ HV *env) {
    SV *cl = oa_env_get(aTHX_ env, "CONTENT_LENGTH");
    SV *in = oa_env_get(aTHX_ env, "psgi.input");
    IV len, off = 0;
    SV *body;
    if (!cl || !in) return NULL;
    len = SvIV(cl);
    if (len <= 0) return NULL;
    /* psgi.input is usually a plain filehandle, and read() on one is a method
     * call. Perl only auto-loads IO::Handle to resolve filehandle methods from
     * 5.14 on; before that the call simply fails, and under the G_EVAL below
     * that failure is silent - the body read back empty and a perfectly good
     * POST was rejected as "missing required request body". Load it once. */
    {
        static int oa_io_handle_loaded = 0;
        if (!oa_io_handle_loaded) {
            oa_io_handle_loaded = 1;
            eval_pv("require IO::Handle;", FALSE);
        }
    }
    body = sv_2mortal(newSVpvs(""));
    while (off < len) {
        dSP; int n; IV got;
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 4);
        PUSHs(in);
        PUSHs(body);
        PUSHs(sv_2mortal(newSViv(len - off)));
        PUSHs(sv_2mortal(newSViv(off)));
        PUTBACK;
        n = call_method("read", G_SCALAR | G_EVAL);
        SPAGAIN;
        got = (!SvTRUE(ERRSV) && n > 0) ? POPi : 0;
        PUTBACK; FREETMPS; LEAVE;
        if (got <= 0) break;
        off += got;
    }
    return body;
}

/* Build the minimal lowercased header HV oa_validate_op needs for this op:
 * content-type, cookie, and each declared header parameter (fresh HV). */
static HV *oa_headers_for(pTHX_ oa_op *o, HV *env) {
    HV *out = newHV();
    SV *v;
    int i;
    if ((v = oa_env_get(aTHX_ env, "CONTENT_TYPE")))
        (void)hv_stores(out, "content-type", newSVsv(v));
    if ((v = oa_env_get(aTHX_ env, "HTTP_COOKIE")))
        (void)hv_stores(out, "cookie", newSVsv(v));
    for (i = 0; i < o->nparams[OA_IN_HEADER]; i++) {
        STRLEN nl; const char *np = SvPV_const(o->params[OA_IN_HEADER][i].name, nl);
        char key[160], lc[128];
        STRLEN k;
        SV **e;
        if (nl + 5 >= sizeof key || nl >= sizeof lc) continue;
        memcpy(key, "HTTP_", 5);
        for (k = 0; k < nl; k++) {
            char c = np[k];
            key[5 + k] = (c == '-') ? '_' : (char)toUPPER((U8)c);
            lc[k]      = (char)toLOWER((U8)c);
        }
        key[5 + nl] = '\0';
        e = hv_fetch(env, key, (I32)(5 + nl), 0);
        if (e && *e && SvOK(*e))
            (void)hv_store(out, lc, (I32)nl, newSVsv(*e), 0);
    }
    return out;
}

/* ---- handler result mapping ---------------------------------------------------- */

/* a PSGI triplet: [ status, \@headers, ... ] */
static int oa_is_triplet(pTHX_ SV *sv) {
    AV *av;
    SV **s, **h;
    if (!sv || !SvROK(sv) || SvTYPE(SvRV(sv)) != SVt_PVAV) return 0;
    av = (AV *)SvRV(sv);
    if (av_len(av) + 1 != 3) return 0;
    s = av_fetch(av, 0, 0);
    h = av_fetch(av, 1, 0);
    if (!s || !*s || !SvOK(*s) || SvROK(*s)) return 0;
    if (!looks_like_number(*s)) return 0;
    if (!h || !*h || !SvROK(*h) || SvTYPE(SvRV(*h)) != SVt_PVAV) return 0;
    return 1;
}

/* an object with on_ready (a Future the server can await) */
static int oa_is_future(pTHX_ SV *sv) {
    return sv && SvROK(sv) && SvOBJECT(SvRV(sv))
        && gv_fetchmethod_autoload(SvSTASH(SvRV(sv)), "on_ready", 0) != NULL;
}

/* triplet passes through; anything else JSON-encodes as a 200 (+1) */
static SV *oa_map_result(pTHX_ SV *res) {
    if (oa_is_triplet(aTHX_ res)) return newSVsv(res);
    return oa_json_response(aTHX_ 200, res);
}

/* ---- response validation ------------------------------------------------------- *
 *
 * Two modes over one code path:
 *
 *   OA_RV_REPLACE (validate_responses => 1) - the dev tool. A mismatch
 *       *replaces* the response with a 500 describing it. Unchanged from
 *       0.06, defaults included: somebody's dev server depends on it.
 *   OA_RV_REPORT  (validate_responses => 'report') - the product. The
 *       errors go to a coderef and NULL comes back, so the triplet the
 *       client receives is the one the handler built, byte for byte.
 *
 * Before any of that, a sampling gate: a per-operation counter, so an
 * unsampled response costs one increment and one comparison and never
 * touches the body. Then the skip rules, in order, each with its own
 * counter - coverage is a reported number, not a silent gap. */

#define OA_RV_OFF     0
#define OA_RV_REPLACE 1
#define OA_RV_REPORT  2

/* defined below, with the rest of the response-finalization helpers */
static AV *oa_resp_headers(pTHX_ SV *resp);

/* case-insensitive equality (the response-finalization section has the same
 * comparison as oa_ci_eq; this one is needed before it) */
static int oa_ci_eq_fwd(const char *a, STRLEN al, const char *b, STRLEN bl) {
    STRLEN i;
    if (al != bl) return 0;
    for (i = 0; i < al; i++)
        if (toLOWER((U8)a[i]) != toLOWER((U8)b[i])) return 0;
    return 1;
}

typedef struct oa_rvcfg {
    int  mode;         /* OA_RV_*                                        */
    SV  *report;       /* coderef for report mode (borrowed), or NULL    */
    IV   sample;       /* validate 1 response in N; 0/1 = all of them     */
    IV   max_body;     /* skip bodies over this many bytes; 0 = no cap    */
} oa_rvcfg;

/* the value of a response header, or NULL (borrowed) */
static SV *oa_hdr_get(pTHX_ AV *ha, const char *name, STRLEN nl) {
    SSize_t i, n = ha ? av_len(ha) + 1 : 0;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(ha, i, 0);
        if (k && *k) {
            STRLEN kl; const char *kp = SvPV_const(*k, kl);
            if (oa_ci_eq_fwd(kp, kl, name, nl)) {
                SV **v = av_fetch(ha, i + 1, 0);
                return (v && *v && SvOK(*v)) ? *v : NULL;
            }
        }
    }
    return NULL;
}

/* the declared schema for this status (exact, then `default`), or NULL.
 * `ctype_ok` reports whether the operation declares a JSON body for it,
 * which is a different question from whether one was compiled. */
static SV *oa_resp_handle(pTHX_ oa_op *o, int status) {
    char sbuf[8];
    STRLEN sl;
    int i;
    sl = (STRLEN)my_snprintf(sbuf, sizeof sbuf, "%d", status);
    for (i = 0; i < o->nresps; i++) {
        STRLEN rl; const char *rp = SvPV_const(o->resps[i].status, rl);
        if (rl == sl && memEQ(rp, sbuf, sl)) return o->resps[i].handle;
    }
    for (i = 0; i < o->nresps; i++) {
        STRLEN rl; const char *rp = SvPV_const(o->resps[i].status, rl);
        if (rl == 7 && memEQ(rp, "default", 7)) return o->resps[i].handle;
    }
    return NULL;
}

/* $report->($op_id, $status, \@errors, $env) - never allowed to break the
 * response, so it runs under G_EVAL and a die is swallowed after a warn. */
static void oa_rv_report(pTHX_ SV *cb, SV *op_id, int status, AV *errs, SV *env_rv) {
    dSP;
    if (!cb || !SvOK(cb)) return;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 4);
    PUSHs(op_id ? op_id : &PL_sv_undef);
    PUSHs(sv_2mortal(newSViv(status)));
    PUSHs(sv_2mortal(newRV_inc((SV *)errs)));
    PUSHs(env_rv ? env_rv : &PL_sv_undef);
    PUTBACK;
    (void)call_sv(cb, G_VOID | G_DISCARD | G_EVAL);
    if (SvTRUE(ERRSV))
        warn("Open::API: response report callback died: %" SVf, SVfARG(ERRSV));
    FREETMPS; LEAVE;
}

/* The check itself. Returns NULL when there is nothing to answer with -
 * which is every case in report mode, and the conforming case in replace
 * mode - or a 500 triplet (+1) for a replace-mode mismatch.
 *
 * `out_errs`, when given, receives the error AV (borrowed, mortal) so a
 * direct caller can have the findings without a callback. */
static SV *oa_check_response_cfg(pTHX_ oa_op *o, SV *trip, const oa_rvcfg *rv,
                                 SV *env_rv, AV **out_errs) {
    AV *tv, *ba, *errs, *ha;
    SV **st, **bd, **b0;
    SV *handle, *data, *cl;
    int status;
    SSize_t j;
    if (out_errs) *out_errs = NULL;
    if (!o || rv->mode == OA_RV_OFF || !oa_is_triplet(aTHX_ trip)) return NULL;

    o->rv.total++;

    /* the sampling gate, before anything touches the body */
    o->rv.seen++;
    if (rv->sample > 1 && (o->rv.seen % (unsigned long)rv->sample) != 0)
        return NULL;
    o->rv.sampled++;

    tv = (AV *)SvRV(trip);
    st = av_fetch(tv, 0, 0);
    status = (int)SvIV(*st);
    ha = oa_resp_headers(aTHX_ trip);

    /* 1. not a declared JSON content type */
    {
        SV *ct = oa_hdr_get(aTHX_ ha, "content-type", 12);
        STRLEN ctl; const char *ctp;
        if (!ct) { o->rv.skip_ctype++; return NULL; }
        ctp = SvPV_const(ct, ctl);
        if (!oa_ctype_is_json(ctp, ctl)) { o->rv.skip_ctype++; return NULL; }
    }

    /* 2. Content-Length absent or over the cap. Only with a cap set: without
     *    one there is nothing to be over, and demanding the header would stop
     *    validating the handlers that never set it. */
    if (rv->max_body > 0) {
        cl = oa_hdr_get(aTHX_ ha, "content-length", 14);
        if (!cl || !looks_like_number(cl) || SvIV(cl) > rv->max_body) {
            o->rv.skip_size++;
            return NULL;
        }
    }

    /* 3. the body is not a plain scalar: a filehandle, a streaming coderef,
     *    an SSE writer. Never buffered, never measured, forwarded as it is. */
    bd = av_fetch(tv, 2, 0);
    if (!bd || !*bd || !SvROK(*bd) || SvTYPE(SvRV(*bd)) != SVt_PVAV) {
        o->rv.skip_body++;
        return NULL;
    }
    ba = (AV *)SvRV(*bd);
    b0 = av_fetch(ba, 0, 0);
    if (!b0 || !*b0 || !SvOK(*b0) || SvROK(*b0)) {
        o->rv.skip_body++;
        return NULL;
    }

    /* 4. the status declares no schema */
    handle = oa_resp_handle(aTHX_ o, status);
    if (!handle) { o->rv.skip_schema++; return NULL; }

    data = oa_body_decode(aTHX_ *b0);
    if (!data) { o->rv.skip_decode++; return NULL; }

    errs = (AV *)sv_2mortal((SV *)newAV());
    o->rv.checked++;
    if (JSF->validate(aTHX_ handle, data, errs)) return NULL;

    o->rv.violations++;
    for (j = 0; j <= av_len(errs); j++) {
        SV **e = av_fetch(errs, j, 0);
        HV *h = (e && *e && SvROK(*e)) ? (HV *)SvRV(*e) : NULL;
        if (h) (void)hv_stores(h, "in", newSVpvs("response"));
    }
    if (out_errs) *out_errs = errs;

    if (rv->mode == OA_RV_REPORT) {
        oa_rv_report(aTHX_ rv->report, o->op_id, status, errs, env_rv);
        return NULL;              /* the client's bytes are not ours to edit */
    }
    return oa_error_response(aTHX_ 500, errs);
}

/* The coverage counters as a hash (+1 owned by the caller). */
static HV *oa_rv_hv(pTHX_ const oa_rvstat *s) {
    HV *h = newHV();
    (void)hv_stores(h, "total",       newSVuv(s->total));
    (void)hv_stores(h, "sampled",     newSVuv(s->sampled));
    (void)hv_stores(h, "checked",     newSVuv(s->checked));
    (void)hv_stores(h, "violations",  newSVuv(s->violations));
    (void)hv_stores(h, "skip_ctype",  newSVuv(s->skip_ctype));
    (void)hv_stores(h, "skip_size",   newSVuv(s->skip_size));
    (void)hv_stores(h, "skip_body",   newSVuv(s->skip_body));
    (void)hv_stores(h, "skip_schema", newSVuv(s->skip_schema));
    (void)hv_stores(h, "skip_decode", newSVuv(s->skip_decode));
    (void)hv_stores(h, "unsampled",   newSVuv(s->total - s->sampled));
    return h;
}

/* The request path's version: the mode comes from its own capture slot, the
 * report callback and the sampling settings from the options HV. */
static void oa_rvcfg_from(pTHX_ int vresp, HV *opts, oa_rvcfg *rv) {
    SV **v;
    rv->mode = vresp; rv->report = NULL; rv->sample = 1; rv->max_body = 0;
    if (!opts) return;
    if ((v = hv_fetchs(opts, "response_report", 0)) && *v && SvOK(*v))
        rv->report = *v;
    if ((v = hv_fetchs(opts, "response_sample", 0)) && *v && SvOK(*v))
        rv->sample = SvIV(*v);
    if ((v = hv_fetchs(opts, "response_max_body", 0)) && *v && SvOK(*v))
        rv->max_body = SvIV(*v);
}

/* Check with the configured mode. NULL unless replace mode found a
 * mismatch, in which case the 500 that replaces the response (+1). */
static SV *oa_check_response_opts(pTHX_ oa_op *o, SV *trip, int vresp,
                                  HV *opts, SV *env_rv) {
    oa_rvcfg rv;
    /* deliberately no `!o->nresps` shortcut: an operation whose declared
     * statuses carry no schema still counts its responses and attributes
     * them to skip_schema. Silence there would read as coverage. */
    if (!o || !vresp) return NULL;
    oa_rvcfg_from(aTHX_ vresp, opts, &rv);
    return oa_check_response_cfg(aTHX_ o, trip, &rv, env_rv, NULL);
}

/* ---- response finalization (security headers, CORS, problem+json) ----------------- */

/* case-insensitive: does the header AV already carry `name`? */
static int oa_hdr_has(pTHX_ AV *ha, const char *name, STRLEN nl) {
    SSize_t i, n = av_len(ha) + 1;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(ha, i, 0);
        if (k && *k) {
            STRLEN kl; const char *kp = SvPV_const(*k, kl);
            STRLEN j; int eq = (kl == nl);
            for (j = 0; eq && j < kl; j++)
                if (toLOWER((U8)kp[j]) != toLOWER((U8)name[j])) eq = 0;
            if (eq) return 1;
        }
    }
    return 0;
}

/* the triplet's header AV, or NULL */
static AV *oa_resp_headers(pTHX_ SV *resp) {
    AV *tv; SV **hh;
    if (!oa_is_triplet(aTHX_ resp)) return NULL;
    tv = (AV *)SvRV(resp);
    hh = av_fetch(tv, 1, 0);
    return (hh && *hh && SvROK(*hh)) ? (AV *)SvRV(*hh) : NULL;
}

/* push name => value (borrowed name, value copied) */
static void oa_hdr_push(pTHX_ AV *ha, const char *name, SV *val) {
    av_push(ha, newSVpv(name, 0));
    av_push(ha, newSVsv(val));
}

/* case-insensitive equality */
static int oa_ci_eq(const char *a, STRLEN al, const char *b, STRLEN bl) {
    STRLEN i;
    if (al != bl) return 0;
    for (i = 0; i < al; i++)
        if (toLOWER((U8)a[i]) != toLOWER((U8)b[i])) return 0;
    return 1;
}

/* join an AV of strings with ", " (mortal SV), NULL when empty */
static SV *oa_join_csv(pTHX_ AV *av) {
    SSize_t i, n = av ? av_len(av) + 1 : 0;
    SV *out;
    if (n <= 0) return NULL;
    out = sv_2mortal(newSVpvs(""));
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        if (!e || !*e) continue;
        if (SvCUR(out)) sv_catpvs(out, ", ");
        sv_catsv(out, *e);
    }
    return out;
}

#define OA_HAS(ha, lit) oa_hdr_has(aTHX_ (ha), "" lit, sizeof(lit) - 1)

/* apply the configured header set (set-if-absent, so a handler or the after
 * hook keeps the last word) to a triplet response */
static void oa_apply_headers(pTHX_ SV *resp, HV *hdrs) {
    AV *ha = oa_resp_headers(aTHX_ resp);
    HE *he;
    if (!ha || !hdrs) return;
    hv_iterinit(hdrs);
    while ((he = hv_iternext(hdrs))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        if (!oa_hdr_has(aTHX_ ha, k, (STRLEN)kl))
            oa_hdr_push(aTHX_ ha, k, hv_iterval(hdrs, he));
    }
}

/* Finalize every outgoing triplet: convert error envelopes to problem+json
 * (opt-in), add CORS response headers for an allowed cross-origin request,
 * then stamp the security header set. Called at each exit and, for async
 * handlers, when the future resolves. opts may be NULL. */
static void oa_cors_actual(pTHX_ SV *resp, SV *env_rv, HV *cors);   /* below */
static void oa_to_problem(pTHX_ SV *resp);                          /* below */

static void oa_finalize(pTHX_ SV *resp, SV *env_rv, HV *opts) {
    SV **v;
    SV *setcookie;
    if (!oa_is_triplet(aTHX_ resp)) return;
    /* CSRF cookie rotation from a check callback (independent of opts, so it
     * applies on the async path and even when no other option is set) */
    if ((setcookie = oa_env_get(aTHX_ (HV *)SvRV(env_rv), "openapi.csrf.setcookie"))) {
        AV *ha = oa_resp_headers(aTHX_ resp);
        if (ha) oa_hdr_push(aTHX_ ha, "Set-Cookie", setcookie);
    }
    if (!opts) return;
    if ((v = hv_fetchs(opts, "error_format", 0)) && *v && SvOK(*v)) {
        STRLEN l; const char *p = SvPV_const(*v, l);
        if (l == 7 && memEQ(p, "problem", 7)) oa_to_problem(aTHX_ resp);
    }
    if ((v = hv_fetchs(opts, "cors", 0)) && *v && SvROK(*v))
        oa_cors_actual(aTHX_ resp, env_rv, (HV *)SvRV(*v));
    if ((v = hv_fetchs(opts, "headers", 0)) && *v && SvROK(*v))
        oa_apply_headers(aTHX_ resp, (HV *)SvRV(*v));
}

/* finalize and return - a function (not a macro) so the response expression
 * is evaluated exactly once at each exit */
static SV *oa_fin(pTHX_ SV *resp, SV *env_rv, HV *opts) {
    oa_finalize(aTHX_ resp, env_rv, opts);
    return resp;
}

/* reason phrase for the statuses this layer emits */
static const char *oa_reason(int s) {
    switch (s) {
        case 400: return "Bad Request";
        case 401: return "Unauthorized";
        case 403: return "Forbidden";
        case 404: return "Not Found";
        case 405: return "Method Not Allowed";
        case 406: return "Not Acceptable";
        case 413: return "Payload Too Large";
        case 415: return "Unsupported Media Type";
        case 500: return "Internal Server Error";
        case 501: return "Not Implemented";
        default:  return "Error";
    }
}

/* Rewrite our JSON error envelope { errors => [...] } into an RFC 7807
 * application/problem+json body. Only touches a >=400 triplet whose body is
 * our application/json envelope; a handler's own error body is left alone. */
static void oa_to_problem(pTHX_ SV *resp) {
    AV *tv = (AV *)SvRV(resp);
    SV **st = av_fetch(tv, 0, 0);
    AV *ha  = oa_resp_headers(aTHX_ resp);
    SV **bd, **b0, **errs;
    AV *ba;
    SV *data, *enc;
    HV *src, *prob;
    int status, is_json = 0;
    SSize_t i, n;

    if (!st || !*st || !ha) return;
    status = (int)SvIV(*st);
    if (status < 400) return;

    n = av_len(ha) + 1;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(ha, i, 0), **v = av_fetch(ha, i + 1, 0);
        if (k && *k && v && *v) {
            STRLEN kl; const char *kp = SvPV_const(*k, kl);
            if (oa_ci_eq(kp, kl, "content-type", 12)) {
                STRLEN vl; const char *vp = SvPV_const(*v, vl);
                is_json = (vl >= 16 && memEQ(vp, "application/json", 16)
                           && (vl == 16 || vp[16] == ';'));
                break;
            }
        }
    }
    if (!is_json) return;

    bd = av_fetch(tv, 2, 0);
    if (!bd || !*bd || !SvROK(*bd) || SvTYPE(SvRV(*bd)) != SVt_PVAV) return;
    ba = (AV *)SvRV(*bd);
    b0 = av_fetch(ba, 0, 0);
    if (!b0 || !*b0 || !SvOK(*b0)) return;
    data = oa_body_decode(aTHX_ *b0);   /* mortal, or NULL */
    if (!data || !SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVHV) return;
    src  = (HV *)SvRV(data);
    errs = hv_fetchs(src, "errors", 0);
    /* the errors AV marks OUR envelope; a handler's own JSON error body
     * (no errors key) is left alone, as promised above */
    if (!(errs && *errs && SvROK(*errs) && SvTYPE(SvRV(*errs)) == SVt_PVAV))
        return;
    prob = newHV();
    (void)hv_stores(prob, "type",   newSVpvs("about:blank"));
    (void)hv_stores(prob, "title",  newSVpv(oa_reason(status), 0));
    (void)hv_stores(prob, "status", newSViv(status));
    (void)hv_stores(prob, "errors", newSVsv(*errs));
    {
        AV *ea = (AV *)SvRV(*errs);
        SV **e0 = av_fetch(ea, 0, 0);
        if (e0 && *e0 && SvROK(*e0) && SvTYPE(SvRV(*e0)) == SVt_PVHV) {
            SV **m = hv_fetchs((HV *)SvRV(*e0), "message", 0);
            if (m && *m && SvOK(*m)) (void)hv_stores(prob, "detail", newSVsv(*m));
        }
    }
    enc = oa_json_encode(aTHX_ sv_2mortal(newRV_noinc((SV *)prob)));
    if (!enc) return;
    (void)av_store(ba, 0, newSVsv(enc));
    if (av_len(ba) > 0) av_fill(ba, 0);   /* one chunk now */
    for (i = 0; i + 1 < n; i += 2) {   /* switch the content-type */
        SV **k = av_fetch(ha, i, 0);
        if (k && *k) {
            STRLEN kl; const char *kp = SvPV_const(*k, kl);
            if (oa_ci_eq(kp, kl, "content-type", 12)) {
                (void)av_store(ha, i + 1,
                    newSVpvs("application/problem+json"));
                break;
            }
        }
    }
}

/* Add CORS headers to a non-preflight response when the request carries an
 * allowed Origin. cors config: origins ('*' or an AV of exact origins),
 * credentials (bool), expose (AV of header names). */
static void oa_cors_actual(pTHX_ SV *resp, SV *env_rv, HV *cors) {
    HV *env = (HV *)SvRV(env_rv);
    SV *origin = oa_env_get(aTHX_ env, "HTTP_ORIGIN");
    AV *ha = oa_resp_headers(aTHX_ resp);
    SV **v, *allow_val;
    int allow = 0, wildcard = 0, creds;

    if (!origin || !ha) return;
    v = hv_fetchs(cors, "credentials", 0);
    creds = (v && *v && SvTRUE(*v));

    v = hv_fetchs(cors, "origins", 0);
    if (v && *v) {
        if (!SvROK(*v)) {   /* '*', or one exact origin */
            STRLEN l; const char *p = SvPV_const(*v, l);
            STRLEN ol; const char *op = SvPV_const(origin, ol);
            if (l == 1 && *p == '*') { allow = 1; wildcard = 1; }
            else if (l == ol && memEQ(p, op, ol)) allow = 1;
        } else if (SvTYPE(SvRV(*v)) == SVt_PVAV) {
            AV *list = (AV *)SvRV(*v);
            STRLEN ol; const char *op = SvPV_const(origin, ol);
            SSize_t i, n = av_len(list) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(list, i, 0);
                STRLEN el; const char *ep;
                if (!e || !*e) continue;
                ep = SvPV_const(*e, el);
                if (el == 1 && *ep == '*') { allow = 1; wildcard = 1; break; }
                if (el == ol && memEQ(ep, op, ol)) { allow = 1; break; }
            }
        }
    }
    if (!allow) return;

    /* credentials forbid a wildcard ACAO: echo the concrete origin */
    allow_val = (wildcard && !creds) ? sv_2mortal(newSVpvs("*")) : origin;
    if (!OA_HAS(ha, "Access-Control-Allow-Origin"))
        oa_hdr_push(aTHX_ ha, "Access-Control-Allow-Origin", allow_val);
    if (!wildcard && !OA_HAS(ha, "Vary"))
        oa_hdr_push(aTHX_ ha, "Vary", sv_2mortal(newSVpvs("Origin")));
    if (creds && !OA_HAS(ha, "Access-Control-Allow-Credentials"))
        oa_hdr_push(aTHX_ ha, "Access-Control-Allow-Credentials",
                    sv_2mortal(newSVpvs("true")));
    v = hv_fetchs(cors, "expose", 0);
    if (v && *v && SvROK(*v) && SvTYPE(SvRV(*v)) == SVt_PVAV) {
        SV *joined = oa_join_csv(aTHX_ (AV *)SvRV(*v));
        if (joined && !OA_HAS(ha, "Access-Control-Expose-Headers"))
            oa_hdr_push(aTHX_ ha, "Access-Control-Expose-Headers", joined);
    }
}

/* Build a CORS preflight (204) response for an OPTIONS request against a known
 * path: Allow-Methods from the router's Allow list (the declared methods),
 * Allow-Headers echoed from the request or configured, and Max-Age. The
 * Allow-Origin / credentials headers are added by oa_cors_actual in finalize.
 * (+1) */
static SV *oa_cors_preflight(pTHX_ SV *env_rv, HV *cors, AV *allow) {
    HV *env = (HV *)SvRV(env_rv);
    AV *h = newAV(), *b = newAV(), *r = newAV();
    SV **v, *methods, *val = NULL;

    av_push(r, newSViv(204));
    av_push(r, newRV_noinc((SV *)h));
    av_push(b, newSVpvs(""));
    av_push(r, newRV_noinc((SV *)b));

    /* Allow-Methods: the declared methods (the router uppercases them),
     * else echo the requested one */
    methods = oa_join_csv(aTHX_ allow);
    if (!methods)
        methods = oa_env_get(aTHX_ env, "HTTP_ACCESS_CONTROL_REQUEST_METHOD");
    if (methods) oa_hdr_push(aTHX_ h, "Access-Control-Allow-Methods", methods);

    /* Allow-Headers: configured list, else echo the requested set */
    v = hv_fetchs(cors, "headers", 0);
    if (v && *v && SvROK(*v) && SvTYPE(SvRV(*v)) == SVt_PVAV)
        val = oa_join_csv(aTHX_ (AV *)SvRV(*v));
    else if (v && *v && SvOK(*v) && !SvROK(*v))
        val = *v;
    if (!val)
        val = oa_env_get(aTHX_ env, "HTTP_ACCESS_CONTROL_REQUEST_HEADERS");
    if (val) oa_hdr_push(aTHX_ h, "Access-Control-Allow-Headers", val);

    if ((v = hv_fetchs(cors, "max_age", 0)) && *v && SvOK(*v))
        oa_hdr_push(aTHX_ h, "Access-Control-Max-Age", *v);

    return newRV_noinc((SV *)r);
}

/* ---- content negotiation (opt-in: 415 request type, 406 Accept) ------------------- */

/* compare two media types ignoring parameters, list separators and space */
static int oa_media_eq(const char *a, STRLEN al, const char *b, STRLEN bl) {
    STRLEN i = 0, j = 0, ie, je;
    while (i < al && (a[i] == ' ' || a[i] == '\t')) i++;
    while (j < bl && (b[j] == ' ' || b[j] == '\t')) j++;
    ie = i;
    je = j;
    while (ie < al && a[ie] != ';' && a[ie] != ',' && a[ie] != ' ') ie++;
    while (je < bl && b[je] != ';' && b[je] != ',' && b[je] != ' ') je++;
    return oa_ci_eq(a + i, ie - i, b + j, je - j);
}

/* 415 when a request body is present but its Content-Type matches none of the
 * operation's declared body media types. NULL to proceed, else a +1 response. */
static SV *oa_check_request_ctype(pTHX_ oa_op *o, HV *env) {
    SV *cl = oa_env_get(aTHX_ env, "CONTENT_LENGTH");
    SV *ct;
    STRLEN rl; const char *rp;
    int i, match = 0;
    if (!o->nbodies) return NULL;               /* no declared body: pass */
    if (!cl || SvIV(cl) <= 0) return NULL;      /* no body sent: pass */
    ct = oa_env_get(aTHX_ env, "CONTENT_TYPE");
    if (!ct) return oa_error_msg(aTHX_ 415, "missing Content-Type");
    rp = SvPV_const(ct, rl);
    for (i = 0; i < o->nbodies; i++) {
        STRLEN dl; const char *dp = SvPV_const(o->bodies[i].ctype, dl);
        if (oa_media_eq(rp, rl, dp, dl)) { match = 1; break; }
    }
    return match ? NULL : oa_error_msg(aTHX_ 415, "unsupported media type");
}

/* 406 when the request has an Accept that admits none of the operation's
 * declared response media types. Lenient: unknown (no declared types, no
 * Accept, or Accept carries a wildcard) always passes. */
static SV *oa_check_accept(pTHX_ oa_op *o, HV *env) {
    SV *acc = oa_env_get(aTHX_ env, "HTTP_ACCEPT");
    STRLEN al, k; const char *ap;
    int i, any = 0, ok = 0;
    if (!acc || !o->nresps) return NULL;
    ap = SvPV_const(acc, al);
    if (al == 0) return NULL;
    for (k = 0; k + 2 < al; k++)               /* star-slash-star: accept all */
        if (ap[k] == '*' && ap[k+1] == '/' && ap[k+2] == '*') return NULL;
    for (i = 0; i < o->nresps && !ok; i++) {
        STRLEN dl; const char *dp;
        STRLEN s;
        if (!o->resps[i].ctype) continue;
        any = 1;
        dp = SvPV_const(o->resps[i].ctype, dl);
        /* acceptable if the declared type (up to ';') appears in Accept */
        for (s = 0; s + dl <= al; s++)
            if (oa_media_eq(ap + s, al - s, dp, dl)) { ok = 1; break; }
    }
    if (!any) return NULL;                       /* nothing declared: pass */
    return ok ? NULL : oa_error_msg(aTHX_ 406, "not acceptable");
}

/* ---- hooks ------------------------------------------------------------------------ */

/* Resolve a hook/handler spec - a coderef, or a fully qualified sub name -
 * to an RV-to-CV (+1). Croaks (with `what` for context) on anything else. */
static SV *oa_cv_or_name(pTHX_ SV *v, const char *what) {
    if (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVCV)
        return newSVsv(v);
    if (v && SvOK(v) && !SvROK(v)) {
        STRLEN nl; const char *np = SvPV_const(v, nl);
        CV *cv = get_cv(np, 0);
        if (!cv)
            croak("Open::API->to_app: %s names no such sub '%.*s'",
                  what, (int)nl, np);
        return newRV_inc((SV *)cv);
    }
    croak("Open::API->to_app: %s must be a coderef or a fully qualified "
          "sub name", what);
    return NULL;   /* not reached */
}

/* Run the after hook on a finished response: $after->($resp, $env, $opId).
 * The hook may mutate the triplet in place; returning a PSGI triplet
 * replaces the response (other return values are ignored). A die becomes a
 * 500. Replaces *resp in place, consuming the old one. */
static void oa_run_after(pTHX_ SV **resp, SV *after, SV *env_rv, SV *opid) {
    dSP; int n; SV *r = NULL;
    if (!after || !SvOK(after)) return;
    ENTER; SAVETMPS; PUSHMARK(SP);
    EXTEND(SP, 3);
    PUSHs(*resp);
    PUSHs(env_rv);
    PUSHs(opid);
    PUTBACK;
    n = call_sv(after, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        SV *e = newSVsv(ERRSV);
        if (n > 0) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
        SvREFCNT_dec(*resp);
        *resp = oa_error_msg(aTHX_ 500, SvPV_nolen(e));
        SvREFCNT_dec(e);
        return;
    }
    if (n > 0) {
        SV *t = POPs;
        if (oa_is_triplet(aTHX_ t) && t != *resp) r = newSVsv(t);
    }
    PUTBACK; FREETMPS; LEAVE;
    if (r) { SvREFCNT_dec(*resp); *resp = r; }
}

/* Run the before hook after routing, before validation:
 * $before->($env, $opId). A REFERENCE return short-circuits the request and
 * becomes the response (a PSGI triplet as-is, other data JSON-encoded);
 * non-reference returns continue. A die becomes a 500. Returns the
 * short-circuit response (+1) or NULL to continue. */
static SV *oa_run_before(pTHX_ SV *before, SV *env_rv, SV *opid) {
    dSP; int n; SV *out = NULL;
    if (!before || !SvOK(before)) return NULL;
    ENTER; SAVETMPS; PUSHMARK(SP);
    EXTEND(SP, 2);
    PUSHs(env_rv);
    PUSHs(opid);
    PUTBACK;
    n = call_sv(before, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        SV *e = newSVsv(ERRSV);
        if (n > 0) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
        out = oa_error_msg(aTHX_ 500, SvPV_nolen(e));
        SvREFCNT_dec(e);
        return out;
    }
    if (n > 0) {
        SV *t = POPs;
        if (SvROK(t)) out = oa_map_result(aTHX_ t);
    }
    PUTBACK; FREETMPS; LEAVE;
    return out;
}

/* ---- security enforcement ---------------------------------------------------------- */

/* Extract the credential a scheme describes from the request. Mortal SV, or
 * NULL when absent/malformed. Basic credentials are base64-decoded so the
 * checker sees "user:pass". */
static SV *oa_sec_extract(pTHX_ oa_scheme *s, HV *env) {
    switch (s->type) {
    case OA_SEC_APIKEY: {
        STRLEN nl; const char *np = SvPV_const(s->pname, nl);
        if (s->loc == OA_IN_HEADER) {
            char key[160];
            STRLEN k;
            SV **e;
            if (nl + 5 >= sizeof key) return NULL;
            memcpy(key, "HTTP_", 5);
            for (k = 0; k < nl; k++) {
                char c = np[k];
                key[5 + k] = (c == '-') ? '_' : (char)toUPPER((U8)c);
            }
            e = hv_fetch(env, key, (I32)(5 + nl), 0);
            return (e && *e && SvOK(*e)) ? sv_mortalcopy(*e) : NULL;
        }
        if (s->loc == OA_IN_QUERY) {
            SV *qs = oa_env_get(aTHX_ env, "QUERY_STRING");
            STRLEN ql; const char *qp;
            STRLEN i = 0;
            if (!qs) return NULL;
            qp = SvPV_const(qs, ql);
            while (i < ql) {
                STRLEN e = i, eq;
                while (e < ql && qp[e] != '&') e++;
                eq = i;
                while (eq < e && qp[eq] != '=') eq++;
                if (eq - i == nl && memEQ(qp + i, np, nl) && eq < e)
                    return sv_2mortal(oa_pct_decode(aTHX_ qp + eq + 1,
                                                    e - eq - 1, 1));
                i = e + 1;
            }
            return NULL;
        }
        if (s->loc == OA_IN_COOKIE) {
            SV *ch = oa_env_get(aTHX_ env, "HTTP_COOKIE");
            HV *jar;
            SV **v;
            SV *out = NULL;
            STRLEN cl; const char *cp;
            if (!ch) return NULL;
            cp = SvPV_const(ch, cl);
            jar = oa_parse_cookies(aTHX_ cp, cl);
            v = hv_fetch(jar, np, (I32)nl, 0);
            if (v && *v && SvOK(*v)) out = sv_mortalcopy(*v);
            SvREFCNT_dec((SV *)jar);
            return out;
        }
        return NULL;
    }
    case OA_SEC_BEARER:
    case OA_SEC_BASIC: {
        SV *az = oa_env_get(aTHX_ env, "HTTP_AUTHORIZATION");
        SV *dec;
        STRLEN al; const char *ap;
        const char *want = (s->type == OA_SEC_BEARER) ? "Bearer " : "Basic ";
        STRLEN wl = (s->type == OA_SEC_BEARER) ? 7 : 6;
        STRLEN k;
        if (!az) return NULL;
        ap = SvPV_const(az, al);
        if (al <= wl) return NULL;
        for (k = 0; k < wl; k++)
            if (toLOWER((U8)ap[k]) != toLOWER((U8)want[k])) return NULL;
        while (wl < al && ap[wl] == ' ') wl++;
        if (s->type == OA_SEC_BEARER)
            return sv_2mortal(newSVpvn(ap + wl, al - wl));
        dec = oa_b64_decode(aTHX_ ap + wl, al - wl);
        return dec ? sv_2mortal(dec) : NULL;
    }
    }
    return NULL;
}

/* Enforce the operation's security requirements: try each alternative in
 * order (schemes within one are ANDed); the first fully satisfied one wins
 * and its checker results land in $env->{'openapi.auth'} = { name => ... }.
 * Returns NULL on success, else a +1 response (401, or 500 for a checker
 * die). Coverage of `checkers` was validated at to_app time. */
static SV *oa_security_check(pTHX_ oa_api *a, oa_op *o, SV *env_rv,
                             HV *checkers) {
    oa_ops *t = (oa_ops *)a->ops;
    HV *env = (HV *)SvRV(env_rv);
    int i;
    for (i = 0; i < o->nsec; i++) {
        oa_secalt *alt = &o->sec[i];
        HV *auth = (HV *)sv_2mortal((SV *)newHV());
        int j, ok = 1;
        for (j = 0; j < alt->n && ok; j++) {
            oa_scheme *s = &t->schemes[alt->items[j].scheme];
            SV *cred = oa_sec_extract(aTHX_ s, env);
            SV **cbp;
            STRLEN nl; const char *np;
            if (!cred) { ok = 0; break; }
            np  = SvPV_const(s->name, nl);
            cbp = hv_fetch(checkers, np, (I32)nl, 0);
            {
                dSP; int n; SV *ret = NULL;
                ENTER; SAVETMPS; PUSHMARK(SP);
                EXTEND(SP, 4);
                PUSHs(cred);
                PUSHs(env_rv);
                PUSHs(o->op_id);
                PUSHs(alt->items[j].scopes ? alt->items[j].scopes
                                           : &PL_sv_undef);
                PUTBACK;
                n = call_sv(*cbp, G_SCALAR | G_EVAL);
                SPAGAIN;
                if (SvTRUE(ERRSV)) {
                    SV *e = newSVsv(ERRSV);
                    SV *resp;
                    if (n > 0) (void)POPs;
                    PUTBACK; FREETMPS; LEAVE;
                    resp = oa_error_msg(aTHX_ 500, SvPV_nolen(e));
                    SvREFCNT_dec(e);
                    return resp;
                }
                if (n > 0) { SV *r = POPs; if (SvTRUE(r)) ret = newSVsv(r); }
                PUTBACK; FREETMPS; LEAVE;
                if (!ret) { ok = 0; break; }
                (void)hv_store(auth, np, (I32)nl, ret, 0);
            }
        }
        if (ok) {
            (void)hv_stores(env, "openapi.auth",
                            newRV_inc((SV *)auth));
            return NULL;
        }
    }
    return oa_error_msg(aTHX_ 401, "unauthorized");
}

/* ---- CSRF -------------------------------------------------------------------------- */

/* "scheme://host:port/..." or a bare "host:port" -> the host:port slice */
static void oa_origin_host(const char *p, STRLEN l, const char **hp, STRLEN *hl) {
    STRLEN i = 0, s;
    const char *sep = "://";
    for (i = 0; i + 2 < l; i++)
        if (p[i] == ':' && p[i+1] == '/' && p[i+2] == '/') { i += 3; break; }
    if (i + 2 >= l) i = 0;   /* no scheme: treat the whole thing as authority */
    s = i;
    while (i < l && p[i] != '/' && p[i] != '?' && p[i] != '#') i++;
    *hp = p + s;
    *hl = i - s;
    (void)sep;
}

/* Enforce CSRF protection for state-changing methods. cfg keys (normalised at
 * to_app time): origins (AV of allowed origins, may be empty for same-origin),
 * secret (SV, present => double-submit), cookie (SV name), header (SV name).
 * Returns NULL when the request may proceed, else a +1 403 response. Safe
 * methods (GET/HEAD/OPTIONS/TRACE) always pass. */
static SV *oa_csrf_check(pTHX_ oa_op *o, SV *env_rv, HV *cfg) {
    HV *env = (HV *)SvRV(env_rv);
    STRLEN ml; const char *mp = SvPV_const(o->method, ml);   /* lowercase */
    SV *origin, *host, **sv, **chk;
    AV *origins;
    const char *oh = NULL;
    STRLEN ohl = 0;
    int matched = 0;

    if ((ml == 3 && memEQ(mp, "get", 3)) || (ml == 4 && memEQ(mp, "head", 4))
        || (ml == 7 && memEQ(mp, "options", 7))
        || (ml == 5 && memEQ(mp, "trace", 5)))
        return NULL;

    /* ---- Origin / Referer check ---- */
    origin = oa_env_get(aTHX_ env, "HTTP_ORIGIN");
    if (!origin) origin = oa_env_get(aTHX_ env, "HTTP_REFERER");
    sv = hv_fetchs(cfg, "origins", 0);
    origins = (sv && *sv && SvROK(*sv)) ? (AV *)SvRV(*sv) : NULL;
    if (origin) {
        STRLEN ol; const char *op = SvPV_const(origin, ol);
        oa_origin_host(op, ol, &oh, &ohl);
    }
    if (origins && av_len(origins) >= 0) {
        SSize_t i;
        if (oh) for (i = 0; i <= av_len(origins); i++) {
            SV **a = av_fetch(origins, i, 0);
            const char *ah, *ap; STRLEN al, al2;
            if (!a || !*a) continue;
            ap = SvPV_const(*a, al);
            oa_origin_host(ap, al, &ah, &al2);
            if (al2 == ohl && memEQ(ah, oh, ohl)) { matched = 1; break; }
        }
    } else {
        /* same-origin default: Origin authority must equal Host */
        host = oa_env_get(aTHX_ env, "HTTP_HOST");
        if (oh && host) {
            STRLEN hl; const char *hpp = SvPV_const(host, hl);
            if (hl == ohl && memEQ(hpp, oh, ohl)) matched = 1;
        }
    }
    if (!matched)
        return oa_error_msg(aTHX_ 403,
            origin ? "CSRF check failed: origin not allowed"
                   : "CSRF check failed: missing Origin/Referer");

    /* ---- token: an app-owned store, via the check callback. The submitted
     * token comes from the configured header (a cross-site page cannot set a
     * custom header, so this half is what actually stops the forgery). */
    chk = hv_fetchs(cfg, "check", 0);
    if (chk && *chk && SvROK(*chk)) {
        SV **hn = hv_fetchs(cfg, "header", 0);
        STRLEN hnl, k;
        const char *hnp = SvPV_const(*hn, hnl);
        char key[160];
        SV *hd = NULL;
        dSP; int n; SV *err = NULL; SV *resp, *keep = NULL;

        if (hnl + 5 < sizeof key) {   /* the submitted token header */
            SV **v;
            memcpy(key, "HTTP_", 5);
            for (k = 0; k < hnl; k++) {
                char c = hnp[k];
                key[5 + k] = (c == '-') ? '_' : (char)toUPPER((U8)c);
            }
            v = hv_fetch(env, key, (I32)(5 + hnl), 0);
            if (v && *v && SvOK(*v)) hd = *v;
        }

        /* check($submitted_token, $env, $operationId) - a truthy return
         * passes AND is stashed as $env->{'openapi.csrf'} (mirroring the
         * security checkers' 'openapi.auth'), so the handler / after hook can
         * consume or rotate the token without re-loading the store. A die
         * becomes a 500. */
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 3);
        PUSHs(hd ? hd : &PL_sv_undef);
        PUSHs(env_rv);
        PUSHs(o->op_id);
        PUTBACK;
        n = call_sv(*chk, G_SCALAR | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            err = newSVsv(ERRSV);
            if (n > 0) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            resp = oa_error_msg(aTHX_ 500, SvPV_nolen(err));
            SvREFCNT_dec(err);
            return resp;
        }
        if (n > 0) { SV *r = POPs; if (SvTRUE(r)) keep = newSVsv(r); }
        PUTBACK; FREETMPS; LEAVE;
        if (!keep)
            return oa_error_msg(aTHX_ 403,
                "CSRF check failed: invalid or missing token");
        (void)hv_stores(env, "openapi.csrf", keep);   /* env owns it */
        /* a returned string token rotates the cookie: the framework sets it
         * on the response (any status), so the client always leaves holding a
         * fresh, unused token. A non-string truthy return (1, a ref) just
         * passes - set your own cookie in the after hook. */
        if (SvPOK(keep) && SvCUR(keep) > 0) {
            SV **cn = hv_fetchs(cfg, "cookie", 0);
            STRLEN cnl; const char *cnp = SvPV_const(*cn, cnl);
            SV *sc = newSVpvn(cnp, cnl);
            sv_catpvs(sc, "=");
            sv_catsv(sc, keep);
            sv_catpvs(sc, "; Path=/; SameSite=Strict");
            (void)hv_stores(env, "openapi.csrf.setcookie", sc);
        }
    }

    return NULL;
}

/* ---- Future completion (nonblocking servers) --------------------------------------- *
 * When a handler returns a Future on a nonblocking server AND there is
 * post-processing to do (after hook or validate_responses), the future is
 * chained with ->then(done, fail): done maps the resolved value and applies
 * response validation + the after hook; fail turns a failed future into a
 * 500 (also passed to after). Captures: [0]=api self SV (keeps the op table
 * alive), [1]=env_rv, [2]=opId SV, [3]=after or undef, [4]=vresp IV,
 * [5]=op pointer IV, [6]=opts HV ref or undef. */

XS_INTERNAL(oa_then_done_cb);
XS_INTERNAL(oa_then_done_cb) {
    dXSARGS;
    AV *cap = oa_clos_cap(aTHX_ cv);
    SV *env_rv, *opid, *after, *resp, *optsv;
    oa_op *o;
    int vresp;
    if (!cap) XSRETURN_EMPTY;
    env_rv = *av_fetch(cap, 1, 0);
    opid   = *av_fetch(cap, 2, 0);
    after  = *av_fetch(cap, 3, 0);
    vresp  = (int)SvIV(*av_fetch(cap, 4, 0));
    o      = INT2PTR(oa_op *, SvIV(*av_fetch(cap, 5, 0)));
    optsv  = *av_fetch(cap, 6, 0);
    resp   = oa_map_result(aTHX_ items > 0 ? ST(0) : &PL_sv_undef);
    if (vresp) {
        SV *bad = oa_check_response_opts(aTHX_ o, resp, vresp,
            SvROK(optsv) ? (HV *)SvRV(optsv) : NULL, env_rv);
        if (bad) { SvREFCNT_dec(resp); resp = bad; }
    }
    oa_run_after(aTHX_ &resp, after, env_rv, opid);
    oa_finalize(aTHX_ resp, env_rv, SvROK(optsv) ? (HV *)SvRV(optsv) : NULL);
    ST(0) = sv_2mortal(resp);
    XSRETURN(1);
}

XS_INTERNAL(oa_then_fail_cb);
XS_INTERNAL(oa_then_fail_cb) {
    dXSARGS;
    AV *cap = oa_clos_cap(aTHX_ cv);
    SV *env_rv, *opid, *after, *resp, *optsv;
    if (!cap) XSRETURN_EMPTY;
    env_rv = *av_fetch(cap, 1, 0);
    opid   = *av_fetch(cap, 2, 0);
    after  = *av_fetch(cap, 3, 0);
    optsv  = *av_fetch(cap, 6, 0);
    resp   = oa_error_msg(aTHX_ 500,
        (items > 0 && SvOK(ST(0))) ? SvPV_nolen(ST(0)) : "handler future failed");
    oa_run_after(aTHX_ &resp, after, env_rv, opid);
    oa_finalize(aTHX_ resp, env_rv, SvROK(optsv) ? (HV *)SvRV(optsv) : NULL);
    ST(0) = sv_2mortal(resp);
    XSRETURN(1);
}

/* one capture AV for the then callbacks (each closure needs its own) */
static AV *oa_then_cap(pTHX_ SV *self_sv, SV *env_rv, oa_op *o, SV *after,
                       int vresp, SV *optsv) {
    AV *cap = newAV();
    av_push(cap, SvREFCNT_inc(self_sv));
    av_push(cap, SvREFCNT_inc(env_rv));
    av_push(cap, newSVsv(o->op_id));
    av_push(cap, after && SvOK(after) ? SvREFCNT_inc(after) : newSV(0));
    av_push(cap, newSViv(vresp));
    av_push(cap, newSViv(PTR2IV(o)));
    av_push(cap, optsv && SvROK(optsv) ? SvREFCNT_inc(optsv) : newSV(0));
    return cap;
}

/* ---- the request path ------------------------------------------------------------ */

/* Serve one PSGI request. Returns a PSGI triplet SV, or a Future SV on a
 * non-blocking server (chained with the post-processing when an after hook
 * or response validation is active). (+1 owned by caller) */
static SV *oa_serve_psgi(pTHX_ SV *self_sv, HV *handlers, SV *env_rv,
                         int vresp, SV *before, SV *after, HV *seccb,
                         HV *csrf, HV *opts) {
    oa_api *a = (oa_api *)INT2PTR(void *, SvIV(SvRV(self_sv)));
    HV *env = (HV *)SvRV(env_rv);
    SV *msv = oa_env_get(aTHX_ env, "REQUEST_METHOD");
    SV *psv = oa_env_get(aTHX_ env, "PATH_INFO");
    SV *qsv = oa_env_get(aTHX_ env, "QUERY_STRING");
    HV *caps  = (HV *)sv_2mortal((SV *)newHV());
    AV *allow = (AV *)sv_2mortal((SV *)newAV());
    oa_op *o;
    HV *headers;
    SV *body, *handler;
    HV *params = NULL;
    AV *errs;
    int is_options = 0;
    HV *cors = NULL;
    int negotiate = 0;
    IV max_body = 0;
    STRLEN ml, pl, il;
    const char *mp, *pp, *ip;
    SV **h;

    /* every triplet exit runs through finalize (problem+json, CORS, headers) */
#define OA_FIN(r) oa_fin(aTHX_ (r), env_rv, opts)

    if (opts) {
        SV **v;
        if ((v = hv_fetchs(opts, "cors", 0)) && *v && SvROK(*v))
            cors = (HV *)SvRV(*v);
        if ((v = hv_fetchs(opts, "negotiate", 0)) && *v) negotiate = SvTRUE(*v);
        if ((v = hv_fetchs(opts, "max_body_size", 0)) && *v) max_body = SvIV(*v);
    }

    mp = msv ? SvPV_const(msv, ml) : (ml = 3, "GET");
    pp = psv ? SvPV_const(psv, pl) : (pl = 1, "/");
    is_options = (ml == 7 && (mp[0]=='O'||mp[0]=='o') && oa_ci_eq(mp, ml, "options", 7));
    o = oa_route(aTHX_ a, mp, ml, pp, pl, caps, allow);
    if (!o) {
        if (av_len(allow) >= 0) {   /* path exists, method does not */
            SV *resp;
            AV *tv, *ha;
            SV **hh;
            SV *joined;
            SSize_t i;
            /* CORS preflight: an OPTIONS with Access-Control-Request-Method */
            if (cors && is_options
                && oa_env_get(aTHX_ env, "HTTP_ACCESS_CONTROL_REQUEST_METHOD"))
                return OA_FIN(oa_cors_preflight(aTHX_ env_rv, cors, allow));
            resp = oa_error_msg(aTHX_ 405, "method not allowed");
            tv = (AV *)SvRV(resp);
            hh = av_fetch(tv, 1, 0);
            ha = (AV *)SvRV(*hh);
            joined = newSVpvs("");
            for (i = 0; i <= av_len(allow); i++) {
                SV **m = av_fetch(allow, i, 0);
                if (i) sv_catpvs(joined, ", ");
                sv_catsv(joined, *m);
            }
            av_push(ha, newSVpvs("Allow"));
            av_push(ha, joined);
            return OA_FIN(resp);
        }
        return OA_FIN(oa_error_msg(aTHX_ 404, "not found"));
    }

    /* body size limit: reject an over-large declared Content-Length before
     * doing any auth or reading the body */
    if (max_body > 0) {
        SV *cl = oa_env_get(aTHX_ env, "CONTENT_LENGTH");
        if (cl && SvIV(cl) > max_body) {
            SV *resp = oa_error_msg(aTHX_ 413, "request body too large");
            oa_run_after(aTHX_ &resp, after, env_rv, o->op_id);
            return OA_FIN(resp);
        }
    }

    /* CSRF: guard state-changing methods before anything else touches the
     * request (independent of who is authenticated) */
    if (csrf) {
        SV *denied = oa_csrf_check(aTHX_ o, env_rv, csrf);
        if (denied) {
            oa_run_after(aTHX_ &denied, after, env_rv, o->op_id);
            return OA_FIN(denied);
        }
    }

    /* spec-driven security first: extract credential, run the checker, 401
     * when no requirement alternative is satisfied */
    if (o->nsec && seccb) {
        SV *denied = oa_security_check(aTHX_ a, o, env_rv, seccb);
        if (denied) {
            oa_run_after(aTHX_ &denied, after, env_rv, o->op_id);
            return OA_FIN(denied);
        }
    }

    /* content negotiation (opt-in): 415 on an unsupported request body type,
     * 406 when the client's Accept admits none of the declared responses */
    if (negotiate) {
        SV *bad = oa_check_request_ctype(aTHX_ o, env);
        if (!bad) bad = oa_check_accept(aTHX_ o, env);
        if (bad) {
            oa_run_after(aTHX_ &bad, after, env_rv, o->op_id);
            return OA_FIN(bad);
        }
    }

    /* before hook: post-route, pre-validation - a reference return
     * short-circuits (the auth case: return [401, ...]) */
    if (before && SvOK(before)) {
        SV *early = oa_run_before(aTHX_ before, env_rv, o->op_id);
        if (early) {
            oa_run_after(aTHX_ &early, after, env_rv, o->op_id);
            return OA_FIN(early);
        }
    }

    headers = (HV *)sv_2mortal((SV *)oa_headers_for(aTHX_ o, env));
    body    = o->nbodies ? oa_read_body_env(aTHX_ env) : NULL;
    errs    = (AV *)sv_2mortal((SV *)newAV());

    if (!oa_validate_op(aTHX_ a, o, caps,
                        qsv ? qsv : &PL_sv_no, headers, body,
                        &params, errs)) {
        SV *resp = oa_error_response(aTHX_ 400, errs);
        oa_run_after(aTHX_ &resp, after, env_rv, o->op_id);
        return OA_FIN(resp);
    }

    ip = SvPV_const(o->op_id, il);
    h  = hv_fetch(handlers, ip, (I32)il, 0);
    if (!h || !*h || !SvROK(*h) || SvTYPE(SvRV(*h)) != SVt_PVCV) {
        SV *resp;
        SvREFCNT_dec((SV *)params);
        resp = oa_error_msg(aTHX_ 501, "no handler for this operation");
        oa_run_after(aTHX_ &resp, after, env_rv, o->op_id);
        return OA_FIN(resp);
    }
    handler = *h;

    {   /* call the handler: ($params, $env) */
        dSP; int n; SV *res = NULL, *resp;
        ENTER; SAVETMPS; PUSHMARK(SP);
        EXTEND(SP, 2);
        mPUSHs(newRV_noinc((SV *)params));
        PUSHs(env_rv);
        PUTBACK;
        n = call_sv(handler, G_SCALAR | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            SV *e = newSVsv(ERRSV);          /* keep past FREETMPS */
            if (n > 0) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            resp = oa_error_msg(aTHX_ 500, SvPV_nolen(e));
            SvREFCNT_dec(e);
            oa_run_after(aTHX_ &resp, after, env_rv, o->op_id);
            return OA_FIN(resp);
        }
        res = n > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;

        if (oa_is_future(aTHX_ res)) {
            SV *nb = oa_env_get(aTHX_ env, "psgi.nonblocking");
            if (nb && SvTRUE(nb)) {
                int want_after = after && SvOK(after);
                if (!want_after && !vresp && !opts)
                    return res;              /* nothing to add: hand it over */
                {   /* chain ->then(done, fail) so mapping + response
                     * validation + finalize + the after hook run on
                     * resolution */
                    dSP; int n2; SV *derived = NULL;
                    SV *optsv = opts ? sv_2mortal(newRV_inc((SV *)opts))
                                     : &PL_sv_undef;
                    SV *done = oa_closure(aTHX_ oa_then_done_cb,
                        oa_then_cap(aTHX_ self_sv, env_rv, o, after, vresp, optsv));
                    SV *fail = oa_closure(aTHX_ oa_then_fail_cb,
                        oa_then_cap(aTHX_ self_sv, env_rv, o, after, 0, optsv));
                    ENTER; SAVETMPS; PUSHMARK(SP);
                    EXTEND(SP, 3);
                    PUSHs(sv_2mortal(res));
                    PUSHs(sv_2mortal(done));
                    PUSHs(sv_2mortal(fail));
                    PUTBACK;
                    n2 = call_method("then", G_SCALAR | G_EVAL);
                    SPAGAIN;
                    if (!SvTRUE(ERRSV) && n2 > 0) derived = SvREFCNT_inc(POPs);
                    else if (n2 > 0) (void)POPs;
                    PUTBACK; FREETMPS; LEAVE;
                    if (derived) return derived;
                    return OA_FIN(oa_error_msg(aTHX_ 500, "could not chain future"));
                }
            }
            {                                    /* blocking: await inline */
                dSP; int n2; SV *val = NULL;
                ENTER; SAVETMPS; PUSHMARK(SP);
                EXTEND(SP, 1); PUSHs(sv_2mortal(res));
                PUTBACK;
                n2 = call_method("get", G_SCALAR | G_EVAL);
                SPAGAIN;
                if (SvTRUE(ERRSV)) {
                    SV *e = newSVsv(ERRSV);  /* keep past FREETMPS */
                    if (n2 > 0) (void)POPs;
                    PUTBACK; FREETMPS; LEAVE;
                    resp = oa_error_msg(aTHX_ 500, SvPV_nolen(e));
                    SvREFCNT_dec(e);
                    oa_run_after(aTHX_ &resp, after, env_rv, o->op_id);
                    return OA_FIN(resp);
                }
                val = n2 > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
                PUTBACK; FREETMPS; LEAVE;
                res = val;
            }
        }
        resp = oa_map_result(aTHX_ res);
        SvREFCNT_dec(res);
        if (vresp) {
            SV *bad = oa_check_response_opts(aTHX_ o, resp, vresp, opts, env_rv);
            if (bad) { SvREFCNT_dec(resp); resp = bad; }
        }
        oa_run_after(aTHX_ &resp, after, env_rv, o->op_id);
        return OA_FIN(resp);
    }
#undef OA_FIN
}

#endif /* OA_PLACK_H */

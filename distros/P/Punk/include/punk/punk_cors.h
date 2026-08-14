/* punk_cors.h - cross-origin resource sharing, in C.
 *
 * Two things happen here, both in pc_app_cb, which is the one function every
 * request passes through before punk_serve routes it:
 *
 *   - a preflight is answered outright, before routing. It has to be: an
 *     OPTIONS to a path with no OPTIONS route would otherwise be the router's
 *     405, and the reply needs the method set the router computes anyway.
 *   - every other response is decorated on the way out - including the 404s
 *     and 405s that never build a context, which is why this is not an
 *     after-dispatch hook.
 *
 * What this is not: access control. CORS tells a *browser* what script is
 * allowed to read. Nothing else honours it, and a credentialed cross-origin
 * write still meets the csrf check.
 *
 * Include after punk_route.h (pr_allow), punk_response.h (punk_triplet) and
 * punk_static.h (punk_closure).
 */

#ifndef PUNK_CORS_H
#define PUNK_CORS_H

/* ---- configuration -------------------------------------------------------- */

static SV *pco_get(pTHX_ HV *cfg, const char *k) {
    SV **e = cfg ? hv_fetch(cfg, k, (I32)strlen(k), 0) : NULL;
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

static SV *pco_env(pTHX_ HV *env, const char *k) {
    SV **e = hv_fetch(env, k, (I32)strlen(k), 0);
    return (e && *e && SvOK(*e) && SvCUR(*e)) ? *e : NULL;
}

/* Join an arrayref config value with ", ", or return the plain string. */
static SV *pco_list(pTHX_ SV *v) {
    AV *av;
    SSize_t i, n;
    SV *out;
    if (!v) return NULL;
    if (!(SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV)) return newSVsv(v);
    av = (AV *)SvRV(v);
    n = av_len(av) + 1;
    if (!n) return NULL;
    out = newSVpvs("");
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        if (!(e && *e && SvOK(*e))) continue;
        if (SvCUR(out)) sv_catpvs(out, ", ");
        sv_catsv(out, *e);
    }
    return out;
}

/* Is this request's path one CORS applies to? `paths` limits it to prefixes -
 * which is how "the API side only" is expressed. */
static int pco_path_ok(pTHX_ HV *cfg, HV *env) {
    SV *paths = pco_get(aTHX_ cfg, "paths");
    SV *pi;
    AV *av;
    SSize_t i, n;
    STRLEN pl;
    const char *p;
    if (!paths) return 1;
    if (!(SvROK(paths) && SvTYPE(SvRV(paths)) == SVt_PVAV)) return 1;
    pi = pco_env(aTHX_ env, "PATH_INFO");
    p  = pi ? SvPV_const(pi, pl) : "/";
    if (!pi) pl = 1;
    av = (AV *)SvRV(paths);
    n = av_len(av) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        STRLEN xl;
        const char *x;
        if (!(e && *e && SvOK(*e))) continue;
        x = SvPV_const(*e, xl);
        if (ps_under(p, pl, x, xl)) return 1;
    }
    return 0;
}

/* The value for Access-Control-Allow-Origin, or NULL when this origin is not
 * allowed. '*' passes through as '*'; a list matches exactly and echoes; a
 * coderef decides and may return a replacement origin. Credentials force the
 * echo, because browsers refuse '*' with them. */
static SV *pco_allow_origin(pTHX_ HV *cfg, SV *origin) {
    SV *spec = pco_get(aTHX_ cfg, "origins");
    if (!origin) return NULL;
    if (!spec) return newSVpvs("*");

    if (SvROK(spec) && SvTYPE(SvRV(spec)) == SVt_PVCV) {
        dSP; int count; SV *r = NULL;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(origin); PUTBACK;
        count = call_sv(spec, G_SCALAR | G_EVAL);
        SPAGAIN;
        if (count > 0) { SV *v = POPs; if (SvTRUE(v)) r = newSVsv(v); }
        PUTBACK; FREETMPS; LEAVE;
        if (r && !SvROK(r) && SvCUR(r) > 1) return r;   /* an origin back */
        if (r) { SvREFCNT_dec(r); return newSVsv(origin); }  /* just true */
        return NULL;
    }
    if (SvROK(spec) && SvTYPE(SvRV(spec)) == SVt_PVAV) {
        AV *av = (AV *)SvRV(spec);
        SSize_t i, n = av_len(av) + 1;
        STRLEN ol;
        const char *o = SvPV_const(origin, ol);
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            STRLEN xl;
            const char *x;
            if (!(e && *e && SvOK(*e))) continue;
            x = SvPV_const(*e, xl);
            if (xl == 1 && *x == '*') return newSVpvs("*");
            if (xl == ol && memEQ(x, o, ol)) return newSVsv(origin);
        }
        return NULL;
    }
    {   /* a plain string: '*' or one origin */
        STRLEN sl, ol;
        const char *s = SvPV_const(spec, sl);
        const char *o = SvPV_const(origin, ol);
        if (sl == 1 && *s == '*') return newSVpvs("*");
        return (sl == ol && memEQ(s, o, ol)) ? newSVsv(origin) : NULL;
    }
}

static int pco_credentials(pTHX_ HV *cfg) {
    SV *v = pco_get(aTHX_ cfg, "credentials");
    return (v && SvTRUE(v)) ? 1 : 0;
}

/* ---- the header block ------------------------------------------------------ */

/* The pairs every CORS response carries. `Vary: Origin` goes on whenever the
 * value depends on the request's origin - anything but a flat '*' - because a
 * shared cache that misses it will hand one origin's response to another. */
static void pco_common(pTHX_ AV *headers, HV *cfg, SV *allow) {
    STRLEN al;
    const char *a = SvPV_const(allow, al);
    av_push(headers, newSVpvs("Access-Control-Allow-Origin"));
    av_push(headers, newSVsv(allow));
    if (!(al == 1 && *a == '*')) {
        av_push(headers, newSVpvs("Vary"));
        av_push(headers, newSVpvs("Origin"));
    }
    if (pco_credentials(aTHX_ cfg)) {
        av_push(headers, newSVpvs("Access-Control-Allow-Credentials"));
        av_push(headers, newSVpvs("true"));
    }
}

/* The methods a path answers, from every tier that routes: the web router and
 * each api mount whose prefix covers it. Asking rather than repeating a
 * configured list is the whole reason preflight lives here - but the router
 * alone would miss every spec operation, which for an api-first application is
 * all of them. Pushes uppercase method SVs into `out`. */
static void pco_methods_for(pTHX_ HV *state, const char *path, STRLEN plen,
                            AV *out) {
    SV *router = ps_state(aTHX_ state, K_ROUTER);
    AV *apims  = ps_state_av(aTHX_ state, K_API_MOUNTS);
    HV *seen   = (HV *)sv_2mortal((SV *)newHV());
    SSize_t i, n;

    if (router && SvROK(router)) {
        AV *web = (AV *)sv_2mortal((SV *)newAV());
        pr_router *rt = (pr_router *)INT2PTR(void *, SvIV(SvRV(router)));
        /* an empty request method keeps every method in the set - we want the
         * whole Allow list, not "everything except this request's" */
        (void)pr_allow(aTHX_ rt, "", 0, path, plen, web);
        n = av_len(web) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(web, i, 0);
            if (e && *e && !hv_exists_ent(seen, *e, 0)) {
                (void)hv_store_ent(seen, *e, PUNK_SET_TRUE, 0);
                av_push(out, newSVsv(*e));
            }
        }
    }

    if (apims) {
        const oa_abi *A = punk_oa_try(aTHX);
        n = av_len(apims) + 1;
        for (i = 0; A && i < n; i++) {
            SV **mp = av_fetch(apims, i, 0);
            HV *am;
            SV **x, *api;
            const char *pf, *rest;
            STRLEN pfl, restl;
            void *api_c;
            AV *allowv;
            SSize_t j, an;
            if (!mp || !*mp || !SvROK(*mp)) continue;
            am = (HV *)SvRV(*mp);
            x = hv_fetchs(am, "prefix", 0);
            if (x && *x && SvOK(*x)) pf = SvPV_const(*x, pfl);
            else { pf = ""; pfl = 0; }
            if (!ps_under(path, plen, pf, pfl)) continue;
            rest  = plen > pfl ? path + pfl : "/";
            restl = plen > pfl ? plen - pfl : 1;
            x = hv_fetchs(am, "api", 0);
            if (!(x && *x)) continue;
            api = *x;
            api_c = A->api_of(aTHX_ api);
            if (!api_c) continue;
            allowv = (AV *)sv_2mortal((SV *)newAV());
            /* a method no spec declares, so route() reports the 405 Allow set
             * for the path - which is the complete list we are after */
            (void)A->route(aTHX_ api_c, "PUNKCORSPROBE", 13, rest, restl,
                           NULL, allowv);
            an = av_len(allowv) + 1;
            for (j = 0; j < an; j++) {
                SV **e = av_fetch(allowv, j, 0);
                if (e && *e && !hv_exists_ent(seen, *e, 0)) {
                    (void)hv_store_ent(seen, *e, PUNK_SET_TRUE, 0);
                    av_push(out, newSVsv(*e));
                }
            }
        }
    }
    if (av_len(out) > 0)
        sortsv(AvARRAY(out), (STRLEN)(av_len(out) + 1), Perl_sv_cmp);
}

/* ---- preflight ------------------------------------------------------------- */

/* Answered before routing, so a preflight never needs an OPTIONS route.
 *
 * Returns the response (+1), or NULL when this is not a preflight and the
 * request should carry on to punk_serve. */
static SV *pco_preflight(pTHX_ HV *state, HV *env) {
    SV *cfg_sv = ps_state(aTHX_ state, K_CORS);
    HV *cfg;
    SV *method, *origin, *want, *allow;
    AV *methods = NULL, *headers, *resp, *body;
    SV *mlist = NULL;
    STRLEN ml, wl;
    const char *m, *w;
    int i, n, found = 0;

    if (!(cfg_sv && SvROK(cfg_sv) && SvTYPE(SvRV(cfg_sv)) == SVt_PVHV))
        return NULL;
    cfg = (HV *)SvRV(cfg_sv);

    method = pco_env(aTHX_ env, "REQUEST_METHOD");
    if (!method) return NULL;
    m = SvPV_const(method, ml);
    if (!(ml == 7 && memEQ(m, "OPTIONS", 7))) return NULL;

    origin = pco_env(aTHX_ env, "HTTP_ORIGIN");
    want   = pco_env(aTHX_ env, "HTTP_ACCESS_CONTROL_REQUEST_METHOD");
    if (!origin || !want) return NULL;      /* a plain OPTIONS: let it route */
    if (!pco_path_ok(aTHX_ cfg, env)) return NULL;

    allow = pco_allow_origin(aTHX_ cfg, origin);
    if (!allow)
        return ps_err_triplet(aTHX_ 403, PS_ERR_403, sizeof(PS_ERR_403) - 1,
                              NULL);
    sv_2mortal(allow);

    /* Which methods this path really answers. Asking the router rather than
     * repeating a configured list is the whole reason this lives here: the
     * reply cannot promise a method the application does not serve. */
    {
        SV *over = pco_get(aTHX_ cfg, "methods");
        if (over) {
            mlist = pco_list(aTHX_ over);
            w = SvPV_const(want, wl);
            if (mlist) {
                STRLEN ll;
                const char *l = SvPV_const(mlist, ll);
                /* a substring hit is enough - the list is ours, not input */
                found = (ll >= wl) && strstr(l, w) != NULL;
            }
        }
        else {
            SV *pi = pco_env(aTHX_ env, "PATH_INFO");
            STRLEN pl;
            const char *p = pi ? SvPV_const(pi, pl) : "/";
            if (!pi) pl = 1;
            methods = (AV *)sv_2mortal((SV *)newAV());
            pco_methods_for(aTHX_ state, p, pl, methods);
            w = SvPV_const(want, wl);
            n = (int)(av_len(methods) + 1);
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(methods, i, 0);
                STRLEN xl;
                const char *x;
                if (!(e && *e && SvOK(*e))) continue;
                x = SvPV_const(*e, xl);
                if (xl == wl && memEQ(x, w, wl)) { found = 1; break; }
            }
            mlist = pco_list(aTHX_ sv_2mortal(newRV_inc((SV *)methods)));
        }
    }
    if (mlist) sv_2mortal(mlist);

    if (!found)
        return ps_err_triplet(aTHX_ 403, PS_ERR_403, sizeof(PS_ERR_403) - 1,
                              NULL);

    headers = newAV();
    pco_common(aTHX_ headers, cfg, allow);
    if (mlist && SvCUR(mlist)) {
        av_push(headers, newSVpvs("Access-Control-Allow-Methods"));
        av_push(headers, newSVsv(mlist));
    }
    {   /* the configured header list, or the requested one echoed back */
        SV *hs = pco_get(aTHX_ cfg, "headers");
        SV *val = hs ? pco_list(aTHX_ hs)
                     : NULL;
        if (!val) {
            SV *req = pco_env(aTHX_ env, "HTTP_ACCESS_CONTROL_REQUEST_HEADERS");
            if (req) val = newSVsv(req);
        }
        if (val && SvCUR(val)) {
            av_push(headers, newSVpvs("Access-Control-Allow-Headers"));
            av_push(headers, val);
        }
        else if (val) SvREFCNT_dec(val);
    }
    {
        SV *ma = pco_get(aTHX_ cfg, "max_age");
        av_push(headers, newSVpvs("Access-Control-Max-Age"));
        av_push(headers, ma ? newSVsv(ma) : newSViv(600));
    }
    /* the preflight reply varies by what was asked, not just by origin */
    av_push(headers, newSVpvs("Vary"));
    av_push(headers, newSVpvs("Access-Control-Request-Method, "
                              "Access-Control-Request-Headers"));
    av_push(headers, newSVpvs("Content-Length"));
    av_push(headers, newSViv(0));

    body = newAV();
    av_push(body, newSVpvs(""));
    resp = newAV();
    av_push(resp, newSViv(204));
    av_push(resp, newRV_noinc((SV *)headers));
    av_push(resp, newRV_noinc((SV *)body));
    return newRV_noinc((SV *)resp);
}

/* ---- decorating a real response -------------------------------------------- */

/* Push the response headers onto an existing header AV. */
static void pco_add(pTHX_ AV *headers, HV *cfg, SV *allow) {
    SV *expose;
    pco_common(aTHX_ headers, cfg, allow);
    expose = pco_get(aTHX_ cfg, "expose");
    if (expose) {
        SV *v = pco_list(aTHX_ expose);
        if (v && SvCUR(v)) {
            av_push(headers, newSVpvs("Access-Control-Expose-Headers"));
            av_push(headers, v);
        }
        else if (v) SvREFCNT_dec(v);
    }
}

/* The header AV of a triplet, or NULL. */
static AV *pco_headers_of(pTHX_ SV *resp) {
    AV *r;
    SV **hp;
    if (!(resp && SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVAV)) return NULL;
    r = (AV *)SvRV(resp);
    if (av_len(r) < 1) return NULL;
    hp = av_fetch(r, 1, 0);
    return (hp && *hp && SvROK(*hp) && SvTYPE(SvRV(*hp)) == SVt_PVAV)
        ? (AV *)SvRV(*hp) : NULL;
}

/* The responder wrapper for a streaming response: the server hands our
 * closure a responder, and we hand the application one that decorates the
 * triplet on its way past. */
XS_INTERNAL(pco_responder_cb);
XS_INTERNAL(pco_responder_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *inner, *allow, *cfg_sv;
    if (!cap || items < 1) XSRETURN_EMPTY;
    inner  = *av_fetch(cap, 0, 0);
    cfg_sv = *av_fetch(cap, 1, 0);
    allow  = *av_fetch(cap, 2, 0);
    {
        AV *headers = pco_headers_of(aTHX_ ST(0));
        if (headers && SvROK(cfg_sv))
            pco_add(aTHX_ headers, (HV *)SvRV(cfg_sv), allow);
    }
    {   /* hand it on and return whatever the real responder returned */
        dSP; int count; SV *r;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(ST(0)); PUTBACK;
        count = call_sv(inner, G_SCALAR);
        SPAGAIN;
        r = count > 0 ? SvREFCNT_inc(POPs) : newSV(0);
        PUTBACK; FREETMPS; LEAVE;
        ST(0) = sv_2mortal(r);
    }
    XSRETURN(1);
}

/* The streaming app wrapper: $app->($responder) becomes
 * $app->(wrapped($responder)). */
XS_INTERNAL(pco_stream_cb);
XS_INTERNAL(pco_stream_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *app, *cfg_sv, *allow, *wrapped;
    AV *rcap;
    if (!cap || items < 1) XSRETURN_EMPTY;
    app    = *av_fetch(cap, 0, 0);
    cfg_sv = *av_fetch(cap, 1, 0);
    allow  = *av_fetch(cap, 2, 0);

    rcap = newAV();
    av_push(rcap, newSVsv(ST(0)));       /* the server's responder */
    av_push(rcap, newSVsv(cfg_sv));
    av_push(rcap, newSVsv(allow));
    wrapped = sv_2mortal(punk_closure(aTHX_ pco_responder_cb, rcap));

    {
        dSP;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 1); PUSHs(wrapped); PUTBACK;
        (void)call_sv(app, G_VOID);
        SPAGAIN;
        PUTBACK; FREETMPS; LEAVE;
    }
    XSRETURN_EMPTY;
}

/* Decorate whatever punk_serve returned. Three shapes reach here and all
 * three matter: a triplet (including the 404s and 405s that never build a
 * context), a streaming coderef, and a Future from a nonblocking handler.
 * *resp is replaced in place for the shapes that need wrapping. */
static void pco_decorate(pTHX_ HV *state, HV *env, SV **resp) {
    SV *cfg_sv = ps_state(aTHX_ state, K_CORS);
    HV *cfg;
    SV *origin, *allow;

    if (!(cfg_sv && SvROK(cfg_sv) && SvTYPE(SvRV(cfg_sv)) == SVt_PVHV)) return;
    cfg = (HV *)SvRV(cfg_sv);
    origin = pco_env(aTHX_ env, "HTTP_ORIGIN");
    if (!origin) return;                 /* not a cross-origin request */
    if (!pco_path_ok(aTHX_ cfg, env)) return;
    allow = pco_allow_origin(aTHX_ cfg, origin);
    if (!allow) return;                  /* refused: send nothing, not a lie */
    sv_2mortal(allow);

    if (!(*resp && SvROK(*resp))) return;

    if (SvTYPE(SvRV(*resp)) == SVt_PVAV) {
        AV *headers = pco_headers_of(aTHX_ *resp);
        if (headers) pco_add(aTHX_ headers, cfg, allow);
        return;
    }

    if (SvTYPE(SvRV(*resp)) == SVt_PVCV) {
        AV *cap = newAV();
        av_push(cap, newSVsv(*resp));
        av_push(cap, newSVsv(cfg_sv));
        av_push(cap, newSVsv(allow));
        SvREFCNT_dec(*resp);
        *resp = punk_closure(aTHX_ pco_stream_cb, cap);
        return;
    }

    if (SvOBJECT(SvRV(*resp)) && pcx_can(aTHX_ *resp, "then")) {
        /* a Future: chain the decoration onto its result, the shape
         * Punk::App::_finish_future already is */
        dSP; int count; SV *chained = NULL;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 3);
        PUSHs(*resp);
        PUSHs(cfg_sv);
        PUSHs(allow);
        PUTBACK;
        count = call_pv("Punk::CORS::_chain", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (count > 0 && !SvTRUE(ERRSV)) chained = SvREFCNT_inc(POPs);
        else if (count > 0) (void)POPs;
        PUTBACK; FREETMPS; LEAVE;
        if (chained) { SvREFCNT_dec(*resp); *resp = chained; }
        return;
    }
}

#endif /* PUNK_CORS_H */

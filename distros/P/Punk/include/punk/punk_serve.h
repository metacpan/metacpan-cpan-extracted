/* punk_serve.h - the request dispatcher, in C.
 *
 * The whole per-request path Punk::App::compile used to build as a Perl
 * closure: static exact hit, API-mount route+dispatch, PSGI/static mounts,
 * dynamic hit, 404/405, then for a web route the before hooks, the guards, the
 * controller (or a websocket upgrade), and the response finish. Everything
 * routes and validates through the C tiers already in place; the only Perl
 * frames are the hooks, guards, controllers and mounted PSGI apps. The
 * boot-time half of Punk::App (the registrar and compile) stays Perl.
 *
 * compile() freezes a `state` hash and returns sub { Punk::_serve($state,
 * $_[0]) }. A nonblocking Future is handed to Punk::App::_finish_future
 * (building the ->then chain is Perl's job); everything else finishes here.
 *
 * Must be included after punk_route.h, punk_dispatch.h and punk_context.h.
 */

#ifndef PUNK_SERVE_H
#define PUNK_SERVE_H

static const char PS_ERR_404[] = "{\"errors\":[{\"message\":\"Not Found\"}]}";
static const char PS_ERR_403[] = "{\"errors\":[{\"message\":\"Forbidden\"}]}";
static const char PS_ERR_405[] =
    "{\"errors\":[{\"message\":\"Method Not Allowed\"}]}";

static SV *ps_state(pTHX_ HV *st, const char *k) {
    SV **e = hv_fetch(st, k, (I32)strlen(k), 0);
    return (e && *e) ? *e : NULL;
}
static AV *ps_state_av(pTHX_ HV *st, const char *k) {
    SV *v = ps_state(aTHX_ st, k);
    return (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV) ? (AV *)SvRV(v) : NULL;
}

/* env{$key} as a borrowed const char*, or (def,*len). */
static const char *ps_env_str(pTHX_ HV *env, const char *k, const char *def,
                              STRLEN *len) {
    SV **e = hv_fetch(env, k, (I32)strlen(k), 0);
    if (e && *e && SvOK(*e) && SvCUR(*e)) return SvPV_const(*e, *len);
    *len = strlen(def);
    return def;
}

/* Bless a fresh context AV (the PCX_* layout from punk_context.h: 0=env,
 * 1=app, 6=match) into the app's context class. match is owned. */
static SV *ps_ctx(pTHX_ SV *ctx_class, HV *env, SV *app, SV *match) {
    AV *av = newAV();
    av_extend(av, PCX_MATCH);
    (void)av_store(av, PCX_ENV,   newRV_inc((SV *)env));
    (void)av_store(av, PCX_APP,   newSVsv(app));
    (void)av_store(av, PCX_MATCH, match);
    return sv_bless(newRV_noinc((SV *)av), gv_stashsv(ctx_class, GV_ADD));
}

/* $on_error->($c,$err) coerced, or the 500 default (+1). */
static SV *punk_handle_error(pTHX_ SV *c, SV *err, SV *on_error) {
    HV *body, *m; AV *errs; SV *bytes; STRLEN l; const char *p;
    if (on_error && SvOK(on_error)) {
        int died = 0;
        SV *r = pcx_call2(aTHX_ on_error, c, err, &died);
        if (!died && r && SvROK(r)) {
            SV *co = punk_coerce(aTHX_ c, r);
            SvREFCNT_dec(r);
            return co;
        }
        if (r) SvREFCNT_dec(r);
    }
    body = newHV(); errs = newAV(); m = newHV();
    p = SvOK(err) ? SvPV_const(err, l) : "";
    if (!SvOK(err)) l = 0;
    (void)hv_stores(m, "message", newSVpvn(p, l));
    av_push(errs, newRV_noinc((SV *)m));
    (void)hv_stores(body, "errors", newRV_noinc((SV *)errs));
    bytes = punk_frj(aTHX)->encode(aTHX_ sv_2mortal(newRV_noinc((SV *)body)), NULL);
    return punk_triplet(aTHX_ 500, sv_2mortal(newSVpvs("application/json")),
                        bytes, NULL);
}

/* error -> handle_error; nonblocking Future -> Punk::App::_finish_future;
 * else coerce; then deliver (+1). ret/err are borrowed. */
static SV *punk_finish_c(pTHX_ SV *app, SV *c, SV *ret, SV *err, SV *on_error,
                         const char *method, STRLEN mlen, AV *after, HV *env) {
    int is_head = (mlen == 4 && memEQ(method, "HEAD", 4));
    SV *resp, *out;
    if (err && SvOK(err) && SvTRUE(err))
        resp = punk_handle_error(aTHX_ c, err, on_error);
    else if (SvROK(ret) && SvOBJECT(SvRV(ret)) && pcx_can(aTHX_ ret, "on_ready")) {
        dSP; SV *r; int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, 6);
        PUSHs(app);
        PUSHs(c);
        PUSHs(ret);
        PUSHs(on_error ? on_error : &PL_sv_undef);
        PUSHs(sv_2mortal(newSVpvn(method, mlen)));
        PUSHs(sv_2mortal(newRV_inc((SV *)(after ? after : newAV()))));
        PUTBACK;
        count = call_method("_finish_future", G_SCALAR);
        SPAGAIN;
        r = count > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
        PUTBACK; FREETMPS; LEAVE;
        return r;
    }
    else resp = punk_coerce(aTHX_ c, ret);
    out = punk_deliver(aTHX_ c, resp, is_head, after);
    SvREFCNT_dec(resp);
    return out;
}

/* A constant-body 404/405 triplet, with an optional Allow header (owned). */
static SV *ps_err_triplet(pTHX_ IV status, const char *b, STRLEN bl, SV *allow) {
    AV *resp = newAV(), *headers = newAV(), *bodyav = newAV();
    av_push(headers, newSVpvs("Content-Type"));
    av_push(headers, newSVpvs("application/json"));
    av_push(headers, newSVpvs("Content-Length"));
    av_push(headers, newSViv((IV)bl));
    if (allow) {
        av_push(headers, newSVpvs("Allow"));
        av_push(headers, allow);
    }
    av_push(bodyav, newSVpvn(b, bl));
    av_push(resp, newSViv(status));
    av_push(resp, newRV_noinc((SV *)headers));
    av_push(resp, newRV_noinc((SV *)bodyav));
    return newRV_noinc((SV *)resp);
}

/* does path (plen) start with prefix (pfl) on a segment boundary? */
static int ps_under(const char *path, STRLEN plen, const char *pf, STRLEN pfl) {
    return plen >= pfl && memEQ(path, pf, pfl)
        && (plen == pfl || path[pfl] == '/');
}

static SV *punk_serve(pTHX_ HV *state, HV *env) {
    SV *router = ps_state(aTHX_ state, "router");
    AV *recs   = ps_state_av(aTHX_ state, "recs");
    AV *apims  = ps_state_av(aTHX_ state, "api_mounts");
    AV *mounts = ps_state_av(aTHX_ state, "mounts");
    SV *ctxcls = ps_state(aTHX_ state, "ctx");
    SV *app    = ps_state(aTHX_ state, "app");
    AV *before = ps_state_av(aTHX_ state, "before");
    AV *after  = ps_state_av(aTHX_ state, "after");
    SV *on_err = ps_state(aTHX_ state, "on_error");
    pr_router *rt = (router && SvROK(router) && SvIOK(SvRV(router)))
                    ? (pr_router *)INT2PTR(void *, SvIV(SvRV(router))) : NULL;

    STRLEN mlen, plen;
    const char *method = ps_env_str(aTHX_ env, "REQUEST_METHOD", "GET", &mlen);
    const char *path   = ps_env_str(aTHX_ env, "PATH_INFO", "/", &plen);
    int is_head = (mlen == 4 && memEQ(method, "HEAD", 4));
    SV *rec = NULL, *caps = NULL;
    AV *api_allow = NULL;

    /* 1. static exact hit */
    if (rt) {
        IV i = pr_static_match(aTHX_ rt, method, mlen, path, plen);
        if (i >= 0) { SV **rp = av_fetch(recs, i, 0); if (rp && *rp) rec = *rp; }
    }

    if (!rec && apims) {                     /* 2. API mounts */
        const oa_abi *A = punk_oa(aTHX);
        SSize_t ai, an = av_len(apims) + 1;
        for (ai = 0; ai < an; ai++) {
            SV **mp = av_fetch(apims, ai, 0);
            HV *am; SV *api; SV **x;
            const char *pf, *rest; STRLEN pfl, restl;
            void *api_c, *op; HV *capsh; AV *allowv; SV *opid; HE *he; SV *oprec;
            IV maxb; SV *mon_err; HV *ops;
            if (!mp || !*mp || !SvROK(*mp)) continue;
            am = (HV *)SvRV(*mp);
            x = hv_fetchs(am, "prefix", 0);
            if (x && *x && SvOK(*x)) pf = SvPV_const(*x, pfl); else { pf = ""; pfl = 0; }
            if (!ps_under(path, plen, pf, pfl)) continue;
            rest = plen > pfl ? path + pfl : "/";
            restl = plen > pfl ? plen - pfl : 1;
            api = *hv_fetchs(am, "api", 0);
            api_c = A->api_of(aTHX_ api);
            capsh  = (HV *)sv_2mortal((SV *)newHV());
            allowv = (AV *)sv_2mortal((SV *)newAV());
            op = api_c ? A->route(aTHX_ api_c, method, mlen, rest, restl, capsh, allowv) : NULL;
            if (!op && is_head)
                op = api_c ? A->route(aTHX_ api_c, "GET", 3, rest, restl, capsh, allowv) : NULL;
            if (!op) {
                if (av_len(allowv) >= 0) {
                    SSize_t j, n = av_len(allowv) + 1;
                    if (!api_allow) api_allow = (AV *)sv_2mortal((SV *)newAV());
                    for (j = 0; j < n; j++) { SV **a = av_fetch(allowv, j, 0);
                        if (a && *a) av_push(api_allow, newSVsv(*a)); }
                }
                continue;
            }
            opid = A->op_id(aTHX_ op);
            x = hv_fetchs(am, "ops", 0);
            ops = (x && *x && SvROK(*x)) ? (HV *)SvRV(*x) : NULL;
            he = ops ? hv_fetch_ent(ops, opid, 0, 0) : NULL;
            oprec = he ? HeVAL(he) : NULL;
            x = hv_fetchs(am, "max_body", 0);
            maxb = (x && *x && SvOK(*x)) ? SvIV(*x) : 0;
            x = hv_fetchs(am, "on_error", 0);
            mon_err = (x && *x && SvOK(*x)) ? *x : on_err;
            {
                HV *match = newHV();
                SV *c, *ret = &PL_sv_undef, *err = &PL_sv_undef, *out;
                (void)hv_stores(match, "captures", newRV_inc((SV *)capsh));
                (void)hv_stores(match, "operation", newSVsv(opid));
                c = sv_2mortal(ps_ctx(aTHX_ ctxcls, env, app, newRV_noinc((SV *)match)));
                if (oprec && SvROK(oprec) && SvTYPE(SvRV(oprec)) == SVt_PVHV)
                    punk_oa_dispatch(aTHX_ c, before, (HV *)SvRV(oprec), api, opid,
                        sv_2mortal(newRV_inc((SV *)capsh)), maxb, &ret, &err);
                out = punk_finish_c(aTHX_ app, c, ret, err, mon_err, method, mlen, after, env);
                if (ret != &PL_sv_undef) SvREFCNT_dec(ret);
                if (err != &PL_sv_undef) SvREFCNT_dec(err);
                return out;
            }
        }
    }

    if (!rec && mounts) {                    /* 3. PSGI / static mounts */
        SSize_t mi, mn = av_len(mounts) + 1;
        for (mi = 0; mi < mn; mi++) {
            SV **mp = av_fetch(mounts, mi, 0);
            HV *m; SV **x; const char *pf; STRLEN pfl; SV *mapp;
            if (!mp || !*mp || !SvROK(*mp)) continue;
            m = (HV *)SvRV(*mp);
            x = hv_fetchs(m, "prefix", 0);
            if (x && *x && SvOK(*x)) pf = SvPV_const(*x, pfl); else { pf = ""; pfl = 0; }
            if (!ps_under(path, plen, pf, pfl)) continue;
            mapp = *hv_fetchs(m, "app", 0);
            {
                SV *save_sn, *save_pi, *newsn, *newpi, *r;
                SV **sn = hv_fetchs(env, "SCRIPT_NAME", 0);
                SV **pi = hv_fetchs(env, "PATH_INFO", 0);
                dSP; int count;
                save_sn = (sn && *sn) ? newSVsv(*sn) : NULL;
                save_pi = (pi && *pi) ? newSVsv(*pi) : NULL;
                newsn = save_sn ? newSVsv(save_sn) : newSVpvs("");
                sv_catpvn(newsn, pf, pfl);
                (void)hv_stores(env, "SCRIPT_NAME", newsn);
                newpi = plen > pfl ? newSVpvn(path + pfl, plen - pfl) : newSVpvs("/");
                (void)hv_stores(env, "PATH_INFO", newpi);
                ENTER; SAVETMPS;
                PUSHMARK(SP); EXTEND(SP, 1);
                PUSHs(sv_2mortal(newRV_inc((SV *)env)));
                PUTBACK;
                count = call_sv(mapp, G_SCALAR);
                SPAGAIN;
                r = count > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
                PUTBACK; FREETMPS; LEAVE;
                (void)hv_stores(env, "SCRIPT_NAME", save_sn ? save_sn : newSV(0));
                (void)hv_stores(env, "PATH_INFO",   save_pi ? save_pi : newSV(0));
                return r;
            }
        }
    }

    if (!rec && rt) {                        /* 4. dynamic hit, else allow */
        HV *capsh = (HV *)sv_2mortal((SV *)newHV());
        IV idx = pr_match(aTHX_ rt, method, mlen, path, plen, capsh);
        if (idx >= 0) {
            SV **rp = av_fetch(recs, idx, 0);
            if (rp && *rp) rec = *rp;
            caps = sv_2mortal(newRV_inc((SV *)capsh));
        }
        else {
            AV *allowv = (AV *)sv_2mortal((SV *)newAV());
            if (pr_allow(aTHX_ rt, method, mlen, path, plen, allowv))
                caps = sv_2mortal(newRV_inc((SV *)allowv));
        }
    }

    if (!rec) {                              /* 405 (merge allow) or 404 */
        HV *seen = (HV *)sv_2mortal((SV *)newHV());
        AV *lists[2];
        int li;
        lists[0] = (caps && SvROK(caps) && SvTYPE(SvRV(caps)) == SVt_PVAV)
                   ? (AV *)SvRV(caps) : NULL;
        lists[1] = api_allow;
        for (li = 0; li < 2; li++) {
            AV *l = lists[li]; SSize_t j, n;
            if (!l) continue;
            n = av_len(l) + 1;
            for (j = 0; j < n; j++) { SV **a = av_fetch(l, j, 0);
                if (a && *a) (void)hv_store_ent(seen, *a, &PL_sv_yes, 0); }
        }
        (void)hv_delete(seen, method, (I32)mlen, 0);
        if (HvUSEDKEYS(seen)) {
            AV *sorted = (AV *)sv_2mortal((SV *)newAV());
            SV *joined; HE *he; SSize_t na = 0, k;
            hv_iterinit(seen);
            while ((he = hv_iternext(seen))) { av_push(sorted, newSVsv(hv_iterkeysv(he))); na++; }
            if (na > 1) sortsv(AvARRAY(sorted), (STRLEN)na, Perl_sv_cmp);
            joined = newSVpvs("");
            for (k = 0; k < na; k++) { SV **a = av_fetch(sorted, k, 0);
                if (k) sv_catpvs(joined, ", "); if (a && *a) sv_catsv(joined, *a); }
            return ps_err_triplet(aTHX_ 405, PS_ERR_405, sizeof(PS_ERR_405) - 1, joined);
        }
        return ps_err_triplet(aTHX_ 404, PS_ERR_404, sizeof(PS_ERR_404) - 1, NULL);
    }

    /* 5. web route: ctx, before + guards, controller/ws, finish */
    {
        HV *rech = (HV *)SvRV(rec);
        HV *match = newHV();
        SV *c, *ret = &PL_sv_undef, *err = &PL_sv_undef, *out;
        SV **guardsp, **codep, **wsp, **ssep;
        int shorted;
        if (caps && SvROK(caps) && SvTYPE(SvRV(caps)) == SVt_PVHV)
            (void)hv_stores(match, "captures", newRV_inc(SvRV(caps)));
        else
            (void)hv_stores(match, "captures", newRV_noinc((SV *)newHV()));
        c = sv_2mortal(ps_ctx(aTHX_ ctxcls, env, app, newRV_noinc((SV *)match)));

        shorted = pd_run_chain(aTHX_ before, c, &ret, &err);
        if (!shorted) {
            guardsp = hv_fetchs(rech, "guards", 0);
            if (guardsp && *guardsp && SvROK(*guardsp)
                && SvTYPE(SvRV(*guardsp)) == SVt_PVAV)
                shorted = pd_run_chain(aTHX_ (AV *)SvRV(*guardsp), c, &ret, &err);
        }
        if (!shorted) {
            int died = 0;
            wsp   = hv_fetchs(rech, "ws", 0);
            ssep  = hv_fetchs(rech, "sse", 0);
            codep = hv_fetchs(rech, "code", 0);
            if ((wsp && *wsp && SvTRUE(*wsp)) || (ssep && *ssep && SvTRUE(*ssep))) {
                const char *disp = (wsp && *wsp && SvTRUE(*wsp))
                    ? "Punk::WebSocket::_dispatch" : "Punk::SSE::_dispatch";
                dSP; int count;
                ENTER; SAVETMPS;
                PUSHMARK(SP); EXTEND(SP, 3);
                PUSHs(c); PUSHs(rec);
                PUSHs(sv_2mortal(newRV_inc((SV *)env)));
                PUTBACK;
                count = call_pv(disp, G_SCALAR | G_EVAL);
                SPAGAIN;
                ret = count > 0 ? SvREFCNT_inc(POPs) : &PL_sv_undef;
                PUTBACK; FREETMPS; LEAVE;
                died = SvTRUE(ERRSV) ? 1 : 0;
            }
            else {
                ret = pd_call(aTHX_ (codep && *codep) ? *codep : &PL_sv_undef, c, &died);
            }
            if (died) err = newSVsv(ERRSV);
        }
        out = punk_finish_c(aTHX_ app, c, ret, err, on_err, method, mlen, after, env);
        if (ret != &PL_sv_undef) SvREFCNT_dec(ret);
        if (err != &PL_sv_undef) SvREFCNT_dec(err);
        return out;
    }
}

#endif /* PUNK_SERVE_H */

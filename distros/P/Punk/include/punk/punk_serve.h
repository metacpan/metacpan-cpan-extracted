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

/* The request context, built once.
 *
 * When a before_request hook has already made one, the routed match is stored
 * into its PCX_MATCH slot rather than a second context being built: a stash
 * written before routing has to survive into the handler, and it does not if
 * the handler is handed a different object. match is owned; *cp is the
 * caller's context slot, NULL until there is one.
 *
 * Do NOT decrement the match being replaced. av_store already frees the
 * element it overwrites, so a dec here is a double free - one that surfaces
 * later in the request as unrelated corruption. The only manual dec is for
 * the store that did not take. */
static SV *ps_ctx_for(pTHX_ SV **cp, SV *ctx_class, HV *env, SV *app,
                      SV *match) {
    if (*cp) {
        AV *av = (AV *)SvRV(*cp);
        if (!av_store(av, PCX_MATCH, match)) SvREFCNT_dec(match);
        return *cp;
    }
    *cp = sv_2mortal(ps_ctx(aTHX_ ctx_class, env, app, match));
    return *cp;
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

/* The conditional-GET check, run between a route's guards and its handler.
 * Defined in punk_cget.h, which is included after punk_sendfile.h because it
 * uses that file's If-None-Match comparison rather than a second copy of it -
 * the same split ps_serve_file uses. */
static int pcg_check(pTHX_ SV *c, HV *rech, HV *env, const char *method,
                     STRLEN mlen, SV **out, SV **errp);

/* The idempotency replay check, in the same slot. Defined in punk_idem.h,
 * which is included after punk_cachefront.h because the store is where the
 * keys live. */
static int pi_check(pTHX_ SV *c, HV *rech, HV *env, const char *method,
                    STRLEN mlen, SV *cfg, SV **out, SV **errp);

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
    {   /* Where a large multipart part spills. The parser has the request's
         * env and nothing else - the env belongs to the server - so the one
         * place this can be handed over is here, and only when an
         * application named a directory. One hv_store for those that did,
         * one hv_fetch for those that did not. */
        SV *ud = ps_state(aTHX_ state, "upload_dir");
        if (ud && SvOK(ud)) (void)hv_stores(env, "punk.upload_dir", newSVsv(ud));
    }
    AV *before = ps_state_av(aTHX_ state, "before");
    AV *after  = ps_state_av(aTHX_ state, "after");
    SV *on_err = ps_state(aTHX_ state, "on_error");
    pr_router *rt = (router && SvROK(router) && SvIOK(SvRV(router)))
                    ? (pr_router *)INT2PTR(void *, SvIV(SvRV(router))) : NULL;

    STRLEN mlen, plen;
    const char *method;

    {   /* Reverse-proxy trust, before anything reads the env: REMOTE_ADDR is
         * rewritten to the real client so rate_limit, block_ip, the access
         * log and $c->req all see it without any of them being changed.
         * Absent a `proxy` policy this is one predictable branch. */
        SV *px = ps_state(aTHX_ state, K_PROXY);
        if (px && SvROK(px) && SvIOK(SvRV(px)))
            pp_resolve(aTHX_ (const pp_policy *)INT2PTR(void *,
                                                        SvIV(SvRV(px))), env);
    }

    method = ps_env_str(aTHX_ env, "REQUEST_METHOD", "GET", &mlen);
    const char *path   = ps_env_str(aTHX_ env, "PATH_INFO", "/", &plen);
    int is_head = (mlen == 4 && memEQ(method, "HEAD", 4));
    SV *rec = NULL, *caps = NULL;
    AV *api_allow = NULL;
    SV *c = NULL;                            /* the one context, once built */

    {   /* before_request: the only phase that runs before routing, so the
         * only one a 404, a 405 or a mount ever reaches. It runs here -
         * after the proxy resolve, because a hook that logs or samples by
         * client address must see the corrected REMOTE_ADDR the same way
         * rate_limit and the access log do, and after the method/path reads,
         * because a short-circuit needs them and they allocate nothing.
         *
         * Being first is also what it costs: this is ahead of the csrf
         * check, ahead of rate_limit and ahead of the max_body ceiling, so
         * the hook sees requests all three will refuse. For a span that is
         * the point; for work done on the client's behalf, before_dispatch
         * is still the right phase.
         *
         * compile omits the state key when the chain is empty, so an app
         * with no such hook pays one hv_fetch and one branch. */
        AV *before_req = ps_state_av(aTHX_ state, K_BEFORE_REQ);
        int has_hooks = (before_req && av_len(before_req) >= 0);

        /* The C ABI's observers register process-globally and run here, ahead
         * of any Perl phase - a consumer measuring a request should start
         * before the first frame this framework hands to an application.
         * Registering either observer is what makes the context get built,
         * which is the guarantee that the response side sees the same one. */
        if (PK_OBS_ANY || has_hooks) {
            HV *match = newHV();
            /* a real hashref with empty captures, not undef, so $c->match and
             * $c->param behave inside the hook instead of croaking */
            (void)hv_stores(match, "captures", newRV_noinc((SV *)newHV()));
            (void)ps_ctx_for(aTHX_ &c, ctxcls, env, app,
                             newRV_noinc((SV *)match));
        }
        if (PK_OBS_WANT_REQ) pk_obs_fire_req(aTHX_ c);

        if (has_hooks) {
            SV *ret = &PL_sv_undef, *err = &PL_sv_undef;
            if (pd_run_chain(aTHX_ before_req, c, &ret, &err)) {
                SV *out = punk_finish_c(aTHX_ app, c, ret, err, on_err,
                                        method, mlen, after, env);
                if (ret != &PL_sv_undef) SvREFCNT_dec(ret);
                if (err != &PL_sv_undef) SvREFCNT_dec(err);
                return out;
            }
        }
    }

    /* 1. static exact hit */
    if (rt) {
        IV i = pr_static_match(aTHX_ rt, method, mlen, path, plen);
        if (i >= 0) { SV **rp = av_fetch(recs, i, 0); if (rp && *rp) rec = *rp; }
    }

    /* 2. API mounts.
     *
     * The COUNT is checked, not just the array: api_mounts is always present
     * in the compiled state, so an app that declared no `api` at all still
     * arrives here with an empty one - and punk_oa croaks when Open::API's
     * ABI does not match. That made Open::API an effective hard requirement
     * of the dynamic-route path for every app in the world, and the failure
     * it produced named the API path, which the app was not using. */
    if (!rec && apims && av_len(apims) >= 0) {
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
                SV *ret = &PL_sv_undef, *err = &PL_sv_undef, *out;
                (void)hv_stores(match, "captures", newRV_inc((SV *)capsh));
                (void)hv_stores(match, "operation", newSVsv(opid));
                (void)ps_ctx_for(aTHX_ &c, ctxcls, env, app,
                                 newRV_noinc((SV *)match));
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
                /* a mounted app owns its answer and never comes through
                 * punk_deliver, so the observers are fired here */
                if (PK_OBS_WANT_RES) pk_obs_fire_res(aTHX_ c, r);
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

    /* 5. trailing-slash rescue: "/account/" answers the route declared as
     *    "/account". It runs only once everything above has missed, so a
     *    route, API operation or mount that really does want the slash still
     *    wins on its own terms first. Mounts are deliberately not retried:
     *    a mounted app is entitled to tell "/docs" from "/docs/", and is the
     *    one that should decide. */
    if (!rec && rt && plen > 1 && path[plen - 1] == '/') {
        STRLEN tl = plen;
        IV i;
        while (tl > 1 && path[tl - 1] == '/') tl--;
        i = pr_static_match(aTHX_ rt, method, mlen, path, tl);
        if (i >= 0) {
            SV **rp = av_fetch(recs, i, 0);
            if (rp && *rp) { rec = *rp; caps = NULL; }
        }
        if (!rec) {
            HV *capsh = (HV *)sv_2mortal((SV *)newHV());
            IV idx = pr_match(aTHX_ rt, method, mlen, path, tl, capsh);
            if (idx >= 0) {
                SV **rp = av_fetch(recs, idx, 0);
                if (rp && *rp) { rec = *rp; caps = sv_2mortal(newRV_inc((SV *)capsh)); }
            }
            else if (!caps) {                /* keep the untrimmed Allow if any */
                AV *allowv = (AV *)sv_2mortal((SV *)newAV());
                if (pr_allow(aTHX_ rt, method, mlen, path, tl, allowv))
                    caps = sv_2mortal(newRV_inc((SV *)allowv));
            }
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
                if (a && *a) (void)hv_store_ent(seen, *a, PUNK_SET_TRUE, 0); }
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
            {   /* the house 405 runs no after-hooks and so never reaches
                 * punk_deliver; the observers still get their one event */
                SV *out = ps_err_triplet(aTHX_ 405, PS_ERR_405,
                                         sizeof(PS_ERR_405) - 1, joined);
                if (PK_OBS_WANT_RES) pk_obs_fire_res(aTHX_ c, out);
                return out;
            }
        }
        {   /* on_not_found: the app's own 404, the on_error contract - a
             * reference return becomes the response (after hooks run, a
             * Future is awaited), anything else keeps the default below,
             * and a die inside it goes through on_error. The 405 above is
             * deliberately not covered: its Allow semantics stay. */
            SV *on_nf = ps_state(aTHX_ state, K_ON_NOT_FOUND);
            if (on_nf && SvOK(on_nf)) {
                HV *match = newHV();
                SV *r = NULL;
                int died;
                (void)hv_stores(match, "captures", newRV_noinc((SV *)newHV()));
                (void)ps_ctx_for(aTHX_ &c, ctxcls, env, app,
                                 newRV_noinc((SV *)match));
                {
                    dSP; int count;
                    ENTER; SAVETMPS;
                    PUSHMARK(SP); EXTEND(SP, 1);
                    PUSHs(c);
                    PUTBACK;
                    count = call_sv(on_nf, G_SCALAR | G_EVAL);
                    SPAGAIN;
                    if (count > 0) { SV *t = POPs; r = SvREFCNT_inc(t); }
                    PUTBACK; FREETMPS; LEAVE;
                    died = SvTRUE(ERRSV) ? 1 : 0;
                }
                if (died) {
                    SV *errsv = sv_2mortal(newSVsv(ERRSV));
                    SV *out = punk_finish_c(aTHX_ app, c, &PL_sv_undef, errsv,
                                            on_err, method, mlen, after, env);
                    if (r) SvREFCNT_dec(r);
                    return out;
                }
                if (r && SvROK(r)) {
                    SV *out = punk_finish_c(aTHX_ app, c, r, &PL_sv_undef,
                                            on_err, method, mlen, after, env);
                    SvREFCNT_dec(r);
                    return out;
                }
                if (r) SvREFCNT_dec(r);   /* declined: the default stands */
            }
        }
        {   /* likewise the house 404 (on_not_found returning a response goes
             * through punk_finish_c and is covered there instead) */
            SV *out = ps_err_triplet(aTHX_ 404, PS_ERR_404,
                                     sizeof(PS_ERR_404) - 1, NULL);
            if (PK_OBS_WANT_RES) pk_obs_fire_res(aTHX_ c, out);
            return out;
        }
    }

    /* 5. web route: ctx, before + guards, controller/ws, finish */
    {
        HV *rech = (HV *)SvRV(rec);
        HV *match = newHV();
        SV *ret = &PL_sv_undef, *err = &PL_sv_undef, *out;
        SV **guardsp, **codep, **wsp, **ssep;
        int shorted;
        if (caps && SvROK(caps) && SvTYPE(SvRV(caps)) == SVt_PVHV)
            (void)hv_stores(match, "captures", newRV_inc(SvRV(caps)));
        else
            (void)hv_stores(match, "captures", newRV_noinc((SV *)newHV()));
        /* the matched route record, which Punk::Context has always documented
         * $c->match as carrying and which nothing actually put there. It is
         * what names the route as DECLARED - "/users/:id" - for anything
         * grouping by route rather than by path, the C ABI included. */
        (void)hv_stores(match, "route", newSVsv(rec));
        (void)ps_ctx_for(aTHX_ &c, ctxcls, env, app, newRV_noinc((SV *)match));

        {   /* The body ceiling, before the hook chain and before the guards:
             * an oversize request should cost no auth lookup, no validation,
             * no body parse and no Perl frame. A route's own value wins over
             * the app-wide one, and 0 on a route disables the check there. */
            SV **rmb = hv_fetchs(rech, K_MAX_BODY, 0);
            SV  *amb = ps_state(aTHX_ state, K_MAX_BODY);
            IV   lim = (rmb && *rmb && SvOK(*rmb)) ? SvIV(*rmb)
                     : (amb && SvOK(amb))          ? SvIV(amb)
                     : 0;
            if (lim > 0) {
                SV *over = pd_body_limit(aTHX_ env, lim);
                if (over) {   /* the 413 refuses before the hook chain, so it
                               * too skips punk_deliver */
                    if (PK_OBS_WANT_RES) pk_obs_fire_res(aTHX_ c, over);
                    return over;
                }
            }
        }

        shorted = pd_run_chain(aTHX_ before, c, &ret, &err);
        if (!shorted) {
            guardsp = hv_fetchs(rech, "guards", 0);
            if (guardsp && *guardsp && SvROK(*guardsp)
                && SvTYPE(SvRV(*guardsp)) == SVt_PVAV)
                shorted = pd_run_chain(aTHX_ (AV *)SvRV(*guardsp), c, &ret, &err);
        }
        if (!shorted) {
            /* The conditional GET, after the guards and before the handler.
             * Not earlier: before_dispatch runs ahead of the guards, and a
             * 304 there would answer a request an authentication guard was
             * about to refuse. Inert unless the plugin is registered, and
             * one hv_fetch when it is not - the `sitemap` arrangement. */
            SV *cg = ps_state(aTHX_ state, K_CGET);
            if (cg && SvTRUE(cg)) {
                SV *cgout = NULL, *cgerr = NULL;
                if (pcg_check(aTHX_ c, rech, env, method, mlen,
                              &cgout, &cgerr)) {
                    if (cgerr) err = cgerr;      /* the app's 500 */
                    else       ret = cgout;      /* the 304 */
                    shorted = 1;
                }
            }
        }
        if (!shorted) {
            /* Idempotency, in the same slot and for the same reason: a
             * replay returns a stored response BODY, so answering it ahead
             * of the guards would hand somebody else's order to a caller
             * the guard was about to refuse. The two never both fire - one
             * answers GET and HEAD, the other only unsafe methods. */
            SV *ic = ps_state(aTHX_ state, K_IDEM);
            SV **ir = ic ? hv_fetchs(rech, K_IDEMPOTENT, 0) : NULL;
            if (ir && *ir && SvTRUE(*ir)) {
                SV *iout = NULL, *ierr = NULL;
                if (pi_check(aTHX_ c, rech, env, method, mlen, ic,
                             &iout, &ierr)) {
                    if (ierr) err = ierr;
                    else      ret = iout;        /* the replay, 400 or 422 */
                    shorted = 1;
                }
            }
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
        {   /* compress => 0: say so in the one place the server will look.
             * `identity` is the documented hands-off spelling (Hyperman
             * strips it before writing); a response that already declares
             * an encoding has said something more specific and is left. */
            SV **nc = hv_fetchs(rech, K_COMPRESS, 0);
            if (nc && *nc && !SvTRUE(*nc)
                && out && SvROK(out) && SvTYPE(SvRV(out)) == SVt_PVAV) {
                AV *ra = (AV *)SvRV(out);
                SV **hp = av_fetch(ra, 1, 0);
                if (hp && *hp && SvROK(*hp) && SvTYPE(SvRV(*hp)) == SVt_PVAV) {
                    AV *hdrs = (AV *)SvRV(*hp);
                    SSize_t j, hn = av_len(hdrs) + 1;
                    int seen = 0;
                    for (j = 0; j + 1 < hn; j += 2) {
                        SV **k = av_fetch(hdrs, j, 0);
                        STRLEN kl;
                        const char *ks;
                        if (!(k && *k)) continue;
                        ks = SvPV_const(*k, kl);
                        if (kl == 16 && foldEQ(ks, "Content-Encoding", 16))
                            { seen = 1; break; }
                    }
                    if (!seen) {
                        av_push(hdrs, newSVpvs("Content-Encoding"));
                        av_push(hdrs, newSVpvs("identity"));
                    }
                }
            }
        }
        if (ret != &PL_sv_undef) SvREFCNT_dec(ret);
        if (err != &PL_sv_undef) SvREFCNT_dec(err);
        return out;
    }
}

#endif /* PUNK_SERVE_H */

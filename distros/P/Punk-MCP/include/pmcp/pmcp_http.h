/* pmcp_http.h - Streamable HTTP, the JSON half: one POST in, one answer out.
 *
 * Needs: pmcp_proto.h, pmcp_reg.h.
 *
 * The checks run in Maat's order (Maat/include/mt_mcp.h:826), cheapest and
 * least trusting first: Origin, Accept, Content-Type, the protocol version
 * header, the guards, the body size, and only then the JSON. A refusal before
 * the dispatcher is still a JSON-RPC error with a null id, so a client shows
 * why rather than a bare status.
 *
 * GET and DELETE need nothing here: Punk answers a method the path does not
 * serve with 405 and an Allow header from the router. Sessions (09) and the
 * GET stream (10) add those routes.
 */

#ifndef PMCP_HTTP_H
#define PMCP_HTTP_H

/* Defined in pmcp_sse.h, which needs this header's env reader. */
static int pmcp_should_stream(pTHX_ pmcp_server *ps, HV *env, pmcp_msg *m);
static SV *pmcp_stream_answer(pTHX_ SV *c, SV *server, SV *doc, enum pmcp_ver v,
                              int cors, SV *sid, int level);

/* What sessions (pmcp_sess.h) carry from before the dispatch to after it. */
typedef struct {
    SV *store;          /* mortal, or NULL with sessions off */
    SV *sid;            /* the request's session, mortal, or NULL */
    HV *rec;            /* its record, mortal */
    int creating;       /* an initialize that will make one if it succeeds */
    int in_session;     /* a second initialize carrying a live session id */
    int level;          /* the session's log level, or -1 */
    enum pmcp_ver v;    /* the session's version */
} pmcp_sess_t;
static SV *pmcp_sess_begin(pTHX_ SV *c, pmcp_server *ps, HV *env, pmcp_msg *m,
                           pmcp_sess_t *s, int cors);
static SV *pmcp_sess_end(pTHX_ pmcp_server *ps, HV *env, pmcp_sess_t *s,
                         pmcp_req *r, pmcp_msg *m);
static void pmcp_level_set(pTHX_ SV *c, pmcp_server *ps, SV *sid, int level);
XS_INTERNAL(pmcp_delete_cb);
static void pmcp_sess_boot_check(pTHX_ SV *app, HV *opts);
static int pmcp_sessions_on(pTHX_ HV *opts);
static void pmcp_bus_install(pTHX_ SV *app, SV *server, SV *guards);
static SV *pmcp_auth_guards(pTHX_ SV *app, HV *opts);
static void pmcp_prm_install(pTHX_ SV *app, HV *opts);
static void pmcp_expose_refusal(pTHX_ SV *out, int cors);
static void pmcp_principal_run(pTHX_ SV *c, SV *principal);

/* What a browser may read off an answer. The plugin sets it itself, so a
 * browser client works without the application listing these in `cors`:
 * Punk's CORS layer leaves a handler's own value alone. */
#define PMCP_EXPOSE "Mcp-Session-Id, MCP-Protocol-Version, WWW-Authenticate"

/* One header of a PSGI env, borrowed, or NULL. */
static SV *pmcp_env_get(pTHX_ HV *env, const char *k)
{
    SV **e = hv_fetch(env, k, (I32)strlen(k), 0);
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

/* [status, [headers], [body]] +1. `body` (+1) may be NULL for none. */
static SV *pmcp_http_answer(pTHX_ int status, SV *body, int cors)
{
    AV *t = newAV(), *h = newAV(), *b = newAV();
    if (body) {
        av_push(h, newSVpvs("Content-Type"));
        av_push(h, newSVpvs("application/json"));
    }
    av_push(h, newSVpvs("Cache-Control"));
    av_push(h, newSVpvs("no-store"));
    if (cors) {
        av_push(h, newSVpvs("Access-Control-Expose-Headers"));
        av_push(h, newSVpvs(PMCP_EXPOSE));
    }
    if (body) av_push(b, body);
    av_push(t, newSViv(status));
    av_push(t, newRV_noinc((SV *)h));
    av_push(t, newRV_noinc((SV *)b));
    return newRV_noinc((SV *)t);
}

/* A refusal before the dispatcher: the status, with a JSON-RPC error saying
 * why. */
static SV *pmcp_http_refuse(pTHX_ int status, const char *why, int cors)
{
    return pmcp_http_answer(aTHX_ status,
        pmcp_rpc_error(aTHX_ NULL, PMCP_REQUEST, why, NULL), cors);
}

/* ---- Origin ------------------------------------------------------------------ */

/* scheme://host[:port], lowercased, with the scheme's default port dropped,
 * into a mortal SV, so https://A.test:443 and https://a.test compare equal. */
static SV *pmcp_origin_norm(pTHX_ const char *p, STRLEN l)
{
    SV *o = sv_2mortal(newSVpvn(p, l));
    char *s = SvPVX(o);
    STRLEN i, n = SvCUR(o);
    for (i = 0; i < n; i++) s[i] = toLOWER(s[i]);
    while (n && s[n - 1] == '/') n--;
    if (n > 12 && memEQ(s, "https://", 8) && memEQ(s + n - 4, ":443", 4)) n -= 4;
    else if (n > 11 && memEQ(s, "http://", 7) && memEQ(s + n - 3, ":80", 3)) n -= 3;
    SvCUR_set(o, n);
    return o;
}

/* Is the request's Origin acceptable? No Origin is (a non-browser client).
 * With `origins`, it must be listed. Without, it must be the server's own,
 * which is the request's scheme and Host. `Origin: null` never matches. */
static int pmcp_origin_ok(pTHX_ HV *env, HV *opts)
{
    SV *o = pmcp_env_get(aTHX_ env, "HTTP_ORIGIN");
    SV *list = pmcp_hget(aTHX_ opts, "origins");
    SV *have;
    STRLEN l;
    const char *p;

    if (!o) return 1;
    p = SvPV_const(o, l);
    have = pmcp_origin_norm(aTHX_ p, l);
    if (list) {
        AV *av = (AV *)SvRV(list);
        SSize_t i, n = av_len(av) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            STRLEN el;
            const char *ep = SvPV_const(*e, el);
            if (sv_eq(have, pmcp_origin_norm(aTHX_ ep, el))) return 1;
        }
        return 0;
    }
    {
        SV *scheme = pmcp_env_get(aTHX_ env, "psgi.url_scheme");
        SV *host = pmcp_env_get(aTHX_ env, "HTTP_HOST");
        SV *own;
        if (!host) return 0;
        own = sv_2mortal(newSVpvf("%s://%" SVf, scheme ? SvPV_nolen(scheme) : "http",
                                  SVfARG(host)));
        p = SvPV_const(own, l);
        return sv_eq(have, pmcp_origin_norm(aTHX_ p, l));
    }
}

/* ---- media types -------------------------------------------------------------- */

/* Does an Accept header allow `type` (application/json, text/event-stream)?
 * No header allows everything, as HTTP has it. */
static int pmcp_accepts(pTHX_ HV *env, const char *type)
{
    SV *a = pmcp_env_get(aTHX_ env, "HTTP_ACCEPT");
    const char *p, *e, *slash = strchr(type, '/');
    STRLEN l, tl = strlen(type), major = (STRLEN)(slash - type);
    if (!a) return 1;
    p = SvPV_const(a, l);
    e = p + l;
    while (p < e) {
        const char *s = p, *end;
        STRLEN n;
        while (p < e && *p != ',') p++;
        end = p;
        if (p < e) p++;
        while (s < end && isSPACE(*s)) s++;
        {
            const char *semi = s;
            while (semi < end && *semi != ';') semi++;
            end = semi;
        }
        while (end > s && isSPACE(end[-1])) end--;
        n = (STRLEN)(end - s);
        if ((n == 3 && memEQ(s, "*/*", 3))
            || (n == tl && foldEQ(s, type, (I32)tl))
            || (n == major + 2 && foldEQ(s, type, (I32)major) && memEQ(s + major, "/*", 2)))
            return 1;
    }
    return 0;
}

static int pmcp_content_type_ok(pTHX_ HV *env)
{
    SV *ct = pmcp_env_get(aTHX_ env, "CONTENT_TYPE");
    STRLEN l, n = 0;
    const char *p;
    if (!ct) return 0;
    p = SvPV_const(ct, l);
    while (n < l && p[n] != ';' && !isSPACE(p[n])) n++;
    return n == 16 && foldEQ(p, "application/json", 16);
}

/* ---- the handler ------------------------------------------------------------------ */

/* POST on the MCP path. cap = [server object, guards AV ref (the hook 11 fills)]. */
XS_INTERNAL(pmcp_http_cb)
{
    dXSARGS;
    SV *c = items > 0 ? ST(0) : &PL_sv_undef;
    pmcp_server *ps = pmcp_server_of(aTHX_ pmcp_cap(aTHX_ cv, 0));
    SV *gslot = pmcp_cap(aTHX_ cv, 1);
    AV *guards = (gslot && pmcp_is_array(gslot)) ? (AV *)SvRV(gslot) : NULL;
    SV *envsv, *out = NULL;
    HV *env, *opts;
    int cors;
    enum pmcp_ver v = PMCP_V_2025_03_26;

    if (!ps) croak("%s: the MCP route lost its server", PMCP_WHO);
    opts = ps->opts;
    envsv = sv_2mortal(pmcp_call_method(aTHX_ c, "env", NULL, 0, G_SCALAR, NULL));
    env = (HV *)SvRV(envsv);
    cors = pmcp_env_get(aTHX_ env, "HTTP_ORIGIN") != NULL;

    /* 1. Origin: a page on another site driving a local server is the attack */
    if (!pmcp_origin_ok(aTHX_ env, opts)) {
        out = pmcp_http_refuse(aTHX_ 403, "origin not allowed", cors);
        goto answer;
    }
    /* 2. Accept */
    if (!pmcp_accepts(aTHX_ env, "application/json")) {
        out = pmcp_http_refuse(aTHX_ 406, "Accept must allow application/json", cors);
        goto answer;
    }
    /* 3. Content-Type */
    if (!pmcp_content_type_ok(aTHX_ env)) {
        out = pmcp_http_refuse(aTHX_ 415, "Content-Type must be application/json", cors);
        goto answer;
    }
    /* 4. the protocol version: absent is read as 2025-03-26, as the spec says */
    {
        SV *pv = pmcp_env_get(aTHX_ env, "HTTP_MCP_PROTOCOL_VERSION");
        if (pv) {
            STRLEN l;
            const char *p = SvPV_const(pv, l);
            v = pmcp_version_of(p, l);
            if (v == PMCP_V_NONE) {
                out = pmcp_http_refuse(aTHX_ 400, "unsupported MCP-Protocol-Version", cors);
                goto answer;
            }
        }
    }
    /* 5. the guards, before any JSON is read. A refusal goes out as the guard
     * made it, since a 401 carries the challenge a client acts on. */
    if (guards) {
        SSize_t i, n = av_len(guards) + 1;
        for (i = 0; i < n; i++) {
            SV *err = NULL;
            SV *r = pmcp_call_sv(aTHX_ *av_fetch(guards, i, 0), &c, 1, G_SCALAR, &err);
            if (!r) pmcp_croak_sv(aTHX_ sv_2mortal(err));
            if (SvROK(r)) { out = r; pmcp_expose_refusal(aTHX_ out, cors); goto answer; }
            SvREFCNT_dec(r);
        }
    }
    /* principal, now the request is let in: what it returns is $c->mcp_user */
    {
        SV *p = pmcp_cap(aTHX_ cv, 2);
        if (p && pmcp_is_code(p)) pmcp_principal_run(aTHX_ c, p);
    }
    /* 6. the body: refused on its declared length before it is read, and on
     * what arrived when there was no length */
    {
        SV *cl = pmcp_env_get(aTHX_ env, "CONTENT_LENGTH");
        SV *maxsv = pmcp_hget(aTHX_ opts, "max_body");
        IV max = maxsv ? SvIV(maxsv) : 1048576;
        SV *req, *body;
        if (cl && SvIV(cl) > max) {
            out = pmcp_http_refuse(aTHX_ 413, "the body is too large", cors);
            goto answer;
        }
        req = sv_2mortal(pmcp_call_method(aTHX_ c, "req", NULL, 0, G_SCALAR, NULL));
        body = sv_2mortal(pmcp_call_method(aTHX_ req, "body", NULL, 0, G_SCALAR, NULL));
        if (SvOK(body) && (IV)SvCUR(body) > max) {
            out = pmcp_http_refuse(aTHX_ 413, "the body is too large", cors);
            goto answer;
        }
        /* 7. the protocol. Decoded once here, because whether to answer with
         * an event stream is decided before anything runs (08). */
        {
            pmcp_req r;
            int status = 0;
            SV *reply;
            SV *doc = pmcp_rpc_decode(aTHX_ SvOK(body) ? body : sv_2mortal(newSVpvs("")));
            if (!doc) {
                out = pmcp_http_answer(aTHX_ 400,
                    pmcp_rpc_error(aTHX_ NULL, PMCP_PARSE, "parse error", NULL), cors);
                goto answer;
            }
            sv_2mortal(doc);
            {
                pmcp_msg m;
                pmcp_sess_t s;
                SV *sid_out;
                Zero(&s, 1, pmcp_sess_t);
                s.level = -1;
                s.v = v;
                pmcp_rpc_classify(aTHX_ doc, &m);
                /* 8. the session: required after initialize, and checked */
                if ((out = pmcp_sess_begin(aTHX_ c, ps, env, &m, &s, cors)))
                    goto answer;
                v = s.v;
                if (pmcp_should_stream(aTHX_ ps, env, &m)) {
                    (void)pmcp_sess_end(aTHX_ ps, env, &s, NULL, &m);
                    out = pmcp_stream_answer(aTHX_ c, pmcp_cap(aTHX_ cv, 0), doc, v,
                                             cors, s.sid, s.level);
                    goto answer;
                }
                pmcp_req_init(&r, v, s.in_session || s.sid);
                r.c = c;
                r.session = s.sid;
                reply = pmcp_dispatch_doc(aTHX_ &ps->srv, &r, doc, &status);
                sid_out = pmcp_sess_end(aTHX_ ps, env, &s, &r, &m);
                if (r.level_set >= 0 && !s.store) ps->srv.log_level = r.level_set;
                pmcp_req_free(aTHX_ &r);
                out = pmcp_http_answer(aTHX_ status, reply, cors);
                if (sid_out) {
                    AV *h = (AV *)SvRV(*av_fetch((AV *)SvRV(out), 1, 0));
                    av_push(h, newSVpvs("Mcp-Session-Id"));
                    av_push(h, newSVsv(sid_out));
                }
            }
        }
    }

answer:
    SP = PL_stack_base + ax - 1;
    ST(0) = sv_2mortal(out);
    XSRETURN(1);
}

/* ---- installing ----------------------------------------------------------------------- */

/* The POST route, at on_compile. */
static void pmcp_http_route(pTHX_ SV *app, SV *server, HV *opts)
{
    AV *cap = newAV();
    SV *argv[5], *r;
    av_push(cap, newSVsv(server));
    av_push(cap, pmcp_auth_guards(aTHX_ app, opts));  /* auth, then oauth (11) */
    {
        /* principal, resolved like any target, or undef */
        SV *p = pmcp_hget(aTHX_ opts, "principal");
        if (p && !pmcp_is_code(p)) {
            SV *pargv[2], *perr = NULL, *code;
            pargv[0] = p;
            pargv[1] = sv_2mortal(newSVpvs("the MCP principal"));
            code = pmcp_call_method(aTHX_ app, "_resolve_target", pargv, 2, G_SCALAR, &perr);
            if (!code) pmcp_croak_sv(aTHX_ sv_2mortal(perr));
            av_push(cap, code);
        }
        else av_push(cap, p ? newSVsv(p) : newSV(0));
    }
    {
        /* the same guards and principal, kept for stdio (13) */
        pmcp_server *srvp = pmcp_server_of(aTHX_ server);
        SV **pp = av_fetch(cap, 2, 0);
        srvp->guards = newSVsv(*av_fetch(cap, 1, 0));
        srvp->principal = (pp && pmcp_is_code(*pp)) ? newSVsv(*pp) : NULL;
    }
    pmcp_prm_install(aTHX_ app, opts);
    argv[0] = sv_2mortal(newSVpvs("POST"));
    argv[1] = pmcp_hget(aTHX_ opts, "path");
    argv[2] = sv_2mortal(pmcp_closure(aTHX_ pmcp_http_cb, cap));
    argv[3] = sv_2mortal(newRV_noinc((SV *)newAV()));
    argv[4] = sv_2mortal(newRV_noinc((SV *)newHV()));
    r = pmcp_call_method(aTHX_ app, "route", argv, 5, G_SCALAR, NULL);
    SvREFCNT_dec(r);

    /* DELETE ends a session. Without sessions the path answers DELETE with
     * Punk's 405, as it does any method it does not serve. The guard hook is
     * the POST route's own, so 11 fills both at once. */
    if (pmcp_sessions_on(aTHX_ opts)) {
        AV *dcap = newAV();
        pmcp_bus_install(aTHX_ app, server, *av_fetch(cap, 1, 0));
        av_push(dcap, newSVsv(server));
        av_push(dcap, newSVsv(*av_fetch(cap, 1, 0)));
        argv[0] = sv_2mortal(newSVpvs("DELETE"));
        argv[2] = sv_2mortal(pmcp_closure(aTHX_ pmcp_delete_cb, dcap));
        argv[3] = sv_2mortal(newRV_noinc((SV *)newAV()));
        argv[4] = sv_2mortal(newRV_noinc((SV *)newHV()));
        r = pmcp_call_method(aTHX_ app, "route", argv, 5, G_SCALAR, NULL);
        SvREFCNT_dec(r);
    }
}

/* At to_app, with the inner app: if the plugin lists `origins`, send the
 * first a preflight and warn when the application's `cors` would refuse the
 * headers an MCP client sends. Only an explicit cors `headers` list can: with
 * none, Punk echoes what was asked. */
static void pmcp_http_cors_check(pTHX_ SV *inner, HV *opts)
{
    SV *origins = pmcp_hget(aTHX_ opts, "origins");
    SV *path = pmcp_hget(aTHX_ opts, "path");
    HV *env;
    SV *res, *err = NULL, *envrv;
    static const char *const need[] = { "authorization", "content-type",
        "mcp-session-id", "mcp-protocol-version", "last-event-id", NULL };

    if (!origins || !pmcp_is_code(inner) || av_len((AV *)SvRV(origins)) < 0) return;
    env = newHV();
    envrv = sv_2mortal(newRV_noinc((SV *)env));
    (void)hv_stores(env, "REQUEST_METHOD", newSVpvs("OPTIONS"));
    (void)hv_stores(env, "PATH_INFO", newSVsv(path));
    (void)hv_stores(env, "SCRIPT_NAME", newSVpvs(""));
    (void)hv_stores(env, "QUERY_STRING", newSVpvs(""));
    (void)hv_stores(env, "SERVER_NAME", newSVpvs("localhost"));
    (void)hv_stores(env, "SERVER_PORT", newSVpvs("80"));
    (void)hv_stores(env, "SERVER_PROTOCOL", newSVpvs("HTTP/1.1"));
    (void)hv_stores(env, "REMOTE_ADDR", newSVpvs("127.0.0.1"));
    (void)hv_stores(env, "psgi.url_scheme", newSVpvs("http"));
    (void)hv_stores(env, "psgi.version", newRV_noinc((SV *)newAV()));
    (void)hv_stores(env, "HTTP_ORIGIN", newSVsv(*av_fetch((AV *)SvRV(origins), 0, 0)));
    (void)hv_stores(env, "HTTP_ACCESS_CONTROL_REQUEST_METHOD", newSVpvs("POST"));
    (void)hv_stores(env, "HTTP_ACCESS_CONTROL_REQUEST_HEADERS",
        newSVpvs("authorization, content-type, mcp-session-id, mcp-protocol-version, last-event-id"));
    res = pmcp_call_sv(aTHX_ inner, &envrv, 1, G_SCALAR, &err);
    if (!res) { SvREFCNT_dec(err); return; }
    sv_2mortal(res);
    if (pmcp_is_array(res) && av_len((AV *)SvRV(res)) >= 1) {
        SV **hp = av_fetch((AV *)SvRV(res), 1, 0);
        AV *h = (hp && pmcp_is_array(*hp)) ? (AV *)SvRV(*hp) : NULL;
        SV *allow = NULL, *missing = sv_2mortal(newSVpvs(""));
        int has_acao = 0, i;
        SSize_t k, n = h ? av_len(h) + 1 : 0;
        for (k = 0; k + 1 < n; k += 2) {
            const char *name = SvPV_nolen(*av_fetch(h, k, 0));
            if (strcasecmp(name, "Access-Control-Allow-Origin") == 0) has_acao = 1;
            if (strcasecmp(name, "Access-Control-Allow-Headers") == 0)
                allow = *av_fetch(h, k + 1, 0);
        }
        if (!has_acao) return;          /* cors does not cover this path */
        for (i = 0; need[i]; i++) {
            SV *lc = sv_2mortal(newSVsv(allow ? allow : &PL_sv_no));
            char *s = SvPV_nolen(lc);
            STRLEN j;
            for (j = 0; s[j]; j++) s[j] = toLOWER(s[j]);
            if (!instr(s, need[i])) {
                if (SvCUR(missing)) sv_catpvs(missing, ", ");
                sv_catpv(missing, need[i]);
            }
        }
        if (SvCUR(missing))
            warn("%s: the application's cors `headers` does not allow %" SVf
                 " on %" SVf ", so a browser client cannot send them\n",
                 PMCP_WHO, SVfARG(missing), SVfARG(path));
    }
}

#endif /* PMCP_HTTP_H */

/* pmcp_bus.h - the GET stream, resource subscriptions, and the worker bus.
 *
 * Needs: pmcp_sess.h, pmcp_res.h.
 *
 * With sessions on, GET on the MCP path opens a session's server stream: an
 * `sse` route whose guard does the checks POST does and the session's. A
 * session has one stream: a second GET closes the first, wherever it is.
 *
 * Each worker keeps its streams in PMCP_STREAMS, session id -> [stream,
 * context, server]. What happens on one worker reaches the stream on another
 * over Punk's bus, on the topic pmcp:<path>, as a payload of
 *
 *   [u8 kind][u32 origin pid][u8 sid length][sid][uri]
 *
 * kind 1, updated: a resource changed, tell every stream whose session
 *   subscribed to it. kind 2, close: end this session's stream.
 *
 * The bus does deliver to the worker that published, but late: a publisher
 * does not wake itself, so its own subscriber runs on its next dispatch (t/70
 * sees it within a timer's wait), and without Hyperman there is no bus at all.
 * So the publisher delivers to its own streams first, then publishes, and a
 * subscriber drops what carries its own pid, or a worker's own streams would
 * hear everything twice (t/70 counts).
 */

#ifndef PMCP_BUS_H
#define PMCP_BUS_H

#define PMCP_BUS_UPDATED 1
#define PMCP_BUS_CLOSE   2
#define PMCP_BUS_SLOT    2048    /* a bus slot, and the most a payload may be */

static HV *PMCP_STREAMS = NULL;

/* Defined in pmcp_stdio.h: a stdio process is a subscriber too (13). */
static void pmcp_stdio_updated(pTHX_ SV *uri);
static void pmcp_stdio_subscribe(pTHX_ SV *uri, int on);
static int pmcp_stdio_active(void);

/* ---- the payload -------------------------------------------------------------- */

/* +1, or NULL when it would not fit a bus slot. */
static SV *pmcp_bus_encode(pTHX_ int kind, U32 pid, SV *sid, SV *uri)
{
    STRLEN sl = 0, ul = 0;
    const char *sp = sid ? SvPV_const(sid, sl) : "";
    const char *up = uri ? SvPV_const(uri, ul) : "";
    unsigned char head[6];
    SV *out;
    if (sl > 255 || 6 + sl + ul > PMCP_BUS_SLOT) return NULL;
    head[0] = (unsigned char)kind;
    head[1] = (unsigned char)(pid >> 24);
    head[2] = (unsigned char)(pid >> 16);
    head[3] = (unsigned char)(pid >> 8);
    head[4] = (unsigned char)pid;
    head[5] = (unsigned char)sl;
    out = newSVpvn((const char *)head, 6);
    sv_catpvn(out, sp, sl);
    sv_catpvn(out, up, ul);
    return out;
}

/* 1 with the parts set (sid and uri mortal, uri UTF-8 if it decodes), or 0
 * for a payload that is not one of ours. */
static int pmcp_bus_decode(pTHX_ SV *payload, int *kind, U32 *pid, SV **sid, SV **uri)
{
    STRLEN l;
    const unsigned char *p;
    STRLEN sl;
    if (!payload || !SvOK(payload)) return 0;
    p = (const unsigned char *)SvPV_const(payload, l);
    if (l < 6) return 0;
    sl = p[5];
    if (6 + sl > l || (p[0] != PMCP_BUS_UPDATED && p[0] != PMCP_BUS_CLOSE)) return 0;
    *kind = p[0];
    *pid = ((U32)p[1] << 24) | ((U32)p[2] << 16) | ((U32)p[3] << 8) | p[4];
    *sid = sv_2mortal(newSVpvn((const char *)p + 6, sl));
    *uri = sv_2mortal(newSVpvn((const char *)p + 6 + sl, l - 6 - sl));
    if (is_utf8_string((U8 *)SvPVX(*uri), SvCUR(*uri))) SvUTF8_on(*uri);
    return 1;
}

static SV *pmcp_bus_topic(pTHX_ pmcp_server *ps)
{
    return sv_2mortal(newSVpvf("pmcp:%" SVf, SVfARG(pmcp_hget(aTHX_ ps->opts, "path"))));
}

/* ---- the streams on this worker ------------------------------------------------ */

static AV *pmcp_stream_entry(pTHX_ SV *sid)
{
    HE *he = PMCP_STREAMS ? hv_fetch_ent(PMCP_STREAMS, sid, 0, 0) : NULL;
    return (he && pmcp_is_array(HeVAL(he))) ? (AV *)SvRV(HeVAL(he)) : NULL;
}

static int pmcp_stream_open(pTHX_ SV *stream)
{
    SV *r = pmcp_call_method(aTHX_ stream, "is_open", NULL, 0, G_SCALAR, NULL);
    int open = r && SvTRUE(r);
    if (r) SvREFCNT_dec(r);
    return open;
}

static void pmcp_stream_close(pTHX_ SV *sid)
{
    AV *e = pmcp_stream_entry(aTHX_ sid);
    if (!e) return;
    {
        SV *stream = sv_2mortal(newSVsv(*av_fetch(e, 0, 0)));
        SV *err = NULL, *r;
        (void)hv_delete_ent(PMCP_STREAMS, sid, G_DISCARD, 0);
        r = pmcp_call_method(aTHX_ stream, "close", NULL, 0, G_SCALAR, &err);
        if (r) SvREFCNT_dec(r); else SvREFCNT_dec(err);
    }
}

/* One notification down one stream: an SSE `message` event. */
static void pmcp_stream_send(pTHX_ SV *stream, const char *method, SV *params)
{
    HV *m = newHV();
    SV *rv, *bytes, *err = NULL, *argv[2], *r;
    (void)hv_stores(m, "jsonrpc", newSVpvs("2.0"));
    (void)hv_stores(m, "method", newSVpv(method, 0));
    (void)hv_stores(m, "params", params);
    rv = sv_2mortal(newRV_noinc((SV *)m));
    bytes = pmcp_json_trapped(aTHX_ rv, &err);
    if (!bytes) { SvREFCNT_dec(err); return; }
    argv[0] = sv_2mortal(newSVpvs("message"));
    argv[1] = sv_2mortal(bytes);
    r = pmcp_call_method(aTHX_ stream, "event", argv, 2, G_SCALAR, &err);
    if (r) SvREFCNT_dec(r); else SvREFCNT_dec(err);
}

/* Does this session subscribe to `uri`? Asked of its record, which is the
 * truth wherever the subscribe arrived. */
static int pmcp_session_subscribes(pTHX_ SV *c, pmcp_server *ps, SV *sid, SV *uri)
{
    SV *store = pmcp_sess_store(aTHX_ c, ps->opts);
    HV *rec = store ? pmcp_sess_load(aTHX_ store, sid, pmcp_now(aTHX)) : NULL;
    SV *subs = rec ? pmcp_hget(aTHX_ rec, "subs") : NULL;
    SSize_t i, n;
    if (!pmcp_is_array(subs)) return 0;
    n = av_len((AV *)SvRV(subs)) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch((AV *)SvRV(subs), i, 0);
        if (e && sv_eq(*e, uri)) return 1;
    }
    return 0;
}

/* What a payload asks of this worker's streams. Prunes the closed ones as it
 * goes: nothing else would, and a table that only grows is a leak. */
static void pmcp_bus_deliver(pTHX_ pmcp_server *ps, int kind, SV *sid, SV *uri)
{
    if (kind == PMCP_BUS_UPDATED) pmcp_stdio_updated(aTHX_ uri);
    if (!PMCP_STREAMS) return;
    if (kind == PMCP_BUS_CLOSE) {
        pmcp_stream_close(aTHX_ sid);
        return;
    }
    {
        AV *sids = (AV *)sv_2mortal((SV *)newAV());
        HE *he;
        SSize_t i, n;
        hv_iterinit(PMCP_STREAMS);
        while ((he = hv_iternext(PMCP_STREAMS)))
            av_push(sids, newSVsv(hv_iterkeysv(he)));
        n = av_len(sids) + 1;
        for (i = 0; i < n; i++) {
            SV *s = *av_fetch(sids, i, 0);
            AV *e = pmcp_stream_entry(aTHX_ s);
            SV *stream, *c;
            if (!e) continue;
            if (pmcp_server_of(aTHX_ *av_fetch(e, 2, 0)) != ps) continue;
            stream = *av_fetch(e, 0, 0);
            c = *av_fetch(e, 1, 0);
            if (!pmcp_stream_open(aTHX_ stream)) {
                (void)hv_delete_ent(PMCP_STREAMS, s, G_DISCARD, 0);
                continue;
            }
            if (pmcp_session_subscribes(aTHX_ c, ps, s, uri)) {
                HV *p = newHV();
                (void)hv_stores(p, "uri", newSVsv(uri));
                pmcp_stream_send(aTHX_ stream, "notifications/resources/updated",
                                 newRV_noinc((SV *)p));
            }
        }
    }
}

/* Deliver here, then tell the pool. `via` is a context or the app, whichever
 * can publish. Returns what publish said: 1 on the ring, 0 local only, -1 not
 * sent (too big). */
static int pmcp_bus_send(pTHX_ pmcp_server *ps, SV *via, int kind, SV *sid, SV *uri)
{
    SV *payload, *argv[2], *r;
    int said = 0;
    pmcp_bus_deliver(aTHX_ ps, kind, sid, uri);
    payload = pmcp_bus_encode(aTHX_ kind, (U32)getpid(), sid, uri);
    if (!payload) {
        warn("%s: a %s for %" SVf " does not fit a bus slot, so only this worker "
             "saw it\n", PMCP_WHO, kind == PMCP_BUS_CLOSE ? "close" : "resource update",
             SVfARG(uri && SvCUR(uri) ? uri : sid));
        return -1;
    }
    argv[0] = pmcp_bus_topic(aTHX_ ps);
    argv[1] = sv_2mortal(payload);
    r = pmcp_call_method(aTHX_ via, "publish", argv, 2, G_SCALAR, NULL);
    if (r) {
        said = SvOK(r) ? (int)SvIV(r) : 0;
        SvREFCNT_dec(r);
    }
    return said;
}

/* The subscriber, registered at boot: ($topic, $payload). cap = [server] */
XS_INTERNAL(pmcp_bus_cb)
{
    dXSARGS;
    pmcp_server *ps = pmcp_server_of(aTHX_ pmcp_cap(aTHX_ cv, 0));
    int kind;
    U32 pid;
    SV *sid, *uri;
    if (ps && items > 1 && pmcp_bus_decode(aTHX_ ST(1), &kind, &pid, &sid, &uri)
        && pid != (U32)getpid())
        pmcp_bus_deliver(aTHX_ ps, kind, sid, uri);
    XSRETURN_EMPTY;
}

/* ---- the GET route ---------------------------------------------------------------- */

/* The route's guard: POST's checks, then the session's. NULL to open the
 * stream (the session id stashed), or the refusal. cap = [server, guards] */
XS_INTERNAL(pmcp_get_guard)
{
    dXSARGS;
    SV *c = items > 0 ? ST(0) : &PL_sv_undef;
    pmcp_server *ps = pmcp_server_of(aTHX_ pmcp_cap(aTHX_ cv, 0));
    SV *gslot = pmcp_cap(aTHX_ cv, 1);
    AV *guards = (gslot && pmcp_is_array(gslot)) ? (AV *)SvRV(gslot) : NULL;
    SV *envsv = sv_2mortal(pmcp_call_method(aTHX_ c, "env", NULL, 0, G_SCALAR, NULL));
    HV *env = (HV *)SvRV(envsv);
    int cors = pmcp_env_get(aTHX_ env, "HTTP_ORIGIN") != NULL;
    SV *out = NULL, *sid, *store, *pv, *stash;
    HV *rec;

    if (!pmcp_origin_ok(aTHX_ env, ps->opts)) {
        out = pmcp_http_refuse(aTHX_ 403, "origin not allowed", cors);
        goto answer;
    }
    if (!pmcp_wants_sse(aTHX_ env)) {
        out = pmcp_http_refuse(aTHX_ 406, "Accept must allow text/event-stream", cors);
        goto answer;
    }
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
    sid = pmcp_env_get(aTHX_ env, "HTTP_MCP_SESSION_ID");
    if (!sid) {
        out = pmcp_http_refuse(aTHX_ 400, "a session id is required", cors);
        goto answer;
    }
    store = pmcp_sess_store(aTHX_ c, ps->opts);
    rec = (store && pmcp_sid_ok(aTHX_ sid)) ? pmcp_sess_load(aTHX_ store, sid, pmcp_now(aTHX)) : NULL;
    if (!rec || !sv_eq(pmcp_hget(aTHX_ rec, "principal"), pmcp_principal(aTHX_ env))) {
        out = pmcp_http_refuse(aTHX_ 404, "unknown session", cors);
        goto answer;
    }
    pv = pmcp_env_get(aTHX_ env, "HTTP_MCP_PROTOCOL_VERSION");
    if (pv && !sv_eq(pv, pmcp_hget(aTHX_ rec, "v"))) {
        out = pmcp_http_refuse(aTHX_ 400, "MCP-Protocol-Version does not match the session's", cors);
        goto answer;
    }
    stash = sv_2mortal(pmcp_call_method(aTHX_ c, "stash", NULL, 0, G_SCALAR, NULL));
    if (pmcp_is_hash(stash)) (void)hv_stores((HV *)SvRV(stash), "mcp.sid", newSVsv(sid));

answer:
    SP = PL_stack_base + ax - 1;
    ST(0) = out ? sv_2mortal(out) : &PL_sv_undef;
    XSRETURN(1);
}

/* Drops the table entry when its stream ends, unless a newer stream has
 * taken the session's place. cap = [sid, stream] */
XS_INTERNAL(pmcp_stream_gone)
{
    dXSARGS;
    SV *sid = pmcp_cap(aTHX_ cv, 0), *stream = pmcp_cap(aTHX_ cv, 1);
    AV *e = sid ? pmcp_stream_entry(aTHX_ sid) : NULL;
    PERL_UNUSED_VAR(items);
    if (e && SvROK(*av_fetch(e, 0, 0)) && stream && SvROK(stream)
        && SvRV(*av_fetch(e, 0, 0)) == SvRV(stream))
        (void)hv_delete_ent(PMCP_STREAMS, sid, G_DISCARD, 0);
    XSRETURN_EMPTY;
}

/* Put a stream in the table for a session, closing whatever held it before:
 * here directly, elsewhere over the bus. `via` publishes. */
static void pmcp_stream_register(pTHX_ SV *server, SV *via, SV *sid, SV *stream, SV *c)
{
    pmcp_server *ps = pmcp_server_of(aTHX_ server);
    AV *e = newAV(), *cap;
    SV *cb, *argv[2], *r, *err = NULL;
    pmcp_bus_send(aTHX_ ps, via, PMCP_BUS_CLOSE, sid, NULL);
    if (!PMCP_STREAMS) PMCP_STREAMS = newHV();
    av_push(e, newSVsv(stream));
    av_push(e, newSVsv(c));
    av_push(e, newSVsv(server));
    (void)hv_store_ent(PMCP_STREAMS, sid, newRV_noinc((SV *)e), 0);
    cap = newAV();
    av_push(cap, newSVsv(sid));
    av_push(cap, newSVsv(stream));
    cb = sv_2mortal(pmcp_closure(aTHX_ pmcp_stream_gone, cap));
    argv[0] = sv_2mortal(newSVpvs("close"));
    argv[1] = cb;
    r = pmcp_call_method(aTHX_ stream, "on", argv, 2, G_SCALAR, &err);
    if (r) SvREFCNT_dec(r); else SvREFCNT_dec(err);
}

/* The sse handler: ($c, $stream). cap = [server] */
XS_INTERNAL(pmcp_get_cb)
{
    dXSARGS;
    SV *c = items > 0 ? ST(0) : &PL_sv_undef;
    SV *stream = items > 1 ? ST(1) : &PL_sv_undef;
    SV *server = pmcp_cap(aTHX_ cv, 0);
    SV *stash = sv_2mortal(pmcp_call_method(aTHX_ c, "stash", NULL, 0, G_SCALAR, NULL));
    SV *sid = pmcp_is_hash(stash) ? pmcp_hget(aTHX_ (HV *)SvRV(stash), "mcp.sid") : NULL;
    if (sid) {
        sid = sv_2mortal(newSVsv(sid));
        pmcp_stream_register(aTHX_ server, c, sid, stream, c);
        {
            /* t/35 drives the live route through this */
            SV *hook = get_sv("Punk::Plugin::MCP::_TEST_GET_HOOK", 0);
            if (hook && pmcp_is_code(hook)) {
                SV *argv[3], *r;
                argv[0] = c; argv[1] = stream; argv[2] = sid;
                r = pmcp_call_sv(aTHX_ hook, argv, 3, G_SCALAR, NULL);
                if (r) SvREFCNT_dec(r);
            }
        }
    }
    XSRETURN_EMPTY;
}

/* At on_compile, with sessions on: the GET route and the bus subscriber. */
static void pmcp_bus_install(pTHX_ SV *app, SV *server, SV *guards)
{
    pmcp_server *ps = pmcp_server_of(aTHX_ server);
    AV *gcap = newAV(), *hcap = newAV(), *bcap = newAV(), *glist = newAV();
    HV *opts = newHV();
    SV *argv[5], *r;

    av_push(gcap, newSVsv(server));
    av_push(gcap, newSVsv(guards));
    av_push(glist, pmcp_closure(aTHX_ pmcp_get_guard, gcap));
    av_push(hcap, newSVsv(server));
    (void)hv_stores(opts, "heartbeat", newSViv(PMCP_HEARTBEAT_SECS));
    argv[0] = pmcp_hget(aTHX_ ps->opts, "path");
    argv[1] = sv_2mortal(pmcp_closure(aTHX_ pmcp_get_cb, hcap));
    argv[2] = sv_2mortal(newRV_noinc((SV *)opts));
    argv[3] = sv_2mortal(newRV_noinc((SV *)glist));
    r = pmcp_call_method(aTHX_ app, "sse", argv, 4, G_SCALAR, NULL);
    if (r) SvREFCNT_dec(r);

    av_push(bcap, newSVsv(server));
    argv[0] = pmcp_bus_topic(aTHX_ ps);
    argv[1] = sv_2mortal(pmcp_closure(aTHX_ pmcp_bus_cb, bcap));
    r = pmcp_call_method(aTHX_ app, "subscribe", argv, 2, G_SCALAR, NULL);
    if (r) SvREFCNT_dec(r);
}

/* ---- resources/subscribe and unsubscribe -------------------------------------------- */

static SV *pmcp_subscription(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params, int on)
{
    pmcp_server *ps = (pmcp_server *)s;     /* pmcp_srv is its first member */
    pmcp_resources *rs = (pmcp_resources *)s->resources;
    SV **uv = params ? hv_fetchs(params, "uri", 0) : NULL;
    SV *store, *subs;
    HV *rec, *caps = NULL;
    pmcp_resource *res;

    if (!rs || !r->c || !((s->can_notify && r->session) || r->stdio))
        return pmcp_fail(r, PMCP_METHOD, "method not found");
    if (!(uv && pmcp_is_str(*uv))) return pmcp_fail(r, PMCP_PARAMS, "a uri is required");
    if (on) {
        SV *why;
        res = pmcp_res_find(aTHX_ rs, *uv, &caps);
        if (caps) SvREFCNT_dec((SV *)caps);
        if (!res) return pmcp_res_not_found(aTHX_ r, *uv);
        if ((why = pmcp_run_guards(aTHX_ res->guards, r->c))) {
            SvREFCNT_dec(why);
            return pmcp_res_not_found(aTHX_ r, *uv);
        }
    }
    /* over stdio the process is the session: its subscriptions are its own */
    if (r->stdio) {
        pmcp_stdio_subscribe(aTHX_ *uv, on);
        return newRV_noinc((SV *)newHV());
    }
    store = pmcp_sess_store(aTHX_ r->c, ps->opts);
    rec = store ? pmcp_sess_load(aTHX_ store, r->session, pmcp_now(aTHX)) : NULL;
    if (!rec) return pmcp_fail(r, PMCP_INTERNAL, "the session is gone");
    subs = pmcp_hget(aTHX_ rec, "subs");
    if (!pmcp_is_array(subs)) {
        subs = sv_2mortal(newRV_noinc((SV *)newAV()));
        (void)hv_stores(rec, "subs", newSVsv(subs));
        subs = pmcp_hget(aTHX_ rec, "subs");
    }
    {
        AV *av = (AV *)SvRV(subs), *keep = newAV();
        SSize_t i, n = av_len(av) + 1;
        int had = 0;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            if (e && sv_eq(*e, *uv)) { had = 1; continue; }
            if (e) av_push(keep, newSVsv(*e));
        }
        if (on) av_push(keep, newSVsv(*uv));
        (void)hv_stores(rec, "subs", newRV_noinc((SV *)keep));
        if (on || had)
            pmcp_sess_save(aTHX_ store, r->session, rec,
                           SvIV(pmcp_hget(aTHX_ ps->opts, "session_ttl")));
    }
    return newRV_noinc((SV *)newHV());
}

static SV *pmcp_resources_subscribe(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    return pmcp_subscription(aTHX_ s, r, params, 1);
}

static SV *pmcp_resources_unsubscribe(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    return pmcp_subscription(aTHX_ s, r, params, 0);
}

/* ---- telling subscribers ------------------------------------------------------------ */

/* $c->mcp_resource_updated($uri): this worker's subscribed streams, then the
 * pool. Returns what publish said, or 0 with sessions off. cap = [] */
XS_INTERNAL(pmcp_helper_updated)
{
    dXSARGS;
    int said = 0;
    if (items < 2 || !SvOK(ST(1)) || SvROK(ST(1)))
        croak("%s: mcp_resource_updated takes the resource's URI", PMCP_WHO);
    {
        SV *app = sv_2mortal(pmcp_call_method(aTHX_ ST(0), "app", NULL, 0, G_SCALAR, NULL));
        HV *st = pmcp_is_hash(app) ? pmcp_state(aTHX_ app) : NULL;
        pmcp_server *ps = st ? pmcp_server_of(aTHX_ pmcp_hget(aTHX_ st, "server")) : NULL;
        if (ps && (pmcp_sessions_on(aTHX_ ps->opts) || pmcp_stdio_active()))
            said = pmcp_bus_send(aTHX_ ps, ST(0), PMCP_BUS_UPDATED, NULL, ST(1));
    }
    SP = PL_stack_base + ax - 1;
    ST(0) = sv_2mortal(newSViv(said));
    XSRETURN(1);
}

/* DELETE's close, for pmcp_sess.h. */
static void pmcp_session_closed(pTHX_ pmcp_server *ps, SV *c, SV *sid)
{
    (void)pmcp_bus_send(aTHX_ ps, c, PMCP_BUS_CLOSE, sid, NULL);
}

#endif /* PMCP_BUS_H */

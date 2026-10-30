/* pmcp_sse.h - SSE on POST: a request answered with an event stream that
 * carries progress and log notifications and ends with the response.
 *
 * Needs: pmcp_call.h, pmcp_http.h.
 *
 * A stream's state is one hash, shared by the transport and the call object
 * so $c->mcp_progress and $c->mcp_log can write to it:
 *
 *   w        the Punk::Stream writer
 *   c        the request's context, to await the writer's drain on
 *   n        the last event id written
 *   level    the minimum log level, a PMCP_LOG_* index
 *   logging  1 when log messages may be sent at all
 *   done     1 once the response is written, which stops the heartbeat
 *
 * Punk::Stream sends X-Accel-Buffering: no on every stream itself.
 *
 * JSON stays the default. On HTTP/1.1 a streamed answer ends the connection,
 * so a client pays a reconnect for every streamed call (POD, 08).
 */

#ifndef PMCP_SSE_H
#define PMCP_SSE_H

#define PMCP_HEARTBEAT_SECS 15

/* Defined in pmcp_stdio.h: one line on the protocol stream (13). */
static void pmcp_stdio_write(pTHX_ SV *json);

/* ---- calls streaming on this worker, for notifications/cancelled ------------- */

static HV *PMCP_LIVE = NULL;

/* The session (or "-" stateless), then "s:" or "i:" and the id, so the
 * string "1" and the number 1 differ, and one session cannot reach into
 * another's calls. Stateless, the id alone is the key, so any client could
 * flag another's call: it only sets a flag the tool chooses to read. Mortal. */
static SV *pmcp_live_key(pTHX_ SV *sid, SV *id)
{
    return sv_2mortal(newSVpvf("%" SVf "/%c:%" SVf,
        SVfARG(sid ? sid : sv_2mortal(newSVpvs("-"))),
        SvPOK(id) ? 's' : 'i', SVfARG(id)));
}

static void pmcp_live_add(pTHX_ SV *sid, SV *id, SV *call)
{
    if (!PMCP_LIVE) PMCP_LIVE = newHV();
    (void)hv_store_ent(PMCP_LIVE, pmcp_live_key(aTHX_ sid, id), newSVsv(call), 0);
}

static void pmcp_live_del(pTHX_ SV *sid, SV *id)
{
    if (PMCP_LIVE) (void)hv_delete_ent(PMCP_LIVE, pmcp_live_key(aTHX_ sid, id), G_DISCARD, 0);
}

static void pmcp_live_cancel(pTHX_ SV *sid, SV *id)
{
    HE *he = PMCP_LIVE ? hv_fetch_ent(PMCP_LIVE, pmcp_live_key(aTHX_ sid, id), 0, 0) : NULL;
    if (he && pmcp_is_hash(HeVAL(he)))
        (void)hv_stores((HV *)SvRV(HeVAL(he)), "cancelled", newSViv(1));
}

/* A call object made while a stream is open learns where to write, and is
 * found by notifications/cancelled while it runs. */
static void pmcp_call_attach(pTHX_ pmcp_req *r, SV *call)
{
    if (!pmcp_is_hash(call)) return;
    if (r->session)
        (void)hv_stores((HV *)SvRV(call), "session", newSVsv(r->session));
    if (!r->stream) return;
    (void)hv_stores((HV *)SvRV(call), "_stream", newSVsv(r->stream));
    if (r->id) pmcp_live_add(aTHX_ r->session, r->id, call);
}

/* ---- writing an event ------------------------------------------------------------ */

/* One event: `event: message`, an id, the JSON on one data line, a blank line.
 * Then the writer's drain is awaited, so bytes never pile up behind a slow
 * client. Returns whether the stream is still open. */
static int pmcp_sse_send(pTHX_ HV *st, SV *json)
{
    SV *w = pmcp_hget(aTHX_ st, "w"), *c = pmcp_hget(aTHX_ st, "c");
    SV *nsv = pmcp_hget(aTHX_ st, "n");
    IV n = (nsv ? SvIV(nsv) : 0) + 1;
    SV *frame, *err = NULL, *r, *drain;
    STRLEN l;
    const char *p;

    /* over stdio a message is a line, not an event */
    if (pmcp_hget(aTHX_ st, "stdio")) {
        pmcp_stdio_write(aTHX_ json);
        return 1;
    }
    if (!w || !c) return 0;
    (void)hv_stores(st, "n", newSViv(n));
    p = SvPV_const(json, l);
    frame = sv_2mortal(newSVpvf("event: message\nid: %" IVdf "\ndata: ", n));
    sv_catpvn(frame, p, l);
    sv_catpvs(frame, "\n\n");
    r = pmcp_call_method(aTHX_ w, "write", &frame, 1, G_SCALAR, &err);
    if (!r) { SvREFCNT_dec(err); return 0; }
    SvREFCNT_dec(r);
    drain = pmcp_call_method(aTHX_ w, "drain", NULL, 0, G_SCALAR, &err);
    if (!drain) { SvREFCNT_dec(err); return 0; }
    sv_2mortal(drain);
    r = pmcp_call_method(aTHX_ c, "await", &drain, 1, G_SCALAR, &err);
    if (!r) { SvREFCNT_dec(err); return 0; }
    {
        int ok = SvTRUE(r);
        SvREFCNT_dec(r);
        return ok;
    }
}

/* A notification, {"jsonrpc":"2.0","method":M,"params":P}, as an event. Takes
 * ownership of params. Returns 1 when written. */
static int pmcp_sse_notify(pTHX_ HV *st, const char *method, SV *params)
{
    HV *m = newHV();
    SV *rv, *bytes, *err = NULL;
    int ok;
    (void)hv_stores(m, "jsonrpc", newSVpvs("2.0"));
    (void)hv_stores(m, "method", newSVpv(method, 0));
    (void)hv_stores(m, "params", params);
    rv = sv_2mortal(newRV_noinc((SV *)m));
    bytes = pmcp_json_trapped(aTHX_ rv, &err);
    if (!bytes) {
        sv_2mortal(err);
        warn("%s: a %s notification is not JSON, not sent: %" SVf, PMCP_WHO,
             method, SVfARG(err));
        return 0;
    }
    ok = pmcp_sse_send(aTHX_ st, sv_2mortal(bytes));
    return ok;
}

/* ---- the heartbeat ------------------------------------------------------------------ */

/* A comment line every PMCP_HEARTBEAT_SECS while the call runs, so a quiet
 * call does not meet an idle timeout in a client or a proxy. Only on a live
 * Hyperman loop (psgix.loop): off one, $c->timer sleeps where it is made and
 * would hold the call up instead. $Punk::Plugin::MCP::HEARTBEAT overrides the
 * interval, for the live tests. cap = [state] */
XS_INTERNAL(pmcp_heartbeat_cb);
static void pmcp_heartbeat_arm(pTHX_ SV *strv)
{
    HV *st = (HV *)SvRV(strv);
    SV *c = pmcp_hget(aTHX_ st, "c"), *secs, *timer, *err = NULL, *cb, *r;
    SV *knob = get_sv("Punk::Plugin::MCP::HEARTBEAT", 0);
    AV *cap;
    if (pmcp_hget(aTHX_ st, "done") || !c) return;
    secs = sv_2mortal(newSVnv(knob && SvOK(knob) && SvNV(knob) > 0
                              ? SvNV(knob) : PMCP_HEARTBEAT_SECS));
    timer = pmcp_call_method(aTHX_ c, "timer", &secs, 1, G_SCALAR, &err);
    if (!timer) { SvREFCNT_dec(err); return; }
    sv_2mortal(timer);
    /* A timer settled already is one that slept where it was made: there is no
     * loop behind this request after all, and re-arming from on_done would
     * never return. */
    {
        SV *ready = pmcp_call_method(aTHX_ timer, "is_ready", NULL, 0, G_SCALAR, NULL);
        int now = ready && SvTRUE(ready);
        if (ready) SvREFCNT_dec(ready);
        if (now) return;
    }
    cap = newAV();
    av_push(cap, newSVsv(strv));
    cb = sv_2mortal(pmcp_closure(aTHX_ pmcp_heartbeat_cb, cap));
    r = pmcp_call_method(aTHX_ timer, "on_done", &cb, 1, G_SCALAR, &err);
    if (r) SvREFCNT_dec(r); else SvREFCNT_dec(err);
}

XS_INTERNAL(pmcp_heartbeat_cb)
{
    dXSARGS;
    SV *strv = pmcp_cap(aTHX_ cv, 0);
    PERL_UNUSED_VAR(items);
    if (strv && pmcp_is_hash(strv)) {
        HV *st = (HV *)SvRV(strv);
        SV *w = pmcp_hget(aTHX_ st, "w");
        if (!pmcp_hget(aTHX_ st, "done") && w) {
            SV *ping = sv_2mortal(newSVpvs(": ping\n\n")), *err = NULL;
            SV *r = pmcp_call_method(aTHX_ w, "write", &ping, 1, G_SCALAR, &err);
            if (r) SvREFCNT_dec(r); else SvREFCNT_dec(err);
            pmcp_heartbeat_arm(aTHX_ strv);
        }
    }
    XSRETURN_EMPTY;
}

/* ---- the stream ------------------------------------------------------------------------- */

/* The dispatch, run under G_EVAL from the stream callback, so a croak becomes
 * an error event and a clean close rather than a body cut short.
 * cap = [server, doc, version, state] */
XS_INTERNAL(pmcp_stream_work)
{
    dXSARGS;
    SV *c = items > 0 ? ST(0) : &PL_sv_undef;
    pmcp_server *ps = pmcp_server_of(aTHX_ pmcp_cap(aTHX_ cv, 0));
    SV *doc = pmcp_cap(aTHX_ cv, 1);
    enum pmcp_ver v = (enum pmcp_ver)SvIV(pmcp_cap(aTHX_ cv, 2));
    SV *strv = pmcp_cap(aTHX_ cv, 3);
    SV *sid = pmcp_cap(aTHX_ cv, 4);
    pmcp_req r;
    int status = 0;
    SV *reply;
    SV *id = NULL;

    if (sid && !SvOK(sid)) sid = NULL;

    /* t/32 proves a croak in here becomes an error event and a clean close */
    {
        SV *k = get_sv("Punk::Plugin::MCP::_TEST_CROAK", 0);
        if (k && SvTRUE(k)) croak("%s: a croak inside the stream, for t/32", PMCP_WHO);
    }
    pmcp_req_init(&r, v, 0);
    r.c = c;
    r.stream = strv;
    r.session = sid;
    r.in_session = sid ? 1 : 0;
    {
        pmcp_msg m;
        pmcp_rpc_classify(aTHX_ doc, &m);
        if (m.id) id = sv_2mortal(newSVsv(m.id));
    }
    reply = pmcp_dispatch_doc(aTHX_ &ps->srv, &r, doc, &status);
    if (id) pmcp_live_del(aTHX_ sid, id);
    if (r.level_set >= 0) pmcp_level_set(aTHX_ c, ps, sid, r.level_set);
    pmcp_req_free(aTHX_ &r);
    if (reply) {
        sv_2mortal(reply);
        (void)pmcp_sse_send(aTHX_ (HV *)SvRV(strv), reply);
    }
    XSRETURN_EMPTY;
}

/* Punk::Stream's callback: ($c, $w). cap = [server, doc, version, sid, level] */
XS_INTERNAL(pmcp_stream_cb)
{
    dXSARGS;
    SV *c = items > 0 ? ST(0) : &PL_sv_undef;
    SV *w = items > 1 ? ST(1) : &PL_sv_undef;
    SV *server = pmcp_cap(aTHX_ cv, 0), *doc = pmcp_cap(aTHX_ cv, 1);
    SV *ver = pmcp_cap(aTHX_ cv, 2);
    SV *sid = pmcp_cap(aTHX_ cv, 3), *lvl = pmcp_cap(aTHX_ cv, 4);
    pmcp_server *ps = pmcp_server_of(aTHX_ server);
    HV *st = newHV();
    SV *strv = sv_2mortal(newRV_noinc((SV *)st));
    AV *cap;
    SV *work, *err = NULL, *r;

    (void)hv_stores(st, "w", newSVsv(w));
    (void)hv_stores(st, "c", newSVsv(c));
    (void)hv_stores(st, "n", newSViv(0));
    (void)hv_stores(st, "level", newSViv(lvl && SvOK(lvl) ? SvIV(lvl)
                                    : ps ? ps->srv.log_level : PMCP_LOG_DEFAULT));
    (void)hv_stores(st, "logging", newSViv(ps && ps->srv.logging && ps->srv.can_notify));
    {
        SV *envsv = sv_2mortal(pmcp_call_method(aTHX_ c, "env", NULL, 0, G_SCALAR, NULL));
        if (pmcp_is_hash(envsv) && pmcp_hget(aTHX_ (HV *)SvRV(envsv), "psgix.loop"))
            pmcp_heartbeat_arm(aTHX_ strv);
    }

    cap = newAV();
    av_push(cap, newSVsv(server));
    av_push(cap, newSVsv(doc));
    av_push(cap, newSVsv(ver));
    av_push(cap, newSVsv(strv));
    av_push(cap, sid ? newSVsv(sid) : newSV(0));
    work = sv_2mortal(pmcp_closure(aTHX_ pmcp_stream_work, cap));
    r = pmcp_call_sv(aTHX_ work, &c, 1, G_SCALAR, &err);
    if (r) SvREFCNT_dec(r);
    else {
        /* the dispatch itself croaked: say so as the answer, then end cleanly */
        pmcp_msg m;
        SV *e;
        pmcp_rpc_classify(aTHX_ doc, &m);
        if (m.id) pmcp_live_del(aTHX_ (sid && SvOK(sid)) ? sid : NULL, m.id);
        e = sv_2mortal(pmcp_rpc_error(aTHX_ m.id, PMCP_INTERNAL, "internal error", NULL));
        (void)pmcp_sse_send(aTHX_ st, e);
        SvREFCNT_dec(err);
    }
    (void)hv_stores(st, "done", newSViv(1));
    XSRETURN_EMPTY;
}

/* Does the client accept an event stream? Only if it says so: no Accept header
 * is a client that never asked for one. */
static int pmcp_wants_sse(pTHX_ HV *env)
{
    SV *a = pmcp_env_get(aTHX_ env, "HTTP_ACCEPT");
    STRLEN l;
    const char *p;
    if (!a) return 0;
    p = SvPV_const(a, l);
    {
        SV *lc = sv_2mortal(newSVpvn(p, l));
        char *s = SvPVX(lc);
        STRLEN i;
        for (i = 0; i < l; i++) s[i] = toLOWER(s[i]);
        return instr(s, "text/event-stream") != NULL;
    }
}

/* Stream this request? After the body is parsed and before anything runs:
 * the tool has to run inside the stream's callback, so the choice comes first. */
static int pmcp_should_stream(pTHX_ pmcp_server *ps, HV *env, pmcp_msg *m)
{
    SV *mode = pmcp_hget(aTHX_ ps->opts, "stream");
    const char *mp = mode ? SvPV_nolen(mode) : "auto";
    if (m->kind != PMCP_K_REQUEST || strEQ(mp, "json")) return 0;
    /* initialize answers with the session id in a header: never a stream */
    if (m->mlen == 10 && memEQ(m->method, "initialize", 10)) return 0;
    if (!pmcp_wants_sse(aTHX_ env)) return 0;
    if (strEQ(mp, "always")) return 1;
    if (m->params) {
        SV **meta = hv_fetchs(m->params, "_meta", 0);
        if (meta && pmcp_is_hash(*meta)) {
            SV **pt = hv_fetchs((HV *)SvRV(*meta), "progressToken", 0);
            if (pt && pmcp_id_ok(*pt)) return 1;
        }
    }
    if (m->mlen == 10 && memEQ(m->method, "tools/call", 10) && ps->srv.tools && m->params) {
        SV **nv = hv_fetchs(m->params, "name", 0);
        pmcp_tool *t = (nv && pmcp_is_str(*nv))
                     ? pmcp_tool_find(aTHX_ (pmcp_tools *)ps->srv.tools, *nv) : NULL;
        if (t && t->stream) return 1;
    }
    return 0;
}

/* The streamed answer: what $c->stream returns, for the handler to return. +1 */
static SV *pmcp_stream_answer(pTHX_ SV *c, SV *server, SV *doc, enum pmcp_ver v,
                              int cors, SV *sid, int level)
{
    AV *cap = newAV(), *hdr = newAV();
    HV *opts = newHV();
    SV *argv[3], *res;
    av_push(cap, newSVsv(server));
    av_push(cap, newSVsv(doc));
    av_push(cap, newSViv((IV)v));
    av_push(cap, sid ? newSVsv(sid) : newSV(0));
    av_push(cap, level >= 0 ? newSViv(level) : newSV(0));
    av_push(hdr, newSVpvs("Cache-Control"));
    av_push(hdr, newSVpvs("no-store"));
    if (cors) {
        av_push(hdr, newSVpvs("Access-Control-Expose-Headers"));
        av_push(hdr, newSVpvs(PMCP_EXPOSE));
    }
    (void)hv_stores(opts, "headers", newRV_noinc((SV *)hdr));
    argv[0] = sv_2mortal(newSVpvs("text/event-stream"));
    argv[1] = sv_2mortal(newRV_noinc((SV *)opts));
    argv[2] = sv_2mortal(pmcp_closure(aTHX_ pmcp_stream_cb, cap));
    res = pmcp_call_method(aTHX_ c, "stream", argv, 3, G_SCALAR, NULL);
    return res;
}

/* ---- $c->mcp_progress and $c->mcp_log ---------------------------------------------------- */

/* The call object and its stream state, or NULL. Both borrowed. */
static HV *pmcp_call_stream(pTHX_ SV *c, HV **call)
{
    SV *callsv = pmcp_stash_get(aTHX_ c, PMCP_STASH_CALL);
    SV *st;
    *call = NULL;
    if (!callsv || !pmcp_is_hash(callsv)) return NULL;
    *call = (HV *)SvRV(callsv);
    st = pmcp_hget(aTHX_ *call, "_stream");
    return pmcp_is_hash(st) ? (HV *)SvRV(st) : NULL;
}

/* A number as JSON writes it: an integer when it is one. +1 */
static SV *pmcp_num(pTHX_ SV *v)
{
    NV n = SvNV(v);
    if (n == (NV)(IV)n) return newSViv((IV)n);
    return newSVnv(n);
}

/* $c->mcp_progress($done, $total?, $message?): 1 when sent, 0 when there is
 * no stream or no progress token to send it against. */
XS_INTERNAL(pmcp_helper_progress)
{
    dXSARGS;
    HV *call, *st, *p;
    SV *token, *last, *done;
    int ok = 0;

    if (items < 2 || !SvOK(ST(1)) || SvROK(ST(1)) || !looks_like_number(ST(1)))
        croak("%s: mcp_progress takes a number, how far along", PMCP_WHO);
    done = ST(1);
    st = pmcp_call_stream(aTHX_ ST(0), &call);
    token = call ? pmcp_hget(aTHX_ call, "progress_token") : NULL;
    if (st && token) {
        last = pmcp_hget(aTHX_ call, "_progress");
        if (last && SvNV(done) <= SvNV(last)) {
            warn("%s: progress %" NVgf " is not above %" NVgf ", not sent\n",
                 PMCP_WHO, SvNV(done), SvNV(last));
        }
        else {
            (void)hv_stores(call, "_progress", newSVnv(SvNV(done)));
            p = newHV();
            (void)hv_stores(p, "progressToken", newSVsv(token));
            (void)hv_stores(p, "progress", pmcp_num(aTHX_ done));
            if (items > 2 && SvOK(ST(2)) && looks_like_number(ST(2)))
                (void)hv_stores(p, "total", pmcp_num(aTHX_ ST(2)));
            if (items > 3 && SvOK(ST(3)))
                (void)hv_stores(p, "message", pmcp_str(aTHX_ ST(3)));
            ok = pmcp_sse_notify(aTHX_ st, "notifications/progress",
                                 newRV_noinc((SV *)p));
        }
    }
    SP = PL_stack_base + ax - 1;
    ST(0) = sv_2mortal(newSViv(ok));
    XSRETURN(1);
}

/* Punk::Logger's level for each of MCP's eight, in PMCP_LOG_NAME order. */
static const char *const PMCP_LOG_PUNK[] = {
    "debug", "info", "info", "warn", "error", "fatal", "fatal", "fatal"
};

/* The record mcp_log hands the request logger: a plain hash's keys as fields,
 * a plain array under data, anything else as the message, and the logger name
 * as a field unless the hash has one. The caller's hash is copied, not
 * touched. +1 */
static SV *pmcp_log_record(pTHX_ SV *data, SV *logger)
{
    HV *r = newHV();

    if (SvROK(data) && !sv_isobject(data) && SvTYPE(SvRV(data)) == SVt_PVHV) {
        HV *from = (HV *)SvRV(data);
        HE *he;
        hv_iterinit(from);
        while ((he = hv_iternext(from)))
            (void)hv_store_ent(r, hv_iterkeysv(he), newSVsv(hv_iterval(from, he)), 0);
    }
    else if (SvROK(data) && !sv_isobject(data))
        (void)hv_stores(r, "data", newSVsv(data));
    else
        (void)hv_stores(r, "message", newSVsv(data));
    if (logger && SvOK(logger) && !hv_exists(r, "logger", 6))
        (void)hv_stores(r, "logger", newSVsv(logger));
    return newRV_noinc((SV *)r);
}

/* $c->log->$level($record), whatever the client asked for and whether or not
 * there is a client to send to. */
static void pmcp_log_app(pTHX_ SV *c, int level, SV *data, SV *logger)
{
    SV *log = sv_2mortal(pmcp_call_method(aTHX_ c, "log", NULL, 0, G_SCALAR, NULL));
    SV *rec;

    if (!SvROK(log)) return;
    rec = sv_2mortal(pmcp_log_record(aTHX_ data, logger));
    SvREFCNT_dec(pmcp_call_method(aTHX_ log, PMCP_LOG_PUNK[level], &rec, 1, G_SCALAR, NULL));
}

/* $c->mcp_log($level, $data, $logger?): writes the request logger, then sends
 * to the client. 1 when sent, 0 below the client's level or with nowhere to
 * send it. An unknown level croaks: it is a bug in the caller. */
XS_INTERNAL(pmcp_helper_log)
{
    dXSARGS;
    HV *call, *st, *p;
    int level, ok = 0;
    STRLEN l;
    const char *lp;

    if (items < 3) croak("%s: mcp_log takes a level and the data", PMCP_WHO);
    lp = SvOK(ST(1)) ? SvPV_const(ST(1), l) : "";
    if (!SvOK(ST(1))) l = 0;
    level = pmcp_log_level_of(lp, l);
    if (level < 0)
        croak("%s: mcp_log level '%.*s' is not one of debug, info, notice, "
              "warning, error, critical, alert, emergency", PMCP_WHO, (int)l, lp);
    pmcp_log_app(aTHX_ ST(0), level, ST(2), items > 3 ? ST(3) : NULL);
    st = pmcp_call_stream(aTHX_ ST(0), &call);
    if (st && SvTRUE(pmcp_hget(aTHX_ st, "logging") ? pmcp_hget(aTHX_ st, "logging") : &PL_sv_no)) {
        SV *min = pmcp_hget(aTHX_ st, "level");
        if (level >= (min ? SvIV(min) : PMCP_LOG_DEFAULT)) {
            p = newHV();
            (void)hv_stores(p, "level", newSVpv(PMCP_LOG_NAME[level], 0));
            (void)hv_stores(p, "data", newSVsv(ST(2)));
            if (items > 3 && SvOK(ST(3)))
                (void)hv_stores(p, "logger", pmcp_str(aTHX_ ST(3)));
            ok = pmcp_sse_notify(aTHX_ st, "notifications/message", newRV_noinc((SV *)p));
        }
    }
    SP = PL_stack_base + ax - 1;
    ST(0) = sv_2mortal(newSViv(ok));
    XSRETURN(1);
}

#endif /* PMCP_SSE_H */

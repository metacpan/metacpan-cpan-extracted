/* pmcp_sess.h - Mcp-Session-Id sessions, kept in a shared Punk::Cache store.
 *
 * Needs: pmcp_http.h, pmcp_rand.h.
 *
 * Off by default (`session => 0`, the owner's ruling of 23 Oct). With
 * `session => NAME` the store NAME must be declared with `cache` and shared
 * across the worker pool, or boot croaks naming it: a session written on one
 * worker and missing on the next is a 404 at random.
 *
 * A record is JSON under pmcp:s:<id>:
 *
 *   v          the negotiated protocol version
 *   client     clientInfo, as initialize sent it
 *   caps       the client's capabilities
 *   level      the minimum log level, a PMCP_LOG_* index
 *   subs       subscribed resource URIs (10)
 *   principal  a digest of the credential that made it
 *   created, seen, exp   epoch seconds
 *
 * Reads go to the store's backend, past any per-worker memory tier, as
 * Punk's own session store and Punk::Plugin::Idempotency do: a tier that has
 * not seen a write answers "no session", which is a 404 for a live one. Writes
 * go through the store, which updates the backend and invalidates the tiers.
 *
 * The record's own `exp` is the expiry that counts. The store's TTL is set to
 * match and only backs it up.
 */

#ifndef PMCP_SESS_H
#define PMCP_SESS_H

#define PMCP_SLIDE_SECS   60   /* a read moves expiry forward at most this often */
#define PMCP_ADDR_PER_MIN 30   /* initialize calls per address per minute */

/* Now, in seconds. $Punk::Plugin::MCP::_NOW stands in for the clock in t/34. */
static NV pmcp_now(pTHX)
{
    SV *k = get_sv("Punk::Plugin::MCP::_NOW", 0);
    return (k && SvOK(k)) ? SvNV(k) : (NV)time(NULL);
}

static int pmcp_sessions_on(pTHX_ HV *opts)
{
    SV *s = pmcp_hget(aTHX_ opts, "session");
    return s && SvTRUE(s);
}

/* The store, through a context, or NULL with sessions off. Mortal. */
static SV *pmcp_sess_store(pTHX_ SV *c, HV *opts)
{
    SV *name;
    SV *s;
    if (!pmcp_sessions_on(aTHX_ opts)) return NULL;
    name = pmcp_hget(aTHX_ opts, "session");
    s = pmcp_call_method(aTHX_ c, "cache", &name, 1, G_SCALAR, NULL);
    return s ? sv_2mortal(s) : NULL;
}

/* At to_app: the named store exists and is shared, or croak. Asked through a
 * context built for the purpose, since the getter lives on the context and
 * the `cache` keyword on the app declares rather than fetches. */
static void pmcp_sess_boot_check(pTHX_ SV *app, HV *opts)
{
    SV *name = pmcp_hget(aTHX_ opts, "session");
    SV *argv[3], *c, *err = NULL, *store, *backend, *shared;
    HV *match;
    int ok = 0;

    if (!pmcp_sessions_on(aTHX_ opts)) return;
    match = newHV();
    (void)hv_stores(match, "captures", newRV_noinc((SV *)newHV()));
    argv[0] = sv_2mortal(newRV_noinc((SV *)newHV()));
    argv[1] = app;
    argv[2] = sv_2mortal(newRV_noinc((SV *)match));
    c = sv_2mortal(pmcp_call_method(aTHX_ sv_2mortal(newSVpvs("Punk::Context")),
                                    "_build", argv, 3, G_SCALAR, NULL));
    store = pmcp_call_method(aTHX_ c, "cache", &name, 1, G_SCALAR, &err);
    if (!store) {
        SvREFCNT_dec(err);
        croak("%s: `session => '%" SVf "'` names a store that is not declared "
              "(add cache %" SVf " => { backend => 'file', ... })", PMCP_WHO,
              SVfARG(name), SVfARG(name));
    }
    sv_2mortal(store);
    backend = pmcp_call_method(aTHX_ store, "backend", NULL, 0, G_SCALAR, NULL);
    if (backend) {
        sv_2mortal(backend);
        if (SvOK(backend) && pmcp_can(aTHX_ backend, "is_shared")) {
            shared = pmcp_call_method(aTHX_ backend, "is_shared", NULL, 0, G_SCALAR, NULL);
            ok = shared && SvTRUE(shared);
            if (shared) SvREFCNT_dec(shared);
        }
    }
    if (!ok)
        croak("%s: the session store '%" SVf "' is not shared across workers, so "
              "a session made on one would be missing on the next. Use a shared "
              "backend (the file one is)", PMCP_WHO, SVfARG(name));
}

/* ---- the record ----------------------------------------------------------------- */

static SV *pmcp_sess_key(pTHX_ SV *sid)
{
    return sv_2mortal(newSVpvf("pmcp:s:%" SVf, SVfARG(sid)));
}

/* A header value that could be one of our ids: 22 base64url characters. Anything
 * else is not looked up at all. */
static int pmcp_sid_ok(pTHX_ SV *sid)
{
    STRLEN l, i;
    const char *p;
    if (!sid || !SvOK(sid) || SvROK(sid)) return 0;
    p = SvPV_nomg_const(sid, l);
    if (l != PMCP_ID_CHARS) return 0;
    for (i = 0; i < l; i++)
        if (pmcp_b64url_val(p[i]) < 0) return 0;
    return 1;
}

/* The record, or NULL when absent or expired. Mortal HV. */
static HV *pmcp_sess_load(pTHX_ SV *store, SV *sid, NV now)
{
    SV *backend, *bytes, *doc, *exp;
    SV *key = pmcp_sess_key(aTHX_ sid);
    backend = pmcp_call_method(aTHX_ store, "backend", NULL, 0, G_SCALAR, NULL);
    if (!backend) return NULL;
    sv_2mortal(backend);
    bytes = pmcp_call_method(aTHX_ backend, "get", &key, 1, G_SCALAR, NULL);
    if (!bytes) return NULL;
    sv_2mortal(bytes);
    if (!SvOK(bytes)) return NULL;
    doc = pmcp_rpc_decode(aTHX_ bytes);
    if (!doc) return NULL;
    sv_2mortal(doc);
    if (!pmcp_is_hash(doc)) return NULL;
    exp = pmcp_hget(aTHX_ (HV *)SvRV(doc), "exp");
    if (!exp || SvNV(exp) <= now) return NULL;
    return (HV *)SvRV(doc);
}

static void pmcp_sess_save(pTHX_ SV *store, SV *sid, HV *rec, IV ttl)
{
    SV *rv = sv_2mortal(newRV_inc((SV *)rec));
    SV *err = NULL;
    SV *bytes = pmcp_json_trapped(aTHX_ rv, &err);
    SV *argv[3], *r;
    if (!bytes) {
        sv_2mortal(err);
        croak("%s: a session record is not JSON: %" SVf, PMCP_WHO, SVfARG(err));
    }
    argv[0] = pmcp_sess_key(aTHX_ sid);
    argv[1] = sv_2mortal(bytes);
    argv[2] = sv_2mortal(newSViv(ttl));
    r = pmcp_call_method(aTHX_ store, "set", argv, 3, G_SCALAR, NULL);
    if (r) SvREFCNT_dec(r);
}

static void pmcp_sess_drop(pTHX_ SV *store, SV *sid)
{
    SV *key = pmcp_sess_key(aTHX_ sid);
    SV *r = pmcp_call_method(aTHX_ store, "delete", &key, 1, G_SCALAR, NULL);
    if (r) SvREFCNT_dec(r);
}

/* Who the request is: a digest of its credential, so a session id taken from
 * one caller is no use to another. 11 refines it with `principal`. Mortal. */
static SV *pmcp_principal(pTHX_ HV *env)
{
    SV *auth = pmcp_env_get(aTHX_ env, "HTTP_AUTHORIZATION");
    SV *arg = auth ? auth : sv_2mortal(newSVpvs(""));
    SV *fn = sv_2mortal(newSVpvs("Digest::SHA::sha256_hex"));
    SV *r;
    static int loaded = 0;
    if (!loaded) {
        SV *err = NULL;
        if (!pmcp_require(aTHX_ "Digest::SHA", &err)) {
            sv_2mortal(err);
            croak("%s: sessions need Digest::SHA: %" SVf, PMCP_WHO, SVfARG(err));
        }
        loaded = 1;
    }
    r = pmcp_call_sv(aTHX_ fn, &arg, 1, G_SCALAR, NULL);
    return sv_2mortal(r);
}

/* A new session for an initialize that succeeded. Returns the id, mortal. */
static SV *pmcp_sess_create(pTHX_ SV *store, HV *opts, HV *env, HV *params,
                            enum pmcp_ver v, NV now)
{
    SV *sid = sv_2mortal(pmcp_rand_id(aTHX));
    IV ttl = SvIV(pmcp_hget(aTHX_ opts, "session_ttl"));
    HV *rec = (HV *)sv_2mortal((SV *)newHV());
    SV **x;
    (void)hv_stores(rec, "v", newSVpv(PMCP_VER_NAME[v], 0));
    if (params && (x = hv_fetchs(params, "clientInfo", 0)) && pmcp_is_hash(*x))
        (void)hv_stores(rec, "client", newSVsv(*x));
    if (params && (x = hv_fetchs(params, "capabilities", 0)) && pmcp_is_hash(*x))
        (void)hv_stores(rec, "caps", newSVsv(*x));
    (void)hv_stores(rec, "level", newSViv(PMCP_LOG_DEFAULT));
    (void)hv_stores(rec, "subs", newRV_noinc((SV *)newAV()));
    (void)hv_stores(rec, "principal", newSVsv(pmcp_principal(aTHX_ env)));
    (void)hv_stores(rec, "created", newSViv((IV)now));
    (void)hv_stores(rec, "seen", newSViv((IV)now));
    (void)hv_stores(rec, "exp", newSViv((IV)now + ttl));
    pmcp_sess_save(aTHX_ store, sid, rec, ttl);
    return sid;
}

/* After a request in a session: a level the client set, and the slide. The
 * slide writes at most once a PMCP_SLIDE_SECS, so most requests only read. */
static void pmcp_sess_after(pTHX_ SV *store, HV *opts, SV *sid, HV *rec,
                            int level_set, NV now)
{
    IV ttl = SvIV(pmcp_hget(aTHX_ opts, "session_ttl"));
    SV *seen = pmcp_hget(aTHX_ rec, "seen");
    int write = 0;
    if (level_set >= 0) {
        (void)hv_stores(rec, "level", newSViv(level_set));
        write = 1;
    }
    if (!seen || now - SvNV(seen) >= PMCP_SLIDE_SECS) {
        (void)hv_stores(rec, "seen", newSViv((IV)now));
        (void)hv_stores(rec, "exp", newSViv((IV)now + ttl));
        write = 1;
    }
    if (write) pmcp_sess_save(aTHX_ store, sid, rec, ttl);
}

/* ---- bounding creation ------------------------------------------------------------- */

static IV pmcp_counter(pTHX_ SV *store, SV *key)
{
    SV *backend = pmcp_call_method(aTHX_ store, "backend", NULL, 0, G_SCALAR, NULL);
    SV *v;
    IV n = 0;
    if (!backend) return 0;
    sv_2mortal(backend);
    v = pmcp_call_method(aTHX_ backend, "get", &key, 1, G_SCALAR, NULL);
    if (v) {
        if (SvOK(v) && looks_like_number(v)) n = SvIV(v);
        SvREFCNT_dec(v);
    }
    return n;
}

static void pmcp_counter_set(pTHX_ SV *store, SV *key, IV n, IV ttl)
{
    SV *argv[3], *r;
    argv[0] = key;
    argv[1] = sv_2mortal(newSViv(n));
    argv[2] = sv_2mortal(newSViv(ttl));
    r = pmcp_call_method(aTHX_ store, "set", argv, 3, G_SCALAR, NULL);
    if (r) SvREFCNT_dec(r);
}

/* May this initialize make a session? 0 when it may, else the HTTP status
 * (503 at the cap, 429 for an address over its rate) with *retry set.
 *
 * The cap counts sessions made in the last session_ttl, from two window
 * counters, the previous one weighted by how much of it still overlaps. Expiry
 * is lazy, so live records cannot be counted without a scan, and a DELETE does
 * not hand a slot back: both err towards refusing. The counters are a read and
 * a write, not atomic, so a burst across workers can overshoot by a few. */
static int pmcp_sess_limits(pTHX_ SV *store, HV *opts, HV *env, NV now, IV *retry)
{
    IV ttl = SvIV(pmcp_hget(aTHX_ opts, "session_ttl"));
    IV max = SvIV(pmcp_hget(aTHX_ opts, "max_sessions"));
    IV w = (IV)(now / (NV)ttl);
    NV into = (now - (NV)w * (NV)ttl) / (NV)ttl;
    SV *kcur = sv_2mortal(newSVpvf("pmcp:n:%" IVdf, w));
    SV *kprev = sv_2mortal(newSVpvf("pmcp:n:%" IVdf, w - 1));
    IV cur = pmcp_counter(aTHX_ store, kcur), prev = pmcp_counter(aTHX_ store, kprev);
    SV *addr = pmcp_env_get(aTHX_ env, "REMOTE_ADDR");
    IV minute = (IV)(now / 60.0);
    SV *ka = sv_2mortal(newSVpvf("pmcp:a:%s:%" IVdf, addr ? SvPV_nolen(addr) : "-", minute));
    IV a = pmcp_counter(aTHX_ store, ka);

    if ((NV)cur + (NV)prev * (1.0 - into) >= (NV)max) {
        *retry = (IV)((1.0 - into) * (NV)ttl) + 1;
        return 503;
    }
    if (a >= PMCP_ADDR_PER_MIN) {
        *retry = 60 - (IV)(now - (NV)minute * 60.0);
        return 429;
    }
    pmcp_counter_set(aTHX_ store, kcur, cur + 1, ttl * 2);
    pmcp_counter_set(aTHX_ store, ka, a + 1, 120);
    return 0;
}

/* ---- around the dispatch ------------------------------------------------------------- */

/* A refusal with Retry-After. +1 */
static SV *pmcp_refuse_retry(pTHX_ int status, const char *why, IV retry, int cors)
{
    SV *out = pmcp_http_refuse(aTHX_ status, why, cors);
    AV *h = (AV *)SvRV(*av_fetch((AV *)SvRV(out), 1, 0));
    av_push(h, newSVpvs("Retry-After"));
    av_push(h, newSViv(retry > 0 ? retry : 1));
    return out;
}

/* Before the dispatch. NULL to carry on (with *s filled), or the refusal (+1):
 *
 *   initialize with no session id   may make one, within the limits
 *   initialize with one             dispatched, and refused there (-32600)
 *   anything else                   needs a live session of this caller's:
 *                                   none 400, unknown or someone else's 404
 *
 * A message that is not JSON-RPC at all is left to the dispatcher's 400. */
static SV *pmcp_sess_begin(pTHX_ SV *c, pmcp_server *ps, HV *env, pmcp_msg *m,
                           pmcp_sess_t *s, int cors)
{
    SV *store = pmcp_sess_store(aTHX_ c, ps->opts), *sid, *pv;
    NV now;
    HV *rec;
    int is_init;

    if (!store || m->kind == PMCP_K_INVALID) return NULL;
    s->store = store;
    now = pmcp_now(aTHX);
    sid = pmcp_env_get(aTHX_ env, "HTTP_MCP_SESSION_ID");
    is_init = m->kind == PMCP_K_REQUEST && m->mlen == 10
              && memEQ(m->method, "initialize", 10);

    if (is_init) {
        IV retry = 0;
        int status;
        if (sid) { s->in_session = 1; return NULL; }
        status = pmcp_sess_limits(aTHX_ store, ps->opts, env, now, &retry);
        if (status == 503)
            return pmcp_refuse_retry(aTHX_ 503, "too many sessions, try again later",
                                     retry, cors);
        if (status == 429)
            return pmcp_refuse_retry(aTHX_ 429, "too many new sessions from this address",
                                     retry, cors);
        s->creating = 1;
        return NULL;
    }

    if (!sid) return pmcp_http_refuse(aTHX_ 400, "a session id is required", cors);
    rec = pmcp_sid_ok(aTHX_ sid) ? pmcp_sess_load(aTHX_ store, sid, now) : NULL;
    if (!rec || !sv_eq(pmcp_hget(aTHX_ rec, "principal"), pmcp_principal(aTHX_ env)))
        return pmcp_http_refuse(aTHX_ 404, "unknown session", cors);
    {
        SV *rv = pmcp_hget(aTHX_ rec, "v");
        STRLEN l;
        const char *p = rv ? SvPV_const(rv, l) : "";
        enum pmcp_ver stored = rv ? pmcp_version_of(p, l) : PMCP_V_NONE;
        pv = pmcp_env_get(aTHX_ env, "HTTP_MCP_PROTOCOL_VERSION");
        if (pv && !sv_eq(pv, rv))
            return pmcp_http_refuse(aTHX_ 400,
                "MCP-Protocol-Version does not match the session's", cors);
        if (stored != PMCP_V_NONE) s->v = stored;
    }
    s->sid = sv_2mortal(newSVsv(sid));
    s->rec = rec;
    {
        SV *lv = pmcp_hget(aTHX_ rec, "level");
        s->level = lv ? (int)SvIV(lv) : PMCP_LOG_DEFAULT;
    }
    return NULL;
}

/* After the dispatch, or before a stream (r NULL). Returns the id of a session
 * just made, for the Mcp-Session-Id header (mortal), or NULL. */
static SV *pmcp_sess_end(pTHX_ pmcp_server *ps, HV *env, pmcp_sess_t *s,
                         pmcp_req *r, pmcp_msg *m)
{
    NV now;
    if (!s->store) return NULL;
    now = pmcp_now(aTHX);
    if (s->creating) {
        /* only an initialize that negotiated: an error made no session */
        if (r && r->negotiated)
            return pmcp_sess_create(aTHX_ s->store, ps->opts, env, m->params,
                                    r->negotiated, now);
        return NULL;
    }
    if (s->sid && s->rec)
        pmcp_sess_after(aTHX_ s->store, ps->opts, s->sid, s->rec,
                        r ? r->level_set : -1, now);
    return NULL;
}

/* A level set by logging/setLevel in a stream, which ends after the handler has
 * returned: the session record is read again and written, or with no session
 * the server's own level is set (stdio, 13). */
static void pmcp_level_set(pTHX_ SV *c, pmcp_server *ps, SV *sid, int level)
{
    SV *store;
    HV *rec;
    if (!sid) { ps->srv.log_level = level; return; }
    store = pmcp_sess_store(aTHX_ c, ps->opts);
    rec = store ? pmcp_sess_load(aTHX_ store, sid, pmcp_now(aTHX)) : NULL;
    if (rec) pmcp_sess_after(aTHX_ store, ps->opts, sid, rec, level, pmcp_now(aTHX));
}

/* ---- DELETE ---------------------------------------------------------------------- */

/* A session ended by DELETE: its GET stream is closed, here or over the bus.
 * Defined in pmcp_bus.h. */
static void pmcp_session_closed(pTHX_ pmcp_server *ps, SV *c, SV *sid);

/* DELETE on the MCP path. cap = [server, guards] */
XS_INTERNAL(pmcp_delete_cb)
{
    dXSARGS;
    SV *c = items > 0 ? ST(0) : &PL_sv_undef;
    pmcp_server *ps = pmcp_server_of(aTHX_ pmcp_cap(aTHX_ cv, 0));
    SV *gslot = pmcp_cap(aTHX_ cv, 1);
    AV *guards = (gslot && pmcp_is_array(gslot)) ? (AV *)SvRV(gslot) : NULL;
    SV *envsv = sv_2mortal(pmcp_call_method(aTHX_ c, "env", NULL, 0, G_SCALAR, NULL));
    HV *env = (HV *)SvRV(envsv);
    int cors = pmcp_env_get(aTHX_ env, "HTTP_ORIGIN") != NULL;
    SV *out = NULL, *sid, *store;
    HV *rec;
    NV now = pmcp_now(aTHX);

    if (!pmcp_origin_ok(aTHX_ env, ps->opts)) {
        out = pmcp_http_refuse(aTHX_ 403, "origin not allowed", cors);
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
    rec = (store && pmcp_sid_ok(aTHX_ sid)) ? pmcp_sess_load(aTHX_ store, sid, now) : NULL;
    if (!rec || !sv_eq(pmcp_hget(aTHX_ rec, "principal"), pmcp_principal(aTHX_ env))) {
        out = pmcp_http_refuse(aTHX_ 404, "unknown session", cors);
        goto answer;
    }
    pmcp_sess_drop(aTHX_ store, sid);
    pmcp_session_closed(aTHX_ ps, c, sid);
    out = pmcp_http_answer(aTHX_ 204, NULL, cors);

answer:
    SP = PL_stack_base + ax - 1;
    ST(0) = sv_2mortal(out);
    XSRETURN(1);
}

#endif /* PMCP_SESS_H */

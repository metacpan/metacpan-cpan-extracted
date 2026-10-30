/* pmcp_proto.h - the protocol core: versions, initialize, ping, notifications,
 * and the dispatcher every transport shares.
 *
 * Needs: pmcp_rpc.h.
 * Gives: pmcp_srv (what a server says about itself), pmcp_req (one message's
 * state), pmcp_dispatch (bytes in, bytes out).
 *
 * pmcp_dispatch is the whole of the protocol below the transport. HTTP (07),
 * the SSE answer (08) and stdio (13) all hand it the body and send back what it
 * gives, so none of them knows a method name.
 */

#ifndef PMCP_PROTO_H
#define PMCP_PROTO_H

/* ---- versions ------------------------------------------------------------ */

/* In order, so a later version compares greater. */
enum pmcp_ver {
    PMCP_V_NONE = 0,
    PMCP_V_2025_03_26,
    PMCP_V_2025_06_18,
    PMCP_V_2025_11_25
};
#define PMCP_V_LATEST PMCP_V_2025_11_25

static const char *const PMCP_VER_NAME[] = {
    NULL, "2025-03-26", "2025-06-18", "2025-11-25"
};

/* The version a string names, or PMCP_V_NONE. */
static enum pmcp_ver pmcp_version_of(const char *s, STRLEN l)
{
    int i;
    if (l != 10) return PMCP_V_NONE;
    for (i = PMCP_V_2025_03_26; i <= PMCP_V_LATEST; i++)
        if (memEQ(s, PMCP_VER_NAME[i], 10)) return (enum pmcp_ver)i;
    return PMCP_V_NONE;
}

/* ---- what a server says about itself ------------------------------------- */

/* Borrowed SVs, held by whoever owns the server (the frozen app state, 04).
 * Any of them may be NULL. */
typedef struct {
    SV *name;
    SV *title;
    SV *version;
    SV *description;
    SV *website;
    SV *icons;          /* an array ref, checked by 04 */
    SV *instructions;
    unsigned has_tools     : 1;
    unsigned has_resources : 1;
    unsigned has_prompts   : 1;
    unsigned logging       : 1;
    /* The transport can carry a notification the client did not ask for:
     * sessions with a GET stream on HTTP, or stdio. Without it subscribe and
     * logging would be promises nothing can keep, so neither is advertised. */
    unsigned can_notify    : 1;
    /* the frozen tables (pmcp_decl.h, pmcp_res.h, pmcp_prompt.h), each NULL
     * when nothing of that kind is declared */
    void *tools;
    void *resources;
    void *prompts;
    /* the innermost app, for an OpenAPI tool to re-enter (12), owned */
    SV *psgi;
    /* The minimum log level logging/setLevel asked for, a PMCP_LOG_* index.
     * Per server until sessions (09) keep one per session, and per process on
     * stdio (13). */
    int log_level;
} pmcp_srv;

/* RFC 5424 severities, in order, as MCP names them. */
static const char *const PMCP_LOG_NAME[] = {
    "debug", "info", "notice", "warning", "error", "critical", "alert",
    "emergency", NULL
};
#define PMCP_LOG_DEFAULT 1   /* info */

static int pmcp_log_level_of(const char *p, STRLEN l)
{
    int i;
    for (i = 0; PMCP_LOG_NAME[i]; i++)
        if (strlen(PMCP_LOG_NAME[i]) == l && memEQ(PMCP_LOG_NAME[i], p, l)) return i;
    return -1;
}

/* ---- one message ---------------------------------------------------------- */

typedef struct {
    /* in: from the transport */
    enum pmcp_ver version;     /* negotiated, or the header's, for this call */
    unsigned in_session : 1;   /* the request carried a live session id      */
    unsigned stdio : 1;        /* over `punk mcp`: the process is the session */
    SV *c;                     /* the request's context, borrowed, or NULL   */
    SV *stream;                /* the SSE stream's state hash, borrowed (08) */
    SV *session;               /* the session id, borrowed, or NULL (09)     */

    /* out: set by a handler */
    enum pmcp_ver negotiated;  /* initialize: what was agreed                */
    SV *cancelled;             /* notifications/cancelled: the requestId, +1 */
    SV *raw;                   /* a result already encoded, +1 (the tools)  */
    SV *id;                    /* the request's id, borrowed, while it runs  */
    int level_set;             /* logging/setLevel: the level asked, or -1  */
    unsigned tool_error : 1;   /* tools/call: the result has isError        */

    /* a handler that fails sets these and returns NULL */
    int         ecode;
    const char *emsg;
    SV         *edata;         /* +1, or NULL */
} pmcp_req;

static void pmcp_req_init(pmcp_req *r, enum pmcp_ver v, int in_session)
{
    Zero(r, 1, pmcp_req);
    r->version = v;
    r->in_session = in_session ? 1 : 0;
    r->level_set = -1;
}

static void pmcp_req_free(pTHX_ pmcp_req *r)
{
    if (r->cancelled) SvREFCNT_dec(r->cancelled);
    if (r->edata) SvREFCNT_dec(r->edata);
    if (r->raw) SvREFCNT_dec(r->raw);
    r->cancelled = r->edata = r->raw = NULL;
}

static SV *pmcp_fail(pmcp_req *r, int code, const char *msg)
{
    r->ecode = code;
    r->emsg = msg;
    return NULL;
}

/* A handler answers a request with a result (+1, encoded by the dispatcher) or
 * NULL after pmcp_fail. A notification handler's return is discarded. */
typedef SV *(*pmcp_handler)(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params);

/* ---- initialize ----------------------------------------------------------- */

static SV *pmcp_initialize(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    HV *res, *caps, *info;
    enum pmcp_ver v = PMCP_V_LATEST;
    SV **pv;

    /* A second initialize on a live session is a client that lost track. It is
     * refused rather than renegotiated under the other requests' feet. */
    if (r->in_session)
        return pmcp_fail(r, PMCP_REQUEST, "session already initialized");
    res = newHV();
    caps = newHV();
    info = newHV();

    /* The client's version when this server speaks it, otherwise the latest,
     * and the client decides whether it can live with that. */
    pv = params ? hv_fetchs(params, "protocolVersion", 0) : NULL;
    if (pv && pmcp_is_str(*pv)) {
        STRLEN l;
        const char *p = SvPV_const(*pv, l);
        enum pmcp_ver asked = pmcp_version_of(p, l);
        if (asked != PMCP_V_NONE) v = asked;
    }
    r->negotiated = v;

    /* Only what was declared, and only what the transport can deliver. No
     * listChanged anywhere: the lists are frozen at to_app (P6). */
    if (s->has_tools)
        (void)hv_stores(caps, "tools", newRV_noinc((SV *)newHV()));
    if (s->has_resources) {
        HV *rc = newHV();
        if (s->can_notify || r->stdio) (void)hv_stores(rc, "subscribe", pmcp_bool(aTHX_ 1));
        (void)hv_stores(caps, "resources", newRV_noinc((SV *)rc));
    }
    if (s->has_prompts)
        (void)hv_stores(caps, "prompts", newRV_noinc((SV *)newHV()));
    if (s->logging && (s->can_notify || r->stdio))
        (void)hv_stores(caps, "logging", newRV_noinc((SV *)newHV()));

    /* serverInfo grows with the version: title in 2025-06-18, description,
     * websiteUrl and icons in 2025-11-25. An older client gets none of them. */
    (void)hv_stores(info, "name",
                    s->name ? pmcp_str(aTHX_ s->name) : newSVpvs("punk"));
    (void)hv_stores(info, "version",
                    s->version ? pmcp_str(aTHX_ s->version) : newSVpvs("0"));
    if (v >= PMCP_V_2025_06_18 && s->title)
        (void)hv_stores(info, "title", pmcp_str(aTHX_ s->title));
    if (v >= PMCP_V_2025_11_25) {
        if (s->description)
            (void)hv_stores(info, "description", pmcp_str(aTHX_ s->description));
        if (s->website)
            (void)hv_stores(info, "websiteUrl", pmcp_str(aTHX_ s->website));
        if (s->icons) (void)hv_stores(info, "icons", newSVsv(s->icons));
    }

    (void)hv_stores(res, "protocolVersion", newSVpv(PMCP_VER_NAME[v], 0));
    (void)hv_stores(res, "capabilities", newRV_noinc((SV *)caps));
    (void)hv_stores(res, "serverInfo", newRV_noinc((SV *)info));
    if (s->instructions)
        (void)hv_stores(res, "instructions", pmcp_str(aTHX_ s->instructions));
    return newRV_noinc((SV *)res);
}

static SV *pmcp_ping(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    PERL_UNUSED_ARG(s);
    PERL_UNUSED_ARG(r);
    PERL_UNUSED_ARG(params);
    return newRV_noinc((SV *)newHV());
}

static SV *pmcp_on_initialized(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    PERL_UNUSED_CONTEXT;
    PERL_UNUSED_ARG(s);
    PERL_UNUSED_ARG(r);
    PERL_UNUSED_ARG(params);
    return NULL;
}

/* Defined in pmcp_sse.h: flag a call streaming on this worker as cancelled. */
static void pmcp_live_cancel(pTHX_ SV *sid, SV *id);

/* Recorded for the transport, and honoured when the call is streaming on this
 * worker. Anywhere else it is accepted and ignored (16). */
static SV *pmcp_on_cancelled(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    SV **e = params ? hv_fetchs(params, "requestId", 0) : NULL;
    PERL_UNUSED_ARG(s);
    if (e && pmcp_id_ok(*e) && !r->cancelled) {
        r->cancelled = newSVsv(*e);
        pmcp_live_cancel(aTHX_ r->session, *e);
    }
    return NULL;
}

/* logging/setLevel. Only where a log message could reach the client: with
 * logging on and a transport that can notify. Elsewhere the method does not
 * exist, as the capability was never advertised. */
static SV *pmcp_set_level(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    SV **lv = params ? hv_fetchs(params, "level", 0) : NULL;
    int level;
    STRLEN l;
    const char *p;
    if (!(s->logging && (s->can_notify || r->stdio)))
        return pmcp_fail(r, PMCP_METHOD, "method not found");
    if (!(lv && pmcp_is_str(*lv)))
        return pmcp_fail(r, PMCP_PARAMS, "a level is required");
    p = SvPV_const(*lv, l);
    level = pmcp_log_level_of(p, l);
    if (level < 0) return pmcp_fail(r, PMCP_PARAMS, "unknown log level");
    r->level_set = level;
    return newRV_noinc((SV *)newHV());
}

/* ---- the table ------------------------------------------------------------ */

/* Defined in pmcp_call.h, pmcp_res.h and pmcp_prompt.h, which need the
 * tables this header precedes. */
static SV *pmcp_tools_list(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params);
static SV *pmcp_tools_call(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params);
static SV *pmcp_resources_list(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params);
static SV *pmcp_resources_templates(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params);
static SV *pmcp_resources_read(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params);
static SV *pmcp_resources_subscribe(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params);
static SV *pmcp_resources_unsubscribe(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params);
static SV *pmcp_prompts_list(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params);
static SV *pmcp_prompts_get(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params);

#define PMCP_REQ  1   /* answers a request      */
#define PMCP_NOTE 2   /* handles a notification */

typedef struct {
    const char  *name;
    STRLEN       len;
    int          kind;
    pmcp_handler fn;
} pmcp_method;

/* Sorted by length, then by bytes. Later phases add rows in place, keeping the
 * order, and t/12 checks it. */
#define PMCP_M(s, k, f) { s, sizeof(s) - 1, k, f }
static const pmcp_method PMCP_METHODS[] = {
    PMCP_M("ping",                      PMCP_REQ,  pmcp_ping),
    PMCP_M("initialize",                PMCP_REQ,  pmcp_initialize),
    PMCP_M("tools/call",                PMCP_REQ,  pmcp_tools_call),
    PMCP_M("tools/list",                PMCP_REQ,  pmcp_tools_list),
    PMCP_M("prompts/get",               PMCP_REQ,  pmcp_prompts_get),
    PMCP_M("prompts/list",              PMCP_REQ,  pmcp_prompts_list),
    PMCP_M("resources/list",            PMCP_REQ,  pmcp_resources_list),
    PMCP_M("resources/read",            PMCP_REQ,  pmcp_resources_read),
    PMCP_M("logging/setLevel",          PMCP_REQ,  pmcp_set_level),
    PMCP_M("resources/subscribe",       PMCP_REQ,  pmcp_resources_subscribe),
    PMCP_M("resources/unsubscribe",     PMCP_REQ,  pmcp_resources_unsubscribe),
    PMCP_M("notifications/cancelled",   PMCP_NOTE, pmcp_on_cancelled),
    PMCP_M("resources/templates/list",  PMCP_REQ,  pmcp_resources_templates),
    PMCP_M("notifications/initialized", PMCP_NOTE, pmcp_on_initialized),
};
#undef PMCP_M
#define PMCP_N_METHODS (sizeof PMCP_METHODS / sizeof PMCP_METHODS[0])

static int pmcp_method_cmp(const char *a, STRLEN al, const pmcp_method *m)
{
    if (al != m->len) return al < m->len ? -1 : 1;
    return memcmp(a, m->name, al);
}

static const pmcp_method *pmcp_method_find(const char *name, STRLEN len)
{
    size_t lo = 0, hi = PMCP_N_METHODS;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        int c = pmcp_method_cmp(name, len, &PMCP_METHODS[mid]);
        if (c == 0) return &PMCP_METHODS[mid];
        if (c < 0) hi = mid; else lo = mid + 1;
    }
    return NULL;
}

/* ---- the dispatcher ------------------------------------------------------- */

#define PMCP_HTTP_OK          200
#define PMCP_HTTP_ACCEPTED    202
#define PMCP_HTTP_BAD_REQUEST 400

/* One body in, the answer out. Returns the reply bytes (+1), or NULL when
 * nothing is owed. *status is what HTTP should send: 200 with a reply, 202 for
 * a notification or response, 400 for a body that is not JSON-RPC. stdio
 * ignores it. */
static SV *pmcp_dispatch_doc(pTHX_ const pmcp_srv *s, pmcp_req *r, SV *doc,
                             int *status);
static SV *pmcp_otel_start(pTHX_ pmcp_req *r, const char *method, STRLEN mlen,
                           HV *params, SV **tracer);
static void pmcp_otel_end(pTHX_ pmcp_req *r, SV *span, SV *tracer, int ecode);

static SV *pmcp_dispatch(pTHX_ const pmcp_srv *s, pmcp_req *r, SV *bytes,
                         int *status)
{
    SV *doc = pmcp_rpc_decode(aTHX_ bytes), *reply;
    if (!doc) {
        *status = PMCP_HTTP_BAD_REQUEST;
        return pmcp_rpc_error(aTHX_ NULL, PMCP_PARSE, "parse error", NULL);
    }
    reply = pmcp_dispatch_doc(aTHX_ s, r, doc, status);
    SvREFCNT_dec(doc);
    return reply;
}

/* The same, for a document already decoded (the HTTP transport decodes once
 * to decide whether to stream). `doc` is borrowed. */
static SV *pmcp_dispatch_doc(pTHX_ const pmcp_srv *s, pmcp_req *r, SV *doc,
                             int *status)
{
    SV *reply = NULL;
    pmcp_msg m;
    const pmcp_method *meth;

    ENTER; SAVETMPS;
    pmcp_rpc_classify(aTHX_ doc, &m);
    r->id = m.id;

    switch (m.kind) {
    case PMCP_K_INVALID:
        *status = PMCP_HTTP_BAD_REQUEST;
        reply = pmcp_rpc_error(aTHX_ m.id, m.err_code, m.err_msg, NULL);
        break;

    case PMCP_K_RESPONSE:
        *status = PMCP_HTTP_ACCEPTED;
        break;

    case PMCP_K_NOTIFY:
        /* An unknown notification, or a request method sent with no id, is
         * dropped: a notification is never answered, not even with an error. */
        *status = PMCP_HTTP_ACCEPTED;
        meth = pmcp_method_find(m.method, m.mlen);
        if (meth && meth->kind == PMCP_NOTE) {
            SV *ignored = meth->fn(aTHX_ s, r, m.params);
            if (ignored) SvREFCNT_dec(ignored);
        }
        break;

    case PMCP_K_REQUEST:
        *status = PMCP_HTTP_OK;
        meth = pmcp_method_find(m.method, m.mlen);
        if (!meth || meth->kind != PMCP_REQ) {
            reply = pmcp_rpc_error(aTHX_ m.id, PMCP_METHOD, "method not found",
                                   NULL);
            break;
        }
        {
            SV *tracer, *span = pmcp_otel_start(aTHX_ r, m.method, m.mlen, m.params, &tracer);
            SV *result = meth->fn(aTHX_ s, r, m.params);
            if (span)
                pmcp_otel_end(aTHX_ r, span, tracer, (result || r->raw) ? 0
                              : (r->ecode ? r->ecode : PMCP_INTERNAL));
            if (result) {
                reply = pmcp_rpc_result(aTHX_ m.id, result);
            }
            else if (r->raw) {
                reply = pmcp_rpc_result_bytes(aTHX_ m.id, r->raw);
            }
            else {
                SV *data = r->edata;
                r->edata = NULL;
                reply = pmcp_rpc_error(aTHX_ m.id,
                                       r->ecode ? r->ecode : PMCP_INTERNAL,
                                       r->emsg ? r->emsg : "internal error",
                                       data);
            }
        }
        break;
    }

    r->id = NULL;               /* borrowed from doc, which the caller owns */
    FREETMPS; LEAVE;
    return reply;
}

#endif /* PMCP_PROTO_H */

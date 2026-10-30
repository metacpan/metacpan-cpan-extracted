/* pmcp_call.h - tools/list and tools/call.
 *
 * Needs: pmcp_decl.h, pmcp_page.h.
 *
 * A tool call runs the declared action the way a route runs it: a context of
 * the request's class, built with Punk::Context->_build over the request's env
 * and app, holding a copy of the request's stash (so what `auth` stashed is
 * there) and the arguments as its OpenAPI params (so $c->param reads them).
 * The action cannot tell a tool call from a web call except through $c->mcp.
 *
 * Whatever the action returns is turned into a tool result here. A die is a
 * result with isError, not a protocol error: the call was well formed and that
 * is its answer, and the model is the one that has to read it.
 */

#ifndef PMCP_CALL_H
#define PMCP_CALL_H

#define PMCP_CALL_CLASS "Punk::MCP::Call"
#define PMCP_STASH_CALL "mcp.call"
#define PMCP_REFUSAL_MAX 300

/* Defined in pmcp_sse.h: tell a call object about the stream it runs in. */
static void pmcp_call_attach(pTHX_ pmcp_req *r, SV *call);
/* Defined in pmcp_oa.h: an OpenAPI tool's request, answered by the app. */
static SV *pmcp_oa_call(pTHX_ SV *psgi, pmcp_tool *t, SV *c, HV *args, SV **why);

/* ---- small builders --------------------------------------------------------- */

/* [{type => 'text', text => TEXT}] +1 */
static SV *pmcp_text_content(pTHX_ SV *text)
{
    AV *a = newAV();
    HV *b = newHV();
    (void)hv_stores(b, "type", newSVpvs("text"));
    (void)hv_stores(b, "text", text);
    av_push(a, newRV_noinc((SV *)b));
    return newRV_noinc((SV *)a);
}

/* {content => [text], isError => true}, plus structuredContent when given and
 * the version has it. Takes ownership of text and structured. +1 */
static SV *pmcp_tool_error(pTHX_ SV *text, SV *structured, enum pmcp_ver v)
{
    HV *r = newHV();
    (void)hv_stores(r, "content", pmcp_text_content(aTHX_ text));
    (void)hv_stores(r, "isError", pmcp_bool(aTHX_ 1));
    if (structured && v >= PMCP_V_2025_06_18)
        (void)hv_stores(r, "structuredContent", structured);
    else if (structured) SvREFCNT_dec(structured);
    return newRV_noinc((SV *)r);
}

/* A die's text, without the " at FILE line N." perl added, which names this
 * dist's caller rather than anything the model can use. +1 */
static SV *pmcp_die_text(pTHX_ SV *err)
{
    SV *t;
    STRLEN l;
    const char *p;
    if (SvROK(err) && !SvAMAGIC(err)) return newSVpvs("the tool failed");
    t = newSVsv(err);
    p = SvPV_const(t, l);
    while (l && (p[l - 1] == '\n' || p[l - 1] == ' ')) l--;
    /* the last " at ", if what follows it is "FILE line N." */
    if (l && p[l - 1] == '.') {
        STRLEN i = l;
        while (i >= 4) {
            i--;
            if (memEQ(p + i - 3, " at ", 4)) {
                const char *tail = p + i + 1;
                STRLEN tl = l - (i + 1);
                static const char ln[] = " line ";
                if (tl < 300 && ninstr(tail, tail + tl, ln, ln + 6))
                    l = i - 3;
                break;
            }
        }
    }
    SvCUR_set(t, l);
    return t;
}

/* ---- the call object -------------------------------------------------------- */

static SV *pmcp_call_object(pTHX_ const char *method, SV *name, SV *args,
                            enum pmcp_ver v, HV *params)
{
    HV *h = newHV();
    SV **meta = params ? hv_fetchs(params, "_meta", 0) : NULL;
    (void)hv_stores(h, "method", newSVpv(method, 0));
    if (name) (void)hv_stores(h, "name", newSVsv(name));
    (void)hv_stores(h, "arguments", args ? newSVsv(args) : newSV(0));
    (void)hv_stores(h, "protocol",
                    v ? newSVpv(PMCP_VER_NAME[v], 0) : newSV(0));
    if (meta && pmcp_is_hash(*meta)) {
        SV **pt = hv_fetchs((HV *)SvRV(*meta), "progressToken", 0);
        if (pt && pmcp_id_ok(*pt))
            (void)hv_stores(h, "progress_token", newSVsv(*pt));
    }
    (void)hv_stores(h, "cancelled", newSViv(0));
    return sv_bless(newRV_noinc((SV *)h), gv_stashpvs(PMCP_CALL_CLASS, GV_ADD));
}

/* ---- the child context --------------------------------------------------------- */

static SV *pmcp_meth0(pTHX_ SV *obj, const char *m)
{
    return pmcp_call_method(aTHX_ obj, m, NULL, 0, G_SCALAR, NULL);
}

/* A context for one call, as described above. +1 */
static SV *pmcp_child_context(pTHX_ SV *c, const char *kind, SV *name,
                              SV *args, SV *call)
{
    SV *env = sv_2mortal(pmcp_meth0(aTHX_ c, "env"));
    SV *app = sv_2mortal(pmcp_meth0(aTHX_ c, "app"));
    SV *stash = sv_2mortal(pmcp_meth0(aTHX_ c, "stash"));
    HV *match = newHV(), *op = newHV(), *copy;
    SV *argv[3], *child, *r;
    const char *class = HvNAME(SvSTASH(SvRV(c)));

    (void)hv_stores(match, "captures", newRV_noinc((SV *)newHV()));
    (void)hv_store(match, kind, (I32)strlen(kind), newSVsv(name), 0);
    argv[0] = env;
    argv[1] = app;
    argv[2] = sv_2mortal(newRV_noinc((SV *)match));
    child = pmcp_call_method(aTHX_ sv_2mortal(newSVpv(class, 0)), "_build",
                             argv, 3, G_SCALAR, NULL);

    copy = pmcp_is_hash(stash) ? newHVhv((HV *)SvRV(stash)) : newHV();
    (void)hv_stores(copy, PMCP_STASH_CALL, newSVsv(call));
    argv[0] = sv_2mortal(newRV_noinc((SV *)copy));
    r = pmcp_call_method(aTHX_ child, "stash_hv", argv, 1, G_SCALAR, NULL);
    SvREFCNT_dec(r);

    (void)hv_stores(op, "query", newSVsv(args));
    argv[0] = sv_2mortal(newRV_noinc((SV *)op));
    r = pmcp_call_method(aTHX_ child, "openapi_params", argv, 1, G_SCALAR, NULL);
    SvREFCNT_dec(r);
    return child;
}

/* ---- guards ----------------------------------------------------------------- */

/* A refusal's words: the body of the response a guard returned, if it is short
 * text, with the status. +1 */
static SV *pmcp_refusal_text(pTHX_ SV *resp)
{
    SV *out = newSVpvs("refused");
    if (pmcp_is_array(resp) && av_len((AV *)SvRV(resp)) >= 2) {
        AV *t = (AV *)SvRV(resp);
        SV **st = av_fetch(t, 0, 0), **bd = av_fetch(t, 2, 0);
        if (st && SvOK(*st)) sv_catpvf(out, " (%" IVdf ")", SvIV(*st));
        if (bd && pmcp_is_array(*bd)) {
            AV *b = (AV *)SvRV(*bd);
            SSize_t i, n = av_len(b) + 1;
            SV *body = sv_2mortal(newSVpvs(""));
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(b, i, 0);
                if (e && SvOK(*e) && !SvROK(*e)) sv_catsv(body, *e);
            }
            if (SvCUR(body) && SvCUR(body) <= PMCP_REFUSAL_MAX) {
                sv_catpvs(out, ": ");
                sv_catsv(out, body);
            }
        }
    }
    return out;
}

/* Run a declaration's guards over `ctx`. NULL when every one passes, else the
 * reason (+1): a refusal's words, or a die's text. */
static SV *pmcp_run_guards(pTHX_ AV *guards, SV *ctx)
{
    SSize_t i, n;
    if (!guards) return NULL;
    n = av_len(guards) + 1;
    for (i = 0; i < n; i++) {
        SV *g = *av_fetch(guards, i, 0), *err = NULL, *r;
        r = pmcp_call_sv(aTHX_ g, &ctx, 1, G_SCALAR, &err);
        if (!r) {
            SV *t = pmcp_die_text(aTHX_ err);
            SvREFCNT_dec(err);
            return t;
        }
        if (SvROK(r)) {
            SV *t = pmcp_refusal_text(aTHX_ r);
            SvREFCNT_dec(r);
            return t;
        }
        SvREFCNT_dec(r);
    }
    return NULL;
}

/* ---- tools/list ------------------------------------------------------------- */

typedef struct { pmcp_tools *ts; SV *c; } pmcp_list_ctx;

static int pmcp_tool_visible(pTHX_ void *vctx, IV i)
{
    pmcp_list_ctx *x = (pmcp_list_ctx *)vctx;
    SV *why;
    if (!x->ts->t[i].guards) return 1;
    if (!x->c) return 0;           /* no request to judge it by: hidden */
    why = pmcp_run_guards(aTHX_ x->ts->t[i].guards, x->c);
    if (!why) return 1;
    SvREFCNT_dec(why);
    return 0;
}

static enum pmcp_ver pmcp_req_version(const pmcp_req *r)
{
    return r->version ? r->version : PMCP_V_2025_03_26;
}

static SV *pmcp_tools_list(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    pmcp_tools *ts = (pmcp_tools *)s->tools;
    enum pmcp_ver v = pmcp_req_version(r);
    SV **cur = params ? hv_fetchs(params, "cursor", 0) : NULL;
    IV start = 0;
    pmcp_list_ctx x;

    if (!ts) return pmcp_fail(r, PMCP_METHOD, "method not found");
    if (cur && SvOK(*cur)) {
        start = pmcp_cursor_read(aTHX_ *cur, ts->n);
        if (start < 0) return pmcp_fail(r, PMCP_PARAMS, "invalid cursor");
    }
    x.ts = ts;
    x.c = r->c;
    r->raw = pmcp_page_bytes(aTHX_ "tools", ts->list[v], ts->n, start,
                             ts->page_size,
                             ts->any_guard ? pmcp_tool_visible : NULL, &x);
    return NULL;
}

/* ---- turning what the action returned into a result ----------------------------- */

static int pmcp_is_triplet(pTHX_ SV *sv)
{
    AV *a;
    SV **st, **h, **b;
    if (!pmcp_is_array(sv)) return 0;
    a = (AV *)SvRV(sv);
    if (av_len(a) != 2) return 0;
    st = av_fetch(a, 0, 0);
    h = av_fetch(a, 1, 0);
    b = av_fetch(a, 2, 0);
    return st && SvOK(*st) && !SvROK(*st) && looks_like_number(*st)
        && SvIV(*st) >= 100 && SvIV(*st) <= 599
        && h && pmcp_is_array(*h) && b && SvROK(*b);
}

/* A triplet's body as one string, or NULL when it is a filehandle. Mortal. */
static SV *pmcp_triplet_body(pTHX_ AV *t, int *is_json)
{
    SV **h = av_fetch(t, 1, 0), **b = av_fetch(t, 2, 0);
    AV *hd = (AV *)SvRV(*h);
    SSize_t i, n = av_len(hd) + 1;
    SV *body;
    *is_json = 0;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(hd, i, 0), **v = av_fetch(hd, i + 1, 0);
        if (k && v && SvOK(*k) && strcasecmp(SvPV_nolen(*k), "Content-Type") == 0
            && instr(SvPV_nolen(*v), "json"))
            *is_json = 1;
    }
    if (!pmcp_is_array(*b)) return NULL;
    body = sv_2mortal(newSVpvs(""));
    n = av_len((AV *)SvRV(*b)) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch((AV *)SvRV(*b), i, 0);
        if (e && SvOK(*e) && !SvROK(*e)) sv_catsv(body, *e);
    }
    return body;
}

/* The result for a value. *err is set (+1) for a value that cannot be a
 * result at all, which the caller answers -32603. +1 */
static SV *pmcp_result_of(pTHX_ pmcp_tool *t, SV *val, enum pmcp_ver v,
                          int depth, SV **err);

/* A Future, awaited on the child context, within the tool's timeout. +1 */
static SV *pmcp_await_result(pTHX_ pmcp_tool *t, SV *child, SV *f,
                             enum pmcp_ver v, int depth, SV **err)
{
    SV *wait = f, *e = NULL, *vals, *val;
    int ready_now = 0;
    {
        SV *r = pmcp_meth0(aTHX_ f, "is_ready");
        ready_now = r && SvTRUE(r);
        if (r) SvREFCNT_dec(r);
    }
    /* Only a Future still pending races the timer. Off a Hyperman worker
     * $c->timer sleeps when it is made, so racing a settled Future would cost
     * the whole timeout for nothing. */
    if (t->timeout > 0 && !ready_now) {
        SV *argv[2], *timer;
        argv[0] = sv_2mortal(newSVnv(t->timeout));
        timer = pmcp_call_method(aTHX_ child, "timer", argv, 1, G_SCALAR, &e);
        if (timer) {
            sv_2mortal(timer);
            argv[0] = f;
            argv[1] = timer;
            wait = pmcp_call_method(aTHX_ sv_2mortal(newSVpvs("Punk::Future")),
                                    "wait_any", argv, 2, G_SCALAR, &e);
            if (wait) sv_2mortal(wait);
        }
        if (e) {
            SV *msg = pmcp_die_text(aTHX_ e);
            SvREFCNT_dec(e);
            return pmcp_tool_error(aTHX_ msg, NULL, v);
        }
    }
    vals = pmcp_call_method(aTHX_ child, "await", &wait, 1, G_LIST, &e);
    if (!vals) {
        SV *msg = pmcp_die_text(aTHX_ e);
        SvREFCNT_dec(e);
        return pmcp_tool_error(aTHX_ msg, NULL, v);
    }
    sv_2mortal(vals);
    if (wait != f) {
        SV *ready = pmcp_meth0(aTHX_ f, "is_ready");
        int done = ready && SvTRUE(ready);
        if (ready) SvREFCNT_dec(ready);
        if (!done) {
            SV *r = pmcp_meth0(aTHX_ f, "cancel");
            if (r) SvREFCNT_dec(r);
            return pmcp_tool_error(aTHX_
                newSVpvf("timed out after %" NVgf " seconds", t->timeout), NULL, v);
        }
        vals = pmcp_call_method(aTHX_ f, "get", NULL, 0, G_LIST, &e);
        if (!vals) {
            SV *msg = pmcp_die_text(aTHX_ e);
            SvREFCNT_dec(e);
            return pmcp_tool_error(aTHX_ msg, NULL, v);
        }
        sv_2mortal(vals);
    }
    {
        SV **first = av_fetch((AV *)SvRV(vals), 0, 0);
        val = first ? *first : &PL_sv_undef;
    }
    return pmcp_result_of(aTHX_ t, val, v, depth + 1, err);
}

static SV *pmcp_errors_text(pTHX_ AV *errs, const char *lead);

/* structured: a hash. The result carries it and its JSON as text, and is
 * checked against the output schema. +1 */
static SV *pmcp_structured_result(pTHX_ pmcp_tool *t, SV *hash, enum pmcp_ver v,
                                  SV **err)
{
    HV *r;
    SV *text = pmcp_json_trapped(aTHX_ hash, err);
    if (!text) return NULL;
    if (t->output && v >= PMCP_V_2025_06_18) {
        AV *errs = newAV();
        if (!PMCP_JSF->validate(aTHX_ t->output, hash, errs)) {
            /* the errors as text: as structuredContent they would not match
             * the schema either */
            SV *msg = pmcp_errors_text(aTHX_ errs,
                "the tool's result does not match its output schema");
            SvREFCNT_dec((SV *)errs);
            SvREFCNT_dec(text);
            return pmcp_tool_error(aTHX_ msg, NULL, v);
        }
        SvREFCNT_dec((SV *)errs);
    }
    r = newHV();
    (void)hv_stores(r, "content", pmcp_text_content(aTHX_ text));
    if (v >= PMCP_V_2025_06_18)
        (void)hv_stores(r, "structuredContent", newSVsv(hash));
    return newRV_noinc((SV *)r);
}

static SV *pmcp_result_of(pTHX_ pmcp_tool *t, SV *val, enum pmcp_ver v,
                          int depth, SV **err)
{
    if (depth > 4) {
        *err = newSVpvs("a result nested too deep");
        return NULL;
    }

    /* an output schema promises structured content, so nothing else will do */
    if (t->output && v >= PMCP_V_2025_06_18 && !pmcp_is_hash(val)
        && !pmcp_is_triplet(aTHX_ val))
        return pmcp_tool_error(aTHX_
            newSVpvs("the tool has an output schema and returned no object"),
            NULL, v);

    if (!SvOK(val)) {
        HV *r = newHV();
        (void)hv_stores(r, "content", newRV_noinc((SV *)newAV()));
        return newRV_noinc((SV *)r);
    }
    if (!SvROK(val) || SvAMAGIC(val)) {
        HV *r = newHV();
        (void)hv_stores(r, "content", pmcp_text_content(aTHX_ pmcp_str(aTHX_ val)));
        return newRV_noinc((SV *)r);
    }
    if (pmcp_is_triplet(aTHX_ val)) {
        AV *tr = (AV *)SvRV(val);
        IV status = SvIV(*av_fetch(tr, 0, 0));
        int is_json;
        SV *body = pmcp_triplet_body(aTHX_ tr, &is_json);
        SV *res, *doc = NULL;
        if (body && is_json && SvCUR(body)) {
            doc = pmcp_rpc_decode(aTHX_ body);
            if (doc) sv_2mortal(doc);
        }
        if (doc && pmcp_is_hash(doc) && status < 400)
            res = pmcp_structured_result(aTHX_ t, doc, v, err);
        else {
            HV *r = newHV();
            (void)hv_stores(r, "content", pmcp_text_content(aTHX_
                body ? newSVsv(body) : newSVpvs("")));
            res = newRV_noinc((SV *)r);
        }
        if (!res) return NULL;
        if (status >= 400)
            (void)hv_stores((HV *)SvRV(res), "isError", pmcp_bool(aTHX_ 1));
        {
            HV *meta = newHV();
            (void)hv_stores(meta, "status", newSViv(status));
            (void)hv_stores((HV *)SvRV(res), "_meta", newRV_noinc((SV *)meta));
        }
        return res;
    }
    if (pmcp_is_hash(val)) {
        HV *h = (HV *)SvRV(val);
        /* already a tool result: passed through, isError made a boolean */
        if (hv_exists(h, "content", 7)) {
            HV *copy = newHVhv(h);
            SV **ie = hv_fetchs(copy, "isError", 0);
            if (ie) (void)hv_stores(copy, "isError", pmcp_bool(aTHX_ SvTRUE(*ie)));
            if (v < PMCP_V_2025_06_18) (void)hv_deletes(copy, "structuredContent", G_DISCARD);
            return newRV_noinc((SV *)copy);
        }
        return pmcp_structured_result(aTHX_ t, val, v, err);
    }
    if (pmcp_is_array(val)) {
        HV *r;
        SV *text = pmcp_json_trapped(aTHX_ val, err);
        if (!text) return NULL;
        r = newHV();
        (void)hv_stores(r, "content", pmcp_text_content(aTHX_ text));
        return newRV_noinc((SV *)r);
    }
    *err = newSVpvf("the tool returned a %s reference", sv_reftype(SvRV(val), 0));
    return NULL;
}

/* ---- tools/call --------------------------------------------------------------- */

/* The validation errors as one line for the model, after `lead`. +1 */
static SV *pmcp_errors_text(pTHX_ AV *errs, const char *lead)
{
    SV *out = newSVpvf("%s:", lead);
    SSize_t i, n = av_len(errs) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(errs, i, 0);
        SV *loc, *msg;
        if (!(e && pmcp_is_hash(*e))) continue;
        loc = pmcp_hget(aTHX_ (HV *)SvRV(*e), "instanceLocation");
        msg = pmcp_hget(aTHX_ (HV *)SvRV(*e), "message");
        sv_catpvf(out, "%s %s%s%s", i ? ";" : "",
                  (loc && SvCUR(loc)) ? SvPV_nolen(loc) : "/",
                  msg ? " " : "", msg ? SvPV_nolen(msg) : "");
    }
    return out;
}

/* The result as bytes, for the dispatcher to splice. Encoded through the
 * trapped encoder, since it may hold anything the action returned. */
static SV *pmcp_tool_answer(pTHX_ pmcp_req *r, SV *result)
{
    SV *err = NULL;
    if (pmcp_is_hash(result)) {
        SV **ie = hv_fetchs((HV *)SvRV(result), "isError", 0);
        if (ie && SvTRUE(*ie)) r->tool_error = 1;
    }
    SV *bytes = pmcp_json_trapped(aTHX_ result, &err);
    SvREFCNT_dec(result);
    if (!bytes) {
        SvREFCNT_dec(err);
        return pmcp_fail(r, PMCP_INTERNAL, "the tool's result is not JSON");
    }
    r->raw = bytes;
    return NULL;
}

static SV *pmcp_tools_call(pTHX_ const pmcp_srv *s, pmcp_req *r, HV *params)
{
    pmcp_tools *ts = (pmcp_tools *)s->tools;
    enum pmcp_ver v = pmcp_req_version(r);
    SV **nv = params ? hv_fetchs(params, "name", 0) : NULL;
    SV **av = params ? hv_fetchs(params, "arguments", 0) : NULL;
    SV *args, *call, *child, *why, *ret, *err = NULL, *result;
    pmcp_tool *t;

    if (!ts) return pmcp_fail(r, PMCP_METHOD, "method not found");
    if (!(nv && pmcp_is_str(*nv)))
        return pmcp_fail(r, PMCP_PARAMS, "a tool name is required");
    t = pmcp_tool_find(aTHX_ ts, *nv);
    if (!t) return pmcp_fail(r, PMCP_PARAMS, "unknown tool");
    if (av && SvOK(*av) && !pmcp_is_hash(*av))
        return pmcp_fail(r, PMCP_PARAMS, "arguments must be an object");
    if (!r->c) return pmcp_fail(r, PMCP_INTERNAL, "no request to call the tool in");

    args = (av && SvOK(*av)) ? *av : sv_2mortal(newRV_noinc((SV *)newHV()));
    call = sv_2mortal(pmcp_call_object(aTHX_ "tools/call", t->name, args, v, params));
    pmcp_call_attach(aTHX_ r, call);
    child = sv_2mortal(pmcp_child_context(aTHX_ r->c, "tool", t->name, args, call));

    /* the tool's own guard, after the endpoint's and before anything else */
    if ((why = pmcp_run_guards(aTHX_ t->guards, child)))
        return pmcp_tool_answer(aTHX_ r, pmcp_tool_error(aTHX_ why, NULL, v));

    {
        AV *errs = newAV();
        if (!PMCP_JSF->validate(aTHX_ t->input, args, errs)) {
            SV *rv = newRV_noinc((SV *)errs);
            /* 2025-11-25 made this a tool error, so the model can fix its
             * arguments and try again. Before it, a protocol error (P5). */
            if (v >= PMCP_V_2025_11_25) {
                SV *data = NULL;
                SV *text = pmcp_errors_text(aTHX_ errs, "invalid arguments");
                /* structuredContent must match an output schema, which the
                 * errors never do, so such a tool has them as text alone */
                if (t->output) SvREFCNT_dec(rv);
                else {
                    data = newRV_noinc((SV *)newHV());
                    (void)hv_stores((HV *)SvRV(data), "errors", rv);
                }
                return pmcp_tool_answer(aTHX_ r, pmcp_tool_error(aTHX_ text, data, v));
            }
            r->edata = newRV_noinc((SV *)newHV());
            (void)hv_stores((HV *)SvRV(r->edata), "errors", rv);
            return pmcp_fail(r, PMCP_PARAMS, "invalid arguments");
        }
        SvREFCNT_dec((SV *)errs);
    }

    /* an OpenAPI tool is a request the application answers (12) */
    if (t->oa_path) {
        SV *why2 = NULL;
        SV *val = s->psgi ? pmcp_oa_call(aTHX_ s->psgi, t, r->c, (HV *)SvRV(args), &why2)
                          : NULL;
        if (!val)
            return pmcp_tool_answer(aTHX_ r, pmcp_tool_error(aTHX_
                why2 ? why2 : newSVpvs("the application is not ready"), NULL, v));
        err = NULL;
        result = pmcp_result_of(aTHX_ t, val, v, 0, &err);
        if (!result) {
            SvREFCNT_dec(err);
            return pmcp_fail(r, PMCP_INTERNAL, "the tool's result is not JSON");
        }
        return pmcp_tool_answer(aTHX_ r, result);
    }

    ret = pmcp_call_sv(aTHX_ t->target, &child, 1, G_SCALAR, &err);
    if (!ret)
        return pmcp_tool_answer(aTHX_ r,
            pmcp_tool_error(aTHX_ pmcp_die_text(aTHX_ sv_2mortal(err)), NULL, v));
    sv_2mortal(ret);

    err = NULL;
    if (SvROK(ret) && sv_derived_from(ret, "Punk::Future"))
        result = pmcp_await_result(aTHX_ t, child, ret, v, 0, &err);
    else
        result = pmcp_result_of(aTHX_ t, ret, v, 0, &err);
    if (!result) {
        SvREFCNT_dec(err);
        return pmcp_fail(r, PMCP_INTERNAL, "the tool's result is not JSON");
    }
    return pmcp_tool_answer(aTHX_ r, result);
}

/* ---- settling a value, for resources and prompts --------------------------------- */

/* What an action returned, with a Future awaited within `timeout` seconds.
 * Returns the value (mortal), or NULL with *why set (+1) to a failure's text:
 * a failed Future, a die in the await, or the timeout. The same rules as
 * pmcp_await_result, without a tool result around them. */
static SV *pmcp_settle(pTHX_ SV *child, SV *ret, NV timeout, SV **why)
{
    SV *wait = ret, *e = NULL, *vals, **first;
    int ready_now;

    *why = NULL;
    if (!(SvROK(ret) && sv_derived_from(ret, "Punk::Future"))) return ret;
    {
        SV *r = pmcp_meth0(aTHX_ ret, "is_ready");
        ready_now = r && SvTRUE(r);
        if (r) SvREFCNT_dec(r);
    }
    if (timeout > 0 && !ready_now) {
        SV *argv[2], *timer;
        argv[0] = sv_2mortal(newSVnv(timeout));
        timer = pmcp_call_method(aTHX_ child, "timer", argv, 1, G_SCALAR, &e);
        if (timer) {
            sv_2mortal(timer);
            argv[0] = ret;
            argv[1] = timer;
            wait = pmcp_call_method(aTHX_ sv_2mortal(newSVpvs("Punk::Future")),
                                    "wait_any", argv, 2, G_SCALAR, &e);
            if (wait) sv_2mortal(wait);
        }
        if (e) { *why = pmcp_die_text(aTHX_ e); SvREFCNT_dec(e); return NULL; }
    }
    vals = pmcp_call_method(aTHX_ child, "await", &wait, 1, G_LIST, &e);
    if (!vals) { *why = pmcp_die_text(aTHX_ e); SvREFCNT_dec(e); return NULL; }
    sv_2mortal(vals);
    if (wait != ret) {
        SV *ready = pmcp_meth0(aTHX_ ret, "is_ready");
        int done = ready && SvTRUE(ready);
        if (ready) SvREFCNT_dec(ready);
        if (!done) {
            SV *r = pmcp_meth0(aTHX_ ret, "cancel");
            if (r) SvREFCNT_dec(r);
            *why = newSVpvf("timed out after %" NVgf " seconds", timeout);
            return NULL;
        }
        vals = pmcp_call_method(aTHX_ ret, "get", NULL, 0, G_LIST, &e);
        if (!vals) { *why = pmcp_die_text(aTHX_ e); SvREFCNT_dec(e); return NULL; }
        sv_2mortal(vals);
    }
    first = av_fetch((AV *)SvRV(vals), 0, 0);
    return first ? *first : &PL_sv_undef;
}

/* Run a declaration's action over a child context and settle the result.
 * Returns the value (mortal), or NULL with *why (+1) for a die or a failure. */
static SV *pmcp_run_action(pTHX_ SV *target, SV *child, NV timeout, SV **why)
{
    SV *err = NULL;
    SV *ret = pmcp_call_sv(aTHX_ target, &child, 1, G_SCALAR, &err);
    if (!ret) {
        *why = pmcp_die_text(aTHX_ err);
        SvREFCNT_dec(err);
        return NULL;
    }
    sv_2mortal(ret);
    return pmcp_settle(aTHX_ child, ret, timeout, why);
}

/* ---- context helpers ------------------------------------------------------------ */

/* A stash key of a context, borrowed, or NULL. Through stash_hv, the raw slot,
 * so asking does not vivify a stash on a request that never had one. */
static SV *pmcp_stash_get(pTHX_ SV *c, const char *k)
{
    SV *st = pmcp_call_method(aTHX_ c, "stash_hv", NULL, 0, G_SCALAR, NULL);
    SV *v = NULL;
    if (st && pmcp_is_hash(st)) {
        SV **e = hv_fetch((HV *)SvRV(st), k, (I32)strlen(k), 0);
        if (e && SvOK(*e)) v = sv_2mortal(newSVsv(*e));
    }
    if (st) SvREFCNT_dec(st);
    return v;
}

/* $c->mcp: the call object inside a tool call, undef anywhere else. */
XS_INTERNAL(pmcp_helper_mcp)
{
    dXSARGS;
    SV *call = items > 0 ? pmcp_stash_get(aTHX_ ST(0), PMCP_STASH_CALL) : NULL;
    ST(0) = call ? call : &PL_sv_undef;
    XSRETURN(1);
}

/* $c->mcp_user: what `principal` returned (11), else $c->current_user, else
 * undef. current_user is asked under G_EVAL: an application with no login
 * session may not have one to ask. */
XS_INTERNAL(pmcp_helper_mcp_user)
{
    dXSARGS;
    SV *u = NULL;
    if (items > 0) {
        SV *c = ST(0);
        u = pmcp_stash_get(aTHX_ c, "mcp.user");
        if (!u && pmcp_can(aTHX_ c, "current_user")) {
            SV *err = NULL;
            SV *r = pmcp_call_method(aTHX_ c, "current_user", NULL, 0,
                                     G_SCALAR, &err);
            if (r) u = sv_2mortal(r);
            else SvREFCNT_dec(err);
        }
    }
    SP = PL_stack_base + ax - 1;
    ST(0) = u ? u : &PL_sv_undef;
    XSRETURN(1);
}

#endif /* PMCP_CALL_H */

/* pmcp_otel.h - a span per MCP request, under Punk-OpenTelemetry.
 *
 * Needs: pmcp_clos.h, pmcp_rpc.h, pmcp_proto.h.
 *
 * Punk-OpenTelemetry names the request's server span from its route, so every
 * call would read `POST /mcp`. Each request with an id gets a child span of
 * that one instead, named and attributed as the OpenTelemetry MCP conventions
 * say: "{mcp.method.name} {target}", where the target is the tool or prompt
 * name, kind SERVER, with mcp.method.name, gen_ai.tool.name or
 * gen_ai.prompt.name, mcp.resource.uri, jsonrpc.request.id, mcp.session.id and
 * mcp.protocol.version. A JSON-RPC error sets error.type to its code and the
 * status to ERROR. A tool result with isError sets error.type tool_error and
 * leaves the status alone, since the call worked.
 *
 * Nothing happens without the plugin (the context has no otel_span method),
 * when the request was not sampled (otel_span is undef), or over stdio (no
 * server span to hang it on).
 */

#ifndef PMCP_OTEL_H
#define PMCP_OTEL_H

#define PMCP_OTEL_KIND_SERVER 2
#define PMCP_OTEL_STATUS_ERROR 2

static void pmcp_otel_attr(pTHX_ SV *span, const char *k, SV *v)
{
    SV *argv[2], *r;
    if (!v || !SvOK(v)) return;
    argv[0] = sv_2mortal(newSVpv(k, 0));
    argv[1] = v;
    r = pmcp_call_method(aTHX_ span, "attr", argv, 2, G_SCALAR, NULL);
    if (r) SvREFCNT_dec(r);
}

/* The span, mortal, or NULL. *tracer is set mortal alongside it. */
static SV *pmcp_otel_start(pTHX_ pmcp_req *r, const char *method, STRLEN mlen,
                           HV *params, SV **tracer)
{
    SV *ref, *tid, *sid, *span, *argv[5], *name, *err = NULL;
    HV *parent, *stash;
    SV *target = NULL, *uri = NULL;

    *tracer = NULL;
    if (!r->c || r->stdio || !SvROK(r->c) || !SvOBJECT(SvRV(r->c))) return NULL;
    stash = SvSTASH(SvRV(r->c));
    if (!gv_fetchmethod_autoload(stash, "otel_span", 0)) return NULL;

    ref = pmcp_call_method(aTHX_ r->c, "otel_span", NULL, 0, G_SCALAR, &err);
    if (!ref) { SvREFCNT_dec(err); return NULL; }
    sv_2mortal(ref);
    if (!SvROK(ref)) return NULL;
    *tracer = pmcp_call_method(aTHX_ r->c, "otel", NULL, 0, G_SCALAR, &err);
    if (!*tracer) { SvREFCNT_dec(err); return NULL; }
    sv_2mortal(*tracer);
    if (!SvROK(*tracer)) { *tracer = NULL; return NULL; }

    tid = pmcp_call_method(aTHX_ ref, "trace_id", NULL, 0, G_SCALAR, NULL);
    sid = pmcp_call_method(aTHX_ ref, "span_id", NULL, 0, G_SCALAR, NULL);
    parent = newHV();
    (void)hv_stores(parent, "trace_id", tid ? tid : newSV(0));
    (void)hv_stores(parent, "span_id", sid ? sid : newSV(0));
    (void)hv_stores(parent, "sampled", newSViv(1));

    if (params) {
        SV **nv = hv_fetchs(params, "name", 0);
        SV **uv = hv_fetchs(params, "uri", 0);
        if (nv && pmcp_is_str(*nv)) target = *nv;
        if (uv && pmcp_is_str(*uv)) uri = *uv;
    }
    name = sv_2mortal(newSVpvn(method, mlen));
    if (target) sv_catpvf(name, " %" SVf, SVfARG(target));

    argv[0] = name;
    argv[1] = sv_2mortal(newSVpvs("kind"));
    argv[2] = sv_2mortal(newSViv(PMCP_OTEL_KIND_SERVER));
    argv[3] = sv_2mortal(newSVpvs("parent"));
    argv[4] = sv_2mortal(newRV_noinc((SV *)parent));
    span = pmcp_call_method(aTHX_ *tracer, "start", argv, 5, G_SCALAR, &err);
    if (!span) { SvREFCNT_dec(err); *tracer = NULL; return NULL; }
    sv_2mortal(span);
    if (!SvROK(span)) { *tracer = NULL; return NULL; }

    pmcp_otel_attr(aTHX_ span, "mcp.method.name", sv_2mortal(newSVpvn(method, mlen)));
    if (target)
        pmcp_otel_attr(aTHX_ span, (mlen == 11 && memEQ(method, "prompts/get", 11))
                                   ? "gen_ai.prompt.name" : "gen_ai.tool.name", target);
    if (uri) pmcp_otel_attr(aTHX_ span, "mcp.resource.uri", uri);
    if (r->id) pmcp_otel_attr(aTHX_ span, "jsonrpc.request.id", sv_2mortal(newSVpvf("%" SVf, SVfARG(r->id))));
    if (r->session) pmcp_otel_attr(aTHX_ span, "mcp.session.id", r->session);
    pmcp_otel_attr(aTHX_ span, "mcp.protocol.version",
                   sv_2mortal(newSVpv(PMCP_VER_NAME[r->version], 0)));
    return span;
}

/* End the span and queue it. ecode is the JSON-RPC error code, or 0. */
static void pmcp_otel_end(pTHX_ pmcp_req *r, SV *span, SV *tracer, int ecode)
{
    SV *argv[2], *ret;
    if (!span || !tracer) return;
    if (ecode) {
        pmcp_otel_attr(aTHX_ span, "error.type", sv_2mortal(newSVpvf("%d", ecode)));
        argv[0] = sv_2mortal(newSViv(PMCP_OTEL_STATUS_ERROR));
        argv[1] = sv_2mortal(newSVpv(r->emsg ? r->emsg : "error", 0));
        ret = pmcp_call_method(aTHX_ span, "status", argv, 2, G_SCALAR, NULL);
        if (ret) SvREFCNT_dec(ret);
    }
    else if (r->tool_error) {
        pmcp_otel_attr(aTHX_ span, "error.type", sv_2mortal(newSVpvs("tool_error")));
    }
    argv[0] = span;
    ret = pmcp_call_method(aTHX_ tracer, "enqueue", argv, 1, G_SCALAR, NULL);
    if (ret) SvREFCNT_dec(ret);
}

#endif /* PMCP_OTEL_H */

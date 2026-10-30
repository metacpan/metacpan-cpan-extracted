/* pmcp_stdio.h - `punk mcp`: one application served over stdin and stdout.
 *
 * Needs: pmcp_auth.h, pmcp_bus.h, pmcp_sse.h.
 *
 * Newline-delimited JSON-RPC, one message a line each way, and nothing else on
 * stdout. The process is the session: it holds the negotiated version, the
 * log level and the subscribed URIs.
 *
 * A line is dispatched directly, not as a synthetic POST through the HTTP
 * route: Origin, Accept, the version header, sessions and SSE framing are all
 * HTTP's, and none of them means anything on a pipe. What does carry over is
 * who may call: each line gets a context of its own, the route's guard list
 * runs on it (with --token as its Authorization), and so does `principal`.
 * The application's request hooks do not run, and the POD says so.
 *
 * One call at a time (P7): `$c->await` blocks off a Hyperman loop, so a Future
 * resolves, and a line that arrives during a call waits in the pipe.
 */

#ifndef PMCP_STDIO_H
#define PMCP_STDIO_H

#include <unistd.h>

#define PMCP_STDIO_REFUSED (-32001)

typedef struct {
    PerlIO *out;     /* the real stdout, kept for the protocol */
    HV     *subs;    /* subscribed URIs */
    int     active;
} pmcp_stdio_t;

static pmcp_stdio_t PMCP_STDIO = { NULL, NULL, 0 };

/* One message, one line. Every protocol byte goes through here, so a
 * notification written during a call can never split an answer. */
static void pmcp_stdio_write(pTHX_ SV *json)
{
    STRLEN l;
    const char *p;
    if (!PMCP_STDIO.out) return;
    p = SvPV_const(json, l);
    PerlIO_write(PMCP_STDIO.out, p, l);
    PerlIO_write(PMCP_STDIO.out, "\n", 1);
    PerlIO_flush(PMCP_STDIO.out);
}

/* resources/updated, if this process subscribes to it. */
static void pmcp_stdio_updated(pTHX_ SV *uri)
{
    HV *m, *p;
    SV *rv, *bytes, *err = NULL;
    if (!PMCP_STDIO.active || !PMCP_STDIO.subs || !uri || !hv_exists_ent(PMCP_STDIO.subs, uri, 0))
        return;
    m = newHV();
    p = newHV();
    (void)hv_stores(p, "uri", newSVsv(uri));
    (void)hv_stores(m, "jsonrpc", newSVpvs("2.0"));
    (void)hv_stores(m, "method", newSVpvs("notifications/resources/updated"));
    (void)hv_stores(m, "params", newRV_noinc((SV *)p));
    rv = sv_2mortal(newRV_noinc((SV *)m));
    bytes = pmcp_json_trapped(aTHX_ rv, &err);
    if (bytes) { pmcp_stdio_write(aTHX_ bytes); SvREFCNT_dec(bytes); }
    else SvREFCNT_dec(err);
}

static int pmcp_stdio_active(void) { return PMCP_STDIO.active; }

static void pmcp_stdio_subscribe(pTHX_ SV *uri, int on)
{
    if (!PMCP_STDIO.subs) PMCP_STDIO.subs = newHV();
    if (on) (void)hv_store_ent(PMCP_STDIO.subs, uri, newSViv(1), 0);
    else (void)hv_delete_ent(PMCP_STDIO.subs, uri, G_DISCARD, 0);
}

/* ---- one line ----------------------------------------------------------------------- */

/* A context for one line, as a request would have: the token as Authorization,
 * a loopback address, the MCP path. +1 */
static SV *pmcp_stdio_context(pTHX_ SV *app, pmcp_server *ps, SV *token, SV *ctx_class)
{
    HV *env = newHV(), *match = newHV();
    AV *ver = newAV();
    SV *argv[3];
    av_push(ver, newSViv(1));
    av_push(ver, newSViv(1));
    (void)hv_stores(env, "REQUEST_METHOD", newSVpvs("POST"));
    (void)hv_stores(env, "PATH_INFO", newSVsv(pmcp_hget(aTHX_ ps->opts, "path")));
    (void)hv_stores(env, "SCRIPT_NAME", newSVpvs(""));
    (void)hv_stores(env, "QUERY_STRING", newSVpvs(""));
    (void)hv_stores(env, "SERVER_NAME", newSVpvs("localhost"));
    (void)hv_stores(env, "SERVER_PORT", newSVpvs("0"));
    (void)hv_stores(env, "SERVER_PROTOCOL", newSVpvs("HTTP/1.1"));
    (void)hv_stores(env, "REMOTE_ADDR", newSVpvs("127.0.0.1"));
    (void)hv_stores(env, "CONTENT_TYPE", newSVpvs("application/json"));
    (void)hv_stores(env, "CONTENT_LENGTH", newSVpvs("0"));
    (void)hv_stores(env, "psgi.url_scheme", newSVpvs("http"));
    (void)hv_stores(env, "psgi.version", newRV_noinc((SV *)ver));
    (void)hv_stores(env, "psgi.errors", newRV_inc((SV *)gv_fetchpvs("STDERR", GV_ADD, SVt_PVIO)));
    (void)hv_stores(env, "pmcp.stdio", newSViv(1));
    if (token && SvOK(token) && SvCUR(token))
        (void)hv_stores(env, "HTTP_AUTHORIZATION", newSVpvf("Bearer %" SVf, SVfARG(token)));
    (void)hv_stores(match, "captures", newRV_noinc((SV *)newHV()));
    argv[0] = sv_2mortal(newRV_noinc((SV *)env));
    argv[1] = app;
    argv[2] = sv_2mortal(newRV_noinc((SV *)match));
    return pmcp_call_method(aTHX_ ctx_class, "_build", argv, 3, G_SCALAR, NULL);
}

/* The guards, unless `stdio_trust`: NULL to carry on, or the refusal's
 * status (mortal). */
static SV *pmcp_stdio_guard(pTHX_ pmcp_server *ps, SV *c)
{
    SV *trust = pmcp_hget(aTHX_ ps->opts, "stdio_trust");
    AV *guards;
    SSize_t i, n;
    if ((trust && SvTRUE(trust)) || !pmcp_is_array(ps->guards)) return NULL;
    guards = (AV *)SvRV(ps->guards);
    n = av_len(guards) + 1;
    for (i = 0; i < n; i++) {
        SV *err = NULL;
        SV *r = pmcp_call_sv(aTHX_ *av_fetch(guards, i, 0), &c, 1, G_SCALAR, &err);
        if (!r) return sv_2mortal(pmcp_die_text(aTHX_ sv_2mortal(err)));
        if (SvROK(r)) {
            SV *t = pmcp_refusal_text(aTHX_ r);
            SvREFCNT_dec(r);
            return sv_2mortal(t);
        }
        SvREFCNT_dec(r);
    }
    return NULL;
}

/* ---- the loop --------------------------------------------------------------------------- */

/* Serve stdin until EOF. Returns the exit status. */
static int pmcp_stdio_run(pTHX_ SV *app, pmcp_server *ps, SV *token, SV *class)
{
    /* the application's own context class, which carries its helpers: a
     * request is built in it, and so is a line */
    SV *ctx_class = sv_2mortal(newSVpvf("%" SVf "::_Context", SVfARG(class)));
    if (!gv_stashsv(ctx_class, 0)) ctx_class = sv_2mortal(newSVpvs("Punk::Context"));
    PerlIO *in = PerlIO_stdin();
    SV *line = sv_2mortal(newSV(256));
    int proto;
    enum pmcp_ver v = PMCP_V_NONE;
    int initialized = 0;
    HV *st = (HV *)sv_2mortal((SV *)newHV());
    SV *strv = sv_2mortal(newRV_inc((SV *)st));

    /* stdout carries protocol lines and nothing else. The real descriptor is
     * kept for the protocol, and fd 1 becomes stderr, so a stray print in a
     * controller lands there instead of corrupting the stream. */
    PerlIO_flush(PerlIO_stdout());
    proto = dup(1);
    if (proto < 0 || dup2(2, 1) < 0)
        croak("%s: punk mcp could not set stdout aside: %s", PMCP_WHO, Strerror(errno));
    PMCP_STDIO.out = PerlIO_fdopen(proto, "w");
    if (!PMCP_STDIO.out) croak("%s: punk mcp could not open the protocol stream", PMCP_WHO);
    PerlIO_binmode(aTHX_ PMCP_STDIO.out, '>', O_BINARY, NULL);
    PMCP_STDIO.active = 1;

    (void)hv_stores(st, "stdio", newSViv(1));
    (void)hv_stores(st, "n", newSViv(0));
    (void)hv_stores(st, "logging", newSViv(ps->srv.logging));
    (void)hv_stores(st, "level", newSViv(ps->srv.log_level));

    while (sv_gets(line, in, 0)) {
        STRLEN l;
        char *p = SvPV(line, l);
        SV *doc, *c, *reply, *refused;
        pmcp_msg m;
        pmcp_req r;
        int status = 0;

        while (l && (p[l - 1] == '\n' || p[l - 1] == '\r')) l--;
        if (!l) continue;
        SvCUR_set(line, l);

        ENTER; SAVETMPS;
        doc = pmcp_rpc_decode(aTHX_ line);
        if (!doc) {
            reply = pmcp_rpc_error(aTHX_ NULL, PMCP_PARSE, "parse error", NULL);
            pmcp_stdio_write(aTHX_ sv_2mortal(reply));
            FREETMPS; LEAVE;
            continue;
        }
        sv_2mortal(doc);
        pmcp_rpc_classify(aTHX_ doc, &m);
        c = sv_2mortal(pmcp_stdio_context(aTHX_ app, ps, token, ctx_class));
        (void)hv_stores(st, "c", newSVsv(c));

        if (m.kind != PMCP_K_INVALID && (refused = pmcp_stdio_guard(aTHX_ ps, c))) {
            if (m.kind == PMCP_K_REQUEST) {
                SV *data = newRV_noinc((SV *)newHV());
                (void)hv_stores((HV *)SvRV(data), "reason", newSVsv(refused));
                pmcp_stdio_write(aTHX_ sv_2mortal(
                    pmcp_rpc_error(aTHX_ m.id, PMCP_STDIO_REFUSED, "not authorized", data)));
            }
            FREETMPS; LEAVE;
            continue;
        }
        if (pmcp_is_code(ps->principal)) pmcp_principal_run(aTHX_ c, ps->principal);

        pmcp_req_init(&r, v, initialized);
        r.c = c;
        r.stdio = 1;
        r.stream = strv;
        reply = pmcp_dispatch_doc(aTHX_ &ps->srv, &r, doc, &status);
        if (m.id) pmcp_live_del(aTHX_ NULL, m.id);
        if (r.negotiated) { v = r.negotiated; initialized = 1; }
        if (r.level_set >= 0) {
            ps->srv.log_level = r.level_set;
            (void)hv_stores(st, "level", newSViv(r.level_set));
        }
        pmcp_req_free(aTHX_ &r);
        if (reply) pmcp_stdio_write(aTHX_ sv_2mortal(reply));
        FREETMPS; LEAVE;
    }
    PerlIO_flush(PMCP_STDIO.out);
    PMCP_STDIO.active = 0;
    return 0;
}

/* ---- `punk mcp` ---------------------------------------------------------------------------- */

/* Perl's STDERR as it stands, so a caller that has redirected the handle
 * (a test, a wrapper) sees what is said, which fd 2 alone would not show. */
static PerlIO *pmcp_stderr(pTHX)
{
    IO *io = PL_stderrgv ? GvIO(PL_stderrgv) : NULL;
    return (io && IoOFP(io)) ? IoOFP(io) : PerlIO_stderr();
}

/* The command's body: ($opt, @args). Loads the application, checks it uses
 * the plugin, and serves it. */
XS_INTERNAL(pmcp_command_cb)
{
    dXSARGS;
    SV *opt = items > 0 ? ST(0) : &PL_sv_undef;
    HV *o = pmcp_is_hash(opt) ? (HV *)SvRV(opt) : NULL;
    SV *dir = o ? pmcp_hget(aTHX_ o, "dir") : NULL;
    SV *token = o ? pmcp_hget(aTHX_ o, "token") : NULL;
    SV *envname = o ? pmcp_hget(aTHX_ o, "env") : NULL;
    SV *argv[4], *info, *err = NULL, *class, *app;
    HV *st;
    pmcp_server *ps;
    int code = 0;

    if (!token) {
        HV *envh = GvHV(gv_fetchpvs("ENV", GV_ADD, SVt_PVHV));
        SV **e = hv_fetchs(envh, "PUNK_MCP_TOKEN", 0);
        if (e && SvOK(*e)) token = *e;
    }
    if (envname) {
        HV *envh = GvHV(gv_fetchpvs("ENV", GV_ADD, SVt_PVHV));
        (void)hv_stores(envh, "PUNK_ENV", newSVsv(envname));
    }

    argv[0] = sv_2mortal(newSVpvs("dir"));
    argv[1] = dir ? dir : &PL_sv_undef;
    argv[2] = sv_2mortal(newSVpvs("chdir"));
    argv[3] = sv_2mortal(newSViv(1));
    info = pmcp_call_method(aTHX_ sv_2mortal(newSVpvs("Punk::Command")), "load_app",
                            argv, 4, G_SCALAR, &err);
    if (!info) {
        PerlIO_printf(pmcp_stderr(aTHX), "punk mcp: %" SVf, SVfARG(sv_2mortal(err)));
        code = 1;
        goto done;
    }
    sv_2mortal(info);
    class = pmcp_hget(aTHX_ (HV *)SvRV(info), "class");
    app = pmcp_hget(aTHX_ (HV *)SvRV(info), "registrar");
    st = (app && pmcp_is_hash(app) && pmcp_hget(aTHX_ (HV *)SvRV(app), "mcp"))
       ? pmcp_state(aTHX_ app) : NULL;
    ps = st ? pmcp_server_of(aTHX_ pmcp_hget(aTHX_ st, "server")) : NULL;
    if (!ps || !pmcp_flag(aTHX_ st, "registered")) {
        PerlIO_printf(pmcp_stderr(aTHX), "punk mcp: %" SVf " does not use plugin 'MCP' "
                      "(add plugin 'MCP' => {...} to it)\n",
                      SVfARG(class ? class : sv_2mortal(newSVpvs("the application"))));
        code = 2;
        goto done;
    }
    code = pmcp_stdio_run(aTHX_ app, ps, token, class);

done:
    SP = PL_stack_base + ax - 1;
    ST(0) = sv_2mortal(newSViv(code));
    XSRETURN(1);
}

/* The doctor row: one line per application in this process using the plugin. */
XS_INTERNAL(pmcp_doctor_cb)
{
    dXSARGS;
    SV *detail = sv_2mortal(newSVpvs(""));
    SSize_t i, n = PMCP_SERVERS ? av_len(PMCP_SERVERS) + 1 : 0;
    PERL_UNUSED_VAR(items);
    for (i = 0; i < n; i++) {
        pmcp_server *ps = pmcp_server_of(aTHX_ *av_fetch(PMCP_SERVERS, i, 0));
        pmcp_tools *ts;
        SV *sess, *oauth;
        if (!ps) continue;
        ts = (pmcp_tools *)ps->srv.tools;
        sess = pmcp_hget(aTHX_ ps->opts, "session");
        oauth = pmcp_hget(aTHX_ ps->opts, "oauth");
        if (SvCUR(detail)) sv_catpvs(detail, "; ");
        sv_catpvf(detail, "%" SVf ": %" IVdf " tools, %" IVdf " resources, %" IVdf
                  " prompts, %s%" SVf ", oauth %s",
                  SVfARG(pmcp_hget(aTHX_ ps->opts, "path")),
                  ts ? ts->n : 0,
                  ps->srv.resources ? ((pmcp_resources *)ps->srv.resources)->n : 0,
                  ps->srv.prompts ? ((pmcp_prompts *)ps->srv.prompts)->n : 0,
                  sess && SvTRUE(sess) ? "sessions in " : "stateless",
                  SVfARG(sess && SvTRUE(sess) ? sess : sv_2mortal(newSVpvs(""))),
                  oauth ? "on" : "off");
    }
    SP = PL_stack_base + ax - 1;
    EXTEND(SP, 2);
    ST(0) = sv_2mortal(newSViv(1));
    ST(1) = SvCUR(detail) ? detail : sv_2mortal(newSVpvs("no application here uses it"));
    XSRETURN(2);
}

/* `use Punk::Plugin::MCP ':command'`, from Punk/Command/Mcp.pm: register the
 * command and the doctor row, once. */
static void pmcp_command_register(pTHX)
{
    static int done = 0;
    SV *class = sv_2mortal(newSVpvs("Punk::Command"));
    HV *spec;
    AV *opts;
    SV *argv[3], *r;
    if (done || !pmcp_can(aTHX_ class, "register")) return;
    done = 1;

    opts = newAV();
    {
        HV *t = newHV();
        (void)hv_stores(t, "spec", newSVpvs("token=s"));
        (void)hv_stores(t, "arg", newSVpvs("TOKEN"));
        (void)hv_stores(t, "doc", newSVpvs("a bearer token the guards see (or PUNK_MCP_TOKEN)"));
        av_push(opts, newRV_noinc((SV *)t));
    }
    {
        HV *e = newHV();
        (void)hv_stores(e, "spec", newSVpvs("env=s"));
        (void)hv_stores(e, "arg", newSVpvs("NAME"));
        (void)hv_stores(e, "doc", newSVpvs("the configuration environment (sets PUNK_ENV)"));
        av_push(opts, newRV_noinc((SV *)e));
    }
    spec = newHV();
    (void)hv_stores(spec, "abstract", newSVpvs("serve the application's MCP endpoint over stdio"));
    (void)hv_stores(spec, "usage", newSVpvs("[options]"));
    (void)hv_stores(spec, "desc", newSVpvs(
        "Newline-delimited JSON-RPC on stdin and stdout, for an MCP client that\n"
        "launches its servers, such as Claude Code: claude mcp add NAME -- punk mcp"));
    (void)hv_stores(spec, "options", newRV_noinc((SV *)opts));
    (void)hv_stores(spec, "code", pmcp_closure(aTHX_ pmcp_command_cb, newAV()));
    argv[0] = sv_2mortal(newSVpvs("mcp"));
    argv[1] = sv_2mortal(newRV_noinc((SV *)spec));
    argv[2] = sv_2mortal(newSVpvs("Punk::Command::Mcp"));
    r = pmcp_call_method(aTHX_ class, "register", argv, 3, G_SCALAR, NULL);
    if (r) SvREFCNT_dec(r);

    if (pmcp_can(aTHX_ class, "register_doctor")) {
        argv[0] = sv_2mortal(newSVpvs("Punk::MCP"));
        argv[1] = sv_2mortal(pmcp_closure(aTHX_ pmcp_doctor_cb, newAV()));
        argv[2] = sv_2mortal(newSVpvs("Punk::Command::Mcp"));
        r = pmcp_call_method(aTHX_ class, "register_doctor", argv, 3, G_SCALAR, NULL);
        if (r) SvREFCNT_dec(r);
    }
}

#endif /* PMCP_STDIO_H */

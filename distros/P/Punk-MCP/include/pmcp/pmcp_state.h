/* pmcp_state.h - one application's MCP state: the declarations the `mcp`
 * keyword records, the options `register` validates, and what on_compile
 * freezes from them.
 *
 * Needs: pmcp_reg.h, pmcp_proto.h.
 *
 * The state is an HV under the `mcp` key of the application's own hash, as
 * Punk-Feed keeps its state, so it lives and dies with the application and two
 * applications in one process cannot share it:
 *
 *   used        how many declarations the keyword has recorded
 *   registered  1 once `plugin 'MCP'` ran
 *   wrapped     1 once the to_app middleware is installed
 *   opts        the validated options (pmcp_opts)
 *   decls       AV of [kind, key, spec, target] in declaration order, the
 *               target a code ref after on_compile
 *   frozen      1 after on_compile
 *   server      the pmcp_srv handle, a Punk::Plugin::MCP::Server object
 */

#ifndef PMCP_STATE_H
#define PMCP_STATE_H

/* Defined in pmcp_oa.h. */
XS_INTERNAL(pmcp_capture_cb);

/* Defined in pmcp_sse.h. */
XS_INTERNAL(pmcp_helper_progress);
XS_INTERNAL(pmcp_helper_log);
XS_INTERNAL(pmcp_helper_updated);

/* Defined in pmcp_http.h, which needs pmcp_server from this header. */
static void pmcp_http_route(pTHX_ SV *app, SV *server, HV *opts);
static void pmcp_http_cors_check(pTHX_ SV *inner, HV *opts);
static void pmcp_sess_boot_check(pTHX_ SV *app, HV *opts);

static const char *const PMCP_KINDS[] = { "tool", "resource", "prompt", NULL };

/* The application's MCP state, created on first ask. */
static HV *pmcp_state(pTHX_ SV *app)
{
    HV *h = pmcp_is_hash(app) ? (HV *)SvRV(app) : NULL;
    SV *s;
    if (!h) croak("%s: not a Punk application", PMCP_WHO);
    s = pmcp_hget(aTHX_ h, "mcp");
    if (pmcp_is_hash(s)) return (HV *)SvRV(s);
    {
        HV *st = newHV();
        (void)hv_stores(st, "decls", newRV_noinc((SV *)newAV()));
        (void)hv_stores(h, "mcp", newRV_noinc((SV *)st));
        return st;
    }
}

static AV *pmcp_decls(pTHX_ HV *st)
{
    return (AV *)SvRV(pmcp_hget(aTHX_ st, "decls"));
}

static IV pmcp_flag(pTHX_ HV *st, const char *k)
{
    SV *v = pmcp_hget(aTHX_ st, k);
    return v ? SvIV(v) : 0;
}

/* ---- the server handle ------------------------------------------------------ */

/* A pmcp_srv held by a blessed pointer object, so it is freed when the
 * application is. The SVs it points at are owned by the options HV, which the
 * handle keeps a reference to. */
typedef struct {
    pmcp_srv srv;
    HV      *opts;
    SV      *guards;      /* the routes' guard list, an AV ref (11), for stdio */
    SV      *principal;   /* `principal` resolved, or NULL */
} pmcp_server;

/* Every server compiled in this process, for `punk doctor` (13). */
static AV *PMCP_SERVERS = NULL;

#define PMCP_SERVER_CLASS "Punk::Plugin::MCP::Server"

static SV *pmcp_server_new(pTHX_ HV *opts, pmcp_tools *ts, int tools,
                           int resources, int prompts)
{
    pmcp_server *ps;
    SV *obj;
    SV *v;

    Newxz(ps, 1, pmcp_server);
    ps->opts = (HV *)SvREFCNT_inc_simple_NN((SV *)opts);
    ps->srv.name         = pmcp_hget(aTHX_ opts, "name");
    ps->srv.title        = pmcp_hget(aTHX_ opts, "title");
    ps->srv.version      = pmcp_hget(aTHX_ opts, "version");
    ps->srv.description  = pmcp_hget(aTHX_ opts, "description");
    ps->srv.website      = pmcp_hget(aTHX_ opts, "website");
    ps->srv.icons        = pmcp_hget(aTHX_ opts, "icons");
    ps->srv.instructions = pmcp_hget(aTHX_ opts, "instructions");
    ps->srv.has_tools     = tools ? 1 : 0;
    ps->srv.has_resources = resources ? 1 : 0;
    ps->srv.has_prompts   = prompts ? 1 : 0;
    ps->srv.logging = (v = pmcp_hget(aTHX_ opts, "logging")) && SvTRUE(v);
    /* With sessions the GET stream (10) can carry a notification. stdio sets
     * its own copy (13). */
    ps->srv.can_notify = (v = pmcp_hget(aTHX_ opts, "session")) && SvTRUE(v);
    ps->srv.tools = ts;
    ps->srv.log_level = PMCP_LOG_DEFAULT;

    obj = newSV(0);
    sv_setref_pv(obj, PMCP_SERVER_CLASS, (void *)ps);
    return obj;
}

static pmcp_server *pmcp_server_of(pTHX_ SV *obj)
{
    if (!(obj && SvROK(obj) && sv_derived_from(obj, PMCP_SERVER_CLASS)))
        return NULL;
    return INT2PTR(pmcp_server *, SvIV(SvRV(obj)));
}

static void pmcp_server_free(pTHX_ pmcp_server *ps)
{
    if (!ps) return;
    if (ps->srv.tools) pmcp_tools_free(aTHX_ (pmcp_tools *)ps->srv.tools);
    if (ps->srv.resources)
        pmcp_resources_free(aTHX_ (pmcp_resources *)ps->srv.resources);
    if (ps->srv.prompts) pmcp_prompts_free(aTHX_ (pmcp_prompts *)ps->srv.prompts);
    if (ps->srv.psgi) SvREFCNT_dec(ps->srv.psgi);
    if (ps->guards) SvREFCNT_dec(ps->guards);
    if (ps->principal) SvREFCNT_dec(ps->principal);
    if (ps->opts) SvREFCNT_dec((SV *)ps->opts);
    Safefree(ps);
}

/* ---- the `mcp` keyword --------------------------------------------------------- */

/*     mcp KIND => KEY => {spec} => TARGET
 *     mcp KIND => KEY => TARGET
 *
 * Records only. The spec is checked by 05 (tools) and 06 (resources, prompts),
 * and the target is resolved at to_app, because the controller it names is
 * often declared below the keyword. cap = [app]. */
XS_INTERNAL(pmcp_kw_cb)
{
    dXSARGS;
    SV *app = pmcp_cap(aTHX_ cv, 0);
    HV *st = pmcp_state(aTHX_ app);
    SV *kind, *key, *spec = NULL, *target;
    AV *decls, *rec;
    SSize_t i, n;
    STRLEN kl;
    const char *k;
    int ki;

    if (items != 3 && items != 4)
        croak("%s: mcp takes KIND => KEY => {spec} => TARGET, as in "
              "mcp tool => search => {...} => 'Books#search'", PMCP_WHO);
    kind = ST(0);
    key = ST(1);
    if (items == 4) { spec = ST(2); target = ST(3); }
    else target = ST(2);

    k = pmcp_is_text(kind) ? SvPV_const(kind, kl) : "";
    if (!pmcp_is_text(kind)) kl = 0;
    for (ki = 0; PMCP_KINDS[ki]; ki++)
        if (strlen(PMCP_KINDS[ki]) == kl && memEQ(PMCP_KINDS[ki], k, kl)) break;
    if (!PMCP_KINDS[ki])
        croak("%s: mcp takes tool, resource or prompt, not '%.*s'", PMCP_WHO,
              (int)kl, k);
    if (!pmcp_is_text(key))
        croak("%s: mcp %s needs a %s", PMCP_WHO, k,
              ki == 1 ? "URI" : "name");
    if (spec && !pmcp_is_hash(spec))
        croak("%s: mcp %s '%" SVf "' takes its description as a hash",
              PMCP_WHO, k, SVfARG(key));
    if (!pmcp_is_target(aTHX_ target))
        croak("%s: mcp %s '%" SVf "' needs a code ref or a "
              "'Controller#method' target", PMCP_WHO, k, SVfARG(key));
    if (pmcp_flag(aTHX_ st, "frozen"))
        croak("%s: mcp %s '%" SVf "' is declared after to_app", PMCP_WHO, k,
              SVfARG(key));

    decls = pmcp_decls(aTHX_ st);
    n = av_len(decls) + 1;
    for (i = 0; i < n; i++) {
        AV *d = (AV *)SvRV(*av_fetch(decls, i, 0));
        if (sv_eq(*av_fetch(d, PMCP_D_KIND, 0), kind)
            && sv_eq(*av_fetch(d, PMCP_D_KEY, 0), key))
            croak("%s: mcp %s '%" SVf "' is declared twice", PMCP_WHO, k,
                  SVfARG(key));
    }

    rec = newAV();
    av_push(rec, newSVpvn(k, kl));
    av_push(rec, newSVsv(key));
    av_push(rec, spec ? newSVsv(spec) : newRV_noinc((SV *)newHV()));
    av_push(rec, newSVsv(target));
    av_push(decls, newRV_noinc((SV *)rec));
    (void)hv_stores(st, "used", newSViv(pmcp_flag(aTHX_ st, "used") + 1));
    XSRETURN_EMPTY;
}

/* ---- on_compile: resolve and freeze ----------------------------------------------- */

/* Every 'Controller#method' target becomes the code ref it names, through
 * Punk's own resolver, so a declaration follows the rules a route does. */
static void pmcp_resolve_targets(pTHX_ SV *app, HV *st)
{
    AV *decls = pmcp_decls(aTHX_ st);
    SSize_t i, n = av_len(decls) + 1;

    for (i = 0; i < n; i++) {
        AV *d = (AV *)SvRV(*av_fetch(decls, i, 0));
        SV *target = *av_fetch(d, PMCP_D_TARGET, 0);
        SV *argv[2], *err = NULL, *code;
        if (pmcp_is_code(target)) continue;
        argv[0] = target;
        argv[1] = sv_2mortal(newSVpvf("mcp %" SVf " '%" SVf "'",
                                      SVfARG(*av_fetch(d, PMCP_D_KIND, 0)),
                                      SVfARG(*av_fetch(d, PMCP_D_KEY, 0))));
        /* _resolve_target croaks by design on a target it cannot find */
        code = pmcp_call_method(aTHX_ app, "_resolve_target", argv, 2,
                                G_SCALAR, &err);
        if (!code) pmcp_croak_sv(aTHX_ sv_2mortal(err));
        if (!pmcp_is_code(code)) {
            SvREFCNT_dec(code);
            croak("%s: %" SVf " did not resolve to code", PMCP_WHO,
                  SVfARG(argv[1]));
        }
        (void)av_store(d, PMCP_D_TARGET, code);
    }
}

static void pmcp_freeze(pTHX_ SV *app, HV *st)
{
    AV *decls = pmcp_decls(aTHX_ st);
    SSize_t i, n = av_len(decls) + 1;
    int counts[3] = { 0, 0, 0 };
    SV *opts = pmcp_hget(aTHX_ st, "opts");

    if (pmcp_flag(aTHX_ st, "frozen")) return;
    pmcp_resolve_targets(aTHX_ app, st);
    for (i = 0; i < n; i++) {
        AV *d = (AV *)SvRV(*av_fetch(decls, i, 0));
        const char *k = SvPV_nolen(*av_fetch(d, PMCP_D_KIND, 0));
        counts[k[0] == 't' ? 0 : k[0] == 'r' ? 1 : 2]++;
    }
    (void)hv_stores(st, "server",
        pmcp_server_new(aTHX_ (HV *)SvRV(opts),
                        counts[0] ? pmcp_tools_freeze(aTHX_ app, decls,
                                                      (HV *)SvRV(opts)) : NULL,
                        counts[0] || pmcp_hget(aTHX_ (HV *)SvRV(opts), "openapi"),
                        counts[1], counts[2]));
    {
        pmcp_server *ps = pmcp_server_of(aTHX_ pmcp_hget(aTHX_ st, "server"));
        if (counts[1])
            ps->srv.resources = pmcp_resources_freeze(aTHX_ app, decls,
                                                      (HV *)SvRV(opts));
        if (counts[2])
            ps->srv.prompts = pmcp_prompts_freeze(aTHX_ app, decls,
                                                  (HV *)SvRV(opts));
    }
    pmcp_http_route(aTHX_ app, pmcp_hget(aTHX_ st, "server"), (HV *)SvRV(opts));
    if (!PMCP_SERVERS) PMCP_SERVERS = newAV();
    av_push(PMCP_SERVERS, newSVsv(pmcp_hget(aTHX_ st, "server")));
    /* last, so innermost: the raw app, for OpenAPI tools to re-enter (12) */
    if (pmcp_hget(aTHX_ (HV *)SvRV(opts), "openapi")) {
        AV *cap = newAV();
        av_push(cap, newSVsv(app));
        av_push(cap, newSVsv(pmcp_hget(aTHX_ st, "server")));
        pmcp_middleware(aTHX_ app, pmcp_capture_cb, cap);
    }
    (void)hv_stores(st, "frozen", newSViv(1));
}

/* cap = [app] */
XS_INTERNAL(pmcp_compile_cb)
{
    dXSARGS;
    SV *app = pmcp_cap(aTHX_ cv, 0);
    PERL_UNUSED_VAR(items);
    pmcp_freeze(aTHX_ app, pmcp_state(aTHX_ app));
    XSRETURN_EMPTY;
}

/* ---- to_app: the tripwire and the guard check ------------------------------------------ */

/* Code ref address -> "GET /path" for every route that carries a guard: the
 * router's records, then each OpenAPI mount's operations. Mortal. Read here and
 * not in on_compile, because the records exist only once the router has
 * compiled (and Punk::Router::records dereferences NULL before then). */
static HV *pmcp_guarded_targets(pTHX_ SV *app)
{
    HV *out = (HV *)sv_2mortal((SV *)newHV());
    HV *h = (HV *)SvRV(app);
    SV *router = pmcp_hget(aTHX_ h, "router");
    SV *mounts = pmcp_hget(aTHX_ h, "api_mounts");
    SV *recs;
    SSize_t i, n;

#define PMCP_NOTE_GUARDED(code, where) STMT_START {                        \
        char key[32];                                                       \
        int kl = my_snprintf(key, sizeof key, "%" UVxf,                     \
                             PTR2UV(SvRV(code)));                           \
        if (!hv_exists(out, key, kl))                                       \
            (void)hv_store(out, key, kl, (where), 0);                       \
        else SvREFCNT_dec(where);                                           \
    } STMT_END

    if (router) {
        recs = pmcp_call_method(aTHX_ router, "records", NULL, 0, G_SCALAR, NULL);
        if (recs && pmcp_is_array(recs)) {
            AV *av = (AV *)SvRV(recs);
            n = av_len(av) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                HV *r;
                SV *code, *g, *m, *p;
                if (!(e && pmcp_is_hash(*e))) continue;
                r = (HV *)SvRV(*e);
                code = pmcp_hget(aTHX_ r, "code");
                g = pmcp_hget(aTHX_ r, "guards");
                if (!(pmcp_is_code(code) && pmcp_is_array(g)
                      && av_len((AV *)SvRV(g)) >= 0)) continue;
                m = pmcp_hget(aTHX_ r, "method");
                p = pmcp_hget(aTHX_ r, "path");
                PMCP_NOTE_GUARDED(code, newSVpvf("%s %s",
                    m ? SvPV_nolen(m) : "?", p ? SvPV_nolen(p) : "?"));
            }
        }
        if (recs) SvREFCNT_dec(recs);
    }

    if (pmcp_is_array(mounts)) {
        AV *ms = (AV *)SvRV(mounts);
        n = av_len(ms) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(ms, i, 0);
            SV *ops;
            HE *he;
            if (!(e && pmcp_is_hash(*e))) continue;
            ops = pmcp_hget(aTHX_ (HV *)SvRV(*e), "ops");
            if (!pmcp_is_hash(ops)) continue;
            hv_iterinit((HV *)SvRV(ops));
            while ((he = hv_iternext((HV *)SvRV(ops)))) {
                SV *rec = HeVAL(he), *code, *g;
                STRLEN ol;
                const char *op;
                if (!pmcp_is_hash(rec)) continue;
                code = pmcp_hget(aTHX_ (HV *)SvRV(rec), "code");
                g = pmcp_hget(aTHX_ (HV *)SvRV(rec), "guards");
                if (!(pmcp_is_code(code) && pmcp_is_array(g)
                      && av_len((AV *)SvRV(g)) >= 0)) continue;
                op = HePV(he, ol);
                PMCP_NOTE_GUARDED(code, newSVpvf("operation %.*s", (int)ol, op));
            }
        }
    }
#undef PMCP_NOTE_GUARDED
    return out;
}

/* P4: a declaration whose action sits behind a guarded route must say how it
 * is guarded. A tool calls the action directly, so without this an action
 * that is admin-only on the web would be callable by anyone past `auth`. */
static void pmcp_guard_check(pTHX_ SV *app, HV *st)
{
    AV *decls = pmcp_decls(aTHX_ st);
    SSize_t i, n = av_len(decls) + 1;
    HV *guarded = NULL;

    for (i = 0; i < n; i++) {
        AV *d = (AV *)SvRV(*av_fetch(decls, i, 0));
        SV *target = *av_fetch(d, PMCP_D_TARGET, 0);
        SV *spec = *av_fetch(d, PMCP_D_SPEC, 0);
        SV **where;
        char key[32];
        int kl;

        if (!pmcp_is_code(target)) continue;
        if (pmcp_is_hash(spec) && hv_exists((HV *)SvRV(spec), "guard", 5))
            continue;
        if (!guarded) guarded = pmcp_guarded_targets(aTHX_ app);
        kl = my_snprintf(key, sizeof key, "%" UVxf, PTR2UV(SvRV(target)));
        where = hv_fetch(guarded, key, kl, 0);
        if (where)
            croak("%s: mcp %" SVf " '%" SVf "' runs the action that %" SVf
                  " guards, and a call through MCP would skip that guard. "
                  "Give it `guard => ...`, or `guard => 'none'` to expose it "
                  "without one", PMCP_WHO,
                  SVfARG(*av_fetch(d, PMCP_D_KIND, 0)),
                  SVfARG(*av_fetch(d, PMCP_D_KEY, 0)), SVfARG(*where));
    }
}

/* The middleware body. Runs once at to_app with the inner app, and returns it
 * unchanged, so it costs nothing per request. cap = [app]. */
XS_INTERNAL(pmcp_wrap_cb)
{
    dXSARGS;
    SV *app = pmcp_cap(aTHX_ cv, 0);
    HV *st = pmcp_state(aTHX_ app);
    SV *inner = items > 0 ? ST(0) : &PL_sv_undef;

    if (pmcp_flag(aTHX_ st, "used") && !pmcp_flag(aTHX_ st, "registered"))
        croak("%s: mcp was used but plugin 'MCP' was never registered "
              "(add plugin 'MCP' => {...})", PMCP_WHO);
    if (pmcp_flag(aTHX_ st, "registered")) {
        SV *opts = pmcp_hget(aTHX_ st, "opts");
        if (!pmcp_flag(aTHX_ st, "used")
            && !(pmcp_is_hash(opts) && pmcp_hget(aTHX_ (HV *)SvRV(opts), "openapi")))
            croak("%s: plugin 'MCP' is registered but nothing is declared "
                  "(use the mcp keyword, or give the plugin an openapi mount)",
                  PMCP_WHO);
        pmcp_guard_check(aTHX_ app, st);
        if (pmcp_is_hash(opts)) pmcp_http_cors_check(aTHX_ inner, (HV *)SvRV(opts));
        if (pmcp_is_hash(opts)) pmcp_sess_boot_check(aTHX_ app, (HV *)SvRV(opts));
    }
    ST(0) = inner;
    XSRETURN(1);
}

/* ---- installing ----------------------------------------------------------------- */

static AV *pmcp_cap_app(pTHX_ SV *app)
{
    AV *cap = newAV();
    av_push(cap, newSVsv(app));
    return cap;
}

/* The keyword and the to_app middleware, once each. Both import and register
 * call this: import so the bareword form parses, register for an application
 * that names the plugin without `use`-ing it. */
static void pmcp_install(pTHX_ SV *app)
{
    HV *st = pmcp_state(aTHX_ app);
    pmcp_keyword(aTHX_ app, "mcp", pmcp_kw_cb, pmcp_cap_app(aTHX_ app));
    if (!pmcp_flag(aTHX_ st, "wrapped")) {
        (void)hv_stores(st, "wrapped", newSViv(1));
        pmcp_middleware(aTHX_ app, pmcp_wrap_cb, pmcp_cap_app(aTHX_ app));
    }
}

/* register($app, \%opts) */
static void pmcp_register(pTHX_ SV *app, SV *opts)
{
    HV *st = pmcp_state(aTHX_ app);
    SV *class = pmcp_hget(aTHX_ (HV *)SvRV(app), "caller");
    HV *o;

    if (pmcp_flag(aTHX_ st, "registered"))
        croak("%s: plugin 'MCP' is registered twice on %" SVf, PMCP_WHO,
              SVfARG(class ? class : sv_2mortal(newSVpvs("this application"))));
    o = pmcp_opts(aTHX_ class ? class : sv_2mortal(newSVpvs("main")), opts);
    (void)hv_stores(st, "opts", newRV_noinc((SV *)o));
    (void)hv_stores(st, "registered", newSViv(1));
    pmcp_install(aTHX_ app);
    pmcp_helper(aTHX_ app, "mcp", pmcp_helper_mcp);
    pmcp_helper(aTHX_ app, "mcp_user", pmcp_helper_mcp_user);
    pmcp_helper(aTHX_ app, "mcp_progress", pmcp_helper_progress);
    pmcp_helper(aTHX_ app, "mcp_log", pmcp_helper_log);
    pmcp_helper(aTHX_ app, "mcp_resource_updated", pmcp_helper_updated);
    pmcp_at_compile(aTHX_ app, pmcp_compile_cb, pmcp_cap_app(aTHX_ app));
}

/* ---- a view for state_for --------------------------------------------------------- */

/* A plain hash of what the application declared and what was frozen, for the
 * command (13) and the tests. A copy: changing it changes nothing. +1. */
static SV *pmcp_state_view(pTHX_ SV *app)
{
    HV *st = pmcp_state(aTHX_ app);
    HV *out = newHV();
    AV *decls = pmcp_decls(aTHX_ st);
    AV *list = newAV();
    HV *names = newHV();
    SSize_t i, n = av_len(decls) + 1;
    SV *opts = pmcp_hget(aTHX_ st, "opts");
    int k;

    for (k = 0; PMCP_KINDS[k]; k++)
        (void)hv_store(names, PMCP_KINDS[k], (I32)strlen(PMCP_KINDS[k]),
                       newRV_noinc((SV *)newAV()), 0);
    for (i = 0; i < n; i++) {
        AV *d = (AV *)SvRV(*av_fetch(decls, i, 0));
        HV *e = newHV();
        SV *kind = *av_fetch(d, PMCP_D_KIND, 0);
        HE *slot = hv_fetch_ent(names, kind, 0, 0);
        (void)hv_stores(e, "kind",   newSVsv(kind));
        (void)hv_stores(e, "key",    newSVsv(*av_fetch(d, PMCP_D_KEY, 0)));
        (void)hv_stores(e, "spec",   newSVsv(*av_fetch(d, PMCP_D_SPEC, 0)));
        (void)hv_stores(e, "target", newSVsv(*av_fetch(d, PMCP_D_TARGET, 0)));
        av_push(list, newRV_noinc((SV *)e));
        if (slot) av_push((AV *)SvRV(HeVAL(slot)),
                          newSVsv(*av_fetch(d, PMCP_D_KEY, 0)));
    }
    (void)hv_stores(out, "declarations", newRV_noinc((SV *)list));
    (void)hv_stores(out, "tools",     newSVsv(*hv_fetchs(names, "tool", 0)));
    (void)hv_stores(out, "resources", newSVsv(*hv_fetchs(names, "resource", 0)));
    (void)hv_stores(out, "prompts",   newSVsv(*hv_fetchs(names, "prompt", 0)));
    SvREFCNT_dec((SV *)names);
    (void)hv_stores(out, "registered", newSViv(pmcp_flag(aTHX_ st, "registered")));
    (void)hv_stores(out, "frozen",     newSViv(pmcp_flag(aTHX_ st, "frozen")));
    if (pmcp_is_hash(opts)) {
        HV *copy = newHVhv((HV *)SvRV(opts));
        (void)hv_stores(out, "opts", newRV_noinc((SV *)copy));
    }
    {
        pmcp_server *ps = pmcp_server_of(aTHX_ pmcp_hget(aTHX_ st, "server"));
        if (ps) {
            HV *s = newHV();
            (void)hv_stores(s, "tools",      newSViv(ps->srv.has_tools));
            (void)hv_stores(s, "resources",  newSViv(ps->srv.has_resources));
            (void)hv_stores(s, "prompts",    newSViv(ps->srv.has_prompts));
            (void)hv_stores(s, "logging",    newSViv(ps->srv.logging));
            (void)hv_stores(s, "can_notify", newSViv(ps->srv.can_notify));
            (void)hv_stores(out, "server", newRV_noinc((SV *)s));
        }
    }
    return newRV_noinc((SV *)out);
}

#endif /* PMCP_STATE_H */

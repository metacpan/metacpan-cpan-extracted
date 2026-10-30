MODULE = Punk::Plugin::MCP    PACKAGE = Punk::Plugin::MCP

PROTOTYPES: DISABLE

# The plugin object. It carries no state: everything lives on the application.

SV *
new(class)
        SV *class
    CODE:
    {
        const char *pkg = PMCP_WHO;
        STRLEN pkgl = sizeof(PMCP_WHO) - 1;
        if (SvOK(class) && !SvROK(class)) pkg = SvPV(class, pkgl);
        RETVAL = sv_bless(newRV_noinc((SV *)newHV()),
                          gv_stashpvn(pkg, (I32)pkgl, GV_ADD));
    }
    OUTPUT:
        RETVAL

# Installs the `mcp` keyword at compile time, the only moment that makes the
# bareword form parse. `plugin 'MCP'` runs when the package body runs, after
# perl has already parsed (or refused) every `mcp tool => ...` line. Silent in a
# package that is not a Punk application.

void
import(class, ...)
        SV *class
    CODE:
    {
        const char *pkg = CopSTASHPV(PL_curcop);
        SV *pkgsv, *app;
        PERL_UNUSED_VAR(class);
        {
            /* `use Punk::Plugin::MCP ':command'`, from Punk/Command/Mcp.pm:
             * the command and the doctor row, and nothing installed (13) */
            I32 a;
            for (a = 1; a < items; a++)
                if (SvOK(ST(a)) && strEQ(SvPV_nolen(ST(a)), ":command")) {
                    pmcp_command_register(aTHX);
                    XSRETURN_EMPTY;
                }
        }
        if (!pkg) XSRETURN_EMPTY;
        pkgsv = sv_2mortal(newSVpv(pkg, 0));
        if (!pmcp_can(aTHX_ pkgsv, "punk_app")) XSRETURN_EMPTY;
        app = pmcp_call_method(aTHX_ pkgsv, "punk_app", NULL, 0, G_SCALAR, NULL);
        sv_2mortal(app);
        if (pmcp_is_hash(app)) pmcp_install(aTHX_ app);
        XSRETURN_EMPTY;
    }

void
register(self, app, opts = &PL_sv_undef)
        SV *self
        SV *app
        SV *opts
    CODE:
        PERL_UNUSED_VAR(self);
        if (!pmcp_is_hash(app))
            croak("%s: register needs the Punk::App", PMCP_WHO);
        pmcp_register(aTHX_ app, opts);

# state_for($class): what the application declared and froze, or undef.

SV *
state_for(self, class)
        SV *self
        SV *class
    CODE:
    {
        SV *app = NULL;
        PERL_UNUSED_VAR(self);
        RETVAL = &PL_sv_undef;
        if (pmcp_can(aTHX_ class, "punk_app")) {
            app = sv_2mortal(pmcp_call_method(aTHX_ class, "punk_app", NULL, 0,
                                              G_SCALAR, NULL));
            if (pmcp_is_hash(app)
                && pmcp_hget(aTHX_ (HV *)SvRV(app), "mcp"))
                RETVAL = pmcp_state_view(aTHX_ app);
        }
        if (RETVAL == &PL_sv_undef) SvREFCNT_inc_simple_void_NN(RETVAL);
    }
    OUTPUT:
        RETVAL

# Test only: a message dispatched against an application's frozen server.

void
_dispatch_app(class, bytes, protocol = &PL_sv_undef)
        SV *class
        SV *bytes
        SV *protocol
    PPCODE:
    {
        SV *app = sv_2mortal(pmcp_call_method(aTHX_ class, "punk_app", NULL, 0,
                                              G_SCALAR, NULL));
        HV *st = pmcp_state(aTHX_ app);
        pmcp_server *ps = pmcp_server_of(aTHX_ pmcp_hget(aTHX_ st, "server"));
        pmcp_req r;
        SV *reply;
        int status = 0;
        enum pmcp_ver v = PMCP_V_2025_03_26;
        if (!ps) croak("%s: %" SVf " is not compiled", PMCP_WHO, SVfARG(class));
        if (SvOK(protocol)) {
            STRLEN l;
            const char *p = SvPV_const(protocol, l);
            v = pmcp_version_of(p, l);
        }
        pmcp_req_init(&r, v, 0);
        reply = pmcp_dispatch(aTHX_ &ps->srv, &r, bytes, &status);
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, 2);
        mPUSHs(newSViv(status));
        if (reply) mPUSHs(reply); else PUSHs(&PL_sv_undef);
        pmcp_req_free(aTHX_ &r);
    }

const char *
_dist()
    CODE:
        RETVAL = PMCP_DIST;
    OUTPUT:
        RETVAL

SV *
_rand_id()
    CODE:
        RETVAL = pmcp_rand_id(aTHX);
    OUTPUT:
        RETVAL

SV *
_abi_versions()
    CODE:
    {
        HV *h = newHV();
        (void)hv_stores(h, "frj", newSViv(PMCP_FRJ ? PMCP_FRJ->abi_version : 0));
        (void)hv_stores(h, "jsf", newSViv(PMCP_JSF ? PMCP_JSF->abi_version : 0));
        RETVAL = newRV_noinc((SV *)h);
    }
    OUTPUT:
        RETVAL

int
_abi_check(module, version)
    const char *module
    SV *version
    CODE:
    {
        int need  = strEQ(module, "JSON::Schema::Fast") ? JSF_ABI_VERSION
                                                        : FRJ_ABI_VERSION;
        const char *since = strEQ(module, "JSON::Schema::Fast")
                          ? PMCP_JSF_SINCE : PMCP_FRJ_SINCE;
        UV found = SvOK(version) ? 1 : 0;
        pmcp_abi_check(aTHX_ module, found, found ? (int)SvIV(version) : 0,
                       need, since,
                       found ? NULL : sv_2mortal(newSVpvs("faked by t/02")));
        RETVAL = 1;
    }
    OUTPUT:
        RETVAL

SV *
_abi_selftest()
    CODE:
    {
        static const char doc[]    = "{\"b\":[1,2,3],\"a\":\"x\"}";
        static const char schema[] = "{\"type\":\"object\",\"required\":[\"a\"],"
                                     "\"properties\":{\"a\":{\"type\":\"string\"}}}";
        HV *out = newHV();
        frj_opts o;
        SV *data, *json, *compiled, *bad;
        AV *errors = (AV *)sv_2mortal((SV *)newAV());

        PMCP_FRJ->opts_init(&o);
        o.canonical = 1;
        data = sv_2mortal(PMCP_FRJ->decode(aTHX_ doc, sizeof doc - 1, &o));
        json = PMCP_FRJ->encode(aTHX_ data, &o);
        (void)hv_stores(out, "decoded_hash", newSViv(pmcp_is_hash(data)));
        (void)hv_stores(out, "json", json);

        compiled = sv_2mortal(PMCP_JSF->compile(aTHX_
                       sv_2mortal(newSVpvn(schema, sizeof schema - 1)),
                       NULL, 0, 0));
        bad = sv_2mortal(newRV_noinc((SV *)newHV()));
        (void)hv_stores(out, "valid",
                        newSViv(PMCP_JSF->is_valid(aTHX_ compiled, data)));
        (void)hv_stores(out, "invalid",
                        newSViv(PMCP_JSF->validate(aTHX_ compiled, bad, errors)));
        (void)hv_stores(out, "errors", newSViv(av_len(errors) + 1));
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

void
_call(target, inv, want_list, ...)
    SV *target
    SV *inv
    int want_list
    PPCODE:
    {
        SV *err = NULL;
        SV *ret;
        SV **argv = items > 3 ? &ST(3) : NULL;
        int argc  = items - 3;
        I32 flags = want_list ? G_LIST : G_SCALAR;

        if (pmcp_is_code(target))
            ret = pmcp_call(aTHX_ SvOK(inv) ? inv : NULL, NULL, target,
                            argv, argc, flags, &err);
        else
            ret = pmcp_call_method(aTHX_ inv, SvPV_nolen(target),
                                   argv, argc, flags, &err);
        /* the call may have reallocated the stack */
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, 2);
        if (ret) {
            mPUSHs(newSViv(1));
            mPUSHs(ret);
        }
        else {
            mPUSHs(newSViv(0));
            mPUSHs(err);
        }
    }

SV *
_call_plain(code, ...)
    SV *code
    CODE:
        RETVAL = pmcp_call_sv(aTHX_ code, items > 1 ? &ST(1) : NULL,
                              items - 1, G_SCALAR, NULL);
    OUTPUT:
        RETVAL

void
_require(module)
    const char *module
    PPCODE:
    {
        SV *err = NULL;
        int ok = pmcp_require(aTHX_ module, &err);
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, 2);
        mPUSHs(newSViv(ok));
        if (err) mPUSHs(err);
        else     PUSHs(&PL_sv_undef);
    }

SV *
_closure(value)
    SV *value
    CODE:
    {
        AV *cap = newAV();
        av_push(cap, newSVsv(value));
        RETVAL = pmcp_closure(aTHX_ pmcp_clos_echo, cap);
    }
    OUTPUT:
        RETVAL

void
_croak_sv(sv)
    SV *sv
    CODE:
        pmcp_croak_sv(aTHX_ sv);

int
_is_array(sv)
    SV *sv
    CODE:
        RETVAL = pmcp_is_array(sv);
    OUTPUT:
        RETVAL

void
_dispatch(state, bytes)
    SV *state
    SV *bytes
    PPCODE:
    {
        HV *h = pmcp_is_hash(state) ? (HV *)SvRV(state) : NULL;
        pmcp_srv s;
        pmcp_req r;
        SV **e, *reply;
        int status = 0;
        enum pmcp_ver v = PMCP_V_2025_03_26;

        if (!h) croak(PMCP_DIST ": _dispatch needs a state hash");
        Zero(&s, 1, pmcp_srv);
#define PMCP_T_SV(k, f) \
        if ((e = hv_fetchs(h, k, 0)) && SvOK(*e)) s.f = *e;
#define PMCP_T_BIT(k, f) \
        if ((e = hv_fetchs(h, k, 0)) && SvTRUE(*e)) s.f = 1;
        PMCP_T_SV("name", name)
        PMCP_T_SV("title", title)
        PMCP_T_SV("version", version)
        PMCP_T_SV("description", description)
        PMCP_T_SV("website", website)
        PMCP_T_SV("icons", icons)
        PMCP_T_SV("instructions", instructions)
        PMCP_T_BIT("tools", has_tools)
        PMCP_T_BIT("resources", has_resources)
        PMCP_T_BIT("prompts", has_prompts)
        PMCP_T_BIT("logging", logging)
        PMCP_T_BIT("notify", can_notify)
#undef PMCP_T_SV
#undef PMCP_T_BIT
        if ((e = hv_fetchs(h, "protocol", 0)) && SvOK(*e)) {
            STRLEN l;
            const char *p = SvPV_const(*e, l);
            v = pmcp_version_of(p, l);
        }
        e = hv_fetchs(h, "in_session", 0);
        pmcp_req_init(&r, v, e && SvTRUE(*e));

        reply = pmcp_dispatch(aTHX_ &s, &r, bytes, &status);

        /* the dispatch ran Perl, which may have moved the stack */
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, 4);
        mPUSHs(newSViv(status));
        if (reply) mPUSHs(reply); else PUSHs(&PL_sv_undef);
        if (r.negotiated) mPUSHs(newSVpv(PMCP_VER_NAME[r.negotiated], 0));
        else PUSHs(&PL_sv_undef);
        if (r.cancelled) mPUSHs(newSVsv(r.cancelled)); else PUSHs(&PL_sv_undef);
        pmcp_req_free(aTHX_ &r);
    }

int
_method_found(name)
        SV *name
    CODE:
    {
        STRLEN l;
        const char *p = SvPV_const(name, l);
        RETVAL = pmcp_method_find(p, l) != NULL;
    }
    OUTPUT:
        RETVAL

void
_methods()
    PPCODE:
    {
        size_t i;
        EXTEND(SP, (SSize_t)PMCP_N_METHODS);
        for (i = 0; i < PMCP_N_METHODS; i++)
            mPUSHs(newSVpvn(PMCP_METHODS[i].name, PMCP_METHODS[i].len));
    }

MODULE = Punk::Plugin::MCP    PACKAGE = Punk::Plugin::MCP::Server

PROTOTYPES: DISABLE

void
DESTROY(self)
        SV *self
    CODE:
    {
        pmcp_server *ps = pmcp_server_of(aTHX_ self);
        if (ps) {
            sv_setiv(SvRV(self), 0);
            pmcp_server_free(aTHX_ ps);
        }
    }

# A pointer object must not be copied into a new thread: two copies would free
# one struct twice.

int
CLONE_SKIP(...)
    CODE:
        PERL_UNUSED_VAR(items);
        RETVAL = 1;
    OUTPUT:
        RETVAL

MODULE = Punk::Plugin::MCP    PACKAGE = Punk::Plugin::MCP

# Test only, until 07 routes it: one message dispatched against the frozen
# server of $c's application, with $c as the request.

void
_rpc(c, bytes, protocol = &PL_sv_undef, session = &PL_sv_undef)
        SV *c
        SV *bytes
        SV *protocol
        SV *session
    PPCODE:
    {
        SV *app = sv_2mortal(pmcp_call_method(aTHX_ c, "app", NULL, 0,
                                              G_SCALAR, NULL));
        HV *st = pmcp_state(aTHX_ app);
        pmcp_server *ps = pmcp_server_of(aTHX_ pmcp_hget(aTHX_ st, "server"));
        pmcp_req r;
        SV *reply;
        int status = 0;
        enum pmcp_ver v = PMCP_V_2025_11_25;
        if (!ps) croak("%s: the application is not compiled", PMCP_WHO);
        if (SvOK(protocol)) {
            STRLEN l;
            const char *p = SvPV_const(protocol, l);
            v = pmcp_version_of(p, l);
        }
        pmcp_req_init(&r, v, 0);
        r.c = c;
        if (SvOK(session)) r.session = session;
        reply = pmcp_dispatch(aTHX_ &ps->srv, &r, bytes, &status);
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, 2);
        mPUSHs(newSViv(status));
        if (reply) mPUSHs(reply); else PUSHs(&PL_sv_undef);
        pmcp_req_free(aTHX_ &r);
    }

MODULE = Punk::Plugin::MCP    PACKAGE = Punk::MCP::Call

PROTOTYPES: DISABLE

# The call object $c->mcp returns. Read-only accessors over its keys.

SV *
method(self)
        SV *self
    ALIAS:
        name           = 1
        arguments      = 2
        protocol       = 3
        progress_token = 4
        cancelled      = 5
        session        = 6
        client         = 7
    CODE:
    {
        static const char *const keys[] = { "method", "name", "arguments",
            "protocol", "progress_token", "cancelled", "session", "client" };
        SV **e = pmcp_is_hash(self)
               ? hv_fetch((HV *)SvRV(self), keys[ix], (I32)strlen(keys[ix]), 0)
               : NULL;
        RETVAL = (e && *e) ? newSVsv(*e) : newSV(0);
    }
    OUTPUT:
        RETVAL

MODULE = Punk::Plugin::MCP    PACKAGE = Punk::Plugin::MCP

# Test only: how many calls are registered as streaming on this worker.

IV
_live_count()
    CODE:
        RETVAL = PMCP_LIVE ? (IV)HvUSEDKEYS(PMCP_LIVE) : 0;
    OUTPUT:
        RETVAL

MODULE = Punk::Plugin::MCP    PACKAGE = Punk::Plugin::MCP

# Punk::Plugin::MCP->resource_updated($class, $uri): tell the sessions that
# subscribe to $uri, from anywhere (a queue job, a cron), with no request.
# Returns what publish said: 1 on the ring, 0 this worker only, -1 too big.

int
resource_updated(self, class, uri)
        SV *self
        SV *class
        SV *uri
    CODE:
    {
        SV *app = NULL;
        HV *st;
        pmcp_server *ps;
        PERL_UNUSED_VAR(self);
        if (!SvOK(uri) || SvROK(uri))
            croak("%s: resource_updated takes the application class and a URI", PMCP_WHO);
        if (pmcp_can(aTHX_ class, "punk_app"))
            app = sv_2mortal(pmcp_call_method(aTHX_ class, "punk_app", NULL, 0, G_SCALAR, NULL));
        st = pmcp_is_hash(app) ? pmcp_state(aTHX_ app) : NULL;
        ps = st ? pmcp_server_of(aTHX_ pmcp_hget(aTHX_ st, "server")) : NULL;
        if (!ps) croak("%s: %" SVf " has no compiled MCP server", PMCP_WHO, SVfARG(class));
        RETVAL = (pmcp_sessions_on(aTHX_ ps->opts) || PMCP_STDIO.active)
               ? pmcp_bus_send(aTHX_ ps, app, PMCP_BUS_UPDATED, NULL, uri) : 0;
    }
    OUTPUT:
        RETVAL

# ---- test only: the bus and the stream table -----------------------------------

SV *
_bus_encode(kind, pid, sid, uri)
        int kind
        UV pid
        SV *sid
        SV *uri
    CODE:
        RETVAL = pmcp_bus_encode(aTHX_ kind, (U32)pid, SvOK(sid) ? sid : NULL,
                                 SvOK(uri) ? uri : NULL);
        if (!RETVAL) RETVAL = newSV(0);
    OUTPUT:
        RETVAL

void
_bus_decode(payload)
        SV *payload
    PPCODE:
    {
        int kind;
        U32 pid;
        SV *sid, *uri;
        if (pmcp_bus_decode(aTHX_ payload, &kind, &pid, &sid, &uri)) {
            EXTEND(SP, 4);
            mPUSHs(newSViv(kind));
            mPUSHs(newSVuv(pid));
            PUSHs(sid);
            PUSHs(uri);
        }
    }

void
_bus_receive(class, payload)
        SV *class
        SV *payload
    CODE:
    {
        SV *app = sv_2mortal(pmcp_call_method(aTHX_ class, "punk_app", NULL, 0, G_SCALAR, NULL));
        SV *server = pmcp_hget(aTHX_ pmcp_state(aTHX_ app), "server");
        AV *cap = newAV();
        SV *cb, *argv[2], *r;
        av_push(cap, newSVsv(server));
        cb = sv_2mortal(pmcp_closure(aTHX_ pmcp_bus_cb, cap));
        argv[0] = sv_2mortal(newSVpvs("pmcp"));
        argv[1] = payload;
        r = pmcp_call_sv(aTHX_ cb, argv, 2, G_SCALAR, NULL);
        if (r) SvREFCNT_dec(r);
    }

void
_stream_register(class, c, sid, stream)
        SV *class
        SV *c
        SV *sid
        SV *stream
    CODE:
    {
        SV *app = sv_2mortal(pmcp_call_method(aTHX_ class, "punk_app", NULL, 0, G_SCALAR, NULL));
        SV *server = pmcp_hget(aTHX_ pmcp_state(aTHX_ app), "server");
        pmcp_stream_register(aTHX_ server, c, sid, stream, c);
    }

IV
_stream_count()
    CODE:
        RETVAL = PMCP_STREAMS ? (IV)HvUSEDKEYS(PMCP_STREAMS) : 0;
    OUTPUT:
        RETVAL

MODULE = Punk::Plugin::MCP    PACKAGE = Punk::Plugin::MCP

# Test only: the audience check wrapped round an introspection checker, given
# any checker coderef and the audiences it must name.

SV *
_aud_checker(checker, auds)
        SV *checker
        SV *auds
    CODE:
    {
        AV *cap = newAV();
        av_push(cap, newSVsv(checker));
        av_push(cap, newSVsv(auds));
        RETVAL = pmcp_closure(aTHX_ pmcp_aud_checker, cap);
    }
    OUTPUT:
        RETVAL

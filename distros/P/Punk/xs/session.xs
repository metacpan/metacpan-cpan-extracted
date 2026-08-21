MODULE = Punk        PACKAGE = Punk::Session

PROTOTYPES: DISABLE

# _seal($app, \%session): the signed cookie a session hashref would ride in,
# as a (name, value) pair - Punk::Test::login_as mints a session with it so
# tests reach guarded pages without driving a login flow. The encoding and
# the signer are the write-back's own, so what this seals, ps_load verifies.
void
_seal(app, data)
        SV *app
        SV *data
    PPCODE:
    {
        HV *cfg = NULL;
        SV **s;
        STRLEN nl, kl;
        const char *name, *key;
        SV *payload, *sealed;
        if (SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV) {
            s = hv_fetchs((HV *)SvRV(app), "session", 0);
            if (s && *s && SvROK(*s) && SvTYPE(SvRV(*s)) == SVt_PVHV)
                cfg = (HV *)SvRV(*s);
        }
        if (!cfg)
            croak("Punk::Session: _seal needs an app with a session keyword");
        name = ps_cfg_str(aTHX_ cfg, "cookie", "punk.sid", &nl);
        key  = ps_cfg_str(aTHX_ cfg, "secret", "", &kl);
        if (!kl)
            croak("Punk::Session: _seal found no session secret");
        payload = sv_2mortal(ps_encode(aTHX_ data));
        sealed = pk_session_sign(aTHX_ payload, key, kl);
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVpvn(name, nl)));
        PUSHs(sv_2mortal(sealed));
    }

PROTOTYPES: DISABLE

# _new_id(): one session id - 128 bits of CSPRNG, hex. Internal, and exposed
# because the properties that matter (the shape, and that two forked workers
# never draw the same one) are properties of the GENERATOR, testable before
# anything reads a session out of a store.
SV *
_new_id()
    CODE:
        RETVAL = ps_new_id(aTHX);
    OUTPUT:
        RETVAL

# _seal_id($app, $id): the cookie an id rides in, as a (name, value) pair -
# the same shape _seal returns, through the same signer. Punk::Test mints one
# with it, and so does t/, so what this seals is what the reader verifies.
void
_seal_id(app, id)
        SV *app
        SV *id
    PPCODE:
    {
        HV *cfg = NULL;
        SV **s;
        STRLEN nl, kl, il;
        const char *name, *key, *idp;
        if (SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV) {
            s = hv_fetchs((HV *)SvRV(app), "session", 0);
            if (s && *s && SvROK(*s) && SvTYPE(SvRV(*s)) == SVt_PVHV)
                cfg = (HV *)SvRV(*s);
        }
        if (!cfg)
            croak("Punk::Session: _seal_id needs an app with a session keyword");
        idp = SvOK(id) ? SvPV_const(id, il) : (il = 0, "");
        if (!ps_id_ok(idp, il))
            croak("Punk::Session: _seal_id needs a %d-character hex id",
                  PK_SESSION_ID_HEX);
        name = ps_cfg_str(aTHX_ cfg, "cookie", "punk.sid", &nl);
        key  = ps_cfg_str(aTHX_ cfg, "secret", "", &kl);
        if (!kl)
            croak("Punk::Session: _seal_id found no session secret");
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVpvn(name, nl)));
        PUSHs(sv_2mortal(ps_id_seal(aTHX_ id, key, kl,
                                    ps_cfg_iv(aTHX_ cfg, "max_age", 0))));
    }

# _seal_session($app, \%session): a cookie a request will arrive with, whether
# the application keeps its sessions in the cookie or in a store.
#
# Punk::Test::login_as signs a user straight into the jar, and it did that by
# sealing the session INTO the cookie - which is no session at all to an
# application with a store, so every suite using login_as would have broken the
# day its application gained one. So the store case is handled here rather than
# in each suite: mint an id, write the session where the application will look
# for it, and seal the id.
void
_seal_session(app, data)
        SV *app
        SV *data
    PPCODE:
    {
        HV *cfg = NULL, *apph;
        SV **s, *store;
        STRLEN nl, kl;
        const char *name, *key;
        if (!(SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV))
            croak("Punk::Session: _seal_session needs an app");
        apph = (HV *)SvRV(app);
        s = hv_fetchs(apph, "session", 0);
        if (s && *s && SvROK(*s) && SvTYPE(SvRV(*s)) == SVt_PVHV)
            cfg = (HV *)SvRV(*s);
        if (!cfg)
            croak("Punk::Session: _seal_session needs an app with a session "
                  "keyword");
        name  = ps_cfg_str(aTHX_ cfg, "cookie", "punk.sid", &nl);
        key   = ps_cfg_str(aTHX_ cfg, "secret", "", &kl);
        if (!kl)
            croak("Punk::Session: _seal_session found no session secret");
        store = ps_cfg_store(aTHX_ cfg);
        /* A store is asked for on the keyword and resolved at to_app, so
         * between those two moments the config says "server-side" and there is
         * nowhere to write. Sealing into the cookie would be silently wrong -
         * a cookie the compiled application will not recognise - so say which
         * mistake it is instead. */
        if (!store && hv_exists(cfg, "store", 5))
            croak("Punk::Session: this application has `session store => ...` "
                  "but has not been compiled yet - call to_app before sealing "
                  "a session, or the cookie names a store that does not exist "
                  "yet");
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSVpvn(name, nl)));
        if (store) {
            IV ttl = ps_cfg_iv(aTHX_ cfg, "max_age", 0);
            SV *id = sv_2mortal(ps_new_id(aTHX));
            SV *argv[3], *ok;
            HV *payload;
            if (ttl <= 0) ttl = PK_SESSION_MAX_LIFETIME;
            /* stamped like any other write, so a sealed session slides too */
            payload = (SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV)
                    ? newHVhv((HV *)SvRV(data)) : newHV();
            (void)hv_store(payload, PK_SESSION_AT, PK_SESSION_AT_LEN,
                           newSViv((IV)time(NULL)), 0);
            argv[0] = id;
            argv[1] = sv_2mortal(ps_encode(aTHX_
                          sv_2mortal(newRV_noinc((SV *)payload))));
            argv[2] = sv_2mortal(newSViv(ttl));
            ok = pcx_call_meth(aTHX_ store, "set", argv, 3, 1);
            if (ok) sv_2mortal(ok);
            if (!(ok && SvTRUE(ok)))
                croak("Punk::Session: the session store refused the write");
            PUSHs(sv_2mortal(ps_id_seal(aTHX_ id, key, kl, ttl)));
        }
        else {
            PUSHs(sv_2mortal(pk_session_sign(aTHX_
                      sv_2mortal(ps_encode(aTHX_ data)), key, kl)));
        }
    }

# _unseal_id($app, $value): the id inside a cookie value, or undef for a bad
# signature, an expired stamp or an id this server would never have minted.
# One answer for all three: which it was is a distinction useful only to
# somebody probing.
SV *
_unseal_id(app, value)
        SV *app
        SV *value
    CODE:
    {
        HV *cfg = NULL;
        SV **s;
        STRLEN kl, vl;
        const char *key;
        SV *id = NULL;
        if (SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV) {
            s = hv_fetchs((HV *)SvRV(app), "session", 0);
            if (s && *s && SvROK(*s) && SvTYPE(SvRV(*s)) == SVt_PVHV)
                cfg = (HV *)SvRV(*s);
        }
        if (!cfg)
            croak("Punk::Session: _unseal_id needs an app with a session "
                  "keyword");
        key = ps_cfg_str(aTHX_ cfg, "secret", "", &kl);
        if (SvOK(value)) {
            const char *v = SvPV_const(value, vl);
            id = ps_id_unseal(aTHX_ v, vl, key, kl);
        }
        RETVAL = id ? id : newSV(0);
    }
    OUTPUT:
        RETVAL

# The after-dispatch write-back installed when the `session` keyword is used
# (punk_session.h). It adds a signed Set-Cookie to the finished triplet when the
# session changed, or a deletion cookie when it was expired. lib/Punk/Session.pm
# is documentation.
SV *
_writeback(c, resp)
        SV *c
        SV *resp
    CODE:
        ps_writeback(aTHX_ c, resp);
        RETVAL = newSVsv(resp);
    OUTPUT:
        RETVAL

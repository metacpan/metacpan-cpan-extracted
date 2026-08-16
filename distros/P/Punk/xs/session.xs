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

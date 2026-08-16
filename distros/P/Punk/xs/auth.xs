MODULE = Punk        PACKAGE = Punk::Context

PROTOTYPES: DISABLE

# The authentication context surface, all C (punk_auth.h): login/logout/
# auth_id are a session load and a hash write; current_user loads through
# the configured model and the await seam; check_password fronts the KDF
# with the dummy-verify rule; the token pair carries the delete-first spend
# order. lib/Punk/Auth.pm is documentation only.

# $c->login($user_or_id): record the signed-in user in the session. A hashref
# uses its id field (the auth fields map); anything else is the id itself.
# Chains.
SV *
login(self, user)
        SV *self
        SV *user
    CODE:
    {
        HV *cfg = pauth_cfg(aTHX_ self);
        SV *id = NULL, *sess;
        STRLEN kl;
        const char *key;
        if (!cfg)
            croak("Punk: login needs the auth keyword (add `auth ...`)");
        if (SvROK(user) && SvTYPE(SvRV(user)) == SVt_PVHV) {
            HV *u = (HV *)SvRV(user);
            STRLEN idl;
            const char *idf = pauth_field(aTHX_ cfg, "id", "id", &idl);
            SV **e = hv_fetch(u, idf, (I32)idl, 0);
            if (!(e && *e && SvOK(*e)))
                croak("Punk: login was handed a user with no '%s'", idf);
            id = *e;
        }
        else if (SvOK(user)) id = user;
        else croak("Punk: login needs a user row or id");

        key = ps_cfg_str(aTHX_ cfg, "session_key", "user_id", &kl);
        sess = ps_load(aTHX_ self);
        if (sess && SvROK(sess) && SvTYPE(SvRV(sess)) == SVt_PVHV)
            (void)hv_store((HV *)SvRV(sess), key, (I32)kl, newSVsv(id), 0);
        if (sess) SvREFCNT_dec(sess);
        {   /* a fresh login invalidates this request's memoized user */
            HV *stash = ps_stash(aTHX_ pcx_av(aTHX_ self));
            (void)hv_delete(stash, "punk.auth", 9, G_DISCARD);
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# $c->logout: empty the session and delete its cookie (session_expire), and
# forget the memoized user. Chains.
SV *
logout(self)
        SV *self
    CODE:
    {
        SV *r = pcx_call_meth(aTHX_ self, "session_expire", NULL, 0, 1);
        if (r) SvREFCNT_dec(r);
        {
            HV *stash = ps_stash(aTHX_ pcx_av(aTHX_ self));
            (void)hv_delete(stash, "punk.auth", 9, G_DISCARD);
        }
        RETVAL = newSVsv(self);
    }
    OUTPUT:
        RETVAL

# $c->auth_id: the signed-in user id straight off the session - no database.
# The oauth2_server authenticate shape: an id, or undef.
SV *
auth_id(self)
        SV *self
    CODE:
    {
        HV *cfg = pauth_cfg(aTHX_ self);
        SV *id;
        if (!cfg)
            croak("Punk: auth_id needs the auth keyword (add `auth ...`)");
        id = pauth_session_id(aTHX_ self, cfg);
        RETVAL = id ? id : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

# $c->current_user: the signed-in user's row, loaded once per request and
# memoized; undef when nobody is signed in or the row is gone.
SV *
current_user(self)
        SV *self
    CODE:
    {
        HV *cfg = pauth_cfg(aTHX_ self);
        SV *user;
        if (!cfg)
            croak("Punk: current_user needs the auth keyword "
                  "(add `auth ...`)");
        user = pauth_current_user(aTHX_ self, cfg);
        RETVAL = user ? user : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

# $c->check_password($user, $password): true only for a real match. With no
# user or no stored hash the same PBKDF2 work is burned before returning
# false, so login response time cannot say which emails exist.
IV
check_password(self, user, password)
        SV *self
        SV *user
        SV *password
    CODE:
    {
        HV *cfg = pauth_cfg(aTHX_ self);
        SV *stored = NULL;
        U32 iterations = 0;
        STRLEN pfl;
        const char *pf;
        if (!cfg)
            croak("Punk: check_password needs the auth keyword "
                  "(add `auth ...`)");
        pf = pauth_field(aTHX_ cfg, "password", "password_hash", &pfl);
        {
            SV **it = hv_fetchs(cfg, "iterations", 0);
            if (it && *it && SvOK(*it) && SvIV(*it) > 0)
                iterations = (U32)SvIV(*it);
            else {
                SV *g = get_sv("Punk::Auth::Password::ITERATIONS", 0);
                if (g && SvOK(g) && SvIV(g) > 0) iterations = (U32)SvIV(g);
            }
        }
        if (SvROK(user) && SvTYPE(SvRV(user)) == SVt_PVHV) {
            SV **e = hv_fetch((HV *)SvRV(user), pf, (I32)pfl, 0);
            if (e && *e && SvOK(*e) && SvCUR(*e)) stored = *e;
        }
        if (!stored) {
            STRLEN pl = 0;
            const char *p = SvOK(password) ? SvPV_const(password, pl) : "";
            pwd_dummy_verify(aTHX_ (const unsigned char *)p, pl, iterations);
            RETVAL = 0;
        }
        else if (!SvOK(password)) RETVAL = 0;
        else {
            STRLEN pl, sl;
            const char *p = SvPV_const(password, pl);
            const char *s = SvPV_const(stored, sl);
            RETVAL = pwd_verify(aTHX_ (const unsigned char *)p, pl, s, sl);
        }
    }
    OUTPUT:
        RETVAL

# $c->issue_token($user_id, $kind, $ttl): a single-use token on the token
# model. Storage sees only the sha256 digest with an absolute expiry; a new
# token invalidates the user's older tokens of the same kind, so a re-sent
# mail leaves exactly one live link. Returns the plaintext, once.
SV *
issue_token(self, user_id, kind, ttl)
        SV *self
        SV *user_id
        SV *kind
        SV *ttl
    CODE:
    {
        HV *cfg = pauth_cfg(aTHX_ self);
        SV *m, *tok;
        if (!cfg)
            croak("Punk: issue_token needs the auth keyword "
                  "(add `auth ...`)");
        if (!SvOK(user_id) || !SvOK(kind) || !SvOK(ttl) || SvIV(ttl) <= 0)
            croak("Punk: issue_token needs a user id, a kind and a ttl");
        m = pauth_model(aTHX_ self, cfg, "token_model", "issue_token");
        {   /* older same-kind tokens die first */
            HV *filter = newHV();
            SV *argv[1], *raw, *res;
            AV *rows;
            (void)hv_stores(filter, "user_id", newSVsv(user_id));
            (void)hv_stores(filter, "kind",    newSVsv(kind));
            argv[0] = sv_2mortal(newRV_noinc((SV *)filter));
            raw = pcx_call_meth(aTHX_ m, "search", argv, 1, 1);
            res = pauth_await(aTHX_ self, raw ? raw : &PL_sv_undef);
            if (raw) SvREFCNT_dec(raw);
            rows = pauth_rows(aTHX_ res);
            if (rows) {
                SSize_t i, n = av_len(rows) + 1;
                for (i = 0; i < n; i++) {
                    SV **rp = av_fetch(rows, i, 0);
                    SV **idp;
                    SV *dargv[2], *draw, *dres;
                    if (!(rp && *rp && SvROK(*rp))) continue;
                    idp = hv_fetchs((HV *)SvRV(*rp), "id", 0);
                    if (!(idp && *idp && SvOK(*idp))) continue;
                    dargv[0] = sv_2mortal(newSVpvs("id"));
                    dargv[1] = *idp;
                    draw = pcx_call_meth(aTHX_ m, "delete", dargv, 2, 1);
                    dres = pauth_await(aTHX_ self,
                                       draw ? draw : &PL_sv_undef);
                    if (draw) SvREFCNT_dec(draw);
                    if (dres) SvREFCNT_dec(dres);
                }
            }
            if (res) SvREFCNT_dec(res);
        }
        tok = pwd_token(aTHX);
        {
            HV *data = newHV();
            SV *argv[1], *raw, *res;
            STRLEN tl;
            const unsigned char *tp =
                (const unsigned char *)SvPV_const(tok, tl);
            (void)hv_stores(data, "user_id", newSVsv(user_id));
            (void)hv_stores(data, "kind",    newSVsv(kind));
            (void)hv_stores(data, "digest",  pwd_token_digest(aTHX_ tp, tl));
            (void)hv_stores(data, "expires",
                            newSViv((IV)time(NULL) + SvIV(ttl)));
            argv[0] = sv_2mortal(newRV_noinc((SV *)data));
            raw = pcx_call_meth(aTHX_ m, "create", argv, 1, 1);
            res = pauth_await(aTHX_ self, raw ? raw : &PL_sv_undef);
            if (raw) SvREFCNT_dec(raw);
            if (res) SvREFCNT_dec(res);
        }
        SvREFCNT_dec(m);
        RETVAL = tok;
    }
    OUTPUT:
        RETVAL

# $c->take_token($token, @kinds): the row, or nothing. THE ORDER IS THE
# FEATURE: look up by digest, delete FIRST, then validate kind and expiry -
# a token is spent whether or not it turns out valid, so a wrong-kind probe
# burns it rather than leaving it live for its real endpoint.
SV *
take_token(self, token, ...)
        SV *self
        SV *token
    CODE:
    {
        HV *cfg = pauth_cfg(aTHX_ self);
        SV *m, *row_copy = NULL;
        if (!cfg)
            croak("Punk: take_token needs the auth keyword "
                  "(add `auth ...`)");
        if (!SvOK(token) || !SvCUR(token) || items < 3)
            XSRETURN_UNDEF;
        m = pauth_model(aTHX_ self, cfg, "token_model", "take_token");
        {
            HV *filter = newHV();
            SV *argv[1], *raw, *res;
            AV *rows;
            SV **rp = NULL;
            STRLEN tl;
            const unsigned char *tp =
                (const unsigned char *)SvPV_const(token, tl);
            (void)hv_stores(filter, "digest", pwd_token_digest(aTHX_ tp, tl));
            argv[0] = sv_2mortal(newRV_noinc((SV *)filter));
            raw = pcx_call_meth(aTHX_ m, "search", argv, 1, 1);
            res = pauth_await(aTHX_ self, raw ? raw : &PL_sv_undef);
            if (raw) SvREFCNT_dec(raw);
            rows = pauth_rows(aTHX_ res);
            if (rows && av_len(rows) >= 0) rp = av_fetch(rows, 0, 0);
            if (rp && *rp && SvROK(*rp)
                && SvTYPE(SvRV(*rp)) == SVt_PVHV) {
                HV *row = (HV *)SvRV(*rp);
                SV **idp = hv_fetchs(row, "id", 0);
                SV **kp  = hv_fetchs(row, "kind", 0);
                SV **xp  = hv_fetchs(row, "expires", 0);
                int i, kind_ok = 0;
                if (idp && *idp && SvOK(*idp)) {
                    SV *dargv[2], *draw, *dres;
                    dargv[0] = sv_2mortal(newSVpvs("id"));
                    dargv[1] = *idp;
                    draw = pcx_call_meth(aTHX_ m, "delete", dargv, 2, 1);
                    dres = pauth_await(aTHX_ self,
                                       draw ? draw : &PL_sv_undef);
                    if (draw) SvREFCNT_dec(draw);
                    if (dres) SvREFCNT_dec(dres);
                }
                if (kp && *kp && SvOK(*kp)) {
                    STRLEN kl2;
                    const char *k2 = SvPV_const(*kp, kl2);
                    for (i = 2; i < items && !kind_ok; i++) {
                        STRLEN wl;
                        const char *w;
                        if (!SvOK(ST(i))) continue;
                        w = SvPV_const(ST(i), wl);
                        if (wl == kl2 && memEQ(w, k2, kl2)) kind_ok = 1;
                    }
                }
                if (kind_ok && xp && *xp && SvOK(*xp)
                    && SvIV(*xp) >= (IV)time(NULL))
                    row_copy = newRV_noinc((SV *)newHVhv(row));
            }
            if (res) SvREFCNT_dec(res);
        }
        SvREFCNT_dec(m);
        if (!row_copy) XSRETURN_UNDEF;
        RETVAL = row_copy;
    }
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::Auth

PROTOTYPES: DISABLE

# The await seam, exposed: Punk::Auth::_await($c, $value) unwraps a
# future-returning model backend's result (Punk::Future through $c->await,
# any other ->get-bearing object through its own get), and passes a plain
# value straight through - so glue code stays backend-agnostic.
SV *
_await(c, v)
        SV *c
        SV *v
    CODE:
        RETVAL = pauth_await(aTHX_ c, v);
    OUTPUT:
        RETVAL

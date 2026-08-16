MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2::Provider

SV *
new(class, name, ...)
        SV *class
        SV *name
    CODE:
        HV *cfg = newHV();
        int i;
        PERL_UNUSED_VAR(class);
        if ((items - 2) % 2)
            croak("Punk::OAuth2::Provider->new: uneven config");
        for (i = 2; i < items; i += 2)
            (void)hv_store_ent(cfg, ST(i), newSVsv(ST(i + 1)), 0);
        RETVAL = pox_prov_new(aTHX_ SvPV_nolen(name), cfg);
        SvREFCNT_dec((SV *)cfg);
    OUTPUT:
        RETVAL

SV *
name(self)
        SV *self
    ALIAS:
        issuer = 1
        scope  = 2
    CODE:
        HV *h = pox_prov_hv(aTHX_ self);
        const char *k = ix == 1 ? "issuer" : ix == 2 ? "scope" : "name";
        SV *v = pox_prov_get(aTHX_ h, k);
        RETVAL = v ? newSVsv(v) : &PL_sv_undef;
    OUTPUT:
        RETVAL

int
oidc(self)
        SV *self
    CODE:
        RETVAL = pox_prov_flag(aTHX_ pox_prov_hv(aTHX_ self), "oidc");
    OUTPUT:
        RETVAL

void
ensure_endpoints(self, c)
        SV *self
        SV *c
    CODE:
        pox_prov_ensure_endpoints(aTHX_ self, c);

SV *
jwks(self, ...)
        SV *self
    CODE:
        SV *j = pox_prov_jwks(aTHX_ self);
        RETVAL = j ? SvREFCNT_inc(j) : &PL_sv_undef;
    OUTPUT:
        RETVAL

SV *
authorize_url(self, ...)
        SV *self
    CODE:
        HV *p = newHV();
        int i;
        if ((items - 1) % 2)
            croak("authorize_url: uneven params");
        for (i = 1; i < items; i += 2)
            (void)hv_store_ent(p, ST(i), newSVsv(ST(i + 1)), 0);
        RETVAL = pox_prov_authorize_url(aTHX_ self, p);
        SvREFCNT_dec((SV *)p);
    OUTPUT:
        RETVAL

SV *
exchange(self, c, ...)
        SV *self
        SV *c
    CODE:
        HV *p = newHV();
        int i;
        SV *code = &PL_sv_undef, *ru = &PL_sv_undef;
        SV *ver = &PL_sv_undef, *nonce = &PL_sv_undef;
        SV **v;
        if ((items - 2) % 2)
            croak("exchange: uneven params");
        for (i = 2; i < items; i += 2)
            (void)hv_store_ent(p, ST(i), newSVsv(ST(i + 1)), 0);
        sv_2mortal((SV *)p);
        if ((v = hv_fetchs(p, "code", 0)))         code  = *v;
        if ((v = hv_fetchs(p, "redirect_uri", 0))) ru    = *v;
        if ((v = hv_fetchs(p, "verifier", 0)))     ver   = *v;
        if ((v = hv_fetchs(p, "nonce", 0)))        nonce = *v;
        RETVAL = SvREFCNT_inc(pox_prov_exchange(aTHX_ self, c, code, ru,
                                                ver, nonce));
    OUTPUT:
        RETVAL

SV *
refresh(self, c, refresh_token)
        SV *self
        SV *c
        SV *refresh_token
    CODE:
        HV *fields = newHV();
        SV *rt = refresh_token;
        if (SvROK(rt) && sv_isobject(rt)
            && sv_derived_from(rt, "Punk::OAuth2::Tokens"))
            rt = sv_2mortal(pox_tokens_get(aTHX_ rt, "refresh_token"));
        if (!SvOK(rt) || !SvCUR(rt))
            croak("oauth2 %s: nothing to refresh",
                  pox_prov_name(aTHX_ pox_prov_hv(aTHX_ self)));
        (void)hv_stores(fields, "grant_type", newSVpvs("refresh_token"));
        (void)hv_stores(fields, "refresh_token", newSVsv(rt));
        sv_2mortal((SV *)fields);
        RETVAL = pox_prov_token_call(aTHX_ self, c, fields);
    OUTPUT:
        RETVAL

SV *
verify_id_token(self, c, id_token, ...)
        SV *self
        SV *c
        SV *id_token
    CODE:
        SV *nonce = NULL;
        int i;
        for (i = 3; i + 1 < items; i += 2)
            if (strEQ(SvPV_nolen(ST(i)), "nonce")) nonce = ST(i + 1);
        {
            SV *claims = pox_prov_verify_id_token(aTHX_ self, c, id_token,
                                                  nonce);
            RETVAL = claims ? SvREFCNT_inc(claims) : &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
identity(self, c, tokens)
        SV *self
        SV *c
        SV *tokens
    CODE:
        RETVAL = SvREFCNT_inc(pox_prov_identity(aTHX_ self, c, tokens));
    OUTPUT:
        RETVAL

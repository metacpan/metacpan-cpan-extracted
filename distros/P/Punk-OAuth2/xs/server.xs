MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2::Server

# new(%opts): issuer, store, key (a Crypt::JWS::Key; generated ES256 if
# absent), alg, at_ttl, rt_ttl, prefix, oidc, authenticate, consent.
SV *
new(class, ...)
        SV *class
    CODE:
        HV *self = newHV();
        HV *opts = newHV();
        int i;
        SV *obj, **v, *key = NULL;
        const char *alg;
        PERL_UNUSED_VAR(class);
        sv_2mortal((SV *)opts);
        if ((items - 1) % 2)
            croak("Punk::OAuth2::Server->new: uneven options");
        for (i = 1; i < items; i += 2)
            (void)hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);

        if (!(v = hv_fetchs(opts, "issuer", 0)) || !SvOK(*v)) {
            SvREFCNT_dec((SV *)self);
            croak("Punk::OAuth2::Server->new: an issuer is required");
        }
        (void)hv_stores(self, "issuer", newSVsv(*v));
        if (!(v = hv_fetchs(opts, "store", 0)) || !SvOK(*v)) {
            SvREFCNT_dec((SV *)self);
            croak("Punk::OAuth2::Server->new: a store is required");
        }
        (void)hv_stores(self, "store", newSVsv(*v));

        alg = (v = hv_fetchs(opts, "alg", 0)) && SvOK(*v)
            ? SvPV_nolen(*v) : "ES256";
        (void)hv_stores(self, "alg", newSVpv(alg, 0));
        (void)hv_stores(self, "at_ttl",
            (v = hv_fetchs(opts, "at_ttl", 0)) && SvOK(*v)
              ? newSVsv(*v) : newSViv(600));
        (void)hv_stores(self, "rt_ttl",
            (v = hv_fetchs(opts, "rt_ttl", 0)) && SvOK(*v)
              ? newSVsv(*v) : newSViv(30 * 86400));
        (void)hv_stores(self, "prefix",
            (v = hv_fetchs(opts, "prefix", 0)) && SvOK(*v)
              ? newSVsv(*v) : newSVpvs("/oauth"));
        if ((v = hv_fetchs(opts, "oidc", 0)) && SvOK(*v))
            (void)hv_stores(self, "oidc", newSVsv(*v));
        if ((v = hv_fetchs(opts, "authenticate", 0)) && SvOK(*v))
            (void)hv_stores(self, "authenticate", newSVsv(*v));
        if ((v = hv_fetchs(opts, "consent", 0)) && SvOK(*v))
            (void)hv_stores(self, "consent", newSVsv(*v));

        /* the signing key: a supplied Crypt::JWS::Key, or a fresh one */
        if ((v = hv_fetchs(opts, "key", 0)) && SvOK(*v)
            && SvROK(*v) && sv_isobject(*v)) {
            key = SvREFCNT_inc(*v);
        }
        else {
            dSP; int count;
            ENTER; SAVETMPS; PUSHMARK(SP);
            XPUSHs(sv_2mortal(newSVpvs("Crypt::JWS::Key")));
            XPUSHs(sv_2mortal(newSVpv(alg, 0)));
            PUTBACK;
            count = call_method("generate", G_SCALAR | G_EVAL); SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) key = SvREFCNT_inc(POPs);
            else if (count > 0) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (!key) { SvREFCNT_dec((SV *)self);
                croak("Punk::OAuth2::Server: key generation failed"); }
        }
        (void)hv_stores(self, "key", key);
        /* kid = key->thumbprint */
        {
            dSP; int count; SV *kid = NULL;
            ENTER; SAVETMPS; PUSHMARK(SP); XPUSHs(key); PUTBACK;
            count = call_method("thumbprint", G_SCALAR | G_EVAL); SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) kid = SvREFCNT_inc(POPs);
            else if (count > 0) (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            (void)hv_stores(self, "kid", kid ? kid : newSVpvs("1"));
        }

        obj = newRV_noinc((SV *)self);
        sv_bless(obj, gv_stashpvs("Punk::OAuth2::Server", GV_ADD));
        RETVAL = obj;
    OUTPUT:
        RETVAL

SV *
authorize(self, c)
        SV *self
        SV *c
    CODE:
        RETVAL = pox_srv_authorize(aTHX_ self, c);
    OUTPUT:
        RETVAL

SV *
token(self, c)
        SV *self
        SV *c
    CODE:
        RETVAL = pox_srv_token(aTHX_ self, c);
    OUTPUT:
        RETVAL

SV *
revoke(self, c)
        SV *self
        SV *c
    CODE:
        RETVAL = pox_srv_revoke(aTHX_ self, c);
    OUTPUT:
        RETVAL

SV *
introspect(self, c)
        SV *self
        SV *c
    CODE:
        RETVAL = pox_srv_introspect(aTHX_ self, c);
    OUTPUT:
        RETVAL

SV *
jwks(self, c)
        SV *self
        SV *c
    CODE:
        RETVAL = pox_srv_jwks(aTHX_ self, c);
    OUTPUT:
        RETVAL

SV *
metadata(self, c)
        SV *self
        SV *c
    CODE:
        RETVAL = pox_srv_metadata(aTHX_ self, c);
    OUTPUT:
        RETVAL

SV *
prefix(self)
        SV *self
    CODE:
        SV *p = pox_srv_get(aTHX_ pox_srv_hv(aTHX_ self), "prefix");
        RETVAL = p ? newSVsv(p) : newSVpvs("/oauth");
    OUTPUT:
        RETVAL

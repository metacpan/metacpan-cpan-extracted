MODULE = Punk::OAuth2  PACKAGE = Punk::OAuth2::Checker

# jwt(%opts) -> a checker coderef (the OpenAPI security-map contract).
# Builds the JWKS object or static key in C and captures the config in an
# anonymous CV; all validation runs in pox_do_check.
SV *
jwt(class, ...)
        SV *class
    CODE:
        HV *cfg = newHV();
        HV *opts = newHV();
        int i;
        SV *self;
        PERL_UNUSED_VAR(class);
        sv_2mortal((SV *)opts);
        if ((items - 1) % 2)
            croak("Punk::OAuth2::Checker->jwt: uneven options");
        for (i = 1; i < items; i += 2)
            (void)hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);

        (void)hv_stores(cfg, "kind", newSVpvs("jwt"));
        {
            SV **v;
            if ((v = hv_fetchs(opts, "issuer", 0)) && SvOK(*v))
                (void)hv_stores(cfg, "issuer", newSVsv(*v));
            if ((v = hv_fetchs(opts, "audience", 0)) && SvOK(*v))
                (void)hv_stores(cfg, "audience", newSVsv(*v));
            if ((v = hv_fetchs(opts, "algs", 0)) && SvOK(*v))
                (void)hv_stores(cfg, "algs", newSVsv(*v));
            else {
                AV *a = newAV();
                av_push(a, newSVpvs("RS256"));
                av_push(a, newSVpvs("ES256"));
                (void)hv_stores(cfg, "algs", newRV_noinc((SV *)a));
            }
            (void)hv_stores(cfg, "leeway",
                (v = hv_fetchs(opts, "leeway", 0)) && SvOK(*v)
                  ? newSVsv(*v) : newSViv(60));
            (void)hv_stores(cfg, "scheme",
                (v = hv_fetchs(opts, "scheme", 0)) && SvOK(*v)
                  ? newSVsv(*v) : newSVpvs("oauth"));
        }

        {
            SV **ju = hv_fetchs(opts, "jwks_url", 0);
            SV **ky = hv_fetchs(opts, "key", 0);
            if (ju && *ju && SvOK(*ju)) {
                /* JWKS->new(url=>..., ua=>..., allow_local=>...) */
                dSP; int count; SV *jwks = NULL;
                ENTER; SAVETMPS; PUSHMARK(SP);
                XPUSHs(sv_2mortal(newSVpvs("Punk::OAuth2::JWKS")));
                XPUSHs(sv_2mortal(newSVpvs("url")));
                XPUSHs(*ju);
                if (hv_fetchs(opts, "ua", 0)) {
                    XPUSHs(sv_2mortal(newSVpvs("ua")));
                    XPUSHs(*hv_fetchs(opts, "ua", 0));
                }
                if (hv_fetchs(opts, "allow_local", 0)) {
                    XPUSHs(sv_2mortal(newSVpvs("allow_local")));
                    XPUSHs(*hv_fetchs(opts, "allow_local", 0));
                }
                PUTBACK;
                count = call_method("new", G_SCALAR | G_EVAL);
                SPAGAIN;
                if (!SvTRUE(ERRSV) && count > 0) jwks = SvREFCNT_inc(POPs);
                else if (count > 0) (void)POPs;
                PUTBACK; FREETMPS; LEAVE;
                if (!jwks) { SvREFCNT_dec((SV *)cfg);
                    croak("Punk::OAuth2::Checker->jwt: %s", SvPV_nolen(ERRSV)); }
                (void)hv_stores(cfg, "jwks", jwks);
            }
            else if (ky && *ky && SvOK(*ky)) {
                SV *key = NULL;
                if (SvROK(*ky) && sv_isobject(*ky)) {
                    key = SvREFCNT_inc(*ky);   /* a Crypt::JWS::Key */
                }
                else {
                    STRLEN kl;
                    const char *kp = SvPV_const(*ky, kl);
                    const char *meth = (kl > 10
                        && strstr(kp, "BEGIN")) ? "from_pem" : "from_secret";
                    dSP; int count;
                    ENTER; SAVETMPS; PUSHMARK(SP);
                    XPUSHs(sv_2mortal(newSVpvs("Crypt::JWS::Key")));
                    XPUSHs(*ky);
                    PUTBACK;
                    count = call_method(meth, G_SCALAR | G_EVAL);
                    SPAGAIN;
                    if (!SvTRUE(ERRSV) && count > 0) key = SvREFCNT_inc(POPs);
                    else if (count > 0) (void)POPs;
                    PUTBACK; FREETMPS; LEAVE;
                    if (!key) { SvREFCNT_dec((SV *)cfg);
                        croak("Punk::OAuth2::Checker->jwt: bad key"); }
                }
                (void)hv_stores(cfg, "key", key);
            }
            else {
                SvREFCNT_dec((SV *)cfg);
                croak("Punk::OAuth2::Checker->jwt: one of jwks_url or key "
                      "is required");
            }
        }

        self = newRV_noinc((SV *)cfg);
        sv_bless(self, gv_stashpvs("Punk::OAuth2::Checker", GV_ADD));
        RETVAL = pox_make_closure(aTHX_ pox_check_cb, (void *)self);
    OUTPUT:
        RETVAL

# introspect(%opts) -> a checker coderef.
SV *
introspect(class, ...)
        SV *class
    CODE:
        HV *cfg = newHV();
        HV *opts = newHV();
        int i;
        SV *self;
        SV **v;
        PERL_UNUSED_VAR(class);
        sv_2mortal((SV *)opts);
        if ((items - 1) % 2)
            croak("Punk::OAuth2::Checker->introspect: uneven options");
        for (i = 1; i < items; i += 2)
            (void)hv_store_ent(opts, ST(i), newSVsv(ST(i + 1)), 0);
        if (!(v = hv_fetchs(opts, "url", 0)) || !SvOK(*v)) {
            SvREFCNT_dec((SV *)cfg);
            croak("Punk::OAuth2::Checker->introspect: a url is required");
        }
        (void)hv_stores(cfg, "kind", newSVpvs("introspect"));
        (void)hv_stores(cfg, "url", newSVsv(*v));
        if ((v = hv_fetchs(opts, "client_id", 0)) && SvOK(*v))
            (void)hv_stores(cfg, "client_id", newSVsv(*v));
        if ((v = hv_fetchs(opts, "client_secret", 0)) && SvOK(*v))
            (void)hv_stores(cfg, "client_secret", newSVsv(*v));
        if ((v = hv_fetchs(opts, "ua", 0)) && SvOK(*v))
            (void)hv_stores(cfg, "ua", newSVsv(*v));
        (void)hv_stores(cfg, "cache_ttl",
            (v = hv_fetchs(opts, "cache_ttl", 0)) && SvOK(*v)
              ? newSVsv(*v) : newSViv(0));
        (void)hv_stores(cfg, "scheme",
            (v = hv_fetchs(opts, "scheme", 0)) && SvOK(*v)
              ? newSVsv(*v) : newSVpvs("oauth"));
        self = newRV_noinc((SV *)cfg);
        sv_bless(self, gv_stashpvs("Punk::OAuth2::Checker", GV_ADD));
        RETVAL = pox_make_closure(aTHX_ pox_check_cb, (void *)self);
    OUTPUT:
        RETVAL

# guard($checker, %opts) -> a route-guard coderef.
SV *
guard(class, checker, ...)
        SV *class
        SV *checker
    CODE:
        HV *cap = newHV();
        int i;
        PERL_UNUSED_VAR(class);
        if (!SvROK(checker) || SvTYPE(SvRV(checker)) != SVt_PVCV)
            croak("Punk::OAuth2::Checker->guard: expects a checker coderef");
        if ((items - 2) % 2)
            croak("Punk::OAuth2::Checker->guard: uneven options");
        (void)hv_stores(cap, "checker", newSVsv(checker));
        (void)hv_stores(cap, "scopes", newRV_noinc((SV *)newAV()));
        (void)hv_stores(cap, "realm", newSVpvs("api"));
        for (i = 2; i < items; i += 2) {
            STRLEN kl;
            const char *k = SvPV_const(ST(i), kl);
            if (kl == 6 && memEQ(k, "scopes", 6))
                (void)hv_stores(cap, "scopes", newSVsv(ST(i + 1)));
            else if (kl == 5 && memEQ(k, "realm", 5))
                (void)hv_stores(cap, "realm", newSVsv(ST(i + 1)));
            else if (kl == 6 && memEQ(k, "scheme", 6))
                (void)hv_stores(cap, "scheme", newSVsv(ST(i + 1)));
        }
        RETVAL = pox_make_closure(aTHX_ pox_guard_cb, (void *)cap);
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::Plugin::Idempotency

PROTOTYPES: DISABLE

# register($app, \%opts)
#
# `scope` is REQUIRED and is the whole security argument. The stored value is
# a WHOLE RESPONSE - somebody's order, with their address in it - so if two
# accounts can produce one cache key, this plugin is a way to read other
# people's responses by guessing a UUID, on exactly the endpoints worth
# reading.
#
# The plugin cannot supply it. A Punk application may authenticate through a
# session, an `auth` identity, an OAuth2 token or an API key - four this
# workspace already ships - and inventing a default means picking one and
# being silently wrong for the rest. Same shape as Punk::Plugin::Sitemap
# refusing to start without `base`, and for the same reason: a default here
# would be a security decision made by the framework on the application's
# behalf.
void
register(self, app, opts = &PL_sv_undef)
        SV *self
        SV *app
        SV *opts
    CODE:
    {
        HV *h = app_hv(aTHX_ app);
        HV *o = NULL;
        HV *cfg;
        SV **sc;
        PERL_UNUSED_VAR(self);

        if (SvOK(opts) && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
            o = (HV *)SvRV(opts);
        if (o) {
            static const char *const known[] = { "scope", "ttl", NULL };
            HE *he;
            hv_iterinit(o);
            while ((he = hv_iternext(o))) {
                const char *k = HePV(he, PL_na);
                int ok = 0, i;
                for (i = 0; known[i]; i++) if (strEQ(k, known[i])) ok = 1;
                if (!ok)
                    croak("Punk::Plugin::Idempotency: unknown option '%s'", k);
            }
        }
        sc = o ? hv_fetchs(o, "scope", 0) : NULL;
        if (!(sc && *sc && SvROK(*sc) && SvTYPE(SvRV(*sc)) == SVt_PVCV))
            croak("Punk::Plugin::Idempotency: `scope` is required and must be "
                  "a coderef - the stored value is a whole response, so a key "
                  "that is not scoped to an account is a way to read somebody "
                  "else's (plugin 'Idempotency' => { scope => sub { "
                  "$_[0]->current_user->{id} } })");

        cfg = newHV();
        (void)hv_stores(cfg, "scope", newSVsv(*sc));
        {   /* 24 hours is the usual default and it is a business decision -
             * how long after a failed request will your client still retry? -
             * so it is an option, not a constant. */
            SV **t = o ? hv_fetchs(o, "ttl", 0) : NULL;
            (void)hv_stores(cfg, "ttl",
                (t && *t && SvOK(*t)) ? newSVnv(SvNV(*t)) : newSVnv(86400));
        }
        (void)hv_stores(h, K_IDEM, newRV_noinc((SV *)cfg));
    }

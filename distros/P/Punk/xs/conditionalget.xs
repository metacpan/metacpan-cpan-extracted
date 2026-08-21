MODULE = Punk        PACKAGE = Punk::Plugin::ConditionalGet

PROTOTYPES: DISABLE

# register($app, \%opts)
#
# The plugin is an on-switch and a place for the documentation to live: the
# work is the `etag` route option and the check in punk_cget.h, which the
# dispatcher runs between a route's guards and its handler.
#
# It is registered rather than always-on because the option changes what a
# request costs and what a client caches, and because a route option that
# does something only when a plugin is loaded is the arrangement `sitemap`
# already established.
void
register(self, app, opts = &PL_sv_undef)
        SV *self
        SV *app
        SV *opts
    CODE:
    {
        HV *h = app_hv(aTHX_ app);
        PERL_UNUSED_VAR(self);
        if (SvOK(opts) && SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV) {
            HV *o = (HV *)SvRV(opts);
            HE *he;
            hv_iterinit(o);
            while ((he = hv_iternext(o)))
                croak("Punk::Plugin::ConditionalGet: unknown option '%s' - "
                      "there is nothing to configure here; the decision is "
                      "per route, as `etag`", HePV(he, PL_na));
        }
        (void)hv_stores(h, K_CGET, newSViv(1));
    }

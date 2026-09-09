MODULE = Punk::SAML  PACKAGE = Punk::Plugin::SAML

# The plugin object and its registration.
#
# Both `import` and `register` install the keywords. Punk makes a second
# install by the same owner a no-op, which is what lets an application say
# `use Punk::Plugin::SAML` for the keywords at compile time and
# `plugin 'SAML' => {...}` for the settings, in either order, without the
# second undoing the first.

# `use Punk::Plugin::SAML` installs the keywords at COMPILE time, which is
# the only moment that helps: `saml_idp okta => {...}` is a bareword call
# and perl has to know the name before it parses the line. `plugin 'SAML'`
# runs at runtime of the package body, long after those lines were
# compiled, so a keyword installed only there is one perl has already
# refused to parse. Punk-Feed, Punk::Plugin::Queue and ::OpenTelemetry all
# split it this way and for this reason.
#
# Silent in a package that is not a Punk application: `use` from a script
# has nothing to install onto and no reason to complain.
void
import(class, ...)
        SV *class
    CODE:
        const char *pkg = CopSTASHPV(PL_curcop);
        SV *pkgsv, *appsv;
        PERL_UNUSED_VAR(class);
        PERL_UNUSED_VAR(items);
        if (!pkg) XSRETURN_EMPTY;
        pkgsv = sv_2mortal(newSVpv(pkg, 0));
        if (!psaml_can(aTHX_ pkgsv, "punk_app")) XSRETURN_EMPTY;
        appsv = sv_2mortal(psaml_call(aTHX_ pkgsv, "punk_app", NULL, 0));
        if (appsv && SvROK(appsv)) psaml_install_kw(aTHX_ appsv);
        XSRETURN_EMPTY;

SV *
new(class, ...)
        SV *class
    CODE:
        HV *self = newHV();
        PERL_UNUSED_VAR(items);
        RETVAL = sv_bless(newRV_noinc((SV *)self),
                          gv_stashsv(class, GV_ADD));
    OUTPUT:
        RETVAL

# register($app, \%opts): validate the options, record them, install the
# keywords and the helpers, and book the on_compile that needs `host`.
void
register(self, app, opts = &PL_sv_undef)
        SV *self
        SV *app
        SV *opts
    CODE:
        HV *validated;
        PERL_UNUSED_VAR(self);
        if (!app || !SvROK(app))
            croak("%s: register needs the Punk::App", PSAML_WHO);
        validated = psaml_opts(aTHX_ app, opts);
        psaml_app_set(aTHX_ app, PSAML_K_OPTS,
                      newRV_noinc((SV *)validated));
        /* Again, for `plugin 'SAML'` with no `use`: the parenthesised form
         * of a keyword resolves at runtime, and this is what it finds. */
        psaml_install_kw(aTHX_ app);
        psaml_install_rest(aTHX_ app);

# _refetch_idp($app, $name, $now): re-read one provider's metadata and
# merge it into the recorded configuration, returning whether it happened.
#
# The ACS failure path calls this through call_method with G_EVAL rather
# than calling psaml_idp_refetch directly, and that is the whole reason it
# is an XSUB: the refetch croaks when the provider cannot be reached, and
# an unreachable provider during somebody's login has to become a refused
# login rather than a 500. Going out through Perl is how C code in this
# dist gets an exception frame.
#
# Not public API, for the same reason _state is not.
IV
_refetch_idp(class, app, name, now)
        SV *class
        SV *app
        SV *name
        IV now
    CODE:
        HV *opts;
        HV *cfg = NULL;
        SV *idpsv;
        PERL_UNUSED_VAR(class);
        if (!app || !SvROK(app))
            croak("%s: _refetch_idp needs the Punk::App", PSAML_WHO);
        opts  = psaml_opts_of(aTHX_ app);
        idpsv = psaml_app_get(aTHX_ app, PSAML_K_IDPS);
        if (opts && idpsv && SvROK(idpsv) && name && SvOK(name)) {
            STRLEN nl;
            const char *np = SvPV_const(name, nl);
            SV **e = hv_fetch((HV *)SvRV(idpsv), np, (I32)nl, 0);
            if (e && *e && SvROK(*e)) cfg = (HV *)SvRV(*e);
        }
        RETVAL = cfg ? psaml_idp_refetch(aTHX_ app, opts, name, cfg, now) : 0;
    OUTPUT:
        RETVAL

# The recorded state, for t/. Not public API and not documented: the
# application hash is Punk's, and a plugin that invited callers to read
# its keys would have made them interface.
SV *
_state(class, app, key)
        SV *class
        SV *app
        const char *key
    CODE:
        SV *v;
        PERL_UNUSED_VAR(class);
        v = psaml_app_get(aTHX_ app, key);
        /* XSRETURN_UNDEF, never `RETVAL = &PL_sv_undef`: xsubpp mortalises
         * RETVAL, and a mortalise on an immortal spends a reference nobody
         * took. Harmless from perl 5.20 and fatal before it. */
        if (!v) XSRETURN_UNDEF;
        RETVAL = newSVsv(v);
    OUTPUT:
        RETVAL

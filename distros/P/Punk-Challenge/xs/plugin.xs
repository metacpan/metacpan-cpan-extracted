MODULE = Punk::Challenge    PACKAGE = Punk::Plugin::Challenge

# The plugin object. Punk::Plugin's own new, so a plugin that carries no
# state costs one hash and nothing else.

SV *
new(class)
        SV *class
    CODE:
    {
        HV *self = newHV();
        const char *pkg = PCHAL_WHO;
        STRLEN pkgl = sizeof(PCHAL_WHO) - 1;
        if (SvOK(class) && !SvROK(class)) pkg = SvPV(class, pkgl);
        RETVAL = sv_bless(newRV_noinc((SV *)self),
                          gv_stashpvn(pkg, (I32)pkgl, GV_ADD));
    }
    OUTPUT:
        RETVAL

# Installs the keywords at COMPILE time, which is the only moment that makes
# the bareword forms parse:
#
#     challenge for => '/login', always => 1;
#     under '/register' => challenge_guard;
#
# `plugin 'Challenge'` runs at RUNTIME of the package body, long after the
# statements above have been compiled, so a keyword installed only there is
# one perl has already refused to parse.
#
# Silent in a package that is not a Punk application: `use
# Punk::Plugin::Challenge` from a script has nothing to install onto and no
# reason to complain.

void
import(class, ...)
        SV *class
    CODE:
    {
        const char *pkg = CopSTASHPV(PL_curcop);
        SV *pkgsv, *appsv;
        PERL_UNUSED_VAR(class);
        PERL_UNUSED_VAR(items);
        if (!pkg) XSRETURN_EMPTY;
        pkgsv = sv_2mortal(newSVpv(pkg, 0));
        if (!pchal_can(aTHX_ pkgsv, "punk_app")) XSRETURN_EMPTY;
        appsv = sv_2mortal(pchal_call(aTHX_ pkgsv, "punk_app", NULL, 0));
        if (appsv && SvROK(appsv)) pchal_install_kws(aTHX_ appsv);
        XSRETURN_EMPTY;
    }

# register($app, \%opts)
#
# Validates the options and leaves them on the application, installs the
# keywords again for the parenthesised forms without the `use`, the helpers
# once, the rule hook and its boot check, the interstitial, and the routes
# with the solver they serve.

void
register(self, app, opts = &PL_sv_undef)
        SV *self
        SV *app
        SV *opts
    CODE:
    {
        HV *h = pchal_app_hv(aTHX_ app);
        HV *o;
        PERL_UNUSED_VAR(self);
        if (!h) croak("%s: register needs the Punk::App", PCHAL_WHO);

        o = pchal_opts(aTHX_ opts);
        (void)hv_stores(h, "challenge_opts", newRV_noinc((SV *)o));

        pchal_install_kws(aTHX_ app);
        pchal_install_helpers(aTHX_ app);
        pchal_install_hook(aTHX_ app);
        pchal_install_page(aTHX_ app, o);
        pchal_install_routes(aTHX_ app, o);
        XSRETURN_EMPTY;
    }

# ---- private, reading back what boot recorded -------------------------------

SV *
_opts(app)
        SV *app
    CODE:
    {
        HV *h = pchal_app_hv(aTHX_ app);
        SV *o = h ? pchal_hget(aTHX_ h, "challenge_opts") : NULL;
        RETVAL = o ? newSVsv(o) : newSV(0);
    }
    OUTPUT:
        RETVAL

# The rules, in declaration order, as hashrefs a test can read.

SV *
_rules(app)
        SV *app
    CODE:
    {
        HV *h = pchal_app_hv(aTHX_ app);
        SV *r = h ? pchal_hget(aTHX_ h, "challenge_rules") : NULL;
        AV *out = newAV();
        if (pchal_is_array(r)) {
            AV *rules = (AV *)SvRV(r);
            SSize_t i, n = av_len(rules) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(rules, i, 0);
                if (e && *e && pchal_is_hash(*e))
                    av_push(out, newSVsv(*e));
            }
        }
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

# What a guard from challenge_guard captured as its difficulty: the explicit
# bits, or undef for "the plugin's default when it runs".

SV *
_guard_bits(guard)
        SV *guard
    CODE:
    {
        SV *b;
        if (!pchal_is_code(guard))
            croak("%s: _guard_bits needs a guard", PCHAL_WHO);
        b = pchal_cap_slot(aTHX_ (CV *)SvRV(guard), 1);
        RETVAL = b ? newSVsv(b) : newSV(0);
    }
    OUTPUT:
        RETVAL

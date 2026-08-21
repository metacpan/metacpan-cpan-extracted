MODULE = Punk        PACKAGE = Punk::Plugin::Sitemap

PROTOTYPES: DISABLE

SV *
new(class)
        SV *class
    CODE:
        RETVAL = sv_bless(newRV_noinc(newSViv(0)),
                          gv_stashpv(SvPV_nolen(class), GV_ADD));
    OUTPUT:
        RETVAL

# use Punk::Plugin::Sitemap;
#
# Installs the `sitemap` keyword at COMPILE time, which is the only moment
# that makes the bareword form parse:
#
#     sitemap users => sub { ... };
#
# `plugin 'Sitemap'` runs at RUNTIME of the package body, long after the
# statement above has been compiled, so a keyword installed only there is one
# perl has already refused to parse. Punk::Plugin::Queue and ::OpenTelemetry
# split it the same way and for the same reason.
#
# Without the `use`, the parenthesised form still works, because perl resolves
# a call with parentheses at runtime:
#
#     sitemap('users' => sub { ... });
void
import(class, ...)
        SV *class
    CODE:
    {
        const char *pkg = CopSTASHPV(PL_curcop);
        SV *pkgsv, *appsv;
        PERL_UNUSED_VAR(class);
        if (!pkg) XSRETURN_EMPTY;
        pkgsv = sv_2mortal(newSVpv(pkg, 0));
        /* Not a Punk application: nothing to install a keyword on, and that
         * is legitimate - a test or a script may load this for its class
         * methods alone. Silence rather than a croak, because the failure
         * mode for getting the order wrong (`use Punk` second) is perl
         * refusing to compile the `sitemap` line, which says so itself. */
        if (!pkc_can_meth(aTHX_ pkgsv, "punk_app")) XSRETURN_EMPTY;
        appsv = pcx_call_meth(aTHX_ pkgsv, "punk_app", NULL, 0, 1);
        if (appsv) {
            pks_install_kw(aTHX_ sv_2mortal(appsv));
        }
    }

# register($app, \%opts)
#
# `base` is REQUIRED and is configuration, with no default and no fallback to
# the request's Host. The sitemap protocol wants absolute URLs, and taking the
# host from the request means an attacker sending `Host: evil.example` gets a
# sitemap naming their host for every page on the site - delivered to search
# engines, and invisible to the owner, whose own request produces a correct
# file. Same shape as `session` refusing to start without a secret.
void
register(self, app, opts = &PL_sv_undef)
        SV *self
        SV *app
        SV *opts
    CODE:
    {
        HV *h = app_hv(aTHX_ app);
        SV **b = NULL;
        PERL_UNUSED_VAR(self);
        if (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
            b = hv_fetchs((HV *)SvRV(opts), "base", 0);
        if (!(b && *b && SvOK(*b) && SvCUR(*b)))
            croak("Punk::Plugin::Sitemap: `base` is required - the sitemap "
                  "protocol needs absolute URLs, and taking the host from the "
                  "request would let a crawler be handed somebody else's "
                  "hostname (plugin 'Sitemap' => { base => 'https://...' })");
        (void)hv_stores(h, "sitemap_base", newSVsv(*b));
        {   /* the routes this plugin adds for itself: out of the sitemap,
             * and out of robots.txt's Disallow list too */
            AV *own = newAV();
            av_push(own, newSVpvs("/sitemap.xml"));
            av_push(own, newSVpvs("/sitemap/:n"));
            av_push(own, newSVpvs("/robots.txt"));
            (void)hv_stores(h, "sitemap_own", newRV_noinc((SV *)own));
        }

        /* Both documents are served from the site ROOT regardless of any
         * mount prefix: /sitemap.xml is a fixed location and a crawler will
         * not look anywhere else. */
        {
            SV *argv[5];
            AV *cap;
            SV *r;

            /* /sitemap.xml - the index, or the single part. Opts itself out,
             * because a sitemap listing itself is noise a crawler follows. */
            cap = newAV();
            av_push(cap, newSVsv(app));
            av_push(cap, newSViv(0));
            argv[0] = sv_2mortal(newSVpvs("GET"));
            argv[1] = sv_2mortal(newSVpvs("/sitemap.xml"));
            argv[2] = sv_2mortal(punk_closure(aTHX_ pks_serve_cb, cap));
            argv[3] = &PL_sv_undef;
            {
                HV *o = newHV();
                (void)hv_stores(o, K_SITEMAP, newSViv(0));
                argv[4] = sv_2mortal(newRV_noinc((SV *)o));
            }
            r = pcx_call_meth(aTHX_ app, "route", argv, 5, 1);
            if (r) SvREFCNT_dec(r);

            /* /sitemap/1.xml, /2.xml and so on. A capture, so phase 1's rules
             * keep it out of the sitemap with no option needed. */
            cap = newAV();
            av_push(cap, newSVsv(app));
            av_push(cap, newSViv(1));
            argv[0] = sv_2mortal(newSVpvs("GET"));
            argv[1] = sv_2mortal(newSVpvs("/sitemap/:n"));
            argv[2] = sv_2mortal(punk_closure(aTHX_ pks_serve_cb, cap));
            argv[3] = &PL_sv_undef;
            argv[4] = &PL_sv_undef;
            r = pcx_call_meth(aTHX_ app, "route", argv, 5, 1);
            if (r) SvREFCNT_dec(r);

            /* /robots.txt, from the same exclusion list. Opts itself out
             * of the sitemap, and is served from the root for the same
             * reason /sitemap.xml is. */
            cap = newAV();
            av_push(cap, newSVsv(app));
            argv[0] = sv_2mortal(newSVpvs("GET"));
            argv[1] = sv_2mortal(newSVpvs("/robots.txt"));
            argv[2] = sv_2mortal(punk_closure(aTHX_ pks_robots_cb, cap));
            argv[3] = &PL_sv_undef;
            {
                HV *o = newHV();
                (void)hv_stores(o, K_SITEMAP, newSViv(0));
                argv[4] = sv_2mortal(newRV_noinc((SV *)o));
            }
            r = pcx_call_meth(aTHX_ app, "route", argv, 5, 1);
            if (r) SvREFCNT_dec(r);

            /* the `sitemap` keyword, for the URLs the route table cannot
             * know, and the TTL that bounds how stale they may be. */
            {
                SV *t = (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
                        ? *(hv_fetchs((HV *)SvRV(opts), "ttl", 1)) : NULL;
                SV **d = (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
                         ? hv_fetchs((HV *)SvRV(opts), "disallow", 0) : NULL;
                SV **da = (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
                          ? hv_fetchs((HV *)SvRV(opts), "disallow_all", 0) : NULL;
                if (d && *d && SvROK(*d) && SvTYPE(SvRV(*d)) == SVt_PVAV)
                    (void)hv_stores(h, "sitemap_disallow", newSVsv(*d));
                if (da && *da) (void)hv_stores(h, "sitemap_disallow_all",
                                               newSViv(SvTRUE(*da) ? 1 : 0));
                (void)hv_stores(h, "sitemap_ttl",
                                (t && SvOK(t) && SvNV(t) > 0)
                                    ? newSVnv(SvNV(t)) : newSVnv(3600.0));
                pks_install_kw(aTHX_ app);
            }

            /* and the build itself, at to_app */
            cap = newAV();
            av_push(cap, newSVsv(app));
            argv[0] = sv_2mortal(punk_closure(aTHX_ pks_mw_cb, cap));
            r = pcx_call_meth(aTHX_ app, "middleware", argv, 1, 1);
            if (r) SvREFCNT_dec(r);
        }
    }

# The rendered document for a part, or the index. Private, and what the
# phase-2 tests parse.
SV *
_doc(class, app, n = 0)
        SV *class
        SV *app
        IV n
    CODE:
    {
        HV *h = app_hv(aTHX_ app);
        SV *doc = NULL;
        PERL_UNUSED_VAR(class);
        if (!h) XSRETURN_UNDEF;
        /* the same refresh a request would trigger - a seam that behaved
         * differently from the serve path would prove nothing */
        pks_ensure(aTHX_ app);
        if (n <= 0) {
            /* /sitemap.xml: the index when there is more than one part, and
             * otherwise the single part itself. */
            doc = app_get(aTHX_ h, "sitemap_index");
            if (!(doc && SvOK(doc))) n = 1;
        }
        if (n > 0) {
            SV *ps = app_get(aTHX_ h, "sitemap_parts");
            AV *parts = (ps && SvROK(ps) && SvTYPE(SvRV(ps)) == SVt_PVAV)
                        ? (AV *)SvRV(ps) : NULL;
            SV **e = parts ? av_fetch(parts, (SSize_t)(n - 1), 0) : NULL;
            doc = (e && *e) ? *e : NULL;
        }
        if (!(doc && SvOK(doc))) XSRETURN_UNDEF;
        RETVAL = newSVsv(doc);
    }
    OUTPUT:
        RETVAL

# How many <urlset> parts the document split into.
IV
_parts(class, app)
        SV *class
        SV *app
    CODE:
    {
        HV *h = app_hv(aTHX_ app);
        SV *ps;
        PERL_UNUSED_VAR(class);
        if (h) pks_ensure(aTHX_ app);
        ps = h ? app_get(aTHX_ h, "sitemap_parts") : NULL;
        RETVAL = (ps && SvROK(ps) && SvTYPE(SvRV(ps)) == SVt_PVAV)
                 ? (IV)(av_len((AV *)SvRV(ps)) + 1) : 0;
    }
    OUTPUT:
        RETVAL

# Render now. Called from the middleware wrapper below, which Punk invokes at
# to_app - the only moment every route has been declared and nothing has been
# served yet.
void
_build(class, app)
        SV *class
        SV *app
    CODE:
        PERL_UNUSED_VAR(class);
        pks_build(aTHX_ app);

# The robots.txt body. Private, and what the phase-4 tests compare against
# the sitemap so the two cannot be shown to disagree.
SV *
_robots(class, app)
        SV *class
        SV *app
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pks_robots(aTHX_ app);
    OUTPUT:
        RETVAL

# The candidate paths, in sorted order. Private, and the seam the phase-1
# tests assert through: a guarded route being ABSENT is the claim, and a
# claim needs something to look at.
void
_paths(class, app)
        SV *class
        SV *app
    PPCODE:
    {
        AV *out = (AV *)sv_2mortal((SV *)pks_paths(aTHX_ app));
        SSize_t i, n = av_len(out) + 1;
        PERL_UNUSED_VAR(class);
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch(out, i, 0))));
    }

# The configured base, for phase 2 to join paths onto.
SV *
_base(class, app)
        SV *class
        SV *app
    CODE:
    {
        HV *h = app_hv(aTHX_ app);
        SV *b = h ? app_get(aTHX_ h, "sitemap_base") : NULL;
        PERL_UNUSED_VAR(class);
        if (!(b && SvOK(b))) XSRETURN_UNDEF;
        RETVAL = newSVsv(b);
    }
    OUTPUT:
        RETVAL

MODULE = Punk        PACKAGE = Punk::Plugin::Health

PROTOTYPES: DISABLE

SV *
new(class)
        SV *class
    CODE:
        RETVAL = sv_bless(newRV_noinc(newSViv(0)),
                          gv_stashpv(SvPV_nolen(class), GV_ADD));
    OUTPUT:
        RETVAL

# register($app, \%opts)
#
# Two routes, and the difference between them is the plugin:
#
#   /healthz  liveness  - checks NOTHING, because failing it restarts the
#                         worker, and restarting a worker does not fix a
#                         database.
#   /readyz   readiness - runs the checks, and failing it only takes this
#                         worker out of the pool.
#
# Both default to bare `{"status":"ok"}`. Health output names an
# application's internal dependencies, and the endpoints are unauthenticated
# because a probe cannot hold a credential - so the detail is behind an
# option rather than on by default.
void
register(self, app, opts = &PL_sv_undef)
        SV *self
        SV *app
        SV *opts
    CODE:
    {
        HV *h = app_hv(aTHX_ app);
        HV *o = (SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV)
                ? (HV *)SvRV(opts) : NULL;
        SV **v;
        SV *live_path  = NULL, *ready_path = NULL;
        int have_live = 1, have_ready = 1;
        PERL_UNUSED_VAR(self);

        if (!h) croak("Punk::Plugin::Health: no application");

        /* Time::HiRes for the budget and the ms figures. A prerequisite of
         * perl itself, but `require`d rather than assumed loaded. */
        (void)pk_require_once(aTHX_ "Time::HiRes", TRUE);

        /* Paths. An explicit undef DISABLES that endpoint - an application
         * whose platform only probes one of them should be able to say so,
         * rather than serving an endpoint nobody asked for. */
        if (o && (v = hv_fetchs(o, "liveness", 0))) {
            if (SvOK(*v) && SvCUR(*v)) live_path = newSVsv(*v);
            else have_live = 0;
        }
        if (o && (v = hv_fetchs(o, "readiness", 0))) {
            if (SvOK(*v) && SvCUR(*v)) ready_path = newSVsv(*v);
            else have_ready = 0;
        }
        if (have_live  && !live_path)  live_path  = newSVpvs("/healthz");
        if (have_ready && !ready_path) ready_path = newSVpvs("/readyz");

        if (o && (v = hv_fetchs(o, "detail", 0)))
            (void)hv_stores(h, "health_detail", newSViv(SvTRUE(*v) ? 1 : 0));
        if (o && (v = hv_fetchs(o, "version", 0)) && SvOK(*v))
            (void)hv_stores(h, "health_version", newSVsv(*v));

        /* ttl: how long a readiness answer may be reused. Zero disables the
         * cache, which is a real choice for an application whose checks are
         * free, and 0.1s of staleness is not what makes a probe wrong. */
        {
            double ttl = PH_DEFAULT_TTL;
            if (o && (v = hv_fetchs(o, "ttl", 0)) && SvOK(*v)) {
                ttl = SvNV(*v);
                if (ttl < 0)
                    croak("Punk::Plugin::Health: `ttl` cannot be negative");
            }
            (void)hv_stores(h, "health_ttl", newSVnv(ttl));
        }

        /* timeout: the budget for the whole readiness pass. NOT a timeout in
         * the sense of interrupting anything - nothing here can unblock a
         * check already waiting in a driver, and the POD says so. It stops
         * further checks being STARTED once the time is spent. */
        {
            double budget = PH_DEFAULT_BUDGET;
            if (o && (v = hv_fetchs(o, "timeout", 0)) && SvOK(*v)) {
                budget = SvNV(*v);
                if (budget <= 0)
                    croak("Punk::Plugin::Health: `timeout` must be positive "
                          "- it is the budget for the readiness checks, and "
                          "a budget of zero would report unready always");
            }
            (void)hv_stores(h, "health_budget", newSVnv(budget));
        }

        if (o && (v = hv_fetchs(o, "checks", 0)) && SvOK(*v)) {
            HV *ch;
            HE *ent;
            if (!(SvROK(*v) && SvTYPE(SvRV(*v)) == SVt_PVHV))
                croak("Punk::Plugin::Health: `checks` takes a hashref of "
                      "name => sub { ... }");
            ch = (HV *)SvRV(*v);
            hv_iterinit(ch);
            while ((ent = hv_iternext(ch))) {
                SV *cb = HeVAL(ent);
                if (!(cb && SvROK(cb) && SvTYPE(SvRV(cb)) == SVt_PVCV))
                    croak("Punk::Plugin::Health: the `%" SVf "` check is not "
                          "a coderef", SVfARG(hv_iterkeysv(ent)));
            }
            (void)hv_stores(h, "health_checks", newSVsv(*v));
        }

        /* The paths this plugin owns, so anything counting requests can skip
         * them. Punk logs no access line of its own, so there is nothing here
         * to exclude from - but a probe every second will dominate any
         * metric an observer keeps, and an observer can only skip what it can
         * name. */
        {
            AV *own = newAV();
            if (live_path)  av_push(own, newSVsv(live_path));
            if (ready_path) av_push(own, newSVsv(ready_path));
            (void)hv_stores(h, "health_paths", newRV_noinc((SV *)own));
        }

        {
            SV *argv[5];
            AV *cap;
            SV *r;

            if (live_path) {
                cap = newAV();
                av_push(cap, newSVsv(app));
                argv[0] = sv_2mortal(newSVpvs("GET"));
                argv[1] = sv_2mortal(live_path);
                argv[2] = sv_2mortal(punk_closure(aTHX_ ph_live_cb, cap));
                argv[3] = &PL_sv_undef;
                {   /* out of the sitemap: a probe endpoint is not a page, and
                     * a crawler following one is pure noise. */
                    HV *ro = newHV();
                    (void)hv_stores(ro, K_SITEMAP, newSViv(0));
                    argv[4] = sv_2mortal(newRV_noinc((SV *)ro));
                }
                r = pcx_call_meth(aTHX_ app, "route", argv, 5, 1);
                if (r) SvREFCNT_dec(r);
            }

            if (ready_path) {
                cap = newAV();
                av_push(cap, newSVsv(app));
                argv[0] = sv_2mortal(newSVpvs("GET"));
                argv[1] = sv_2mortal(ready_path);
                argv[2] = sv_2mortal(punk_closure(aTHX_ ph_ready_cb, cap));
                argv[3] = &PL_sv_undef;
                {
                    HV *ro = newHV();
                    (void)hv_stores(ro, K_SITEMAP, newSViv(0));
                    argv[4] = sv_2mortal(newRV_noinc((SV *)ro));
                }
                r = pcx_call_meth(aTHX_ app, "route", argv, 5, 1);
                if (r) SvREFCNT_dec(r);
            }
        }
    }

# The paths the plugin serves, for an observer that wants to skip them.
void
paths(class, app)
        SV *class
        SV *app
    PPCODE:
    {
        HV *h = app_hv(aTHX_ app);
        SV *own = h ? app_get(aTHX_ h, "health_paths") : NULL;
        AV *av = (own && SvROK(own) && SvTYPE(SvRV(own)) == SVt_PVAV)
                 ? (AV *)SvRV(own) : NULL;
        SSize_t i, n = av ? av_len(av) + 1 : 0;
        PERL_UNUSED_VAR(class);
        EXTEND(SP, n);
        for (i = 0; i < n; i++)
            PUSHs(sv_2mortal(newSVsv(*av_fetch(av, i, 0))));
    }

# _ready($app, $c) -> (ready, detail_json)
#
# The readiness pass with the response and the cache taken off it, so a test
# can assert what the checks decided rather than parsing a body. Private.
void
_ready(class, app, c = &PL_sv_undef)
        SV *class
        SV *app
        SV *c
    PPCODE:
    {
        SV *det = sv_2mortal(newSVpvs(""));
        int ready;
        PERL_UNUSED_VAR(class);
        ready = ph_readiness(aTHX_ app, SvOK(c) ? c : NULL, det);
        /* ph_readiness runs Perl, which may have reallocated the stack. */
        SP = PL_stack_base + ax - 1;
        EXTEND(SP, 2);
        PUSHs(sv_2mortal(newSViv(ready)));
        PUSHs(sv_2mortal(newSVsv(det)));
    }

# Drop a cached readiness answer, so a test does not have to sleep out a ttl.
void
_uncache(class, app)
        SV *class
        SV *app
    CODE:
    {
        HV *h = app_hv(aTHX_ app);
        PERL_UNUSED_VAR(class);
        if (h) (void)hv_delete(h, "health_cached",
                               (I32)(sizeof("health_cached") - 1), G_DISCARD);
    }

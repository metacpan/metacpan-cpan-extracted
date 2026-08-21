MODULE = Punk        PACKAGE = Punk::Plugin::Metrics

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
        SV *path = NULL;
        PERL_UNUSED_VAR(self);

        if (!h) croak("Punk::Plugin::Metrics: no application");

        if (o && (v = hv_fetchs(o, "path", 0)) && SvOK(*v) && SvCUR(*v))
            path = newSVsv(*v);
        else
            path = newSVpvs("/metrics");

        if (o && (v = hv_fetchs(o, "collect", 0)) && SvOK(*v)) {
            if (!(SvROK(*v) && SvTYPE(SvRV(*v)) == SVt_PVCV))
                croak("Punk::Plugin::Metrics: `collect` takes a coderef "
                      "returning a hashref of name => number");
            (void)hv_stores(h, "metrics_collect", newSVsv(*v));
        }

        (void)hv_stores(h, "metrics_path", newSVsv(path));

        pm_init(aTHX);

        /* This scrape endpoint, ADDED to the set rather than replacing it -
         * see the note on PM_SKIP. Every metrics path in the process is
         * excluded, whichever application declared it. */
        (void)hv_store_ent(PM_SKIP, path, newSViv(1), 0);

        /* Registered ONCE per process. The registry is a static array with no
         * removal, so registering per application would count every request
         * twice in a test file that builds two apps - and silently, since
         * both numbers look plausible. */
        if (!PM_OBSERVING) {
            PM_OBSERVING = 1;
            (void)pk_obs_add_req(aTHX_ pm_on_request,  NULL);
            (void)pk_obs_add_res(aTHX_ pm_on_response, NULL);
        }

        {
            SV *argv[5];
            AV *cap = newAV();
            SV *r;
            av_push(cap, newSVsv(app));
            argv[0] = sv_2mortal(newSVpvs("GET"));
            argv[1] = sv_2mortal(path);
            argv[2] = sv_2mortal(punk_closure(aTHX_ pm_serve_cb, cap));
            argv[3] = &PL_sv_undef;
            {   /* out of the sitemap: a scrape target is not a page */
                HV *ro = newHV();
                (void)hv_stores(ro, K_SITEMAP, newSViv(0));
                argv[4] = sv_2mortal(newRV_noinc((SV *)ro));
            }
            r = pcx_call_meth(aTHX_ app, "route", argv, 5, 1);
            if (r) SvREFCNT_dec(r);
        }
    }

# The exposition document, without going through a request. Private.
SV *
_render(class, app)
        SV *class
        SV *app
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pm_render(aTHX_ app);
    OUTPUT:
        RETVAL

# The bucket boundaries, so a test asserts the documented set rather than
# whatever the code happens to hold.
void
buckets(class)
        SV *class
    PPCODE:
    {
        int i;
        PERL_UNUSED_VAR(class);
        EXTEND(SP, PM_NBUCKETS);
        for (i = 0; i < PM_NBUCKETS; i++)
            PUSHs(sv_2mortal(newSVnv(PM_BUCKETS[i])));
    }

# Drop everything counted so far. Private: the counters are process-wide, so
# a test asserting a number needs to know where it started from.
void
_reset(class)
        SV *class
    CODE:
        PERL_UNUSED_VAR(class);
        pm_init(aTHX);
        hv_clear(PM_TOTAL);
        hv_clear(PM_HIST);
        PM_INFLIGHT = 0;

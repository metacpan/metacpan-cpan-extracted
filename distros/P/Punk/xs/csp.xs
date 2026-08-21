MODULE = Punk        PACKAGE = Punk::Plugin::CSP

PROTOTYPES: DISABLE

# register($app, \%opts)
#
# Freezes the policy onto the app, where the compile step copies it into the
# compiled state and phd_effective reads it once per response. Every directive
# is checked HERE, at boot, because a value carrying a newline would split the
# response and a policy that is not the one that was written is worse than no
# policy at all.
void
register(self, app, opts = &PL_sv_undef)
        SV *self
        SV *app
        SV *opts
    CODE:
    {
        HV *h = app_hv(aTHX_ app);
        HV *cfg = newHV();
        PERL_UNUSED_VAR(self);
        if (SvOK(opts)) {
            HV *o;
            HE *he;
            if (!(SvROK(opts) && SvTYPE(SvRV(opts)) == SVt_PVHV))
                croak("Punk::Plugin::CSP: options must be a hashref");
            o = (HV *)SvRV(opts);
            hv_iterinit(o);
            while ((he = hv_iternext(o))) {
                STRLEN kl;
                const char *k = HePV(he, kl);
                SV *v = HeVAL(he);
                if (strEQ(k, "report_only")) {
                    /* A hashref here is a second policy; its directives get
                     * the same boot-time check as the first one's. */
                    if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) {
                        HV *ro = (HV *)SvRV(v);
                        HE *rhe;
                        hv_iterinit(ro);
                        while ((rhe = hv_iternext(ro)))
                            pcsp_check_value(aTHX_ HePV(rhe, PL_na),
                                             HeVAL(rhe));
                    }
                }
                else pcsp_check_value(aTHX_ k, v);
                (void)hv_store(cfg, k, (I32)kl, newSVsv(v), 0);
            }
        }
        (void)hv_stores(h, K_CSP, newRV_noinc((SV *)cfg));

        {   /* The report endpoint, mounted by the PLUGIN.
             *
             * It is a public unauthenticated POST that takes a body from
             * anybody, which is exactly why it belongs here rather than in
             * the application: without limits it is a free log-flooding
             * endpoint, and Punk has both limits already. Leaving them to the
             * application means the one application that forgets has an open
             * one.
             *
             * Only when report_uri names a LOCAL path. An absolute URL is
             * somebody else's collector and mounting a route for it would be
             * wrong. */
            SV **ru = hv_fetchs(cfg, "report_uri", 0);
            if (ru && *ru && SvOK(*ru)) {
                STRLEN ul;
                const char *up = SvPV_const(*ru, ul);
                if (ul > 1 && up[0] == '/') {
                    SV *argv[5];
                    AV *cap = newAV();
                    SV *r;
                    av_push(cap, newSVsv(app));
                    argv[0] = sv_2mortal(newSVpvs("POST"));
                    argv[1] = sv_2mortal(newSVpvn(up, ul));
                    argv[2] = sv_2mortal(punk_closure(aTHX_ pcsp_report_cb, cap));
                    argv[3] = &PL_sv_undef;
                    {   /* A violation report is small. Anything large is not
                         * a report, and parsing it first would be doing the
                         * work the limit exists to refuse. */
                        HV *o = newHV();
                        (void)hv_stores(o, K_MAX_BODY, newSViv(16384));
                        (void)hv_stores(o, K_SITEMAP,  newSViv(0));
                        argv[4] = sv_2mortal(newRV_noinc((SV *)o));
                    }
                    r = pcx_call_meth(aTHX_ app, "route", argv, 5, 1);
                    if (r) SvREFCNT_dec(r);

                    {   /* and a rate limit, per address and low */
                        SV *rl[6];
                        rl[0] = sv_2mortal(newSVpvs("for"));
                        rl[1] = sv_2mortal(newSVpvn(up, ul));
                        rl[2] = sv_2mortal(newSVpvs("limit"));
                        rl[3] = sv_2mortal(newSViv(60));
                        rl[4] = sv_2mortal(newSVpvs("window"));
                        rl[5] = sv_2mortal(newSViv(60));
                        r = pcx_call_meth(aTHX_ app, "rate_limit", rl, 6, 1);
                        if (r) SvREFCNT_dec(r);
                    }
                }
            }
        }

        {   /* $c->csp_nonce, for a handler building HTML or a JSON payload
             * that needs it. The same value the header carries and the same
             * one a template renders, because all three read the one the env
             * holds. */
            CV *cv = get_cv("Punk::Plugin::CSP::_nonce", 0);
            if (cv) {
                SV *argv[2];
                SV *r;
                argv[0] = sv_2mortal(newSVpvs("csp_nonce"));
                argv[1] = sv_2mortal(newRV_inc((SV *)cv));
                r = pcx_call_meth(aTHX_ app, "helper", argv, 2, 1);
                if (r) SvREFCNT_dec(r);
            }
        }
    }

# $c->csp_nonce - this request's nonce, minted on first ask.
#
# The same value the header carries, because both read the one the env holds:
# a nonce in the template that the header does not carry protects nothing and
# looks perfectly fine, which is the failure nobody notices.
SV *
_nonce(c)
        SV *c
    CODE:
    {
        AV *av = pcx_av(aTHX_ c);
        SV *e  = av ? pcx_get(aTHX_ av, PCX_ENV) : NULL;
        if (e && SvROK(e) && SvTYPE(SvRV(e)) == SVt_PVHV)
            RETVAL = newSVsv(pcsp_nonce(aTHX_ (HV *)SvRV(e)));
        else
            RETVAL = newSV(0);
    }
    OUTPUT:
        RETVAL

# What this process has been told about. A number nobody can see is a number
# nobody acts on, and a rising one during a report-only rollout is the whole
# reason to roll out that way.
void
stats(class = &PL_sv_undef)
        SV *class
    PPCODE:
    {
        PERL_UNUSED_VAR(class);
        EXTEND(SP, 8);
        mPUSHs(newSVpvs("reports"));   mPUSHu(pcsp_n_reports);
        mPUSHs(newSVpvs("malformed")); mPUSHu(pcsp_n_malformed);
        mPUSHs(newSVpvs("scanned"));   mPUSHu(pcsp_n_scanned);
        mPUSHs(newSVpvs("warned"));    mPUSHu(pcsp_n_warned);
        XSRETURN(8);
    }

MODULE = Punk        PACKAGE = Punk::Static

PROTOTYPES: DISABLE

# Punk::Static->app($dir, %opts) - the PSGI coderef serving that directory.
# The request path itself is punk_static_cb in include/punk/punk_static.h: a
# magic CV carrying the mount's whole configuration, so a request for a file
# crosses no Perl frame at all.
#
# Options: max_age (seconds of freshness for a plain URL), cache_control (a
# verbatim header value, overriding max_age), fingerprint (content-addressed
# URLs, on by default) and dev (re-check digests against the filesystem;
# defaults from PUNK_ENV, and the compiler passes the app's own env).
SV *
app(class, dir, ...)
        SV *class
        SV *dir
    CODE:
    {
        AV *cap;
        Stat_t st;
        HV *opts = NULL;
        SV **o;
        SV *cc = NULL;
        const char *d = SvPV_nolen(dir);
        /* fingerprinting is opt-in: it changes what a path MEANS - a URL
         * shaped like a fingerprint stops being a 404 and starts resolving
         * to another file - and that is not something a mount should start
         * doing because it was upgraded */
        int fingerprint = 0, dev = 0, i;
        PERL_UNUSED_VAR(class);

        if (PerlLIO_stat(d, &st) < 0 || !S_ISDIR(st.st_mode))
            croak("Punk::Static: '%s' is not a directory", d);

        /* a hashref or a flat list, so the compiler can hand over a mount
         * record's options without flattening them first */
        if (items == 3 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2))) == SVt_PVHV)
            opts = (HV *)SvRV(ST(2));
        else if (items > 2) {
            if ((items - 2) % 2)
                croak("Punk::Static: app takes a directory and an "
                      "even-sized option list");
            opts = (HV *)sv_2mortal((SV *)newHV());
            for (i = 2; i + 1 < items; i += 2) {
                STRLEN kl;
                const char *kp = SvPV_const(ST(i), kl);
                (void)hv_store(opts, kp, (I32)kl, newSVsv(ST(i + 1)), 0);
            }
        }

        if (opts) {
            static const char *const known[] = {
                "max_age", "cache_control", "fingerprint", "dev", NULL
            };
            HE *he;
            hv_iterinit(opts);
            while ((he = hv_iternext(opts))) {
                const char *k = HePV(he, PL_na);
                int ok = 0;
                for (i = 0; known[i]; i++) if (strEQ(k, known[i])) ok = 1;
                if (!ok)
                    croak("Punk::Static: unknown option '%s'", k);
            }
            o = hv_fetchs(opts, "fingerprint", 0);
            if (o && *o) fingerprint = SvTRUE(*o) ? 1 : 0;
            o = hv_fetchs(opts, "dev", 0);
            if (o && *o) dev = SvTRUE(*o) ? 1 : 0;
            else dev = (getenv("PUNK_ENV")
                        && strEQ(getenv("PUNK_ENV"), "development")) ? 1 : 0;
            /* cache_control is verbatim and wins; max_age is the spelling
             * that covers what almost everyone means by it */
            o = hv_fetchs(opts, "cache_control", 0);
            if (o && *o && SvOK(*o)) cc = newSVsv(*o);
            else {
                o = hv_fetchs(opts, "max_age", 0);
                if (o && *o && SvOK(*o)) {
                    cc = newSVpvs("public, max-age=");
                    sv_catpvf(cc, "%" IVdf, (IV)SvIV(*o));
                }
            }
        }
        else
            dev = (getenv("PUNK_ENV")
                   && strEQ(getenv("PUNK_ENV"), "development")) ? 1 : 0;

        cap = newAV();
        av_extend(cap, PSC_DEV);
        {   /* keep the directory without a trailing slash, so joining a
             * PATH_INFO (which always starts with one) cannot double it */
            STRLEN dlen;
            const char *p = SvPV_const(dir, dlen);
            while (dlen > 1 && p[dlen - 1] == '/') dlen--;
            (void)av_store(cap, PSC_DIR, newSVpvn(p, dlen));
        }
        (void)av_store(cap, PSC_CC, cc ? cc : newSV(0));
        /* A year and `immutable`, the only lifetime a content-addressed URL
         * wants: it is the largest value RFC 9111 asks caches to honour, and
         * `immutable` stops a reload revalidating a URL that cannot have
         * changed. It is sent only after the digest has been checked. */
        (void)av_store(cap, PSC_CC_IMM,
            fingerprint ? newSVpvs("public, max-age=31536000, immutable")
                        : newSV(0));
        (void)av_store(cap, PSC_CACHE,
            fingerprint ? newRV_noinc((SV *)newHV()) : newSV(0));
        (void)av_store(cap, PSC_DEV, dev ? newSViv(1) : newSV(0));
        RETVAL = punk_closure(aTHX_ punk_static_cb, cap);
    }
    OUTPUT:
        RETVAL

# The digest a fingerprinted URL for $url would carry, or undef when the
# mount does not fingerprint or the file cannot be read. $c->asset is the
# way to reach this; it is here so the mount's own cache answers.
SV *
_asset(app, url)
        SV *app
        SV *url
    CODE:
    {
        RETVAL = pa_asset_url(aTHX_ app, url);
        if (!RETVAL) RETVAL = newSVsv(url);
    }
    OUTPUT:
        RETVAL

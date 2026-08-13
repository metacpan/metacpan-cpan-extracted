MODULE = Punk        PACKAGE = Punk::App

PROTOTYPES: DISABLE

# rate_limit(limit => N, window => S, by => 'ip'|'header:X-Api-Key'|$coderef,
#            for => '/prefix', tag => 'name')
#
# The `rate_limit` keyword forwards here. Captures the rule into a magic-CV
# closure and pushes it onto before_dispatch (punk_ratelimit.h); the per-request
# enforcement then runs entirely in C. lib/Punk/RateLimit.pm is documentation.
# Chainable - declare it more than once for layered limits.
SV *
rate_limit(self, ...)
        SV *self
    CODE:
    {
        IV  limit = 60, window = 60, by = 0;
        SV *byfn = NULL;
        const char *envkey = "", *forp = NULL, *tag = NULL;
        STRLEN elen = 0, flen = 0, tlen = 0;
        SV *envkeysv = NULL;
        int i;

        if ((items - 1) % 2)
            croak("Punk: rate_limit takes a list of key => value options");

        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV *v = ST(i + 1);
            if (strEQ(k, "limit"))       limit  = SvOK(v) ? SvIV(v) : 0;
            else if (strEQ(k, "window")) window = SvIV(v);
            else if (strEQ(k, "for"))    { if (SvOK(v)) forp = SvPV(v, flen); }
            else if (strEQ(k, "tag"))    { if (SvOK(v)) tag  = SvPV(v, tlen); }
            else if (strEQ(k, "by")) {
                if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVCV) {
                    by = 2; byfn = v;
                } else if (SvOK(v)) {
                    STRLEN bl;
                    const char *bs = SvPV(v, bl);
                    if (bl > 7 && strnEQ(bs, "header:", 7)) {
                        STRLEN j;
                        by = 1;
                        envkeysv = sv_2mortal(newSVpvs("HTTP_"));
                        for (j = 7; j < bl; j++) {
                            char ch = bs[j];
                            ch = (ch == '-') ? '_' : (char)toupper((unsigned char)ch);
                            sv_catpvn(envkeysv, &ch, 1);
                        }
                        envkey = SvPV(envkeysv, elen);
                    }
                    /* anything else (including 'ip') keeps by = 0 */
                }
            }
        }

        /* tag default names the counter namespace so two rules never share a
         * counter: the header env key, or 'fn' / 'ip'. */
        if (!tag) {
            if      (by == 2) { tag = "fn"; tlen = 2; }
            else if (by == 1) { tag = envkey; tlen = elen; }
            else              { tag = "ip"; tlen = 2; }
        }

        prl_install(aTHX_ self, limit, window, by, envkey, elen,
                    forp, flen, tag, tlen, byfn);
        RETVAL = newSVsv(self);      /* chainable */
    }
    OUTPUT:
        RETVAL

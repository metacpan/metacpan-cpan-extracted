MODULE = Punk        PACKAGE = Punk::RateLimit

PROTOTYPES: DISABLE

# The boot half of the `rate_limit` ROUTE option (punk_ratelimit.h): called
# from Punk::App::compile_extras when any route carried one. Appends a C guard
# closure running the same check the keyword installs on before_dispatch -
# before the `validate` guard, so a refused request never parses a body.
void
_compile_routes(self)
        SV *self
    CODE:
        prl_compile_routes(aTHX_ self);

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

        # uncoverable branch true
        # uncoverable condition left count:1 class:ignore_covered_err
        if ((items - 1) % 2)
            croak("Punk: rate_limit takes a list of key => value options"); /* # uncoverable statement */

        for (i = 1; i + 1 < items; i += 2) {
            const char *k = SvPV_nolen(ST(i));
            SV *v = ST(i + 1);
            if (strEQ(k, "limit"))       limit  = SvOK(v) ? SvIV(v) : 0; /* # uncoverable condition right count:2 class:ignore_covered_err */
            else if (strEQ(k, "window")) window = SvIV(v);
            # uncoverable branch false count:1 class:ignore_covered_err
            # uncoverable branch true count:2 class:ignore_covered_err
            # uncoverable branch true count:3 class:ignore_covered_err
            # uncoverable condition right count:1 class:ignore_covered_err
            # uncoverable condition right count:2 class:ignore_covered_err
            else if (strEQ(k, "for"))    { if (SvOK(v)) forp = SvPV(v, flen); }
            # uncoverable statement class:ignore_covered_err
            # uncoverable branch true count:1 class:ignore_covered_err
            # uncoverable branch false count:1 class:ignore_covered_err
            # uncoverable branch true count:2 class:ignore_covered_err
            # uncoverable branch false count:2 class:ignore_covered_err
            # uncoverable branch true count:3 class:ignore_covered_err
            # uncoverable branch false count:3 class:ignore_covered_err
            # uncoverable condition left count:1 class:ignore_covered_err
            # uncoverable condition right count:1 class:ignore_covered_err
            # uncoverable condition left count:2 class:ignore_covered_err
            # uncoverable condition right count:2 class:ignore_covered_err
            else if (strEQ(k, "tag"))    { if (SvOK(v)) tag  = SvPV(v, tlen); }
            # uncoverable branch false class:ignore_covered_err
            # uncoverable statement class:ignore_covered_err
            # uncoverable branch true class:ignore_covered_err
            # uncoverable condition left count:1 class:ignore_covered_err
            # uncoverable condition right count:1 class:ignore_covered_err
            else if (strEQ(k, "by")) {
                # uncoverable statement class:ignore_covered_err
                # uncoverable branch true class:ignore_covered_err
                # uncoverable branch false class:ignore_covered_err
                # uncoverable condition left count:1 class:ignore_covered_err
                # uncoverable condition right count:1 class:ignore_covered_err
                # uncoverable condition left count:2 class:ignore_covered_err
                # uncoverable condition right count:2 class:ignore_covered_err
                if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVCV) {
                    by = 2; byfn = v; /* # uncoverable statement class:ignore_covered_err */
                # uncoverable branch false class:ignore_covered_err
                # uncoverable statement class:ignore_covered_err
                # uncoverable branch true class:ignore_covered_err
                # uncoverable condition left count:1 class:ignore_covered_err
                # uncoverable condition right count:1 class:ignore_covered_err
                } else if (SvOK(v)) {
                    STRLEN bl;
                    const char *bs = SvPV(v, bl); /* # uncoverable statement class:ignore_covered_err */
                    # uncoverable statement class:ignore_covered_err
                    # uncoverable branch true class:ignore_covered_err
                    # uncoverable branch false class:ignore_covered_err
                    # uncoverable condition left count:1 class:ignore_covered_err
                    # uncoverable condition right count:1 class:ignore_covered_err
                    # uncoverable condition left count:2 class:ignore_covered_err
                    # uncoverable condition right count:2 class:ignore_covered_err
                    if (bl > 7 && strnEQ(bs, "header:", 7)) {
                        by = 1; /* # uncoverable statement class:ignore_covered_err */
                        envkeysv = prl_header_envkey(aTHX_ bs, bl); /* # uncoverable statement class:ignore_covered_err */
                        envkey = SvPV(envkeysv, elen); /* # uncoverable statement class:ignore_covered_err */
                    }
                    /* anything else (including 'ip') keeps by = 0 */
                }
            }
        }

        /* tag default names the counter namespace so two rules never share a
         * counter: the header env key, or 'fn' / 'ip'. */
        # uncoverable branch false class:ignore_covered_err
        # uncoverable condition right count:1 class:ignore_covered_err
        if (!tag) {
            # uncoverable branch true
            # uncoverable condition left count:1 class:ignore_covered_err
            if      (by == 2) { tag = "fn"; tlen = 2; }
            # uncoverable branch true
            # uncoverable condition left count:1 class:ignore_covered_err
            else if (by == 1) { tag = envkey; tlen = elen; }
            else              { tag = "ip"; tlen = 2; }
        }

        prl_install(aTHX_ self, limit, window, by, envkey, elen,
                    forp, flen, tag, tlen, byfn);
        RETVAL = newSVsv(self);      /* chainable */
    }
    OUTPUT:
        RETVAL

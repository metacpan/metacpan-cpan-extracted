#ifndef PCHAL_BOOT_H
#define PCHAL_BOOT_H

/* Boot: the options, validated and normalised at the `plugin` line.
 *
 * State lives as keys on the application's own hash rather than in a struct,
 * which is what Punk-Feed does and for the same reason: the application is
 * already the thing whose lifetime this state shares, and a struct would be
 * a second one to keep in step with it.
 *
 *   challenge_opts   the validated option hash, every key present:
 *                      secret     AV of strings, newest first
 *                      prefix     rooted path, no trailing slash
 *                      bits       IV, 1..PCHAL_MAX_BITS
 *                      ttl        IV seconds
 *                      puzzle_ttl IV seconds
 *                      bind       "prefix", "ip" or "none"
 *                      cookie     the cookie name
 *                      exempt     AV of rooted path prefixes
 *                      render     undef, a coderef, or a method name
 *                      assets     0 or 1
 *
 * Must be included after pchal_reg.h.
 */

static const char *const PCHAL_OPTS[] = {
    "secret", "prefix", "bits", "ttl", "puzzle_ttl", "bind", "cookie",
    "exempt", "render", "assets", NULL
};

/* Nothing above 22 is accepted: at 24 a slow phone takes a minute and the
 * site is closed. */
#define PCHAL_MAX_BITS 22

/* A rooted, concrete path: starts with '/', no whitespace, no control
 * characters, no query or fragment. */
static int pchal_path_ok(const char *p, STRLEN l)
{
    STRLEN i;
    if (!l || p[0] != '/') return 0;
    for (i = 0; i < l; i++) {
        unsigned char c = (unsigned char)p[i];
        if (c <= 0x20 || c == 0x7f || c == '?' || c == '#') return 0;
    }
    return 1;
}

/* A string option: a defined, non-reference value with at least one byte.
 * NULL when absent. Croaks on a reference, because "prefix => [...]" is a
 * mistake and not a value. */
static SV *pchal_opt_str(pTHX_ HV *in, const char *k)
{
    SV *v = in ? pchal_hget(aTHX_ in, k) : NULL;
    if (!v) return NULL;
    if (SvROK(v))
        croak("%s: `%s` must be a string, not a reference", PCHAL_WHO, k);
    return v;
}

static IV pchal_opt_iv(pTHX_ HV *in, const char *k, IV dflt, IV lo, IV hi)
{
    SV *v = pchal_opt_str(aTHX_ in, k);
    IV n;
    if (!v) return dflt;
    if (!looks_like_number(v))
        croak("%s: `%s` must be a number, not '%" SVf "'", PCHAL_WHO, k,
              SVfARG(v));
    n = SvIV(v);
    if (n < lo || n > hi)
        croak("%s: `%s` must be between %" IVdf " and %" IVdf ", not %" IVdf,
              PCHAL_WHO, k, lo, hi, n);
    return n;
}

/* The secret. Configuration, never generated: Hyperman runs a pool, each
 * worker would mint its own, and a clearance issued by one worker would be
 * refused by every other - a challenge page that comes back one time in four
 * after it was solved, which nobody would connect to the configuration.
 *
 * A list rotates: the first issues, each is tried in turn on verify. */
static AV *pchal_opt_secret(pTHX_ HV *in)
{
    SV *v = in ? pchal_hget(aTHX_ in, "secret") : NULL;
    AV *keys = newAV();
    SV *rv = sv_2mortal(newRV_noinc((SV *)keys));
    SSize_t i, n;

    if (v && pchal_is_array(v)) {
        AV *list = (AV *)SvRV(v);
        n = av_len(list) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(list, i, 0);
            STRLEN l = 0;
            if (!(e && *e && SvOK(*e))) continue;
            if (SvROK(*e))
                croak("%s: every `secret` must be a string", PCHAL_WHO);
            (void)SvPV_const(*e, l);
            if (l) av_push(keys, newSVsv(*e));
        }
    }
    else if (v && !SvROK(v)) {
        STRLEN l = 0;
        (void)SvPV_const(v, l);
        if (l) av_push(keys, newSVsv(v));
    }
    else if (v) {
        croak("%s: `secret` must be a string or a list of strings", PCHAL_WHO);
    }

    if (av_len(keys) < 0)
        croak("%s: `secret` is required and is never generated for you - "
              "run `punk challenge key` and configure what it prints",
              PCHAL_WHO);

    return (AV *)SvREFCNT_inc_simple_NN(SvRV(rv));
}

/* Validate and normalise, at the `plugin` line. Every croak here names the
 * option, because the alternative is a setting that silently did not apply.
 *
 * The result is built behind a mortal so that a croak part-way frees it. */
static HV *pchal_opts(pTHX_ SV *optsv)
{
    HV *in = pchal_is_hash(optsv) ? (HV *)SvRV(optsv) : NULL;
    HV *out = newHV();
    SV *rv = sv_2mortal(newRV_noinc((SV *)out));
    SV *v;

    if (optsv && SvOK(optsv) && !in)
        croak("%s: options must be a hash reference", PCHAL_WHO);

    pchal_check_opts(aTHX_ "option", in, PCHAL_OPTS);

    (void)hv_stores(out, "secret", newRV_noinc((SV *)pchal_opt_secret(aTHX_ in)));

    {   /* prefix: the stem the verify route and the asset hang off */
        SV *p = pchal_opt_str(aTHX_ in, "prefix");
        SV *keep = p ? newSVsv(p) : newSVpvs("/challenge");
        STRLEN pl;
        const char *pp = SvPV_const(keep, pl);
        (void)hv_stores(out, "prefix", keep);
        /* a trailing slash would make the routes /challenge//verify */
        while (pl > 1 && pp[pl - 1] == '/') { SvCUR_set(keep, --pl); }
        pp = SvPV_const(keep, pl);
        if (!pchal_path_ok(pp, pl))
            croak("%s: `prefix` must be a rooted path, not '%" SVf "'",
                  PCHAL_WHO, SVfARG(keep));
    }

    (void)hv_stores(out, "bits",
                    newSViv(pchal_opt_iv(aTHX_ in, "bits", 16, 1, PCHAL_MAX_BITS)));
    (void)hv_stores(out, "ttl",
                    newSViv(pchal_opt_iv(aTHX_ in, "ttl", 3600, 1, IV_MAX)));
    (void)hv_stores(out, "puzzle_ttl",
                    newSViv(pchal_opt_iv(aTHX_ in, "puzzle_ttl", 300, 1, IV_MAX)));

    {   /* bind: what a puzzle and a clearance are tied to */
        SV *b = pchal_opt_str(aTHX_ in, "bind");
        const char *bp = "prefix";
        STRLEN bl = 6;
        if (b) bp = SvPV_const(b, bl);
        if (!((bl == 6 && memEQ(bp, "prefix", 6))
              || (bl == 2 && memEQ(bp, "ip", 2))
              || (bl == 4 && memEQ(bp, "none", 4))))
            croak("%s: `bind` must be 'prefix', 'ip' or 'none', not '%.*s'",
                  PCHAL_WHO, (int)bl, bp);
        (void)hv_stores(out, "bind", newSVpvn(bp, bl));
    }

    {   /* cookie: a token, in the RFC 6265 sense */
        SV *c = pchal_opt_str(aTHX_ in, "cookie");
        SV *keep = c ? newSVsv(c) : newSVpvs("_clearance");
        STRLEN cl, i;
        const char *cp = SvPV_const(keep, cl);
        (void)hv_stores(out, "cookie", keep);
        for (i = 0; i < cl; i++) {
            unsigned char ch = (unsigned char)cp[i];
            if (ch <= 0x20 || ch >= 0x7f || ch == ';' || ch == ',' || ch == '='
                || ch == '"' || ch == '(' || ch == ')' || ch == '<' || ch == '>'
                || ch == '@' || ch == ':' || ch == '\\' || ch == '/'
                || ch == '[' || ch == ']' || ch == '?' || ch == '{' || ch == '}')
                croak("%s: `cookie` must be a cookie name, not '%" SVf "'",
                      PCHAL_WHO, SVfARG(keep));
        }
        if (!cl)
            croak("%s: `cookie` must not be empty", PCHAL_WHO);
    }

    {   /* exempt: path prefixes never challenged */
        AV *keep = newAV();
        (void)hv_stores(out, "exempt", newRV_noinc((SV *)keep));
        v = in ? pchal_hget(aTHX_ in, "exempt") : NULL;
        if (v) {
            AV *list;
            SSize_t i, n;
            if (!pchal_is_array(v))
                croak("%s: `exempt` must be a list of path prefixes", PCHAL_WHO);
            list = (AV *)SvRV(v);
            n = av_len(list) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(list, i, 0);
                STRLEN l = 0;
                const char *p;
                if (!(e && *e && SvOK(*e)) || SvROK(*e))
                    croak("%s: every `exempt` entry must be a path", PCHAL_WHO);
                p = SvPV_const(*e, l);
                if (!pchal_path_ok(p, l))
                    croak("%s: `exempt` entry '%" SVf "' is not a rooted path",
                          PCHAL_WHO, SVfARG(*e));
                av_push(keep, newSVsv(*e));
            }
        }
    }

    {   /* render: a coderef, or the name of a context method */
        v = in ? pchal_hget(aTHX_ in, "render") : NULL;
        if (!v) {
            (void)hv_stores(out, "render", newSV(0));
        }
        else if (pchal_is_code(v)) {
            (void)hv_stores(out, "render", newSVsv(v));
        }
        else if (!SvROK(v)) {
            STRLEN l = 0;
            (void)SvPV_const(v, l);
            if (!l)
                croak("%s: `render` must be a coderef or a method name",
                      PCHAL_WHO);
            (void)hv_stores(out, "render", newSVsv(v));
        }
        else {
            croak("%s: `render` must be a coderef or a method name", PCHAL_WHO);
        }
    }

    {   /* assets: serve challenge.js */
        v = in ? pchal_hget(aTHX_ in, "assets") : NULL;
        (void)hv_stores(out, "assets", newSViv(v ? (SvTRUE(v) ? 1 : 0) : 1));
    }

    return (HV *)SvREFCNT_inc_simple_NN(SvRV(rv));
}

#endif /* PCHAL_BOOT_H */

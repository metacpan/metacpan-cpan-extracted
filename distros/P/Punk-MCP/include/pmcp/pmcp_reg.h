/* pmcp_reg.h - reading the plugin's options, and the calls into Punk's
 * registrar that install a keyword, a to_app callback and a middleware.
 *
 * Needs: pmcp_clos.h.
 * Gives: pmcp_opts (validate `plugin 'MCP' => {...}`), pmcp_keyword,
 * pmcp_at_compile, pmcp_middleware, pmcp_can, pmcp_hget.
 *
 * Every registration is a method call. Punk installs pk_abi.h, an observer
 * table with no install_kw, route or on_compile, so a plugin reaches the
 * registrar through its Perl surface as Punk-Feed does.
 */

#ifndef PMCP_REG_H
#define PMCP_REG_H

#define PMCP_WHO "Punk::Plugin::MCP"

/* A declaration record, as the `mcp` keyword stores it (pmcp_state.h). */
enum { PMCP_D_KIND = 0, PMCP_D_KEY = 1, PMCP_D_SPEC = 2, PMCP_D_TARGET = 3 };

/* ---- small readers -------------------------------------------------------- */

/* One key of a hash, borrowed, or NULL when absent or undef. */
static SV *pmcp_hget(pTHX_ HV *h, const char *k)
{
    SV **e = h ? hv_fetch(h, k, (I32)strlen(k), 0) : NULL;
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

/* Does this class or object have that method? */
static int pmcp_can(pTHX_ SV *obj, const char *meth)
{
    SV *m = sv_2mortal(newSVpv(meth, 0));
    SV *r = pmcp_call_method(aTHX_ obj, "can", &m, 1, G_SCALAR, NULL);
    int yes = r && SvTRUE(r);
    if (r) SvREFCNT_dec(r);
    return yes;
}

/* A non-empty string that is not a reference. */
static int pmcp_is_text(SV *sv)
{
    return sv && SvOK(sv) && !SvROK(sv) && SvCUR(sv) > 0;
}

/* A code ref, or a 'Controller#method' target. Either is what a route takes. */
static int pmcp_is_target(pTHX_ SV *sv)
{
    PERL_UNUSED_CONTEXT;
    return pmcp_is_code(sv) || pmcp_is_text(sv);
}

/* ---- the options ----------------------------------------------------------- */

static const char *const PMCP_OPTS[] = {
    "path", "name", "title", "version", "description", "website", "icons",
    "instructions", "auth", "oauth", "principal", "openapi", "ops",
    "session", "session_ttl", "max_sessions", "stream", "origins",
    "page_size", "max_body", "logging", "timeout", "stdio_trust", NULL
};

static SV *pmcp_name_list(pTHX_ const char *const *names)
{
    SV *out = sv_2mortal(newSVpvs(""));
    int i;
    for (i = 0; names[i]; i++) {
        if (i) sv_catpvs(out, ", ");
        sv_catpv(out, names[i]);
    }
    return out;
}

/* Every key of `h` must be in `known`. A misspelled option is a setting that
 * silently did not apply, so it croaks naming the key and what was meant. */
static void pmcp_check_keys(pTHX_ const char *noun, HV *h,
                            const char *const *known)
{
    HE *he;
    if (!h) return;
    hv_iterinit(h);
    while ((he = hv_iternext(h))) {
        STRLEN kl;
        const char *k = HePV(he, kl);
        int i, ok = 0;
        for (i = 0; known[i]; i++)
            if (strlen(known[i]) == kl && memEQ(known[i], k, kl)) { ok = 1; break; }
        if (!ok)
            croak("%s: unknown %s '%.*s' (known: %s)", PMCP_WHO, noun,
                  (int)kl, k, SvPV_nolen(pmcp_name_list(aTHX_ known)));
    }
}

static void pmcp_opt_croak(pTHX_ const char *opt, const char *want)
{
    croak("%s: option '%s' must be %s", PMCP_WHO, opt, want);
}

/* A positive whole number, or the default when absent. */
static IV pmcp_opt_count(pTHX_ HV *in, const char *k, IV dflt, IV max)
{
    SV *v = pmcp_hget(aTHX_ in, k);
    IV n;
    if (!v) return dflt;
    if (SvROK(v) || !looks_like_number(v) || SvNV(v) != (NV)SvIV(v)
        || (n = SvIV(v)) < 1 || (max && n > max)) {
        if (max) croak("%s: option '%s' must be a whole number from 1 to %"
                       IVdf, PMCP_WHO, k, max);
        pmcp_opt_croak(aTHX_ k, "a positive whole number");
    }
    return n;
}

/* An origin: scheme://host[:port], no path. */
static int pmcp_is_origin(const char *p, STRLEN l)
{
    const char *h, *e = p + l;
    if (l > 8 && memEQ(p, "https://", 8)) h = p + 8;
    else if (l > 7 && memEQ(p, "http://", 7)) h = p + 7;
    else return 0;
    if (h >= e) return 0;
    for (; h < e; h++)
        if (*h == '/' || *h == '?' || *h == '#' || *h == ' ') return 0;
    return 1;
}

/* An icon list: [{src, mimeType?, sizes?}, ...], src https or data:. */
static void pmcp_check_icons(pTHX_ SV *v)
{
    AV *av;
    SSize_t i, n;
    static const char *const keys[] = { "src", "mimeType", "sizes", "theme", NULL };
    if (!pmcp_is_array(v))
        pmcp_opt_croak(aTHX_ "icons", "a list of {src, mimeType, sizes}");
    av = (AV *)SvRV(v);
    n = av_len(av) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        SV *src;
        STRLEN l;
        const char *p;
        if (!(e && pmcp_is_hash(*e)))
            pmcp_opt_croak(aTHX_ "icons", "a list of {src, mimeType, sizes}");
        pmcp_check_keys(aTHX_ "icon key", (HV *)SvRV(*e), keys);
        src = pmcp_hget(aTHX_ (HV *)SvRV(*e), "src");
        if (!pmcp_is_text(src))
            pmcp_opt_croak(aTHX_ "icons", "a list of icons that each have a src");
        p = SvPV_const(src, l);
        if (!((l > 8 && memEQ(p, "https://", 8)) || (l > 5 && memEQ(p, "data:", 5))))
            croak("%s: an icon src must be an https or data: URI, not '%.*s'",
                  PMCP_WHO, (int)l, p);
    }
}

/* A guard: a code ref or a 'Controller#method' string, or a list of them. */
static void pmcp_check_guards(pTHX_ const char *opt, SV *v)
{
    if (pmcp_is_target(aTHX_ v)) return;
    if (pmcp_is_array(v)) {
        AV *av = (AV *)SvRV(v);
        SSize_t i, n = av_len(av) + 1;
        if (n > 0) {
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                if (!(e && pmcp_is_target(aTHX_ *e))) break;
            }
            if (i == n) return;
        }
    }
    pmcp_opt_croak(aTHX_ opt, "a guard (a code ref or 'Controller#method') "
                              "or a list of them");
}

/* Validate `plugin 'MCP' => {...}` and fill in the defaults. Returns a new HV
 * (+1). `class` is the application class, for the name and version defaults. */
static HV *pmcp_opts(pTHX_ SV *class, SV *optsv)
{
    HV *in, *out = newHV();
    SV *v;

    if (SvOK(optsv) && !pmcp_is_hash(optsv)) {
        SvREFCNT_dec((SV *)out);
        croak("%s: the options must be a hash", PMCP_WHO);
    }
    in = SvOK(optsv) ? (HV *)SvRV(optsv) : NULL;
    sv_2mortal((SV *)out);                 /* until it is safely built */
    pmcp_check_keys(aTHX_ "option", in, PMCP_OPTS);

    /* path: rooted, concrete, no trailing slash */
    v = pmcp_hget(aTHX_ in, "path");
    if (v) {
        STRLEN l;
        const char *p;
        if (!pmcp_is_text(v)) pmcp_opt_croak(aTHX_ "path", "a path such as /mcp");
        p = SvPV_const(v, l);
        if (p[0] != '/' || (l > 1 && p[l - 1] == '/') || memchr(p, ':', l)
            || memchr(p, '*', l) || memchr(p, '?', l) || memchr(p, '#', l))
            croak("%s: option 'path' must be a rooted, concrete path with no "
                  "trailing slash, not '%.*s'", PMCP_WHO, (int)l, p);
        (void)hv_stores(out, "path", newSVsv(v));
    }
    else (void)hv_stores(out, "path", newSVpvs("/mcp"));

    /* name and version default to the application's own */
    v = pmcp_hget(aTHX_ in, "name");
    if (v && !pmcp_is_text(v)) pmcp_opt_croak(aTHX_ "name", "a non-empty string");
    (void)hv_stores(out, "name", newSVsv(v ? v : class));

    v = pmcp_hget(aTHX_ in, "version");
    if (v && (SvROK(v) || !SvCUR(v)))
        pmcp_opt_croak(aTHX_ "version", "a non-empty string");
    if (!v) {
        SV *av = pmcp_call_method(aTHX_ class, "VERSION", NULL, 0, G_SCALAR, NULL);
        if (av && SvOK(av)) (void)hv_stores(out, "version", av);
        else {
            if (av) SvREFCNT_dec(av);
            (void)hv_stores(out, "version", newSVpvs("0"));
        }
    }
    else (void)hv_stores(out, "version", newSVsv(v));

    {   /* plain strings */
        static const char *const text[] = { "title", "description", "instructions",
                                            NULL };
        int i;
        for (i = 0; text[i]; i++) {
            v = pmcp_hget(aTHX_ in, text[i]);
            if (!v) continue;
            if (!pmcp_is_text(v)) pmcp_opt_croak(aTHX_ text[i], "a non-empty string");
            (void)hv_store(out, text[i], (I32)strlen(text[i]), newSVsv(v), 0);
        }
    }

    v = pmcp_hget(aTHX_ in, "website");
    if (v) {
        STRLEN l;
        const char *p = pmcp_is_text(v) ? SvPV_const(v, l) : NULL;
        if (!p || !((l > 8 && memEQ(p, "https://", 8))
                    || (l > 7 && memEQ(p, "http://", 7))))
            pmcp_opt_croak(aTHX_ "website", "an http or https URL");
        (void)hv_stores(out, "website", newSVsv(v));
    }

    if ((v = pmcp_hget(aTHX_ in, "icons"))) {
        pmcp_check_icons(aTHX_ v);
        (void)hv_stores(out, "icons", newSVsv(v));
    }

    if ((v = pmcp_hget(aTHX_ in, "auth"))) {
        pmcp_check_guards(aTHX_ "auth", v);
        (void)hv_stores(out, "auth", newSVsv(v));
    }

    /* the shape only, the keys are 11's */
    if ((v = pmcp_hget(aTHX_ in, "oauth"))) {
        if (!pmcp_is_hash(v)) pmcp_opt_croak(aTHX_ "oauth", "a hash");
        (void)hv_stores(out, "oauth", newSVsv(v));
    }

    if ((v = pmcp_hget(aTHX_ in, "principal"))) {
        if (!pmcp_is_target(aTHX_ v))
            pmcp_opt_croak(aTHX_ "principal",
                           "a code ref or a 'Controller#method' target");
        (void)hv_stores(out, "principal", newSVsv(v));
    }

    /* openapi: an api mount, '*', a spec or a prefix, or a list of them;
     * ops needs it. Strings are matched to mounts at to_app (12). */
    if ((v = pmcp_hget(aTHX_ in, "openapi"))) {
        AV *names = newAV();
        if (pmcp_is_text(v) || (SvROK(v) && sv_derived_from(v, "Punk::Mount::OpenAPI")))
            av_push(names, newSVsv(v));
        else if (pmcp_is_array(v) && av_len((AV *)SvRV(v)) >= 0) {
            AV *src = (AV *)SvRV(v);
            SSize_t i, n = av_len(src) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(src, i, 0);
                if (!(e && (pmcp_is_text(*e)
                            || (SvROK(*e) && sv_derived_from(*e, "Punk::Mount::OpenAPI"))))) {
                    SvREFCNT_dec((SV *)names);
                    pmcp_opt_croak(aTHX_ "openapi", "an api mount, '*', a spec or a prefix, or a list of them");
                }
                av_push(names, newSVsv(*e));
            }
        }
        else {
            SvREFCNT_dec((SV *)names);
            pmcp_opt_croak(aTHX_ "openapi", "an api mount, '*', a spec or a prefix, or a list of them");
        }
        (void)hv_stores(out, "openapi", newRV_noinc((SV *)names));
    }
    if ((v = pmcp_hget(aTHX_ in, "ops"))) {
        AV *src;
        SSize_t i, n;
        if (!pmcp_hget(aTHX_ out, "openapi"))
            croak("%s: option 'ops' needs 'openapi', the mount the operations "
                  "come from", PMCP_WHO);
        if (!pmcp_is_array(v)) pmcp_opt_croak(aTHX_ "ops", "a list of operationIds");
        src = (AV *)SvRV(v);
        n = av_len(src) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(src, i, 0);
            if (!(e && pmcp_is_text(*e)))
                pmcp_opt_croak(aTHX_ "ops", "a list of operationIds");
        }
        (void)hv_stores(out, "ops", newSVsv(v));
    }

    /* session: 0 for stateless, or the name of a Punk::Cache store */
    v = pmcp_hget(aTHX_ in, "session");
    if (v && !SvROK(v) && looks_like_number(v) && SvIV(v) == 0 && SvNV(v) == 0)
        (void)hv_stores(out, "session", newSViv(0));
    else if (v && !pmcp_is_text(v))
        pmcp_opt_croak(aTHX_ "session", "0, or the name of a Punk::Cache store");
    else (void)hv_stores(out, "session", v ? newSVsv(v) : newSViv(0));

    (void)hv_stores(out, "session_ttl",
                    newSViv(pmcp_opt_count(aTHX_ in, "session_ttl", 3600, 0)));
    (void)hv_stores(out, "max_sessions",
                    newSViv(pmcp_opt_count(aTHX_ in, "max_sessions", 10000, 0)));
    (void)hv_stores(out, "page_size",
                    newSViv(pmcp_opt_count(aTHX_ in, "page_size", 50, 1000)));
    (void)hv_stores(out, "max_body",
                    newSViv(pmcp_opt_count(aTHX_ in, "max_body", 1048576, 0)));

    v = pmcp_hget(aTHX_ in, "stream");
    if (v) {
        STRLEN l;
        const char *p = pmcp_is_text(v) ? SvPV_const(v, l) : NULL;
        if (!p || !((l == 4 && memEQ(p, "auto", 4)) || (l == 4 && memEQ(p, "json", 4))
                    || (l == 6 && memEQ(p, "always", 6))))
            pmcp_opt_croak(aTHX_ "stream", "'auto', 'json' or 'always'");
    }
    (void)hv_stores(out, "stream", v ? newSVsv(v) : newSVpvs("auto"));

    if ((v = pmcp_hget(aTHX_ in, "origins"))) {
        AV *src;
        SSize_t i, n;
        if (!pmcp_is_array(v))
            pmcp_opt_croak(aTHX_ "origins", "a list of origins such as https://acme.test");
        src = (AV *)SvRV(v);
        n = av_len(src) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(src, i, 0);
            STRLEN l;
            const char *p = (e && pmcp_is_text(*e)) ? SvPV_const(*e, l) : NULL;
            if (!p || !pmcp_is_origin(p, l))
                croak("%s: option 'origins' holds '%s', which is not an origin "
                      "such as https://acme.test", PMCP_WHO,
                      p ? p : "a value that is not a string");
        }
        (void)hv_stores(out, "origins", newSVsv(v));
    }

    (void)hv_stores(out, "logging",
                    newSViv((v = pmcp_hget(aTHX_ in, "logging")) && SvTRUE(v)));
    (void)hv_stores(out, "stdio_trust",
                    newSViv((v = pmcp_hget(aTHX_ in, "stdio_trust")) && SvTRUE(v)));

    /* timeout: seconds, fractional allowed, for a call that returns a Future */
    if ((v = pmcp_hget(aTHX_ in, "timeout"))) {
        if (SvROK(v) || !looks_like_number(v) || !(SvNV(v) > 0))
            pmcp_opt_croak(aTHX_ "timeout", "a number of seconds above 0");
        (void)hv_stores(out, "timeout", newSVnv(SvNV(v)));
    }

    return (HV *)SvREFCNT_inc_simple_NN((SV *)out);
}

/* ---- installing ------------------------------------------------------------ */

/* A keyword on the application class. Idempotent per owner, so import and
 * register may both ask and only the first does anything. */
static void pmcp_keyword(pTHX_ SV *app, const char *name, XSUBADDR_t body,
                         AV *cap)
{
    SV *argv[3];
    SV *r;
    argv[0] = sv_2mortal(newSVpv(name, 0));
    argv[1] = sv_2mortal(pmcp_closure(aTHX_ body, cap));
    argv[2] = sv_2mortal(newSVpvs(PMCP_WHO));
    r = pmcp_call_method(aTHX_ app, "install_kw", argv, 3, G_SCALAR, NULL);
    SvREFCNT_dec(r);
}

/* A to_app callback: after every keyword has recorded, before compiling. */
static void pmcp_at_compile(pTHX_ SV *app, XSUBADDR_t body, AV *cap)
{
    SV *argv[2];
    SV *r;
    argv[0] = sv_2mortal(pmcp_closure(aTHX_ body, cap));
    argv[1] = sv_2mortal(newSVpvs(PMCP_WHO));
    r = pmcp_call_method(aTHX_ app, "on_compile", argv, 2, G_SCALAR, NULL);
    SvREFCNT_dec(r);
}

/* A context helper, $c->NAME. Idempotent per name in Punk. */
static void pmcp_helper(pTHX_ SV *app, const char *name, XSUBADDR_t body)
{
    SV *argv[2];
    SV *r;
    argv[0] = sv_2mortal(newSVpv(name, 0));
    argv[1] = sv_2mortal(pmcp_closure(aTHX_ body, newAV()));
    r = pmcp_call_method(aTHX_ app, "helper", argv, 2, G_SCALAR, NULL);
    SvREFCNT_dec(r);
}

/* A middleware. Its body runs once at to_app with the inner app, after the
 * router has compiled, so it can read the route records. A croak from it is a
 * to_app croak. */
static void pmcp_middleware(pTHX_ SV *app, XSUBADDR_t body, AV *cap)
{
    SV *argv[1];
    SV *r;
    argv[0] = sv_2mortal(pmcp_closure(aTHX_ body, cap));
    r = pmcp_call_method(aTHX_ app, "middleware", argv, 1, G_SCALAR, NULL);
    SvREFCNT_dec(r);
}

#endif /* PMCP_REG_H */

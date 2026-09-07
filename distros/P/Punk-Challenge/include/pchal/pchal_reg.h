#ifndef PCHAL_REG_H
#define PCHAL_REG_H

/* The boot-time devices `register` needs in C: reading options without
 * letting a typo through, and installing a keyword and a helper through the
 * registrar's ordinary Perl surface.
 *
 * There is no other way in. Punk installs pk_abi.h and nothing else, and
 * pk_abi.h is an observer table with no install_kw, no route and no app_hv,
 * so every registration here is a method dispatch. Punk::Plugin::Feed
 * registers from outside the distribution the same way.
 *
 * Must be included after pchal_clos.h.
 */

#define PCHAL_WHO "Punk::Plugin::Challenge"

/* ---- reading options ------------------------------------------------------ */

/* A comma-joined list of names, for a diagnostic that says what the caller
 * could have meant. Mortal. */
static SV *pchal_name_list(pTHX_ const char *const *names)
{
    SV *out = sv_2mortal(newSVpvs(""));
    int i;
    for (i = 0; names[i]; i++) {
        if (i) sv_catpvs(out, ", ");
        sv_catpv(out, names[i]);
    }
    return out;
}

/* Every key of `opts` must be in `known`, or the option was misspelled - and
 * a misspelled option is a setting that silently did not apply. `bitz => 20`
 * would leave the whole site at the default difficulty while the operator
 * believed it hardened. */
static void pchal_check_opts(pTHX_ const char *noun, HV *opts,
                             const char *const *known)
{
    HE *he;
    if (!opts) return;
    hv_iterinit(opts);
    while ((he = hv_iternext(opts))) {
        STRLEN kl;
        const char *k = HePV(he, kl);
        int i, ok = 0;
        for (i = 0; known[i]; i++)
            if (strlen(known[i]) == kl && memEQ(known[i], k, kl)) { ok = 1; break; }
        if (!ok)
            croak("%s: unknown %s '%.*s' (known: %s)", PCHAL_WHO, noun,
                  (int)kl, k, SvPV_nolen(pchal_name_list(aTHX_ known)));
    }
}

/* The arguments of a keyword or a helper as a hash: key => value pairs, or
 * one hash reference, which is what auth_guard accepts. Mortal. An odd
 * number of arguments is a croak naming the caller, because `bits => 18`
 * with a comma lost is `bits` and nothing, and the nothing would otherwise
 * become the value of an option that does not exist. */
static HV *pchal_args(pTHX_ const char *what, SV **st, I32 n)
{
    HV *out = newHV();
    I32 i;
    (void)sv_2mortal(newRV_noinc((SV *)out));

    if (n == 1) {
        HE *he;
        HV *given;
        if (!pchal_is_hash(st[0]))
            croak("%s: %s takes key => value pairs or a hash reference",
                  PCHAL_WHO, what);
        given = (HV *)SvRV(st[0]);
        hv_iterinit(given);
        while ((he = hv_iternext(given))) {
            STRLEN kl;
            const char *k = HePV(he, kl);
            (void)hv_store(out, k, (I32)kl, newSVsv(HeVAL(he)), 0);
        }
        return out;
    }
    if (n % 2)
        croak("%s: %s has an odd number of arguments", PCHAL_WHO, what);
    for (i = 0; i + 1 < n; i += 2) {
        STRLEN kl;
        const char *k;
        if (!SvOK(st[i]) || SvROK(st[i]))
            croak("%s: %s option names must be strings", PCHAL_WHO, what);
        k = SvPV_const(st[i], kl);
        (void)hv_store(out, k, (I32)kl, newSVsv(st[i + 1]), 0);
    }
    return out;
}

/* ---- installing ----------------------------------------------------------- */

/* A keyword, owned by this plugin so a second install from the same owner is
 * the no-op Punk makes it - which is what lets `import` and `register` both
 * ask and only the first do anything. Takes ownership of cap. */
static void pchal_keyword(pTHX_ SV *app, const char *name, XSUBADDR_t body,
                          AV *cap)
{
    SV *argv[3];
    argv[0] = sv_2mortal(newSVpv(name, 0));
    argv[1] = sv_2mortal(pchal_closure(aTHX_ body, cap));
    argv[2] = sv_2mortal(newSVpvs(PCHAL_WHO));
    SvREFCNT_dec(pchal_call(aTHX_ app, "install_kw", argv, 3));
}

/* A request hook: before_dispatch here. Takes ownership of cap. */
static void pchal_hook(pTHX_ SV *app, const char *name, XSUBADDR_t body,
                       AV *cap)
{
    SV *argv[2];
    argv[0] = sv_2mortal(newSVpv(name, 0));
    argv[1] = sv_2mortal(pchal_closure(aTHX_ body, cap));
    SvREFCNT_dec(pchal_call(aTHX_ app, "hook", argv, 2));
}

/* The to_app seam. on_compile runs once, in registration order, after every
 * keyword has recorded and before anything is compiled - the only moment at
 * which the whole rule set is certainly known. Takes ownership of cap. */
static void pchal_at_compile(pTHX_ SV *app, XSUBADDR_t body, AV *cap)
{
    SV *argv[2];
    if (!pchal_can(aTHX_ app, "on_compile")) {
        SvREFCNT_dec((SV *)cap);
        croak("%s needs Punk 0.30 or newer for on_compile", PCHAL_WHO);
    }
    argv[0] = sv_2mortal(pchal_closure(aTHX_ body, cap));
    argv[1] = sv_2mortal(newSVpvs(PCHAL_WHO));
    SvREFCNT_dec(pchal_call(aTHX_ app, "on_compile", argv, 2));
}

/* A context helper. Unlike a keyword there is no same-owner no-op: a second
 * install of the same name croaks naming both owners, so this is asked
 * exactly once, from `register`. Takes ownership of cap. */
static void pchal_helper(pTHX_ SV *app, const char *name, XSUBADDR_t body,
                         AV *cap)
{
    SV *argv[3];
    argv[0] = sv_2mortal(newSVpv(name, 0));
    argv[1] = sv_2mortal(pchal_closure(aTHX_ body, cap));
    argv[2] = sv_2mortal(newSVpvs(PCHAL_WHO));
    SvREFCNT_dec(pchal_call(aTHX_ app, "helper", argv, 3));
}

#endif /* PCHAL_REG_H */

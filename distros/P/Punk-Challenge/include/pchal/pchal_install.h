#ifndef PCHAL_INSTALL_H
#define PCHAL_INSTALL_H

/* What `import` and `register` install, and which of them installs it.
 *
 * The keywords go in from both. `import` runs at compile time of the
 * application's package body, which is the only moment that makes the
 * bareword forms parse - `challenge for => ...;` and a bare `challenge_guard`
 * in an `under` - and `register` runs at runtime of that body, long after
 * those statements were compiled. Punk makes a second install by the same
 * owner a no-op, so both may ask.
 *
 * The helpers, the hook, the compile callback and the page go in from
 * `register` alone: `helper` croaks on any second install, a hook installed
 * twice would run twice, and all of them need the options `register`
 * records anyway.
 *
 * Must be included after pchal_rules.h, pchal_guard.h and pchal_helpers.h.
 */

static void pchal_install_kws(pTHX_ SV *app)
{
    AV *cap;

    cap = newAV();
    av_push(cap, newSVsv(app));
    pchal_keyword(aTHX_ app, "challenge", pchal_kw_challenge_cb, cap);

    cap = newAV();
    av_push(cap, newSVsv(app));
    pchal_keyword(aTHX_ app, "challenge_guard", pchal_kw_guard_cb, cap);
}

static void pchal_install_helpers(pTHX_ SV *app)
{
    static const struct { const char *name; XSUBADDR_t body; } table[] = {
        { "challenge_cleared", pchal_h_cleared_cb },
        { "challenge_issue",   pchal_h_issue_cb   },
        { "challenge_clear",   pchal_h_clear_cb   },
    };
    size_t i;
    for (i = 0; i < sizeof table / sizeof table[0]; i++) {
        AV *cap = newAV();
        av_push(cap, newSVsv(app));
        pchal_helper(aTHX_ app, table[i].name, table[i].body, cap);
    }
}

/* The rule hook and the boot check. */
static void pchal_install_hook(pTHX_ SV *app)
{
    AV *cap;

    cap = newAV();
    av_push(cap, newSVsv(app));
    pchal_hook(aTHX_ app, "before_dispatch", pchal_hook_cb, cap);

    cap = newAV();
    av_push(cap, newSVsv(app));
    pchal_at_compile(aTHX_ app, pchal_compile_cb, cap);
}

/* The interstitial, read now so a missing page is a croak at the plugin
 * line and not a 500 on every challenge. Not read when `render` replaces
 * it. The routes read the solver the same way. */
static void pchal_install_page(pTHX_ SV *app, HV *opts)
{
    HV *h = pchal_app_hv(aTHX_ app);
    if (!h || pchal_hget(aTHX_ opts, "render")) return;
    (void)hv_stores(h, "challenge_page", pchal_page_load(aTHX));
}

#endif /* PCHAL_INSTALL_H */

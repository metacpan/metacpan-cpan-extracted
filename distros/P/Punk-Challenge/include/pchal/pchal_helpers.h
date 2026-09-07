#ifndef PCHAL_HELPERS_H
#define PCHAL_HELPERS_H

/* The context helpers, for a handler that wants the gate in its own hands.
 *
 *     $c->challenge_cleared(%opts)   true with a valid clearance at or above bits
 *     $c->challenge_issue(%opts)     a fresh puzzle for this request's subject
 *     $c->challenge_clear(%opts)     set the clearance cookie; returns its value
 *
 * Each takes `bits => N` to override the plugin's default. The options are
 * validated before the gate is reached, so `bitz => 18` is a croak naming
 * the option and not a helper that quietly used the default.
 *
 * Installed from `register` only: `helper` has no same-owner no-op, and a
 * second install from `import` would croak naming this plugin twice.
 *
 * Must be included after pchal_gate.h.
 */

static const char *const PCHAL_HELPER_OPTS[] = { "bits", NULL };

/* The difficulty a helper was asked for: `bits => N` from its arguments
 * (ST(1) onward), else the plugin's default. */
static IV pchal_helper_bits(pTHX_ const char *name, SV **st, I32 n, HV *opts)
{
    HV *in = NULL;
    SV *b = NULL;
    if (n > 0) {
        in = pchal_args(aTHX_ name, st, n);
        pchal_check_opts(aTHX_ "option", in, PCHAL_HELPER_OPTS);
        b = pchal_opt_str(aTHX_ in, "bits");
    }
    if (b) return pchal_opt_iv(aTHX_ in, "bits", 0, 1, PCHAL_MAX_BITS);
    return pchal_bits_for(aTHX_ opts, NULL);
}

XS_INTERNAL(pchal_h_cleared_cb);
XS_INTERNAL(pchal_h_cleared_cb)
{
    dXSARGS;
    SV *app = pchal_cap_slot(aTHX_ cv, 0);
    HV *opts;
    IV bits;
    if (items < 1) croak("%s: challenge_cleared needs the context", PCHAL_WHO);
    opts = pchal_opts_of(aTHX_ app);
    bits = pchal_helper_bits(aTHX_ "challenge_cleared", &ST(1), items - 1, opts);
    ST(0) = boolSV(pchal_cleared(aTHX_ ST(0), opts, bits));
    XSRETURN(1);
}

XS_INTERNAL(pchal_h_issue_cb);
XS_INTERNAL(pchal_h_issue_cb)
{
    dXSARGS;
    SV *app = pchal_cap_slot(aTHX_ cv, 0);
    HV *opts;
    IV bits;
    if (items < 1) croak("%s: challenge_issue needs the context", PCHAL_WHO);
    opts = pchal_opts_of(aTHX_ app);
    bits = pchal_helper_bits(aTHX_ "challenge_issue", &ST(1), items - 1, opts);
    ST(0) = sv_2mortal(pchal_issue(aTHX_ ST(0), opts, bits));
    XSRETURN(1);
}

XS_INTERNAL(pchal_h_clear_cb);
XS_INTERNAL(pchal_h_clear_cb)
{
    dXSARGS;
    SV *app = pchal_cap_slot(aTHX_ cv, 0);
    HV *opts;
    IV bits;
    if (items < 1) croak("%s: challenge_clear needs the context", PCHAL_WHO);
    opts = pchal_opts_of(aTHX_ app);
    bits = pchal_helper_bits(aTHX_ "challenge_clear", &ST(1), items - 1, opts);
    ST(0) = sv_2mortal(pchal_clear(aTHX_ ST(0), opts, bits));
    XSRETURN(1);
}

#endif /* PCHAL_HELPERS_H */

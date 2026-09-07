#ifndef PCHAL_GUARD_H
#define PCHAL_GUARD_H

/* `challenge_guard`: a guard for `under`, in the auth_guard shape.
 *
 *     under '/register' => challenge_guard;
 *     under('/account' => auth_guard)->under('' => challenge_guard(bits => 18));
 *
 * (`under` takes one guard; the second is a nested scope with an empty
 * prefix, whose guards run outer to inner.)
 *
 * This exists because of the phase Punk does not have. before_dispatch runs
 * ahead of a route's guards, so a rule installed by the keyword answers
 * before auth_guard has looked at the request - and a guard is the only
 * public way to run after it. Where the order matters, write the guard;
 * where it does not, write the rule.
 *
 * The factory captures [app, bits-or-undef]; the body resolves the plugin's
 * options at the request, so a guard declared above the `plugin` line still
 * sees its configuration.
 *
 * Must be included after pchal_gate.h.
 */

static const char *const PCHAL_GUARD_OPTS[] = { "bits", NULL };

/* The guard body: a reference return short-circuits with the challenge,
 * nothing continues. */
XS_INTERNAL(pchal_guard_cb);
XS_INTERNAL(pchal_guard_cb)
{
    dXSARGS;
    SV *app = pchal_cap_slot(aTHX_ cv, 0);
    SV *bits_sv = pchal_cap_slot(aTHX_ cv, 1);
    SV *c = items > 0 ? ST(0) : NULL;
    HV *opts;
    IV bits;
    SV *r;

    if (!c) XSRETURN_EMPTY;
    opts = pchal_opts_of(aTHX_ app);
    bits = pchal_bits_for(aTHX_ opts, bits_sv);
    if (pchal_cleared(aTHX_ c, opts, bits)) XSRETURN_EMPTY;
    r = pchal_demand(aTHX_ c, opts, bits);
    ST(0) = sv_2mortal(r);
    XSRETURN(1);
}

/* The factory: the keyword. Validates at the declaration, because a guard
 * asking for 99 bits is a site nobody can enter, and the first request is
 * the wrong time to learn that. */
XS_INTERNAL(pchal_kw_guard_cb);
XS_INTERNAL(pchal_kw_guard_cb)
{
    dXSARGS;
    SV *app = pchal_cap_slot(aTHX_ cv, 0);
    HV *in = NULL;
    SV *b = NULL;
    AV *cap;

    if (items) {
        in = pchal_args(aTHX_ "challenge_guard", &ST(0), items);
        pchal_check_opts(aTHX_ "challenge_guard option", in, PCHAL_GUARD_OPTS);
        b = pchal_opt_str(aTHX_ in, "bits");
    }

    cap = newAV();
    av_push(cap, app ? newSVsv(app) : newSV(0));
    av_push(cap, b ? newSViv(pchal_opt_iv(aTHX_ in, "bits", 0, 1, PCHAL_MAX_BITS))
                   : newSV(0));
    ST(0) = sv_2mortal(pchal_closure(aTHX_ pchal_guard_cb, cap));
    XSRETURN(1);
}

#endif /* PCHAL_GUARD_H */

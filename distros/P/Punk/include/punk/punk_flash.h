/* punk_flash.h - one-request flash messages over the signed-cookie session.
 *
 * One reserved key inside the session hashref, `punk.flash`, holds the
 * outbound flash - what the NEXT request will read. On the first flash call
 * of a request the inbound hash is deleted out of the session into the
 * stash (`punk.flash.in`): the delete dirties the session, so the response
 * of the request that consumed it rewrites the cookie without it - the
 * one-request lifetime falls out of the ordinary change-detected write-back,
 * and a request that never touches flash leaves it riding. Everything else
 * is the session's existing machinery: the signing, the 4KB cap, and the
 * croak when no `session` keyword is configured.
 *
 * Needs punk_session.h (ps_load, ps_stash).
 */

#ifndef PUNK_FLASH_H
#define PUNK_FLASH_H

/* this request's inbound flash, rotated out of the session on first call;
 * never NULL (borrowed - the stash owns it) */
static HV *pf_inbound(pTHX_ SV *c) {
    AV *av = pcx_av(aTHX_ c);
    HV *stash = ps_stash(aTHX_ av);
    SV **in = hv_fetchs(stash, "punk.flash.in", 0);
    SV *sess_rv, *moved, *rv;
    HV *inh;
    if (in && *in && SvROK(*in) && SvTYPE(SvRV(*in)) == SVt_PVHV)
        return (HV *)SvRV(*in);
    sess_rv = sv_2mortal(ps_load(aTHX_ c));        /* croaks unconfigured */
    moved = hv_delete((HV *)SvRV(sess_rv), "punk.flash", 10, 0);
    if (moved && SvROK(moved) && SvTYPE(SvRV(moved)) == SVt_PVHV) {
        inh = (HV *)SvRV(moved);
        rv = newRV_inc((SV *)inh);     /* moved is mortal; keep the HV */
    }
    else {
        inh = newHV();
        rv = newRV_noinc((SV *)inh);
    }
    (void)hv_stores(stash, "punk.flash.in", rv);   /* the stash owns rv */
    return inh;
}

/* the outbound flash inside the session, created on demand (borrowed) */
static HV *pf_outbound(pTHX_ SV *c) {
    SV *sess_rv = sv_2mortal(ps_load(aTHX_ c));
    HV *sess = (HV *)SvRV(sess_rv);
    SV **e = hv_fetchs(sess, "punk.flash", 0);
    HV *out;
    if (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)
        return (HV *)SvRV(*e);
    out = newHV();
    (void)hv_stores(sess, "punk.flash", newRV_noinc((SV *)out));
    return out;
}

#endif /* PUNK_FLASH_H */

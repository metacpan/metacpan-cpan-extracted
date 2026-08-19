/* pk_abi_impl.h - Punk's side of its public C ABI (pk_abi.h).
 *
 * Included by Punk.xs AFTER punk_context.h (the PCX_* slot layout) and
 * punk_obs.h (the observer registry). Everything here is private to Punk's
 * translation unit; a consumer reaches it only through the PK_ABI table
 * returned by Punk::_abi_ptr.
 */

#ifndef PK_ABI_IMPL_H
#define PK_ABI_IMPL_H

#include "pk_abi.h"

/* A context's AV, or NULL for anything that is not one. The whole table has
 * to be safe to call on a value the consumer only thinks is a context, so
 * this never croaks the way pcx_av does. */
static AV *pk_abi_av(pTHX_ SV *c) {
    PERL_UNUSED_CONTEXT;
    if (!c || !SvROK(c) || SvTYPE(SvRV(c)) != SVt_PVAV) return NULL;
    return (AV *)SvRV(c);
}

/* One slot, borrowed; NULL when absent or undef. */
static SV *pk_abi_slot(pTHX_ SV *c, SSize_t i) {
    AV *av = pk_abi_av(aTHX_ c);
    SV **e = av ? av_fetch(av, i, 0) : NULL;
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

static SV *pk_abi_env_of(pTHX_ SV *c)   { return pk_abi_slot(aTHX_ c, PCX_ENV); }
static SV *pk_abi_app_of(pTHX_ SV *c)   { return pk_abi_slot(aTHX_ c, PCX_APP); }
static SV *pk_abi_match_of(pTHX_ SV *c) { return pk_abi_slot(aTHX_ c, PCX_MATCH); }

/* The stash, created on first ask. A consumer's first act is normally to
 * leave something for the response side to find, and it should not have to
 * know the slot layout to do it. */
static SV *pk_abi_stash_of(pTHX_ SV *c) {
    AV *av = pk_abi_av(aTHX_ c);
    SV *st;
    if (!av) return NULL;
    st = pcx_get(aTHX_ av, PCX_STASH);
    if (!st) {
        st = newRV_noinc((SV *)newHV());
        if (!av_store(av, PCX_STASH, st)) { SvREFCNT_dec(st); return NULL; }
    }
    return st;
}

/* The match hash, or NULL. */
static HV *pk_abi_match_hv(pTHX_ SV *c) {
    SV *m = pk_abi_match_of(aTHX_ c);
    if (!(m && SvROK(m) && SvTYPE(SvRV(m)) == SVt_PVHV)) return NULL;
    return (HV *)SvRV(m);
}

/* The declared route path, through the route record the dispatcher stores in
 * the match. NULL whenever there is no matched route to name, which includes
 * every request-start callback: routing has not happened yet. */
static SV *pk_abi_route_pattern_of(pTHX_ SV *c) {
    HV *mh = pk_abi_match_hv(aTHX_ c);
    SV **r, **p;
    if (!mh) return NULL;
    r = hv_fetchs(mh, "route", 0);
    if (!(r && *r && SvROK(*r) && SvTYPE(SvRV(*r)) == SVt_PVHV)) return NULL;
    p = hv_fetchs((HV *)SvRV(*r), K_PATH, 0);
    return (p && *p && SvOK(*p)) ? *p : NULL;
}

static SV *pk_abi_operation_of(pTHX_ SV *c) {
    HV *mh = pk_abi_match_hv(aTHX_ c);
    SV **o = mh ? hv_fetchs(mh, "operation", 0) : NULL;
    return (o && *o && SvOK(*o)) ? *o : NULL;
}

/* The status out of a PSGI triplet; -1 when there is none to read - a
 * streaming coderef, or anything that is not a triplet. */
static IV pk_abi_status_of(pTHX_ SV *response) {
    AV *ra;
    SV **s;
    if (!response || !SvROK(response) || SvTYPE(SvRV(response)) != SVt_PVAV)
        return -1;
    ra = (AV *)SvRV(response);
    s = av_fetch(ra, 0, 0);
    return (s && *s && SvOK(*s)) ? SvIV(*s) : -1;
}

static const pk_abi PK_ABI = {
    PK_ABI_VERSION,
    pk_abi_env_of,
    pk_abi_app_of,
    pk_abi_match_of,
    pk_abi_stash_of,
    pk_abi_route_pattern_of,
    pk_abi_operation_of,
    pk_abi_status_of,
    pk_obs_add_req,
    pk_obs_add_res,
    pk_obs_add_query,            /* v2 */
    pl_observe,                  /* v3 */
};

#endif /* PK_ABI_IMPL_H */

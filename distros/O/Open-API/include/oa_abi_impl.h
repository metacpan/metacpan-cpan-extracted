#ifndef OA_ABI_IMPL_H
#define OA_ABI_IMPL_H

/* Open::API-side implementation of the shared C ABI (oa_abi.h). Included by
 * API.xs AFTER oa_route.h / oa_validate.h / oa_compile.h, so oa_route,
 * oa_validate_op, oa_op_by_id and the oa_get/oa_hv_of helpers are in scope.
 * Everything here is private to Open::API's translation unit; consumers reach
 * it only through the OA_ABI table returned by Open::API::_abi_ptr. */

#include "oa_abi.h"

/* Like oa_api_of but never croaks - the fall-back path must be able to probe a
 * value safely. Returns NULL for anything that is not a reference. */
static void *oa_abi_api_of(pTHX_ SV *api_sv) {
    if (!api_sv || !SvROK(api_sv)) return NULL;
    return INT2PTR(void *, SvIV(SvRV(api_sv)));
}

static void *oa_abi_route(pTHX_ void *api, const char *method, STRLEN mlen,
                          const char *path, STRLEN plen, HV *caps, AV *allow) {
    oa_api *a = (oa_api *)api;
    AV     *sink = allow ? allow : (AV *)sv_2mortal((SV *)newAV());
    if (!a) return NULL;
    return (void *)oa_route(aTHX_ a, method, mlen, path, plen, caps, sink);
}

static void *oa_abi_op_by_id(pTHX_ void *api, SV *op_id) {
    oa_api *a = (oa_api *)api;
    if (!a || !op_id) return NULL;
    return (void *)oa_op_by_id(aTHX_ a, op_id);
}

static int oa_abi_validate(pTHX_ void *api, void *op, HV *raw,
                           HV *typed, AV *errors) {
    oa_api *a = (oa_api *)api;
    oa_op  *o = (oa_op *)op;
    HV     *rawpath, *headers;
    SV     *query, *body;
    HV     *params = NULL;
    int     ok;
    if (!a || !o || !raw) return 0;
    rawpath = oa_hv_of(oa_get(aTHX_ raw, "path"));
    headers = oa_hv_of(oa_get(aTHX_ raw, "header"));
    query   = oa_get(aTHX_ raw, "query");
    body    = oa_get(aTHX_ raw, "body");
    ok = oa_validate_op(aTHX_ a, o, rawpath, query, headers, body,
                        typed ? &params : NULL, errors);
    if (ok && typed && params) {
        /* move path/query/header/cookie/body into the caller's HV, then drop
         * the shell oa_validate_op allocated */
        HE *he;
        hv_iterinit(params);
        while ((he = hv_iternext(params))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            SV *v = hv_iterval(params, he);
            (void)hv_store(typed, k, kl, SvREFCNT_inc(v), 0);
        }
        SvREFCNT_dec((SV *)params);
    }
    return ok;
}

static SV *oa_abi_op_id(pTHX_ void *op) {
    oa_op *o = (oa_op *)op;
    return o ? o->op_id : NULL;
}

static const oa_abi OA_ABI = {
    OA_ABI_VERSION,
    oa_abi_api_of,
    oa_abi_route,
    oa_abi_op_by_id,
    oa_abi_validate,
    oa_abi_op_id,
};

#endif /* OA_ABI_IMPL_H */

#ifndef OA_TYPES_H
#define OA_TYPES_H

/* The top-level compiled API object. An Open::API is a blessed IV pointing at
 * this struct (the jsf_compiled_t pattern). `spec` keeps the decoded document
 * alive for introspection; `keep` owns every compiled JSF handle (blessed SVs
 * returned +1 by the JSF ABI) so DESTROY frees them all in one sweep. The
 * operation table itself is built in phase 1 (oa_compile.h). */

typedef struct oa_api {
    SV *spec;      /* decoded OpenAPI document hashref (+1)          */
    AV *keep;      /* compiled JSF handle SVs and other keepalives   */
    void *ops;     /* oa_ops table (phase 1); NULL until compiled    */
    SV *defs;      /* components.schemas rewritten for $defs (in keep;
                    * borrowed) - shared across every wrapped schema */
} oa_api;

static oa_api *oa_api_new(pTHX) {
    oa_api *a = (oa_api *)malloc(sizeof *a);
    if (!a) return NULL;
    a->spec = NULL;
    a->keep = newAV();
    a->ops  = NULL;
    a->defs = NULL;
    return a;
}

static void oa_ops_free(pTHX_ void *p);   /* defined in oa_compile.h */

static void oa_api_free(pTHX_ oa_api *a) {
    if (!a) return;
    oa_ops_free(aTHX_ a->ops);            /* C arrays only; SVs live in keep */
    if (a->spec) SvREFCNT_dec(a->spec);
    if (a->keep) SvREFCNT_dec((SV *)a->keep);
    free(a);
}

#endif /* OA_TYPES_H */

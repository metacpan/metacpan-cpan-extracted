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
    /* The same thing PROJECTED for a direction. `readOnly` means a property
     * may come back in a response but should not be sent in a request, and
     * `writeOnly` is the mirror; a `required` readOnly property is required
     * of responses ONLY. None of that can be decided while validating,
     * because JSF owns the traversal once a schema is compiled - so it is
     * expanded into 2020-12 constructs here, per direction, the way
     * `discriminator` is. A $ref from a request body has to reach the
     * request-projected component, hence a whole projected defs block rather
     * than a flag. Both live in `keep`; borrowed, NULL when the document has
     * no readOnly/writeOnly anywhere. */
    SV *defs_req;  /* readOnly properties forbidden, and un-required  */
    SV *defs_resp; /* writeOnly properties forbidden, and un-required */
    /* Does the document use the flag at all? A document that does not pays
     * nothing: no projection is built and every schema compiles down the
     * original path. Separate from the defs above because the flag can sit in
     * an inline body schema of a document with no components.schemas, where
     * there is no defs block to project but the schema itself still needs it. */
    int proj_req;
    int proj_resp;
    /* The path prefix a Server Object's URL carries, already expanded, to be
     * stripped before routing - or NULL, which is the default. OPT-IN:
     * honouring a prefix re-routes every deployment that currently mounts so
     * PATH_INFO already matches, and the failure mode is a silent 404 on live
     * traffic, so it happens only when the caller asks for it. In `keep`;
     * borrowed. */
    SV *prefix;
    /* the caller asked for server URLs to be honoured. Kept separately from
     * `prefix`, which stays NULL when the document declares no root servers -
     * a path item or an operation may still declare its own. */
    int want_servers;
} oa_api;

static oa_api *oa_api_new(pTHX) {
    oa_api *a = (oa_api *)malloc(sizeof *a);
    if (!a) return NULL;
    a->spec = NULL;
    a->keep = newAV();
    a->ops  = NULL;
    a->defs = NULL;
    a->defs_req  = NULL;
    a->defs_resp = NULL;
    a->proj_req  = 0;
    a->proj_resp = 0;
    a->prefix    = NULL;
    a->want_servers = 0;
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

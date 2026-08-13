#ifndef OA_NORMALIZE_H
#define OA_NORMALIZE_H

/* Document normalisation: everything that has to be true of a spec before the
 * schemas reach JSON::Schema::Fast. Runs once, at load, on a copy - the
 * caller's document is never mutated.
 *
 * Two jobs, and both are here rather than in oa_compile_schema for the same
 * reason: oa_mock.h walks `a->spec` directly rather than the compiled JSF
 * handles, so anything done only to compiled schemas would make the mock
 * generator and the validator disagree about the same document.
 *
 *   1. OpenAPI 3.0 -> 3.1 (version-gated, `N->v30`).
 *
 *      A 3.1 Schema Object IS JSON Schema 2020-12, which is what
 *      JSON::Schema::Fast validates, so a 3.1 document reaches the validator
 *      unchanged. A 3.0 Schema Object is a different dialect - an extended
 *      subset of JSON Schema Wright draft-00 - so it is rewritten: nullable,
 *      the boolean exclusive bounds, tuple items, schema-level example, the
 *      binary formats, and $ref siblings.
 *
 *   2. `discriminator` -> if/then (both versions).
 *
 *      Once a schema is compiled, JSF owns the traversal - C cannot step in
 *      partway down to pick a branch. So the discriminator is expanded into
 *      constructs 2020-12 already has, and the validator needs to know
 *      nothing about OpenAPI at all.
 *
 * Two properties this file has to keep:
 *
 *   Position-aware. A spec's `example`, `default` and `enum` values are
 *   arbitrary user JSON that may perfectly legitimately contain a key called
 *   `nullable` or `items`. So the walk descends only through the document
 *   positions where a Schema Object can actually appear, and inside a schema
 *   only through schema-valued keywords. It never rewrites a value.
 *
 *   Idempotent. The normalised document keeps its original `openapi` string -
 *   a document should not lie about what it was - so
 *   Open::API->new(spec => $api->spec) runs it through here a second time.
 *   Every rule is written so that twice equals once; t/28-openapi30.t and
 *   t/30-discriminator.t pin that down.
 *
 * Only the spine (paths, path items, operations, content maps, components) and
 * the schemas themselves are rebuilt - every other branch is shared with the
 * original through newSVsv, so the copy stays cheap. */

/* Literal nesting depth guard. $refs are not followed, so this bounds only
 * hand-written nesting - but a spec can arrive from anywhere (Maat takes
 * uploads), and C recursion is not a place to trust input. */
#define OA_CONV_MAX_DEPTH 128

/* The marker every generated subschema carries. It makes the expansion
 * idempotent - a later pass drops what it finds and rebuilds - and it means a
 * reader of ->spec can see which branches the document declared and which
 * Open::API derived. `x-` is OpenAPI's own extension spelling, and JSF ignores
 * keywords it does not know. */
#define OA_DISC_MARK     "x-oa-discriminator"
#define OA_DISC_MARK_LEN 18

#define OA_SCHEMA_PFX     "#/components/schemas/"
#define OA_SCHEMA_PFX_LEN 21

typedef struct oa_norm {
    int v30;      /* apply the OpenAPI 3.0 schema rules            */
    HV *doc;      /* the source document                           */
    HV *kids;     /* base schema name -> AV of child names (+1)    */
} oa_norm;

static SV *oa_conv_schema(pTHX_ oa_norm *N, SV *schema, int depth,
                          const char *nm, STRLEN nml);

/* ---- booleans -------------------------------------------------------------- */

/* A JSON boolean as a decoder leaves it: a blessed Boolean object
 * (File::Raw::JSON::Boolean, JSON::PP::Boolean, ...) or the \1 / \0 idiom.
 *
 * A bare 1 or 0 is deliberately NOT one. It is the difference between the two
 * forms of `exclusiveMinimum`: 3.0 says boolean, 2020-12 says number, and
 * after conversion the key holds a number in a document that still declares
 * 3.0. Reading a bare 1 as `true` would make the second pass eat its own
 * output. */
static int oa_sv_is_json_bool(pTHX_ SV *sv) {
    SV *rv;
    PERL_UNUSED_CONTEXT;
    if (!sv || !SvROK(sv)) return 0;
    rv = SvRV(sv);
    return !(SvTYPE(rv) == SVt_PVHV || SvTYPE(rv) == SVt_PVAV
             || SvTYPE(rv) == SVt_PVCV);
}

/* Truth of a JSON boolean, or of a bare scalar. Used for `nullable`, which is
 * not a 2020-12 keyword at all and so is always consumed whatever its form. */
static int oa_sv_truthy(pTHX_ SV *sv) {
    if (!sv || !SvOK(sv)) return 0;
    if (SvROK(sv)) {
        SV *rv = SvRV(sv);
        if (SvTYPE(rv) == SVt_PVHV || SvTYPE(rv) == SVt_PVAV) return 1;
        return SvTRUE(rv) ? 1 : 0;
    }
    return SvTRUE(sv) ? 1 : 0;
}

/* ---- small copy helpers ---------------------------------------------------- */

/* Copy an HV one level deep: keys duplicated, values shared through newSVsv.
 * The caller then overwrites whichever keys it actually converts. */
static HV *oa_conv_copy_hv(pTHX_ HV *src) {
    HV *dst = newHV();
    HE *he;
    hv_iterinit(src);
    while ((he = hv_iternext(src))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        (void)hv_store(dst, k, kl, newSVsv(hv_iterval(src, he)), 0);
    }
    return dst;
}

typedef SV *(*oa_conv_fn)(pTHX_ oa_norm *N, SV *);

/* Apply `fn` to every value of a keyed map (paths, components.responses, ...). */
static SV *oa_conv_map(pTHX_ oa_norm *N, SV *map, oa_conv_fn fn) {
    HV *src = oa_hv_of(map), *dst;
    HE *he;
    if (!src) return newSVsv(map);
    dst = newHV();
    hv_iterinit(src);
    while ((he = hv_iternext(src))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        (void)hv_store(dst, k, kl, fn(aTHX_ N, hv_iterval(src, he)), 0);
    }
    return newRV_noinc((SV *)dst);
}

/* A list of schemas: allOf / anyOf / oneOf / prefixItems / tuple items. */
static SV *oa_conv_schema_list(pTHX_ oa_norm *N, SV *list, int depth) {
    AV *src = oa_av_of(list), *dst;
    SSize_t i, n;
    if (!src) return newSVsv(list);
    dst = newAV();
    n = av_len(src) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(src, i, 0);
        av_push(dst, (e && *e) ? oa_conv_schema(aTHX_ N, *e, depth + 1, NULL, 0)
                               : newSV(0));
    }
    return newRV_noinc((SV *)dst);
}

/* A map of schemas: properties / patternProperties / $defs / dependentSchemas. */
static SV *oa_conv_schema_map(pTHX_ oa_norm *N, SV *map, int depth) {
    HV *src = oa_hv_of(map), *dst;
    HE *he;
    if (!src) return newSVsv(map);
    dst = newHV();
    hv_iterinit(src);
    while ((he = hv_iternext(src))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        (void)hv_store(dst, k, kl,
                       oa_conv_schema(aTHX_ N, hv_iterval(src, he), depth + 1,
                                      NULL, 0), 0);
    }
    return newRV_noinc((SV *)dst);
}

/* ---- the schema keyword tables --------------------------------------------- */

static int oa_kw_in(const char *k, STRLEN l, const char *const *set) {
    int i;
    for (i = 0; set[i]; i++)
        if (strlen(set[i]) == l && memEQ(k, set[i], l)) return 1;
    return 0;
}

/* keywords whose value is a single Schema Object */
static int oa_kw_schema(const char *k, STRLEN l) {
    static const char *const s[] = {
        "additionalProperties", "not", "if", "then", "else", "propertyNames",
        "contains", "unevaluatedItems", "unevaluatedProperties", "contentSchema",
        NULL
    };
    return oa_kw_in(k, l, s);
}
/* keywords whose value is a map of Schema Objects */
static int oa_kw_schema_map(const char *k, STRLEN l) {
    static const char *const s[] = {
        "properties", "patternProperties", "$defs", "definitions",
        "dependentSchemas", NULL
    };
    return oa_kw_in(k, l, s);
}
/* keywords whose value is a list of Schema Objects */
static int oa_kw_schema_list(const char *k, STRLEN l) {
    static const char *const s[] = { "allOf", "anyOf", "oneOf", "prefixItems", NULL };
    return oa_kw_in(k, l, s);
}

/* Under 3.0, keywords beside a `$ref` are ignored. These are pure annotations
 * that cannot change a verdict - JSON::Schema::Fast treats every one of them as
 * inert - so they ride along and keep the docs UI useful; every other sibling
 * is an assertion and is dropped. */
static int oa_ref_sibling_ok(const char *k, STRLEN l) {
    static const char *const s[] = {
        "$ref", "title", "description", "summary", "deprecated", "default",
        "example", "examples", "readOnly", "writeOnly", "externalDocs", "xml",
        "discriminator", NULL
    };
    return oa_kw_in(k, l, s);
}

/* ---- discriminator --------------------------------------------------------- */

/* "#/components/schemas/Dog" -> "Dog". NULL when the ref is not a local
 * component schema (a remote or otherwise-shaped ref is left alone). */
static const char *oa_schema_ref_name(pTHX_ SV *ref, STRLEN *out) {
    STRLEN l; const char *p;
    if (!ref || SvROK(ref) || !SvOK(ref)) return NULL;
    p = SvPV_const(ref, l);
    if (l <= OA_SCHEMA_PFX_LEN || !memEQ(p, OA_SCHEMA_PFX, OA_SCHEMA_PFX_LEN))
        return NULL;
    if (memchr(p + OA_SCHEMA_PFX_LEN, '/', l - OA_SCHEMA_PFX_LEN)) return NULL;
    *out = l - OA_SCHEMA_PFX_LEN;
    return p + OA_SCHEMA_PFX_LEN;
}

/* A mapping value is either a JSON pointer or a bare component-schema name
 * ("Dog" and "#/components/schemas/Dog" both mean the same thing). */
static SV *oa_disc_ref(pTHX_ SV *v) {
    STRLEN l; const char *p;
    if (!v || SvROK(v)) return NULL;
    p = SvPV_const(v, l);
    if (!l) return NULL;
    if (p[0] == '#' || memchr(p, '/', l)) return newSVsv(v);
    { SV *r = newSVpvn(OA_SCHEMA_PFX, OA_SCHEMA_PFX_LEN);
      sv_catpvn(r, p, l); return r; }
}

/* components.schemas.<name> as it was written, borrowed. */
static SV *oa_named_schema(pTHX_ oa_norm *N, const char *nm, STRLEN nl) {
    HV *comp = N->doc ? oa_hv_of(oa_get(aTHX_ N->doc, "components")) : NULL;
    HV *sch  = comp ? oa_hv_of(oa_get(aTHX_ comp, "schemas")) : NULL;
    SV **e   = sch ? hv_fetch(sch, nm, (I32)nl, 0) : NULL;
    return (e && *e && oa_hv_of(*e)) ? *e : NULL;
}

/* base schema name -> the schemas that allOf-reference it, in document order.
 * Built once, lazily: it is only needed by the inheritance form. */
static HV *oa_norm_kids(pTHX_ oa_norm *N) {
    HV *comp, *schemas;
    HE *he;
    if (N->kids) return N->kids;
    N->kids = newHV();
    comp    = N->doc ? oa_hv_of(oa_get(aTHX_ N->doc, "components")) : NULL;
    schemas = comp ? oa_hv_of(oa_get(aTHX_ comp, "schemas")) : NULL;
    if (!schemas) return N->kids;
    hv_iterinit(schemas);
    while ((he = hv_iternext(schemas))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        HV *sh = oa_hv_of(hv_iterval(schemas, he));
        AV *all = sh ? oa_av_of(oa_get(aTHX_ sh, "allOf")) : NULL;
        SSize_t i, n = all ? av_len(all) + 1 : 0;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(all, i, 0);
            HV *mh = (e && *e) ? oa_hv_of(*e) : NULL;
            STRLEN bl;
            const char *base = mh ? oa_schema_ref_name(aTHX_ oa_get(aTHX_ mh, "$ref"), &bl)
                                  : NULL;
            SV **slot;
            AV *lst;
            if (!base) continue;
            slot = hv_fetch(N->kids, base, (I32)bl, 0);
            if (slot && *slot && oa_av_of(*slot)) lst = oa_av_of(*slot);
            else {
                lst = newAV();
                (void)hv_store(N->kids, base, (I32)bl, newRV_noinc((SV *)lst), 0);
            }
            av_push(lst, newSVpvn(k, (STRLEN)kl));
        }
    }
    return N->kids;
}

/* Insertion-sort an AV of strings. Hash order is not order, and a document
 * that normalises differently run to run is a document you cannot diff. */
static void oa_sort_av(pTHX_ AV *av) {
    SSize_t i, j, n = av_len(av) + 1;
    for (i = 1; i < n; i++) {
        SV *key = SvREFCNT_inc(*av_fetch(av, i, 0));
        for (j = i - 1; j >= 0; j--) {
            SV **c = av_fetch(av, j, 0);
            if (!c || !*c || sv_cmp(*c, key) <= 0) break;
            (void)av_store(av, j + 1, SvREFCNT_inc(*c));
        }
        (void)av_store(av, j + 1, key);
    }
}

/* Collect the discriminator's (key -> $ref) entries into two parallel arrays.
 *
 * Three sources, in precedence order: an explicit `mapping`; the $refs of a
 * sibling oneOf/anyOf (implicit key = the schema name); or, for a named base
 * schema, the schemas that allOf-reference it. Returns 0 when there is nothing
 * to expand, in which case the discriminator stays an inert annotation.
 *
 * `*from_union` says the entries came from oneOf/anyOf, which are then replaced
 * by the generated chain: leaving them would reintroduce the ambiguity the
 * discriminator exists to resolve (two branches a payload both satisfies make
 * `oneOf` fail, however clear the document was about which one was meant). */
static int oa_disc_entries(pTHX_ oa_norm *N, HV *src, HV *dh,
                           const char *nm, STRLEN nml,
                           AV **keys_out, AV **refs_out, int *from_union) {
    AV *keys = (AV *)sv_2mortal((SV *)newAV());
    AV *refs = (AV *)sv_2mortal((SV *)newAV());
    HV *map  = oa_hv_of(oa_get(aTHX_ dh, "mapping"));
    SSize_t i, n;

    *from_union = 0;

    if (map && HvUSEDKEYS(map)) {
        AV *mk = (AV *)sv_2mortal((SV *)newAV());
        HE *he;
        hv_iterinit(map);
        while ((he = hv_iternext(map))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            av_push(mk, newSVpvn(k, (STRLEN)kl));
        }
        oa_sort_av(aTHX_ mk);
        n = av_len(mk) + 1;
        for (i = 0; i < n; i++) {
            SV *k = *av_fetch(mk, i, 0);
            STRLEN kl; const char *kp = SvPV_const(k, kl);
            SV **v = hv_fetch(map, kp, (I32)kl, 0);
            SV *ref = (v && *v) ? oa_disc_ref(aTHX_ *v) : NULL;
            if (!ref) continue;
            av_push(keys, newSVsv(k));
            av_push(refs, ref);
        }
    }
    else {
        /* a sibling union, but only when every branch is a plain component
         * $ref - a mixed union has nothing to key an implicit mapping on */
        AV *un = oa_av_of(oa_get(aTHX_ src, "oneOf"));
        if (!un) un = oa_av_of(oa_get(aTHX_ src, "anyOf"));
        if (un && (n = av_len(un) + 1) > 0) {
            int all_refs = 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(un, i, 0);
                HV *mh = (e && *e) ? oa_hv_of(*e) : NULL;
                STRLEN rl;
                const char *rn = mh ? oa_schema_ref_name(aTHX_ oa_get(aTHX_ mh, "$ref"), &rl)
                                    : NULL;
                if (!rn) { all_refs = 0; break; }
                av_push(keys, newSVpvn(rn, rl));
                av_push(refs, newSVsv(oa_get(aTHX_ mh, "$ref")));
            }
            if (all_refs) *from_union = 1;
            else { av_clear(keys); av_clear(refs); }
        }
        /* a named base schema: the children that inherit from it */
        if (!*from_union && nm && nml) {
            HV *kids = oa_norm_kids(aTHX_ N);
            SV **slot = hv_fetch(kids, nm, (I32)nml, 0);
            AV *lst = (slot && *slot) ? oa_av_of(*slot) : NULL;
            if (lst) {
                AV *sorted = (AV *)sv_2mortal((SV *)newAV());
                n = av_len(lst) + 1;
                for (i = 0; i < n; i++) av_push(sorted, newSVsv(*av_fetch(lst, i, 0)));
                oa_sort_av(aTHX_ sorted);
                for (i = 0; i < n; i++) {
                    SV *c = *av_fetch(sorted, i, 0);
                    STRLEN cl; const char *cp = SvPV_const(c, cl);
                    SV *ref = newSVpvn(OA_SCHEMA_PFX, OA_SCHEMA_PFX_LEN);
                    sv_catpvn(ref, cp, cl);
                    av_push(keys, newSVsv(c));
                    av_push(refs, ref);
                }
            }
        }
    }

    if (av_len(keys) < 0) return 0;
    *keys_out = keys;
    *refs_out = refs;
    return 1;
}

/* The `then` schema for one mapping entry.
 *
 * Normally {$ref: target}. But in the inheritance form the child allOf-
 * references the very base doing the dispatching, and
 * base -> then -> child -> base is an infinite validation loop. So when the
 * target refers back to `nm`, that one reference is dropped and the child's
 * own constraints are inlined instead - which is exactly what the child adds
 * on top of the base, and terminates. */
static SV *oa_disc_then(pTHX_ oa_norm *N, SV *ref, const char *nm, STRLEN nml,
                        int depth) {
    STRLEN tl = 0;
    const char *tn = NULL;
    SV *target = NULL;
    AV *all = NULL;
    SSize_t i, n = 0;
    int backref = 0;

    if (nm && nml && (tn = oa_schema_ref_name(aTHX_ ref, &tl)) != NULL
        && (target = oa_named_schema(aTHX_ N, tn, tl)) != NULL
        && (all = oa_av_of(oa_get(aTHX_ (HV *)SvRV(target), "allOf"))) != NULL) {
        n = av_len(all) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(all, i, 0);
            HV *mh = (e && *e) ? oa_hv_of(*e) : NULL;
            STRLEN bl;
            const char *bn = mh
                ? oa_schema_ref_name(aTHX_ oa_get(aTHX_ mh, "$ref"), &bl) : NULL;
            if (bn && bl == nml && memEQ(bn, nm, nml)) { backref = 1; break; }
        }
    }

    if (!backref) {                      /* no loop to break: name the target */
        HV *r = newHV();
        (void)hv_stores(r, "$ref", newSVsv(ref));
        return newRV_noinc((SV *)r);
    }

    /* Convert the child exactly as it is converted in its own right - passing
     * its name so a hierarchy more than one level deep expands the same way -
     * then drop the one member that points back at us. */
    {
        SV *conv = oa_conv_schema(aTHX_ N, target, depth + 1, tn, tl);
        HV *out  = (HV *)SvRV(conv);
        AV *ca   = oa_av_of(oa_get(aTHX_ out, "allOf"));
        AV *keep;
        if (!ca) return conv;
        keep = newAV();
        n = av_len(ca) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(ca, i, 0);
            HV *mh = (e && *e) ? oa_hv_of(*e) : NULL;
            STRLEN bl;
            const char *bn = mh
                ? oa_schema_ref_name(aTHX_ oa_get(aTHX_ mh, "$ref"), &bl) : NULL;
            if (bn && bl == nml && memEQ(bn, nm, nml)) continue;
            av_push(keep, (e && *e) ? SvREFCNT_inc(*e) : newSV(0));
        }
        if (av_len(keep) >= 0)
            (void)hv_stores(out, "allOf", newRV_noinc((SV *)keep));
        else {
            SvREFCNT_dec((SV *)keep);
            (void)hv_delete(out, "allOf", 5, G_DISCARD);
        }
        return conv;
    }
}

/* { <mark>: pn, required: [pn], properties: { pn: <inner> } } - the shape both
 * generated forms share: the guard uses an enum of every known value, each
 * branch's `if` uses a const. */
static SV *oa_disc_probe(pTHX_ SV *pn, SV *inner) {
    HV *out = newHV(), *props = newHV();
    AV *req = newAV();
    av_push(req, newSVsv(pn));
    (void)hv_store(props, SvPVX_const(pn), (I32)SvCUR(pn), inner, 0);
    (void)hv_stores(out, "required",   newRV_noinc((SV *)req));
    (void)hv_stores(out, "properties", newRV_noinc((SV *)props));
    return newRV_noinc((SV *)out);
}

/* ---- a Schema Object ------------------------------------------------------- */

static SV *oa_conv_schema(pTHX_ oa_norm *N, SV *schema, int depth,
                          const char *nm, STRLEN nml) {
    HV *src = oa_hv_of(schema), *dst;
    HE *he;
    SV *nullable, *ref, *type, *mn, *mx, *exmn, *exmx, *items, *fmt;
    SV *disc, *pn = NULL;
    HV *dh = NULL;
    AV *dkeys = NULL, *drefs = NULL;
    int has_ref, is_nullable, tuple;
    int exmn_bool, exmx_bool, exmn_on, exmx_on;
    int expand = 0, from_union = 0;

    /* booleans, arrays and junk are not objects to rewrite: share them */
    if (!src || depth >= OA_CONV_MAX_DEPTH) return newSVsv(schema);

    nullable = N->v30 ? oa_get(aTHX_ src, "nullable") : NULL;
    ref      = oa_get(aTHX_ src, "$ref");
    type     = oa_get(aTHX_ src, "type");
    mn       = oa_get(aTHX_ src, "minimum");
    mx       = oa_get(aTHX_ src, "maximum");
    exmn     = oa_get(aTHX_ src, "exclusiveMinimum");
    exmx     = oa_get(aTHX_ src, "exclusiveMaximum");
    items    = oa_get(aTHX_ src, "items");
    fmt      = oa_get(aTHX_ src, "format");
    disc     = oa_get(aTHX_ src, "discriminator");

    has_ref     = ref && !SvROK(ref);
    is_nullable = oa_sv_truthy(aTHX_ nullable);

    /* the 3.0 boolean form of the exclusive bounds, and only that form */
    exmn_bool = N->v30 && exmn && oa_sv_is_json_bool(aTHX_ exmn);
    exmx_bool = N->v30 && exmx && oa_sv_is_json_bool(aTHX_ exmx);
    exmn_on   = exmn_bool && oa_sv_truthy(aTHX_ exmn) && mn != NULL;
    exmx_on   = exmx_bool && oa_sv_truthy(aTHX_ exmx) && mx != NULL;

    /* draft-04 tuple `items` (not legal 3.0, but specs carry the habit) */
    tuple = N->v30 && items && oa_av_of(items) && !oa_get(aTHX_ src, "prefixItems");

    /* discriminator: expandable in either version */
    dh = disc ? oa_hv_of(disc) : NULL;
    pn = dh ? oa_get(aTHX_ dh, "propertyName") : NULL;
    if (pn && !SvROK(pn)) {
        STRLEN pl;
        (void)SvPV_const(pn, pl);   /* force POK: SvPVX/SvCUR are used below */
        if (pl) expand = oa_disc_entries(aTHX_ N, src, dh, nm, nml,
                                         &dkeys, &drefs, &from_union);
    }

    dst = newHV();
    hv_iterinit(src);
    while ((he = hv_iternext(src))) {
        I32 i32kl; const char *k = hv_iterkey(he, &i32kl);
        SV *v = hv_iterval(src, he);
        STRLEN kl = (STRLEN)i32kl;

        /* `nullable` never survives: it is not a 2020-12 keyword */
        if (N->v30 && kl == 8 && memEQ(k, "nullable", 8)) continue;

        /* beside a $ref, assertions are ignored under 3.0 */
        if (N->v30 && has_ref && !oa_ref_sibling_ok(k, kl)) continue;

        /* $ref itself: the nullable form rebuilds it as an anyOf below */
        if (kl == 4 && memEQ(k, "$ref", 4)) {
            if (!(has_ref && is_nullable))
                (void)hv_store(dst, k, i32kl, newSVsv(v), 0);
            continue;
        }

        /* the union the discriminator replaces */
        if (expand && from_union
            && ((kl == 5 && memEQ(k, "oneOf", 5))
             || (kl == 5 && memEQ(k, "anyOf", 5)))) continue;

        /* the discriminator is rewritten below, with its mapping made explicit */
        if (expand && kl == 13 && memEQ(k, "discriminator", 13)) continue;

        /* previously generated members: dropped, then rebuilt */
        if (expand && kl == 5 && memEQ(k, "allOf", 5)) {
            AV *keep = newAV();
            AV *av = oa_av_of(v);
            SSize_t i, n = av ? av_len(av) + 1 : 0;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                HV *mh = (e && *e) ? oa_hv_of(*e) : NULL;
                if (mh && hv_exists(mh, OA_DISC_MARK, OA_DISC_MARK_LEN)) continue;
                av_push(keep, (e && *e)
                        ? oa_conv_schema(aTHX_ N, *e, depth + 1, NULL, 0) : newSV(0));
            }
            (void)hv_stores(dst, "allOf", newRV_noinc((SV *)keep));
            continue;
        }

        /* numeric bounds: the boolean exclusive* form folds into the number */
        if (N->v30 && kl == 7 && memEQ(k, "minimum", 7)) {
            if (!exmn_on) (void)hv_store(dst, k, i32kl, newSVsv(v), 0);
            continue;
        }
        if (N->v30 && kl == 7 && memEQ(k, "maximum", 7)) {
            if (!exmx_on) (void)hv_store(dst, k, i32kl, newSVsv(v), 0);
            continue;
        }
        if (kl == 16 && memEQ(k, "exclusiveMinimum", 16)) {
            if      (!exmn_bool) (void)hv_store(dst, k, i32kl, newSVsv(v), 0);
            else if (exmn_on)    (void)hv_store(dst, k, i32kl, newSVsv(mn), 0);
            continue;   /* `true` with no minimum, or `false`: meaningless */
        }
        if (kl == 16 && memEQ(k, "exclusiveMaximum", 16)) {
            if      (!exmx_bool) (void)hv_store(dst, k, i32kl, newSVsv(v), 0);
            else if (exmx_on)    (void)hv_store(dst, k, i32kl, newSVsv(mx), 0);
            continue;
        }

        /* tuple items -> prefixItems, and additionalItems takes over `items` */
        if (kl == 5 && memEQ(k, "items", 5)) {
            if (tuple)
                (void)hv_stores(dst, "prefixItems",
                                oa_conv_schema_list(aTHX_ N, v, depth));
            else
                (void)hv_store(dst, k, i32kl,
                               oa_conv_schema(aTHX_ N, v, depth + 1, NULL, 0), 0);
            continue;
        }
        if (N->v30 && kl == 15 && memEQ(k, "additionalItems", 15)) {
            if (tuple)
                (void)hv_stores(dst, "items",
                                oa_conv_schema(aTHX_ N, v, depth + 1, NULL, 0));
            continue;   /* without a tuple it constrains nothing */
        }

        /* schema-level `example` is 3.1's `examples` array. The value itself is
         * user JSON and is copied, never walked. */
        if (N->v30 && kl == 7 && memEQ(k, "example", 7)) {
            if (!oa_get(aTHX_ src, "examples")) {
                AV *ex = newAV();
                av_push(ex, newSVsv(v));
                (void)hv_stores(dst, "examples", newRV_noinc((SV *)ex));
            }
            continue;
        }

        if (oa_kw_schema(k, kl)) {
            (void)hv_store(dst, k, i32kl,
                           oa_conv_schema(aTHX_ N, v, depth + 1, NULL, 0), 0);
        } else if (oa_kw_schema_map(k, kl)) {
            (void)hv_store(dst, k, i32kl, oa_conv_schema_map(aTHX_ N, v, depth), 0);
        } else if (oa_kw_schema_list(k, kl)) {
            (void)hv_store(dst, k, i32kl, oa_conv_schema_list(aTHX_ N, v, depth), 0);
        } else {
            (void)hv_store(dst, k, i32kl, newSVsv(v), 0);   /* value or annotation */
        }
    }

    /* ---- rules that add keys ---- */

    if (is_nullable) {
        if (has_ref) {
            /* `nullable` beside a $ref: the one sibling worth keeping, as the
             * union the 3.1 spec would have written. */
            AV *alt = newAV();
            HV *rh  = newHV(), *nh = newHV();
            (void)hv_stores(rh, "$ref", newSVsv(ref));
            (void)hv_stores(nh, "type", newSVpvs("null"));
            av_push(alt, newRV_noinc((SV *)rh));
            av_push(alt, newRV_noinc((SV *)nh));
            (void)hv_stores(dst, "anyOf", newRV_noinc((SV *)alt));
        } else if (type) {
            AV *t = newAV();
            int seen = 0;
            if (SvROK(type) && oa_av_of(type)) {
                AV *ta = oa_av_of(type);
                SSize_t i, n = av_len(ta) + 1;
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(ta, i, 0);
                    if (!e || !*e) continue;
                    { STRLEN l; const char *p = SvPV_const(*e, l);
                      if (l == 4 && memEQ(p, "null", 4)) seen = 1; }
                    av_push(t, newSVsv(*e));
                }
            } else {
                STRLEN l; const char *p = SvPV_const(type, l);
                if (l == 4 && memEQ(p, "null", 4)) seen = 1;
                av_push(t, newSVsv(type));
            }
            if (!seen) av_push(t, newSVpvs("null"));
            (void)hv_stores(dst, "type", newRV_noinc((SV *)t));
        } else {
            /* no type to widen: a nullable enum admits the null member */
            SV *en = oa_get(aTHX_ src, "enum");
            AV *ea = en ? oa_av_of(en) : NULL;
            if (ea) {
                AV *out = newAV();
                SSize_t i, n = av_len(ea) + 1;
                int seen = 0;
                for (i = 0; i < n; i++) {
                    SV **e = av_fetch(ea, i, 0);
                    if (e && *e && !SvOK(*e)) seen = 1;
                    av_push(out, (e && *e) ? newSVsv(*e) : newSV(0));
                }
                if (!seen) av_push(out, newSV(0));
                (void)hv_stores(dst, "enum", newRV_noinc((SV *)out));
            }
            /* nullable with neither type nor enum constrains nothing: drop it */
        }
    }

    /* 3.0 spelled binary payloads with `format`; 2020-12 has vocabulary for it.
     * `format` stays as well - it is inert to the validator, and the docs UI
     * keys its file picker off either idiom. */
    if (N->v30 && fmt && !SvROK(fmt)) {
        STRLEN l; const char *p = SvPV_const(fmt, l);
        if (l == 4 && memEQ(p, "byte", 4) && !oa_get(aTHX_ src, "contentEncoding"))
            (void)hv_stores(dst, "contentEncoding", newSVpvs("base64"));
        else if (l == 6 && memEQ(p, "binary", 6)
                 && !oa_get(aTHX_ src, "contentMediaType"))
            (void)hv_stores(dst, "contentMediaType",
                            newSVpvs("application/octet-stream"));
    }

    /* the discriminator chain */
    if (expand) {
        SSize_t i, n = av_len(dkeys) + 1;
        AV *chain;
        SV **slot;

        {   /* the discriminator, with its mapping now always explicit: that is
             * what makes a second pass rebuild exactly this same chain */
            HV *d2 = oa_conv_copy_hv(aTHX_ dh);
            HV *m2 = newHV();
            for (i = 0; i < n; i++) {
                SV *k = *av_fetch(dkeys, i, 0);
                (void)hv_store(m2, SvPVX_const(k), (I32)SvCUR(k),
                               newSVsv(*av_fetch(drefs, i, 0)), 0);
            }
            (void)hv_stores(d2, "mapping", newRV_noinc((SV *)m2));
            (void)hv_stores(dst, "discriminator", newRV_noinc((SV *)d2));
        }

        slot  = hv_fetchs(dst, "allOf", 0);
        chain = (slot && *slot && oa_av_of(*slot)) ? oa_av_of(*slot) : NULL;
        if (!chain) {
            chain = newAV();
            (void)hv_stores(dst, "allOf", newRV_noinc((SV *)chain));
        }

        {   /* the guard: the property is required, and must name a branch we
             * know. Without it an unmapped value would match no `if` at all and
             * so be validated against nothing. */
            AV *en = newAV();
            HV *inner = newHV();
            SV *probe;
            for (i = 0; i < n; i++) av_push(en, newSVsv(*av_fetch(dkeys, i, 0)));
            (void)hv_stores(inner, "enum", newRV_noinc((SV *)en));
            probe = oa_disc_probe(aTHX_ pn, newRV_noinc((SV *)inner));
            (void)hv_stores((HV *)SvRV(probe), OA_DISC_MARK, newSVsv(pn));
            av_push(chain, probe);
        }

        for (i = 0; i < n; i++) {
            HV *branch = newHV(), *inner = newHV();
            SV *ref_i = *av_fetch(drefs, i, 0);
            (void)hv_stores(inner, "const", newSVsv(*av_fetch(dkeys, i, 0)));
            (void)hv_stores(branch, OA_DISC_MARK, newSVsv(pn));
            (void)hv_stores(branch, "if",
                            oa_disc_probe(aTHX_ pn, newRV_noinc((SV *)inner)));
            (void)hv_stores(branch, "then",
                            oa_disc_then(aTHX_ N, ref_i, nm, nml, depth));
            av_push(chain, newRV_noinc((SV *)branch));
        }
    }

    return newRV_noinc((SV *)dst);
}

/* ---- the document spine ---------------------------------------------------- */

/* A Media Type Object: { schema: S, example: V, examples: {...} }. The
 * `example`/`examples` here are Example Objects, not schema keywords - they are
 * copied, not converted. */
static SV *oa_conv_media(pTHX_ oa_norm *N, SV *media) {
    HV *mh = oa_hv_of(media), *mc;
    SV *schema;
    if (!mh) return newSVsv(media);
    schema = oa_get(aTHX_ mh, "schema");
    if (!schema) return newSVsv(media);
    mc = oa_conv_copy_hv(aTHX_ mh);
    (void)hv_stores(mc, "schema", oa_conv_schema(aTHX_ N, schema, 0, NULL, 0));
    return newRV_noinc((SV *)mc);
}

/* a `content` map: { "application/json": <Media Type Object>, ... } */
static SV *oa_conv_content(pTHX_ oa_norm *N, SV *content) {
    return oa_conv_map(aTHX_ N, content, oa_conv_media);
}

/* A Parameter or Header Object: `schema`, or `content` holding one. */
static SV *oa_conv_param(pTHX_ oa_norm *N, SV *p) {
    HV *ph = oa_hv_of(p), *pc;
    SV *schema, *content;
    if (!ph) return newSVsv(p);
    schema  = oa_get(aTHX_ ph, "schema");
    content = oa_get(aTHX_ ph, "content");
    if (!schema && !content) return newSVsv(p);
    pc = oa_conv_copy_hv(aTHX_ ph);
    if (schema)  (void)hv_stores(pc, "schema",
                                 oa_conv_schema(aTHX_ N, schema, 0, NULL, 0));
    if (content) (void)hv_stores(pc, "content", oa_conv_content(aTHX_ N, content));
    return newRV_noinc((SV *)pc);
}

static SV *oa_conv_param_list(pTHX_ oa_norm *N, SV *params) {
    AV *src = oa_av_of(params), *dst;
    SSize_t i, n;
    if (!src) return newSVsv(params);
    dst = newAV();
    n = av_len(src) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(src, i, 0);
        av_push(dst, (e && *e) ? oa_conv_param(aTHX_ N, *e) : newSV(0));
    }
    return newRV_noinc((SV *)dst);
}

static SV *oa_conv_body(pTHX_ oa_norm *N, SV *rb) {
    HV *h = oa_hv_of(rb), *c;
    SV *content;
    if (!h) return newSVsv(rb);
    content = oa_get(aTHX_ h, "content");
    if (!content) return newSVsv(rb);
    c = oa_conv_copy_hv(aTHX_ h);
    (void)hv_stores(c, "content", oa_conv_content(aTHX_ N, content));
    return newRV_noinc((SV *)c);
}

static SV *oa_conv_response(pTHX_ oa_norm *N, SV *r) {
    HV *h = oa_hv_of(r), *c;
    SV *content, *hdrs;
    if (!h) return newSVsv(r);
    content = oa_get(aTHX_ h, "content");
    hdrs    = oa_get(aTHX_ h, "headers");
    if (!content && !hdrs) return newSVsv(r);
    c = oa_conv_copy_hv(aTHX_ h);
    if (content) (void)hv_stores(c, "content", oa_conv_content(aTHX_ N, content));
    if (hdrs)    (void)hv_stores(c, "headers",
                                 oa_conv_map(aTHX_ N, hdrs, oa_conv_param));
    return newRV_noinc((SV *)c);
}

static SV *oa_conv_operation(pTHX_ oa_norm *N, SV *op) {
    HV *h = oa_hv_of(op), *c;
    SV *params, *rb, *resps;
    if (!h) return newSVsv(op);
    params = oa_get(aTHX_ h, "parameters");
    rb     = oa_get(aTHX_ h, "requestBody");
    resps  = oa_get(aTHX_ h, "responses");
    if (!params && !rb && !resps) return newSVsv(op);
    c = oa_conv_copy_hv(aTHX_ h);
    if (params) (void)hv_stores(c, "parameters",  oa_conv_param_list(aTHX_ N, params));
    if (rb)     (void)hv_stores(c, "requestBody", oa_conv_body(aTHX_ N, rb));
    if (resps)  (void)hv_stores(c, "responses",
                                oa_conv_map(aTHX_ N, resps, oa_conv_response));
    return newRV_noinc((SV *)c);
}

static SV *oa_conv_path_item(pTHX_ oa_norm *N, SV *item) {
    HV *h = oa_hv_of(item), *c;
    SV *params;
    int m;
    if (!h) return newSVsv(item);
    c = oa_conv_copy_hv(aTHX_ h);
    params = oa_get(aTHX_ h, "parameters");
    if (params) (void)hv_stores(c, "parameters", oa_conv_param_list(aTHX_ N, params));
    for (m = 0; oa_methods[m]; m++) {
        SV *op = oa_get(aTHX_ h, oa_methods[m]);
        if (op) (void)hv_store(c, oa_methods[m], (I32)strlen(oa_methods[m]),
                               oa_conv_operation(aTHX_ N, op), 0);
    }
    return newRV_noinc((SV *)c);
}

/* components.schemas is the one place a schema has a name, and the name is what
 * the inheritance form of `discriminator` keys its children on. */
static SV *oa_conv_schemas(pTHX_ oa_norm *N, SV *schemas) {
    HV *src = oa_hv_of(schemas), *dst;
    HE *he;
    if (!src) return newSVsv(schemas);
    dst = newHV();
    hv_iterinit(src);
    while ((he = hv_iternext(src))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        (void)hv_store(dst, k, kl,
                       oa_conv_schema(aTHX_ N, hv_iterval(src, he), 0,
                                      k, (STRLEN)kl), 0);
    }
    return newRV_noinc((SV *)dst);
}

static SV *oa_conv_components(pTHX_ oa_norm *N, SV *comp) {
    HV *h = oa_hv_of(comp), *c;
    SV *v;
    if (!h) return newSVsv(comp);
    c = oa_conv_copy_hv(aTHX_ h);
    if ((v = oa_get(aTHX_ h, "schemas")))
        (void)hv_stores(c, "schemas", oa_conv_schemas(aTHX_ N, v));
    if ((v = oa_get(aTHX_ h, "parameters")))
        (void)hv_stores(c, "parameters", oa_conv_map(aTHX_ N, v, oa_conv_param));
    if ((v = oa_get(aTHX_ h, "headers")))
        (void)hv_stores(c, "headers", oa_conv_map(aTHX_ N, v, oa_conv_param));
    if ((v = oa_get(aTHX_ h, "requestBodies")))
        (void)hv_stores(c, "requestBodies", oa_conv_map(aTHX_ N, v, oa_conv_body));
    if ((v = oa_get(aTHX_ h, "responses")))
        (void)hv_stores(c, "responses", oa_conv_map(aTHX_ N, v, oa_conv_response));
    return newRV_noinc((SV *)c);
}

/* Return a normalised document, or the original SV when there is nothing to do.
 * `doc` is never mutated. */
static SV *oa_normalize(pTHX_ SV *doc, int v30) {
    HV *h = oa_hv_of(doc), *c;
    SV *v;
    oa_norm N;
    if (!h) return newSVsv(doc);
    N.v30  = v30;
    N.doc  = h;
    N.kids = NULL;
    c = oa_conv_copy_hv(aTHX_ h);
    if ((v = oa_get(aTHX_ h, "paths")))
        (void)hv_stores(c, "paths", oa_conv_map(aTHX_ &N, v, oa_conv_path_item));
    if ((v = oa_get(aTHX_ h, "components")))
        (void)hv_stores(c, "components", oa_conv_components(aTHX_ &N, v));
    if (N.kids) SvREFCNT_dec((SV *)N.kids);
    return newRV_noinc((SV *)c);
}

#endif /* OA_NORMALIZE_H */

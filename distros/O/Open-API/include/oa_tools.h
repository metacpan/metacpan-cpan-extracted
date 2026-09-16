#ifndef OA_TOOLS_H
#define OA_TOOLS_H

/* Two things the compiled table cannot answer.
 *
 * oa_compile.h keeps a JSON::Schema::Fast handle where a schema would be, so
 * operation_info can report only WHETHER one is attached, and it keeps no
 * summary, description or tags at all - the compiled form is what will be
 * checked, not what the document said. A caller that wants to describe an
 * operation to something that is not this validator needs the document, and
 * ->spec is the right document to read: it is normalised to 3.1 shape whatever
 * the source declared, and OpenAPI 3.1 schemas ARE JSON Schema 2020-12, so
 * what comes out needs no dialect translation.
 *
 * Both entry points run once per compile, never on a request path.
 *
 * Deliberately NOT emitted: `additionalProperties`. The natural spelling of
 * JSON false here is the \0 idiom the rest of the stack uses, and
 * JSON::Schema::Fast refuses a scalar ref as a boolean schema ("schema must be
 * a hashref or boolean"), while a bare 0 would encode as the number zero and
 * stop being valid JSON Schema on the wire. Leaving it out keeps the result
 * both compilable and encodable, and a caller reading these schemas takes the
 * parameter names it knows.
 *
 * Needs oa_compile.h (oa_get, oa_hv_of, oa_av_of, oa_methods, oa_ctype_is_json)
 * and oa_normalize.h (oa_conv_copy_hv). */

#ifndef OA_SCHEMA_PFX
#define OA_SCHEMA_PFX     "#/components/schemas/"
#define OA_SCHEMA_PFX_LEN 21
#endif

#define OA_DEFS_PFX      "#/$defs/"
#define OA_DEFS_PFX_LEN  8

/* A spec can arrive from anywhere, and C recursion is not a place to trust
 * input; the same reasoning as OA_CONV_MAX_DEPTH next door. */
#define OA_TOOLS_MAX_DEPTH 128

/* ---- walking -------------------------------------------------------------- */

static void oa_tools_refs_in(pTHX_ SV *node, HV *seen, int depth);

static void oa_tools_refs_hv(pTHX_ HV *h, HV *seen, int depth) {
    HE *he;
    hv_iterinit(h);
    while ((he = hv_iternext(h))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        SV *v = hv_iterval(h, he);
        if (kl == 4 && memEQ(k, "$ref", 4) && v && !SvROK(v) && SvOK(v)) {
            STRLEN l; const char *p = SvPV_const(v, l);
            if (l > OA_DEFS_PFX_LEN && memEQ(p, OA_DEFS_PFX, OA_DEFS_PFX_LEN)) {
                /* The DEF is the first segment; anything after it is a pointer
                 * INTO that def (`#/$defs/A/properties/b`), which resolves on
                 * its own once A is carried. Keying on the whole remainder
                 * looked for a def literally named "A/properties/b", missed,
                 * and - before 0.13 - stored an EMPTY schema under that name,
                 * which compiles and then accepts anything. */
                const char *nm = p + OA_DEFS_PFX_LEN;
                STRLEN nl = l - OA_DEFS_PFX_LEN;
                const char *slash = (const char *)memchr(nm, '/', nl);
                if (slash) nl = (STRLEN)(slash - nm);
                if (nl) (void)hv_store(seen, nm, (I32)nl, newSViv(1), 0);
            }
            continue;
        }
        oa_tools_refs_in(aTHX_ v, seen, depth + 1);
    }
}

/* Every "#/$defs/NAME" mentioned anywhere under `node`, as keys of `seen`. */
static void oa_tools_refs_in(pTHX_ SV *node, HV *seen, int depth) {
    SV *rv;
    if (!node || depth > OA_TOOLS_MAX_DEPTH || !SvROK(node)) return;
    rv = SvRV(node);
    if (SvTYPE(rv) == SVt_PVHV) { oa_tools_refs_hv(aTHX_ (HV *)rv, seen, depth); return; }
    if (SvTYPE(rv) == SVt_PVAV) {
        AV *av = (AV *)rv;
        SSize_t i, n = av_len(av) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            if (e && *e) oa_tools_refs_in(aTHX_ *e, seen, depth + 1);
        }
    }
}

/* A deep copy with every "#/components/schemas/X" rewritten to "#/$defs/X".
 * A copy, because nothing handed to a caller may share nodes with ->spec. */
static SV *oa_tools_rewrite(pTHX_ SV *node, int depth) {
    SV *rv;
    if (!node) return newSV(0);
    if (depth > OA_TOOLS_MAX_DEPTH || !SvROK(node)) return newSVsv(node);
    rv = SvRV(node);

    if (SvTYPE(rv) == SVt_PVHV) {
        HV *src = (HV *)rv, *dst = newHV();
        HE *he;
        hv_iterinit(src);
        while ((he = hv_iternext(src))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            SV *v = hv_iterval(src, he);
            if (kl == 4 && memEQ(k, "$ref", 4) && v && !SvROK(v) && SvOK(v)) {
                STRLEN l; const char *p = SvPV_const(v, l);
                if (l > OA_SCHEMA_PFX_LEN
                    && memEQ(p, OA_SCHEMA_PFX, OA_SCHEMA_PFX_LEN)) {
                    SV *nr = newSVpvn(OA_DEFS_PFX, OA_DEFS_PFX_LEN);
                    sv_catpvn(nr, p + OA_SCHEMA_PFX_LEN, l - OA_SCHEMA_PFX_LEN);
                    (void)hv_store(dst, k, kl, nr, 0);
                    continue;
                }
            }
            (void)hv_store(dst, k, kl, oa_tools_rewrite(aTHX_ v, depth + 1), 0);
        }
        return newRV_noinc((SV *)dst);
    }

    if (SvTYPE(rv) == SVt_PVAV) {
        AV *src = (AV *)rv, *dst = newAV();
        SSize_t i, n = av_len(src) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(src, i, 0);
            av_push(dst, oa_tools_rewrite(aTHX_ (e && *e) ? *e : NULL, depth + 1));
        }
        return newRV_noinc((SV *)dst);
    }

    return newSVsv(node);
}

/* ---- finding --------------------------------------------------------------- */

/* The operation object as the document wrote it. `item_out` is its path item,
 * which carries parameters shared by every method on that path. */
static HV *oa_tools_find_op(pTHX_ oa_api *a, SV *op_id, HV **item_out,
                            SV **path_out, const char **method_out) {
    HV *spec  = a ? oa_hv_of(a->spec) : NULL;
    HV *paths = spec ? oa_hv_of(oa_get(aTHX_ spec, "paths")) : NULL;
    HE *he;
    STRLEN wl;
    const char *want;

    if (!paths || !op_id || !SvOK(op_id)) return NULL;
    want = SvPV_const(op_id, wl);

    hv_iterinit(paths);
    while ((he = hv_iternext(paths))) {
        I32 pl; const char *pk = hv_iterkey(he, &pl);
        HV *item = oa_hv_of(hv_iterval(paths, he));
        int m;
        if (!item) continue;
        for (m = 0; oa_methods[m]; m++) {
            HV *op = oa_hv_of(oa_get(aTHX_ item, oa_methods[m]));
            SV *oid;
            STRLEN ol;
            const char *ops;
            if (!op) continue;
            oid = oa_get(aTHX_ op, "operationId");
            if (!oid || !SvOK(oid)) continue;
            ops = SvPV_const(oid, ol);
            if (ol != wl || memNE(ops, want, wl)) continue;
            if (item_out)   *item_out   = item;
            if (path_out)   *path_out   = newSVpvn(pk, (STRLEN)pl);
            if (method_out) *method_out = oa_methods[m];
            return op;
        }
    }
    return NULL;
}

/* A parameter's schema: `schema`, or the JSON media type's schema when the
 * parameter was declared with `content` instead. Borrowed. */
static SV *oa_tools_param_schema(pTHX_ HV *p) {
    SV *s = oa_get(aTHX_ p, "schema");
    HV *content;
    HE *he;
    if (s && oa_hv_of(s)) return s;
    content = oa_hv_of(oa_get(aTHX_ p, "content"));
    if (!content) return NULL;
    hv_iterinit(content);
    while ((he = hv_iternext(content))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        HV *m = oa_hv_of(hv_iterval(content, he));
        SV *ms = m ? oa_get(aTHX_ m, "schema") : NULL;
        if (ms && oa_hv_of(ms) && oa_ctype_is_json(k, (STRLEN)kl)) return ms;
    }
    return NULL;
}

static SV *oa_tools_body_schema(pTHX_ HV *op) {
    HV *rb = oa_hv_of(oa_get(aTHX_ op, "requestBody"));
    HV *content = rb ? oa_hv_of(oa_get(aTHX_ rb, "content")) : NULL;
    HE *he;
    if (!content) return NULL;
    hv_iterinit(content);
    while ((he = hv_iternext(content))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        HV *m = oa_hv_of(hv_iterval(content, he));
        SV *ms = m ? oa_get(aTHX_ m, "schema") : NULL;
        if (ms && oa_hv_of(ms) && oa_ctype_is_json(k, (STRLEN)kl)) return ms;
    }
    return NULL;
}

/* ---- the two answers ------------------------------------------------------- */

/* What the document SAYS about an operation. NULL for an unknown id. */
static SV *oa_tools_doc(pTHX_ oa_api *a, SV *op_id) {
    HV *item = NULL, *op, *out;
    SV *path = NULL, *v;
    const char *method = NULL;
    HE *he;

    op = oa_tools_find_op(aTHX_ a, op_id, &item, &path, &method);
    if (!op) { if (path) SvREFCNT_dec(path); return NULL; }

    out = newHV();
    (void)hv_stores(out, "operationId", newSVsv(op_id));
    {
        SV *mu = newSVpv(method ? method : "", 0);
        char *s = SvPV_nolen(mu);
        STRLEN i, l = SvCUR(mu);
        for (i = 0; i < l; i++)
            if (s[i] >= 'a' && s[i] <= 'z') s[i] = (char)(s[i] - 'a' + 'A');
        (void)hv_stores(out, "method", mu);
    }
    (void)hv_stores(out, "path", path ? path : newSVpvs(""));

    v = oa_get(aTHX_ op, "summary");
    (void)hv_stores(out, "summary", v ? newSVsv(v) : newSVpvs(""));
    v = oa_get(aTHX_ op, "description");
    (void)hv_stores(out, "description", v ? newSVsv(v) : newSVpvs(""));
    v = oa_get(aTHX_ op, "tags");
    (void)hv_stores(out, "tags", v ? newSVsv(v) : newRV_noinc((SV *)newAV()));
    v = oa_get(aTHX_ op, "deprecated");
    (void)hv_stores(out, "deprecated", newSViv(v && SvTRUE(v) ? 1 : 0));

    /* Extensions ride along: they are how a document says something this
     * library has no opinion about. */
    hv_iterinit(op);
    while ((he = hv_iternext(op))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        if (kl > 2 && k[0] == 'x' && k[1] == '-')
            (void)hv_store(out, k, kl, newSVsv(hv_iterval(op, he)), 0);
    }

    return newRV_noinc((SV *)out);
}

/* Every input an operation declares, as one JSON Schema object.
 * NULL for an unknown id. */
static SV *oa_tools_schema(pTHX_ oa_api *a, SV *op_id) {
    HV *item = NULL, *op, *props, *out;
    AV *required;
    HV *merged[64];
    int nm = 0, i, src;
    SV *body;

    op = oa_tools_find_op(aTHX_ a, op_id, &item, NULL, NULL);
    if (!op) return NULL;

    /* Path-item parameters first, then the operation's own, an operation-level
     * one replacing a path-level one with the same (name, in). The same
     * precedence oa_compile_params applies - a description of the inputs that
     * disagreed with the validator about which inputs exist would be a
     * description nothing could act on. */
    for (src = 0; src < 2; src++) {
        HV *from = (src == 0) ? item : op;
        AV *list = from ? oa_av_of(oa_get(aTHX_ from, "parameters")) : NULL;
        SSize_t j, n;
        if (!list) continue;
        n = av_len(list) + 1;
        for (j = 0; j < n; j++) {
            SV **e = av_fetch(list, j, 0);
            HV *p = (e && *e) ? oa_hv_of(*e) : NULL;
            SV *pn, *pi;
            int k, hit = 0;
            if (!p) continue;
            pn = oa_get(aTHX_ p, "name");
            pi = oa_get(aTHX_ p, "in");
            if (!pn || !pi || !SvOK(pn) || !SvOK(pi)) continue;
            for (k = 0; k < nm; k++) {
                SV *qn = oa_get(aTHX_ merged[k], "name");
                SV *qi = oa_get(aTHX_ merged[k], "in");
                if (qn && qi && sv_eq(qn, pn) && sv_eq(qi, pi)) {
                    merged[k] = p; hit = 1; break;
                }
            }
            if (!hit && nm < 64) merged[nm++] = p;
        }
    }

    props    = newHV();
    required = newAV();

    for (i = 0; i < nm; i++) {
        HV *p = merged[i], *ps;
        SV *pn  = oa_get(aTHX_ p, "name");
        SV *sch = oa_tools_param_schema(aTHX_ p);
        SV *req = oa_get(aTHX_ p, "required");
        STRLEN nl;
        const char *nmp = SvPV_const(pn, nl);
        int clash = (nl == 4 && memEQ(nmp, "body", 4));
        const char *key = clash ? "param_body" : nmp;
        I32 keyl = clash ? 10 : (I32)nl;

        ps = (sch && oa_hv_of(sch)) ? oa_conv_copy_hv(aTHX_ oa_hv_of(sch)) : newHV();

        /* The prose lives on the parameter, not on its schema, and it is the
         * only thing telling two same-typed parameters apart. */
        if (!oa_get(aTHX_ ps, "description")) {
            SV *pd = oa_get(aTHX_ p, "description");
            if (pd && SvOK(pd)) (void)hv_stores(ps, "description", newSVsv(pd));
        }
        if (clash) {
            SV *d = oa_get(aTHX_ ps, "description");
            SV *t;
            if (d && SvOK(d)) { t = newSVsv(d); sv_catpvs(t, " (the `body` parameter)"); }
            else t = newSVpvs("the `body` parameter");
            (void)hv_stores(ps, "description", t);
        }

        (void)hv_store(props, key, keyl, newRV_noinc((SV *)ps), 0);
        if (req && SvTRUE(req)) av_push(required, newSVpvn(key, (STRLEN)keyl));
    }

    body = oa_tools_body_schema(aTHX_ op);
    if (body) {
        HV *rb = oa_hv_of(oa_get(aTHX_ op, "requestBody"));
        SV *rq = rb ? oa_get(aTHX_ rb, "required") : NULL;
        (void)hv_stores(props, "body", newSVsv(body));
        if (rq && SvTRUE(rq)) av_push(required, newSVpvs("body"));
    }

    out = newHV();
    (void)hv_stores(out, "type", newSVpvs("object"));
    {
        SV *pr = newRV_noinc((SV *)props);
        (void)hv_stores(out, "properties", oa_tools_rewrite(aTHX_ pr, 0));
        SvREFCNT_dec(pr);
    }
    if (av_len(required) >= 0)
        (void)hv_stores(out, "required", newRV_noinc((SV *)required));
    else
        SvREFCNT_dec((SV *)required);

    /* Carry only the component schemas this operation can actually reach. A
     * document with two hundred of them would otherwise put all two hundred
     * into every answer, and JSON::Schema::Fast throws on an unresolvable
     * $ref - so too little here is a loud failure, not a quiet one. */
    {
        HV *spec    = oa_hv_of(a->spec);
        HV *comp    = spec ? oa_hv_of(oa_get(aTHX_ spec, "components")) : NULL;
        HV *schemas = comp ? oa_hv_of(oa_get(aTHX_ comp, "schemas")) : NULL;
        if (schemas) {
            HV *want = newHV(), *defs = newHV();
            int added = 1;
            oa_tools_refs_in(aTHX_ oa_get(aTHX_ out, "properties"), want, 0);
            while (added) {
                HE *he;
                added = 0;
                hv_iterinit(want);
                while ((he = hv_iternext(want))) {
                    I32 kl; const char *k = hv_iterkey(he, &kl);
                    SV **s;
                    SV *rw;
                    if (hv_fetch(defs, k, kl, 0)) continue;
                    s  = hv_fetch(schemas, k, kl, 0);
                    /* A name that is not in components.schemas cannot be
                     * carried, and an EMPTY schema is not a safe stand-in: {}
                     * is valid JSON Schema that accepts ANYTHING, so the
                     * result compiled clean and then validated nothing. Refuse
                     * instead, which is the loud failure the comment above
                     * this block is relying on. */
                    if (!s || !*s)
                        croak("Open::API: operation_schema: $ref names '%.*s', "
                              "which is not in components.schemas",
                              (int)kl, k);
                    rw = oa_tools_rewrite(aTHX_ *s, 0);
                    (void)hv_store(defs, k, kl, rw, 0);
                    /* A schema can name others, so this widens `want` - which
                     * invalidates the iterator, hence one per pass. */
                    oa_tools_refs_in(aTHX_ rw, want, 0);
                    added = 1;
                    break;
                }
            }
            if (HvUSEDKEYS(defs)) (void)hv_stores(out, "$defs", newRV_noinc((SV *)defs));
            else                  SvREFCNT_dec((SV *)defs);
            SvREFCNT_dec((SV *)want);
        }
    }

    return newRV_noinc((SV *)out);
}

#endif /* OA_TOOLS_H */

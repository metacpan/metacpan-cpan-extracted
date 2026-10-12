#ifndef OA_SWAGGER2_H
#define OA_SWAGGER2_H

/* Swagger 2.0 -> OpenAPI 3.0 shape, at document level.
 *
 * A 2.0 Schema Object is a draft-04 subset of 3.0's, so the 3.0 pass in
 * oa_normalize.h already does the schema work (boolean exclusive bounds,
 * tuple items, example, byte/binary, $ref siblings, discriminator). This
 * pass does only what 2.0 spells DIFFERENTLY: the root (host, basePath,
 * schemes, the definition sections, consumes, produces, securityDefinitions),
 * the operation (body and formData parameters, response schema and
 * examples), the parameter (inline type keywords, Items, collectionFormat)
 * and three schema spellings ($ref prefixes, the string discriminator, the
 * type MUST). See plan_openapi_v2/00-overview.md for the field map.
 *
 * Contract, the same as oa_normalize's: the caller's document is never
 * mutated; a NEW root is returned and becomes the document the 3.0 pass
 * resolves against, so a `$ref` rewritten here to `#/components/...` is found
 * there. The output keeps `swagger: "2.0"`; every rule fires only on a 2.0
 * spelling, which the rule itself removes or converts, so running the pass
 * again over its own output changes nothing (D2 in the plan).
 *
 * Position-aware, like the 3.0 pass: the schema walk descends only where a
 * Schema Object can appear, because `default`, `example` and `enum` hold
 * user JSON that may itself carry a key spelled `$ref`.
 *
 * Built in phases: 03 the root (this file's first half: servers, the
 * sections, security schemes, the $ref table, a light walk of paths that
 * rewrites reference strings), 04 the operation, 05 the parameter and the
 * Items, 06 the schema. Where a later phase owns a conversion the earlier
 * one copies the object unchanged and says so. */

typedef struct oa_sw2 {
    HV *src;        /* the 2.0 document as loaded, never written          */
    HV *out;        /* the 3.0-shaped root being built                     */
    AV *consumes;   /* root consumes, borrowed from src, or NULL           */
    AV *produces;   /* root produces, borrowed from src, or NULL           */
    int has_host;   /* a server URL can be rendered for operation schemes */
    SV *host;       /* borrowed from src when has_host                    */
    SV *basepath;   /* borrowed from src, or NULL                          */
} oa_sw2;

#define OA_SW2_MAX_HOPS     8
#define OA_SW2_SCHEMA_DEPTH 64

/* ---- small helpers ----------------------------------------------------------- */

/* one level deep: keys duplicated, values shared through newSVsv (the same
 * shape as oa_conv_copy_hv, which is defined after this header is included) */
static HV *oa_sw2_copy_hv(pTHX_ HV *src) {
    HV *dst = newHV();
    HE *he;
    hv_iterinit(src);
    while ((he = hv_iternext(src))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        (void)hv_store(dst, k, kl, newSVsv(hv_iterval(src, he)), 0);
    }
    return dst;
}

static int oa_sw2_is_ext(const char *k, STRLEN kl) {
    return kl >= 2 && k[0] == 'x' && k[1] == '-';
}

/* `description` and every ^x- key of src onto dst: what a rebuilt object
 * keeps of the original beside the fields the rebuild knows about */
static void oa_sw2_copy_extras(pTHX_ HV *dst, HV *src) {
    HE *he;
    hv_iterinit(src);
    while ((he = hv_iternext(src))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        if (oa_sw2_is_ext(k, (STRLEN)kl)
            || (kl == 11 && memEQ(k, "description", 11)))
            (void)hv_store(dst, k, kl, newSVsv(hv_iterval(src, he)), 0);
    }
}

static int oa_sw2_has(const char *p, STRLEN l, const char *needle) {
    STRLEN nl = strlen(needle), i;
    if (l < nl) return 0;
    for (i = 0; i + nl <= l; i++)
        if (memEQ(p + i, needle, nl)) return 1;
    return 0;
}

static int oa_sw2_str_is(pTHX_ SV *sv, const char *want) {
    STRLEN l; const char *p;
    if (!sv || SvROK(sv) || !SvOK(sv)) return 0;
    p = SvPV_const(sv, l);
    return l == strlen(want) && memEQ(p, want, l);
}

/* RFC 6901: `~1` is `/`, `~0` is `~`. The caller owns the result. */
static SV *oa_sw2_unescape(pTHX_ const char *p, STRLEN l) {
    SV *out = newSVpvs("");
    STRLEN i;
    for (i = 0; i < l; i++) {
        if (p[i] == '~' && i + 1 < l && (p[i + 1] == '1' || p[i + 1] == '0')) {
            sv_catpvn(out, p[i + 1] == '1' ? "/" : "~", 1);
            i++;
            continue;
        }
        sv_catpvn(out, p + i, 1);
    }
    return out;
}

/* ---- rule 6: the pass's own dereference ------------------------------------- *
 *
 * The 3.0 normaliser resolves `#/components/...` against the document it is
 * handed, which is this pass's OUTPUT. This pass needs to read the SOURCE: a
 * use site of `#/parameters/X` becomes a request body, a form member or a
 * component parameter depending on the target's `in`, and only the raw 2.0
 * object says which. Draft-04 semantics: a Reference Object has no siblings,
 * so nothing beside the `$ref` is read. */

/* the raw object `#/<section>/<name>` names in the source, borrowed, or NULL
 * when the string is not such a reference or it names nothing */
static HV *oa_sw2_target(pTHX_ oa_sw2 *S, SV *ref, const char *section) {
    STRLEN l, secl = strlen(section), nl;
    const char *p, *nm;
    HV *bucket;
    SV **e, *name;
    if (!ref || SvROK(ref) || !SvOK(ref)) return NULL;
    p = SvPV_const(ref, l);
    if (l < secl + 4 || p[0] != '#' || p[1] != '/'
        || !memEQ(p + 2, section, secl) || p[2 + secl] != '/') return NULL;
    nm = p + 3 + secl;
    nl = l - 3 - secl;
    /* a deeper pointer addresses something inside the object, not the object */
    if (!nl || memchr(nm, '/', nl)) return NULL;
    bucket = oa_hv_of(oa_get(aTHX_ S->src, section));
    if (!bucket) return NULL;
    name = sv_2mortal(oa_sw2_unescape(aTHX_ nm, nl));
    e = hv_fetch(bucket, SvPVX(name), (I32)SvCUR(name), 0);
    return (e && *e) ? oa_hv_of(*e) : NULL;
}

/* the object a Reference Object (or a chain of them within one section)
 * finally names, borrowed; NULL when it cannot be followed, including a cycle
 * or a chain past OA_SW2_MAX_HOPS - the caller then leaves the reference as
 * it was, and the 3.0 pass refuses it by name rather than this pass hanging */
static HV *oa_sw2_deref(pTHX_ oa_sw2 *S, HV *obj, const char *section) {
    HV *cur = obj;
    int hops;
    for (hops = 0; hops < OA_SW2_MAX_HOPS; hops++) {
        SV *ref = oa_get(aTHX_ cur, "$ref");
        HV *t;
        if (!ref) return cur;
        t = oa_sw2_target(aTHX_ S, ref, section);
        if (!t || t == cur) return NULL;
        cur = t;
    }
    return NULL;
}

/* ---- rule 5: the $ref prefix table ------------------------------------------ *
 *
 * A reference string rewritten to its 3.0 home, as a new SV the caller owns.
 * `#/definitions/` and `#/responses/` move wholesale. `#/parameters/` depends
 * on the target: a component parameter moves to components.parameters; a BODY
 * definition is a request body and a FORMDATA one is inlined at its use site,
 * and both are the operation walk's business (phase 04), so their references
 * are returned unchanged here. A string this pass cannot place is also
 * returned unchanged, so the 3.0 pass refuses it loudly by name. JSON-pointer
 * escapes survive a prefix swap untouched. */
static SV *oa_sw2_ref(pTHX_ oa_sw2 *S, SV *ref) {
    static const struct { const char *from; const char *to; } tbl[] = {
        { "#/definitions/", "#/components/schemas/"   },
        { "#/responses/",   "#/components/responses/" },
        { NULL, NULL }
    };
    static const char pf[] = "#/parameters/";
    const STRLEN pfl = sizeof(pf) - 1;
    STRLEN l;
    const char *p;
    int i;
    if (!ref || SvROK(ref) || !SvOK(ref)) return newSVsv(ref);
    p = SvPV_const(ref, l);
    for (i = 0; tbl[i].from; i++) {
        STRLEN fl = strlen(tbl[i].from);
        if (l > fl && memEQ(p, tbl[i].from, fl)) {
            SV *out = newSVpv(tbl[i].to, 0);
            sv_catpvn(out, p + fl, l - fl);
            return out;
        }
    }
    if (l > pfl && memEQ(p, pf, pfl)) {
        HV *t = oa_sw2_target(aTHX_ S, ref, "parameters");
        HV *d = t ? oa_sw2_deref(aTHX_ S, t, "parameters") : NULL;
        if (d && !oa_sw2_str_is(aTHX_ oa_get(aTHX_ d, "in"), "body")
              && !oa_sw2_str_is(aTHX_ oa_get(aTHX_ d, "in"), "formData")) {
            SV *out = newSVpvs("#/components/parameters/");
            sv_catpvn(out, p + pfl, l - pfl);
            return out;
        }
    }
    return newSVsv(ref);
}

/* ---- the schema walk --------------------------------------------------------- *
 *
 * Position-aware: descends only where a Schema Object can appear, through the
 * keyword tables oa_compile.h shares with the 3.0 pass. Phase 03: the `$ref`
 * rewrite only. Phase 06 adds the string discriminator, the type MUST and the
 * nullable drop; everything else about a schema is the 3.0 pass's. */

static SV *oa_sw2_schema(pTHX_ oa_sw2 *S, SV *schema, int depth);

static SV *oa_sw2_schema_list(pTHX_ oa_sw2 *S, SV *list, int depth) {
    AV *src = oa_av_of(list), *dst;
    I32 i, n;
    if (!src) return newSVsv(list);
    dst = newAV();
    n = av_len(src);
    for (i = 0; i <= n; i++) {
        SV **e = av_fetch(src, i, 0);
        av_push(dst, (e && *e) ? oa_sw2_schema(aTHX_ S, *e, depth) : newSV(0));
    }
    return newRV_noinc((SV *)dst);
}

static SV *oa_sw2_schema_map(pTHX_ oa_sw2 *S, SV *map, int depth) {
    HV *src = oa_hv_of(map), *dst;
    HE *he;
    if (!src) return newSVsv(map);
    dst = newHV();
    hv_iterinit(src);
    while ((he = hv_iternext(src))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        (void)hv_store(dst, k, kl, oa_sw2_schema(aTHX_ S, hv_iterval(src, he), depth), 0);
    }
    return newRV_noinc((SV *)dst);
}

/* The string discriminator (phase 06). 2.0: "The property name used MUST be
 * defined at this schema and it MUST be in the required property list." Both
 * are checked on THIS schema, then the string becomes the 3.0 object form the
 * 3.0 pass expands (inheritance through the children's allOf $ref back to the
 * base, exactly as for a 3.x document). The object form is left alone, which
 * is what a converted document fed back through new() carries. */
static SV *oa_sw2_discriminator(pTHX_ HV *schema, SV *disc) {
    HV *props = oa_hv_of(oa_get(aTHX_ schema, "properties")), *out;
    AV *req   = oa_av_of(oa_get(aTHX_ schema, "required"));
    STRLEN dl; const char *dp;
    int found = 0;
    I32 i, n;
    if (SvROK(disc)) return newSVsv(disc);
    dp = SvPV_const(disc, dl);
    if (!props || !hv_exists(props, dp, (I32)dl))
        croak("Open::API: discriminator property '%.*s' is not defined at this "
              "schema (it MUST be)", (int)dl, dp);
    if (req) {
        n = av_len(req);
        for (i = 0; i <= n && !found; i++) {
            SV **e = av_fetch(req, i, 0);
            STRLEN el; const char *ep;
            if (!e || !*e || SvROK(*e)) continue;
            ep = SvPV_const(*e, el);
            if (el == dl && memEQ(ep, dp, dl)) found = 1;
        }
    }
    if (!found)
        croak("Open::API: discriminator property '%.*s' is not in the required "
              "property list (it MUST be)", (int)dl, dp);
    out = newHV();
    (void)hv_stores(out, "propertyName", newSVpvn(dp, dl));
    return newRV_noinc((SV *)out);
}

static SV *oa_sw2_schema(pTHX_ oa_sw2 *S, SV *schema, int depth) {
    HV *src = oa_hv_of(schema), *dst;
    HE *he;
    if (!src) return newSVsv(schema);        /* a boolean, or not a schema */
    if (depth > OA_SW2_SCHEMA_DEPTH)
        croak("Open::API: schema nesting deeper than %d", OA_SW2_SCHEMA_DEPTH);
    dst = newHV();
    hv_iterinit(src);
    while ((he = hv_iternext(src))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        SV *v = hv_iterval(src, he), *nv;
        /* "type: Value MUST be a string. Multiple types via an array are not
         * supported." Nothing in this pipeline makes a type array for a 2.0
         * document once `nullable` is dropped below, so the refusal survives a
         * second pass. */
        if (kl == 4 && memEQ(k, "type", 4) && oa_av_of(v))
            croak("Open::API: Swagger 2.0 schema: type must be a string, not an "
                  "array of types");
        /* not a 2.0 keyword; draft-04 ignores what it does not know. Left in,
         * the 3.0 pass would consume it into a type union and the second pass
         * would refuse this build's own output under the rule above. */
        if (kl == 8 && memEQ(k, "nullable", 8)) continue;
        if (kl == 4 && memEQ(k, "$ref", 4))
            nv = oa_sw2_ref(aTHX_ S, v);
        else if (kl == 13 && memEQ(k, "discriminator", 13))
            nv = oa_sw2_discriminator(aTHX_ src, v);
        else if (kl == 5 && memEQ(k, "items", 5))
            nv = oa_av_of(v) ? oa_sw2_schema_list(aTHX_ S, v, depth + 1)
                             : oa_sw2_schema(aTHX_ S, v, depth + 1);
        else if (oa_kw_schema(k, (STRLEN)kl))
            nv = oa_sw2_schema(aTHX_ S, v, depth + 1);
        else if (oa_kw_schema_map(k, (STRLEN)kl))
            nv = oa_sw2_schema_map(aTHX_ S, v, depth + 1);
        else if (oa_kw_schema_list(k, (STRLEN)kl))
            nv = oa_sw2_schema_list(aTHX_ S, v, depth + 1);
        else
            nv = newSVsv(v);                 /* default, example, enum, x-: user data */
        (void)hv_store(dst, k, kl, nv, 0);
    }
    return newRV_noinc((SV *)dst);
}

/* ---- rule 2: host, basePath, schemes -> servers ------------------------------ */

static int oa_sw2_scheme_ok(const char *s, STRLEN l) {
    return (l == 4 && memEQ(s, "http", 4))  || (l == 5 && memEQ(s, "https", 5))
        || (l == 2 && memEQ(s, "ws", 2))    || (l == 3 && memEQ(s, "wss", 3));
}

static void oa_sw2_push_server(pTHX_ AV *servers, SV *url) {
    HV *s = newHV();
    (void)hv_stores(s, "url", url);
    av_push(servers, newRV_noinc((SV *)s));
}

/* One server per scheme, `scheme://host/basePath`. A host with no schemes is
 * scheme-relative, `//host/basePath` ("the one used to access the Swagger
 * definition itself"). A basePath alone is a relative URL. Nothing at all
 * invents no servers. The MUSTs are checked by presence, so a converted
 * document fed back through new() (which has none of the three) is untouched. */
static void oa_sw2_servers(pTHX_ oa_sw2 *S) {
    SV *host = oa_get(aTHX_ S->src, "host");
    SV *bp   = oa_get(aTHX_ S->src, "basePath");
    SV *sch  = oa_get(aTHX_ S->src, "schemes");
    AV *schemes = sch ? oa_av_of(sch) : NULL;
    STRLEN hl = 0, bl = 0;
    const char *hp = NULL, *bpp = NULL;
    AV *servers;
    I32 i, n;

    if (host) {
        if (SvROK(host)) croak("Open::API: host must be a string");
        hp = SvPV_const(host, hl);
        if (oa_sw2_has(hp, hl, "://"))
            croak("Open::API: host '%.*s' must be the host only, without a scheme",
                  (int)hl, hp);
        if (!hl || memchr(hp, '/', hl))
            croak("Open::API: host '%.*s' must be the host only, without a path",
                  (int)hl, hp);
        S->has_host = 1;
        S->host     = host;
    }
    if (bp) {
        if (SvROK(bp)) croak("Open::API: basePath must be a string");
        S->basepath = bp;
        bpp = SvPV_const(bp, bl);
        if (!bl || bpp[0] != '/')
            croak("Open::API: basePath '%.*s' must start with a leading slash",
                  (int)bl, bpp);
    }
    if (sch) {
        if (!schemes) croak("Open::API: schemes must be a list");
        n = av_len(schemes);
        for (i = 0; i <= n; i++) {
            SV **e = av_fetch(schemes, i, 0);
            STRLEN sl; const char *sp;
            if (!e || !*e || SvROK(*e) || !SvOK(*e))
                croak("Open::API: schemes: a scheme must be a string");
            sp = SvPV_const(*e, sl);
            if (!oa_sw2_scheme_ok(sp, sl))
                croak("Open::API: schemes value '%.*s' is not one of http, "
                      "https, ws, wss", (int)sl, sp);
        }
    }
    if (!host && !bp) return;

    servers = newAV();
    (void)hv_stores(S->out, "servers", newRV_noinc((SV *)servers));
    if (host) {
        if (schemes && av_len(schemes) >= 0) {
            n = av_len(schemes);
            for (i = 0; i <= n; i++) {
                SV **e = av_fetch(schemes, i, 0);
                SV *url = newSVsv(*e);
                sv_catpvs(url, "://");
                sv_catpvn(url, hp, hl);
                if (bp) sv_catpvn(url, bpp, bl);
                oa_sw2_push_server(aTHX_ servers, url);
            }
        } else {
            SV *url = newSVpvs("//");
            sv_catpvn(url, hp, hl);
            if (bp) sv_catpvn(url, bpp, bl);
            oa_sw2_push_server(aTHX_ servers, url);
        }
    } else {
        oa_sw2_push_server(aTHX_ servers, newSVpvn(bpp, bl));
    }
}

/* ---- rule 3: consumes and produces ------------------------------------------- */

/* the list, borrowed, with every entry checked to be a media type ("Value
 * MUST be as described under Mime Types": type/subtype); NULL when absent */
static AV *oa_sw2_mimes(pTHX_ SV *list, const char *what) {
    AV *av;
    I32 i, n;
    if (!list) return NULL;
    av = oa_av_of(list);
    if (!av) croak("Open::API: %s must be a list of media types", what);
    n = av_len(av);
    for (i = 0; i <= n; i++) {
        SV **e = av_fetch(av, i, 0);
        STRLEN l; const char *p, *sl;
        if (!e || !*e || SvROK(*e) || !SvOK(*e))
            croak("Open::API: %s: a media type must be a string", what);
        p  = SvPV_const(*e, l);
        sl = l ? (const char *)memchr(p, '/', l) : NULL;
        if (!sl || sl == p || sl == p + l - 1)
            croak("Open::API: %s: '%.*s' is not a media type (type/subtype)",
                  what, (int)l, p);
    }
    return av;
}

/* ---- rule 9: securityDefinitions -> components.securitySchemes --------------- *
 *
 * Every 2.0 MUST about a scheme is checked HERE, because the compiler reads
 * the converted shape: a `basic` it would refuse as an unknown type, a cookie
 * apiKey it would accept, a missing `flow` it could not see. The croak names
 * the field it is about, which the catalogue requires of it. */
static SV *oa_sw2_scheme(pTHX_ oa_sw2 *S, const char *name, I32 nl, SV *sv) {
    HV *h = oa_hv_of(sv), *out;
    SV *tv;
    STRLEN tl; const char *tp;
    PERL_UNUSED_ARG(S);
    if (!h)
        croak("Open::API: securityDefinitions '%.*s' is not an object", (int)nl, name);
    tv = oa_get(aTHX_ h, "type");
    if (!tv || SvROK(tv))
        croak("Open::API: securityDefinitions '%.*s' has no 'type' (it is required)",
              (int)nl, name);
    tp  = SvPV_const(tv, tl);
    out = newHV();
    sv_2mortal((SV *)out);                   /* the checks below croak */
    if (tl == 5 && memEQ(tp, "basic", 5)) {
        (void)hv_stores(out, "type",   newSVpvs("http"));
        (void)hv_stores(out, "scheme", newSVpvs("basic"));
    }
    else if (tl == 6 && memEQ(tp, "apiKey", 6)) {
        SV *nm = oa_get(aTHX_ h, "name"), *in = oa_get(aTHX_ h, "in");
        if (!nm)
            croak("Open::API: securityDefinitions '%.*s': apiKey has no 'name' "
                  "(it is required)", (int)nl, name);
        if (!in || SvROK(in))
            croak("Open::API: securityDefinitions '%.*s': apiKey has no 'in' "
                  "(it is required)", (int)nl, name);
        if (!oa_sw2_str_is(aTHX_ in, "query") && !oa_sw2_str_is(aTHX_ in, "header")) {
            STRLEN il; const char *ip = SvPV_const(in, il);
            croak("Open::API: securityDefinitions '%.*s': apiKey 'in' must be "
                  "query or header (got %.*s)", (int)nl, name, (int)il, ip);
        }
        (void)hv_stores(out, "type", newSVpvs("apiKey"));
        (void)hv_stores(out, "name", newSVsv(nm));
        (void)hv_stores(out, "in",   newSVsv(in));
    }
    else if (tl == 6 && memEQ(tp, "oauth2", 6)) {
        SV *flow = oa_get(aTHX_ h, "flow"), *scopes = oa_get(aTHX_ h, "scopes");
        SV *au = oa_get(aTHX_ h, "authorizationUrl"), *tu = oa_get(aTHX_ h, "tokenUrl");
        STRLEN fl; const char *fp;
        const char *dest;
        int wants_auth, wants_token;
        HV *flows, *f;
        if (!flow || SvROK(flow))
            croak("Open::API: securityDefinitions '%.*s': oauth2 has no 'flow' "
                  "(it is required)", (int)nl, name);
        fp = SvPV_const(flow, fl);
        if      (fl ==  8 && memEQ(fp, "implicit",    8)) { dest = "implicit";          wants_auth = 1; wants_token = 0; }
        else if (fl ==  8 && memEQ(fp, "password",    8)) { dest = "password";          wants_auth = 0; wants_token = 1; }
        else if (fl == 11 && memEQ(fp, "application", 11)) { dest = "clientCredentials"; wants_auth = 0; wants_token = 1; }
        else if (fl == 10 && memEQ(fp, "accessCode",  10)) { dest = "authorizationCode"; wants_auth = 1; wants_token = 1; }
        else
            croak("Open::API: securityDefinitions '%.*s': oauth2 flow '%.*s' is not "
                  "one of implicit, password, application or accessCode",
                  (int)nl, name, (int)fl, fp);
        if (!scopes || !oa_hv_of(scopes))
            croak("Open::API: securityDefinitions '%.*s': oauth2 has no 'scopes' "
                  "(it is required)", (int)nl, name);
        if (wants_auth && !au)
            croak("Open::API: securityDefinitions '%.*s': oauth2 flow '%.*s' has no "
                  "'authorizationUrl' (it is required)", (int)nl, name, (int)fl, fp);
        if (wants_token && !tu)
            croak("Open::API: securityDefinitions '%.*s': oauth2 flow '%.*s' has no "
                  "'tokenUrl' (it is required)", (int)nl, name, (int)fl, fp);
        f = newHV();
        if (au) (void)hv_stores(f, "authorizationUrl", newSVsv(au));
        if (tu) (void)hv_stores(f, "tokenUrl",         newSVsv(tu));
        (void)hv_stores(f, "scopes", newSVsv(scopes));
        flows = newHV();
        (void)hv_store(flows, dest, (I32)strlen(dest), newRV_noinc((SV *)f), 0);
        (void)hv_stores(out, "type",  newSVpvs("oauth2"));
        (void)hv_stores(out, "flows", newRV_noinc((SV *)flows));
    }
    else
        croak("Open::API: securityDefinitions '%.*s': type '%.*s' is not basic, "
              "apiKey or oauth2", (int)nl, name, (int)tl, tp);
    oa_sw2_copy_extras(aTHX_ out, h);
    return newRV_inc((SV *)out);
}

/* ---- shared builders for rules 4, 5, 8 and 10 --------------------------------- */

/* `{<each media type>: {schema}}`: the schema under every type in `types`, or
 * under `dflt` when the list is NULL or empty (D4: a body with no consumes
 * anywhere is JSON, a response with no produces likewise). `conv` is owned by
 * the caller and handed over here. */
static SV *oa_sw2_content(pTHX_ SV *conv, AV *types, const char *dflt) {
    HV *content = newHV();
    I32 i, n;
    if (types && (n = av_len(types)) >= 0) {
        for (i = 0; i <= n; i++) {
            SV **e = av_fetch(types, i, 0);
            HV *mt = newHV();
            STRLEN cl; const char *cp = SvPV_const(*e, cl);
            (void)hv_stores(mt, "schema", i == n ? conv : newSVsv(conv));
            (void)hv_store(content, cp, (I32)cl, newRV_noinc((SV *)mt), 0);
        }
    } else {
        HV *mt = newHV();
        (void)hv_stores(mt, "schema", conv);
        (void)hv_store(content, dflt, (I32)strlen(dflt), newRV_noinc((SV *)mt), 0);
    }
    return newRV_noinc((SV *)content);
}

/* the operation's own list when the key is PRESENT (an empty list "MAY be used
 * to clear the global definition" and then falls to the default, not to the
 * root), else the root's; NULL means the default */
static AV *oa_sw2_effective(pTHX_ oa_sw2 *S, HV *op, const char *key, AV *root) {
    SV **e = op ? hv_fetch(op, key, (I32)strlen(key), 0) : NULL;
    AV *av;
    PERL_UNUSED_ARG(S);
    if (!e || !*e || !SvOK(*e)) return root;
    av = oa_sw2_mimes(aTHX_ *e, key);
    return (av && av_len(av) >= 0) ? av : NULL;
}

/* The inline type of a Parameter, Items or Header Object as a Schema Object:
 * the draft-04 keywords 2.0 lists travel as they are, `type: file` becomes a
 * binary string (the 3.0 pass then adds contentMediaType), and a nested Items
 * Object recurses with its own collectionFormat carried as the
 * x-oa-collectionFormat extension for the compiler to read (D5). `depth` is
 * the Items nesting: 0 is the parameter itself, 4 the deepest accepted. */
static const char *const oa_sw2_type_kws[] = {
    "type", "format", "default", "enum", "maximum", "exclusiveMaximum",
    "minimum", "exclusiveMinimum", "maxLength", "minLength", "pattern",
    "maxItems", "minItems", "uniqueItems", "multipleOf", NULL
};

static SV *oa_sw2_type_schema(pTHX_ oa_sw2 *S, HV *p, int depth, const char *where) {
    HV *out;
    SV *v, *type;
    int i;
    if (depth > 4)
        croak("Open::API: %s: array items nested deeper than 4 levels", where);
    type = oa_get(aTHX_ p, "type");
    if (depth > 0) {
        if (!type)
            croak("Open::API: %s: items has no 'type' (it is required)", where);
        if (oa_sw2_str_is(aTHX_ type, "file"))
            croak("Open::API: %s: items of type file: \"Files and models are not "
                  "allowed\"", where);
    }
    out = newHV();
    sv_2mortal((SV *)out);
    for (i = 0; oa_sw2_type_kws[i]; i++)
        if ((v = oa_get(aTHX_ p, oa_sw2_type_kws[i])))
            (void)hv_store(out, oa_sw2_type_kws[i], (I32)strlen(oa_sw2_type_kws[i]),
                           newSVsv(v), 0);
    if (oa_sw2_str_is(aTHX_ type, "file")) {
        (void)hv_stores(out, "type",   newSVpvs("string"));
        (void)hv_stores(out, "format", newSVpvs("binary"));
    }
    if ((v = oa_get(aTHX_ p, "items"))) {
        HV *ih = oa_hv_of(v);
        if (!ih) croak("Open::API: %s: items must be an object", where);
        (void)hv_stores(out, "items", oa_sw2_type_schema(aTHX_ S, ih, depth + 1, where));
    } else if (oa_sw2_str_is(aTHX_ type, "array")) {
        croak("Open::API: %s: type array has no 'items' (it is required)", where);
    }
    if (depth > 0 && (v = oa_get(aTHX_ p, "collectionFormat"))) {
        if (oa_sw2_str_is(aTHX_ v, "multi"))
            croak("Open::API: %s: collectionFormat multi is not a value of an "
                  "Items Object", where);
        (void)hv_stores(out, "x-oa-collectionFormat", newSVsv(v));
    }
    {   /* an Items Object's extensions */
        HE *he;
        hv_iterinit(p);
        while ((he = hv_iternext(p))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            if (depth > 0 && oa_sw2_is_ext(k, (STRLEN)kl))
                (void)hv_store(out, k, kl, newSVsv(hv_iterval(p, he)), 0);
        }
    }
    return newRV_inc((SV *)out);
}

/* ---- rule 10: a Header Object -> a 3.x header carrying a schema -------------- */
static SV *oa_sw2_header(pTHX_ oa_sw2 *S, SV *hsv, const char *name, const char *where) {
    HV *h = oa_hv_of(hsv), *out;
    SV *type, *cf;
    if (!h) return newSVsv(hsv);
    /* already 3.x-shaped: a converted document fed back through new() */
    if (oa_get(aTHX_ h, "schema") || oa_get(aTHX_ h, "$ref")) return newSVsv(hsv);
    type = oa_get(aTHX_ h, "type");
    if (!type)
        croak("Open::API: %s: header '%s' has no 'type' (it is required)", where, name);
    if (oa_sw2_str_is(aTHX_ type, "file"))
        croak("Open::API: %s: header '%s': type file is not a header type", where, name);
    out = newHV();
    sv_2mortal((SV *)out);
    (void)hv_stores(out, "schema", oa_sw2_type_schema(aTHX_ S, h, 0, where));
    if ((cf = oa_get(aTHX_ h, "collectionFormat"))) {
        if (oa_sw2_str_is(aTHX_ cf, "multi"))
            croak("Open::API: %s: header '%s': collectionFormat multi is valid "
                  "only for parameters in query or formData", where, name);
        /* a 3.x header is simple (comma) and nothing else; the other three
         * delimiters travel as the extension the compiler reads (05) */
        if (!oa_sw2_str_is(aTHX_ cf, "csv"))
            (void)hv_stores(out, "x-oa-collectionFormat", newSVsv(cf));
    }
    oa_sw2_copy_extras(aTHX_ out, h);
    return newRV_inc((SV *)out);
}

/* ---- rules 8, 9, 10: a Response Object -------------------------------------- *
 *
 * `schema` becomes `content[<each produces type>].schema` (a root `type: file`
 * is a binary string), `examples` {mime: value} becomes `content[mime].example`,
 * each Header Object gets a schema. A `$ref` response is rewritten and left for
 * the 3.0 pass to inline. By presence: a converted response has none of the
 * three 2.0 spellings. */
static SV *oa_sw2_response(pTHX_ oa_sw2 *S, SV *r, AV *produces, const char *where) {
    HV *h = oa_hv_of(r), *out;
    SV *v, *ref;
    if (!h) return newSVsv(r);
    out = oa_sw2_copy_hv(aTHX_ h);
    sv_2mortal((SV *)out);
    if ((ref = oa_get(aTHX_ h, "$ref"))) {
        (void)hv_stores(out, "$ref", oa_sw2_ref(aTHX_ S, ref));
        return newRV_inc((SV *)out);
    }
    if ((v = oa_get(aTHX_ h, "schema"))) {
        HV *sh = oa_hv_of(v);
        SV *conv;
        if (sh && oa_sw2_str_is(aTHX_ oa_get(aTHX_ sh, "type"), "file")) {
            HV *bin = newHV();
            (void)hv_stores(bin, "type",   newSVpvs("string"));
            (void)hv_stores(bin, "format", newSVpvs("binary"));
            oa_sw2_copy_extras(aTHX_ bin, sh);
            conv = newRV_noinc((SV *)bin);
        } else {
            conv = oa_sw2_schema(aTHX_ S, v, 0);
        }
        (void)hv_stores(out, "content", oa_sw2_content(aTHX_ conv, produces, "application/json"));
        (void)hv_delete(out, "schema", 6, G_DISCARD);
    }
    if ((v = oa_get(aTHX_ h, "examples"))) {
        HV *ex = oa_hv_of(v), *content;
        HE *he;
        if (!ex) croak("Open::API: %s: examples must be an object keyed by media type", where);
        content = oa_hv_of(oa_get(aTHX_ out, "content"));
        if (!content) {
            content = newHV();
            (void)hv_stores(out, "content", newRV_noinc((SV *)content));
        }
        hv_iterinit(ex);
        while ((he = hv_iternext(ex))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            SV **mte = hv_fetch(content, k, kl, 0);
            HV *mt = (mte && *mte) ? oa_hv_of(*mte) : NULL;
            if (!mt) {
                mt = newHV();
                (void)hv_store(content, k, kl, newRV_noinc((SV *)mt), 0);
            }
            (void)hv_stores(mt, "example", newSVsv(hv_iterval(ex, he)));
        }
        (void)hv_delete(out, "examples", 8, G_DISCARD);
    }
    if ((v = oa_get(aTHX_ h, "headers"))) {
        HV *hs = oa_hv_of(v);
        if (hs) {
            HV *nh = newHV();
            HE *he;
            (void)hv_stores(out, "headers", newRV_noinc((SV *)nh));
            hv_iterinit(hs);
            while ((he = hv_iternext(hs))) {
                I32 kl; const char *k = hv_iterkey(he, &kl);
                SV *name = sv_2mortal(newSVpvn(k, (STRLEN)kl));
                (void)hv_store(nh, k, kl,
                               oa_sw2_header(aTHX_ S, hv_iterval(hs, he), SvPVX(name), where), 0);
            }
        }
    }
    return newRV_inc((SV *)out);
}

/* ---- rules 7 and 8: the definition sections ---------------------------------- */

/* a body parameter definition as a Request Body Object: `required`,
 * `description`, the schema under every root consumes type (D4's default when
 * there are none), and the parameter's extensions; `name` is informational in
 * 2.0 and dropped */
static SV *oa_sw2_body_def(pTHX_ oa_sw2 *S, HV *p, const char *name, I32 nl) {
    HV *out;
    SV *schema = oa_get(aTHX_ p, "schema"), *req = oa_get(aTHX_ p, "required");
    if (!schema)
        croak("Open::API: parameters '%.*s': a body parameter has no 'schema' "
              "(it is required)", (int)nl, name);
    out = newHV();
    if (req) (void)hv_stores(out, "required", newSVsv(req));
    (void)hv_stores(out, "content",
                    oa_sw2_content(aTHX_ oa_sw2_schema(aTHX_ S, schema, 0),
                                   S->consumes, "application/json"));
    oa_sw2_copy_extras(aTHX_ out, p);
    return newRV_noinc((SV *)out);
}

/* ---- phase 05: a non-body Parameter Object ----------------------------------- *
 *
 * The inline type keywords become `schema` (oa_sw2_type_schema), and
 * collectionFormat becomes what 3.x can spell for the location, or the
 * x-oa-collectionFormat extension where it cannot (D5). THE CATCH: 2.0's
 * default for an array is csv, which is NOT exploded, while 3.x's default for
 * a query parameter is form WITH explode, the reverse - so csv on a query
 * array is written out as `style: form, explode: false`, and only multi gets
 * explode true. In a path or header, csv IS the default (simple), and ssv,
 * tsv and pipes have no 3.x style at all, so they travel as the extension. */
static void oa_sw2_collection(pTHX_ HV *out, SV *cf, const char *in, int is_array,
                              const char *where) {
    const char *fmt = "csv";
    STRLEN fl = 3;
    int query = strEQ(in, "query");
    if (cf) {
        if (SvROK(cf)) croak("Open::API: parameter '%s': collectionFormat must be a string", where);
        fmt = SvPV_const(cf, fl);
    }
    /* "Determines the format of the array if type array is used": on a
     * scalar it says nothing, and nothing is written */
    if (!is_array) return;
#define OA_SW2_FMT(s) (fl == sizeof(s) - 1 && memEQ(fmt, s, fl))
    if (OA_SW2_FMT("multi")) {
        if (!query)
            croak("Open::API: parameter '%s': collectionFormat multi is valid only for "
                  "parameters in query or formData", where);
        (void)hv_stores(out, "style",   newSVpvs("form"));
        (void)hv_stores(out, "explode", newRV_noinc(newSViv(1)));
    } else if (OA_SW2_FMT("csv")) {
        if (query) {
            (void)hv_stores(out, "style",   newSVpvs("form"));
            (void)hv_stores(out, "explode", newRV_noinc(newSViv(0)));
        }
    } else if (OA_SW2_FMT("ssv")) {
        if (query) (void)hv_stores(out, "style", newSVpvs("spaceDelimited"));
        else       (void)hv_stores(out, "x-oa-collectionFormat", newSVpvs("ssv"));
    } else if (OA_SW2_FMT("pipes")) {
        if (query) (void)hv_stores(out, "style", newSVpvs("pipeDelimited"));
        else       (void)hv_stores(out, "x-oa-collectionFormat", newSVpvs("pipes"));
    } else if (OA_SW2_FMT("tsv")) {
        if (query) {
            (void)hv_stores(out, "style",   newSVpvs("form"));
            (void)hv_stores(out, "explode", newRV_noinc(newSViv(0)));
        }
        (void)hv_stores(out, "x-oa-collectionFormat", newSVpvs("tsv"));
    } else {
        croak("Open::API: parameter '%s': collectionFormat '%.*s' is not csv, ssv, tsv, "
              "pipes or multi", where, (int)fl, fmt);
    }
#undef OA_SW2_FMT
}

/* the keys oa_sw2_type_schema moves into the schema, plus the two the
 * conversion consumes; everything else on the parameter stays */
static int oa_sw2_param_moved(const char *k, STRLEN kl) {
    int i;
    for (i = 0; oa_sw2_type_kws[i]; i++)
        if (strlen(oa_sw2_type_kws[i]) == kl && memEQ(k, oa_sw2_type_kws[i], kl)) return 1;
    return (kl == 5 && memEQ(k, "items", 5)) || (kl == 16 && memEQ(k, "collectionFormat", 16));
}

static SV *oa_sw2_param_def(pTHX_ oa_sw2 *S, HV *p) {
    SV *type = oa_get(aTHX_ p, "type"), *schema = oa_get(aTHX_ p, "schema");
    SV *in = oa_get(aTHX_ p, "in"), *name = oa_get(aTHX_ p, "name");
    const char *where = name && !SvROK(name) ? SvPV_nolen(name) : "(unnamed)";
    const char *inp;
    HV *out;
    HE *he;
    int is_path, is_query, is_header;

    /* a definition that is itself a Reference Object (not legal 2.0, which
     * maps a name to a Parameter Object, but harmless): the string is
     * rewritten and the 3.0 pass follows it, bounded, and refuses a cycle */
    if (oa_get(aTHX_ p, "$ref")) {
        out = oa_sw2_copy_hv(aTHX_ p);
        (void)hv_stores(out, "$ref", oa_sw2_ref(aTHX_ S, oa_get(aTHX_ p, "$ref")));
        return newRV_noinc((SV *)out);
    }
    /* already 3.x-shaped (a converted document fed back, or an author who
     * wrote `schema`): copied, with the schema walked for its $refs. "type:
     * Required" is phrased so that shape survives: a parameter with neither
     * type nor schema nor content is the one refused. */
    if (!type || schema) {
        if (!type && !schema && !oa_get(aTHX_ p, "content"))
            croak("Open::API: parameter '%s' has no 'type' (it is required)", where);
        out = oa_sw2_copy_hv(aTHX_ p);
        if (schema) (void)hv_stores(out, "schema", oa_sw2_schema(aTHX_ S, schema, 0));
        return newRV_noinc((SV *)out);
    }
    if (!in || SvROK(in))
        croak("Open::API: parameter '%s' has no 'in' (it is required)", where);
    inp = SvPV_nolen(in);
    is_path = strEQ(inp, "path"); is_query = strEQ(inp, "query"); is_header = strEQ(inp, "header");
    if (!is_path && !is_query && !is_header)
        croak("Open::API: parameter '%s': in '%s' is not one of query, header, path, "
              "formData or body", where, inp);
    if (oa_sw2_str_is(aTHX_ type, "file"))
        croak("Open::API: parameter '%s': type file: \"the parameter MUST be in formData\"",
              where);
    if (is_path && !oa_sv_truthy(aTHX_ oa_get(aTHX_ p, "required")))
        croak("Open::API: path parameter '%s' must have required: true", where);

    out = newHV();
    sv_2mortal((SV *)out);
    hv_iterinit(p);
    while ((he = hv_iternext(p))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        if (oa_sw2_param_moved(k, (STRLEN)kl)) continue;
        (void)hv_store(out, k, kl, newSVsv(hv_iterval(p, he)), 0);
    }
    (void)hv_stores(out, "schema", oa_sw2_type_schema(aTHX_ S, p, 0, where));
    oa_sw2_collection(aTHX_ out, oa_get(aTHX_ p, "collectionFormat"), inp,
                      oa_sw2_str_is(aTHX_ type, "array"), where);
    return newRV_inc((SV *)out);
}

static void oa_sw2_components(pTHX_ oa_sw2 *S) {
    SV *existing = oa_get(aTHX_ S->out, "components");
    HV *comp = oa_hv_of(existing) ? oa_sw2_copy_hv(aTHX_ oa_hv_of(existing)) : newHV();
    HV *defs, *ps, *rs, *sd;
    HE *he;
    (void)hv_stores(S->out, "components", newRV_noinc((SV *)comp));

    if ((defs = oa_hv_of(oa_get(aTHX_ S->src, "definitions")))) {
        HV *schemas = newHV();
        (void)hv_stores(comp, "schemas", newRV_noinc((SV *)schemas));
        hv_iterinit(defs);
        while ((he = hv_iternext(defs))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            (void)hv_store(schemas, k, kl, oa_sw2_schema(aTHX_ S, hv_iterval(defs, he), 0), 0);
        }
    }
    if ((ps = oa_hv_of(oa_get(aTHX_ S->src, "parameters")))) {
        HV *params = newHV(), *bodies = newHV();
        (void)hv_stores(comp, "parameters",    newRV_noinc((SV *)params));
        (void)hv_stores(comp, "requestBodies", newRV_noinc((SV *)bodies));
        hv_iterinit(ps);
        while ((he = hv_iternext(ps))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            HV *p = oa_hv_of(hv_iterval(ps, he));
            SV *in;
            if (!p) croak("Open::API: parameters '%.*s' is not an object", (int)kl, k);
            in = oa_get(aTHX_ p, "in");
            if (oa_sw2_str_is(aTHX_ in, "body"))
                (void)hv_store(bodies, k, kl, oa_sw2_body_def(aTHX_ S, p, k, kl), 0);
            else if (oa_sw2_str_is(aTHX_ in, "formData"))
                /* several form members make ONE body, so no component can
                 * stand for one of them: it is inlined at every use (04)
                 * and a definition nothing references is dead */
                continue;
            else
                (void)hv_store(params, k, kl, oa_sw2_param_def(aTHX_ S, p), 0);
        }
        if (!HvUSEDKEYS(params)) (void)hv_delete(comp, "parameters", 10, G_DISCARD);
        if (!HvUSEDKEYS(bodies)) (void)hv_delete(comp, "requestBodies", 13, G_DISCARD);
    }
    if ((rs = oa_hv_of(oa_get(aTHX_ S->src, "responses")))) {
        HV *responses = newHV();
        (void)hv_stores(comp, "responses", newRV_noinc((SV *)responses));
        hv_iterinit(rs);
        while ((he = hv_iternext(rs))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            (void)hv_store(responses, k, kl,
                           oa_sw2_response(aTHX_ S, hv_iterval(rs, he), S->produces, "responses"), 0);
        }
    }
    if ((sd = oa_hv_of(oa_get(aTHX_ S->src, "securityDefinitions")))) {
        HV *schemes = newHV();
        (void)hv_stores(comp, "securitySchemes", newRV_noinc((SV *)schemes));
        hv_iterinit(sd);
        while ((he = hv_iternext(sd))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            (void)hv_store(schemes, k, kl, oa_sw2_scheme(aTHX_ S, k, kl, hv_iterval(sd, he)), 0);
        }
    }
    if (!HvUSEDKEYS(comp)) (void)hv_delete(S->out, "components", 10, G_DISCARD);
}

/* ---- rules 1 to 7 and 11: the operation ------------------------------------- *
 *
 * The effective parameter list is the path item's with the operation's layered
 * over by (name, in). Entries with `in` path, query or header STAY where they
 * were (the compiler merges those levels itself, and moving them would change
 * operation_doc). Entries with `in` body or formData, from either level, come
 * out of their lists and become the operation's requestBody: one body at most,
 * never beside formData, keyed by the effective consumes (D4). A `$ref` entry
 * is followed into the SOURCE to learn its `in`; a body or formData definition
 * reached that way is inlined, since the request body depends on THIS
 * operation's consumes and several form members make one body. */

/* a non-body list entry: a reference rewritten, or the object with its schema
 * walked (phase 05 turns the inline type into a schema here) */
static SV *oa_sw2_param_entry(pTHX_ oa_sw2 *S, HV *p) {
    SV *ref = oa_get(aTHX_ p, "$ref");
    if (ref) {
        HV *c = oa_sw2_copy_hv(aTHX_ p);
        (void)hv_stores(c, "$ref", oa_sw2_ref(aTHX_ S, ref));
        return newRV_noinc((SV *)c);
    }
    return oa_sw2_param_def(aTHX_ S, p);
}

/* the raw object a list entry stands for: itself, or the definition its $ref
 * names; NULL when the reference cannot be followed (left for the 3.0 pass) */
static HV *oa_sw2_entry_raw(pTHX_ oa_sw2 *S, HV *p) {
    return oa_get(aTHX_ p, "$ref") ? oa_sw2_deref(aTHX_ S, p, "parameters") : p;
}

static int oa_sw2_same_param(pTHX_ HV *x, HV *y) {
    SV *xn = oa_get(aTHX_ x, "name"), *yn = oa_get(aTHX_ y, "name");
    SV *xi = oa_get(aTHX_ x, "in"),   *yi = oa_get(aTHX_ y, "in");
    if (!xn || !yn || !xi || !yi) return 0;
    return sv_eq(xn, yn) && sv_eq(xi, yi);
}

static int oa_sw2_is_form_type(const char *p, STRLEN l) {
    return (l == 33 && memEQ(p, "application/x-www-form-urlencoded", 33))
        || (l == 19 && memEQ(p, "multipart/form-data", 19));
}

/* the Encoding Object entry a formData array member needs: csv is form
 * UNEXPLODED (3.x's default for a form member is exploded, the reverse), multi
 * exploded, ssv and pipes their named styles, tsv the extension (D5) */
static SV *oa_sw2_form_encoding(pTHX_ SV *cf, const char *where, const char *name) {
    HV *e = newHV();
    const char *fmt = "csv";
    STRLEN fl = 3;
    if (cf) {
        if (SvROK(cf)) croak("Open::API: %s: formData '%s': collectionFormat must be a string", where, name);
        fmt = SvPV_const(cf, fl);
    }
    if (fl == 3 && memEQ(fmt, "csv", 3)) {
        (void)hv_stores(e, "style",   newSVpvs("form"));
        (void)hv_stores(e, "explode", newRV_noinc(newSViv(0)));
    } else if (fl == 5 && memEQ(fmt, "multi", 5)) {
        (void)hv_stores(e, "style",   newSVpvs("form"));
        (void)hv_stores(e, "explode", newRV_noinc(newSViv(1)));
    } else if (fl == 3 && memEQ(fmt, "ssv", 3)) {
        (void)hv_stores(e, "style",   newSVpvs("spaceDelimited"));
    } else if (fl == 5 && memEQ(fmt, "pipes", 5)) {
        (void)hv_stores(e, "style",   newSVpvs("pipeDelimited"));
    } else if (fl == 3 && memEQ(fmt, "tsv", 3)) {
        (void)hv_stores(e, "style",   newSVpvs("form"));
        (void)hv_stores(e, "explode", newRV_noinc(newSViv(0)));
        (void)hv_stores(e, "x-oa-collectionFormat", newSVpvs("tsv"));
    } else {
        croak("Open::API: %s: formData '%s': collectionFormat '%.*s' is not csv, "
              "ssv, tsv, pipes or multi", where, name, (int)fl, fmt);
    }
    return newRV_noinc((SV *)e);
}

#define OA_SW2_MAX_PARAMS 64

static SV *oa_sw2_operation(pTHX_ oa_sw2 *S, HV *item, HV *op, const char *where) {
    HV *out = oa_sw2_copy_hv(aTHX_ op);
    AV *consumes = oa_sw2_effective(aTHX_ S, op, "consumes", S->consumes);
    AV *produces = oa_sw2_effective(aTHX_ S, op, "produces", S->produces);
    HV *body = NULL, *forms[OA_SW2_MAX_PARAMS], *seen[OA_SW2_MAX_PARAMS];
    int nforms = 0, nseen = 0;
    AV *op_params = oa_av_of(oa_get(aTHX_ op, "parameters"));
    AV *item_params = oa_av_of(oa_get(aTHX_ item, "parameters"));
    SV *v;
    I32 i, n;
    sv_2mortal((SV *)out);

    /* the operation's own list */
    if (op_params) {
        AV *keep = newAV();
        (void)hv_stores(out, "parameters", newRV_noinc((SV *)keep));
        n = av_len(op_params);
        for (i = 0; i <= n; i++) {
            SV **e = av_fetch(op_params, i, 0);
            HV *p = (e && *e) ? oa_hv_of(*e) : NULL, *raw;
            int k;
            if (!p) croak("Open::API: %s: a parameter is not an object", where);
            raw = oa_sw2_entry_raw(aTHX_ S, p);
            if (!raw) { av_push(keep, newSVsv(*e)); continue; }   /* refused by name later */
            for (k = 0; k < nseen; k++)
                if (oa_sw2_same_param(aTHX_ seen[k], raw))
                    croak("Open::API: %s: parameter '%s' (in %s) is declared twice in "
                          "one list", where, SvPV_nolen(oa_get(aTHX_ raw, "name")),
                          SvPV_nolen(oa_get(aTHX_ raw, "in")));
            if (nseen < OA_SW2_MAX_PARAMS) seen[nseen++] = raw;
            if (oa_sw2_str_is(aTHX_ oa_get(aTHX_ raw, "in"), "body")) {
                if (body)
                    croak("Open::API: %s: there can be one body parameter at most", where);
                body = raw;
            } else if (oa_sw2_str_is(aTHX_ oa_get(aTHX_ raw, "in"), "formData")) {
                if (nforms >= OA_SW2_MAX_PARAMS)
                    croak("Open::API: %s: more than %d formData parameters", where, OA_SW2_MAX_PARAMS);
                forms[nforms++] = raw;
            } else {
                av_push(keep, oa_sw2_param_entry(aTHX_ S, p));
            }
        }
    }
    /* the path item's list: body and formData members apply to this operation
     * unless it declares the same (name, in) itself; the rest stay on the item */
    if (item_params) {
        n = av_len(item_params);
        for (i = 0; i <= n; i++) {
            SV **e = av_fetch(item_params, i, 0);
            HV *p = (e && *e) ? oa_hv_of(*e) : NULL, *raw;
            int k, overridden = 0;
            if (!p) continue;
            raw = oa_sw2_entry_raw(aTHX_ S, p);
            if (!raw) continue;
            for (k = 0; k < nseen; k++)
                if (oa_sw2_same_param(aTHX_ seen[k], raw)) { overridden = 1; break; }
            if (overridden) continue;
            if (oa_sw2_str_is(aTHX_ oa_get(aTHX_ raw, "in"), "body")) {
                if (body)
                    croak("Open::API: %s: there can be one body parameter at most "
                          "(one is declared on the path item too)", where);
                body = raw;
            } else if (oa_sw2_str_is(aTHX_ oa_get(aTHX_ raw, "in"), "formData")) {
                if (nforms >= OA_SW2_MAX_PARAMS)
                    croak("Open::API: %s: more than %d formData parameters", where, OA_SW2_MAX_PARAMS);
                forms[nforms++] = raw;
            }
        }
    }
    if (body && nforms)
        croak("Open::API: %s: a body parameter and formData parameters cannot be "
              "declared together", where);

    /* rule 4: the body */
    if (body) {
        HV *rb = newHV();
        SV *schema = oa_get(aTHX_ body, "schema"), *req = oa_get(aTHX_ body, "required");
        (void)hv_stores(out, "requestBody", newRV_noinc((SV *)rb));
        if (!schema)
            croak("Open::API: %s: the body parameter has no 'schema' (it is required)", where);
        if (req) (void)hv_stores(rb, "required", newSVsv(req));
        (void)hv_stores(rb, "content",
                        oa_sw2_content(aTHX_ oa_sw2_schema(aTHX_ S, schema, 0),
                                       consumes, "application/json"));
        oa_sw2_copy_extras(aTHX_ rb, body);
    }
    /* rule 5: the form */
    else if (nforms) {
        HV *rb = newHV(), *schema = newHV(), *props = newHV(), *enc = newHV();
        AV *required = newAV(), *types;
        int f, has_file = 0, any_required = 0;
        (void)hv_stores(out, "requestBody", newRV_noinc((SV *)rb));
        sv_2mortal((SV *)schema);
        sv_2mortal((SV *)enc);
        (void)hv_stores(schema, "type", newSVpvs("object"));
        (void)hv_stores(schema, "properties", newRV_noinc((SV *)props));
        (void)hv_stores(schema, "required", newRV_noinc((SV *)required));
        for (f = 0; f < nforms; f++)
            if (oa_sw2_str_is(aTHX_ oa_get(aTHX_ forms[f], "type"), "file")) has_file = 1;
        /* the form media types: those of the effective consumes, or D4's default */
        types = (AV *)sv_2mortal((SV *)newAV());
        if (consumes) {
            I32 cn = av_len(consumes);
            for (i = 0; i <= cn; i++) {
                SV **e = av_fetch(consumes, i, 0);
                STRLEN cl; const char *cp = SvPV_const(*e, cl);
                if (oa_sw2_is_form_type(cp, cl)) av_push(types, newSVsv(*e));
            }
            if (av_len(types) < 0) {
                if (has_file)
                    croak("Open::API: %s: a formData parameter of type file requires "
                          "consumes multipart/form-data, application/x-www-form-urlencoded "
                          "or both", where);
                croak("Open::API: %s: formData parameters need a form media type in "
                      "consumes (multipart/form-data or application/x-www-form-urlencoded)",
                      where);
            }
        } else {
            av_push(types, newSVpv(has_file ? "multipart/form-data"
                                            : "application/x-www-form-urlencoded", 0));
        }
        for (f = 0; f < nforms; f++) {
            HV *p = forms[f];
            SV *nm = oa_get(aTHX_ p, "name"), *prop;
            STRLEN nl; const char *np;
            /* two form members with one name were refused above as a
             * duplicated (name, in): the mutation table showed a check here
             * could never fire, so there is none */
            if (!nm) croak("Open::API: %s: a formData parameter has no 'name'", where);
            np = SvPV_const(nm, nl);
            prop = oa_sw2_type_schema(aTHX_ S, p, 0, where);
            if (oa_sv_truthy(aTHX_ oa_get(aTHX_ p, "allowEmptyValue"))) {
                /* "valid only for either query or formData": as a property the
                 * keyword is gone, so the widening is written out (no const
                 * in 3.0) */
                HV *w = newHV(), *empty = newHV();
                AV *any = newAV(), *en = newAV();
                av_push(en, newSVpvs(""));
                (void)hv_stores(empty, "type", newSVpvs("string"));
                (void)hv_stores(empty, "enum", newRV_noinc((SV *)en));
                av_push(any, prop);
                av_push(any, newRV_noinc((SV *)empty));
                (void)hv_stores(w, "anyOf", newRV_noinc((SV *)any));
                prop = newRV_noinc((SV *)w);
            }
            (void)hv_store(props, np, (I32)nl, prop, 0);
            if (oa_sv_truthy(aTHX_ oa_get(aTHX_ p, "required"))) {
                av_push(required, newSVsv(nm));
                any_required = 1;
            }
            if (oa_sw2_str_is(aTHX_ oa_get(aTHX_ p, "type"), "array"))
                (void)hv_store(enc, np, (I32)nl,
                               oa_sw2_form_encoding(aTHX_ oa_get(aTHX_ p, "collectionFormat"), where, np), 0);
        }
        if (av_len(required) < 0) (void)hv_delete(schema, "required", 8, G_DISCARD);
        if (any_required) (void)hv_stores(rb, "required", newRV_noinc(newSViv(1)));
        {
            HV *content = newHV();
            I32 tn = av_len(types);
            (void)hv_stores(rb, "content", newRV_noinc((SV *)content));
            for (i = 0; i <= tn; i++) {
                SV **e = av_fetch(types, i, 0);
                HV *mt = newHV();
                STRLEN cl; const char *cp = SvPV_const(*e, cl);
                (void)hv_stores(mt, "schema", newRV_inc((SV *)schema));
                if (HvUSEDKEYS(enc)) (void)hv_stores(mt, "encoding", newRV_inc((SV *)enc));
                (void)hv_store(content, cp, (I32)cl, newRV_noinc((SV *)mt), 0);
            }
        }
    }
    (void)hv_delete(out, "consumes", 8, G_DISCARD);
    (void)hv_delete(out, "produces", 8, G_DISCARD);

    /* rules 6 to 10: the responses */
    {
        HV *rh = oa_hv_of(oa_get(aTHX_ op, "responses")), *nr;
        HE *he;
        if (!rh)
            croak("Open::API: %s: operation has no 'responses' (it is required)", where);
        if (!HvUSEDKEYS(rh))
            croak("Open::API: %s: responses \"MUST contain at least one response code\"", where);
        nr = newHV();
        (void)hv_stores(out, "responses", newRV_noinc((SV *)nr));
        hv_iterinit(rh);
        while ((he = hv_iternext(rh))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            if (oa_sw2_is_ext(k, (STRLEN)kl)) {
                (void)hv_store(nr, k, kl, newSVsv(hv_iterval(rh, he)), 0);
                continue;
            }
            /* 2.0's keys are HTTP status codes and `default`; a range such as
             * 2XX is 3.0's, and the compiler would honour it silently */
            if (kl == 3 && k[0] >= '1' && k[0] <= '5'
                && (k[1] == 'X' || k[1] == 'x') && (k[2] == 'X' || k[2] == 'x'))
                croak("Open::API: %s: response key '%.*s' is a status range, which "
                      "Swagger 2.0 does not define (keys are status codes or default)",
                      where, (int)kl, k);
            (void)hv_store(nr, k, kl,
                           oa_sw2_response(aTHX_ S, hv_iterval(rh, he), produces, where), 0);
        }
    }

    /* rule 11: operation schemes -> operation servers, when a host exists */
    if ((v = oa_get(aTHX_ op, "schemes"))) {
        AV *schemes = oa_av_of(v);
        if (!schemes) croak("Open::API: %s: schemes must be a list", where);
        n = av_len(schemes);
        for (i = 0; i <= n; i++) {
            SV **e = av_fetch(schemes, i, 0);
            STRLEN sl; const char *sp;
            if (!e || !*e || SvROK(*e) || !SvOK(*e))
                croak("Open::API: %s: schemes: a scheme must be a string", where);
            sp = SvPV_const(*e, sl);
            if (!oa_sw2_scheme_ok(sp, sl))
                croak("Open::API: %s: schemes value '%.*s' is not one of http, https, "
                      "ws, wss", where, (int)sl, sp);
        }
        if (S->has_host && n >= 0) {
            AV *servers = newAV();
            STRLEN hl, bl = 0; const char *hp = SvPV_const(S->host, hl), *bpp = NULL;
            if (S->basepath) bpp = SvPV_const(S->basepath, bl);
            (void)hv_stores(out, "servers", newRV_noinc((SV *)servers));
            for (i = 0; i <= n; i++) {
                SV **e = av_fetch(schemes, i, 0);
                SV *url = newSVsv(*e);
                sv_catpvs(url, "://");
                sv_catpvn(url, hp, hl);
                if (bpp) sv_catpvn(url, bpp, bl);
                oa_sw2_push_server(aTHX_ servers, url);
            }
        }
        (void)hv_delete(out, "schemes", 7, G_DISCARD);
    }
    return newRV_inc((SV *)out);
}

static SV *oa_sw2_path_item(pTHX_ oa_sw2 *S, SV *item, const char *path) {
    HV *h = oa_hv_of(item), *out;
    SV *v;
    int m;
    if (!h) return newSVsv(item);
    out = oa_sw2_copy_hv(aTHX_ h);
    sv_2mortal((SV *)out);
    /* path-level parameters: body and formData members were folded into every
     * operation; the rest stay here for the compiler's merge */
    if ((v = oa_get(aTHX_ h, "parameters"))) {
        AV *src = oa_av_of(v), *keep;
        HV *seen[OA_SW2_MAX_PARAMS];
        int nseen = 0;
        I32 i, n;
        if (!src) croak("Open::API: %s: parameters must be a list", path);
        keep = newAV();
        (void)hv_stores(out, "parameters", newRV_noinc((SV *)keep));
        n = av_len(src);
        for (i = 0; i <= n; i++) {
            SV **e = av_fetch(src, i, 0);
            HV *p = (e && *e) ? oa_hv_of(*e) : NULL, *raw;
            int k;
            if (!p) croak("Open::API: %s: a parameter is not an object", path);
            raw = oa_sw2_entry_raw(aTHX_ S, p);
            if (!raw) { av_push(keep, newSVsv(*e)); continue; }
            for (k = 0; k < nseen; k++)
                if (oa_sw2_same_param(aTHX_ seen[k], raw))
                    croak("Open::API: %s: path item parameter '%s' (in %s) is declared "
                          "twice in one list", path, SvPV_nolen(oa_get(aTHX_ raw, "name")),
                          SvPV_nolen(oa_get(aTHX_ raw, "in")));
            if (nseen < OA_SW2_MAX_PARAMS) seen[nseen++] = raw;
            if (oa_sw2_str_is(aTHX_ oa_get(aTHX_ raw, "in"), "body")
                || oa_sw2_str_is(aTHX_ oa_get(aTHX_ raw, "in"), "formData")) continue;
            av_push(keep, oa_sw2_param_entry(aTHX_ S, p));
        }
    }
    for (m = 0; oa_methods[m]; m++) {
        HV *op;
        if (!(v = oa_get(aTHX_ h, oa_methods[m]))) continue;
        op = oa_hv_of(v);
        if (!op) croak("Open::API: %s: %s is not an object", path, oa_methods[m]);
        {
            SV *where = sv_2mortal(newSVpvf("%s %s", oa_methods[m], path));
            (void)hv_store(out, oa_methods[m], (I32)strlen(oa_methods[m]),
                           oa_sw2_operation(aTHX_ S, h, op, SvPVX(where)), 0);
        }
    }
    return newRV_inc((SV *)out);
}

static void oa_sw2_paths(pTHX_ oa_sw2 *S) {
    HV *paths = oa_hv_of(oa_get(aTHX_ S->src, "paths")), *dst;
    HE *he;
    if (!paths) return;                        /* rule 1 was checked by the caller */
    dst = newHV();
    (void)hv_stores(S->out, "paths", newRV_noinc((SV *)dst));
    hv_iterinit(paths);
    while ((he = hv_iternext(paths))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        SV *path = sv_2mortal(newSVpvn(k, (STRLEN)kl));
        (void)hv_store(dst, k, kl,
                       oa_sw2_path_item(aTHX_ S, hv_iterval(paths, he), SvPVX(path)), 0);
    }
}

/* ---- the entry point --------------------------------------------------------- */

static SV *oa_swagger2_to_30(pTHX_ SV *doc) {
    oa_sw2 S;
    static const char *const gone[] = {
        "host", "basePath", "schemes", "consumes", "produces",
        "definitions", "parameters", "responses", "securityDefinitions", NULL
    };
    int i;
    S.src      = (HV *)SvRV(doc);
    S.out      = oa_sw2_copy_hv(aTHX_ S.src);
    S.consumes = NULL;
    S.produces = NULL;
    S.has_host = 0;
    S.host     = NULL;
    S.basepath = NULL;
    sv_2mortal((SV *)S.out);                   /* the rules below croak */

    /* rule 1: "paths: Required." 3.1 allows a document without one; 2.0 does
     * not, and one that lacks it would load as an API with no operations. */
    if (!oa_get(aTHX_ S.src, "paths"))
        croak("Open::API: a Swagger 2.0 document has no 'paths' (it is required)");

    S.consumes = oa_sw2_mimes(aTHX_ oa_get(aTHX_ S.src, "consumes"), "consumes");
    S.produces = oa_sw2_mimes(aTHX_ oa_get(aTHX_ S.src, "produces"), "produces");
    oa_sw2_servers(aTHX_ &S);
    oa_sw2_components(aTHX_ &S);
    oa_sw2_paths(aTHX_ &S);

    /* rule 10: the 2.0 keys are consumed, not copied beside their
     * replacements, or the second pass would convert them again */
    for (i = 0; gone[i]; i++)
        (void)hv_delete(S.out, gone[i], (I32)strlen(gone[i]), G_DISCARD);

    return newRV_inc((SV *)S.out);
}

#endif /* OA_SWAGGER2_H */

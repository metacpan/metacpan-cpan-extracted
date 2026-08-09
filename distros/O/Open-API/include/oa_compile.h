#ifndef OA_COMPILE_H
#define OA_COMPILE_H

/* The spec compiler: runs once inside Open::API->new, after the 3.1 gate.
 * Walks the decoded document and builds the operation table - every path
 * template pre-split into segments, every parameter/body/response schema
 * compiled through the JSF ABI - so the per-request path (oa_route.h /
 * oa_validate.h, phase 2) never touches the document again.
 *
 * SV ownership: every SV stored in the table is first pushed onto the api's
 * keepalive AV (oa_keep), which owns it; the structs hold borrowed pointers.
 * oa_ops_free only frees the C arrays - dropping the keep AV in oa_api_free
 * releases all SVs, including the compiled JSF handles (blessed SVs whose
 * DESTROY frees the underlying validators). */

enum { OA_IN_PATH = 0, OA_IN_QUERY, OA_IN_HEADER, OA_IN_COOKIE, OA_IN_N };

/* security scheme kinds (oauth2 / openIdConnect are carried as BEARER: the
 * credential is the access token; flow automation is out of scope) */
enum { OA_SEC_APIKEY = 0, OA_SEC_BEARER, OA_SEC_BASIC };

typedef struct oa_seg   { SV *lit; SV *pname; } oa_seg;   /* lit XOR pname */
typedef struct oa_param { SV *name; SV *handle; int required; int is_array; } oa_param;
typedef struct oa_body  { SV *ctype; SV *handle; } oa_body;  /* handle NULL = pass-through */
typedef struct oa_resp  { SV *status; SV *ctype; SV *handle; } oa_resp;

typedef struct oa_scheme  { SV *name; int type; int loc; SV *pname; } oa_scheme;
typedef struct oa_secitem { int scheme; SV *scopes; } oa_secitem;   /* scopes AV rv or NULL */
typedef struct oa_secalt  { oa_secitem *items; int n; } oa_secalt;

/* Response-validation coverage, per operation. Every response either is
 * checked or is skipped for exactly one named reason, so what was not
 * looked at is a reported number rather than a silent gap. `seen` is the
 * sampling counter: deterministic 1-in-N, which is cheaper than a random
 * draw and gives a stable denominator. */
typedef struct oa_rvstat {
    unsigned long total;        /* responses reaching the check          */
    unsigned long seen;         /* the sampling counter                  */
    unsigned long sampled;      /* passed the sampling gate              */
    unsigned long checked;      /* decoded and validated                 */
    unsigned long violations;   /* validated and did not conform         */
    unsigned long skip_ctype;   /* not a declared JSON content type      */
    unsigned long skip_size;    /* Content-Length absent or over max_body */
    unsigned long skip_body;    /* body not a plain scalar (fh/stream)   */
    unsigned long skip_schema;  /* the status declares no schema         */
    unsigned long skip_decode;  /* the body is not decodable JSON        */
} oa_rvstat;

typedef struct oa_op {
    SV *op_id, *method, *path;         /* method stored lowercase */
    oa_seg   *segs;  int nsegs;
    oa_param *params[OA_IN_N]; int nparams[OA_IN_N];
    oa_body  *bodies; int nbodies; int body_required;
    oa_resp  *resps;  int nresps;
    oa_secalt *sec;  int nsec;         /* requirement alternatives (OR) */
    int own_sec;                       /* 1 = op-level copy, 0 = shares rootsec */
    oa_rvstat rv;                      /* response-validation coverage */
} oa_op;

typedef struct oa_ops {
    oa_op *ops; int n, cap;
    HV *by_id;                          /* operationId -> IV index */
    oa_scheme *schemes; int nschemes;   /* components.securitySchemes */
    oa_secalt *rootsec; int nrootsec;   /* document-level security */
} oa_ops;

static void oa_secalts_free(oa_secalt *alts, int n) {
    int i;
    if (!alts) return;
    for (i = 0; i < n; i++) free(alts[i].items);
    free(alts);
}

static void oa_ops_free(pTHX_ void *p) {
    oa_ops *t = (oa_ops *)p;
    int i, loc;
    if (!t) return;
    for (i = 0; i < t->n; i++) {
        oa_op *o = &t->ops[i];
        free(o->segs);
        for (loc = 0; loc < OA_IN_N; loc++) free(o->params[loc]);
        free(o->bodies);
        free(o->resps);
        if (o->own_sec) oa_secalts_free(o->sec, o->nsec);
    }
    free(t->ops);
    oa_secalts_free(t->rootsec, t->nrootsec);
    free(t->schemes);
    if (t->by_id) SvREFCNT_dec((SV *)t->by_id);
    free(t);
}

/* ---- base64 (Basic credentials, both directions) -------------------------- */

static const char oa_b64_al[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static SV *oa_b64_encode(pTHX_ const char *in, STRLEN len) {
    SV *out = newSV((len + 2) / 3 * 4 + 1);
    char *d;
    STRLEN i;
    SvPOK_on(out);
    d = SvPVX(out);
    for (i = 0; i + 2 < len; i += 3) {
        U32 v = ((U32)(U8)in[i] << 16) | ((U32)(U8)in[i+1] << 8) | (U8)in[i+2];
        *d++ = oa_b64_al[v >> 18]; *d++ = oa_b64_al[(v >> 12) & 63];
        *d++ = oa_b64_al[(v >> 6) & 63]; *d++ = oa_b64_al[v & 63];
    }
    if (i < len) {
        U32 v = (U32)(U8)in[i] << 16;
        int two = (i + 1 < len);
        if (two) v |= (U32)(U8)in[i+1] << 8;
        *d++ = oa_b64_al[v >> 18]; *d++ = oa_b64_al[(v >> 12) & 63];
        *d++ = two ? oa_b64_al[(v >> 6) & 63] : '=';
        *d++ = '=';
    }
    *d = '\0';
    SvCUR_set(out, (STRLEN)(d - SvPVX(out)));
    return out;
}

static int oa_b64_val(char c) {
    if (c >= 'A' && c <= 'Z') return c - 'A';
    if (c >= 'a' && c <= 'z') return c - 'a' + 26;
    if (c >= '0' && c <= '9') return c - '0' + 52;
    if (c == '+') return 62;
    if (c == '/') return 63;
    return -1;
}

static SV *oa_b64_decode(pTHX_ const char *in, STRLEN len) {   /* NULL on junk */
    SV *out;
    char *d;
    U32 acc = 0;
    int nb = 0;
    STRLEN i;
    while (len && (in[len-1] == '=' || isSPACE((U8)in[len-1]))) len--;
    out = newSV(len / 4 * 3 + 4);
    SvPOK_on(out);
    d = SvPVX(out);
    for (i = 0; i < len; i++) {
        int v = oa_b64_val(in[i]);
        if (v < 0) { SvREFCNT_dec(out); return NULL; }
        acc = (acc << 6) | (U32)v;
        if (++nb == 4) { *d++ = (char)(acc >> 16); *d++ = (char)(acc >> 8);
                         *d++ = (char)acc; acc = 0; nb = 0; }
    }
    if (nb == 3)      { *d++ = (char)(acc >> 10); *d++ = (char)(acc >> 2); }
    else if (nb == 2) { *d++ = (char)(acc >> 4); }
    else if (nb == 1) { SvREFCNT_dec(out); return NULL; }
    *d = '\0';
    SvCUR_set(out, (STRLEN)(d - SvPVX(out)));
    return out;
}

/* ---- small helpers -------------------------------------------------------- */

static SV *oa_keep(pTHX_ oa_api *a, SV *sv) {   /* keep AV takes ownership */
    av_push(a->keep, sv);
    return sv;
}
static HV *oa_hv_of(SV *sv) {
    return (sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV) ? (HV *)SvRV(sv) : NULL;
}
static AV *oa_av_of(SV *sv) {
    return (sv && SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV) ? (AV *)SvRV(sv) : NULL;
}
static SV *oa_get(pTHX_ HV *h, const char *k) {
    SV **e = h ? hv_fetch(h, k, (I32)strlen(k), 0) : NULL;
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

/* schema's `type` is or contains "array" (query repeat-key handling) */
static int oa_schema_is_array(pTHX_ SV *schema) {
    HV *h = oa_hv_of(schema);
    SV *t = h ? oa_get(aTHX_ h, "type") : NULL;
    if (!t) return 0;
    if (!SvROK(t)) { STRLEN l; const char *p = SvPV_const(t, l);
                     return l == 5 && memEQ(p, "array", 5); }
    {
        AV *av = oa_av_of(t);
        SSize_t i, n = av ? av_len(av) + 1 : 0;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            if (e && *e) { STRLEN l; const char *p = SvPV_const(*e, l);
                           if (l == 5 && memEQ(p, "array", 5)) return 1; }
        }
    }
    return 0;
}

/* JSF resolves same-document $refs against schema locations it knows -
 * `#/$defs/Name` works, arbitrary keys like `#/components/schemas/Name` do
 * not. So at compile time every extracted schema is deep-copied with its
 * refs REWRITTEN (#/components/schemas/X -> #/$defs/X) and the spec's
 * components.schemas - itself rewritten once, since schemas reference each
 * other - is attached as a shared $defs. */

#define OA_COMP_PFX     "#/components/schemas/"
#define OA_COMP_PFX_LEN 21

static SV *oa_rewrite_refs(pTHX_ SV *sv) {
    if (sv && SvROK(sv)) {
        SV *rv = SvRV(sv);
        if (SvTYPE(rv) == SVt_PVHV) {
            HV *src = (HV *)rv, *dst = newHV();
            HE *he;
            hv_iterinit(src);
            while ((he = hv_iternext(src))) {
                I32 kl; const char *k = hv_iterkey(he, &kl);
                SV *v = hv_iterval(src, he);
                if (kl == 4 && memEQ(k, "$ref", 4) && SvOK(v) && !SvROK(v)) {
                    STRLEN vl; const char *vp = SvPV_const(v, vl);
                    if (vl > OA_COMP_PFX_LEN
                        && memEQ(vp, OA_COMP_PFX, OA_COMP_PFX_LEN)) {
                        SV *nv = newSVpvs("#/$defs/");
                        sv_catpvn(nv, vp + OA_COMP_PFX_LEN, vl - OA_COMP_PFX_LEN);
                        (void)hv_store(dst, k, kl, nv, 0);
                        continue;
                    }
                }
                (void)hv_store(dst, k, kl, oa_rewrite_refs(aTHX_ v), 0);
            }
            return newRV_noinc((SV *)dst);
        }
        if (SvTYPE(rv) == SVt_PVAV) {
            AV *src = (AV *)rv, *dst = newAV();
            SSize_t i, n = av_len(src) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(src, i, 0);
                av_push(dst, (e && *e) ? oa_rewrite_refs(aTHX_ *e) : newSV(0));
            }
            return newRV_noinc((SV *)dst);
        }
    }
    return newSVsv(sv);
}

/* Build the shared $defs (rewritten components.schemas) once per api. */
static void oa_build_defs(pTHX_ oa_api *a) {
    HV *doc  = (HV *)SvRV(a->spec);
    HV *comp = oa_hv_of(oa_get(aTHX_ doc, "components"));
    SV *schemas = comp ? oa_get(aTHX_ comp, "schemas") : NULL;
    if (schemas && oa_hv_of(schemas))
        a->defs = oa_keep(aTHX_ a, oa_rewrite_refs(aTHX_ schemas));
}

/* Rewrite a schema's refs, attach the shared $defs, compile via the JSF ABI.
 * The returned handle is owned by the keep AV. */
static SV *oa_compile_schema(pTHX_ oa_api *a, SV *schema, int coerce) {
    SV *to = schema;
    if (a->defs && oa_hv_of(schema)) {
        SV *rw = sv_2mortal(oa_rewrite_refs(aTHX_ schema));
        HV *w  = (HV *)SvRV(rw);
        SV **own = hv_fetchs(w, "$defs", 0);
        if (own && *own && oa_hv_of(*own)) {
            /* schema carries its own $defs: overlay ours underneath */
            HV *merged = newHV(), *shared = (HV *)SvRV(a->defs), *mine;
            HE *he;
            hv_iterinit(shared);
            while ((he = hv_iternext(shared))) {
                I32 kl; const char *k = hv_iterkey(he, &kl);
                (void)hv_store(merged, k, kl,
                               SvREFCNT_inc(hv_iterval(shared, he)), 0);
            }
            mine = (HV *)SvRV(*own);
            hv_iterinit(mine);
            while ((he = hv_iternext(mine))) {
                I32 kl; const char *k = hv_iterkey(he, &kl);
                (void)hv_store(merged, k, kl,
                               SvREFCNT_inc(hv_iterval(mine, he)), 0);
            }
            (void)hv_stores(w, "$defs", newRV_noinc((SV *)merged));
        } else {
            (void)hv_stores(w, "$defs", SvREFCNT_inc(a->defs));
        }
        to = rw;
    }
    return oa_keep(aTHX_ a, JSF->compile(aTHX_ to, &PL_sv_undef, coerce, 1));
}

/* ---- path template -> segments -------------------------------------------- */

static void oa_compile_segs(pTHX_ oa_api *a, oa_op *o, const char *tpl, STRLEN tl) {
    /* count segments */
    int n = 0, i;
    STRLEN s = 0;
    while (s < tl) {
        while (s < tl && tpl[s] == '/') s++;
        if (s < tl) n++;
        while (s < tl && tpl[s] != '/') s++;
    }
    o->nsegs = n;
    o->segs  = n ? (oa_seg *)calloc((size_t)n, sizeof(oa_seg)) : NULL;
    if (n && !o->segs) croak("Open::API: out of memory");
    s = 0; i = 0;
    while (s < tl) {
        STRLEN e;
        while (s < tl && tpl[s] == '/') s++;
        if (s >= tl) break;
        e = s;
        while (e < tl && tpl[e] != '/') e++;
        if (tpl[s] == '{' && tpl[e - 1] == '}' && e - s > 2) {
            o->segs[i].pname = oa_keep(aTHX_ a, newSVpvn(tpl + s + 1, e - s - 2));
        } else {
            o->segs[i].lit = oa_keep(aTHX_ a, newSVpvn(tpl + s, e - s));
        }
        i++;
        s = e;
    }
}

/* ---- parameters ------------------------------------------------------------ */

static int oa_param_loc(pTHX_ SV *in) {
    STRLEN l; const char *p;
    if (!in) return -1;
    p = SvPV_const(in, l);
    if (l == 4 && memEQ(p, "path", 4))   return OA_IN_PATH;
    if (l == 5 && memEQ(p, "query", 5))  return OA_IN_QUERY;
    if (l == 6 && memEQ(p, "header", 6)) return OA_IN_HEADER;
    if (l == 6 && memEQ(p, "cookie", 6)) return OA_IN_COOKIE;
    return -1;
}

/* same (name, in)? - for the path-item / operation parameter merge */
static int oa_param_same(pTHX_ HV *x, HV *y) {
    SV *xn = oa_get(aTHX_ x, "name"), *yn = oa_get(aTHX_ y, "name");
    SV *xi = oa_get(aTHX_ x, "in"),   *yi = oa_get(aTHX_ y, "in");
    if (!xn || !yn || !xi || !yi) return 0;
    return sv_eq(xn, yn) && sv_eq(xi, yi);
}

/* Merge path-item + operation parameter lists (operation wins on name+in),
 * then compile each into the op's per-location arrays. */
static void oa_compile_params(pTHX_ oa_api *a, oa_op *o, AV *item_params,
                              AV *op_params) {
    HV *merged[64];
    int nm = 0, i, loc;
    int counts[OA_IN_N] = { 0, 0, 0, 0 };
    int fill[OA_IN_N]   = { 0, 0, 0, 0 };

    /* path-item level first */
    if (item_params) {
        SSize_t n = av_len(item_params) + 1, j;
        for (j = 0; j < n && nm < 64; j++) {
            SV **e = av_fetch(item_params, j, 0);
            HV *ph = e ? oa_hv_of(*e) : NULL;
            if (ph) merged[nm++] = ph;
        }
    }
    /* operation level: replace same (name,in), else append */
    if (op_params) {
        SSize_t n = av_len(op_params) + 1, j;
        for (j = 0; j < n; j++) {
            SV **e = av_fetch(op_params, j, 0);
            HV *ph = e ? oa_hv_of(*e) : NULL;
            int k, hit = 0;
            if (!ph) continue;
            for (k = 0; k < nm; k++)
                if (oa_param_same(aTHX_ merged[k], ph)) { merged[k] = ph; hit = 1; break; }
            if (!hit) {
                if (nm >= 64) croak("Open::API: more than 64 parameters on %s",
                                    SvPV_nolen(o->op_id));
                merged[nm++] = ph;
            }
        }
    }

    for (i = 0; i < nm; i++) {
        int l = oa_param_loc(aTHX_ oa_get(aTHX_ merged[i], "in"));
        if (l < 0) croak("Open::API: parameter with bad 'in' on %s",
                         SvPV_nolen(o->op_id));
        counts[l]++;
    }
    for (loc = 0; loc < OA_IN_N; loc++) {
        o->nparams[loc] = counts[loc];
        o->params[loc]  = counts[loc]
            ? (oa_param *)calloc((size_t)counts[loc], sizeof(oa_param)) : NULL;
        if (counts[loc] && !o->params[loc]) croak("Open::API: out of memory");
    }
    for (i = 0; i < nm; i++) {
        HV *ph = merged[i];
        SV *name   = oa_get(aTHX_ ph, "name");
        SV *schema = oa_get(aTHX_ ph, "schema");
        SV *req    = oa_get(aTHX_ ph, "required");
        int l      = oa_param_loc(aTHX_ oa_get(aTHX_ ph, "in"));
        oa_param *pp;
        if (!name) croak("Open::API: parameter without a name on %s",
                         SvPV_nolen(o->op_id));
        pp = &o->params[l][fill[l]++];
        pp->name     = oa_keep(aTHX_ a, newSVsv(name));
        pp->required = (l == OA_IN_PATH) ? 1 : (req && SvTRUE(req)) ? 1 : 0;
        pp->is_array = schema ? oa_schema_is_array(aTHX_ schema) : 0;
        pp->handle   = schema
            ? oa_compile_schema(aTHX_ a, schema, 1) : NULL;
    }
}

/* ---- requestBody / responses ----------------------------------------------- */

static int oa_ctype_is_json(const char *p, STRLEN l) {
    return l >= 16 && memEQ(p, "application/json", 16);
}

static void oa_compile_body(pTHX_ oa_api *a, oa_op *o, SV *rb) {
    HV *rbh = oa_hv_of(rb);
    HV *content;
    HE *he;
    int n = 0, i = 0;
    if (!rbh) return;
    {
        SV *req = oa_get(aTHX_ rbh, "required");
        o->body_required = req && SvTRUE(req) ? 1 : 0;
    }
    content = oa_hv_of(oa_get(aTHX_ rbh, "content"));
    if (!content) return;
    n = (int)HvUSEDKEYS(content);
    if (!n) return;
    o->bodies  = (oa_body *)calloc((size_t)n, sizeof(oa_body));
    if (!o->bodies) croak("Open::API: out of memory");
    o->nbodies = n;
    hv_iterinit(content);
    while ((he = hv_iternext(content))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        HV *media = oa_hv_of(hv_iterval(content, he));
        SV *schema = media ? oa_get(aTHX_ media, "schema") : NULL;
        o->bodies[i].ctype  = oa_keep(aTHX_ a, newSVpvn(k, (STRLEN)kl));
        o->bodies[i].handle = (schema && oa_ctype_is_json(k, (STRLEN)kl))
            ? oa_compile_schema(aTHX_ a, schema, 0) : NULL;
        i++;
    }
}

static void oa_compile_responses(pTHX_ oa_api *a, oa_op *o, SV *resps) {
    HV *rh = oa_hv_of(resps);
    HE *she;
    int cap = 0, n = 0;
    oa_resp *rows = NULL;
    if (!rh) return;
    hv_iterinit(rh);
    while ((she = hv_iternext(rh))) {
        I32 skl; const char *sk = hv_iterkey(she, &skl);
        HV *robj = oa_hv_of(hv_iterval(rh, she));
        HV *content = robj ? oa_hv_of(oa_get(aTHX_ robj, "content")) : NULL;
        HE *che;
        if (!content) continue;
        hv_iterinit(content);
        while ((che = hv_iternext(content))) {
            I32 ckl; const char *ck = hv_iterkey(che, &ckl);
            HV *media = oa_hv_of(hv_iterval(content, che));
            SV *schema = media ? oa_get(aTHX_ media, "schema") : NULL;
            if (!schema || !oa_ctype_is_json(ck, (STRLEN)ckl)) continue;
            if (n == cap) {
                cap = cap ? cap * 2 : 4;
                rows = (oa_resp *)realloc(rows, (size_t)cap * sizeof(oa_resp));
                if (!rows) croak("Open::API: out of memory");
            }
            rows[n].status = oa_keep(aTHX_ a, newSVpvn(sk, (STRLEN)skl));
            rows[n].ctype  = oa_keep(aTHX_ a, newSVpvn(ck, (STRLEN)ckl));
            rows[n].handle = oa_compile_schema(aTHX_ a, schema, 0);
            n++;
        }
    }
    o->resps  = rows;
    o->nresps = n;
}

/* ---- security: schemes + requirements --------------------------------------- */

/* components.securitySchemes -> the schemes table. Unsupported types croak
 * only when a requirement actually references them (checked at lookup). */
static void oa_compile_schemes(pTHX_ oa_api *a, oa_ops *t) {
    HV *doc  = (HV *)SvRV(a->spec);
    HV *comp = oa_hv_of(oa_get(aTHX_ doc, "components"));
    HV *ss   = comp ? oa_hv_of(oa_get(aTHX_ comp, "securitySchemes")) : NULL;
    HE *he;
    int i = 0, n;
    if (!ss) return;
    n = (int)HvUSEDKEYS(ss);
    if (!n) return;
    t->schemes = (oa_scheme *)calloc((size_t)n, sizeof(oa_scheme));
    if (!t->schemes) croak("Open::API: out of memory");
    hv_iterinit(ss);
    while ((he = hv_iternext(ss))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        HV *sh = oa_hv_of(hv_iterval(ss, he));
        SV *tv = sh ? oa_get(aTHX_ sh, "type") : NULL;
        oa_scheme *s = &t->schemes[i];
        STRLEN tl; const char *tp;
        if (!tv) croak("Open::API: securityScheme '%.*s' has no type", (int)kl, k);
        tp = SvPV_const(tv, tl);
        s->name = oa_keep(aTHX_ a, newSVpvn(k, (STRLEN)kl));
        s->loc  = -1;
        if (tl == 6 && memEQ(tp, "apiKey", 6)) {
            SV *nm = oa_get(aTHX_ sh, "name");
            int loc = oa_param_loc(aTHX_ oa_get(aTHX_ sh, "in"));
            if (!nm || loc < 0 || loc == OA_IN_PATH)
                croak("Open::API: apiKey scheme '%.*s' needs name and "
                      "in (query/header/cookie)", (int)kl, k);
            s->type  = OA_SEC_APIKEY;
            s->loc   = loc;
            s->pname = oa_keep(aTHX_ a, newSVsv(nm));
        } else if (tl == 4 && memEQ(tp, "http", 4)) {
            SV *sch = oa_get(aTHX_ sh, "scheme");
            STRLEN sl; const char *sp = sch ? SvPV_const(sch, sl) : NULL;
            if (sp && sl == 6 && (memEQ(sp, "bearer", 6) || memEQ(sp, "Bearer", 6)))
                s->type = OA_SEC_BEARER;
            else if (sp && sl == 5 && (memEQ(sp, "basic", 5) || memEQ(sp, "Basic", 5)))
                s->type = OA_SEC_BASIC;
            else
                croak("Open::API: http securityScheme '%.*s': unsupported "
                      "scheme '%s' (bearer and basic are supported)",
                      (int)kl, k, sp ? sp : "(none)");
        } else if ((tl == 6 && memEQ(tp, "oauth2", 6))
                || (tl == 13 && memEQ(tp, "openIdConnect", 13))) {
            s->type = OA_SEC_BEARER;   /* the credential is the access token */
        } else {
            croak("Open::API: securityScheme '%.*s': unsupported type '%.*s'",
                  (int)kl, k, (int)tl, tp);
        }
        i++;
    }
    t->nschemes = i;
}

static int oa_scheme_index(pTHX_ oa_ops *t, SV *name) {
    int i;
    for (i = 0; i < t->nschemes; i++)
        if (sv_eq(t->schemes[i].name, name)) return i;
    return -1;
}

/* a `security` AV -> malloc'd alternative list (each element an object whose
 * keys are ANDed schemes; an empty object means "no auth is acceptable") */
static oa_secalt *oa_compile_security(pTHX_ oa_api *a, oa_ops *t, AV *sec,
                                      int *nout, const char *where) {
    SSize_t n = av_len(sec) + 1, i;
    oa_secalt *alts;
    *nout = 0;
    if (n <= 0) return NULL;
    alts = (oa_secalt *)calloc((size_t)n, sizeof(oa_secalt));
    if (!alts) croak("Open::API: out of memory");
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(sec, i, 0);
        HV *req = e ? oa_hv_of(*e) : NULL;
        HE *he;
        int m, j = 0;
        if (!req) croak("Open::API: %s: security entries must be objects", where);
        m = (int)HvUSEDKEYS(req);
        alts[i].n = m;
        alts[i].items = m ? (oa_secitem *)calloc((size_t)m, sizeof(oa_secitem))
                          : NULL;
        if (m && !alts[i].items) croak("Open::API: out of memory");
        hv_iterinit(req);
        while ((he = hv_iternext(req))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            SV *nm = sv_2mortal(newSVpvn(k, (STRLEN)kl));
            SV *scopes = hv_iterval(req, he);
            int idx = oa_scheme_index(aTHX_ t, nm);
            if (idx < 0)
                croak("Open::API: %s references unknown securityScheme '%.*s'",
                      where, (int)kl, k);
            alts[i].items[j].scheme = idx;
            alts[i].items[j].scopes = oa_av_of(scopes)
                ? oa_keep(aTHX_ a, newSVsv(scopes)) : NULL;
            j++;
        }
    }
    *nout = (int)n;
    return alts;
}

/* ---- the walk --------------------------------------------------------------- */

static const char *oa_methods[] = {
    "get", "put", "post", "delete", "options", "head", "patch", "trace", NULL
};

static void oa_compile(pTHX_ oa_api *a) {
    HV *doc   = (HV *)SvRV(a->spec);
    HV *paths = oa_hv_of(oa_get(aTHX_ doc, "paths"));
    oa_ops *t;
    HE *phe;

    oa_build_defs(aTHX_ a);   /* shared $defs from components.schemas */

    t = (oa_ops *)calloc(1, sizeof(oa_ops));
    if (!t) croak("Open::API: out of memory");
    t->by_id = newHV();
    a->ops   = t;

    oa_compile_schemes(aTHX_ a, t);
    {
        AV *rs = oa_av_of(oa_get(aTHX_ doc, "security"));
        if (rs) t->rootsec = oa_compile_security(aTHX_ a, t, rs,
                                                 &t->nrootsec, "document security");
    }

    if (!paths) return;

    hv_iterinit(paths);
    while ((phe = hv_iternext(paths))) {
        I32 tkl; const char *tpl = hv_iterkey(phe, &tkl);
        HV *item = oa_hv_of(hv_iterval(paths, phe));
        AV *item_params;
        int m;
        if (!item) continue;
        item_params = oa_av_of(oa_get(aTHX_ item, "parameters"));

        for (m = 0; oa_methods[m]; m++) {
            HV *oph = oa_hv_of(oa_get(aTHX_ item, oa_methods[m]));
            SV *op_id;
            oa_op *o;
            if (!oph) continue;
            op_id = oa_get(aTHX_ oph, "operationId");
            if (!op_id)
                croak("Open::API: %s %.*s has no operationId",
                      oa_methods[m], (int)tkl, tpl);
            {
                STRLEN il; const char *ip = SvPV_const(op_id, il);
                if (hv_exists(t->by_id, ip, (I32)il))
                    croak("Open::API: duplicate operationId '%.*s'", (int)il, ip);
                if (t->n == t->cap) {
                    t->cap = t->cap ? t->cap * 2 : 8;
                    t->ops = (oa_op *)realloc(t->ops,
                                              (size_t)t->cap * sizeof(oa_op));
                    if (!t->ops) croak("Open::API: out of memory");
                }
                o = &t->ops[t->n];
                memset(o, 0, sizeof(*o));
                o->op_id  = oa_keep(aTHX_ a, newSVsv(op_id));
                o->method = oa_keep(aTHX_ a, newSVpv(oa_methods[m], 0));
                o->path   = oa_keep(aTHX_ a, newSVpvn(tpl, (STRLEN)tkl));
                (void)hv_store(t->by_id, ip, (I32)il, newSViv(t->n), 0);
                t->n++;
            }
            oa_compile_segs(aTHX_ a, o, tpl, (STRLEN)tkl);
            oa_compile_params(aTHX_ a, o, item_params,
                              oa_av_of(oa_get(aTHX_ oph, "parameters")));
            oa_compile_body(aTHX_ a, o, oa_get(aTHX_ oph, "requestBody"));
            oa_compile_responses(aTHX_ a, o, oa_get(aTHX_ oph, "responses"));
            {   /* security: operation-level overrides (an explicit empty
                 * array disables auth); otherwise inherit the document's */
                SV *osec = oa_get(aTHX_ oph, "security");
                if (osec) {
                    AV *sa = oa_av_of(osec);
                    if (!sa) croak("Open::API: %s: security must be an array",
                                   SvPV_nolen(o->op_id));
                    o->sec = oa_compile_security(aTHX_ a, t, sa, &o->nsec,
                                                 SvPV_nolen(o->op_id));
                    o->own_sec = 1;
                } else {
                    o->sec  = t->rootsec;
                    o->nsec = t->nrootsec;
                    o->own_sec = 0;
                }
            }
        }
    }
}

/* op by id, or NULL */
static oa_op *oa_op_by_id(pTHX_ oa_api *a, SV *id) {
    oa_ops *t = (oa_ops *)a->ops;
    STRLEN l; const char *p;
    SV **e;
    if (!t) return NULL;
    p = SvPV_const(id, l);
    e = hv_fetch(t->by_id, p, (I32)l, 0);
    return (e && *e) ? &t->ops[SvIV(*e)] : NULL;
}

#endif /* OA_COMPILE_H */

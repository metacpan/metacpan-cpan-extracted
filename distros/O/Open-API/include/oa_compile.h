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
/* OA_SEC_OTHER carries a scheme the specification defines but this library
 * cannot settle by itself: mutualTLS (decided by the transport, and carrying
 * no credential in the request at all) and an http scheme such as digest,
 * which needs a challenge/response exchange. Refusing the document was worse
 * than carrying it - a valid document became unusable - so the declaration is
 * kept and the application's checker decides, exactly as scopes already work. */
enum { OA_SEC_APIKEY = 0, OA_SEC_BEARER, OA_SEC_BASIC, OA_SEC_OTHER };

typedef struct oa_seg   { SV *lit; SV *pname; } oa_seg;   /* lit XOR pname */
/* `ctype` is set only for a parameter declared with `content` instead of
 * `schema`: the value on the wire is then a document of that media type, and
 * has to be decoded before the schema sees it. NULL is the ordinary case. */
/* How a parameter's value is spelled on the wire. The default depends on
 * where the parameter lives: `simple` in a path or header, `form` in a query
 * or cookie. `explode` defaults to TRUE for `form` and false for every other
 * style, which is a per-style default rather than a global one.
 *
 * A value is split on the RAW text and each piece percent-decoded after,
 * never the other way round: %2C is a comma that belongs to the value, not a
 * delimiter, and decoding first would split `a%2Cb` into two elements. */
enum {
    OA_ST_SIMPLE = 0,   /* path, header:  a,b,c                     */
    OA_ST_LABEL,        /* path:          .a.b.c                    */
    OA_ST_MATRIX,       /* path:          ;name=a,b  /  ;name=a;name=b */
    OA_ST_FORM,         /* query, cookie: ?n=a&n=b  /  ?n=a,b       */
    OA_ST_SPACE,        /* query:         ?n=a%20b                  */
    OA_ST_PIPE,         /* query:         ?n=a|b                    */
    OA_ST_DEEP          /* query:         ?n[k]=v                   */
};

typedef struct oa_param {
    SV *name; SV *handle; SV *ctype; int required; int is_array;
    /* An object-typed parameter is assembled from its serialized form the way
     * an array is. `props` holds the declared property names, and is needed
     * only by form+explode, where the members arrive as SEPARATE top-level
     * query keys (`R=100&G=200&B=150`) with nothing but the schema to say
     * which keys belong to this parameter. NULL when there are none. */
    int is_object; SV *props;
    int style; int explode; int deprecated; int allow_empty;
    /* allowReserved: a CLIENT-side rule. The reserved set may go on the wire
     * unencoded, so this is read by the URL builder, never by the validator -
     * a server decodes either spelling to the same value. */
    int allow_reserved;
} oa_param;
/* `kind` is OA_MT_*: which decoder the DECLARED type wants, decided once at
 * compile time. A range defers that to the request's own type. handle NULL
 * still means pass-through. */
typedef struct oa_body  { SV *ctype; SV *handle; int kind; SV *encoding; } oa_body;
typedef struct oa_resp  { SV *status; SV *ctype; SV *handle; } oa_resp;
/* A declared response header. Keyed by STATUS, not by media type: headers
 * belong to the Response Object, so a status declaring two content types must
 * not carry two copies, and a header-only status (204, a 3xx with Location)
 * must still be checked even though it compiles no oa_resp row at all - the
 * response row loop skips anything without JSON `content`.
 *
 * The value is an oa_param because a Header Object IS a Parameter Object
 * without `name`/`in`, so oa_check_param applies unchanged. */
typedef struct oa_rhdr { SV *status; oa_param p; } oa_rhdr;

/* `oauthish` is 1 for oauth2 and openIdConnect. It cannot be derived from
 * `type`: both collapse to OA_SEC_BEARER, which http/bearer uses too, and the
 * specification lets only those two carry scopes in a requirement. */
typedef struct oa_scheme  { SV *name; int type; int loc; SV *pname;
                            int oauthish; } oa_scheme;
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
    unsigned long hdr_checked;  /* responses whose headers were checked  */
    unsigned long hdr_missing;  /* a declared required header was absent */
    unsigned long hdr_invalid;  /* a declared header failed its schema   */
} oa_rvstat;

typedef struct oa_op {
    SV *op_id, *method, *path;         /* method stored lowercase */
    oa_seg   *segs;  int nsegs;
    oa_param *params[OA_IN_N]; int nparams[OA_IN_N];
    oa_body  *bodies; int nbodies; int body_required;
    oa_resp  *resps;  int nresps;
    oa_rhdr  *rhdrs;  int nrhdrs;      /* declared response headers, by status */
    /* This operation's own server path prefix, when it or its path item
     * declares `servers` and the caller opted in. NULL is the ordinary case,
     * where the document-level prefix (a->prefix) applies instead. In `keep`;
     * borrowed. */
    SV *prefix;
    oa_secalt *sec;  int nsec;         /* requirement alternatives (OR) */
    int own_sec;                       /* 1 = op-level copy, 0 = shares rootsec */
    oa_rvstat rv;                      /* response-validation coverage */
} oa_op;

typedef struct oa_ops {
    oa_op *ops; int n, cap;
    /* The order the ROUTER walks `ops` in, most specific first. It is a
     * separate index rather than a sort of `ops` itself because `by_id` holds
     * INDICES into that array, and reordering it would silently point every
     * operationId at the wrong operation. See oa_order_routes. */
    int *order;
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
        free(o->rhdrs);
        if (o->own_sec) oa_secalts_free(o->sec, o->nsec);
    }
    free(t->ops);
    free(t->order);
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

/* What a reference into components.schemas looks like. Defined here rather
 * than beside oa_rewrite_refs because oa_schema_is_array below reads it too,
 * and the two must not drift apart on the spelling. */
#define OA_COMP_PFX     "#/components/schemas/"
#define OA_COMP_PFX_LEN 21

/* A component schema by name, from the normalised document. ->spec keeps its
 * refs in `#/components/schemas/` form: the `#/$defs/` rewrite happens on the
 * copy oa_compile_schema makes, not here. */
static SV *oa_comp_schema(pTHX_ oa_api *a, const char *nm, STRLEN nl) {
    HV *doc  = a && a->spec ? oa_hv_of(a->spec) : NULL;
    HV *comp = doc  ? oa_hv_of(oa_get(aTHX_ doc, "components")) : NULL;
    HV *sch  = comp ? oa_hv_of(oa_get(aTHX_ comp, "schemas"))   : NULL;
    SV **e   = sch  ? hv_fetch(sch, nm, (I32)nl, 0) : NULL;
    return (e && *e && oa_hv_of(*e)) ? *e : NULL;
}

#define OA_ARR_MAX_DEPTH 8

/* Is this schema an array? `type` decides it directly, but the type may sit
 * behind a $ref or inside an allOf/oneOf/anyOf - and that matters, because
 * this is what tells the query parser to accumulate repeat keys. Reading only
 * a literal `type` meant an array declared through a component was invisible,
 * so ?v=a&v=b collapsed to the last value alone. Bounded, because a document
 * can point a $ref at itself. */
static int oa_schema_is_type(pTHX_ oa_api *a, SV *schema, int depth,
                             const char *tn, STRLEN tnl) {
    HV *h = oa_hv_of(schema);
    SV *t, *r;
    int k;
    static const char *const unions[] = { "allOf", "oneOf", "anyOf", NULL };

    if (!h || depth > OA_ARR_MAX_DEPTH) return 0;

    t = oa_get(aTHX_ h, "type");
    if (t) {
        if (!SvROK(t)) { STRLEN l; const char *p = SvPV_const(t, l);
                         if (l == tnl && memEQ(p, tn, tnl)) return 1; }
        else {
            AV *av = oa_av_of(t);
            SSize_t i, n = av ? av_len(av) + 1 : 0;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                if (e && *e) { STRLEN l; const char *p = SvPV_const(*e, l);
                               if (l == tnl && memEQ(p, tn, tnl)) return 1; }
            }
        }
    }

    /* through a reference into components.schemas */
    r = oa_get(aTHX_ h, "$ref");
    if (r && !SvROK(r)) {
        STRLEN rl; const char *rp = SvPV_const(r, rl);
        if (rl > OA_COMP_PFX_LEN && memEQ(rp, OA_COMP_PFX, OA_COMP_PFX_LEN)) {
            SV *tgt = oa_comp_schema(aTHX_ a, rp + OA_COMP_PFX_LEN,
                                     rl - OA_COMP_PFX_LEN);
            if (tgt && oa_schema_is_type(aTHX_ a, tgt, depth + 1, tn, tnl))
                return 1;
        }
    }

    /* or inside a union: one member is enough to make repeat keys right */
    for (k = 0; unions[k]; k++) {
        AV *av = oa_av_of(oa_get(aTHX_ h, unions[k]));
        SSize_t i, n = av ? av_len(av) + 1 : 0;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            if (e && *e && oa_schema_is_type(aTHX_ a, *e, depth + 1, tn, tnl))
                return 1;
        }
    }
    return 0;
}

static int oa_schema_is_array(pTHX_ oa_api *a, SV *schema, int depth) {
    return oa_schema_is_type(aTHX_ a, schema, depth, "array", 5);
}

static int oa_schema_is_object(pTHX_ oa_api *a, SV *schema, int depth) {
    return oa_schema_is_type(aTHX_ a, schema, depth, "object", 6);
}

/* The declared property names, following the same $ref and union paths the
 * type test does. Only form+explode needs them: there the members arrive as
 * separate top-level query keys and the schema is the only thing that says
 * which of them belong to this parameter. Returns a new AV ref, or NULL. */
static void oa_schema_props_into(pTHX_ oa_api *a, SV *schema, int depth,
                                 AV *out) {
    HV *h = oa_hv_of(schema);
    HV *props;
    SV *r;
    int k;
    static const char *const unions[] = { "allOf", "oneOf", "anyOf", NULL };

    if (!h || depth > OA_ARR_MAX_DEPTH) return;

    props = oa_hv_of(oa_get(aTHX_ h, "properties"));
    if (props) {
        HE *he;
        hv_iterinit(props);
        while ((he = hv_iternext(props))) {
            I32 kl; const char *kp = hv_iterkey(he, &kl);
            av_push(out, newSVpvn(kp, (STRLEN)kl));
        }
    }

    r = oa_get(aTHX_ h, "$ref");
    if (r && !SvROK(r)) {
        STRLEN rl; const char *rp = SvPV_const(r, rl);
        if (rl > OA_COMP_PFX_LEN && memEQ(rp, OA_COMP_PFX, OA_COMP_PFX_LEN)) {
            SV *tgt = oa_comp_schema(aTHX_ a, rp + OA_COMP_PFX_LEN,
                                     rl - OA_COMP_PFX_LEN);
            if (tgt) oa_schema_props_into(aTHX_ a, tgt, depth + 1, out);
        }
    }
    for (k = 0; unions[k]; k++) {
        AV *av = oa_av_of(oa_get(aTHX_ h, unions[k]));
        SSize_t i, n = av ? av_len(av) + 1 : 0;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            if (e && *e) oa_schema_props_into(aTHX_ a, *e, depth + 1, out);
        }
    }
}

static SV *oa_schema_props(pTHX_ oa_api *a, SV *schema) {
    AV *out = newAV();
    oa_schema_props_into(aTHX_ a, schema, 0, out);
    if (av_len(out) < 0) { SvREFCNT_dec((SV *)out); return NULL; }
    return newRV_noinc((SV *)out);
}

/* ---- JSON booleans ----------------------------------------------------------
 *
 * A document's `false` does NOT arrive as a plain 0. File::Raw::JSON yields a
 * blessed Boolean, and the \0 idiom is a scalar ref - and a reference is TRUE
 * to C's SvTRUE, whatever it points at. So reading `readOnly: false` or
 * `explode: false` with SvTRUE gets the answer exactly backwards, silently,
 * for every real specification.
 *
 * These two are the only correct way to read a boolean that came out of a
 * document. Moved here from oa_normalize.h because oa_compile.h is included
 * first and most of the reads are in the compiler. */
static int oa_sv_is_json_bool(pTHX_ SV *sv) {
    SV *rv;
    PERL_UNUSED_CONTEXT;
    if (!sv || !SvROK(sv)) return 0;
    rv = SvRV(sv);
    return !(SvTYPE(rv) == SVt_PVHV || SvTYPE(rv) == SVt_PVAV
             || SvTYPE(rv) == SVt_PVCV);
}

static int oa_sv_truthy(pTHX_ SV *sv) {
    if (!sv || !SvOK(sv)) return 0;
    if (SvROK(sv)) {
        SV *rv = SvRV(sv);
        if (SvTYPE(rv) == SVt_PVHV || SvTYPE(rv) == SVt_PVAV) return 1;
        return SvTRUE(rv) ? 1 : 0;
    }
    return SvTRUE(sv) ? 1 : 0;
}

/* A Components Object key: the specification fixes the alphabet. */
static int oa_key_ok(const char *k, STRLEN l) {
    STRLEN i;
    if (!l) return 0;
    for (i = 0; i < l; i++) {
        char c = k[i];
        if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
              || (c >= '0' && c <= '9') || c == '.' || c == '-' || c == '_'))
            return 0;
    }
    return 1;
}

/* `MUST be in the format of a URL` (Contact) and `MUST be in the form of an
 * absolute URI` (the XML Object's namespace) are the same test here: a scheme
 * followed by a colon, and no whitespace anywhere.
 *
 * Deliberately loose. A full URI grammar would refuse documents that work, and
 * a false refusal is worse than a missed typo: nothing in this library
 * dereferences either field, so the only value of the check is catching a
 * value that was never a URL at all. Anything with a scheme passes. */
static int oa_looks_like_url(pTHX_ SV *sv) {
    STRLEN l, i;
    const char *p;
    if (!sv || !SvOK(sv)) return 1;
    p = SvPV_const(sv, l);
    if (!l) return 0;
    for (i = 0; i < l; i++)
        if (p[i] == ' ' || p[i] == '\t' || p[i] == '\n' || p[i] == '\r')
            return 0;
    /* scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." ) ":" */
    if (!((p[0] >= 'A' && p[0] <= 'Z') || (p[0] >= 'a' && p[0] <= 'z')))
        return 0;
    for (i = 1; i < l; i++) {
        char c = p[i];
        if (c == ':') return i > 0;
        if (!((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
              || (c >= '0' && c <= '9') || c == '+' || c == '-' || c == '.'))
            return 0;
    }
    return 0;
}

/* `MUST be in the format of an email address`. Loose for the same reason: one
 * `@` with something either side, and no whitespace. The local part of a real
 * address can contain almost anything, so anything stricter would refuse
 * addresses that deliver. */
static int oa_looks_like_email(pTHX_ SV *sv) {
    STRLEN l, i;
    const char *p;
    STRLEN at = 0;
    int seen = 0;
    if (!sv || !SvOK(sv)) return 1;
    p = SvPV_const(sv, l);
    if (!l) return 0;
    for (i = 0; i < l; i++) {
        char c = p[i];
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r') return 0;
        if (c == '@') { if (seen) return 0; seen = 1; at = i; }
    }
    return (seen && at > 0 && at < l - 1) ? 1 : 0;
}

/* An External Documentation Object requires a `url`. It can hang off the
 * document root, an operation, a tag or a schema, so the check lives here and
 * every one of those sites calls it rather than repeating the shape. `where`
 * names the position for the message, because "externalDocs has no url" on a
 * document with thirty operations is not an actionable complaint. */
static void oa_ext_docs_ok(pTHX_ SV *xd, const char *where) {
    HV *h;
    if (!xd || !SvROK(xd) || SvTYPE(SvRV(xd)) != SVt_PVHV) return;
    h = (HV *)SvRV(xd);
    if (!hv_exists(h, "url", 3))
        croak("Open::API: %s: externalDocs has no 'url' (it is required)",
              where);
}

/* case-insensitive equality. Defined here rather than beside its users
 * because media types, header names and scheme names are all compared this
 * way and this is the first header that needs one. */
static int oa_ci_eq(const char *a, STRLEN al, const char *b, STRLEN bl) {
    STRLEN i;
    if (al != bl) return 0;
    for (i = 0; i < al; i++)
        if (toLOWER((U8)a[i]) != toLOWER((U8)b[i])) return 0;
    return 1;
}

/* A media type we have a decoder for: `application/json` itself, or any
 * `+json`-suffixed relative (`application/vnd.api+json`, `application/hal+json`).
 *
 * Media types are case-insensitive (RFC 7231) and any parameters after `;`
 * are not part of the type, so both are handled here - this is the one place
 * that decides, for request bodies, responses and parameter `content` alike.
 *
 * The suffix test is a real suffix test. Until 0.13 this was a PREFIX test
 * whose comment claimed it matched `+json` relatives; it could not, because
 * `application/vnd.api+json` does not begin with `application/json`. The same
 * missing delimiter check made `application/json-seq` match as JSON and then
 * fail to decode. */
/* The media type proper: leading space skipped, stopped at `;`, trailing
 * space trimmed. One place, so every predicate below agrees about where a
 * media type ends - `application/json; charset=utf-8` is JSON, and
 * `multipart/form-data; boundary=xx` is multipart. */
static void oa_ctype_span(const char *p, STRLEN l, STRLEN *bo, STRLEN *eo) {
    STRLEN b = 0, e;
    while (b < l && isSPACE((U8)p[b])) b++;
    e = b;
    while (e < l && p[e] != ';') e++;
    while (e > b && isSPACE((U8)p[e - 1])) e--;
    *bo = b; *eo = e;
}

static int oa_ctype_is_json(const char *p, STRLEN l) {
    STRLEN b, e;
    oa_ctype_span(p, l, &b, &e);
    if (e - b == 16 && oa_ci_eq(p + b, 16, "application/json", 16)) return 1;
    return (e - b) > 5 && oa_ci_eq(p + e - 5, 5, "+json", 5);
}

static int oa_ctype_is_form(const char *p, STRLEN l) {
    STRLEN b, e;
    oa_ctype_span(p, l, &b, &e);
    return e - b == 33
        && oa_ci_eq(p + b, 33, "application/x-www-form-urlencoded", 33);
}

static int oa_ctype_is_multipart(const char *p, STRLEN l) {
    STRLEN b, e;
    oa_ctype_span(p, l, &b, &e);
    return e - b == 19 && oa_ci_eq(p + b, 19, "multipart/form-data", 19);
}

/* A media range: the catch-all, or a type followed by a wildcard subtype. */
static int oa_ctype_is_range(const char *p, STRLEN l) {
    STRLEN b, e;
    oa_ctype_span(p, l, &b, &e);
    return (e - b) >= 3 && p[e - 1] == '*' && p[e - 2] == '/';
}

/* Which decoder a media type wants. OA_MT_RANGE is not a decoder: it says the
 * declared entry is a range, so the decision belongs to the REQUEST's own
 * content type at validate time. Anything else we cannot decode is OPAQUE and
 * passes through untouched - a declared text/plain must keep behaving exactly
 * as it always has. */
enum { OA_MT_OPAQUE = 0, OA_MT_JSON, OA_MT_FORM, OA_MT_MULTIPART, OA_MT_RANGE };

static int oa_ctype_kind(const char *p, STRLEN l) {
    if (oa_ctype_is_range(p, l))     return OA_MT_RANGE;
    if (oa_ctype_is_json(p, l))      return OA_MT_JSON;
    if (oa_ctype_is_form(p, l))      return OA_MT_FORM;
    if (oa_ctype_is_multipart(p, l)) return OA_MT_MULTIPART;
    return OA_MT_OPAQUE;
}

/* Does a DECLARED media type cover an ACTUAL one? Exact, or a range. */
static int oa_ctype_matches(const char *d, STRLEN dl, const char *a, STRLEN al) {
    STRLEN db, de, ab, ae;
    oa_ctype_span(d, dl, &db, &de);
    oa_ctype_span(a, al, &ab, &ae);
    if (de - db == 3 && memEQ(d + db, "*/*", 3)) return 1;
    if ((de - db) > 2 && d[de - 1] == '*' && d[de - 2] == '/') {
        STRLEN tl = de - db - 2, i = 0;
        const char *as = a + ab;
        while (ab + i < ae && as[i] != '/') i++;
        return i == tl && oa_ci_eq(d + db, tl, as, tl);
    }
    return oa_ci_eq(d + db, de - db, a + ab, ae - ab);
}

/* Does a declared response key cover this status? Exact first, then a range
 * key (`2XX`), then `default` - the precedence OpenAPI gives them. `want` is
 * the decimal status as text.
 *
 * Both the server (oa_plack.h) and the client (oa_client.h) choose a response
 * schema, and they used to do it with a copy each of an exact-then-`default`
 * loop. A range key matched neither, so a document written with `2XX`/`4XX`
 * compiled schemas that were never selected and never applied. One helper, so
 * the two cannot disagree about which schema governs a response. */
static int oa_status_covers(const char *key, STRLEN kl,
                            const char *want, STRLEN wl) {
    if (kl == wl && memEQ(key, want, kl)) return 1;
    if (kl == 7 && memEQ(key, "default", 7)) return 0;   /* caller's last pass */
    if (kl == 3 && wl == 3 && key[0] == want[0]
        && (key[1] == 'X' || key[1] == 'x')
        && (key[2] == 'X' || key[2] == 'x')) return 1;
    return 0;
}

/* ---- the schema keyword tables ---------------------------------------------
 *
 * Where a Schema Object can actually appear. Used by the 3.0 converter in
 * oa_normalize.h and by the readOnly/writeOnly projection below, which must
 * walk the same positions and no others: `example`, `default` and `enum` hold
 * arbitrary user JSON that may itself contain a key called `properties`. */

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

/* JSF resolves same-document $refs against schema locations it knows -
 * `#/$defs/Name` works, arbitrary keys like `#/components/schemas/Name` do
 * not. So at compile time every extracted schema is deep-copied with its
 * refs REWRITTEN (#/components/schemas/X -> #/$defs/X) and the spec's
 * components.schemas - itself rewritten once, since schemas reference each
 * other - is attached as a shared $defs. */

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

/* ---- the readOnly / writeOnly projection ------------------------------------
 *
 * `readOnly` says a property may come back in a response but should not be
 * sent in a request; `writeOnly` is the mirror. And a `required` property that
 * is readOnly is required of RESPONSES only - so the same component means two
 * different things depending on which way the payload is travelling.
 *
 * None of that can be decided while validating: once a schema is compiled JSF
 * owns the traversal, exactly as with `discriminator`. So it is expanded into
 * 2020-12 constructs here, at compile time, per direction. A forbidden
 * property becomes `{not:{}}` - always false, so its presence fails - spelled
 * as a hashref because JSF refuses the \0 JSON-false idiom and a bare 0 would
 * encode as a number and stop being valid JSON Schema on the wire.
 *
 * Only the positions where a Schema Object can appear are descended, for the
 * reason the 3.0 converter has the same rule: `example`, `default` and `enum`
 * hold user JSON that may itself contain a key called `properties`. */

#define OA_DIR_NONE 0
#define OA_DIR_REQ  1   /* a request: readOnly is forbidden  */
#define OA_DIR_RESP 2   /* a response: writeOnly is forbidden */
#define OA_PROJ_MAX_DEPTH 128

static int oa_flagged(pTHX_ SV *sv, const char *flag) {
    HV *h = oa_hv_of(sv);
    SV *v = h ? oa_get(aTHX_ h, flag) : NULL;
    return (v && oa_sv_truthy(aTHX_ v)) ? 1 : 0;
}

/* Does the document mention the flag anywhere? A false positive (the word
 * inside an `example`) only costs a projection nobody consults; a false
 * negative would silently disable the feature, so this scan is deliberately
 * blunt rather than position-aware. */
static int oa_uses_flag(pTHX_ SV *node, const char *flag, int depth) {
    SV *rv;
    if (!node || depth > OA_PROJ_MAX_DEPTH || !SvROK(node)) return 0;
    rv = SvRV(node);
    if (SvTYPE(rv) == SVt_PVHV) {
        HV *h = (HV *)rv;
        HE *he;
        STRLEN fl = strlen(flag);
        hv_iterinit(h);
        while ((he = hv_iternext(h))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            SV *v = hv_iterval(h, he);
            if ((STRLEN)kl == fl && memEQ(k, flag, fl)
                && v && oa_sv_truthy(aTHX_ v)) return 1;
            if (oa_uses_flag(aTHX_ v, flag, depth + 1)) return 1;
        }
        return 0;
    }
    if (SvTYPE(rv) == SVt_PVAV) {
        AV *av = (AV *)rv;
        SSize_t i, n = av_len(av) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            if (e && *e && oa_uses_flag(aTHX_ *e, flag, depth + 1)) return 1;
        }
    }
    return 0;
}

static SV *oa_project(pTHX_ SV *node, const char *flag, int depth);

/* project each value of a map-of-schemas / each element of a list-of-schemas */
static SV *oa_project_map(pTHX_ SV *v, const char *flag, int depth) {
    HV *src = oa_hv_of(v), *dst;
    HE *he;
    if (!src) return newSVsv(v);
    dst = newHV();
    hv_iterinit(src);
    while ((he = hv_iternext(src))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        (void)hv_store(dst, k, kl,
                       oa_project(aTHX_ hv_iterval(src, he), flag, depth + 1), 0);
    }
    return newRV_noinc((SV *)dst);
}

static SV *oa_project_list(pTHX_ SV *v, const char *flag, int depth) {
    AV *src = oa_av_of(v), *dst;
    SSize_t i, n;
    if (!src) return newSVsv(v);
    dst = newAV();
    n = av_len(src) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(src, i, 0);
        av_push(dst, oa_project(aTHX_ (e && *e) ? *e : NULL, flag, depth + 1));
    }
    return newRV_noinc((SV *)dst);
}

static SV *oa_project(pTHX_ SV *node, const char *flag, int depth) {
    HV *src, *dst, *drop = NULL;
    SV *props;
    HE *he;
    if (!node || depth > OA_PROJ_MAX_DEPTH || !SvROK(node)) return newSVsv(node);
    if (SvTYPE(SvRV(node)) != SVt_PVHV) return newSVsv(node);
    src = (HV *)SvRV(node);
    dst = newHV();

    /* `properties` first: it is the only place the flag is read, and what it
     * finds decides which names have to come out of `required` below. */
    props = oa_get(aTHX_ src, "properties");
    if (oa_hv_of(props)) {
        HV *ph = (HV *)SvRV(props), *np = newHV();
        HE *pe;
        hv_iterinit(ph);
        while ((pe = hv_iternext(ph))) {
            I32 pkl; const char *pk = hv_iterkey(pe, &pkl);
            SV *pv = hv_iterval(ph, pe);
            if (oa_flagged(aTHX_ pv, flag)) {
                HV *no = newHV();
                (void)hv_stores(no, "not", newRV_noinc((SV *)newHV()));
                (void)hv_store(np, pk, pkl, newRV_noinc((SV *)no), 0);
                if (!drop) drop = (HV *)sv_2mortal((SV *)newHV());
                (void)hv_store(drop, pk, pkl, newSViv(1), 0);
            }
            else (void)hv_store(np, pk, pkl,
                                oa_project(aTHX_ pv, flag, depth + 1), 0);
        }
        (void)hv_stores(dst, "properties", newRV_noinc((SV *)np));
    }

    hv_iterinit(src);
    while ((he = hv_iternext(src))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        SV *v = hv_iterval(src, he);
        if (kl == 10 && memEQ(k, "properties", 10)) continue;   /* done above */
        if (drop && kl == 8 && memEQ(k, "required", 8)) {
            AV *ra = oa_av_of(v), *keep = newAV();
            SSize_t j, rn = ra ? av_len(ra) + 1 : 0;
            for (j = 0; j < rn; j++) {
                SV **e = av_fetch(ra, j, 0);
                STRLEN nl; const char *np2;
                if (!e || !*e) continue;
                np2 = SvPV_const(*e, nl);
                if (hv_exists(drop, np2, (I32)nl)) continue;   /* other direction */
                av_push(keep, newSVsv(*e));
            }
            /* an emptied `required` is deleted, not left as [] - JSON Schema
             * allows the empty array but it is noise in ->spec and in errors */
            if (av_len(keep) >= 0)
                (void)hv_store(dst, k, kl, newRV_noinc((SV *)keep), 0);
            else SvREFCNT_dec((SV *)keep);
            continue;
        }
        /* `items` is a Schema Object but appears in none of the three tables:
         * the converter special-cases it for the 3.0 tuple form, which by now
         * has already become prefixItems. Both shapes are handled anyway. */
        if (kl == 5 && memEQ(k, "items", 5)) {
            (void)hv_store(dst, k, kl,
                           oa_av_of(v) ? oa_project_list(aTHX_ v, flag, depth)
                                       : oa_project(aTHX_ v, flag, depth + 1), 0);
            continue;
        }
        if (oa_kw_schema(k, kl)) {
            (void)hv_store(dst, k, kl, oa_project(aTHX_ v, flag, depth + 1), 0);
            continue;
        }
        if (oa_kw_schema_map(k, kl)) {
            (void)hv_store(dst, k, kl, oa_project_map(aTHX_ v, flag, depth), 0);
            continue;
        }
        if (oa_kw_schema_list(k, kl)) {
            (void)hv_store(dst, k, kl, oa_project_list(aTHX_ v, flag, depth), 0);
            continue;
        }
        (void)hv_store(dst, k, kl, newSVsv(v), 0);   /* user JSON: untouched */
    }
    return newRV_noinc((SV *)dst);
}

/* Build the shared $defs (rewritten components.schemas) once per api, plus a
 * projection of it per direction when the document uses readOnly/writeOnly. */
static void oa_build_defs(pTHX_ oa_api *a) {
    HV *doc  = (HV *)SvRV(a->spec);
    HV *comp = oa_hv_of(oa_get(aTHX_ doc, "components"));
    SV *schemas = comp ? oa_get(aTHX_ comp, "schemas") : NULL;

    a->proj_req  = oa_uses_flag(aTHX_ a->spec, "readOnly", 0);
    a->proj_resp = oa_uses_flag(aTHX_ a->spec, "writeOnly", 0);

    if (schemas && oa_hv_of(schemas)) {
        a->defs = oa_keep(aTHX_ a, oa_rewrite_refs(aTHX_ schemas));
        /* projected from the REWRITTEN defs, so a $ref from a request body
         * reaches the request-projected component transitively.
         *
         * oa_project_MAP, not oa_project: a defs block is `name => schema`,
         * not a schema. Handed to oa_project it finds no `properties` on the
         * map, treats every component name as an unknown keyword and copies
         * it through untouched - so the projection silently did nothing and
         * only inline schemas were ever direction-aware. */
        if (a->proj_req)
            a->defs_req = oa_keep(aTHX_ a,
                                  oa_project_map(aTHX_ a->defs, "readOnly", 0));
        if (a->proj_resp)
            a->defs_resp = oa_keep(aTHX_ a,
                                   oa_project_map(aTHX_ a->defs, "writeOnly", 0));
    }
}

/* Rewrite a schema's refs, attach the shared $defs, compile via the JSF ABI.
 * The returned handle is owned by the keep AV. */
static SV *oa_compile_schema(pTHX_ oa_api *a, SV *schema, int coerce, int dir) {
    SV *to = schema;
    SV *defs = a->defs;
    /* Which way is this payload travelling? A request forbids readOnly, a
     * response forbids writeOnly, and each reaches its own projection of the
     * components so a $ref lands on the right variant. OA_DIR_NONE, and a
     * document that never uses either flag, compile down the original path. */
    if (dir == OA_DIR_REQ) {
        if (a->defs_req) defs = a->defs_req;
        if (a->proj_req) schema = sv_2mortal(oa_project(aTHX_ schema, "readOnly", 0));
    }
    else if (dir == OA_DIR_RESP) {
        if (a->defs_resp) defs = a->defs_resp;
        if (a->proj_resp) schema = sv_2mortal(oa_project(aTHX_ schema, "writeOnly", 0));
    }
    to = schema;
    if (defs && oa_hv_of(schema)) {
        SV *rw = sv_2mortal(oa_rewrite_refs(aTHX_ schema));
        HV *w  = (HV *)SvRV(rw);
        SV **own = hv_fetchs(w, "$defs", 0);
        if (own && *own && oa_hv_of(*own)) {
            /* schema carries its own $defs: overlay ours underneath */
            HV *merged = newHV(), *shared = (HV *)SvRV(defs), *mine;
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
            (void)hv_stores(w, "$defs", SvREFCNT_inc(defs));
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
        pp->required = (l == OA_IN_PATH) ? 1
                     : (req && oa_sv_truthy(aTHX_ req)) ? 1 : 0;
        pp->ctype    = NULL;
        pp->is_array  = schema ? oa_schema_is_array(aTHX_ a, schema, 0) : 0;
        pp->is_object = schema ? oa_schema_is_object(aTHX_ a, schema, 0) : 0;
        /* only form+explode reads these, but the schema is here and the
         * request path is not the place to walk it */
        pp->props     = (pp->is_object && schema)
                      ? oa_schema_props(aTHX_ a, schema) : NULL;
        pp->handle   = schema
            ? oa_compile_schema(aTHX_ a, schema, 1, OA_DIR_REQ) : NULL;

        /* How the value is spelled on the wire. The default follows the
         * location: `simple` in a path or header, `form` in a query or
         * cookie; `explode` defaults to true for `form` alone. An unknown
         * style is left at the default rather than refused - the document is
         * still a valid document, and refusing here would reject specs that
         * work against other tools. */
        {
            SV *st = oa_get(aTHX_ ph, "style");
            SV *ex = oa_get(aTHX_ ph, "explode");
            pp->style = (l == OA_IN_PATH || l == OA_IN_HEADER)
                        ? OA_ST_SIMPLE : OA_ST_FORM;
            if (st) {
                STRLEN sl; const char *sp = SvPV_const(st, sl);
                if      (sl ==  6 && memEQ(sp, "simple", 6))           pp->style = OA_ST_SIMPLE;
                else if (sl ==  5 && memEQ(sp, "label", 5))            pp->style = OA_ST_LABEL;
                else if (sl ==  6 && memEQ(sp, "matrix", 6))           pp->style = OA_ST_MATRIX;
                else if (sl ==  4 && memEQ(sp, "form", 4))             pp->style = OA_ST_FORM;
                else if (sl == 14 && memEQ(sp, "spaceDelimited", 14))  pp->style = OA_ST_SPACE;
                else if (sl == 13 && memEQ(sp, "pipeDelimited", 13))   pp->style = OA_ST_PIPE;
                else if (sl == 10 && memEQ(sp, "deepObject", 10))      pp->style = OA_ST_DEEP;
            }
            pp->explode = ex ? (oa_sv_truthy(aTHX_ ex) ? 1 : 0)
                             : (pp->style == OA_ST_FORM ? 1 : 0);
        }
        {   /* reported to consumers; the specification gives it no effect on
             * validation, so it is carried rather than enforced */
            SV *dep = oa_get(aTHX_ ph, "deprecated");
            pp->deprecated = (dep && oa_sv_truthy(aTHX_ dep)) ? 1 : 0;
        }
        {   /* allowEmptyValue: `?flag=` is present with no value. 3.1
             * deprecates the keyword and its semantics are under-specified,
             * so the reading here is the narrow one that can be defended:
             * a QUERY parameter whose value is the empty string is permitted
             * rather than pushed at its schema. Everywhere else it is
             * ignored, which is what the specification asks for. */
            SV *ae = oa_get(aTHX_ ph, "allowEmptyValue");
            pp->allow_empty = (l == OA_IN_QUERY
                               && ae && oa_sv_truthy(aTHX_ ae)) ? 1 : 0;
        }
        {   /* allowReserved: reserved characters MAY be sent without
             * percent-encoding. Query only. The specification also allows it
             * on a path parameter, but a reserved character in a path segment
             * changes the SHAPE of the path, so honouring it there would be a
             * bug wearing a feature's clothes. */
            SV *ar = oa_get(aTHX_ ph, "allowReserved");
            pp->allow_reserved = (l == OA_IN_QUERY
                                  && ar && oa_sv_truthy(aTHX_ ar)) ? 1 : 0;
        }

        /* `content` instead of `schema`: the value is a document, not a
         * string standing in for one. The spec allows exactly one entry, so
         * the first is the one - and it is compiled WITHOUT coercion, unlike
         * an ordinary parameter, because a decoded JSON document already has
         * the types the schema is talking about. */
        if (!schema) {
            HV *content = oa_hv_of(oa_get(aTHX_ ph, "content"));
            HE *he;
            /* the map MUST contain exactly one entry: it says what the single
             * value on the wire is, and two answers is no answer */
            if (content && HvUSEDKEYS(content) > 1)
                croak("Open::API: parameter '%s' on %s declares %d content "
                      "entries; the map must contain only one",
                      SvPV_nolen(name), SvPV_nolen(o->op_id),
                      (int)HvUSEDKEYS(content));
            if (content && HvUSEDKEYS(content)) {
                hv_iterinit(content);
                if ((he = hv_iternext(content))) {
                    I32 ckl; const char *ck = hv_iterkey(he, &ckl);
                    HV *media = oa_hv_of(hv_iterval(content, he));
                    SV *cs = media ? oa_get(aTHX_ media, "schema") : NULL;
                    pp->ctype = oa_keep(aTHX_ a, newSVpvn(ck, (STRLEN)ckl));
                    if (cs && oa_ctype_is_json(ck, (STRLEN)ckl))
                        pp->handle = oa_compile_schema(aTHX_ a, cs, 0, OA_DIR_REQ);
                }
            }
        }
    }
}

/* ---- requestBody / responses ----------------------------------------------- */

static void oa_compile_body(pTHX_ oa_api *a, oa_op *o, SV *rb) {
    HV *rbh = oa_hv_of(rb);
    HV *content;
    HE *he;
    int n = 0, i = 0;
    if (!rbh) return;
    {
        SV *req = oa_get(aTHX_ rbh, "required");
        o->body_required = (req && oa_sv_truthy(aTHX_ req)) ? 1 : 0;
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
        int kind = oa_ctype_kind(k, (STRLEN)kl);
        o->bodies[i].ctype  = oa_keep(aTHX_ a, newSVpvn(k, (STRLEN)kl));
        o->bodies[i].kind   = kind;
        /* A handle is compiled for every type we can decode, and for a range,
         * whose decoder is chosen from the request. OPAQUE gets none, so a
         * declared text/plain keeps passing through with its body preserved -
         * the behaviour t/06-body.t pins and the petstore fixtures rely on.
         *
         * Form bodies are coerced, like parameters: every value arrives as
         * text, so `count=3` has to satisfy an integer the way `?count=3`
         * does. JSON already carries its own types. */
        o->bodies[i].handle = (schema && kind != OA_MT_OPAQUE)
            ? oa_compile_schema(aTHX_ a, schema,
                                (kind == OA_MT_FORM || kind == OA_MT_MULTIPART),
                                OA_DIR_REQ)
            : NULL;
        /* An Encoding Object says how each PROPERTY of a form body is
         * serialized. It has meaning only where a form body is parsed into
         * properties in the first place, so it is kept for form and multipart
         * and ignored elsewhere - a JSON body already carries its own types. */
        {
            SV *enc = media ? oa_get(aTHX_ media, "encoding") : NULL;
            o->bodies[i].encoding =
                (enc && oa_hv_of(enc)
                     && (kind == OA_MT_FORM || kind == OA_MT_MULTIPART))
                ? oa_keep(aTHX_ a, newSVsv(enc)) : NULL;
        }
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
        /* description is REQUIRED on a Response Object. Checked BEFORE the
         * `content` early-return below, or a response with neither would be
         * skipped rather than refused. */
        if (robj && !oa_get(aTHX_ robj, "description"))
            croak("Open::API: %s: response '%.*s' has no description",
                  SvPV_nolen(o->op_id), (int)skl, sk);
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
            rows[n].handle = oa_compile_schema(aTHX_ a, schema, 0, OA_DIR_RESP);
            n++;
        }
    }
    o->resps  = rows;
    o->nresps = n;

    /* Headers, in a second pass, because they hang off the STATUS and not the
     * media type. Two consequences the loop above cannot express: a status
     * declaring two content types must not carry two copies of its headers,
     * and a status with headers but no JSON body - 204, or a 3xx carrying
     * Location - compiles no row above at all yet still has headers to check.
     *
     * A Header Object is a Parameter Object without `name`/`in`, so each one
     * fills an oa_param and oa_check_param applies unchanged. Compiled with
     * coercion on, as parameters are: a header value arrives as text. */
    {
        int hcap = 0, hn = 0;
        oa_rhdr *hrows = NULL;
        hv_iterinit(rh);
        while ((she = hv_iternext(rh))) {
            I32 skl; const char *sk = hv_iterkey(she, &skl);
            HV *robj = oa_hv_of(hv_iterval(rh, she));
            HV *hdrs = robj ? oa_hv_of(oa_get(aTHX_ robj, "headers")) : NULL;
            HE *hhe;
            if (!hdrs) continue;
            hv_iterinit(hdrs);
            while ((hhe = hv_iternext(hdrs))) {
                I32 hkl; const char *hk = hv_iterkey(hhe, &hkl);
                HV *hobj = oa_hv_of(hv_iterval(hdrs, hhe));
                SV *hs, *hr;
                if (!hobj) continue;
                hs = oa_get(aTHX_ hobj, "schema");
                hr = oa_get(aTHX_ hobj, "required");
                if (hn == hcap) {
                    hcap = hcap ? hcap * 2 : 4;
                    hrows = (oa_rhdr *)realloc(hrows,
                                               (size_t)hcap * sizeof(oa_rhdr));
                    if (!hrows) croak("Open::API: out of memory");
                }
                hrows[hn].status     = oa_keep(aTHX_ a, newSVpvn(sk, (STRLEN)skl));
                hrows[hn].p.name     = oa_keep(aTHX_ a, newSVpvn(hk, (STRLEN)hkl));
                hrows[hn].p.required = (hr && oa_sv_truthy(aTHX_ hr)) ? 1 : 0;
                hrows[hn].p.ctype    = NULL;
                hrows[hn].p.is_array = 0;
                /* these rows come from realloc, NOT calloc: every field has
                 * to be assigned or it reads uninitialised memory */
                hrows[hn].p.is_object   = 0;
                hrows[hn].p.props       = NULL;
                hrows[hn].p.style       = OA_ST_SIMPLE;
                hrows[hn].p.explode     = 0;
                hrows[hn].p.deprecated     = 0;
                hrows[hn].p.allow_empty    = 0;
                hrows[hn].p.allow_reserved = 0;
                hrows[hn].p.handle   = hs
                    ? oa_compile_schema(aTHX_ a, hs, 1, OA_DIR_RESP) : NULL;
                hn++;
            }
        }
        o->rhdrs  = hrows;
        o->nrhdrs = hn;
    }
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
                s->type = OA_SEC_OTHER;   /* digest and friends: the checker's */
        } else if ((tl == 6 && memEQ(tp, "oauth2", 6))
                || (tl == 13 && memEQ(tp, "openIdConnect", 13))) {
            s->type     = OA_SEC_BEARER;  /* the credential is the access token */
            s->oauthish = 1;              /* only these two may carry scopes */
            /* Flow automation is out of scope, but the DECLARATION still has
             * required fields, and a document that omits them is not a valid
             * document. Accepting it means trusting a description nobody
             * checked. */
            if (tl == 13) {
                if (!oa_get(aTHX_ sh, "openIdConnectUrl"))
                    croak("Open::API: openIdConnect scheme '%.*s' has no "
                          "openIdConnectUrl", (int)kl, k);
            } else {
                HV *flows = oa_hv_of(oa_get(aTHX_ sh, "flows"));
                HE *fhe;
                if (!flows)
                    croak("Open::API: oauth2 scheme '%.*s' has no flows",
                          (int)kl, k);
                hv_iterinit(flows);
                while ((fhe = hv_iternext(flows))) {
                    I32 fkl; const char *fk = hv_iterkey(fhe, &fkl);
                    HV *fl = oa_hv_of(hv_iterval(flows, fhe));
                    int wants_auth  = (fkl ==  8 && memEQ(fk, "implicit", 8))
                                   || (fkl == 17 && memEQ(fk, "authorizationCode", 17));
                    int wants_token = (fkl ==  8 && memEQ(fk, "password", 8))
                                   || (fkl == 17 && memEQ(fk, "clientCredentials", 17))
                                   || (fkl == 17 && memEQ(fk, "authorizationCode", 17));
                    if (!fl)
                        croak("Open::API: oauth2 scheme '%.*s': flow '%.*s' is "
                              "not an object", (int)kl, k, (int)fkl, fk);
                    if (!oa_get(aTHX_ fl, "scopes"))
                        croak("Open::API: oauth2 scheme '%.*s': flow '%.*s' has "
                              "no scopes", (int)kl, k, (int)fkl, fk);
                    if (wants_auth && !oa_get(aTHX_ fl, "authorizationUrl"))
                        croak("Open::API: oauth2 scheme '%.*s': flow '%.*s' has "
                              "no authorizationUrl", (int)kl, k, (int)fkl, fk);
                    if (wants_token && !oa_get(aTHX_ fl, "tokenUrl"))
                        croak("Open::API: oauth2 scheme '%.*s': flow '%.*s' has "
                              "no tokenUrl", (int)kl, k, (int)fkl, fk);
                }
            }
        } else if (tl == 9 && memEQ(tp, "mutualTLS", 9)) {
            s->type = OA_SEC_OTHER;    /* settled by the transport */
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
            /* Only oauth2 and openIdConnect may name scopes. For every other
             * scheme the specification says the list MUST be empty, and a
             * document asking for scopes on an apiKey is describing something
             * that cannot happen. */
            {
                AV *sc = oa_av_of(scopes);
                if (sc && av_len(sc) >= 0 && !t->schemes[idx].oauthish)
                    /* "named" matters: a scheme's NAME is free, so one called
                     * "apiKey" can be declared `type: http`, and a message
                     * saying only "scheme 'apiKey'" reads like the type */
                    croak("Open::API: %s: the security scheme NAMED '%.*s' is "
                          "declared as neither oauth2 nor openIdConnect, so "
                          "the scopes listed for it here must be an empty list",
                          where, (int)kl, k);
            }
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

/* The path prefix the first Server Object's URL carries, with {variables}
 * expanded from their declared defaults: `https://h.test/api/v1` yields
 * `/api/v1`, and a URL with no path (or a bare `/`) yields nothing to strip.
 * A relative URL is all path. Called only when the caller opted in. */
/* The prefix a `servers` array's first entry carries, as a kept SV, or NULL.
 * Shared by the document level and by a path item or operation declaring its
 * own - the specification lets any of the three, most specific winning. */
static SV *oa_server_prefix_of(pTHX_ oa_api *a, AV *srv) {
    SV **e   = srv ? av_fetch(srv, 0, 0) : NULL;
    HV *s0   = (e && *e) ? oa_hv_of(*e) : NULL;
    SV *url  = s0 ? oa_get(aTHX_ s0, "url") : NULL;
    HV *vars = s0 ? oa_hv_of(oa_get(aTHX_ s0, "variables")) : NULL;
    STRLEN ul, i, pathstart = 0;
    const char *up;
    SV *out;
    if (!url) return NULL;
    up = SvPV_const(url, ul);
    for (i = 0; i + 2 < ul; i++) {           /* past scheme://host */
        if (up[i] == ':' && up[i + 1] == '/' && up[i + 2] == '/') {
            STRLEN j = i + 3;
            while (j < ul && up[j] != '/') j++;
            pathstart = j;
            break;
        }
    }
    out = sv_2mortal(newSVpvs(""));
    for (i = pathstart; i < ul; i++) {
        if (up[i] == '{') {
            STRLEN j = i + 1;
            while (j < ul && up[j] != '}') j++;
            if (j < ul) {
                SV **dv = vars ? hv_fetch(vars, up + i + 1,
                                          (I32)(j - i - 1), 0) : NULL;
                HV *vh  = (dv && *dv) ? oa_hv_of(*dv) : NULL;
                SV *def = vh ? oa_get(aTHX_ vh, "default") : NULL;
                if (def) sv_catsv(out, def);
                i = j;
                continue;
            }
        }
        sv_catpvn(out, up + i, 1);
    }
    while (SvCUR(out) && SvPVX(out)[SvCUR(out) - 1] == '/')
        SvCUR_set(out, SvCUR(out) - 1);      /* a trailing / is not prefix */
    return SvCUR(out) ? oa_keep(aTHX_ a, newSVsv(out)) : NULL;
}

static void oa_set_server_prefix(pTHX_ oa_api *a) {
    HV *doc  = oa_hv_of(a->spec);
    AV *srv  = doc ? oa_av_of(oa_get(aTHX_ doc, "servers")) : NULL;
    SV **e   = srv ? av_fetch(srv, 0, 0) : NULL;
    HV *s0   = (e && *e) ? oa_hv_of(*e) : NULL;
    SV *url  = s0 ? oa_get(aTHX_ s0, "url") : NULL;
    HV *vars = s0 ? oa_hv_of(oa_get(aTHX_ s0, "variables")) : NULL;
    STRLEN ul, i, pathstart = 0;
    const char *up;
    SV *out;
    if (!url) return;
    up = SvPV_const(url, ul);

    /* past scheme://host, when there is one */
    for (i = 0; i + 2 < ul; i++) {
        if (up[i] == ':' && up[i + 1] == '/' && up[i + 2] == '/') {
            STRLEN j = i + 3;
            while (j < ul && up[j] != '/') j++;
            pathstart = j;
            break;
        }
    }

    out = sv_2mortal(newSVpvs(""));
    for (i = pathstart; i < ul; i++) {
        if (up[i] == '{') {
            STRLEN j = i + 1;
            while (j < ul && up[j] != '}') j++;
            if (j < ul) {
                SV **dv = vars ? hv_fetch(vars, up + i + 1,
                                          (I32)(j - i - 1), 0) : NULL;
                HV *vh  = (dv && *dv) ? oa_hv_of(*dv) : NULL;
                SV *def = vh ? oa_get(aTHX_ vh, "default") : NULL;
                if (def) sv_catsv(out, def);
                i = j;
                continue;
            }
        }
        sv_catpvn(out, up + i, 1);
    }
    while (SvCUR(out) && SvPVX(out)[SvCUR(out) - 1] == '/')
        SvCUR_set(out, SvCUR(out) - 1);      /* a trailing / is not prefix */
    if (SvCUR(out)) a->prefix = oa_keep(aTHX_ a, newSVsv(out));
}

/* The order the router walks the operation table in.
 *
 * Without one, the table is in `paths` hash order, which perl randomises per
 * process - so a request that two templates both fit routed to a DIFFERENT
 * operation between runs of the same document. `/t/fixed` against `/t/fixed`
 * and `/t/{id}` picked the template roughly one run in five.
 *
 * Ordering rule, applied left to right: at the first segment where two
 * templates differ in kind, the one with a LITERAL there sorts first, so a
 * concrete path is always preferred over a template that also fits. Ties are
 * broken on the path string, which makes the order total and reproducible
 * even between two templates of identical shape.
 *
 * A separate index, because by_id holds indices into `ops`. Insertion sort:
 * a document has tens of routes and this runs once, at compile.  */
static int oa_route_before(pTHX_ oa_op *x, oa_op *y) {
    int i, n = x->nsegs < y->nsegs ? x->nsegs : y->nsegs;
    STRLEN xl, yl;
    const char *xp, *yp;
    int c;
    for (i = 0; i < n; i++) {
        int xlit = x->segs[i].lit ? 1 : 0;
        int ylit = y->segs[i].lit ? 1 : 0;
        if (xlit != ylit) return xlit;      /* literal first */
    }
    if (x->nsegs != y->nsegs) return x->nsegs < y->nsegs;
    /* identical shape: order on the path, then the method, so the result does
     * not depend on which the hash happened to hand over first */
    xp = x->path ? SvPV_const(x->path, xl) : (xl = 0, "");
    yp = y->path ? SvPV_const(y->path, yl) : (yl = 0, "");
    c = memcmp(xp, yp, xl < yl ? xl : yl);
    if (c) return c < 0;
    if (xl != yl) return xl < yl;
    xp = x->method ? SvPV_const(x->method, xl) : (xl = 0, "");
    yp = y->method ? SvPV_const(y->method, yl) : (yl = 0, "");
    c = memcmp(xp, yp, xl < yl ? xl : yl);
    if (c) return c < 0;
    return xl <= yl;
}

static void oa_order_routes(pTHX_ oa_ops *t) {
    int i;
    free(t->order);
    t->order = NULL;
    if (t->n <= 0) return;
    t->order = (int *)malloc((size_t)t->n * sizeof(int));
    if (!t->order) croak("Open::API: out of memory");
    for (i = 0; i < t->n; i++) t->order[i] = i;
    for (i = 1; i < t->n; i++) {
        int cur = t->order[i];
        int j = i - 1;
        while (j >= 0 && oa_route_before(aTHX_ &t->ops[cur], &t->ops[t->order[j]])) {
            t->order[j + 1] = t->order[j];
            j--;
        }
        t->order[j + 1] = cur;
    }
}

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

    /* Two templated paths with the same hierarchy but different variable
     * names are IDENTICAL and must not both exist - /t/{a} and /t/{b} are one
     * path, and a document declaring both is asking for two routes that can
     * never be told apart. Each template is canonicalised by replacing every
     * {...} with a single placeholder, and a repeat is refused. */
    {
        HV *seen = (HV *)sv_2mortal((SV *)newHV());
        hv_iterinit(paths);
        while ((phe = hv_iternext(paths))) {
            I32 tkl; const char *tpl = hv_iterkey(phe, &tkl);
            SV *canon = sv_2mortal(newSVpvs(""));
            STRLEN q;
            /* a path field name MUST begin with a forward slash: it is
             * appended to a server URL, and one that does not would silently
             * join onto the host instead */
            if (tkl < 1 || tpl[0] != '/')
                croak("Open::API: path '%.*s' does not begin with '/'",
                      (int)tkl, tpl);
            for (q = 0; q < (STRLEN)tkl; q++) {
                if (tpl[q] == '{') {
                    while (q < (STRLEN)tkl && tpl[q] != '}') q++;
                    sv_catpvs(canon, "\1");        /* one placeholder */
                    continue;
                }
                sv_catpvn(canon, tpl + q, 1);
            }
            {
                STRLEN cl; const char *cp = SvPV_const(canon, cl);
                if (hv_exists(seen, cp, (I32)cl))
                    croak("Open::API: paths '%.*s' duplicates another path "
                          "that differs only in its template variable names",
                          (int)tkl, tpl);
                (void)hv_store(seen, cp, (I32)cl, newSViv(1), 0);
            }
        }
    }

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
            oa_ext_docs_ok(aTHX_ oa_get(aTHX_ oph, "externalDocs"), "operation");
            op_id = oa_get(aTHX_ oph, "operationId");
            if (!op_id) {
                /* operationId is OPTIONAL per the specification, so a document
                 * without one is still valid and must still compile. It is the
                 * dispatch key here, so one is derived: <method>_<path>, with
                 * the template braces dropped and separators flattened. Same
                 * rule as plan_maat_mcp/01, so the MCP tool names and the core
                 * agree on what an unnamed operation is called. A collision
                 * with a real operationId is still caught below, as it must
                 * be - two operations cannot share a dispatch key. */
                SV *d = sv_2mortal(newSVpv(oa_methods[m], 0));
                STRLEN q;
                int owed = 1;   /* a separator is owed before the next char */
                for (q = 0; q < (STRLEN)tkl; q++) {
                    char ch = tpl[q];
                    if (ch == '{' || ch == '}') continue;
                    /* a slash OWES a separator rather than emitting one, so a
                     * leading slash does not double the underscore already
                     * between method and path, and a trailing one leaves none
                     * dangling: /a -> get_a, /pets/{petId} -> get_pets_petId */
                    if (ch == '/') { owed = 1; continue; }
                    if (owed) { sv_catpvs(d, "_"); owed = 0; }
                    sv_catpvn(d, &ch, 1);
                }
                op_id = d;
            }
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
            /* A path item or an operation may declare its own `servers`, and
             * the more specific wins. Only consulted when the caller opted
             * in, exactly as the document-level prefix is: honouring a prefix
             * re-routes an application that already mounts without it. */
            if (a->prefix || a->want_servers) {
                AV *osrv = oa_av_of(oa_get(aTHX_ oph,  "servers"));
                AV *psrv = oa_av_of(oa_get(aTHX_ item, "servers"));
                if (osrv)      o->prefix = oa_server_prefix_of(aTHX_ a, osrv);
                else if (psrv) o->prefix = oa_server_prefix_of(aTHX_ a, psrv);
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

    /* A Link's operationId names "an existing, resolvable OAS operation".
     * Links are carried for consumers rather than compiled, so nothing else
     * would ever catch a dangling one.
     *
     * This runs AFTER the walk above, not inside it: a Link may point at an
     * operation declared later in the document, and refusing that would be
     * wrong. By here every operationId - declared or derived - is in by_id. */
    oa_order_routes(aTHX_ t);
    {
        HE *lphe;
        hv_iterinit(paths);
        while ((lphe = hv_iternext(paths))) {
            HV *item = oa_hv_of(hv_iterval(paths, lphe));
            int m;
            if (!item) continue;
            for (m = 0; oa_methods[m]; m++) {
                HV *oph = oa_hv_of(oa_get(aTHX_ item, oa_methods[m]));
                HV *resps = oph ? oa_hv_of(oa_get(aTHX_ oph, "responses")) : NULL;
                HE *rhe;
                if (!resps) continue;
                hv_iterinit(resps);
                while ((rhe = hv_iternext(resps))) {
                    HV *robj  = oa_hv_of(hv_iterval(resps, rhe));
                    HV *links = robj ? oa_hv_of(oa_get(aTHX_ robj, "links")) : NULL;
                    HE *lhe;
                    if (!links) continue;
                    hv_iterinit(links);
                    while ((lhe = hv_iternext(links))) {
                        I32 lkl; const char *lk = hv_iterkey(lhe, &lkl);
                        HV *lo = oa_hv_of(hv_iterval(links, lhe));
                        SV *oid  = lo ? oa_get(aTHX_ lo, "operationId")  : NULL;
                        SV *oref = lo ? oa_get(aTHX_ lo, "operationRef") : NULL;
                        STRLEN il; const char *ip;
                        if (oid && oref)
                            croak("Open::API: link '%.*s' declares both "
                                  "operationId and operationRef, which are "
                                  "mutually exclusive", (int)lkl, lk);
                        /* operationRef is the other spelling, and names a
                         * location rather than an id: not ours to resolve */
                        if (!oid) continue;
                        ip = SvPV_const(oid, il);
                        if (!hv_exists(t->by_id, ip, (I32)il))
                            croak("Open::API: link '%.*s' names operationId "
                                  "'%.*s', which no operation declares",
                                  (int)lkl, lk, (int)il, ip);
                    }
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

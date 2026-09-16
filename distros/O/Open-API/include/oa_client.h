#ifndef OA_CLIENT_H
#define OA_CLIENT_H

/* Open::API::Client - the spec-driven HTTP client on Fetch's C ABI.
 *
 * A client is a blessed HV: { api => Open::API, base_url, validate, ua,
 * ua_opts => [k, v, ...] }. call($operationId, %params) validates the flat
 * %params against the operation's compiled JSF handles (croaking BEFORE any
 * I/O on bad input), builds the URL/headers/body in C, and fires the request
 * through the Fetch ABI. The returned Fetch::Future resolves to
 *   { status, headers => {lc-name => value}, data, error? }
 * - `data` is the JSON-decoded body when the response is application/json,
 * the raw body otherwise; transport failures resolve with status 0 and
 * `error`; with validate => 1 a response-schema mismatch sets `error` and
 * `errors`. */

/* ---- lazy Fetch ABI resolution (the jsf_fetch.h pattern) ------------------- */

static int oa_fetch_init(pTHX) {
    dSP; int count; IV p = 0;
    if (OA_FETCH) return 1;
    if (OA_FETCH_TRIED) return 0;
    OA_FETCH_TRIED = 1;
    eval_pv("require Fetch;", FALSE);
    if (SvTRUE(ERRSV)) return 0;
    SPAGAIN;   /* the require may have reallocated the value stack */
    ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
    count = call_pv("Fetch::_abi_ptr", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) p = POPi;
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    if (p) {
        const fetch_abi *f = INT2PTR(const fetch_abi *, p);
        if (f && f->abi_version >= FETCH_ABI_VERSION) OA_FETCH = f;
    }
    return OA_FETCH != NULL;
}

/* ---- percent-encoding ------------------------------------------------------- */

/* RFC 3986 gen-delims + sub-delims. Passed through unencoded only for a query
 * parameter declared allowReserved, and only for its VALUE - a name is always
 * encoded, or the pair separators stop meaning anything. */
static int oa_is_reserved(U8 c) {
    return c == ':' || c == '/' || c == '?' || c == '#' || c == '['
        || c == ']' || c == '@' || c == '!' || c == '$' || c == '&'
        || c == '\'' || c == '(' || c == ')' || c == '*' || c == '+'
        || c == ',' || c == ';' || c == '=';
}

static void oa_pct_encode_res(pTHX_ SV *out, const char *p, STRLEN l,
                              int reserved) {
    static const char hex[] = "0123456789ABCDEF";
    STRLEN i;
    for (i = 0; i < l; i++) {
        U8 c = (U8)p[i];
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
            || (c >= '0' && c <= '9') || c == '-' || c == '.'
            || c == '_' || c == '~'
            || (reserved && oa_is_reserved(c))) {
            sv_catpvn(out, (const char *)&c, 1);
        } else {
            char b[3];
            b[0] = '%'; b[1] = hex[c >> 4]; b[2] = hex[c & 15];
            sv_catpvn(out, b, 3);
        }
    }
}

/* the ordinary encoding: nothing reserved passes through */
static void oa_pct_encode_into(pTHX_ SV *out, const char *p, STRLEN l) {
    oa_pct_encode_res(aTHX_ out, p, l, 0);
}

/* ---- style-aware serialization ----------------------------------------------
 *
 * The mirror of oa_style_path and oa_parse_query on the way OUT. Without it the
 * builder handed whatever it was given to SvPV, so an arrayref or hashref in a
 * path segment stringified to `ARRAY(0x...)` and went on the wire, and `style`
 * was ignored everywhere: a matrix parameter emitted a bare value with no
 * `;name=`, a spaceDelimited list emitted repeat keys. The client built URLs
 * this library's own server would refuse.
 *
 * Structural characters (the `;` `.` `,` `=` a style is MADE of) are written
 * literally; only the values around them are encoded. That is why each piece is
 * encoded on its own rather than the finished string being encoded at the end.
 */

/* An object's members in a stable order. Perl randomises hash order, so
 * serializing one straight out of the hash produces a DIFFERENT URL each run -
 * the same defect the router had. Sorted, so a URL is reproducible; object
 * members carry no meaningful order, so the server rebuilds the same value
 * whatever the order. */
static AV *oa_cli_sorted_keys(pTHX_ HV *h) {
    AV *keys = (AV *)sv_2mortal((SV *)newAV());
    HE *he;
    SSize_t i;
    hv_iterinit(h);
    while ((he = hv_iternext(h))) {
        I32 kl; const char *kp = hv_iterkey(he, &kl);
        av_push(keys, newSVpvn(kp, (STRLEN)kl));
    }
    for (i = 1; i <= av_len(keys); i++) {      /* insertion sort: few members */
        SV **cur = av_fetch(keys, i, 0);
        SV *c = cur && *cur ? SvREFCNT_inc(*cur) : NULL;
        SSize_t j = i - 1;
        if (!c) continue;
        while (j >= 0) {
            SV **prev = av_fetch(keys, j, 0);
            if (!prev || !*prev || sv_cmp(*prev, c) <= 0) break;
            (void)av_store(keys, j + 1, SvREFCNT_inc(*prev));
            j--;
        }
        (void)av_store(keys, j + 1, c);
    }
    return keys;
}

/* one value, encoded */
static void oa_cli_val(pTHX_ SV *out, SV *v, int reserved) {
    STRLEN l;
    const char *p;
    if (!v || !SvOK(v)) return;
    p = SvPV_const(v, l);
    oa_pct_encode_res(aTHX_ out, p, l, reserved);
}

/* Serialize `val` for a PATH segment per pp->style. `out` already ends at the
 * '/' this segment follows. */
static void oa_cli_ser_path(pTHX_ oa_param *pp, SV *val, SV *out) {
    STRLEN nl; const char *np = SvPV_const(pp->name, nl);
    AV *av = oa_av_of(val);
    HV *hv = (!av && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV)
           ? (HV *)SvRV(val) : NULL;
    const char *pfx = pp->style == OA_ST_LABEL  ? "."
                    : pp->style == OA_ST_MATRIX ? ";" : "";
    /* the separator BETWEEN elements once exploded */
    const char *esep = pp->style == OA_ST_LABEL  ? "."
                     : pp->style == OA_ST_MATRIX ? ";" : ",";

    if (*pfx) sv_catpv(out, pfx);

    if (!av && !hv) {                                   /* a scalar */
        if (pp->style == OA_ST_MATRIX) {
            /* `;name=value`, and `;name` alone when the value is empty */
            STRLEN vl; const char *vp = SvPV_const(val, vl);
            oa_pct_encode_into(aTHX_ out, np, nl);
            if (vl) { sv_catpvs(out, "="); oa_cli_val(aTHX_ out, val, 0); }
        } else {
            oa_cli_val(aTHX_ out, val, 0);
        }
        return;
    }

    if (av) {
        SSize_t i, n = av_len(av) + 1;
        /* matrix, not exploded, prefixes the name ONCE: `;name=a,b` */
        if (pp->style == OA_ST_MATRIX && !pp->explode) {
            oa_pct_encode_into(aTHX_ out, np, nl);
            sv_catpvs(out, "=");
        }
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            if (i) {
                /* label and simple keep a comma unless exploded; matrix
                 * exploded repeats `;name=` per element */
                if (pp->explode) sv_catpv(out, esep);
                else             sv_catpvs(out, ",");
            }
            if (pp->style == OA_ST_MATRIX && pp->explode) {
                if (i) { /* the `;` was written above */ }
                oa_pct_encode_into(aTHX_ out, np, nl);
                sv_catpvs(out, "=");
            }
            if (e && *e) oa_cli_val(aTHX_ out, *e, 0);
        }
        return;
    }

    {   /* an object */
        AV *keys = oa_cli_sorted_keys(aTHX_ hv);
        SSize_t i, n = av_len(keys) + 1;
        if (pp->style == OA_ST_MATRIX && !pp->explode) {
            oa_pct_encode_into(aTHX_ out, np, nl);
            sv_catpvs(out, "=");
        }
        for (i = 0; i < n; i++) {
            SV **k = av_fetch(keys, i, 0);
            SV **v;
            STRLEN kl; const char *kp;
            if (!k || !*k) continue;
            kp = SvPV_const(*k, kl);
            v = hv_fetch(hv, kp, (I32)kl, 0);
            if (i) {
                if (pp->explode) sv_catpv(out, esep);
                else             sv_catpvs(out, ",");
            }
            /* exploded names each MEMBER with `=`; not exploded, the members
             * are just more comma-separated pieces. sv_catpv, not sv_catpvs:
             * the _s form is a macro over a string LITERAL. */
            oa_pct_encode_into(aTHX_ out, kp, kl);
            sv_catpv(out, pp->explode ? "=" : ",");
            if (v && *v) oa_cli_val(aTHX_ out, *v, 0);
        }
    }
}

/* Serialize `val` as QUERY pieces per pp->style, appending to `url`. */
static void oa_cli_ser_query(pTHX_ oa_param *pp, SV *val, SV *url, int *first) {
    STRLEN nl; const char *np = SvPV_const(pp->name, nl);
    AV *av = oa_av_of(val);
    HV *hv = (!av && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV)
           ? (HV *)SvRV(val) : NULL;
    int res = pp->allow_reserved;
    const char *dsep = pp->style == OA_ST_SPACE ? "%20"
                     : pp->style == OA_ST_PIPE  ? "|" : ",";

    if (!av && !hv) {                                   /* a scalar */
        sv_catpvn(url, *first ? "?" : "&", 1); *first = 0;
        oa_pct_encode_into(aTHX_ url, np, nl);
        sv_catpvs(url, "=");
        oa_cli_val(aTHX_ url, val, res);
        return;
    }

    if (av) {
        SSize_t i, n = av_len(av) + 1;
        /* form + explode repeats the key; every other query style joins the
         * elements into ONE value with its own delimiter */
        if (pp->style == OA_ST_FORM && pp->explode) {
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                if (!e || !*e || !SvOK(*e)) continue;
                sv_catpvn(url, *first ? "?" : "&", 1); *first = 0;
                oa_pct_encode_into(aTHX_ url, np, nl);
                sv_catpvs(url, "=");
                oa_cli_val(aTHX_ url, *e, res);
            }
            return;
        }
        sv_catpvn(url, *first ? "?" : "&", 1); *first = 0;
        oa_pct_encode_into(aTHX_ url, np, nl);
        sv_catpvs(url, "=");
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            if (i) sv_catpv(url, dsep);
            if (e && *e) oa_cli_val(aTHX_ url, *e, res);
        }
        return;
    }

    {   /* an object */
        AV *keys = oa_cli_sorted_keys(aTHX_ hv);
        SSize_t i, n = av_len(keys) + 1;
        int one_value = !(pp->style == OA_ST_DEEP
                          || (pp->style == OA_ST_FORM && pp->explode));
        if (one_value) {
            sv_catpvn(url, *first ? "?" : "&", 1); *first = 0;
            oa_pct_encode_into(aTHX_ url, np, nl);
            sv_catpvs(url, "=");
        }
        for (i = 0; i < n; i++) {
            SV **k = av_fetch(keys, i, 0);
            SV **v;
            STRLEN kl; const char *kp;
            if (!k || !*k) continue;
            kp = SvPV_const(*k, kl);
            v = hv_fetch(hv, kp, (I32)kl, 0);
            if (one_value) {
                if (i) sv_catpv(url, dsep);
                oa_pct_encode_into(aTHX_ url, kp, kl);
                sv_catpv(url, dsep);
                if (v && *v) oa_cli_val(aTHX_ url, *v, res);
                continue;
            }
            sv_catpvn(url, *first ? "?" : "&", 1); *first = 0;
            if (pp->style == OA_ST_DEEP) {
                /* `name[member]=value` - the brackets are structural */
                oa_pct_encode_into(aTHX_ url, np, nl);
                sv_catpvs(url, "[");
                oa_pct_encode_into(aTHX_ url, kp, kl);
                sv_catpvs(url, "]");
            } else {
                /* form + explode: the MEMBER is the key */
                oa_pct_encode_into(aTHX_ url, kp, kl);
            }
            sv_catpvs(url, "=");
            if (v && *v) oa_cli_val(aTHX_ url, *v, res);
        }
    }
}

/* A header or cookie value. Neither is percent-encoded - the server splits
 * them but does not decode - so this joins the pieces literally rather than
 * going through oa_cli_val. Both locations are comma separated: a header is
 * `simple` by definition, and a cookie is `form`, whose non-exploded list is
 * also a comma. Without this an arrayref reached SvPV and the request carried
 * `X-H: ARRAY(0x...)`, which was verified going out over a socket. */
static void oa_cli_ser_flat(pTHX_ oa_param *pp, SV *val, SV *out) {
    AV *av = oa_av_of(val);
    HV *hv = (!av && SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVHV)
           ? (HV *)SvRV(val) : NULL;
    if (!av && !hv) { sv_catsv(out, val); return; }
    if (av) {
        SSize_t i, n = av_len(av) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            if (i) sv_catpvs(out, ",");
            if (e && *e && SvOK(*e)) sv_catsv(out, *e);
        }
        return;
    }
    {
        AV *keys = oa_cli_sorted_keys(aTHX_ hv);
        SSize_t i, n = av_len(keys) + 1;
        for (i = 0; i < n; i++) {
            SV **k = av_fetch(keys, i, 0);
            SV **v;
            STRLEN kl; const char *kp;
            if (!k || !*k) continue;
            kp = SvPV_const(*k, kl);
            v = hv_fetch(hv, kp, (I32)kl, 0);
            if (i) sv_catpvs(out, ",");
            sv_catpvn(out, kp, kl);
            sv_catpv(out, pp->explode ? "=" : ",");
            if (v && *v && SvOK(*v)) sv_catsv(out, *v);
        }
    }
}

/* ---- client-side validation -------------------------------------------------- */

/* croak with the first JSF error message for a bad client-side value */
static void oa_cli_bad(pTHX_ oa_op *o, const char *in, SV *name, SV *value,
                       SV *handle) {
    AV *errs = (AV *)sv_2mortal((SV *)newAV());
    const char *msg = "value does not match the schema";
    (void)JSF->validate(aTHX_ handle, value, errs);
    if (av_len(errs) >= 0) {
        SV **e = av_fetch(errs, 0, 0);
        HV *h = (e && *e && SvROK(*e)) ? (HV *)SvRV(*e) : NULL;
        SV *m = h ? oa_get(aTHX_ h, "message") : NULL;
        if (m) msg = SvPV_nolen(m);
    }
    croak("Open::API::Client: %s: invalid %s parameter '%s': %s",
          SvPV_nolen(o->op_id), in, name ? SvPV_nolen(name) : "body", msg);
}

/* The wire form of a parameter value.
 *
 * A `content` parameter carries a whole document in one value, so a structure
 * is encoded to its media type before it goes into the URL or a header -
 * without this it would stringify as HASH(0x...). A caller who has already
 * encoded it passes a string, which travels as it is. Mortal, or the original
 * SV when nothing needs doing. */
static SV *oa_cli_wire(pTHX_ oa_param *pp, SV *v) {
    if (pp->ctype && SvROK(v)
        && (SvTYPE(SvRV(v)) == SVt_PVHV || SvTYPE(SvRV(v)) == SVt_PVAV)) {
        STRLEN cl; const char *cp = SvPV_const(pp->ctype, cl);
        if (oa_ctype_is_json(cp, cl)) {
            SV *j = oa_json_encode(aTHX_ v);
            if (j) return j;
        }
    }
    return v;
}

/* The value a `content` parameter's schema should see: the decoded document.
 * Croaks on undecodable input, so the client fails before any I/O. */
static SV *oa_cli_decoded(pTHX_ oa_op *o, oa_param *pp, const char *in, SV *v) {
    if (pp->ctype && !SvROK(v)) {
        STRLEN cl; const char *cp = SvPV_const(pp->ctype, cl);
        if (oa_ctype_is_json(cp, cl)) {
            SV *d = oa_body_decode(aTHX_ v);
            if (!d) croak("Open::API::Client: %s: %s parameter '%s' is not "
                          "valid JSON", SvPV_nolen(o->op_id), in,
                          SvPV_nolen(pp->name));
            return d;
        }
    }
    return v;
}

/* ---- the response map callback ------------------------------------------------ */

typedef struct oa_cli_ctx {
    SV    *api_sv;      /* keeps the op table alive (+1)   */
    oa_op *op;
    int    validate;
    SV    *cli;         /* RV to the client HV, for CSRF token capture (+1) */
    SV    *csrf_cookie; /* CSRF cookie name to watch for in Set-Cookie (+1) */
} oa_cli_ctx;

static SV *oa_cli_map(pTHX_ int ok, int status, AV *headers, SV *body,
                      SV *err, void *ud) {
    oa_cli_ctx *c = (oa_cli_ctx *)ud;
    HV *out = newHV();
    HV *hh  = newHV();
    int is_json = 0;
    SSize_t i, n;
    SV *data = NULL;

    if (!ok) {
        (void)hv_stores(out, "status", newSViv(0));
        (void)hv_stores(out, "error",
            (err && SvOK(err)) ? newSVsv(err)
                               : newSVpvs("request failed"));
        SvREFCNT_dec((SV *)hh);
        goto done;
    }

    (void)hv_stores(out, "status", newSViv(status));
    n = headers ? av_len(headers) + 1 : 0;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(headers, i, 0);
        SV **v = av_fetch(headers, i + 1, 0);
        if (k && *k && v && *v) {
            STRLEN kl; const char *kp = SvPV_const(*k, kl);
            char lc[128];
            STRLEN j;
            if (kl >= sizeof lc) continue;
            for (j = 0; j < kl; j++) lc[j] = (char)toLOWER((U8)kp[j]);
            (void)hv_store(hh, lc, (I32)kl, newSVsv(*v), 0);
            if (kl == 12 && memEQ(lc, "content-type", 12)) {
                STRLEN vl; const char *vp = SvPV_const(*v, vl);
                if (vl >= 16 && memEQ(vp, "application/json", 16))
                    is_json = 1;
            }
        }
    }
    (void)hv_stores(out, "headers", newRV_noinc((SV *)hh));

    /* transparent CSRF: capture the (rotated) token the server set, so the
     * next unsafe call can echo it in the token header */
    if (c->csrf_cookie && c->cli && headers) {
        STRLEN wnl; const char *wnp = SvPV_const(c->csrf_cookie, wnl);
        for (i = 0; i + 1 < n; i += 2) {
            SV **k = av_fetch(headers, i, 0);
            SV **v = av_fetch(headers, i + 1, 0);
            STRLEN kl, vl; const char *kp, *vp;
            if (!k || !*k || !v || !*v) continue;
            kp = SvPV_const(*k, kl);
            if (!(kl == 10 && oa_ci_eq(kp, kl, "set-cookie", 10))) continue;
            vp = SvPV_const(*v, vl);
            if (vl > wnl + 1 && memEQ(vp, wnp, wnl) && vp[wnl] == '=') {
                STRLEN s = wnl + 1, e = s;
                while (e < vl && vp[e] != ';') e++;
                (void)hv_stores((HV *)SvRV(c->cli), "_csrf_token",
                                newSVpvn(vp + s, e - s));
            }
        }
    }

    if (is_json && body && SvOK(body) && SvCUR(body))
        data = oa_body_decode(aTHX_ body);   /* mortal or NULL */
    if (data) (void)hv_stores(out, "data", newSVsv(data));
    else      (void)hv_stores(out, "data",
                   body && SvOK(body) ? newSVsv(body) : newSV(0));

    /* optional response-schema validation */
    if (c->validate && c->op && data) {
        SV *handle = NULL;
        char sbuf[8];
        STRLEN sl = (STRLEN)my_snprintf(sbuf, sizeof sbuf, "%d", status);
        int ri;
        for (ri = 0; ri < c->op->nresps; ri++) {
            STRLEN rl; const char *rp = SvPV_const(c->op->resps[ri].status, rl);
            if (rl == sl && memEQ(rp, sbuf, sl))
                { handle = c->op->resps[ri].handle; break; }
        }
        if (!handle) {   /* a range key: 2XX, 4XX, ... (same order as the server) */
            for (ri = 0; ri < c->op->nresps; ri++) {
                STRLEN rl; const char *rp = SvPV_const(c->op->resps[ri].status, rl);
                if (oa_status_covers(rp, rl, sbuf, sl))
                    { handle = c->op->resps[ri].handle; break; }
            }
        }
        if (!handle) {
            for (ri = 0; ri < c->op->nresps; ri++) {
                STRLEN rl; const char *rp = SvPV_const(c->op->resps[ri].status, rl);
                if (rl == 7 && memEQ(rp, "default", 7))
                    { handle = c->op->resps[ri].handle; break; }
            }
        }
        if (handle) {
            AV *errs = newAV();
            if (!JSF->validate(aTHX_ handle, data, errs)) {
                (void)hv_stores(out, "error",
                                newSVpvs("response validation failed"));
                (void)hv_stores(out, "errors", newRV_noinc((SV *)errs));
            } else {
                SvREFCNT_dec((SV *)errs);
            }
        }
    }

done:
    if (c) {
        if (c->api_sv)      SvREFCNT_dec(c->api_sv);
        if (c->cli)         SvREFCNT_dec(c->cli);
        if (c->csrf_cookie) SvREFCNT_dec(c->csrf_cookie);
        Safefree(c);
    }
    return newRV_noinc((SV *)out);
}

/* ---- call ----------------------------------------------------------------------- */

/* the client HV field, or NULL */
static SV *oa_cli_get(pTHX_ HV *self, const char *k) {
    return oa_get(aTHX_ self, k);
}

/* lazily build (and cache) the client's Fetch UA from ua_opts */
static SV *oa_cli_ua(pTHX_ HV *self) {
    SV *ua = oa_cli_get(aTHX_ self, "ua");
    AV *opts;
    SV *kv[16];
    int nkv = 0;
    if (ua && SvROK(ua)) return ua;
    opts = oa_av_of(oa_cli_get(aTHX_ self, "ua_opts"));
    if (opts) {
        SSize_t i, n = av_len(opts) + 1;
        for (i = 0; i < n && nkv < 16; i++) {
            SV **e = av_fetch(opts, i, 0);
            kv[nkv++] = (e && *e) ? *e : &PL_sv_undef;
        }
    }
    ua = OA_FETCH->ua_new(aTHX_ kv, nkv);            /* +1 */
    (void)hv_stores(self, "ua", ua);                 /* HV takes the ref */
    return ua;
}

/* "user:pass" (or an [user, pass] arrayref) -> mortal "Basic base64" value */
static SV *oa_cli_basic(pTHX_ SV *cred) {
    AV *av = oa_av_of(cred);
    SV *joined = cred;
    SV *out;
    STRLEN l; const char *pv;
    if (av) {
        SV **u = av_fetch(av, 0, 0), **p = av_fetch(av, 1, 0);
        joined = sv_2mortal(newSVpvs(""));
        if (u && *u && SvOK(*u)) sv_catsv(joined, *u);
        sv_catpvs(joined, ":");
        if (p && *p && SvOK(*p)) sv_catsv(joined, *p);
    }
    pv  = SvPV_const(joined, l);
    out = sv_2mortal(newSVpvs("Basic "));
    sv_catsv(out, sv_2mortal(oa_b64_encode(aTHX_ pv, l)));
    return out;
}

/* An apiKey credential selected from the op's security requirements, to be
 * attached as a header, a query pair or a cookie. Named rather than anonymous
 * because oa_cli_url below takes the query ones as an argument. */
typedef struct oa_cli_sec { SV *name; SV *val; } oa_cli_sec;

/* The request URL: base + interpolated path + query. Split out of
 * oa_cli_call so the same construction can be inspected without firing a
 * request - a client's serialization rules (allowReserved) are otherwise
 * observable only by standing up a real server. `sec_q`/`nsec_q` carry
 * apiKey-in-query credentials; pass 0 for none. Mortal. */
static SV *oa_cli_url(pTHX_ oa_op *o, HV *params, SV *base,
                      const oa_cli_sec *sec_q, int nsec_q) {
    SV *url = sv_2mortal(newSVpvs(""));
    int i;

    if (base && SvOK(base)) {
        STRLEN bl; const char *bpv = SvPV_const(base, bl);
        while (bl && bpv[bl - 1] == '/') bl--;
        sv_catpvn(url, bpv, bl);
    }
    for (i = 0; i < o->nsegs; i++) {
        sv_catpvs(url, "/");
        if (o->segs[i].lit) {
            sv_catsv(url, o->segs[i].lit);
        } else {
            STRLEN nl; const char *np = SvPV_const(o->segs[i].pname, nl);
            SV **v = hv_fetch(params, np, (I32)nl, 0);
            SV *w;
            oa_param *decl = NULL;
            int k;
            /* declared path params were checked by the caller, but a template
             * var the spec never declared as a parameter reaches here
             * unchecked */
            if (!v || !*v || !SvOK(*v))
                croak("Open::API::Client: %s: missing required path parameter "
                      "'%.*s'", SvPV_nolen(o->op_id), (int)nl, np);
            w = *v;
            for (k = 0; k < o->nparams[OA_IN_PATH]; k++)
                if (sv_eq(o->params[OA_IN_PATH][k].name, o->segs[i].pname)) {
                    decl = &o->params[OA_IN_PATH][k];
                    w = oa_cli_wire(aTHX_ decl, *v);
                    break;
                }
            /* Always fully encoded: a reserved character in a path segment
             * changes the SHAPE of the path, so allowReserved does not reach
             * here even when a path parameter declares it. The style's own
             * structural characters are written by the serializer and are not
             * encoded - they ARE the shape. */
            if (decl) {
                oa_cli_ser_path(aTHX_ decl, w, url);
            } else {
                STRLEN vl; const char *vp = SvPV_const(w, vl);
                oa_pct_encode_into(aTHX_ url, vp, vl);
            }
        }
    }
    if (!o->nsegs) sv_catpvs(url, "/");
    {
        int first = 1;
        for (i = 0; i < o->nparams[OA_IN_QUERY]; i++) {
            oa_param *pp = &o->params[OA_IN_QUERY][i];
            STRLEN nl; const char *np = SvPV_const(pp->name, nl);
            SV **v = hv_fetch(params, np, (I32)nl, 0);
            int structured;
            if (!v || !*v || !SvOK(*v)) continue;
            /* a content parameter's arrayref is its DOCUMENT, not a list to
             * serialize per style: it goes through oa_cli_wire as one value */
            structured = !pp->ctype && SvROK(*v)
                       && (SvTYPE(SvRV(*v)) == SVt_PVAV
                           || SvTYPE(SvRV(*v)) == SVt_PVHV);
            if (structured) {
                oa_cli_ser_query(aTHX_ pp, *v, url, &first);
            } else {
                SV *w = oa_cli_wire(aTHX_ pp, *v);
                STRLEN vl; const char *vp = SvPV_const(w, vl);
                sv_catpvn(url, first ? "?" : "&", 1); first = 0;
                oa_pct_encode_into(aTHX_ url, np, nl);
                sv_catpvs(url, "=");
                oa_pct_encode_res(aTHX_ url, vp, vl, pp->allow_reserved);
            }
        }
        for (i = 0; i < nsec_q; i++) {          /* apiKey-in-query schemes */
            STRLEN nl2, vl2;
            const char *np2 = SvPV_const(sec_q[i].name, nl2);
            const char *vp2 = SvPV_const(sec_q[i].val, vl2);
            sv_catpvn(url, first ? "?" : "&", 1); first = 0;
            oa_pct_encode_into(aTHX_ url, np2, nl2);
            sv_catpvs(url, "=");
            oa_pct_encode_into(aTHX_ url, vp2, vl2);
        }
    }
    return url;
}

/* ---- the request body, per the media type the operation DECLARES ------------
 *
 * The builder used to JSON-encode whatever it was handed and label it
 * `application/json`, whatever the document said. An operation declaring only
 * `application/x-www-form-urlencoded` therefore sent JSON under the wrong
 * Content-Type, and this library's OWN server answered 415: a client and a
 * server generated from one document could not talk to each other.
 *
 * Split out of oa_cli_call so `_request_body` can expose it, the way
 * oa_cli_url is exposed as `_request_url`. Untestable otherwise: a body that
 * only exists inside a live request cannot be asserted against.
 */

/* Which declared body to send. JSON when the operation declares it - the
 * safest default and what callers already relied on - then form, then
 * multipart, then whatever is first. */
static oa_body *oa_cli_pick_body(oa_op *o) {
    int i;
    oa_body *form = NULL, *multi = NULL, *any = NULL;
    for (i = 0; i < o->nbodies; i++) {
        oa_body *b = &o->bodies[i];
        if (b->kind == OA_MT_JSON) return b;
        if (!form  && b->kind == OA_MT_FORM)      form  = b;
        if (!multi && b->kind == OA_MT_MULTIPART) multi = b;
        if (!any) any = b;
    }
    return form ? form : multi ? multi : any;
}

/* `a=1&b=2`, with an array member repeated unless its Encoding says otherwise.
 * Members are sorted for the same reason the URL builder sorts them: hash
 * order is randomised and a body that changes between runs is not one a test
 * or a signature can rely on. */
static SV *oa_cli_form_encode(pTHX_ oa_op *o, SV *val) {
    SV *out = sv_2mortal(newSVpvs(""));
    HV *hv;
    AV *keys;
    SSize_t i, n;
    int first = 1;
    if (!val || !SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVHV)
        croak("Open::API::Client: %s: a form body wants a hashref",
              SvPV_nolen(o->op_id));
    hv = (HV *)SvRV(val);
    keys = oa_cli_sorted_keys(aTHX_ hv);
    n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV **k = av_fetch(keys, i, 0);
        SV **v;
        STRLEN kl; const char *kp;
        AV *av;
        if (!k || !*k) continue;
        kp = SvPV_const(*k, kl);
        v = hv_fetch(hv, kp, (I32)kl, 0);
        if (!v || !*v || !SvOK(*v)) continue;
        av = oa_av_of(*v);
        if (av) {
            SSize_t j, m = av_len(av) + 1;
            for (j = 0; j < m; j++) {
                SV **e = av_fetch(av, j, 0);
                if (!e || !*e || !SvOK(*e)) continue;
                if (!first) sv_catpvs(out, "&");
                first = 0;
                oa_pct_encode_into(aTHX_ out, kp, kl);
                sv_catpvs(out, "=");
                oa_cli_val(aTHX_ out, *e, 0);
            }
            continue;
        }
        if (!first) sv_catpvs(out, "&");
        first = 0;
        oa_pct_encode_into(aTHX_ out, kp, kl);
        sv_catpvs(out, "=");
        oa_cli_val(aTHX_ out, *v, 0);
    }
    return out;
}

/* multipart/form-data. The boundary is fixed rather than random: this library
 * sends no binary parts of its own, a body that differs run to run cannot be
 * asserted, and the value is checked against the payload below. */
static SV *oa_cli_multipart_encode(pTHX_ oa_op *o, SV *val, const char *bnd) {
    SV *out = sv_2mortal(newSVpvs(""));
    HV *hv;
    AV *keys;
    SSize_t i, n;
    if (!val || !SvROK(val) || SvTYPE(SvRV(val)) != SVt_PVHV)
        croak("Open::API::Client: %s: a multipart body wants a hashref",
              SvPV_nolen(o->op_id));
    hv = (HV *)SvRV(val);
    keys = oa_cli_sorted_keys(aTHX_ hv);
    n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV **k = av_fetch(keys, i, 0);
        SV **v;
        STRLEN kl, vl; const char *kp, *vp;
        if (!k || !*k) continue;
        kp = SvPV_const(*k, kl);
        v = hv_fetch(hv, kp, (I32)kl, 0);
        if (!v || !*v || !SvOK(*v)) continue;
        /* a boundary that appears inside a part would end it early */
        vp = SvPV_const(*v, vl);
        if (vl && ninstr(vp, vp + vl, bnd, bnd + strlen(bnd)))
            croak("Open::API::Client: %s: a multipart value contains the "
                  "boundary", SvPV_nolen(o->op_id));
        sv_catpvs(out, "--"); sv_catpv(out, bnd); sv_catpvs(out, "\r\n");
        sv_catpvs(out, "Content-Disposition: form-data; name=\"");
        sv_catpvn(out, kp, kl);
        sv_catpvs(out, "\"\r\n\r\n");
        sv_catpvn(out, vp, vl);
        sv_catpvs(out, "\r\n");
    }
    sv_catpvs(out, "--"); sv_catpv(out, bnd); sv_catpvs(out, "--\r\n");
    return out;
}

#define OA_CLI_BOUNDARY "OpenAPIClientBoundary1"

/* Returns a mortal body SV, or NULL when the operation sends none. *ctype is
 * set to a mortal Content-Type SV whenever a body is returned. */
static SV *oa_cli_build_body(pTHX_ oa_op *o, HV *params, SV **ctype) {
    SV **bv = hv_fetchs(params, "body", 0);
    SV *bsv = (bv && *bv && SvOK(*bv)) ? *bv : NULL;
    oa_body *b;
    SV *out;

    *ctype = NULL;
    if (!o->nbodies) return NULL;
    if (!bsv) {
        if (o->body_required)
            croak("Open::API::Client: %s: missing required body",
                  SvPV_nolen(o->op_id));
        return NULL;
    }
    b = oa_cli_pick_body(o);
    if (!b) return NULL;

    /* the declared schema still decides, whatever the media type */
    if (b->handle && !JSF->is_valid(aTHX_ b->handle, bsv))
        oa_cli_bad(aTHX_ o, "body", NULL, bsv, b->handle);

    if (b->kind == OA_MT_FORM) {
        out = oa_cli_form_encode(aTHX_ o, bsv);
        *ctype = sv_2mortal(newSVpvs("application/x-www-form-urlencoded"));
        return out;
    }
    if (b->kind == OA_MT_MULTIPART) {
        out = oa_cli_multipart_encode(aTHX_ o, bsv, OA_CLI_BOUNDARY);
        *ctype = sv_2mortal(newSVpvs("multipart/form-data; boundary="
                                     OA_CLI_BOUNDARY));
        return out;
    }
    if (b->kind == OA_MT_JSON) {
        out = oa_json_encode(aTHX_ bsv);
        if (!out) croak("Open::API::Client: %s: could not encode body",
                        SvPV_nolen(o->op_id));
        *ctype = sv_2mortal(newSVsv(b->ctype));
        return out;
    }
    /* opaque: send what the caller gave, under the declared type */
    if (SvROK(bsv))
        croak("Open::API::Client: %s: %" SVf " wants a plain string body",
              SvPV_nolen(o->op_id), SVfARG(b->ctype));
    out = sv_2mortal(newSVsv(bsv));
    *ctype = sv_2mortal(newSVsv(b->ctype));
    return out;
}

/* Build and fire one call. params is the flat name => value HV. Returns the
 * request future (+1). */
static SV *oa_cli_call(pTHX_ HV *self, SV *op_id, HV *params) {
    SV *api_sv = oa_cli_get(aTHX_ self, "api");
    oa_api *a;
    oa_op *o;
    SV *base = oa_cli_get(aTHX_ self, "base_url");
    SV *url;
    fetch_hdr hdrs[32];
    int nh = 0;
    SV *cookie = NULL, *bodyjson = NULL;
    const char *bp = NULL;
    STRLEN blen = 0;
    char method[16];
    STRLEN ml, mk;
    const char *mmp;
    oa_cli_ctx *ctx;
    int loc, i;
    SV *ua, *csrf_cfg;
    SV *csrf_cookie_name = NULL;   /* set when transparent CSRF is enabled */
    /* security attachments, selected from the op's requirements below */
    SV *sec_auth = NULL;                                   /* Authorization */
    oa_cli_sec sec_h[8], sec_q[8], sec_c[8];
    int nsec_h = 0, nsec_q = 0, nsec_c = 0;

    if (!api_sv || !SvROK(api_sv))
        croak("Open::API::Client: no api on this client");
    a = (oa_api *)INT2PTR(void *, SvIV(SvRV(api_sv)));
    o = oa_op_by_id(aTHX_ a, op_id);
    if (!o) croak("Open::API::Client: unknown operationId '%s'",
                  SvPV_nolen(op_id));
    if (!oa_fetch_init(aTHX))
        croak("Open::API::Client requires Fetch with its C ABI "
              "(Fetch 0.05 or later)");

    /* ---- security: first requirement alternative the credentials cover ---- */
    if (o->nsec) {
        HV *creds = oa_hv_of(oa_cli_get(aTHX_ self, "security"));
        oa_ops *t = (oa_ops *)a->ops;
        int ai, found = -1;
        for (ai = 0; ai < o->nsec && found < 0; ai++) {
            int ii, all = 1;
            for (ii = 0; ii < o->sec[ai].n; ii++) {
                oa_scheme *s = &t->schemes[o->sec[ai].items[ii].scheme];
                STRLEN nl; const char *np = SvPV_const(s->name, nl);
                SV **c = creds ? hv_fetch(creds, np, (I32)nl, 0) : NULL;
                if (!c || !*c || !SvOK(*c)) {
                    /* an apiKey-in-cookie (e.g. a session cookie set at login)
                     * is carried ambiently by the cookie jar, so it needs no
                     * explicit credential; every other scheme does */
                    if (!(s->type == OA_SEC_APIKEY && s->loc == OA_IN_COOKIE))
                        { all = 0; break; }
                }
            }
            if (all) found = ai;
        }
        if (found < 0)
            croak("Open::API::Client: %s: no satisfiable security requirement "
                  "- pass security => { scheme_name => credential }",
                  SvPV_nolen(o->op_id));
        for (i = 0; i < o->sec[found].n; i++) {
            oa_scheme *s = &t->schemes[o->sec[found].items[i].scheme];
            STRLEN nl; const char *np = SvPV_const(s->name, nl);
            SV **cp = creds ? hv_fetch(creds, np, (I32)nl, 0) : NULL;
            SV *cred = (cp && *cp && SvOK(*cp)) ? *cp : NULL;
            switch (s->type) {
            case OA_SEC_APIKEY:
                if (!cred) break;   /* cookie carried by the jar: nothing to add */
                if (s->loc == OA_IN_HEADER && nsec_h < 8)
                    { sec_h[nsec_h].name = s->pname; sec_h[nsec_h].val = cred; nsec_h++; }
                else if (s->loc == OA_IN_QUERY && nsec_q < 8)
                    { sec_q[nsec_q].name = s->pname; sec_q[nsec_q].val = cred; nsec_q++; }
                else if (s->loc == OA_IN_COOKIE && nsec_c < 8)
                    { sec_c[nsec_c].name = s->pname; sec_c[nsec_c].val = cred; nsec_c++; }
                break;
            case OA_SEC_BEARER:
                if (!cred) break;
                sec_auth = sv_2mortal(newSVpvs("Bearer "));
                sv_catsv(sec_auth, cred);
                break;
            case OA_SEC_BASIC:
                if (!cred) break;
                sec_auth = oa_cli_basic(aTHX_ cred);
                break;
            }
        }
    }

    /* ---- validate every declared parameter (fail before I/O) ---- */
    for (loc = 0; loc < OA_IN_N; loc++) {
        for (i = 0; i < o->nparams[loc]; i++) {
            oa_param *pp = &o->params[loc][i];
            STRLEN nl; const char *np = SvPV_const(pp->name, nl);
            SV **v = hv_fetch(params, np, (I32)nl, 0);
            if (v && *v && SvOK(*v)) {
                SV *chk = oa_cli_decoded(aTHX_ o, pp, oa_loc_name(loc), *v);
                if (pp->handle && !JSF->is_valid(aTHX_ pp->handle, chk))
                    oa_cli_bad(aTHX_ o, oa_loc_name(loc), pp->name, chk,
                               pp->handle);
            } else if (pp->required) {
                croak("Open::API::Client: %s: missing required %s parameter '%.*s'",
                      SvPV_nolen(o->op_id), oa_loc_name(loc), (int)nl, np);
            }
        }
    }

    /* ---- body ---- */
    {
        SV *bctype = NULL;
        bodyjson = oa_cli_build_body(aTHX_ o, params, &bctype);
        if (bodyjson && bctype) {
            STRLEN ctl;
            const char *ctp = SvPV_const(bctype, ctl);
            bp = SvPV_const(bodyjson, blen);
            hdrs[nh].name = "Content-Type"; hdrs[nh].nlen = 12;
            hdrs[nh].val  = ctp;            hdrs[nh].vlen = ctl;
            nh++;
        }
    }

    /* ---- URL: base + interpolated path + query ---- */
    url = oa_cli_url(aTHX_ o, params, base, sec_q, nsec_q);

    /* ---- headers + cookies ---- */
    for (i = 0; i < o->nparams[OA_IN_HEADER] && nh < 31; i++) {
        oa_param *pp = &o->params[OA_IN_HEADER][i];
        STRLEN nl; const char *np = SvPV_const(pp->name, nl);
        SV **v = hv_fetch(params, np, (I32)nl, 0);
        if (v && *v && SvOK(*v)) {
            SV *w = oa_cli_wire(aTHX_ pp, *v);
            STRLEN vl; const char *vp;
            /* a list or object header is joined, not stringified: SvPV on a
             * reference puts `ARRAY(0x...)` on the wire */
            if (SvROK(w) && (SvTYPE(SvRV(w)) == SVt_PVAV
                             || SvTYPE(SvRV(w)) == SVt_PVHV)) {
                SV *flat = sv_2mortal(newSVpvs(""));
                oa_cli_ser_flat(aTHX_ pp, w, flat);
                w = flat;
            }
            vp = SvPV_const(w, vl);
            hdrs[nh].name = np; hdrs[nh].nlen = nl;
            hdrs[nh].val  = vp; hdrs[nh].vlen = vl;
            nh++;
        }
    }
    for (i = 0; i < o->nparams[OA_IN_COOKIE]; i++) {
        oa_param *pp = &o->params[OA_IN_COOKIE][i];
        STRLEN nl; const char *np = SvPV_const(pp->name, nl);
        SV **v = hv_fetch(params, np, (I32)nl, 0);
        if (v && *v && SvOK(*v)) {
            if (!cookie) cookie = sv_2mortal(newSVpvs(""));
            else sv_catpvs(cookie, "; ");
            sv_catpvn(cookie, np, nl);
            sv_catpvs(cookie, "=");
            {   /* same reference trap as the header loop above */
                SV *w = oa_cli_wire(aTHX_ pp, *v);
                if (SvROK(w) && (SvTYPE(SvRV(w)) == SVt_PVAV
                                 || SvTYPE(SvRV(w)) == SVt_PVHV))
                    oa_cli_ser_flat(aTHX_ pp, w, cookie);
                else
                    sv_catsv(cookie, w);
            }
        }
    }
    for (i = 0; i < nsec_c; i++) {              /* apiKey-in-cookie schemes */
        if (!cookie) cookie = sv_2mortal(newSVpvs(""));
        else sv_catpvs(cookie, "; ");
        sv_catsv(cookie, sec_c[i].name);
        sv_catpvs(cookie, "=");
        sv_catsv(cookie, sec_c[i].val);
    }
    for (i = 0; i < nsec_h && nh < 31; i++) {   /* apiKey-in-header schemes */
        STRLEN nl2, vl2;
        hdrs[nh].name = SvPV_const(sec_h[i].name, nl2); hdrs[nh].nlen = nl2;
        hdrs[nh].val  = SvPV_const(sec_h[i].val, vl2);  hdrs[nh].vlen = vl2;
        nh++;
    }
    if (sec_auth && nh < 31) {                  /* bearer / basic */
        STRLEN al;
        hdrs[nh].name = "Authorization"; hdrs[nh].nlen = 13;
        hdrs[nh].val  = SvPV_const(sec_auth, al); hdrs[nh].vlen = al;
        nh++;
    }
    if (cookie && nh < 31) {
        STRLEN cl; const char *cp = SvPV_const(cookie, cl);
        hdrs[nh].name = "Cookie"; hdrs[nh].nlen = 6;
        hdrs[nh].val  = cp;       hdrs[nh].vlen = cl;
        nh++;
    }

    /* ---- transparent CSRF ---- *
     * On a state-changing method, present the Origin the server expects and
     * echo the CSRF token captured from the previous response into the token
     * header (a custom header a cross-site page could not set). The response
     * map (oa_cli_map) captures the rotated token for the next call. */
    csrf_cfg = oa_cli_get(aTHX_ self, "_csrf");
    if (csrf_cfg && SvROK(csrf_cfg)) {
        HV *cd = (HV *)SvRV(csrf_cfg);
        STRLEN mml; const char *mp2 = SvPV_const(o->method, mml);
        int unsafe = !((mml == 3 && memEQ(mp2, "get", 3))
                    || (mml == 4 && memEQ(mp2, "head", 4))
                    || (mml == 7 && memEQ(mp2, "options", 7))
                    || (mml == 5 && memEQ(mp2, "trace", 5)));
        csrf_cookie_name = *hv_fetchs(cd, "cookie", 0);   /* for capture */
        if (unsafe) {
            SV **org = hv_fetchs(cd, "origin", 0);
            SV *tok  = oa_cli_get(aTHX_ self, "_csrf_token");
            if (org && *org && SvOK(*org) && nh < 31) {
                STRLEN ol; const char *op = SvPV_const(*org, ol);
                hdrs[nh].name = "Origin"; hdrs[nh].nlen = 6;
                hdrs[nh].val  = op;       hdrs[nh].vlen = ol;
                nh++;
            }
            if (tok && SvOK(tok) && nh < 31) {
                SV *hn = *hv_fetchs(cd, "header", 0);
                STRLEN hnl; const char *hnp = SvPV_const(hn, hnl);
                STRLEN tl;  const char *tp  = SvPV_const(tok, tl);
                hdrs[nh].name = hnp; hdrs[nh].nlen = hnl;
                hdrs[nh].val  = tp;  hdrs[nh].vlen = tl;
                nh++;
            }
        }
    }

    /* ---- fire ---- */
    mmp = SvPV_const(o->method, ml);
    if (ml >= sizeof method) ml = sizeof method - 1;
    for (mk = 0; mk < ml; mk++) method[mk] = (char)toUPPER((U8)mmp[mk]);
    method[ml] = '\0';
    Newxz(ctx, 1, oa_cli_ctx);
    ctx->api_sv   = SvREFCNT_inc(api_sv);
    ctx->op       = o;
    ctx->validate = oa_cli_get(aTHX_ self, "validate")
                    && SvTRUE(oa_cli_get(aTHX_ self, "validate")) ? 1 : 0;
    if (csrf_cookie_name) {   /* capture the rotated token from the response */
        ctx->cli         = newRV_inc((SV *)self);
        ctx->csrf_cookie = newSVsv(csrf_cookie_name);
    }
    ua = oa_cli_ua(aTHX_ self);
    return OA_FETCH->request(aTHX_ ua, method, SvPV_nolen(url),
                             nh ? hdrs : NULL, nh, bp, blen,
                             0.0, -1, oa_cli_map, ctx);
}

#endif /* OA_CLIENT_H */

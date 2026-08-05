#ifndef OA_VALIDATE_H
#define OA_VALIDATE_H

/* Per-request validation for a matched operation: percent-decode path
 * captures, parse the query string and Cookie header in C, JSON-decode the
 * body, run every declared parameter and the body through the JSF ABI, and
 * assemble the validated params structure. Two modes: errs == NULL uses the
 * cheap boolean path (is_valid); with an AV, all failures are collected as
 * hashrefs - JSF's error hashes augmented with `in` and `name`. */

/* ---- decoding helpers ------------------------------------------------------ */

static int oa_hexval(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

/* %XX (and optionally '+' -> space) decode into a fresh SV */
static SV *oa_pct_decode(pTHX_ const char *p, STRLEN l, int plus) {
    SV *out = newSV(l + 1);
    char *d;
    STRLEN i, o = 0;
    SvPOK_on(out);
    d = SvPVX(out);
    for (i = 0; i < l; i++) {
        if (p[i] == '%' && i + 2 < l) {
            int h = oa_hexval(p[i + 1]), lo = oa_hexval(p[i + 2]);
            if (h >= 0 && lo >= 0) { d[o++] = (char)((h << 4) | lo); i += 2; continue; }
        }
        if (plus && p[i] == '+') { d[o++] = ' '; continue; }
        d[o++] = p[i];
    }
    d[o] = '\0';
    SvCUR_set(out, o);
    return out;
}

/* ---- error helpers --------------------------------------------------------- */

static const char *oa_loc_name(int loc) {
    static const char *n[OA_IN_N] = { "path", "query", "header", "cookie" };
    return n[loc];
}

static void oa_err_push(pTHX_ AV *errs, const char *in, SV *name,
                        const char *keyword, const char *msg) {
    HV *e = newHV();
    (void)hv_stores(e, "in",      newSVpv(in, 0));
    if (name) (void)hv_stores(e, "name", newSVsv(name));
    (void)hv_stores(e, "keyword", newSVpv(keyword, 0));
    (void)hv_stores(e, "message", newSVpv(msg, 0));
    av_push(errs, newRV_noinc((SV *)e));
}

/* run one value through a handle; on failure augment the new JSF errors */
static int oa_check(pTHX_ SV *handle, SV *value, AV *errs,
                    const char *in, SV *name) {
    if (!handle) return 1;                     /* no schema: anything goes */
    if (!errs) return JSF->is_valid(aTHX_ handle, value);
    {
        SSize_t before = av_len(errs);
        int ok = JSF->validate(aTHX_ handle, value, errs);
        if (!ok) {
            SSize_t i, after = av_len(errs);
            for (i = before + 1; i <= after; i++) {
                SV **e = av_fetch(errs, i, 0);
                HV *h = (e && *e && SvROK(*e)) ? (HV *)SvRV(*e) : NULL;
                if (h) {
                    (void)hv_stores(h, "in", newSVpv(in, 0));
                    if (name) (void)hv_stores(h, "name", newSVsv(name));
                }
            }
        }
        return ok;
    }
}

/* ---- query / cookie parsing ------------------------------------------------ */

/* Parse a query string into a fresh HV: every key decoded; a key is an
 * arrayref when the op declares that query parameter as array-typed (repeat
 * keys accumulate), else last value wins. Undeclared keys are kept (string). */
static HV *oa_parse_query(pTHX_ oa_op *o, const char *qs, STRLEN ql) {
    HV *out = newHV();
    STRLEN s = 0;
    while (s < ql) {
        STRLEN e = s, eq;
        SV *k, *v;
        int i, is_arr = 0;
        while (e < ql && qs[e] != '&') e++;
        eq = s;
        while (eq < e && qs[eq] != '=') eq++;
        if (eq > s) {
            k = sv_2mortal(oa_pct_decode(aTHX_ qs + s, eq - s, 1));
            v = oa_pct_decode(aTHX_ qs + (eq < e ? eq + 1 : e),
                              eq < e ? e - eq - 1 : 0, 1);
            for (i = 0; i < o->nparams[OA_IN_QUERY]; i++) {
                if (sv_eq(o->params[OA_IN_QUERY][i].name, k)) {
                    is_arr = o->params[OA_IN_QUERY][i].is_array;
                    break;
                }
            }
            {
                STRLEN kl; const char *kp = SvPV_const(k, kl);
                if (is_arr) {
                    SV **cur = hv_fetch(out, kp, (I32)kl, 0);
                    AV *av;
                    if (cur && *cur && SvROK(*cur)
                        && SvTYPE(SvRV(*cur)) == SVt_PVAV) {
                        av = (AV *)SvRV(*cur);
                    } else {
                        av = newAV();
                        (void)hv_store(out, kp, (I32)kl,
                                       newRV_noinc((SV *)av), 0);
                    }
                    av_push(av, v);
                } else {
                    (void)hv_store(out, kp, (I32)kl, v, 0);
                }
            }
        }
        s = e + 1;
    }
    return out;
}

/* Parse a Cookie header ("a=b; c=d") into a fresh HV (raw values). */
static HV *oa_parse_cookies(pTHX_ const char *p, STRLEN l) {
    HV *out = newHV();
    STRLEN s = 0;
    while (s < l) {
        STRLEN e = s, eq;
        while (e < l && p[e] != ';') e++;
        while (s < e && isSPACE((U8)p[s])) s++;
        eq = s;
        while (eq < e && p[eq] != '=') eq++;
        if (eq > s && eq < e) {
            STRLEN ve = e;
            while (ve > eq + 1 && isSPACE((U8)p[ve - 1])) ve--;
            (void)hv_store(out, p + s, (I32)(eq - s),
                           newSVpvn(p + eq + 1, ve - eq - 1), 0);
        }
        s = e + 1;
    }
    return out;
}

/* ---- body ------------------------------------------------------------------- */

/* find the declared body entry for a Content-Type header value (parameters
 * after ';' ignored); NULL when the type is not declared */
static oa_body *oa_body_for(pTHX_ oa_op *o, SV *ctype_hdr) {
    STRLEN l, ml;
    const char *p;
    int i;
    if (!o->nbodies) return NULL;
    if (!ctype_hdr || !SvOK(ctype_hdr)) return NULL;
    p = SvPV_const(ctype_hdr, l);
    ml = 0;
    while (ml < l && p[ml] != ';') ml++;
    while (ml > 0 && isSPACE((U8)p[ml - 1])) ml--;
    for (i = 0; i < o->nbodies; i++) {
        STRLEN cl; const char *cp = SvPV_const(o->bodies[i].ctype, cl);
        if (cl == ml && memEQ(cp, p, ml)) return &o->bodies[i];
    }
    return NULL;
}

/* Decode JSON text through the frj ABI. The ABI croaks on malformed input,
 * so the decode runs inside the private _frj_decode trampoline (a direct ABI
 * call), invoked here on its cached CV with G_EVAL - a bad request body
 * becomes a 400, never an escaped die. Mortal SV on success, NULL on parse
 * failure. OA_DEC_CV is resolved in BOOT (API.xs). */
static SV *OA_DEC_CV = NULL;
static SV *OA_ENC_CV = NULL;

static SV *oa_body_decode(pTHX_ SV *text) {
    dSP; int count; SV *ret = NULL;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(text); PUTBACK;
    count = call_sv(OA_DEC_CV, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) { SV *r = POPs; if (SvOK(r)) ret = newSVsv(r); }
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    return ret ? sv_2mortal(ret) : NULL;
}

/* ---- the validation pipeline ------------------------------------------------ */

/* Validate a matched operation's inputs. All arguments may be NULL/absent
 * except the op. Returns 1/0; params_out (if non-NULL) receives a fresh HV
 * { path, query, header, cookie, body } on success. */
static int oa_validate_op(pTHX_ oa_api *a, oa_op *o,
                          HV *rawpath, SV *query, HV *headers, SV *body_raw,
                          HV **params_out, AV *errs) {
    HV *out = newHV();
    HV *op_ = newHV(), *oq = NULL, *oh = newHV(), *oc = newHV();
    int ok = 1, i;
    PERL_UNUSED_ARG(a);

    /* path captures: decode, validate, store */
    for (i = 0; i < o->nparams[OA_IN_PATH]; i++) {
        oa_param *pp = &o->params[OA_IN_PATH][i];
        STRLEN nl; const char *np = SvPV_const(pp->name, nl);
        SV **raw = rawpath ? hv_fetch(rawpath, np, (I32)nl, 0) : NULL;
        if (raw && *raw && SvOK(*raw)) {
            STRLEN vl; const char *vp = SvPV_const(*raw, vl);
            SV *dec = sv_2mortal(oa_pct_decode(aTHX_ vp, vl, 0));
            if (!oa_check(aTHX_ pp->handle, dec, errs, "path", pp->name)) ok = 0;
            else (void)hv_store(op_, np, (I32)nl, SvREFCNT_inc(dec), 0);
        } else {
            ok = 0;
            if (errs) oa_err_push(aTHX_ errs, "path", pp->name,
                                  "required", "missing required path parameter");
        }
        if (!ok && !errs) goto done;
    }

    /* query: string -> parse; hashref -> use as given */
    if (query && SvROK(query) && SvTYPE(SvRV(query)) == SVt_PVHV) {
        HV *src = (HV *)SvRV(query);
        HE *he;
        oq = newHV();
        hv_iterinit(src);
        while ((he = hv_iternext(src))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            (void)hv_store(oq, k, kl, newSVsv(hv_iterval(src, he)), 0);
        }
    } else if (query && SvOK(query)) {
        STRLEN ql; const char *qp = SvPV_const(query, ql);
        oq = oa_parse_query(aTHX_ o, qp, ql);
    } else {
        oq = newHV();
    }
    for (i = 0; i < o->nparams[OA_IN_QUERY]; i++) {
        oa_param *pp = &o->params[OA_IN_QUERY][i];
        STRLEN nl; const char *np = SvPV_const(pp->name, nl);
        SV **v = hv_fetch(oq, np, (I32)nl, 0);
        if (v && *v && SvOK(*v)) {
            if (!oa_check(aTHX_ pp->handle, *v, errs, "query", pp->name)) ok = 0;
        } else if (pp->required) {
            ok = 0;
            if (errs) oa_err_push(aTHX_ errs, "query", pp->name,
                                  "required", "missing required query parameter");
        }
        if (!ok && !errs) goto done;
    }

    /* headers: declared names looked up lowercased */
    for (i = 0; i < o->nparams[OA_IN_HEADER]; i++) {
        oa_param *pp = &o->params[OA_IN_HEADER][i];
        STRLEN nl; const char *np = SvPV_const(pp->name, nl);
        char lc[128];
        SV **v = NULL;
        if (nl < sizeof lc) {
            STRLEN k;
            for (k = 0; k < nl; k++) lc[k] = (char)toLOWER((U8)np[k]);
            v = headers ? hv_fetch(headers, lc, (I32)nl, 0) : NULL;
        }
        if (v && *v && SvOK(*v)) {
            if (!oa_check(aTHX_ pp->handle, *v, errs, "header", pp->name)) ok = 0;
            else (void)hv_store(oh, np, (I32)nl, newSVsv(*v), 0);
        } else if (pp->required) {
            ok = 0;
            if (errs) oa_err_push(aTHX_ errs, "header", pp->name,
                                  "required", "missing required header");
        }
        if (!ok && !errs) goto done;
    }

    /* cookies: parsed from the Cookie header only when declared */
    if (o->nparams[OA_IN_COOKIE]) {
        SV **ch = headers ? hv_fetchs(headers, "cookie", 0) : NULL;
        HV *jar = NULL;
        if (ch && *ch && SvOK(*ch)) {
            STRLEN cl; const char *cp = SvPV_const(*ch, cl);
            jar = oa_parse_cookies(aTHX_ cp, cl);
        }
        for (i = 0; i < o->nparams[OA_IN_COOKIE]; i++) {
            oa_param *pp = &o->params[OA_IN_COOKIE][i];
            STRLEN nl; const char *np = SvPV_const(pp->name, nl);
            SV **v = jar ? hv_fetch(jar, np, (I32)nl, 0) : NULL;
            if (v && *v && SvOK(*v)) {
                if (!oa_check(aTHX_ pp->handle, *v, errs, "cookie", pp->name)) ok = 0;
                else (void)hv_store(oc, np, (I32)nl, newSVsv(*v), 0);
            } else if (pp->required) {
                ok = 0;
                if (errs) oa_err_push(aTHX_ errs, "cookie", pp->name,
                                      "required", "missing required cookie");
            }
            if (!ok && !errs) { if (jar) SvREFCNT_dec((SV *)jar); goto done; }
        }
        if (jar) SvREFCNT_dec((SV *)jar);
    }

    /* body */
    if (o->nbodies) {
        SV **cth = headers ? hv_fetchs(headers, "content-type", 0) : NULL;
        int have = body_raw && SvOK(body_raw)
                   && (SvROK(body_raw) || SvCUR(body_raw) > 0);
        if (!have) {
            if (o->body_required) {
                ok = 0;
                if (errs) oa_err_push(aTHX_ errs, "body", NULL,
                                      "required", "missing required request body");
            }
        } else {
            oa_body *b = oa_body_for(aTHX_ o, cth ? *cth : NULL);
            if (!b) {
                ok = 0;
                if (errs) oa_err_push(aTHX_ errs, "body", NULL, "content-type",
                                      "undeclared request content type");
            } else if (b->handle) {
                SV *data = SvROK(body_raw) ? body_raw
                                           : oa_body_decode(aTHX_ body_raw);
                if (!data) {
                    ok = 0;
                    if (errs) oa_err_push(aTHX_ errs, "body", NULL, "json",
                                          "request body is not valid JSON");
                } else {
                    if (!oa_check(aTHX_ b->handle, data, errs, "body", NULL))
                        ok = 0;
                    else (void)hv_stores(out, "body", newSVsv(data));
                }
            } else {
                (void)hv_stores(out, "body", newSVsv(body_raw)); /* pass-through */
            }
        }
        if (!ok && !errs) goto done;
    }

done:
    if (ok && params_out) {
        (void)hv_stores(out, "path",   newRV_noinc((SV *)op_));
        (void)hv_stores(out, "query",  newRV_noinc((SV *)(oq ? oq : newHV())));
        (void)hv_stores(out, "header", newRV_noinc((SV *)oh));
        (void)hv_stores(out, "cookie", newRV_noinc((SV *)oc));
        *params_out = out;
    } else {
        SvREFCNT_dec((SV *)op_);
        if (oq) SvREFCNT_dec((SV *)oq);
        SvREFCNT_dec((SV *)oh);
        SvREFCNT_dec((SV *)oc);
        SvREFCNT_dec((SV *)out);
        if (params_out) *params_out = NULL;
    }
    return ok;
}

#endif /* OA_VALIDATE_H */

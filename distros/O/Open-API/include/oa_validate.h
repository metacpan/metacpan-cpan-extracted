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

/* ---- parameter serialization (style / explode) ------------------------------
 *
 * Split `l` bytes on `delim` into a fresh AV. `decode` percent-decodes each
 * piece AFTER the split, which is the only correct order: %2C is a comma that
 * belongs to the value, not a delimiter, so decoding first would split
 * `a%2Cb` into two elements.
 *
 * Header and cookie values are NOT decoded here. Header values never were,
 * and oa_parse_cookies deliberately keeps its values raw; decoding them now
 * would quietly change what every existing document sees. */
static SV *oa_split(pTHX_ const char *p, STRLEN l, char delim,
                    int decode, int plus) {
    AV *av = newAV();
    STRLEN s = 0;
    for (;;) {
        STRLEN e = s;
        while (e < l && p[e] != delim) e++;
        av_push(av, decode ? oa_pct_decode(aTHX_ p + s, e - s, plus)
                           : newSVpvn(p + s, e - s));
        if (e >= l) break;
        s = e + 1;
    }
    return newRV_noinc((SV *)av);
}

/* Split on any of `toks`, matched against the RAW text, decoding each piece
 * after. This exists beside oa_split because a comma and a space are not
 * symmetrical: `%2C` is an ESCAPED comma that belongs inside its element,
 * while a space can only reach us as `%20` or `+`, so for spaceDelimited
 * those encoded spellings ARE the delimiter. The spec offers no way to put a
 * literal space inside a spaceDelimited array, so none is invented here. */
static SV *oa_split_tokens(pTHX_ const char *p, STRLEN l,
                           const char *const *toks, int plus) {
    AV *av = newAV();
    STRLEN s = 0;
    for (;;) {
        STRLEN e = s;
        STRLEN tl = 0;
        while (e < l) {
            int t;
            for (t = 0; toks[t]; t++) {
                STRLEN len = (STRLEN)strlen(toks[t]);
                if (e + len <= l && memEQ(p + e, toks[t], len)) { tl = len; break; }
            }
            if (tl) break;
            e++;
        }
        av_push(av, oa_pct_decode(aTHX_ p + s, e - s, plus));
        if (e >= l) break;
        s = e + tl;
    }
    return newRV_noinc((SV *)av);
}

/* ---- object-typed parameters ------------------------------------------------
 *
 * Every style in the specification's Style Examples table can carry an object,
 * not just deepObject. Two shapes reach here, and which one depends only on
 * `explode`:
 *
 *   not exploded   R,100,G,200,B,150     a flat list, read as key,value pairs
 *   exploded       R=100.G=200.B=150     each piece is its own `key=value`
 *
 * The delimiter differs per style but the assembly does not, so both take an
 * already-split list. An odd trailing element in the pair form, or a piece with
 * no `=` in the exploded form, is skipped rather than guessed at: the schema
 * refuses the result afterwards, which is a better error than an invented one.
 */
static SV *oa_obj_from_pairs(pTHX_ SV *listrv) {
    AV *av = (AV *)SvRV(listrv);
    HV *h = newHV();
    SSize_t i, n = av_len(av) + 1;
    for (i = 0; i + 1 < n; i += 2) {
        SV **k = av_fetch(av, i, 0);
        SV **v = av_fetch(av, i + 1, 0);
        if (k && *k && v && *v) {
            STRLEN kl; const char *kp = SvPV_const(*k, kl);
            if (kl) (void)hv_store(h, kp, (I32)kl, newSVsv(*v), 0);
        }
    }
    return sv_2mortal(newRV_noinc((SV *)h));
}

static SV *oa_obj_from_kv(pTHX_ SV *listrv) {
    AV *av = (AV *)SvRV(listrv);
    HV *h = newHV();
    SSize_t i, n = av_len(av) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        STRLEN el; const char *ep, *eq;
        if (!e || !*e) continue;
        ep = SvPV_const(*e, el);
        eq = (const char *)memchr(ep, '=', el);
        if (!eq || eq == ep) continue;      /* no key, or no `=`: skip */
        (void)hv_store(h, ep, (I32)(eq - ep),
                       newSVpvn(eq + 1, el - (STRLEN)(eq - ep) - 1), 0);
    }
    return sv_2mortal(newRV_noinc((SV *)h));
}

/* A path parameter, per its style. The style's marker is stripped whether or
 * not the schema wants a list - `label` on a scalar is `.5` and `matrix` is
 * `;id=5`, so handling the marker only for arrays would leave scalars holding
 * it. Returns a mortal: a decoded scalar, or an arrayref of decoded pieces. */
static SV *oa_style_path(pTHX_ oa_param *pp, const char *vp, STRLEN vl) {
    char delim = ',';
    STRLEN nl = 0;
    const char *np = NULL;

    if (pp->style == OA_ST_LABEL) {
        if (vl && vp[0] == '.') { vp++; vl--; }
        if (pp->explode) delim = '.';
    }
    else if (pp->style == OA_ST_MATRIX) {
        np = SvPV_const(pp->name, nl);
        if (vl && vp[0] == ';') { vp++; vl--; }
        if (pp->explode) delim = ';';
        /* a leading `name=` is the style speaking, not the value */
        if (vl > nl && memEQ(vp, np, nl) && vp[nl] == '=') {
            vp += nl + 1; vl -= nl + 1;
        }
        /* `;color` with nothing after it is the EMPTY value, not the literal
         * string "color" - the name is the style speaking here too, and with
         * no `=` the strip above does not fire */
        else if (vl == nl && memEQ(vp, np, nl)) {
            vp += nl; vl = 0;
        }
    }

    /* An object is assembled from the same pieces an array would be, so the
     * split is shared - only what is built from it differs. Exploded matrix is
     * the one shape whose pieces still carry the parameter name, and for an
     * object they do not: `;R=100;G=200` names the MEMBERS, so the name strip
     * below is an array-only concern. */
    if (pp->is_object && !pp->is_array) {
        SV *rv = sv_2mortal(oa_split(aTHX_ vp, vl, delim, 1, 0));
        return pp->explode ? oa_obj_from_kv(aTHX_ rv)
                           : oa_obj_from_pairs(aTHX_ rv);
    }

    if (!pp->is_array)
        return sv_2mortal(oa_pct_decode(aTHX_ vp, vl, 0));

    {
        SV *rv = sv_2mortal(oa_split(aTHX_ vp, vl, delim, 1, 0));
        /* exploded matrix repeats the name: `;id=a;id=b` */
        if (pp->style == OA_ST_MATRIX && pp->explode && np) {
            AV *av = (AV *)SvRV(rv);
            SSize_t i, n = av_len(av) + 1;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(av, i, 0);
                if (e && *e) {
                    STRLEN el; const char *ep = SvPV_const(*e, el);
                    if (el > nl && memEQ(ep, np, nl) && ep[nl] == '=')
                        sv_setpvn(*e, ep + nl + 1, el - nl - 1);
                }
            }
        }
        return rv;
    }
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

static SV *oa_body_decode(pTHX_ SV *text);   /* defined below */

/* One declared parameter against its value.
 *
 * The ordinary case is a straight schema check. A parameter declared with
 * `content` rather than `schema` carries a document of that media type in a
 * single value - `?filter={"a":1}` - so the value is decoded first and the
 * schema then sees the structure it was written about. An undecodable value is
 * a 400 rather than a silent pass, exactly as a request body is; a media type
 * with no decoder is left alone, as an undeclared body type is. */
static int oa_check_param(pTHX_ oa_param *pp, SV *value, AV *errs,
                          const char *in) {
    SV *data = value;
    if (!pp->handle) return 1;
    if (pp->ctype) {
        STRLEN cl; const char *cp = SvPV_const(pp->ctype, cl);
        if (!oa_ctype_is_json(cp, cl)) return 1;
        if (!SvROK(value)) {
            data = oa_body_decode(aTHX_ value);
            if (!data) {
                if (errs) oa_err_push(aTHX_ errs, in, pp->name, "content",
                                      "parameter is not valid JSON");
                return 0;
            }
        }
    }
    return oa_check(aTHX_ pp->handle, data, errs, in, pp->name);
}

/* ---- query / cookie parsing ------------------------------------------------ */

/* Parse a query string into a fresh HV: every key decoded; a key is an
 * arrayref when the op declares that query parameter as array-typed (repeat
 * keys accumulate), else last value wins. Undeclared keys are kept (string). */
static HV *oa_parse_query(pTHX_ oa_op *o, const char *qs, STRLEN ql) {
    /* a space reaches us only encoded, so both spellings are the delimiter */
    static const char *const tok_space[] = { "%20", "+", " ", NULL };
    static const char *const tok_pipe[]  = { "%7C", "%7c", "|", NULL };
    HV *out = newHV();
    STRLEN s = 0;
    while (s < ql) {
        STRLEN e = s, eq;
        SV *k, *v;
        int i;
        oa_param *pp = NULL;
        const char *rawv;
        STRLEN rawvl;

        while (e < ql && qs[e] != '&') e++;
        eq = s;
        while (eq < e && qs[eq] != '=') eq++;
        if (eq > s) {
            k = sv_2mortal(oa_pct_decode(aTHX_ qs + s, eq - s, 1));
            /* the RAW value: the declared parameter is found first, because
             * a style has to split before anything is decoded */
            rawv  = qs + (eq < e ? eq + 1 : e);
            rawvl = eq < e ? e - eq - 1 : 0;

            for (i = 0; i < o->nparams[OA_IN_QUERY]; i++) {
                if (sv_eq(o->params[OA_IN_QUERY][i].name, k)) {
                    pp = &o->params[OA_IN_QUERY][i];
                    break;
                }
            }

            /* deepObject: `v[k]=x` is a MEMBER of the parameter named `v`, so
             * the key on the wire is not the parameter's name and the lookup
             * above can never find it. It also accumulates into a hash rather
             * than replacing a value, so it is settled here, before the
             * ordinary store. Object-typed, so the is_array gate that guards
             * every other style does not apply. */
            if (!pp) {
                STRLEN dkl; const char *dkp = SvPV_const(k, dkl);
                const char *br = (dkl > 2 && dkp[dkl - 1] == ']')
                               ? (const char *)memchr(dkp, '[', dkl) : NULL;
                int deep = 0;
                if (br && br > dkp) {
                    STRLEN bl  = (STRLEN)(br - dkp);      /* the name   */
                    STRLEN sbl = dkl - bl - 2;            /* inside [ ] */
                    for (i = 0; i < o->nparams[OA_IN_QUERY]; i++) {
                        oa_param *c = &o->params[OA_IN_QUERY][i];
                        STRLEN cnl; const char *cnp = SvPV_const(c->name, cnl);
                        SV **cur;
                        HV *bag;
                        if (c->style != OA_ST_DEEP) continue;
                        if (cnl != bl || memNE(cnp, dkp, bl)) continue;
                        cur = hv_fetch(out, cnp, (I32)cnl, 0);
                        if (cur && *cur && SvROK(*cur)
                            && SvTYPE(SvRV(*cur)) == SVt_PVHV) {
                            bag = (HV *)SvRV(*cur);
                        } else {
                            bag = newHV();
                            (void)hv_store(out, cnp, (I32)cnl,
                                           newRV_noinc((SV *)bag), 0);
                        }
                        (void)hv_store(bag, br + 1, (I32)sbl,
                                       oa_pct_decode(aTHX_ rawv, rawvl, 1), 0);
                        deep = 1;
                        break;
                    }
                }
                /* form + explode on an object spreads the MEMBERS as top-level
                 * keys: `R=100&G=200&B=150`. Nothing on the wire ties them to
                 * the parameter, so the declared property names are the only
                 * link - which is why they are compiled in. A key matching no
                 * declared property falls through and is stored as itself. */
                if (!deep) {
                    for (i = 0; i < o->nparams[OA_IN_QUERY]; i++) {
                        oa_param *c = &o->params[OA_IN_QUERY][i];
                        AV *names;
                        SSize_t pi, pn;
                        STRLEN cnl; const char *cnp;
                        if (!c->is_object || c->is_array) continue;
                        if (c->style != OA_ST_FORM || !c->explode) continue;
                        if (!c->props) continue;
                        names = (AV *)SvRV(c->props);
                        pn = av_len(names) + 1;
                        for (pi = 0; pi < pn; pi++) {
                            SV **nm = av_fetch(names, pi, 0);
                            if (nm && *nm && sv_eq(*nm, k)) break;
                        }
                        if (pi == pn) continue;          /* not a member */
                        cnp = SvPV_const(c->name, cnl);
                        {
                            SV **cur = hv_fetch(out, cnp, (I32)cnl, 0);
                            HV *bag;
                            if (cur && *cur && SvROK(*cur)
                                && SvTYPE(SvRV(*cur)) == SVt_PVHV) {
                                bag = (HV *)SvRV(*cur);
                            } else {
                                bag = newHV();
                                (void)hv_store(out, cnp, (I32)cnl,
                                               newRV_noinc((SV *)bag), 0);
                            }
                            {
                                STRLEN mkl; const char *mkp = SvPV_const(k, mkl);
                                (void)hv_store(bag, mkp, (I32)mkl,
                                               oa_pct_decode(aTHX_ rawv, rawvl, 1), 0);
                            }
                            deep = 1;
                        }
                        break;
                    }
                }
                if (deep) { s = e + 1; continue; }
            }
            {
                STRLEN kl; const char *kp = SvPV_const(k, kl);
                int delimited = 0;

                /* an OBJECT arriving in one value: the same split as the list
                 * form, read as key,value pairs rather than as elements */
                if (pp && pp->is_object && !pp->is_array) {
                    SV *pieces = NULL;
                    if (pp->style == OA_ST_SPACE)
                        pieces = oa_split_tokens(aTHX_ rawv, rawvl, tok_space, 1);
                    else if (pp->style == OA_ST_PIPE)
                        pieces = oa_split_tokens(aTHX_ rawv, rawvl, tok_pipe, 1);
                    else if (pp->style == OA_ST_FORM && !pp->explode)
                        pieces = oa_split(aTHX_ rawv, rawvl, ',', 1, 1);
                    if (pieces) {
                        SV *obj = oa_obj_from_pairs(aTHX_ sv_2mortal(pieces));
                        (void)hv_store(out, kp, (I32)kl, SvREFCNT_inc(obj), 0);
                        s = e + 1;
                        continue;
                    }
                }

                /* a style whose list arrives in ONE value */
                if (pp && pp->is_array) {
                    if (pp->style == OA_ST_SPACE) {
                        v = oa_split_tokens(aTHX_ rawv, rawvl, tok_space, 1);
                        delimited = 1;
                    }
                    else if (pp->style == OA_ST_PIPE) {
                        v = oa_split_tokens(aTHX_ rawv, rawvl, tok_pipe, 1);
                        delimited = 1;
                    }
                    else if (pp->style == OA_ST_FORM && !pp->explode) {
                        v = oa_split(aTHX_ rawv, rawvl, ',', 1, 1);
                        delimited = 1;
                    }
                }
                if (delimited) {
                    (void)hv_store(out, kp, (I32)kl, v, 0);
                    s = e + 1;
                    continue;
                }

                v = oa_pct_decode(aTHX_ rawv, rawvl, 1);

                /* form + explode (the default): repeat keys accumulate.
                 * Unchanged, and it is what every document that declares no
                 * style at all goes through. */
                if (pp && pp->is_array) {
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

/* The declared entry covering this Content-Type, most specific first: an
 * exact type beats a type-level range, which beats the catch-all range.
 * Matching is case-insensitive per RFC 7231 and ignores parameters; NULL when
 * nothing declared covers the type. */
static oa_body *oa_body_for(pTHX_ oa_op *o, SV *ctype_hdr) {
    STRLEN l;
    const char *p;
    int i;
    oa_body *star = NULL, *type_star = NULL;
    if (!o->nbodies) return NULL;
    if (!ctype_hdr || !SvOK(ctype_hdr)) return NULL;
    p = SvPV_const(ctype_hdr, l);
    for (i = 0; i < o->nbodies; i++) {
        STRLEN cl; const char *cp = SvPV_const(o->bodies[i].ctype, cl);
        STRLEN cb, ce;
        oa_ctype_span(cp, cl, &cb, &ce);
        if (ce - cb == 3 && memEQ(cp + cb, "*/*", 3)) {
            if (!star) star = &o->bodies[i];
            continue;
        }
        if ((ce - cb) > 2 && cp[ce - 1] == '*' && cp[ce - 2] == '/') {
            if (!type_star && oa_ctype_matches(cp, cl, p, l))
                type_star = &o->bodies[i];
            continue;
        }
        if (oa_ctype_matches(cp, cl, p, l)) return &o->bodies[i];
    }
    return type_star ? type_star : star;
}

/* ---- form bodies ------------------------------------------------------------
 *
 * Neither of these goes through the frj ABI: a form body is not JSON. They
 * build the same shape a decoded JSON object would have, so one schema
 * validates either spelling.
 *
 * A repeat key becomes an arrayref, because a form carries repeats naturally
 * (checkboxes, multi-selects) and a schema saying `type: array` must see one. */
static void oa_form_add(pTHX_ HV *out, SV *key, SV *val) {
    STRLEN kl; const char *kp = SvPV_const(key, kl);
    SV **cur = hv_fetch(out, kp, (I32)kl, 0);
    if (cur && *cur) {
        AV *list;
        if (SvROK(*cur) && SvTYPE(SvRV(*cur)) == SVt_PVAV) list = (AV *)SvRV(*cur);
        else {
            list = newAV();
            av_push(list, newSVsv(*cur));
            (void)hv_store(out, kp, (I32)kl, newRV_noinc((SV *)list), 0);
        }
        av_push(list, val);
        return;
    }
    (void)hv_store(out, kp, (I32)kl, val, 0);
}

/* application/x-www-form-urlencoded. Mortal hashref; never NULL - an empty
 * body is an empty object, which a schema is entitled to reject. */
static SV *oa_form_decode(pTHX_ SV *text, SV *encoding) {
    STRLEN l; const char *p = SvPV_const(text, l);
    HV *out = newHV();
    HV *enc = (encoding && SvROK(encoding)
               && SvTYPE(SvRV(encoding)) == SVt_PVHV)
            ? (HV *)SvRV(encoding) : NULL;
    STRLEN s = 0;
    while (s < l) {
        STRLEN e = s, eq;
        while (e < l && p[e] != '&') e++;
        eq = s;
        while (eq < e && p[eq] != '=') eq++;
        if (eq > s) {
            SV *k = sv_2mortal(oa_pct_decode(aTHX_ p + s, eq - s, 1));
            const char *rawv = p + (eq < e ? eq + 1 : e);
            STRLEN rawvl = eq < e ? e - eq - 1 : 0;
            SV *v = NULL;
            /* An Encoding Object may say this property is a delimited list.
             * The split is on the RAW span, BEFORE decoding, so an escaped
             * delimiter stays inside its element - `a=x%2Cy` is one value
             * containing a comma, not two values. Same asymmetry the query
             * styles turn on, and the reason the encoding has to reach the
             * decoder rather than being applied to its output. */
            if (enc) {
                STRLEN kl2; const char *kp2 = SvPV_const(k, kl2);
                SV **es = hv_fetch(enc, kp2, (I32)kl2, 0);
                HV *eh  = (es && *es) ? oa_hv_of(*es) : NULL;
                if (eh) {
                    SV *st = oa_get(aTHX_ eh, "style");
                    SV *ex = oa_get(aTHX_ eh, "explode");
                    STRLEN sl2 = 0;
                    const char *sp2 = st ? SvPV_const(st, sl2) : NULL;
                    /* `form` is the default style here, and it explodes by
                     * default - so only an explicit explode:false makes a
                     * form property a delimited list */
                    int exploded = ex ? (oa_sv_truthy(aTHX_ ex) ? 1 : 0) : 1;
                    int isform  = !sp2 || (sl2 ==  4 && memEQ(sp2, "form", 4));
                    int isspace = sp2 && sl2 == 14 && memEQ(sp2, "spaceDelimited", 14);
                    int ispipe  = sp2 && sl2 == 13 && memEQ(sp2, "pipeDelimited", 13);
                    if (isform && !exploded)
                        v = oa_split(aTHX_ rawv, rawvl, ',', 1, 1);
                    else if (isspace) {
                        static const char *const tok_sp[] = { "%20", "+", " ", NULL };
                        v = oa_split_tokens(aTHX_ rawv, rawvl, tok_sp, 1);
                    }
                    else if (ispipe) {
                        static const char *const tok_pp[] = { "%7C", "%7c", "|", NULL };
                        v = oa_split_tokens(aTHX_ rawv, rawvl, tok_pp, 1);
                    }
                }
            }
            if (!v) v = oa_pct_decode(aTHX_ rawv, rawvl, 1);
            oa_form_add(aTHX_ out, k, v);
        }
        s = e + 1;
    }
    return sv_2mortal(newRV_noinc((SV *)out));
}

/* Apply an Encoding Object to a decoded form body. A property whose encoding
 * names a JSON media type carries a whole document in one field - the
 * `a={"n":"x"}` idiom - so it is decoded before the schema sees it, exactly
 * as a parameter declared with `content` is. A field that is already a
 * reference (a repeat promoted to an arrayref) is left alone, and a value
 * that will not decode is left as text for the schema to refuse. */
static void oa_apply_encoding(pTHX_ SV *data, SV *encoding) {
    HV *d, *e;
    HE *he;
    if (!data || !SvROK(data) || SvTYPE(SvRV(data)) != SVt_PVHV) return;
    if (!encoding || !SvROK(encoding) || SvTYPE(SvRV(encoding)) != SVt_PVHV) return;
    d = (HV *)SvRV(data);
    e = (HV *)SvRV(encoding);
    hv_iterinit(e);
    while ((he = hv_iternext(e))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        HV *spec = oa_hv_of(hv_iterval(e, he));
        SV *ct = spec ? oa_get(aTHX_ spec, "contentType") : NULL;
        SV **slot;
        STRLEN cl; const char *cp;
        if (!ct) continue;
        cp = SvPV_const(ct, cl);
        if (!oa_ctype_is_json(cp, cl)) continue;
        slot = hv_fetch(d, k, kl, 0);
        if (slot && *slot && SvOK(*slot) && !SvROK(*slot)) {
            SV *dec = oa_body_decode(aTHX_ *slot);
            if (dec) (void)hv_store(d, k, kl, newSVsv(dec), 0);
        }
    }
}

/* An Encoding Object may declare `headers` for a multipart part - a map of
 * Header Objects, exactly as a response declares them. A declared `required`
 * header that the part does not carry is a bad request, and nothing else
 * would report it: the part's headers are not part of the value the schema
 * sees. Header names are compared case-insensitively, per RFC 7231. */
static int oa_check_encoding_headers(pTHX_ SV *encoding, HV *part_hdrs,
                                     AV *errs) {
    HV *e;
    HE *he;
    int ok = 1;
    if (!encoding || !SvROK(encoding) || SvTYPE(SvRV(encoding)) != SVt_PVHV)
        return 1;
    if (!part_hdrs) return 1;
    e = (HV *)SvRV(encoding);
    hv_iterinit(e);
    while ((he = hv_iternext(e))) {
        I32 pkl; const char *pk = hv_iterkey(he, &pkl);
        HV *spec = oa_hv_of(hv_iterval(e, he));
        HV *want = spec ? oa_hv_of(oa_get(aTHX_ spec, "headers")) : NULL;
        SV **got = hv_fetch(part_hdrs, pk, pkl, 0);
        HV *have = (got && *got) ? oa_hv_of(*got) : NULL;
        HE *whe;
        if (!want) continue;
        hv_iterinit(want);
        while ((whe = hv_iternext(want))) {
            I32 hkl; const char *hk = hv_iterkey(whe, &hkl);
            HV *hspec = oa_hv_of(hv_iterval(want, whe));
            SV *req = hspec ? oa_get(aTHX_ hspec, "required") : NULL;
            int found = 0;
            if (!req || !oa_sv_truthy(aTHX_ req)) continue;
            if (have) {
                HE *ghe;
                hv_iterinit(have);
                while ((ghe = hv_iternext(have))) {
                    I32 gkl; const char *gk = hv_iterkey(ghe, &gkl);
                    if (oa_ci_eq(gk, (STRLEN)gkl, hk, (STRLEN)hkl))
                        { found = 1; break; }
                }
            }
            if (!found) {
                ok = 0;
                if (errs) {
                    SV *nm = sv_2mortal(newSVpvn(hk, (STRLEN)hkl));
                    oa_err_push(aTHX_ errs, "body", nm, "required",
                                "multipart part is missing a required "
                                "encoding header");
                }
            }
        }
    }
    return ok;
}

/* the value of a header parameter: name=value or name="value" */
static const char *oa_hdr_param(const char *s, STRLEN sl, const char *name,
                                STRLEN *vl) {
    STRLEN nl = strlen(name), i;
    for (i = 0; i + nl + 1 <= sl; i++) {
        if ((i == 0 || s[i-1] == ' ' || s[i-1] == ';' || s[i-1] == '\t')
            && oa_ci_eq(s + i, nl, name, nl) && s[i + nl] == '=') {
            const char *v = s + i + nl + 1;
            const char *e;
            if (v < s + sl && *v == '"') { v++; e = v;
                                           while (e < s + sl && *e != '"') e++; }
            else { e = v; while (e < s + sl && *e != ';') e++; }
            *vl = (STRLEN)(e - v);
            return v;
        }
    }
    return NULL;
}

/* multipart/form-data. The boundary lives in the Content-Type's parameters,
 * which is why the FULL header is needed here and not the trimmed type.
 * Field parts become values; a part with a filename keeps its content, since
 * a schema can only speak about what is in the body. NULL when there is no
 * boundary to walk - that is a malformed request, not an empty one. */
/* `part_hdrs`, when given, is filled with part name => { header => value }.
 * The decoded body itself stays a plain name => value map, because that is
 * what the schema validates - an Encoding Object's declared headers are a
 * separate question, asked separately. Pass NULL to not collect them. */
static SV *oa_multipart_decode(pTHX_ SV *text, const char *ct, STRLEN ctl,
                               HV *part_hdrs) {
    STRLEN bl = 0, l;
    const char *bp = oa_hdr_param(ct, ctl, "boundary", &bl);
    const char *body, *end, *p;
    SV *dash;
    HV *out;
    if (!bp || !bl) return NULL;
    body = SvPV_const(text, l);
    end  = body + l;
    dash = sv_2mortal(newSVpvs("--"));
    sv_catpvn(dash, bp, bl);
    {
        char *dp = SvPVX(dash);
        STRLEN dl = SvCUR(dash);
        p = ninstr((char *)body, (char *)end, dp, dp + dl);
        if (!p) return NULL;
        out = newHV();
        p += dl;
        while (p < end) {
            const char *hend, *nd, *content, *hp;
            STRLEN nlen = 0;
            const char *nm = NULL;
            HV *hdrs_here;
            if (p + 2 <= end && p[0] == '-' && p[1] == '-') break;  /* closing */
            while (p < end && (*p == '\r' || *p == '\n')) p++;
            {   /* both ends of the needle must come from ONE object: two
                 * spellings of the same literal are two objects, so `lit + n`
                 * would point past a different array than `lit` */
                const char *crlf2 = "\r\n\r\n";
                hend = ninstr((char *)p, (char *)end,
                              (char *)crlf2, (char *)crlf2 + 4);
            }
            if (!hend) break;
            hdrs_here = part_hdrs ? (HV *)sv_2mortal((SV *)newHV()) : NULL;
            for (hp = p; hp < hend; ) {
                const char *crlf = "\r\n";
                const char *le = ninstr((char *)hp, (char *)hend,
                                        (char *)crlf, (char *)crlf + 2);
                STRLEN ll = (STRLEN)((le ? le : hend) - hp);
                if (ll >= 20 && oa_ci_eq(hp, 20, "Content-Disposition:", 20))
                    nm = oa_hdr_param(hp, ll, "name", &nlen);
                /* every header line, kept for the encoding check. The name is
                 * everything before the colon; the value is what follows,
                 * with leading space trimmed. */
                if (hdrs_here) {
                    STRLEN c = 0;
                    while (c < ll && hp[c] != ':') c++;
                    if (c > 0 && c < ll) {
                        STRLEN vs = c + 1;
                        while (vs < ll && (hp[vs] == ' ' || hp[vs] == '\t')) vs++;
                        (void)hv_store(hdrs_here, hp, (I32)c,
                                       newSVpvn(hp + vs, ll - vs), 0);
                    }
                }
                if (!le) break;
                hp = le + 2;
            }
            content = hend + 4;
            nd = ninstr((char *)content, (char *)end, dp, dp + dl);
            if (!nd) break;
            if (nm) {
                STRLEN clen = (STRLEN)(nd - content);
                while (clen >= 2 && content[clen-1] == '\n' && content[clen-2] == '\r')
                    clen -= 2;                       /* the CRLF before --bound */
                oa_form_add(aTHX_ out, sv_2mortal(newSVpvn(nm, nlen)),
                            newSVpvn(content, clen));
                if (part_hdrs && hdrs_here)
                    (void)hv_store(part_hdrs, nm, (I32)nlen,
                                   newRV_inc((SV *)hdrs_here), 0);
            }
            p = nd + dl;
        }
    }
    return sv_2mortal(newRV_noinc((SV *)out));
}

/* Decode JSON text through the frj ABI. The ABI croaks on malformed input,
 * so the decode runs inside the private _frj_decode trampoline (a direct ABI
 * call), invoked here on its cached CV with G_EVAL - a bad request body
 * becomes a 400, never an escaped die. Mortal SV on success, NULL on parse
 * failure. OA_DEC_CV is resolved in BOOT (API.xs). */
static SV *OA_DEC_CV = NULL;
static SV *OA_ENC_CV = NULL;

/* `*ok` separates the two things a NULL return used to mean: the text was not
 * JSON at all, and the text was the JSON document `null`. They are not the
 * same - `null` is a valid JSON text (RFC 8259) and `type: null` is a valid
 * 3.1 schema, which is also what a 3.0 `nullable` converts INTO - and folding
 * them together reported a conforming null body as malformed JSON.
 *
 * On success with a null document this returns NULL with *ok true, so a caller
 * that does not care keeps its old behaviour exactly. */
static SV *oa_body_decode_ok(pTHX_ SV *text, int *ok) {
    dSP; int count; SV *ret = NULL;
    *ok = 0;
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(text); PUTBACK;
    count = call_sv(OA_DEC_CV, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (!SvTRUE(ERRSV) && count > 0) {
        SV *r = POPs;
        *ok = 1;
        if (SvOK(r)) ret = newSVsv(r);
    }
    else if (count > 0) (void)POPs;
    PUTBACK; FREETMPS; LEAVE;
    return ret ? sv_2mortal(ret) : NULL;
}

static SV *oa_body_decode(pTHX_ SV *text) {
    int ok;
    return oa_body_decode_ok(aTHX_ text, &ok);
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
            SV *dec = oa_style_path(aTHX_ pp, vp, vl);
            if (!oa_check_param(aTHX_ pp, dec, errs, "path")) ok = 0;
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
            /* present and empty, with allowEmptyValue: permitted as it
             * stands rather than handed to a schema that will refuse it */
            if (pp->allow_empty && !SvROK(*v) && SvCUR(*v) == 0) {
                /* accepted */
            }
            else if (!oa_check_param(aTHX_ pp, *v, errs, "query")) ok = 0;
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
            SV *val = *v;
            /* header is always `simple`: a list is comma separated, and the
             * value is not percent-encoded, so it is split but not decoded */
            if (pp->is_array) {
                STRLEN hl; const char *hp = SvPV_const(val, hl);
                val = sv_2mortal(oa_split(aTHX_ hp, hl, ',', 0, 0));
            }
            /* an object is comma separated too, and explode decides whether
             * the pieces are `k,v` pairs or their own `k=v` */
            else if (pp->is_object) {
                STRLEN hl; const char *hp = SvPV_const(val, hl);
                SV *pieces = sv_2mortal(oa_split(aTHX_ hp, hl, ',', 0, 0));
                val = pp->explode ? oa_obj_from_kv(aTHX_ pieces)
                                  : oa_obj_from_pairs(aTHX_ pieces);
            }
            if (!oa_check_param(aTHX_ pp, val, errs, "header")) ok = 0;
            else (void)hv_store(oh, np, (I32)nl, newSVsv(val), 0);
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
                SV *val = *v;
                /* cookie is `form`; a list is comma separated. Values are
                 * kept raw by oa_parse_cookies, so split without decoding */
                if (pp->is_array) {
                    STRLEN cl2; const char *cp2 = SvPV_const(val, cl2);
                    val = sv_2mortal(oa_split(aTHX_ cp2, cl2, ',', 0, 0));
                }
                /* an object cookie is assembled the way a header one is:
                 * comma separated, `k,v` pairs or `k=v` when exploded */
                else if (pp->is_object) {
                    STRLEN cl2; const char *cp2 = SvPV_const(val, cl2);
                    SV *pieces = sv_2mortal(oa_split(aTHX_ cp2, cl2, ',', 0, 0));
                    val = pp->explode ? oa_obj_from_kv(aTHX_ pieces)
                                      : oa_obj_from_pairs(aTHX_ pieces);
                }
                if (!oa_check_param(aTHX_ pp, val, errs, "cookie")) ok = 0;
                else (void)hv_store(oc, np, (I32)nl, newSVsv(val), 0);
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
                /* A range declares no decoder of its own, so the REQUEST's
                 * content type decides. Without this a catch-all range would
                 * match and then pass through unvalidated - a silent
                 * acceptance, worse than the wrong rejection it replaced. */
                STRLEN ctl = 0;
                const char *ctp = (cth && *cth && SvOK(*cth))
                                ? SvPV_const(*cth, ctl) : NULL;
                int kind = b->kind;
                SV *data;
                /* a JSON body that decoded cleanly to the document `null`:
                 * data is NULL but nothing is wrong with it */
                int json_null = 0;
                HV *part_hdrs = NULL;   /* multipart, when an encoding asks */
                if (kind == OA_MT_RANGE)
                    kind = ctp ? oa_ctype_kind(ctp, ctl) : OA_MT_OPAQUE;

                if (SvROK(body_raw))            data = body_raw;
                else if (kind == OA_MT_FORM)
                    data = oa_form_decode(aTHX_ body_raw, b->encoding);
                else if (kind == OA_MT_MULTIPART) {
                    if (b->encoding)
                        part_hdrs = (HV *)sv_2mortal((SV *)newHV());
                    data = ctp ? oa_multipart_decode(aTHX_ body_raw, ctp, ctl,
                                                     part_hdrs) : NULL;
                }
                else if (kind == OA_MT_JSON) {
                    int dec_ok;
                    data = oa_body_decode_ok(aTHX_ body_raw, &dec_ok);
                    json_null = dec_ok && !data;
                }
                else {
                    /* a range covering something we cannot decode: preserve
                     * the pass-through rather than invent a verdict */
                    (void)hv_stores(out, "body", newSVsv(body_raw));
                    goto body_done;
                }

                /* the Encoding Object, once the body IS properties */
                if (data && b->encoding) {
                    oa_apply_encoding(aTHX_ data, b->encoding);
                    if (!oa_check_encoding_headers(aTHX_ b->encoding,
                                                   part_hdrs, errs))
                        ok = 0;
                }

                if (!data && json_null) {
                    /* the document IS null. Hand the schema an undef so it can
                     * say whether `null` was allowed here, rather than calling
                     * a well-formed body malformed. */
                    if (!oa_check(aTHX_ b->handle, &PL_sv_undef, errs,
                                  "body", NULL))
                        ok = 0;
                } else if (!data) {
                    ok = 0;
                    if (errs) oa_err_push(aTHX_ errs, "body", NULL,
                        kind == OA_MT_MULTIPART ? "multipart" : "json",
                        kind == OA_MT_MULTIPART
                            ? "request body is not valid multipart/form-data"
                            : "request body is not valid JSON");
                } else {
                    if (!oa_check(aTHX_ b->handle, data, errs, "body", NULL))
                        ok = 0;
                    else (void)hv_stores(out, "body", newSVsv(data));
                }
            } else {
                (void)hv_stores(out, "body", newSVsv(body_raw)); /* pass-through */
            }
        }
body_done:
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

#ifndef OA_MOCK_H
#define OA_MOCK_H

#include <math.h>

/* Response synthesis: a body for an operation + status, from the document
 * alone. This is what serves a mock - paste a spec, get a working API - so
 * two properties outrank everything else here:
 *
 *   DETERMINISTIC. The same request produces byte-identical bodies, every
 *   time, because a mock that changes under you is useless for tests.
 *   There is no randomness anywhere below - "first" always means the same
 *   member, formats map to fixed strings, numbers sit on their bounds.
 *
 *   SELF-CONSISTENT. What the generator produces must validate against the
 *   schema it was produced from - the mock may not generate something its
 *   own validator rejects. That is a gate (a property test over whole
 *   specs), not an aspiration, and it is why the generator honours the
 *   constraining keywords (enum, const, minimum, minLength, minItems,
 *   required) rather than emitting the friendliest-looking value.
 *
 * The body for a chosen response is, in order:
 *
 *   1. the media type's `example`
 *   2. the media type's named `examples` - the requested name when
 *      `Prefer: example=name` asked for one, the lexicographically first
 *      entry otherwise (hash order would be per-process noise)
 *   3. the (resolved) schema's `default`
 *   4. a value generated from the schema
 *
 * Status selection: `Prefer: code=404` picks a declared status; without a
 * preference the lowest declared 2xx wins, then `default` (as 200), then
 * the lowest declared status. A preferred status the document does not
 * declare is still answered - with the `default` response's body when one
 * is declared, empty otherwise - because the point of Prefer is exercising
 * error handling, and refusing undeclared codes would make the feature
 * useless against the specs that need it most. */

/* generated strings are padded to minLength at most this far - a pasted
 * spec must not be able to ask a mock for a gigabyte of 'a' */
#define OA_MOCK_MAX_PAD 4096

/* recursion guard: $ref cycles and pathological nesting synthesize null
 * past this depth rather than recursing forever */
#define OA_MOCK_MAX_DEPTH 32

/* How many elements an array gets when the document does not say.
 *
 * Not zero, which is what `minItems` absent literally means and which is
 * a correct answer to the wrong question: a list endpoint that mocks as
 * [] validates perfectly and tells the caller nothing about the shape of
 * what they will get. Not one either - a single-element list is a shape
 * you cannot build a table, a pagination control or an empty-state
 * against. Five is enough to look like data and small enough to read.
 *
 * `minItems` still raises it and `maxItems` still caps it, including
 * `maxItems: 0` where the document has said it means empty. */
#define OA_MOCK_ARRAY_ITEMS 5

/* ---- the document, by JSON pointer ---------------------------------------- */

/* "#/components/schemas/Pet" -> the node, or NULL. Borrowed. */
static SV *oa_doc_at(pTHX_ HV *doc, const char *ref, STRLEN rl) {
    SV *node = NULL;
    STRLEN i = 0;
    if (!doc || rl < 2 || ref[0] != '#' || ref[1] != '/') return NULL;
    i = 2;
    while (i <= rl) {
        char seg[256];
        STRLEN sl = 0, e = i;
        while (e < rl && ref[e] != '/') e++;
        /* unescape ~1 -> '/', ~0 -> '~' */
        while (i < e && sl + 1 < sizeof seg) {
            if (ref[i] == '~' && i + 1 < e && (ref[i+1] == '0' || ref[i+1] == '1')) {
                seg[sl++] = ref[i+1] == '1' ? '/' : '~';
                i += 2;
            } else seg[sl++] = ref[i++];
        }
        if (!node) {
            SV **v = hv_fetch(doc, seg, (I32)sl, 0);
            node = (v && *v) ? *v : NULL;
        } else if (oa_hv_of(node)) {
            SV **v = hv_fetch(oa_hv_of(node), seg, (I32)sl, 0);
            node = (v && *v) ? *v : NULL;
        } else if (oa_av_of(node)) {
            char *end = NULL;
            long ix = strtol(seg, &end, 10);
            SV **v;
            if (!end || *end || ix < 0) return NULL;
            v = av_fetch(oa_av_of(node), (SSize_t)ix, 0);
            node = (v && *v) ? *v : NULL;
        } else return NULL;
        if (!node) return NULL;
        i = e + 1;
    }
    return node;
}

/* follow $ref until a concrete schema (or the depth guard). Borrowed. */
static SV *oa_mock_deref(pTHX_ HV *doc, SV *schema, int depth) {
    int hops = 0;
    while (schema && hops++ < OA_MOCK_MAX_DEPTH) {
        HV *h = oa_hv_of(schema);
        SV *r = h ? oa_get(aTHX_ h, "$ref") : NULL;
        STRLEN rl; const char *rp;
        if (!r || SvROK(r)) return schema;
        rp = SvPV_const(r, rl);
        schema = oa_doc_at(aTHX_ doc, rp, rl);
    }
    PERL_UNUSED_VAR(depth);
    return schema;
}

/* ---- generation ------------------------------------------------------------ */

/* `caps` is the request's path captures, or NULL. A generated object
 * prefers a captured value for a property it names - see oa_gen_echo -
 * so `GET /pets/42` answers with id 42 rather than with the schema's
 * placeholder. It is threaded through rather than consulted globally
 * because a mock that echoed at every depth would put the pet's id on
 * the owner and the vet as well. */
static SV *oa_gen(pTHX_ HV *doc, SV *schema, HV *caps, int depth);   /* forward */
static SV *oa_gen_type_of(pTHX_ HV *h);                              /* forward */

/* Does `val` (always a string, off the wire) satisfy this schema well
 * enough to answer with? Returns the value to use - coerced to the
 * declared type - or NULL to generate instead.
 *
 * Conservative on purpose. The mock's contract is that it cannot
 * produce something its own validator would reject, and this is the one
 * place a value arrives that the document did not write. So anything
 * this cannot check, it refuses: a `pattern` is not evaluated here, and
 * its presence alone sends the value back to the generator. */
static SV *oa_gen_fits(pTHX_ HV *h, SV *val) {
    SV *t;
    STRLEN tl, vl;
    const char *tp, *vp;
    SV *e;

    if (!h || !val || !SvOK(val)) return NULL;
    vp = SvPV_const(val, vl);
    if (!vl) return NULL;

    /* a regex we are not going to run is a rule we cannot honour */
    if (oa_get(aTHX_ h, "pattern")) return NULL;

    /* an enum or a const is the document naming the only answers */
    if ((e = oa_get(aTHX_ h, "enum"))) {
        AV *av = oa_av_of(e);
        SSize_t i, n = av ? av_len(av) + 1 : 0;
        int found = 0;
        for (i = 0; i < n && !found; i++) {
            SV **m = av_fetch(av, i, 0);
            STRLEN ml; const char *mp;
            if (!m || !*m || !SvOK(*m) || SvROK(*m)) continue;
            mp = SvPV_const(*m, ml);
            if (ml == vl && memEQ(mp, vp, vl)) found = 1;
        }
        if (!found) return NULL;
    }
    if ((e = oa_get(aTHX_ h, "const"))) {
        STRLEN cl; const char *cp;
        if (SvROK(e) || !SvOK(e)) return NULL;
        cp = SvPV_const(e, cl);
        if (!(cl == vl && memEQ(cp, vp, vl))) return NULL;
    }

    t = oa_gen_type_of(aTHX_ h);
    if (!t) return newSVpvn(vp, vl);        /* untyped: a string will do */
    tp = SvPV_const(t, tl);

    if (tl == 6 && memEQ(tp, "string", 6)) {
        SV *mn = oa_get(aTHX_ h, "minLength");
        SV *mx = oa_get(aTHX_ h, "maxLength");
        if (mn && (IV)vl < SvIV(mn)) return NULL;
        if (mx && (IV)vl > SvIV(mx)) return NULL;
        return newSVpvn(vp, vl);
    }

    if ((tl == 7 && memEQ(tp, "integer", 7))
     || (tl == 6 && memEQ(tp, "number", 6))) {
        int is_int = (tl == 7);
        STRLEN i = 0;
        int dot = 0;
        SV *out;
        if (vp[0] == '-' || vp[0] == '+') i = 1;
        if (i >= vl) return NULL;
        for (; i < vl; i++) {
            if (vp[i] == '.' && !is_int && !dot) { dot = 1; continue; }
            if (vp[i] < '0' || vp[i] > '9') return NULL;
        }
        /* the numeric bounds, which a string that merely looks like a
         * number can still be outside of */
        {
            NV n = SvNV(val);
            SV *b;
            if ((b = oa_get(aTHX_ h, "minimum"))          && n <  SvNV(b)) return NULL;
            if ((b = oa_get(aTHX_ h, "maximum"))          && n >  SvNV(b)) return NULL;
            if ((b = oa_get(aTHX_ h, "exclusiveMinimum")) && n <= SvNV(b)) return NULL;
            if ((b = oa_get(aTHX_ h, "exclusiveMaximum")) && n >= SvNV(b)) return NULL;
            out = is_int ? newSViv((IV)n) : newSVnv(n);
        }
        return out;
    }

    if (tl == 7 && memEQ(tp, "boolean", 7)) {
        if (vl == 4 && memEQ(vp, "true", 4))  return newRV_noinc(newSViv(1));
        if (vl == 5 && memEQ(vp, "false", 5)) return newRV_noinc(newSViv(0));
        return NULL;
    }

    /* an object or an array cannot come from one path segment */
    return NULL;
}

/* Give the nth element of an array a distinct identifier.
 *
 * Five rows that are byte-identical are not a list, they are the same
 * row five times - you cannot tell a rendering bug from a keying bug
 * against them, and nothing that consumes ids (a table, a router, a
 * cache) behaves the way it will in production. So the integer fields
 * that name a thing get the element's index added to whatever the
 * schema generated.
 *
 * Deterministic: the index is the position, not a counter, so the same
 * request still gives byte-identical bodies. Still valid: the base came
 * from the generator inside the schema's own bounds, and anything that
 * would leave `maximum` behind is left alone. */
static void oa_seq_id(pTHX_ HV *doc, SV *items, SV *elem, IV n) {
    HV *eh, *sh, *props;
    SV *deref;
    HE *he;

    if (!n || !elem || !SvROK(elem) || SvTYPE(SvRV(elem)) != SVt_PVHV) return;
    eh = (HV *)SvRV(elem);

    deref = items ? oa_mock_deref(aTHX_ doc, items, 0) : NULL;
    sh    = deref ? oa_hv_of(deref) : NULL;
    props = sh ? oa_hv_of(oa_get(aTHX_ sh, "properties")) : NULL;
    if (!props) return;

    hv_iterinit(eh);
    while ((he = hv_iternext(eh))) {
        I32 kl;
        const char *kp = hv_iterkey(he, &kl);
        SV *val = hv_iterval(eh, he);
        SV **ps;
        HV *ph;
        SV *t, *mx;
        STRLEN tl;
        const char *tp;

        /* the fields that name a thing: `id`, `petId`, `order_id` */
        if (!(kl >= 2 && toLOWER((U8)kp[kl - 2]) == 'i'
                      && toLOWER((U8)kp[kl - 1]) == 'd')) continue;
        if (!val || !SvOK(val) || SvROK(val)) continue;

        ps = hv_fetch(props, kp, kl, 0);
        if (!ps || !*ps) continue;
        ph = oa_hv_of(oa_mock_deref(aTHX_ doc, *ps, 0));
        if (!ph) continue;

        t = oa_gen_type_of(aTHX_ ph);
        if (!t) continue;
        tp = SvPV_const(t, tl);
        if (!(tl == 7 && memEQ(tp, "integer", 7))) continue;

        mx = oa_get(aTHX_ ph, "maximum");
        if (mx && (NV)(SvIV(val) + n) > SvNV(mx)) continue;
        sv_setiv(val, SvIV(val) + n);
    }
}

/* The captured value to answer a property with, or NULL.
 *
 * Matching is by name, in the order people actually write documents:
 * the same name, the same name in any case, and then the convention
 * every REST document uses - a path templated `{petId}` naming the
 * resource whose schema calls the field `id`.
 *
 * That last rule applies only when exactly one capture ends in `id`.
 * `/pets/{petId}/toys/{toyId}` has two, and there is no honest way to
 * say which of them the `id` on a nested object means, so it generates
 * rather than guesses. Guessing here would put a toy's id on a pet. */
static SV *oa_gen_echo(pTHX_ HV *caps, const char *name, STRLEN nl, HV *h) {
    SV **hit;
    HE *he;
    SV *only = NULL;
    int nid = 0;

    if (!caps || !name) return NULL;

    if ((hit = hv_fetch(caps, name, (I32)nl, 0)) && *hit && SvOK(*hit))
        return oa_gen_fits(aTHX_ h, *hit);

    hv_iterinit(caps);
    while ((he = hv_iternext(caps))) {
        I32 kl;
        const char *kp = hv_iterkey(he, &kl);
        SV *v = hv_iterval(caps, he);
        STRLEN i;
        int same = ((STRLEN)kl == nl);
        for (i = 0; same && i < nl; i++)
            if (toLOWER((U8)kp[i]) != toLOWER((U8)name[i])) same = 0;
        if (same) return oa_gen_fits(aTHX_ h, v);

        if (kl >= 2 && toLOWER((U8)kp[kl - 2]) == 'i'
                    && toLOWER((U8)kp[kl - 1]) == 'd') {
            nid++;
            only = v;
        }
    }

    if (nid == 1 && nl == 2 && toLOWER((U8)name[0]) == 'i'
                            && toLOWER((U8)name[1]) == 'd')
        return oa_gen_fits(aTHX_ h, only);

    return NULL;
}

/* the first non-"null" entry of a type union, or NULL for "just null" */
static SV *oa_gen_type_of(pTHX_ HV *h) {
    SV *t = oa_get(aTHX_ h, "type");
    if (!t) return NULL;
    if (!SvROK(t)) return t;
    {
        AV *av = oa_av_of(t);
        SSize_t i, n = av ? av_len(av) + 1 : 0;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(av, i, 0);
            if (e && *e && SvOK(*e)) {
                STRLEN l; const char *p = SvPV_const(*e, l);
                if (!(l == 4 && memEQ(p, "null", 4))) return *e;
            }
        }
    }
    return NULL;
}

/* fixed, valid representative for a `format` (NULL: no special value) */
static const char *oa_gen_format(const char *p, STRLEN l) {
    if (l == 9  && memEQ(p, "date-time", 9)) return "1970-01-01T00:00:00Z";
    if (l == 4  && memEQ(p, "date", 4))      return "1970-01-01";
    if (l == 4  && memEQ(p, "time", 4))      return "00:00:00Z";
    if (l == 8  && memEQ(p, "duration", 8))  return "PT0S";
    if (l == 4  && memEQ(p, "uuid", 4))      return "00000000-0000-0000-0000-000000000000";
    if (l == 5  && memEQ(p, "email", 5))     return "user@example.com";
    if (l == 3  && memEQ(p, "uri", 3))       return "https://example.com/";
    if (l == 13 && memEQ(p, "uri-reference", 13)) return "/";
    if (l == 8  && memEQ(p, "hostname", 8))  return "example.com";
    if (l == 4  && memEQ(p, "ipv4", 4))      return "127.0.0.1";
    if (l == 4  && memEQ(p, "ipv6", 4))      return "::1";
    if (l == 4  && memEQ(p, "byte", 4))      return "AA==";
    return NULL;
}

static SV *oa_gen_string(pTHX_ HV *h) {
    SV *f = oa_get(aTHX_ h, "format");
    SV *minl = oa_get(aTHX_ h, "minLength");
    SV *maxl = oa_get(aTHX_ h, "maxLength");
    SV *out;
    const char *fixed = NULL;
    if (f && !SvROK(f)) {
        STRLEN fl; const char *fp = SvPV_const(f, fl);
        fixed = oa_gen_format(fp, fl);
    }
    out = newSVpv(fixed ? fixed : "string", 0);
    if (minl && SvIV(minl) > 0) {
        IV want = SvIV(minl);
        if (want > OA_MOCK_MAX_PAD) want = OA_MOCK_MAX_PAD;
        while ((IV)SvCUR(out) < want) sv_catpvs(out, "a");
    }
    if (maxl && SvIV(maxl) >= 0 && (IV)SvCUR(out) > SvIV(maxl)) {
        SvCUR_set(out, (STRLEN)SvIV(maxl));
        *SvEND(out) = '\0';
    }
    return out;
}

/* a number sitting on its lower bound (0 without one), nudged onto
 * multipleOf. Integer types return an IV; number types return an IV when
 * the value is integral, so 0 encodes as 0 and not 0.0. */
static SV *oa_gen_number(pTHX_ HV *h, int is_int) {
    NV v = 0.0;
    SV *mi = oa_get(aTHX_ h, "minimum");
    SV *xm = oa_get(aTHX_ h, "exclusiveMinimum");
    SV *ma = oa_get(aTHX_ h, "maximum");
    SV *mo = oa_get(aTHX_ h, "multipleOf");
    if (mi) v = SvNV(mi);
    if (xm && !SvROK(xm) && looks_like_number(xm)) {
        /* draft 2020-12: a number the value must sit strictly above */
        NV x = SvNV(xm);
        if (v <= x) v = is_int ? floor(x) + 1 : x + 1;
    } else if (xm && SvTRUE(xm) && mi) {
        v += 1;                            /* OAS 3.0 boolean form */
    }
    if (mo && SvNV(mo) > 0) {
        NV m = SvNV(mo);
        v = ceil(v / m) * m;
    }
    if (ma && SvNV(ma) < v) v = SvNV(ma);   /* contradictory spec: best effort */
    if (is_int || v == floor(v)) return newSViv((IV)v);
    return newSVnv(v);
}

/* allOf: fold the members into one working schema - properties merged
 * key-wise, required concatenated, scalar keywords last-wins - then
 * generate from the fold. Mortal intermediate, +1 result. */
static SV *oa_gen_allof(pTHX_ HV *doc, AV *all, HV *caps, int depth) {
    HV *m = (HV *)sv_2mortal((SV *)newHV());
    HV *mp = NULL;
    AV *mr = NULL;
    SSize_t i, n = av_len(all) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(all, i, 0);
        SV *sub = e && *e ? oa_mock_deref(aTHX_ doc, *e, depth) : NULL;
        HV *sh = sub ? oa_hv_of(sub) : NULL;
        HE *he;
        if (!sh) continue;
        hv_iterinit(sh);
        while ((he = hv_iternext(sh))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            SV *v = hv_iterval(sh, he);
            if (kl == 10 && memEQ(k, "properties", 10)) {
                HV *ph = oa_hv_of(v);
                HE *pe;
                if (!ph) continue;
                if (!mp) {
                    mp = newHV();
                    (void)hv_stores(m, "properties", newRV_noinc((SV *)mp));
                }
                hv_iterinit(ph);
                while ((pe = hv_iternext(ph))) {
                    I32 pkl; const char *pk = hv_iterkey(pe, &pkl);
                    (void)hv_store(mp, pk, pkl,
                                   SvREFCNT_inc(hv_iterval(ph, pe)), 0);
                }
            } else if (kl == 8 && memEQ(k, "required", 8)) {
                AV *ra = oa_av_of(v);
                SSize_t j, rn = ra ? av_len(ra) + 1 : 0;
                if (!mr) {
                    mr = newAV();
                    (void)hv_stores(m, "required", newRV_noinc((SV *)mr));
                }
                for (j = 0; j < rn; j++) {
                    SV **r = av_fetch(ra, j, 0);
                    if (r && *r) av_push(mr, newSVsv(*r));
                }
            } else {
                (void)hv_store(m, k, kl, SvREFCNT_inc(v), 0);
            }
        }
    }
    return oa_gen(aTHX_ doc, sv_2mortal(newRV_inc((SV *)m)), caps, depth + 1);
}

/* Generate a value that validates against `schema`. Always answers -
 * anything unresolvable becomes JSON null, which is at least honest and
 * still deterministic. (+1) */
static SV *oa_gen(pTHX_ HV *doc, SV *schema, HV *caps, int depth) {
    HV *h;
    SV *v, *t;
    if (depth > OA_MOCK_MAX_DEPTH) return newSV(0);
    schema = oa_mock_deref(aTHX_ doc, schema, depth);
    h = schema ? oa_hv_of(schema) : NULL;
    if (!h) return newSV(0);                 /* true/false schema, or junk */

    if ((v = oa_get(aTHX_ h, "const")))   return newSVsv(v);
    if ((v = oa_get(aTHX_ h, "enum"))) {
        AV *av = oa_av_of(v);
        SV **e = av ? av_fetch(av, 0, 0) : NULL;
        if (e && *e) return newSVsv(*e);
    }
    if ((v = oa_get(aTHX_ h, "default"))) return newSVsv(v);

    if ((v = oa_get(aTHX_ h, "allOf")) && oa_av_of(v))
        return oa_gen_allof(aTHX_ doc, oa_av_of(v), caps, depth);
    if (((v = oa_get(aTHX_ h, "oneOf")) && oa_av_of(v))
     || ((v = oa_get(aTHX_ h, "anyOf")) && oa_av_of(v))) {
        SV **e = av_fetch(oa_av_of(v), 0, 0);
        return (e && *e) ? oa_gen(aTHX_ doc, *e, caps, depth + 1) : newSV(0);
    }

    t = oa_gen_type_of(aTHX_ h);
    if (!t) {
        /* no type declared: shape hints, then null (valid anywhere) */
        if (oa_get(aTHX_ h, "properties") || oa_get(aTHX_ h, "required"))
            t = sv_2mortal(newSVpvs("object"));
        else if (oa_get(aTHX_ h, "items"))
            t = sv_2mortal(newSVpvs("array"));
        else
            return newSV(0);
    }
    {
        STRLEN tl; const char *tp = SvPV_const(t, tl);
        if (tl == 6 && memEQ(tp, "string", 6))
            return oa_gen_string(aTHX_ h);
        if (tl == 7 && memEQ(tp, "integer", 7))
            return oa_gen_number(aTHX_ h, 1);
        if (tl == 6 && memEQ(tp, "number", 6))
            return oa_gen_number(aTHX_ h, 0);
        if (tl == 7 && memEQ(tp, "boolean", 7))
            return newRV_noinc(newSViv(1));       /* \1 encodes as true */
        if (tl == 4 && memEQ(tp, "null", 4))
            return newSV(0);
        if (tl == 5 && memEQ(tp, "array", 5)) {
            AV *out = newAV();
            SV *items = oa_get(aTHX_ h, "items");
            SV *mn = oa_get(aTHX_ h, "minItems");
            SV *mx = oa_get(aTHX_ h, "maxItems");
            /* One element, not none, when the document does not say.
             *
             * An empty array satisfies `type: array` and is therefore a
             * correct answer, which is precisely why this was wrong: a
             * list endpoint that mocks as [] tells the caller nothing
             * about the shape of what they will get, and no client can
             * be developed against it. The useful answer is the
             * smallest one that shows the shape.
             *
             * An explicit minItems still wins, and maxItems still caps -
             * including `maxItems: 0`, where the document has said it
             * means empty and we believe it. */
            IV want = OA_MOCK_ARRAY_ITEMS, i;
            if (mn && SvIV(mn) > want) want = SvIV(mn);
            if (mx && SvIV(mx) < want) want = SvIV(mx);
            if (want > 64) want = 64;             /* bounded, like the pad */
            if (want < 0) want = 0;
            for (i = 0; i < want; i++) {
                SV *el = items ? oa_gen(aTHX_ doc, items, caps, depth + 1)
                               : newSV(0);
                oa_seq_id(aTHX_ doc, items, el, i);
                av_push(out, el);
            }
            return newRV_noinc((SV *)out);
        }
        if (tl == 6 && memEQ(tp, "object", 6)) {
            HV *out = newHV();
            HV *props = oa_hv_of(oa_get(aTHX_ h, "properties"));
            AV *req   = oa_av_of(oa_get(aTHX_ h, "required"));
            SSize_t i, n = req ? av_len(req) + 1 : 0;
            for (i = 0; i < n; i++) {
                SV **e = av_fetch(req, i, 0);
                STRLEN kl; const char *kp;
                SV **ps;
                if (!e || !*e || !SvOK(*e)) continue;
                SV *echo = NULL;
                kp = SvPV_const(*e, kl);
                ps = props ? hv_fetch(props, kp, (I32)kl, 0) : NULL;

                /* The request, where it answers the question better than
                 * the schema does. `GET /pets/42` replying with id 0 is
                 * a mock nobody can develop a client against. */
                if (caps && ps && *ps) {
                    SV *rs = oa_mock_deref(aTHX_ doc, *ps, depth);
                    HV *rh = rs ? oa_hv_of(rs) : NULL;
                    if (rh) echo = oa_gen_echo(aTHX_ caps, kp, (STRLEN)kl, rh);
                }

                (void)hv_store(out, kp, (I32)kl,
                               echo ? echo
                             : (ps && *ps) ? oa_gen(aTHX_ doc, *ps, caps, depth + 1)
                                           : newSV(0), 0);
            }
            return newRV_noinc((SV *)out);
        }
    }
    return newSV(0);
}

/* ---- the declared responses, raw -------------------------------------------- */

/* the raw operation object (paths -> template -> method), or NULL. Borrowed. */
static HV *oa_raw_op(pTHX_ oa_api *a, oa_op *o) {
    HV *doc = (HV *)SvRV(a->spec);
    HV *paths = oa_hv_of(oa_get(aTHX_ doc, "paths"));
    SV *item;
    HV *ih;
    STRLEN pl; const char *pp;
    SV **e;
    if (!paths) return NULL;
    pp = SvPV_const(o->path, pl);
    e = hv_fetch(paths, pp, (I32)pl, 0);
    item = (e && *e) ? *e : NULL;
    ih = item ? oa_hv_of(item) : NULL;
    if (!ih) return NULL;
    return oa_hv_of(oa_get(aTHX_ ih, SvPV_nolen(o->method)));
}

/* Choose the status and its raw response object. `want` is the preferred
 * code (0 = none). Fills *robj (may end NULL: answer with no body) and
 * returns the status. */
static int oa_mock_status(pTHX_ HV *responses, int want, HV **robj) {
    HE *he;
    char kb[8];
    *robj = NULL;
    if (!responses) return want ? want : 200;

    if (want) {
        SV **e;
        STRLEN kl = (STRLEN)my_snprintf(kb, sizeof kb, "%d", want);
        e = hv_fetch(responses, kb, (I32)kl, 0);
        if (e && *e) { *robj = oa_hv_of(*e); return want; }
        e = hv_fetch(responses, "default", 7, 0);
        if (e && *e) { *robj = oa_hv_of(*e); return want; }
        return want;                       /* undeclared: empty body */
    }

    {
        int best2 = 0, bestany = 0;
        SV *best2sv = NULL, *bestanysv = NULL;
        hv_iterinit(responses);
        while ((he = hv_iternext(responses))) {
            I32 kl; const char *k = hv_iterkey(he, &kl);
            char *end = NULL;
            long s = strtol(k, &end, 10);
            if (!end || end != k + kl || s < 100 || s > 599) continue;
            if (s >= 200 && s < 300 && (!best2 || s < best2)) {
                best2 = (int)s; best2sv = hv_iterval(responses, he);
            }
            if (!bestany || s < bestany) {
                bestany = (int)s; bestanysv = hv_iterval(responses, he);
            }
        }
        if (best2) { *robj = oa_hv_of(best2sv); return best2; }
        {
            SV **d = hv_fetch(responses, "default", 7, 0);
            if (d && *d) { *robj = oa_hv_of(*d); return 200; }
        }
        if (bestany) { *robj = oa_hv_of(bestanysv); return bestany; }
    }
    return 200;
}

/* the JSON media entry of a content object: exact application/json first,
 * then the lexicographically first declared JSON type (deterministic where
 * hash order is not). *ctype_out borrowed. NULL when none. */
static HV *oa_mock_media(pTHX_ HV *content, SV **ctype_out) {
    HE *he;
    SV *bestk = NULL, *bestv = NULL;
    SV **exact;
    *ctype_out = NULL;
    if (!content) return NULL;
    exact = hv_fetch(content, "application/json", 16, 0);
    if (exact && *exact && oa_hv_of(*exact)) {
        SV *ct = sv_newmortal();
        sv_setpvn(ct, "application/json", 16);
        *ctype_out = ct;
        return oa_hv_of(*exact);
    }
    hv_iterinit(content);
    while ((he = hv_iternext(content))) {
        I32 kl; const char *k = hv_iterkey(he, &kl);
        if (!oa_ctype_is_json(k, (STRLEN)kl)) continue;
        if (!oa_hv_of(hv_iterval(content, he))) continue;
        if (!bestk || strcmp(k, SvPV_nolen(bestk)) < 0) {
            if (!bestk) bestk = sv_newmortal();
            sv_setpvn(bestk, k, (STRLEN)kl);
            bestv = hv_iterval(content, he);
        }
    }
    if (!bestv) return NULL;
    *ctype_out = bestk;
    return oa_hv_of(bestv);
}

/* "code=404, example=named" - the value of one token of a Prefer header.
 * Mortal SV, or NULL. Values may be double-quoted. */
static SV *oa_prefer_token(pTHX_ SV *prefer, const char *name, STRLEN nl) {
    STRLEN pl; const char *pp;
    STRLEN i = 0;
    if (!prefer || !SvOK(prefer)) return NULL;
    pp = SvPV_const(prefer, pl);
    while (i < pl) {
        STRLEN e = i, eq, vs, ve;
        while (e < pl && pp[e] != ',' && pp[e] != ';') e++;
        while (i < e && isSPACE((U8)pp[i])) i++;
        eq = i;
        while (eq < e && pp[eq] != '=') eq++;
        {
            STRLEN ne = eq;
            while (ne > i && isSPACE((U8)pp[ne-1])) ne--;
            if (ne - i == nl) {
                STRLEN k;
                int same = 1;
                for (k = 0; k < nl; k++)
                    if (toLOWER((U8)pp[i+k]) != (U8)name[k]) { same = 0; break; }
                if (same && eq < e) {
                    vs = eq + 1;
                    ve = e;
                    while (vs < ve && isSPACE((U8)pp[vs])) vs++;
                    while (ve > vs && isSPACE((U8)pp[ve-1])) ve--;
                    if (ve > vs + 1 && pp[vs] == '"' && pp[ve-1] == '"') { vs++; ve--; }
                    return sv_2mortal(newSVpvn(pp + vs, ve - vs));
                }
            }
        }
        i = e + 1;
    }
    return NULL;
}

/* ---- the synthesized response ---------------------------------------------- */

/* Canonical JSON (sorted keys, minimal whitespace) through the frj ABI.
 * Perl randomises hash iteration order per hash, so an ordinary encode of a
 * freshly built object would shuffle its keys on every request - canonical
 * form is what makes "byte-identical bodies" true, and it holds across
 * processes, not merely within one. (+1; croaks on an unencodable shape,
 * which a value built from a decoded document cannot be.) */
static SV *oa_mock_encode(pTHX_ SV *val) {
    const frj_abi *J = oa_frj(aTHX);
    frj_opts o;
    J->opts_init(&o);
    o.canonical = 1;
    return J->encode(aTHX_ val, &o);
}

/* Build the PSGI triplet for op + options (+1).
 *
 *   want_code   0, or the status Prefer asked for
 *   want_name   NULL, or the named example Prefer asked for
 *
 * The body precedence is the header comment's; a response with no JSON
 * content answers with an empty body and no Content-Type, which is what a
 * 204 or a bare "404: no such pet" declares. */
static SV *oa_synthesize(pTHX_ oa_api *a, oa_op *o, int want_code, SV *want_name,
                          HV *caps) {
    HV *doc = (HV *)SvRV(a->spec);
    HV *rawop = oa_raw_op(aTHX_ a, o);
    HV *responses = rawop ? oa_hv_of(oa_get(aTHX_ rawop, "responses")) : NULL;
    HV *robj = NULL;
    int status = oa_mock_status(aTHX_ responses, want_code, &robj);
    HV *content = robj ? oa_hv_of(oa_get(aTHX_ robj, "content")) : NULL;
    SV *ctype = NULL;
    HV *media = oa_mock_media(aTHX_ content, &ctype);
    SV *value = NULL, *json = NULL;
    AV *ha, *ba, *tv;

    if (media) {
        SV *ex;
        /* 1/2. example, or a named / the first examples entry */
        if (want_name && SvOK(want_name)) {
            HV *exs = oa_hv_of(oa_get(aTHX_ media, "examples"));
            STRLEN wl; const char *wp = SvPV_const(want_name, wl);
            SV **e = exs ? hv_fetch(exs, wp, (I32)wl, 0) : NULL;
            HV *eh = (e && *e) ? oa_hv_of(*e) : NULL;
            if (eh) value = oa_get(aTHX_ eh, "value");
        }
        if (!value && (ex = oa_get(aTHX_ media, "example")))
            value = ex;
        if (!value) {
            HV *exs = oa_hv_of(oa_get(aTHX_ media, "examples"));
            if (exs) {
                HE *he;
                SV *bestk = NULL, *bestv = NULL;
                hv_iterinit(exs);
                while ((he = hv_iternext(exs))) {
                    I32 kl; const char *k = hv_iterkey(he, &kl);
                    if (!bestk || strcmp(k, SvPV_nolen(bestk)) < 0) {
                        if (!bestk) bestk = sv_newmortal();
                        sv_setpvn(bestk, k, (STRLEN)kl);
                        bestv = hv_iterval(exs, he);
                    }
                }
                if (bestv && oa_hv_of(bestv))
                    value = oa_get(aTHX_ oa_hv_of(bestv), "value");
            }
        }
        /* 3/4. the schema's default, else generated from the schema */
        if (!value) {
            SV *schema = oa_get(aTHX_ media, "schema");
            SV *res = schema ? oa_mock_deref(aTHX_ doc, schema, 0) : NULL;
            HV *sh = res ? oa_hv_of(res) : NULL;
            SV *def = sh ? oa_get(aTHX_ sh, "default") : NULL;
            if (def) value = def;
            else if (schema) value = sv_2mortal(oa_gen(aTHX_ doc, schema, caps, 0));
        }
        if (value) json = sv_2mortal(oa_mock_encode(aTHX_ value));
    }

    /* nothing owned is allocated before this point, so the encode above may
     * croak without leaking */
    ha = newAV(); ba = newAV(); tv = newAV();
    if (json) {
        av_push(ha, newSVpvs("Content-Type"));
        av_push(ha, newSVsv(ctype));
        av_push(ha, newSVpvs("Content-Length"));
        av_push(ha, newSVuv((UV)SvCUR(json)));
        av_push(ba, newSVsv(json));
    } else {
        av_push(ha, newSVpvs("Content-Length"));
        av_push(ha, newSVpvs("0"));
        av_push(ba, newSVpvs(""));
    }
    av_push(tv, newSViv(status));
    av_push(tv, newRV_noinc((SV *)ha));
    av_push(tv, newRV_noinc((SV *)ba));
    return newRV_noinc((SV *)tv);
}

#endif /* OA_MOCK_H */

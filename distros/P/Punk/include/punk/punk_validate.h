/* punk_validate.h - collecting request validation, in C.
 *
 * The whole tier runs on the JSON::Schema::Fast C ABI (jsf_abi.h): plain
 * hashref schemas compile once through the table (coercion on) and cache by
 * their canonical JSON via the File::Raw::JSON ABI - a hashref literal in a
 * handler is a fresh ref every call, so refaddr keying would recompile
 * forever; a prebuilt JSON::Schema::Fast::Compiled passes straight through.
 * Per request nothing is Perl but the (optional) req->json / params calls
 * that fetch the data.
 *
 * Invalid data never croaks - it collects into a Punk::Validate::Result the
 * handler (or the generated route guard, a punk_closure appended to the
 * record's guards AV at boot) turns into a 400 or a form re-render. Errors
 * carry the Open::API shape: the JSON::Schema::Fast fields plus `name`,
 * with a root-level `required` failure expanded to one error per missing
 * property so a form can put the message beside its field.
 *
 * Needs (include after): punk_context.h (pcx_*), punk_session.h (ps_stash),
 * punk_dispatch.h (pd_call), punk_static.h (punk_closure), punk_names.h,
 * and the root's punk_frj. */

#ifndef PUNK_VALIDATE_H
#define PUNK_VALIDATE_H

#include "jsf_abi.h"

#define PV_RESULT_CLASS "Punk::Validate::Result"

/* ---- the JSON::Schema::Fast ABI, resolved once at runtime ----------------- */

static const jsf_abi *PUNK_JSF_TAB = NULL;
static int PUNK_JSF_TAB_TRIED = 0;

static const jsf_abi *punk_jsf_try(pTHX) {
    if (!PUNK_JSF_TAB_TRIED) {
        dSP; int count, ok; IV p = 0;
        PUNK_JSF_TAB_TRIED = 1;
        ok = pk_require_once(aTHX_ "JSON::Schema::Fast", FALSE);
        SPAGAIN;   /* the require may have reallocated the value stack */
        if (ok) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("JSON::Schema::Fast::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)              (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const jsf_abi *a = INT2PTR(const jsf_abi *, p);
                if (a && a->abi_version >= JSF_ABI_VERSION)
                    PUNK_JSF_TAB = a;
            }
        }
    }
    return PUNK_JSF_TAB;
}

static const jsf_abi *punk_jsf(pTHX) {
    const jsf_abi *a = punk_jsf_try(aTHX);
    if (!a)
        croak("Punk: validation needs JSON::Schema::Fast with a compatible "
              "C ABI (JSF_ABI_VERSION %d)", JSF_ABI_VERSION);
    return a;
}

/* ---- small helpers -------------------------------------------------------- */

/* $obj->$meth(@argv) under G_EVAL: NULL (and a cleared error) on a die -
 * the data-fetching calls mirror the defensive evals the Perl tier had. */
static SV *pv_meth_ev(pTHX_ SV *obj, const char *meth, SV **argv, int nargs) {
    dSP; SV *r = NULL; int count, i;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, nargs + 1);
    PUSHs(obj);
    for (i = 0; i < nargs; i++) PUSHs(argv[i]);
    PUTBACK;
    count = call_method(meth, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (count > 0) { SV *t = POPs; if (!SvTRUE(ERRSV)) r = newSVsv(t); }
    PUTBACK; FREETMPS; LEAVE;
    if (SvTRUE(ERRSV)) sv_setsv(ERRSV, &PL_sv_no);
    return r;
}

/* case-insensitive "does hay contain needle" */
static int pv_ci_has(const char *hay, STRLEN hl, const char *needle) {
    STRLEN nl = strlen(needle), i, j;
    if (nl == 0 || hl < nl) return 0;
    for (i = 0; i + nl <= hl; i++) {
        for (j = 0; j < nl; j++) {
            char a = hay[i + j], b = needle[j];
            if (a >= 'A' && a <= 'Z') a = (char)(a - 'A' + 'a');
            if (b >= 'A' && b <= 'Z') b = (char)(b - 'A' + 'a');
            if (a != b) break;
        }
        if (j == nl) return 1;
    }
    return 0;
}

/* canonical JSON of an SV (+1) - the schema cache key */
static SV *pv_canon(pTHX_ SV *data) {
    frj_opts o;
    Zero(&o, 1, frj_opts);
    o.canonical = 1;
    return punk_frj(aTHX)->encode(aTHX_ data, &o);
}

/* ---- the schema cache ----------------------------------------------------- */

static HV *PV_CACHE = NULL;

/* A compiled validator (+1): a blessed Compiled passes through, a hashref
 * compiles once (coerce on) and caches by canonical JSON. Croaks on
 * anything else, and on a malformed schema (from the ABI). */
static SV *pv_compile(pTHX_ SV *schema) {
    if (SvROK(schema) && SvOBJECT(SvRV(schema)))
        return newSVsv(schema);
    if (!(SvROK(schema) && SvTYPE(SvRV(schema)) == SVt_PVHV))
        croak("Punk: the validate schema must be a hashref or a "
              "JSON::Schema::Fast::Compiled");
    {
        SV *key = sv_2mortal(pv_canon(aTHX_ schema));
        HE *he;
        if (!PV_CACHE) PV_CACHE = newHV();
        he = hv_fetch_ent(PV_CACHE, key, 0, 0);
        if (he) return newSVsv(HeVAL(he));
        {
            SV *compiled = punk_jsf(aTHX)->compile(aTHX_ schema,
                                                   &PL_sv_undef, 1, 0);
            (void)hv_store_ent(PV_CACHE, key, compiled, 0);  /* cache owns */
            return newSVsv(compiled);
        }
    }
}

/* ---- errors: the Open::API shape plus name -------------------------------- */

/* instanceLocation -> the field name a form wants: '/year' -> 'year',
 * '/a/b' -> 'a.b', '~1'/'~0' unescaped, the root -> '' (+1) */
static SV *pv_name_of(pTHX_ const char *s, STRLEN l) {
    SV *out = newSVpvs("");
    STRLEN i = (l && s[0] == '/') ? 1 : 0;
    for (; i < l; i++) {
        if (s[i] == '/') sv_catpvs(out, ".");
        else if (s[i] == '~' && i + 1 < l && s[i + 1] == '1') {
            sv_catpvs(out, "/"); i++;
        }
        else if (s[i] == '~' && i + 1 < l && s[i + 1] == '0') {
            sv_catpvs(out, "~"); i++;
        }
        else sv_catpvn(out, s + i, 1);
    }
    return out;
}

/* Augment raw JSON::Schema::Fast errors (+1 AV): every error gains `name`;
 * a root-level `required` failure is expanded to one error per missing
 * property (when the plain schema and a hash of data are known), so
 * error($name) lands beside the right field. */
static AV *pv_augment(pTHX_ AV *errors, HV *schema, SV *data) {
    AV *out = newAV();
    HV *datah = (data && SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV)
                ? (HV *)SvRV(data) : NULL;
    SSize_t i, n = av_len(errors) + 1;
    for (i = 0; i < n; i++) {
        SV **ep = av_fetch(errors, i, 0);
        HV *e; SV **kw, **loc;
        const char *locs = ""; STRLEN locl = 0;
        if (!(ep && *ep && SvROK(*ep) && SvTYPE(SvRV(*ep)) == SVt_PVHV))
            continue;
        e   = (HV *)SvRV(*ep);
        kw  = hv_fetchs(e, "keyword", 0);
        loc = hv_fetchs(e, "instanceLocation", 0);
        if (loc && *loc && SvOK(*loc)) locs = SvPV_const(*loc, locl);
        if (kw && *kw && SvOK(*kw) && strEQ(SvPV_nolen(*kw), "required")
            && locl == 0 && schema && datah) {
            SV **rq = hv_fetchs(schema, "required", 0);
            if (rq && *rq && SvROK(*rq) && SvTYPE(SvRV(*rq)) == SVt_PVAV) {
                AV *req = (AV *)SvRV(*rq);
                SSize_t j, rn = av_len(req) + 1;
                int missing = 0;
                for (j = 0; j < rn; j++) {
                    SV **pp = av_fetch(req, j, 0);
                    STRLEN pl; const char *p;
                    HV *ne; SV *iloc;
                    if (!(pp && *pp && SvOK(*pp))) continue;
                    p = SvPV_const(*pp, pl);
                    if (hv_exists(datah, p, (I32)pl)) continue;
                    ne = newHVhv(e);
                    iloc = newSVpvs("/");
                    sv_catpvn(iloc, p, pl);
                    (void)hv_stores(ne, "instanceLocation", iloc);
                    (void)hv_stores(ne, "name", newSVpvn(p, pl));
                    (void)hv_stores(ne, "message",
                        newSVpvf("missing required property '%.*s'",
                                 (int)pl, p));
                    av_push(out, newRV_noinc((SV *)ne));
                    missing = 1;
                }
                if (missing) continue;
            }
        }
        {
            HV *ne = newHVhv(e);
            (void)hv_stores(ne, "name", pv_name_of(aTHX_ locs, locl));
            av_push(out, newRV_noinc((SV *)ne));
        }
    }
    return out;
}

/* ---- the data sources ----------------------------------------------------- */

static SV *pv_source_json(pTHX_ SV *c) {
    SV *req = pv_meth_ev(aTHX_ c, "req", NULL, 0);
    SV *body = NULL;
    if (req) {
        body = pv_meth_ev(aTHX_ req, "json", NULL, 0);
        SvREFCNT_dec(req);
    }
    if (body && SvROK(body)) return body;
    if (body) SvREFCNT_dec(body);
    return newRV_noinc((SV *)newHV());
}

static SV *pv_source_params(pTHX_ SV *c) {
    SV *p = pv_meth_ev(aTHX_ c, "params", NULL, 0);
    if (p && SvROK(p) && SvTYPE(SvRV(p)) == SVt_PVHV) return p;
    if (p) SvREFCNT_dec(p);
    return newRV_noinc((SV *)newHV());
}

/* auto: the decoded JSON body for a JSON request, the merged params
 * (captures, query, form) otherwise (+1) */
static SV *pv_source_auto(pTHX_ SV *c) {
    SV *req = pv_meth_ev(aTHX_ c, "req", NULL, 0);
    int is_json = 0;
    if (req) {
        SV *argv[1], *ct;
        argv[0] = sv_2mortal(newSVpvs("content-type"));
        ct = pv_meth_ev(aTHX_ req, "header", argv, 1);
        if (ct && SvOK(ct)) {
            STRLEN l; const char *s = SvPV_const(ct, l);
            is_json = pv_ci_has(s, l, "application/json");
        }
        if (ct) SvREFCNT_dec(ct);
        SvREFCNT_dec(req);
    }
    return is_json ? pv_source_json(aTHX_ c) : pv_source_params(aTHX_ c);
}

/* ---- the Result ----------------------------------------------------------- */

/* bless { errors, data, schema? } (+1); owns errs */
static SV *pv_result_new(pTHX_ AV *errs, SV *data, SV *plain_schema) {
    HV *h = newHV();
    (void)hv_stores(h, "errors", newRV_noinc((SV *)errs));
    (void)hv_stores(h, "data",   newSVsv(data));
    if (plain_schema)
        (void)hv_stores(h, "schema", newSVsv(plain_schema));
    return sv_bless(newRV_noinc((SV *)h),
                    gv_stashpvs(PV_RESULT_CLASS, GV_ADD));
}

static HV *pv_result_hv(pTHX_ SV *self) {
    if (!(self && SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV))
        croak("Punk: not a " PV_RESULT_CLASS);
    return (HV *)SvRV(self);
}

static AV *pv_result_errors(pTHX_ HV *h) {
    SV **e = hv_fetchs(h, "errors", 0);
    return (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV)
        ? (AV *)SvRV(*e) : NULL;
}

/* valid / valid($name): only declared properties, numeric strings numified
 * for integer/number, booleans canonical 1/0 - the shapes $c->openapi
 * delivers. Without a plain schema (a precompiled validator) the data
 * comes back as-is (+1). */
static SV *pv_result_valid(pTHX_ HV *h, SV *name) {
    SV **d = hv_fetchs(h, "data", 0);
    SV **s = hv_fetchs(h, "schema", 0);
    SV *data = (d && *d) ? *d : &PL_sv_undef;
    HV *datah = (SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV)
                ? (HV *)SvRV(data) : NULL;
    HV *props = NULL;
    if (s && *s && SvROK(*s) && SvTYPE(SvRV(*s)) == SVt_PVHV) {
        SV **pp = hv_fetchs((HV *)SvRV(*s), "properties", 0);
        if (pp && *pp && SvROK(*pp) && SvTYPE(SvRV(*pp)) == SVt_PVHV)
            props = (HV *)SvRV(*pp);
    }
    if (!props || !datah) {
        if (name && SvOK(name)) {
            HE *he = datah ? hv_fetch_ent(datah, name, 0, 0) : NULL;
            return he ? newSVsv(HeVAL(he)) : newSV(0);
        }
        return datah ? newRV_noinc((SV *)newHVhv(datah)) : newSVsv(data);
    }
    {
        HV *out = newHV();
        HE *he;
        hv_iterinit(props);
        while ((he = hv_iternext(props))) {
            SV *k = hv_iterkeysv(he);
            HE *dhe = hv_fetch_ent(datah, k, 0, 0);
            SV *v, *prop, *nv = NULL;
            const char *type = NULL;
            if (!dhe) continue;
            v = HeVAL(dhe);
            prop = HeVAL(he);
            if (prop && SvROK(prop) && SvTYPE(SvRV(prop)) == SVt_PVHV) {
                SV **tp = hv_fetchs((HV *)SvRV(prop), "type", 0);
                if (tp && *tp && SvOK(*tp)) type = SvPV_nolen(*tp);
            }
            if (type && v && SvOK(v) && !SvROK(v)) {
                if ((strEQ(type, "integer") || strEQ(type, "number"))
                    && looks_like_number(v)) {
                    nv = strEQ(type, "integer") ? newSViv((IV)SvNV(v))
                                                : newSVnv(SvNV(v));
                }
                else if (strEQ(type, "boolean")) {
                    STRLEN vl; const char *vs = SvPV_const(v, vl);
                    int truthy = SvTRUE(v)
                        && !(vl == 5 && memEQ(vs, "false", 5))
                        && !(vl == 1 && vs[0] == '0');
                    nv = newSViv(truthy ? 1 : 0);
                }
            }
            (void)hv_store_ent(out, k, nv ? nv : newSVsv(v), 0);
        }
        if (name && SvOK(name)) {
            HE *ohe = hv_fetch_ent(out, name, 0, 0);
            SV *r = ohe ? newSVsv(HeVAL(ohe)) : newSV(0);
            SvREFCNT_dec((SV *)out);
            return r;
        }
        return newRV_noinc((SV *)out);
    }
}

/* ---- run one validation --------------------------------------------------- */

/* validate `data` against a compiled schema, stash and return the Result
 * (+1). plain_schema is the hashref form when known (drives `required`
 * expansion and valid()'s property filter), else NULL. */
static SV *pv_run(pTHX_ SV *c, SV *compiled, SV *plain_schema, SV *data) {
    AV *raw = (AV *)sv_2mortal((SV *)newAV());
    int ok = punk_jsf(aTHX)->validate(aTHX_ compiled, data, raw);
    HV *sh = (plain_schema && SvROK(plain_schema)
              && SvTYPE(SvRV(plain_schema)) == SVt_PVHV)
             ? (HV *)SvRV(plain_schema) : NULL;
    AV *errs = ok ? newAV() : pv_augment(aTHX_ raw, sh, data);
    SV *r = pv_result_new(aTHX_ errs, data, sh ? plain_schema : NULL);
    HV *stash = ps_stash(aTHX_ pcx_av(aTHX_ c));
    (void)hv_stores(stash, "punk.validation", newSVsv(r));
    return r;
}

/* $c->validate($schema, $data?) (+1 Result) */
static SV *pv_validate(pTHX_ SV *c, SV *schema, SV *source) {
    SV *compiled = sv_2mortal(pv_compile(aTHX_ schema));
    SV *plain = (SvROK(schema) && SvTYPE(SvRV(schema)) == SVt_PVHV)
                ? schema : NULL;
    SV *data = (source && SvROK(source)) ? newSVsv(source)
                                         : pv_source_auto(aTHX_ c);
    SV *r;
    sv_2mortal(data);
    r = pv_run(aTHX_ c, compiled, plain, data);
    return r;
}

/* ---- the route guard ------------------------------------------------------ */

/* capture: [ compiled, plain-schema-or-undef, source-or-undef,
 *            on_invalid-or-undef ] */
XS_INTERNAL(pv_guard_cb);
XS_INTERNAL(pv_guard_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *c, *compiled, *plain, *srcv, *oi, *data, *r;
    AV *errs;
    if (items < 1 || !cap) XSRETURN_EMPTY;
    c        = ST(0);
    compiled = *av_fetch(cap, 0, 0);
    plain    = *av_fetch(cap, 1, 0);
    srcv     = *av_fetch(cap, 2, 0);
    oi       = *av_fetch(cap, 3, 0);

    if (SvOK(srcv)) {
        data = strEQ(SvPV_nolen(srcv), "json") ? pv_source_json(aTHX_ c)
                                               : pv_source_params(aTHX_ c);
    }
    else data = pv_source_auto(aTHX_ c);
    sv_2mortal(data);

    r = sv_2mortal(pv_run(aTHX_ c, compiled,
                          SvOK(plain) ? plain : NULL, data));
    errs = pv_result_errors(aTHX_ pv_result_hv(aTHX_ r));
    if (!errs || av_len(errs) < 0) XSRETURN_EMPTY;   /* valid: continue */

    if (SvOK(oi)) {                     /* the app's own failure response */
        int died = 0;
        SV *out = pd_call(aTHX_ oi, c, &died);
        if (died) { if (out) SvREFCNT_dec(out); croak_sv(ERRSV); }
        ST(0) = out ? sv_2mortal(out) : &PL_sv_undef;
        XSRETURN(1);
    }
    {                                   /* the OpenAPI-mount-shaped 400 */
        HV *body = newHV();
        SV *argv[2], *resp;
        (void)hv_stores(body, "errors", newRV_inc((SV *)errs));
        argv[0] = sv_2mortal(newRV_noinc((SV *)body));
        argv[1] = sv_2mortal(newSViv(400));
        resp = pcx_call_meth(aTHX_ c, "json", argv, 2, 1);
        ST(0) = resp ? sv_2mortal(resp) : &PL_sv_undef;
        XSRETURN(1);
    }
}

/* ---- boot: compile the route-level validate options ----------------------- */

/* Called from Punk::App::compile_extras (after the router compiled): parse
 * each validate spec, compile its schema once, resolve on_invalid, and
 * APPEND a guard closure to the record - after any auth guards, so a 401
 * still costs no body parse. punk_serve walks the same guards AV with no
 * idea anything changed. */
static void pv_compile_routes(pTHX_ SV *self) {
    HV *h = (HV *)SvRV(self);
    SV **vrp = hv_fetchs(h, K_VALIDATE_ROUTES, 0);
    SV **rop = hv_fetchs(h, K_ROUTER, 0);
    AV *vrs, *recs;
    HV *by;
    SV *recs_rv;
    SSize_t i, n;
    if (!(vrp && *vrp && SvROK(*vrp) && SvTYPE(SvRV(*vrp)) == SVt_PVAV))
        return;
    vrs = (AV *)SvRV(*vrp);
    n = av_len(vrs) + 1;
    if (!n) return;
    if (!(rop && *rop && SvOK(*rop)))
        croak("Punk: validate routes with no router");
    recs_rv = pcx_call_meth(aTHX_ *rop, "records", NULL, 0, 1);
    if (!(recs_rv && SvROK(recs_rv) && SvTYPE(SvRV(recs_rv)) == SVt_PVAV)) {
        if (recs_rv) SvREFCNT_dec(recs_rv);
        croak("Punk: validate routes but no compiled records");
    }
    sv_2mortal(recs_rv);
    recs = (AV *)SvRV(recs_rv);

    by = (HV *)sv_2mortal((SV *)newHV());
    {
        SSize_t ri, rn = av_len(recs) + 1;
        for (ri = 0; ri < rn; ri++) {
            SV **rp = av_fetch(recs, ri, 0);
            HV *rec; SV **m, **p; SV *key;
            if (!(rp && *rp && SvROK(*rp) && SvTYPE(SvRV(*rp)) == SVt_PVHV))
                continue;
            rec = (HV *)SvRV(*rp);
            m = hv_fetchs(rec, K_METHOD, 0);
            p = hv_fetchs(rec, K_PATH, 0);
            if (!(m && *m && p && *p)) continue;
            key = sv_2mortal(newSVsv(*m));
            sv_catpvs(key, " ");
            sv_catsv(key, *p);
            (void)hv_store_ent(by, key, newSVsv(*rp), 0);
        }
    }

    for (i = 0; i < n; i++) {
        SV **vp = av_fetch(vrs, i, 0);
        HV *vr, *rec;
        SV **m, **p, **sp;
        SV *where, *spec, *schema, *src = NULL, *oi = NULL;
        SV *compiled, *resolved = NULL;
        HE *he;
        if (!(vp && *vp && SvROK(*vp) && SvTYPE(SvRV(*vp)) == SVt_PVHV))
            continue;
        vr = (HV *)SvRV(*vp);
        m  = hv_fetchs(vr, K_METHOD, 0);
        p  = hv_fetchs(vr, K_PATH, 0);
        sp = hv_fetchs(vr, K_VALIDATE, 0);
        if (!(m && *m && p && *p && sp && *sp)) continue;
        where = sv_2mortal(newSVsv(*m));
        sv_catpvs(where, " ");
        sv_catsv(where, *p);

        he = hv_fetch_ent(by, where, 0, 0);
        if (!he)
            croak("Punk: validate on unknown route %s", SvPV_nolen(where));
        rec = (HV *)SvRV(HeVAL(he));

        spec = *sp;
        schema = spec;
        if (SvROK(spec) && SvTYPE(SvRV(spec)) == SVt_PVHV
            && hv_exists((HV *)SvRV(spec), "schema", 6)) {
            HV *sh = (HV *)SvRV(spec);
            HE *ke;
            SV **x;
            hv_iterinit(sh);
            while ((ke = hv_iternext(sh))) {
                STRLEN kl; const char *k = HePV(ke, kl);
                if (!(strEQ(k, "schema") || strEQ(k, "source")
                      || strEQ(k, "on_invalid")))
                    croak("Punk: unknown validate option '%s' on %s",
                          k, SvPV_nolen(where));
            }
            x = hv_fetchs(sh, "schema", 0);
            schema = (x && *x) ? *x : &PL_sv_undef;
            x = hv_fetchs(sh, "source", 0);
            if (x && *x && SvOK(*x)) src = *x;
            x = hv_fetchs(sh, "on_invalid", 0);
            if (x && *x && SvOK(*x)) oi = *x;
        }

        if (!(SvROK(schema)
              && (SvOBJECT(SvRV(schema))
                  || SvTYPE(SvRV(schema)) == SVt_PVHV)))
            croak("Punk: invalid validate schema on %s: the schema must be "
                  "a hashref or a JSON::Schema::Fast::Compiled",
                  SvPV_nolen(where));
        compiled = pv_compile(aTHX_ schema);   /* croaks on a bad schema */

        if (src && !(strEQ(SvPV_nolen(src), "params")
                     || strEQ(SvPV_nolen(src), "json"))) {
            SvREFCNT_dec(compiled);
            croak("Punk: validate source on %s must be 'params' or 'json'",
                  SvPV_nolen(where));
        }
        if (oi) {
            SV *argv[2];
            argv[0] = oi;
            argv[1] = sv_2mortal(newSVpvs("on_invalid"));
            resolved = pcx_call_meth(aTHX_ self, "_resolve_target",
                                     argv, 2, 1);   /* croaks on a typo */
        }

        {
            AV *cap = newAV();
            SV *guard;
            SV **gp;
            av_push(cap, compiled);                       /* owns the +1 */
            av_push(cap, (SvROK(schema)
                          && SvTYPE(SvRV(schema)) == SVt_PVHV)
                         ? newSVsv(schema) : newSV(0));
            av_push(cap, src ? newSVsv(src) : newSV(0));
            av_push(cap, resolved ? resolved : newSV(0)); /* owns the +1 */
            guard = punk_closure(aTHX_ pv_guard_cb, cap);
            gp = hv_fetchs(rec, K_GUARDS, 0);
            if (!(gp && *gp && SvROK(*gp)
                  && SvTYPE(SvRV(*gp)) == SVt_PVAV)) {
                (void)hv_stores(rec, K_GUARDS,
                                newRV_noinc((SV *)newAV()));
                gp = hv_fetchs(rec, K_GUARDS, 0);
            }
            av_push((AV *)SvRV(*gp), guard);              /* owns the +1 */
        }
    }
}

#endif /* PUNK_VALIDATE_H */

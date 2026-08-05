#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "oa.h"

/* ---- the JSON::Schema::Fast C ABI (required) ----------------------------- *
 * Resolved once at boot from JSON::Schema::Fast::_abi_ptr and version-checked.
 * NULL means the installed JSON::Schema::Fast is absent or too old; Open/API.pm
 * treats that as a hard load-time error. */
static const jsf_abi *JSF = NULL;

/* ---- the Fetch C ABI (client only; resolved lazily in phase 4) ----------- */
static const fetch_abi *OA_FETCH = NULL;
static int OA_FETCH_TRIED = 0;

/* ---- the File::Raw::JSON C ABI (spec + body JSON decode; required) -------- *
 * Resolved lazily on first decode from File::Raw::JSON::_abi_ptr. */
static const frj_abi *OA_FRJ = NULL;
static int OA_FRJ_TRIED = 0;
static const frj_abi *oa_frj(pTHX);   /* defined below; used by the headers */

#include "oa_compile.h"   /* needs the JSF table above */
#include "oa_route.h"
#include "oa_validate.h"
#include "oa_plack.h"
#include "oa_client.h"

/* the PSGI app coderef body: captures
 * ($api, \%handlers, $vresp, $before, $after, \%security, \%csrf, \%opts) */
XS_INTERNAL(oa_app_cb);
XS_INTERNAL(oa_app_cb) {
    dXSARGS;
    AV *cap = oa_clos_cap(aTHX_ cv);
    SV *self_sv, *hs, *flags, *before, *after, *sec, *csrf, *opts, *env, *resp;
    if (!cap || items < 1) XSRETURN_EMPTY;
    self_sv = *av_fetch(cap, 0, 0);
    hs      = *av_fetch(cap, 1, 0);
    flags   = *av_fetch(cap, 2, 0);
    before  = *av_fetch(cap, 3, 0);
    after   = *av_fetch(cap, 4, 0);
    sec     = *av_fetch(cap, 5, 0);
    csrf    = *av_fetch(cap, 6, 0);
    opts    = *av_fetch(cap, 7, 0);
    env     = ST(0);
    if (!SvROK(env) || SvTYPE(SvRV(env)) != SVt_PVHV)
        croak("Open::API app: env must be a hashref");
    resp = oa_serve_psgi(aTHX_ self_sv, (HV *)SvRV(hs), env, (int)SvIV(flags),
                         before, after,
                         (sec  && SvROK(sec))  ? (HV *)SvRV(sec)  : NULL,
                         (csrf && SvROK(csrf)) ? (HV *)SvRV(csrf) : NULL,
                         (opts && SvROK(opts)) ? (HV *)SvRV(opts) : NULL);
    ST(0) = sv_2mortal(resp);
    XSRETURN(1);
}

/* The coderef can() hands back for an operationId: sub { $s->call($op, @_) },
 * with $op captured. Dispatches straight to oa_cli_call (the ->call C path). */
XS_INTERNAL(oa_op_call_cb);
XS_INTERNAL(oa_op_call_cb) {
    dXSARGS;
    AV *cap = oa_clos_cap(aTHX_ cv);
    SV *self, *op, *ret;
    HV *params;
    int i;
    if (!cap || items < 1) XSRETURN_EMPTY;
    op   = *av_fetch(cap, 0, 0);          /* captured operationId */
    self = ST(0);
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
        croak("Open::API::Client: not a client");
    params = (HV *)sv_2mortal((SV *)newHV());
    for (i = 1; i + 1 < items; i += 2) {
        STRLEN kl; const char *k = SvPV_const(ST(i), kl);
        (void)hv_store(params, k, (I32)kl, newSVsv(ST(i + 1)), 0);
    }
    ret = oa_cli_call(aTHX_ (HV *)SvRV(self), op, params);
    ST(0) = sv_2mortal(ret);
    XSRETURN(1);
}

/* ---- object plumbing ------------------------------------------------------ */

static oa_api *oa_api_of(pTHX_ SV *self) {
    if (!SvROK(self)) croak("Open::API: not an Open::API object");
    return (oa_api *)INT2PTR(void *, SvIV(SvRV(self)));
}

/* ---- spec decoding -------------------------------------------------------- */

/* Resolve File::Raw::JSON's ABI table once (a PREREQ). Croak if unavailable. */
static const frj_abi *oa_frj(pTHX) {
    if (!OA_FRJ && !OA_FRJ_TRIED) {
        dSP; int count; IV p = 0;
        OA_FRJ_TRIED = 1;
        eval_pv("require File::Raw::JSON;", FALSE);
        if (!SvTRUE(ERRSV)) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("File::Raw::JSON::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const frj_abi *a = INT2PTR(const frj_abi *, p);
                if (a && a->abi_version == FRJ_ABI_VERSION) OA_FRJ = a;
            }
        }
    }
    if (!OA_FRJ)
        croak("Open::API: JSON decode needs File::Raw::JSON with a compatible "
              "C ABI (FRJ_ABI_VERSION %d)", FRJ_ABI_VERSION);
    return OA_FRJ;
}

/* Decode JSON text via File::Raw::JSON's C ABI. Mortal ref (SV +1 -> mortal),
 * or croak (byte-offset message) on malformed JSON. */
static SV *oa_json_decode(pTHX_ SV *text) {
    const frj_abi *J = oa_frj(aTHX);
    STRLEN len;
    const char *pv = SvPV(text, len);
    return sv_2mortal(J->decode(aTHX_ pv, len, NULL));
}

/* Decode YAML text via YAML::XS, loaded lazily - only a YAML spec needs it,
 * so it is not a PREREQ. A small Perl shim is installed once: it localises
 * $YAML::XS::Boolean to 'JSON::PP' (when JSON::PP is available) so YAML
 * true/false decode to boolean objects like JSON booleans do, without
 * changing YAML::XS behaviour for the rest of the process. Mortal ref, or
 * croak. */
static SV *oa_yaml_decode(pTHX_ SV *text) {
    dSP; int count; SV *ret;
    static int shim = 0;
    eval_pv("require YAML::XS;", FALSE);
    if (SvTRUE(ERRSV))
        croak("Open::API: a YAML spec requires YAML::XS (not installed)");
    if (!shim) {
        eval_pv(
            "sub Open::API::_yaml_load {"
            "  local $YAML::XS::Boolean ="
            "    eval { require JSON::PP; 1 } ? 'JSON::PP' : $YAML::XS::Boolean;"
            "  YAML::XS::Load($_[0]);"
            "}", TRUE);
        shim = 1;
    }
    ENTER; SAVETMPS; PUSHMARK(SP);
    XPUSHs(text); PUTBACK;
    count = call_pv("Open::API::_yaml_load", G_SCALAR | G_EVAL);
    SPAGAIN;
    if (SvTRUE(ERRSV)) {
        SV *e = newSVsv(ERRSV);
        PUTBACK; FREETMPS; LEAVE;
        croak("Open::API: spec YAML parse failed: %s", SvPV_nolen(e));
    }
    ret = count > 0 ? newSVsv(POPs) : &PL_sv_undef;
    PUTBACK; FREETMPS; LEAVE;
    return sv_2mortal(ret);
}

/* True when a client's spec declares the operationId `name`. Shared by the
 * _has_op and AUTOLOAD XSUBs. `self` must be an Open::API::Client hashref. */
static int oa_op_exists(pTHX_ HV *self, SV *name) {
    SV **e = hv_fetchs(self, "api", 0);
    SV  *api = (e && *e) ? *e : NULL;
    if (api && SvROK(api)) {
        oa_api *a = (oa_api *)INT2PTR(void *, SvIV(SvRV(api)));
        return oa_op_by_id(aTHX_ a, name) ? 1 : 0;
    }
    return 0;
}

/* Slurp a file into a mortal SV, or NULL if it cannot be opened. */
static SV *oa_slurp(pTHX_ const char *path) {
    PerlIO *fh = PerlIO_open(path, "rb");
    SV *sv;
    char buf[8192];
    SSize_t n;
    if (!fh) return NULL;
    sv = sv_2mortal(newSVpvs(""));
    while ((n = PerlIO_read(fh, buf, sizeof buf)) > 0)
        sv_catpvn(sv, buf, (STRLEN)n);
    PerlIO_close(fh);
    return sv;
}

/* True when the text's first non-whitespace byte is `c`. */
static int oa_first_nonws_is(const char *p, STRLEN l, char c) {
    STRLEN i = 0;
    while (i < l && isSPACE((U8)p[i])) i++;
    return i < l && p[i] == c;
}

/* Resolve the spec argument - a hashref, JSON text, YAML text, or a filename -
 * into a decoded document hashref (mortal or borrowed). Croaks on failure. */
static SV *oa_load_spec(pTHX_ SV *spec) {
    STRLEN l;
    const char *p;
    SV *doc = NULL;

    if (SvROK(spec)) {
        if (SvTYPE(SvRV(spec)) != SVt_PVHV)
            croak("Open::API: spec reference must be a hashref");
        return spec;
    }
    if (!SvOK(spec) || !SvPOK(spec))
        croak("Open::API: spec must be a hashref, JSON/YAML text, or a filename");

    p = SvPV_const(spec, l);

    /* a filename: no newline, and the file opens */
    if (!memchr(p, '\n', l)) {
        SV *body = oa_slurp(aTHX_ p);
        if (body) {
            STRLEN bl; const char *bp = SvPV_const(body, bl);
            int is_json;
            if      (l >= 5 && memEQ(p + l - 5, ".json", 5)) is_json = 1;
            else if (l >= 5 && memEQ(p + l - 5, ".yaml", 5)) is_json = 0;
            else if (l >= 4 && memEQ(p + l - 4, ".yml", 4))  is_json = 0;
            else is_json = oa_first_nonws_is(bp, bl, '{');
            return is_json ? oa_json_decode(aTHX_ body)
                           : oa_yaml_decode(aTHX_ body);
        }
        /* fall through: not an openable file, treat as inline text */
    }

    doc = oa_first_nonws_is(p, l, '{') ? oa_json_decode(aTHX_ spec)
                                       : oa_yaml_decode(aTHX_ spec);
    return doc;
}

/* Enforce OpenAPI 3.1: doc must be a hashref whose `openapi` is 3.1[.x]. */
static void oa_check_version(pTHX_ SV *doc) {
    HV *h; SV **v;
    STRLEN l; const char *p;
    if (!doc || !SvROK(doc) || SvTYPE(SvRV(doc)) != SVt_PVHV)
        croak("Open::API: spec did not decode to an object/hashref");
    h = (HV *)SvRV(doc);
    v = hv_fetchs(h, "openapi", 0);
    if (!v || !*v || !SvOK(*v))
        croak("Open::API: spec has no 'openapi' version field");
    p = SvPV_const(*v, l);
    if (!(l >= 3 && memEQ(p, "3.1", 3) && (l == 3 || p[3] == '.')))
        croak("Open::API supports OpenAPI 3.1 only (got %.*s)", (int)l, p);
}

/* Construct a compiled Open::API from a spec argument (shared by
 * Open::API->new and Open::API::Client->new(spec => ...)). */
static SV *oa_new_from_spec(pTHX_ const char *cls, SV *spec) {
    SV *doc = oa_load_spec(aTHX_ spec);
    oa_api *a;
    oa_check_version(aTHX_ doc);
    a = oa_api_new(aTHX);
    if (!a) croak("Open::API: out of memory");
    a->spec = newSVsv(doc);
    oa_compile(aTHX_ a);
    return sv_bless(newRV_noinc(newSViv(PTR2IV(a))), gv_stashpv(cls, GV_ADD));
}

MODULE = Open::API        PACKAGE = Open::API

PROTOTYPES: DISABLE

BOOT:
{
    IV p = 0;
    dSP;
    eval_pv("require JSON::Schema::Fast;", FALSE);
    if (!SvTRUE(ERRSV)) {
        PUSHMARK(SP);
        PUTBACK;
        if (call_pv("JSON::Schema::Fast::_abi_ptr", G_SCALAR | G_EVAL) > 0) {
            SPAGAIN;
            if (!SvTRUE(ERRSV)) p = POPi; else (void)POPs;
            PUTBACK;
        }
    }
    if (p) {
        const jsf_abi *a = INT2PTR(const jsf_abi *, p);
        if (a && a->abi_version == JSF_ABI_VERSION) JSF = a;
    }
    /* cache the frj trampoline CVs: the request path invokes them via
     * call_sv + G_EVAL (no name lookup, croaks contained) */
    OA_DEC_CV = SvREFCNT_inc((SV *)get_cv("Open::API::_frj_decode", GV_ADD));
    OA_ENC_CV = SvREFCNT_inc((SV *)get_cv("Open::API::_frj_encode", GV_ADD));
}

# True when JSON::Schema::Fast's C ABI resolved and matched our vendored
# version. Open/API.pm croaks at load when it did not.
int
_abi_ok()
    CODE:
        RETVAL = JSF ? 1 : 0;
    OUTPUT:
        RETVAL

# Direct frj-ABI trampolines. They croak on bad input (the ABI's semantics);
# the request path calls them on cached CVs with G_EVAL so a malformed body
# is a 400 and an unencodable handler return degrades cleanly. Private.
SV *
_frj_decode(text)
        SV *text
    CODE:
    {
        const frj_abi *J = oa_frj(aTHX);
        STRLEN len;
        const char *pv = SvPV_const(text, len);
        RETVAL = J->decode(aTHX_ pv, len, NULL);
    }
    OUTPUT:
        RETVAL

SV *
_frj_encode(val)
        SV *val
    CODE:
        RETVAL = oa_frj(aTHX)->encode(aTHX_ val, NULL);
    OUTPUT:
        RETVAL

# Open::API->new(spec => ...): load and gate the document. The operation
# table is compiled here too (phase 1).
SV *
new(class, ...)
        SV *class
    CODE:
    {
        const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                        ? HvNAME(SvSTASH(SvRV(class))) : SvPV_nolen(class);
        SV *spec = NULL;
        int i;
        if (!JSF) croak("Open::API: JSON::Schema::Fast C ABI unavailable");
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            if (kl == 4 && memEQ(k, "spec", 4)) spec = ST(i + 1);
        }
        if (!spec) croak("Open::API->new: a 'spec' is required");
        RETVAL = oa_new_from_spec(aTHX_ cls, spec);
    }
    OUTPUT:
        RETVAL

# The decoded spec document (a hashref copy reference).
SV *
spec(self)
        SV *self
    CODE:
    {
        oa_api *a = oa_api_of(aTHX_ self);
        RETVAL = a->spec ? newSVsv(a->spec) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

# All operations: [ { operationId, method, path }, ... ] in spec order.
SV *
operations(self)
        SV *self
    CODE:
    {
        oa_api *a = oa_api_of(aTHX_ self);
        oa_ops *t = (oa_ops *)a->ops;
        AV *out = newAV();
        int i;
        for (i = 0; t && i < t->n; i++) {
            HV *h = newHV();
            (void)hv_stores(h, "operationId", newSVsv(t->ops[i].op_id));
            (void)hv_stores(h, "method",      newSVsv(t->ops[i].method));
            (void)hv_stores(h, "path",        newSVsv(t->ops[i].path));
            av_push(out, newRV_noinc((SV *)h));
        }
        RETVAL = newRV_noinc((SV *)out);
    }
    OUTPUT:
        RETVAL

# One operation described: params by location, body content types, response
# statuses. Returns undef for an unknown operationId.
SV *
operation(self, id)
        SV *self
        SV *id
    CODE:
    {
        oa_api *a = oa_api_of(aTHX_ self);
        oa_op *o = oa_op_by_id(aTHX_ a, id);
        if (!o) { RETVAL = &PL_sv_undef; }
        else {
            static const char *locs[OA_IN_N] =
                { "path", "query", "header", "cookie" };
            HV *h = newHV(), *ph = newHV(), *bh = newHV();
            AV *ra = newAV(), *ca = newAV();
            int loc, i;
            (void)hv_stores(h, "operationId", newSVsv(o->op_id));
            (void)hv_stores(h, "method",      newSVsv(o->method));
            (void)hv_stores(h, "path",        newSVsv(o->path));
            for (loc = 0; loc < OA_IN_N; loc++) {
                AV *pa = newAV();
                for (i = 0; i < o->nparams[loc]; i++) {
                    HV *pe = newHV();
                    (void)hv_stores(pe, "name", newSVsv(o->params[loc][i].name));
                    (void)hv_stores(pe, "required",
                                    newSViv(o->params[loc][i].required));
                    av_push(pa, newRV_noinc((SV *)pe));
                }
                (void)hv_store(ph, locs[loc], (I32)strlen(locs[loc]),
                               newRV_noinc((SV *)pa), 0);
            }
            (void)hv_stores(h, "params", newRV_noinc((SV *)ph));
            for (i = 0; i < o->nbodies; i++)
                av_push(ca, newSVsv(o->bodies[i].ctype));
            (void)hv_stores(bh, "required", newSViv(o->body_required));
            (void)hv_stores(bh, "content",  newRV_noinc((SV *)ca));
            (void)hv_stores(h, "body", newRV_noinc((SV *)bh));
            for (i = 0; i < o->nresps; i++)
                av_push(ra, newSVsv(o->resps[i].status));
            (void)hv_stores(h, "responses", newRV_noinc((SV *)ra));
            RETVAL = newRV_noinc((SV *)h);
        }
    }
    OUTPUT:
        RETVAL

# Route a (method, path) pair. List returns:
#   matched:              ($operationId, \%raw_path_captures)
#   path, wrong method:   (undef, \@allow)     - a 405 with its Allow list
#   no such path:         ()                   - a 404
void
match(self, method, path)
        SV *self
        SV *method
        SV *path
    PPCODE:
    {
        oa_api *a = oa_api_of(aTHX_ self);
        STRLEN ml, pl;
        const char *mp = SvPV_const(method, ml);
        const char *pp = SvPV_const(path, pl);
        HV *caps  = (HV *)sv_2mortal((SV *)newHV());
        AV *allow = (AV *)sv_2mortal((SV *)newAV());
        oa_op *o  = oa_route(aTHX_ a, mp, ml, pp, pl, caps, allow);
        if (o) {
            mXPUSHs(newSVsv(o->op_id));
            mXPUSHs(newRV_inc((SV *)caps));
        } else if (av_len(allow) >= 0) {
            XPUSHs(&PL_sv_undef);
            mXPUSHs(newRV_inc((SV *)allow));
        }
        /* else: empty list = 404 */
    }

# Validate raw inputs for an operation. $raw is
#   { path => \%captures, query => $string_or_hashref,
#     header => \%lowercased, body => $raw_text_or_decoded_ref }
# List returns (1, \%params) or (0, \@errors).
void
validate_request(self, op_id, raw)
        SV *self
        SV *op_id
        SV *raw
    PPCODE:
    {
        oa_api *a = oa_api_of(aTHX_ self);
        oa_op *o = oa_op_by_id(aTHX_ a, op_id);
        HV *rh, *rawpath = NULL, *headers = NULL;
        SV *query = NULL, *body = NULL, *e;
        AV *errs;
        HV *params = NULL;
        int ok;
        if (!o) croak("Open::API: unknown operationId '%s'", SvPV_nolen(op_id));
        rh = oa_hv_of(raw);
        if (!rh) croak("Open::API: validate_request needs a hashref of raw inputs");
        rawpath = oa_hv_of(oa_get(aTHX_ rh, "path"));
        headers = oa_hv_of(oa_get(aTHX_ rh, "header"));
        query   = oa_get(aTHX_ rh, "query");
        body    = oa_get(aTHX_ rh, "body");
        errs    = (AV *)sv_2mortal((SV *)newAV());
        ok = oa_validate_op(aTHX_ a, o, rawpath, query, headers, body,
                            &params, errs);
        PERL_UNUSED_VAR(e);
        if (ok) {
            mXPUSHs(newSViv(1));
            mXPUSHs(newRV_noinc((SV *)params));
        } else {
            mXPUSHs(newSViv(0));
            mXPUSHs(newRV_inc((SV *)errs));
        }
    }

# The PSGI app: $api->to_app(handlers => { opId => sub {...} },
# validate_responses => 0|1). The coderef's request path is entirely C:
# route -> validate -> dispatch -> respond (see oa_plack.h).
SV *
to_app(self, ...)
        SV *self
    CODE:
    {
        SV *handlers = NULL, *before = NULL, *after = NULL, *security = NULL;
        SV *csrf = NULL;
        int vresp = 0, i;
        AV *cap;
        oa_api *a = oa_api_of(aTHX_ self);   /* type check */
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            if (kl == 8 && memEQ(k, "handlers", 8)) handlers = ST(i + 1);
            else if (kl == 6 && memEQ(k, "before", 6)) before = ST(i + 1);
            else if (kl == 5 && memEQ(k, "after", 5))  after  = ST(i + 1);
            else if (kl == 8 && memEQ(k, "security", 8)) security = ST(i + 1);
            else if (kl == 4 && memEQ(k, "csrf", 4))     csrf   = ST(i + 1);
            else if (kl == 18 && memEQ(k, "validate_responses", 18))
                vresp = SvTRUE(ST(i + 1)) ? 1 : 0;
        }
        if (!handlers || !SvROK(handlers)
            || SvTYPE(SvRV(handlers)) != SVt_PVHV)
            croak("Open::API->to_app: a 'handlers' hashref is required");
        {   /* normalise: values are coderefs, or fully qualified sub names
             * ('MyApp::listPets') resolved right here - a typo croaks at
             * to_app time, not per request. */
            HV *src = (HV *)SvRV(handlers);
            HV *dst = newHV();
            HE *he;
            hv_iterinit(src);
            while ((he = hv_iternext(src))) {
                I32 kl; const char *k = hv_iterkey(he, &kl);
                SV *v = hv_iterval(src, he);
                if (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVCV) {
                    (void)hv_store(dst, k, kl, newSVsv(v), 0);
                } else if (v && SvOK(v) && !SvROK(v)) {
                    STRLEN nl; const char *np = SvPV_const(v, nl);
                    CV *cv = get_cv(np, 0);
                    if (!cv)
                        croak("Open::API->to_app: handler for '%.*s' names "
                              "no such sub '%.*s'",
                              (int)kl, k, (int)nl, np);
                    (void)hv_store(dst, k, kl, newRV_inc((SV *)cv), 0);
                } else {
                    croak("Open::API->to_app: handler for '%.*s' must be a "
                          "coderef or a fully qualified sub name", (int)kl, k);
                }
            }
            handlers = sv_2mortal(newRV_noinc((SV *)dst));
        }
        {   /* security checkers: resolve each (coderef or sub name) and
             * verify at startup that every scheme any operation's
             * requirements reference has a checker - a missing one is a
             * config error now, not a 500 later. */
            HV *seccb = newHV();
            oa_ops *t = (oa_ops *)a->ops;
            if (security) {
                HV *src = oa_hv_of(security);
                HE *he;
                if (!src) croak("Open::API->to_app: 'security' must be a "
                                "hashref of scheme => checker");
                hv_iterinit(src);
                while ((he = hv_iternext(src))) {
                    I32 kl; const char *k = hv_iterkey(he, &kl);
                    char what[160];
                    my_snprintf(what, sizeof what,
                                "security checker for '%.*s'", (int)kl, k);
                    (void)hv_store(seccb, k, kl,
                        oa_cv_or_name(aTHX_ hv_iterval(src, he), what), 0);
                }
            }
            if (t) {
                int oi, ai, ii;
                for (oi = 0; oi < t->n; oi++) {
                    oa_op *o = &t->ops[oi];
                    for (ai = 0; ai < o->nsec; ai++) {
                        for (ii = 0; ii < o->sec[ai].n; ii++) {
                            oa_scheme *s =
                                &t->schemes[o->sec[ai].items[ii].scheme];
                            STRLEN nl; const char *np = SvPV_const(s->name, nl);
                            if (!hv_fetch(seccb, np, (I32)nl, 0))
                                croak("Open::API->to_app: operation '%s' "
                                      "requires securityScheme '%.*s' but no "
                                      "checker was given (security => { '%.*s' "
                                      "=> sub { ... } })",
                                      SvPV_nolen(o->op_id), (int)nl, np,
                                      (int)nl, np);
                        }
                    }
                }
            }
            cap = newAV();
            av_push(cap, SvREFCNT_inc(self));
            av_push(cap, SvREFCNT_inc(handlers));
            av_push(cap, newSViv(vresp));
            av_push(cap, before ? oa_cv_or_name(aTHX_ before, "'before' hook")
                                : newSV(0));
            av_push(cap, after  ? oa_cv_or_name(aTHX_ after, "'after' hook")
                                : newSV(0));
            av_push(cap, newRV_noinc((SV *)seccb));
        }
        {   /* csrf: normalise into a config HV (origins AV, check callback,
             * cookie + header names) once, so the request path only reads it.
             * undef when no csrf option was given. */
            SV *cfg = &PL_sv_undef;
            if (csrf && SvOK(csrf)) {
                HV *src = oa_hv_of(csrf);
                HV *dst;
                SV **v;
                if (!src) croak("Open::API->to_app: 'csrf' must be a hashref");
                dst = newHV();
                if ((v = hv_fetchs(src, "origins", 0)) && *v && SvROK(*v)
                    && SvTYPE(SvRV(*v)) == SVt_PVAV)
                    (void)hv_stores(dst, "origins", newSVsv(*v));
                if ((v = hv_fetchs(src, "check", 0)) && *v && SvOK(*v))
                    (void)hv_stores(dst, "check",
                        oa_cv_or_name(aTHX_ *v, "csrf 'check' callback"));
                v = hv_fetchs(src, "cookie", 0);
                (void)hv_stores(dst, "cookie",
                    (v && *v && SvOK(*v)) ? newSVsv(*v) : newSVpvs("csrf"));
                v = hv_fetchs(src, "header", 0);
                (void)hv_stores(dst, "header",
                    (v && *v && SvOK(*v)) ? newSVsv(*v) : newSVpvs("X-CSRF-Token"));
                cfg = sv_2mortal(newRV_noinc((SV *)dst));
            }
            av_push(cap, SvREFCNT_inc(cfg));
        }
        {   /* server options (slot 7): security headers (secure defaults on,
             * overridable / removable), body-size limit, CORS, error format,
             * content negotiation. Always built - the default header set is
             * stamped onto every response in finalize. */
            HV *o_opts = newHV();
            HV *hdrs   = newHV();
            SV *headers_opt = NULL, *cors_opt = NULL, *errfmt_opt = NULL;
            IV maxbody = 0; int negotiate = 0;

            for (i = 1; i + 1 < items; i += 2) {
                STRLEN kl; const char *k = SvPV_const(ST(i), kl);
                SV *v = ST(i + 1);
                if (kl == 7 && memEQ(k, "headers", 7)) headers_opt = v;
                else if (kl == 4 && memEQ(k, "cors", 4)) cors_opt = v;
                else if (kl == 13 && memEQ(k, "max_body_size", 13))
                    maxbody = SvOK(v) ? SvIV(v) : 0;
                else if (kl == 12 && memEQ(k, "error_format", 12)) errfmt_opt = v;
                else if (kl == 9 && memEQ(k, "negotiate", 9)) negotiate = SvTRUE(v);
            }

            /* secure defaults appropriate for a JSON API (HSTS is opt-in) */
            (void)hv_stores(hdrs, "X-Content-Type-Options", newSVpvs("nosniff"));
            (void)hv_stores(hdrs, "Content-Security-Policy",
                newSVpvs("default-src 'none'; frame-ancestors 'none'"));
            (void)hv_stores(hdrs, "X-Frame-Options", newSVpvs("DENY"));
            (void)hv_stores(hdrs, "Referrer-Policy", newSVpvs("no-referrer"));
            if (headers_opt && SvOK(headers_opt)) {
                HV *uh = oa_hv_of(headers_opt);
                HE *he;
                if (!uh) croak("Open::API->to_app: 'headers' must be a hashref");
                hv_iterinit(uh);
                while ((he = hv_iternext(uh))) {
                    I32 kl; const char *k = hv_iterkey(he, &kl);
                    SV *v = hv_iterval(uh, he);
                    HE *h2; AV *del = (AV *)sv_2mortal((SV *)newAV());
                    SSize_t di;
                    hv_iterinit(hdrs);          /* drop any case-variant default */
                    while ((h2 = hv_iternext(hdrs))) {
                        I32 kl2; const char *k2 = hv_iterkey(h2, &kl2);
                        if (oa_ci_eq(k2, (STRLEN)kl2, k, (STRLEN)kl))
                            av_push(del, newSVpvn(k2, kl2));
                    }
                    for (di = 0; di <= av_len(del); di++) {
                        SV **d = av_fetch(del, di, 0);
                        STRLEN dl; const char *dp = SvPV_const(*d, dl);
                        (void)hv_delete(hdrs, dp, (I32)dl, G_DISCARD);
                    }
                    if (SvOK(v))                /* an undef value removes it */
                        (void)hv_store(hdrs, k, kl, newSVsv(v), 0);
                }
            }
            (void)hv_stores(o_opts, "headers", newRV_noinc((SV *)hdrs));

            if (maxbody > 0)
                (void)hv_stores(o_opts, "max_body_size", newSViv(maxbody));
            if (negotiate)
                (void)hv_stores(o_opts, "negotiate", newSViv(1));
            if (errfmt_opt && SvOK(errfmt_opt)) {
                STRLEN l; const char *p = SvPV_const(errfmt_opt, l);
                if (l == 7 && memEQ(p, "problem", 7))
                    (void)hv_stores(o_opts, "error_format", newSVpvs("problem"));
                else if (!(l == 4 && memEQ(p, "json", 4)))
                    croak("Open::API->to_app: 'error_format' must be "
                          "'json' or 'problem'");
            }
            if (cors_opt && SvOK(cors_opt)) {
                HV *cs = oa_hv_of(cors_opt), *cd;
                SV **v, *origins;
                int creds = 0, wild;
                if (!cs) croak("Open::API->to_app: 'cors' must be a hashref");
                cd = newHV();
                if ((v = hv_fetchs(cs, "origins", 0)) && *v && SvOK(*v))
                    origins = newSVsv(*v);
                else
                    origins = newSVpvs("*");    /* public by default */
                if ((v = hv_fetchs(cs, "credentials", 0)) && *v)
                    creds = SvTRUE(*v);
                /* a wildcard origin with credentials would let any site make
                 * credentialed requests - refuse the footgun */
                wild = 0;
                if (!SvROK(origins)) {
                    STRLEN wl; const char *wp = SvPV_const(origins, wl);
                    wild = (wl == 1 && *wp == '*');
                }
                if (SvROK(origins) && SvTYPE(SvRV(origins)) == SVt_PVAV) {
                    AV *l = (AV *)SvRV(origins); SSize_t j;
                    for (j = 0; j <= av_len(l); j++) {
                        SV **e = av_fetch(l, j, 0);
                        if (e && *e && SvPOK(*e) && SvCUR(*e) == 1
                            && *SvPVX(*e) == '*') { wild = 1; break; }
                    }
                }
                if (creds && wild)
                    croak("Open::API->to_app: cors credentials => 1 needs an "
                          "explicit origins list (a wildcard '*' origin cannot "
                          "be used with credentials)");
                (void)hv_stores(cd, "origins", origins);
                (void)hv_stores(cd, "credentials", newSViv(creds ? 1 : 0));
                if ((v = hv_fetchs(cs, "headers", 0)) && *v && SvOK(*v))
                    (void)hv_stores(cd, "headers", newSVsv(*v));
                if ((v = hv_fetchs(cs, "expose", 0)) && *v && SvROK(*v))
                    (void)hv_stores(cd, "expose", newSVsv(*v));
                if ((v = hv_fetchs(cs, "max_age", 0)) && *v && SvOK(*v))
                    (void)hv_stores(cd, "max_age", newSVsv(*v));
                (void)hv_stores(o_opts, "cors", newRV_noinc((SV *)cd));
            }
            av_push(cap, newRV_noinc((SV *)o_opts));
        }
        RETVAL = oa_closure(aTHX_ oa_app_cb, cap);
    }
    OUTPUT:
        RETVAL

# ---- test shims (validate one value through a compiled handle) -------------

# -1 unknown op/param, -2 no schema, else is_valid 0/1
int
_param_check(self, op_id, in, name, value)
        SV *self
        SV *op_id
        SV *in
        SV *name
        SV *value
    CODE:
    {
        oa_api *a = oa_api_of(aTHX_ self);
        oa_op *o = oa_op_by_id(aTHX_ a, op_id);
        int loc = oa_param_loc(aTHX_ in), i;
        RETVAL = -1;
        if (o && loc >= 0) {
            for (i = 0; i < o->nparams[loc]; i++) {
                if (sv_eq(o->params[loc][i].name, name)) {
                    RETVAL = o->params[loc][i].handle
                        ? JSF->is_valid(aTHX_ o->params[loc][i].handle, value)
                        : -2;
                    break;
                }
            }
        }
    }
    OUTPUT:
        RETVAL

# -1 unknown op/ctype, -2 pass-through (no schema), else is_valid 0/1
int
_body_check(self, op_id, ctype, value)
        SV *self
        SV *op_id
        SV *ctype
        SV *value
    CODE:
    {
        oa_api *a = oa_api_of(aTHX_ self);
        oa_op *o = oa_op_by_id(aTHX_ a, op_id);
        int i;
        RETVAL = -1;
        if (o) {
            for (i = 0; i < o->nbodies; i++) {
                if (sv_eq(o->bodies[i].ctype, ctype)) {
                    RETVAL = o->bodies[i].handle
                        ? JSF->is_valid(aTHX_ o->bodies[i].handle, value)
                        : -2;
                    break;
                }
            }
        }
    }
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self
    CODE:
        oa_api_free(aTHX_ oa_api_of(aTHX_ self));

MODULE = Open::API        PACKAGE = Open::API::Client

# Open::API::Client->new(api => $api | spec => ..., base_url => ...,
# validate => 0|1, %ua_opts). Remaining pairs (timeout, tls_verify,
# pool_size, loop, ...) are passed to Fetch's ua_new on first use.
SV *
new(class, ...)
        SV *class
    CODE:
    {
        const char *cls = (SvROK(class) && SvOBJECT(SvRV(class)))
                        ? HvNAME(SvSTASH(SvRV(class))) : SvPV_nolen(class);
        /* mortal until blessed: a croak below must not leak them */
        HV *self = (HV *)sv_2mortal((SV *)newHV());
        AV *ua_opts = (AV *)sv_2mortal((SV *)newAV());
        SV *api = NULL, *spec = NULL;
        SV **bv;
        STRLEN bl = 0;
        int i;
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            SV *v = ST(i + 1);
            if      (kl == 3 && memEQ(k, "api", 3))       api = v;
            else if (kl == 4 && memEQ(k, "spec", 4))      spec = v;
            else if (kl == 8 && memEQ(k, "base_url", 8))
                (void)hv_stores(self, "base_url", newSVsv(v));
            else if (kl == 8 && memEQ(k, "security", 8))
                (void)hv_stores(self, "security", newSVsv(v));
            else if (kl == 4 && memEQ(k, "csrf", 4))
                (void)hv_stores(self, "_csrf_opt", newSVsv(v));
            else if (kl == 8 && memEQ(k, "validate", 8))
                (void)hv_stores(self, "validate", newSViv(SvTRUE(v) ? 1 : 0));
            else {
                av_push(ua_opts, newSVpvn(k, kl));
                av_push(ua_opts, newSVsv(v));
            }
        }
        if (api) {
            if (!sv_derived_from(api, "Open::API"))
                croak("Open::API::Client->new: 'api' must be an Open::API");
            (void)hv_stores(self, "api", newSVsv(api));
        } else if (spec) {
            (void)hv_stores(self, "api",
                            oa_new_from_spec(aTHX_ "Open::API", spec));
        } else {
            croak("Open::API::Client->new: give 'api' or 'spec'");
        }
        bv = hv_fetchs(self, "base_url", 0);
        if (bv && *bv && SvOK(*bv)) (void)SvPV_const(*bv, bl);
        if (!bl)
            croak("Open::API::Client->new: a 'base_url' is required");
        {   /* normalise transparent-CSRF config: cookie + header names and
             * the Origin to present (derived from base_url unless given) */
            SV **c = hv_fetchs(self, "_csrf_opt", 0);
            if (c && *c && SvTRUE(*c)) {
                HV *cd  = newHV();
                HV *src = (SvROK(*c) && SvTYPE(SvRV(*c)) == SVt_PVHV)
                        ? (HV *)SvRV(*c) : NULL;
                SV **v;
                if (src && (v = hv_fetchs(src, "cookie", 0)) && *v && SvOK(*v))
                    (void)hv_stores(cd, "cookie", newSVsv(*v));
                else (void)hv_stores(cd, "cookie", newSVpvs("csrf"));
                if (src && (v = hv_fetchs(src, "header", 0)) && *v && SvOK(*v))
                    (void)hv_stores(cd, "header", newSVsv(*v));
                else (void)hv_stores(cd, "header", newSVpvs("X-CSRF-Token"));
                if (src && (v = hv_fetchs(src, "origin", 0)) && *v && SvOK(*v))
                    (void)hv_stores(cd, "origin", newSVsv(*v));
                else {   /* scheme://authority of base_url (strip any path) */
                    SV *bu = *hv_fetchs(self, "base_url", 0);
                    STRLEN bl; const char *bp = SvPV_const(bu, bl);
                    STRLEN i2, sep;
                    for (i2 = 0; i2 + 2 < bl; i2++)
                        if (bp[i2] == ':' && bp[i2+1] == '/' && bp[i2+2] == '/')
                            { i2 += 3; break; }
                    if (i2 + 2 >= bl) i2 = 0;
                    for (sep = i2; sep < bl && bp[sep] != '/'; sep++) ;
                    (void)hv_stores(cd, "origin", newSVpvn(bp, sep));
                }
                (void)hv_stores(self, "_csrf", newRV_noinc((SV *)cd));
            }
            (void)hv_deletes(self, "_csrf_opt", G_DISCARD);
        }
        (void)hv_stores(self, "ua_opts", newRV_inc((SV *)ua_opts));
        RETVAL = sv_bless(newRV_inc((SV *)self), gv_stashpv(cls, GV_ADD));
    }
    OUTPUT:
        RETVAL

# Fire one operation: $client->call($operationId, %params). Flat %params are
# matched to the operation's declared parameters by name (body => the request
# body). Croaks on invalid input BEFORE any I/O; returns a Fetch::Future
# resolving to { status, headers, data, error? }.
SV *
call(self, op_id, ...)
        SV *self
        SV *op_id
    CODE:
    {
        HV *params = (HV *)sv_2mortal((SV *)newHV());
        int i;
        if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVHV)
            croak("Open::API::Client: not a client");
        for (i = 2; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(params, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        RETVAL = oa_cli_call(aTHX_ (HV *)SvRV(self), op_id, params);
    }
    OUTPUT:
        RETVAL

# True when the operationId exists (can() support; can stays pure Perl).
int
_has_op(self, name)
        SV *self
        SV *name
    CODE:
        RETVAL = (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV)
               ? oa_op_exists(aTHX_ (HV *)SvRV(self), name) : 0;
    OUTPUT:
        RETVAL

# $client->$operationId(%params) sugar. Perl sets $Open::API::Client::AUTOLOAD
# to the fully-qualified name; we dispatch straight to oa_cli_call (the same C
# path as ->call), skipping a Perl method hop. An unknown name croaks - a typo
# dies rather than silently 404ing.
void
AUTOLOAD(self, ...)
        SV *self
    PPCODE:
    {
        SV *avar = get_sv("Open::API::Client::AUTOLOAD", 0);
        const char *full, *mp;
        SV *op, *ret;
        HV *params;
        int i;
        if (!avar || !SvOK(avar)) XSRETURN_EMPTY;
        full = SvPV_nolen(avar);
        mp   = strrchr(full, ':');
        mp   = mp ? mp + 1 : full;
        if (strEQ(mp, "DESTROY")) XSRETURN_EMPTY;
        op = sv_2mortal(newSVpv(mp, 0));
        if (!(SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV
              && oa_op_exists(aTHX_ (HV *)SvRV(self), op)))
            croak("Open::API::Client: no such method or operation '%s'", mp);
        params = (HV *)sv_2mortal((SV *)newHV());
        for (i = 1; i + 1 < items; i += 2) {
            STRLEN kl; const char *k = SvPV_const(ST(i), kl);
            (void)hv_store(params, k, (I32)kl, newSVsv(ST(i + 1)), 0);
        }
        ret = oa_cli_call(aTHX_ (HV *)SvRV(self), op, params);
        ST(0) = sv_2mortal(ret);
        XSRETURN(1);
    }

# can(): a real method if one exists (like UNIVERSAL::can - Open::API::Client
# has no @ISA, so the original SUPER::can collapsed to that), else a coderef
# for an operationId (so `$c->can($op)->($c, %p)` works), else undef.
SV *
can(self, method)
        SV *self
        SV *method
    CODE:
    {
        const char *m = SvPV_nolen(method);
        HV *stash = (SvROK(self) && SvOBJECT(SvRV(self))) ? SvSTASH(SvRV(self))
                  : SvPOK(self) ? gv_stashsv(self, 0) : NULL;
        GV *gv;
        RETVAL = &PL_sv_undef;
        if (stash && (gv = gv_fetchmethod_autoload(stash, m, FALSE)) && GvCV(gv))
            RETVAL = newRV_inc((SV *)GvCV(gv));            /* a real method */
        else if (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV
                 && oa_op_exists(aTHX_ (HV *)SvRV(self), method)) {
            AV *cap = newAV();
            av_push(cap, newSVsv(method));                 /* capture the op id */
            RETVAL = oa_closure(aTHX_ oa_op_call_cb, cap); /* +1 owned coderef */
        }
    }
    OUTPUT:
        RETVAL

# The underlying Open::API object.
SV *
api(self)
        SV *self
    CODE:
    {
        SV **e = (SvROK(self) && SvTYPE(SvRV(self)) == SVt_PVHV)
               ? hv_fetchs((HV *)SvRV(self), "api", 0) : NULL;
        RETVAL = (e && *e) ? newSVsv(*e) : &PL_sv_undef;
    }
    OUTPUT:
        RETVAL

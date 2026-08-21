/* punk_context.h - the per-request context object, in C.
 *
 * Punk::Context is a blessed AV whose slots are defined here and nowhere else:
 * this enum is the whole storage contract. Both faces of it are C - the plain
 * accessors (env/app/_req/_res/stash_hv/openapi_params/match) and the hot
 * methods (req/res/stash/param/json/text/html/...) are all XSUBs in
 * xs/context.xs reading these slots directly, and _build fills them. There is
 * no Perl-side class builder to keep in step, so lib/Punk/Context.pm is
 * documentation only.
 *
 * Perl headers and punk_response.h (punk_triplet, the PS_* Response slots)
 * must be in scope before this file.
 */

#ifndef PUNK_CONTEXT_H
#define PUNK_CONTEXT_H

/* The slot layout. The accessor XSUB's ALIAS indices run in this same order
 * (see xs/context.xs), which is what lets it map ix straight to a slot. */
enum {
    PCX_ENV     = 0,
    PCX_APP     = 1,
    PCX_REQ     = 2,
    PCX_RES     = 3,
    PCX_STASH   = 4,
    PCX_OPENAPI = 5,
    PCX_MATCH   = 6,
    PCX_UA      = 7,  /* memoised $c->ua; the agent itself lives on the app */
    PCX_REQID   = 8   /* Punk::Plugin::RequestId's id, when it is loaded     */
};

static AV *pcx_av(pTHX_ SV *self) {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
        croak("Punk::Context: not a context object");
    return (AV *)SvRV(self);
}

/* the slot value, or NULL when unset */
static SV *pcx_get(pTHX_ AV *av, I32 slot) {
    SV **e = av_fetch(av, slot, 0);
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

/* the Punk::Response AV at PCX_RES (its slots are the PS_* from
 * punk_response.h), or NULL when the response was never forced. */
static AV *pcx_res_av(pTHX_ AV *av) {
    SV *r = pcx_get(aTHX_ av, PCX_RES);
    return (r && SvROK(r) && SvTYPE(SvRV(r)) == SVt_PVAV) ? (AV *)SvRV(r) : NULL;
}

/* the pending response status (PS_STATUS), or 0 */
static IV pcx_res_status(pTHX_ AV *res) {
    SV **e = res ? av_fetch(res, PS_STATUS, 0) : NULL;
    return (e && *e && SvOK(*e)) ? SvIV(*e) : 0;
}

/* the pending response header pair-AV (PS_HEADERS), or NULL */
static AV *pcx_res_headers(pTHX_ AV *res) {
    SV **e = res ? av_fetch(res, PS_HEADERS, 0) : NULL;
    return (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV)
        ? (AV *)SvRV(*e) : NULL;
}

/* Lazily build the sub-object in a slot (Punk::Request / Punk::Response) with
 * Class->new($arg?), caching it. Returns it borrowed (the slot owns it). */
static SV *pcx_force(pTHX_ AV *av, I32 slot, const char *class, SV *arg) {
    SV *cur = pcx_get(aTHX_ av, slot);
    if (cur) return cur;
    {
        dSP; SV *obj; int count;
        ENTER; SAVETMPS;
        PUSHMARK(SP); EXTEND(SP, arg ? 2 : 1);
        PUSHs(sv_2mortal(newSVpv(class, 0)));
        if (arg) PUSHs(arg);
        PUTBACK;
        count = call_method("new", G_SCALAR);
        SPAGAIN;
        obj = count > 0 ? POPs : &PL_sv_undef;
        SvREFCNT_inc(obj);
        PUTBACK; FREETMPS; LEAVE;
        (void)av_store(av, slot, obj);
        return obj;
    }
}

/* Call $obj->$meth(@argv) in its own stack scope, returning the scalar result
 * (+1) when want is true, else NULL. argv holds stable SV* captured before any
 * stack manipulation (EXTEND may move the caller's stack, staling ST()). */
static SV *pcx_call_meth(pTHX_ SV *obj, const char *meth,
                         SV **argv, int nargs, int want) {
    dSP; SV *r = NULL; int count, i;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, nargs + 1);
    PUSHs(obj);
    for (i = 0; i < nargs; i++) PUSHs(argv[i]);
    PUTBACK;
    count = call_method(meth, want ? G_SCALAR : G_VOID);
    SPAGAIN;
    if (want && count > 0) r = SvREFCNT_inc(POPs);
    PUTBACK; FREETMPS; LEAVE;
    return r;
}

/* The context's own parameter layers, in precedence order: the validated
 * OpenAPI params (path, then query), then the route captures. Borrowed,
 * NULL when neither carries the name - the request is the caller's
 * fallback, because reaching it forces Punk::Request into being. */
static SV *pcx_param_local(pTHX_ AV *av, SV *name) {
    STRLEN nl;
    const char *n = SvPV_const(name, nl);
    SV *op = pcx_get(aTHX_ av, PCX_OPENAPI);
    SV *m  = pcx_get(aTHX_ av, PCX_MATCH);
    if (op && SvROK(op) && SvTYPE(SvRV(op)) == SVt_PVHV) {
        HV *oph = (HV *)SvRV(op);
        static const char *loc[2] = { "path", "query" };
        int i;
        for (i = 0; i < 2; i++) {
            SV **lv = hv_fetch(oph, loc[i], (I32)strlen(loc[i]), 0);
            if (lv && *lv && SvROK(*lv) && SvTYPE(SvRV(*lv)) == SVt_PVHV) {
                SV **v = hv_fetch((HV *)SvRV(*lv), n, (I32)nl, 0);
                if (v) return *v ? *v : &PL_sv_undef;
            }
        }
    }
    if (m && SvROK(m) && SvTYPE(SvRV(m)) == SVt_PVHV) {
        SV **cap = hv_fetchs((HV *)SvRV(m), "captures", 0);
        if (cap && *cap && SvROK(*cap) && SvTYPE(SvRV(*cap)) == SVt_PVHV) {
            SV **v = hv_fetch((HV *)SvRV(*cap), n, (I32)nl, 0);
            if (v) return *v ? *v : &PL_sv_undef;
        }
    }
    return NULL;
}

/* The lazy Punk::Request for this context, borrowed. */
static SV *pcx_req(pTHX_ AV *av) {
    return pcx_force(aTHX_ av, PCX_REQ, "Punk::Request",
                     pcx_get(aTHX_ av, PCX_ENV));
}

/* $c->param($name): the layers above, else the request (query, then form
 * body). Owned (+1), NULL when nothing carries the name. */
static SV *pcx_param(pTHX_ AV *av, SV *name) {
    SV *found = pcx_param_local(aTHX_ av, name);
    SV *argv[1];
    SV *r;
    if (found) return newSVsv(found);
    argv[0] = name;
    r = pcx_call_meth(aTHX_ pcx_req(aTHX_ av), "param", argv, 1, 1);
    if (r && SvOK(r)) return r;
    if (r) SvREFCNT_dec(r);
    return NULL;
}

/* Every parameter the context can see, stacked in the same precedence
 * pcx_param resolves one by: the request's merged table underneath, then
 * the route captures, then the validated OpenAPI query and path. +1. */
static HV *pcx_params_merged(pTHX_ AV *av) {
    HV *out = newHV();
    SV *rp  = pcx_call_meth(aTHX_ pcx_req(aTHX_ av), "params", NULL, 0, 1);
    SV *m   = pcx_get(aTHX_ av, PCX_MATCH);
    SV *op  = pcx_get(aTHX_ av, PCX_OPENAPI);
    pq_overlay(aTHX_ out, rp);
    if (rp) SvREFCNT_dec(rp);
    if (m && SvROK(m) && SvTYPE(SvRV(m)) == SVt_PVHV) {
        SV **cap = hv_fetchs((HV *)SvRV(m), "captures", 0);
        if (cap) pq_overlay(aTHX_ out, *cap);
    }
    if (op && SvROK(op) && SvTYPE(SvRV(op)) == SVt_PVHV) {
        HV *oph  = (HV *)SvRV(op);
        SV **qry = hv_fetchs(oph, "query", 0);
        SV **pth = hv_fetchs(oph, "path", 0);
        if (qry) pq_overlay(aTHX_ out, *qry);
        if (pth) pq_overlay(aTHX_ out, *pth);
    }
    return out;
}

/* does the blessed ref have method $meth? (a ->can without the call) */
static int pcx_can(pTHX_ SV *obj, const char *meth) {
    HV *stash = (SvROK(obj) && SvOBJECT(SvRV(obj))) ? SvSTASH(SvRV(obj)) : NULL;
    return (stash && gv_fetchmethod_autoload(stash, meth, 0)) ? 1 : 0;
}

/* $h->($c, $resp) trapping a die; result (+1) or NULL, *died set. */
static SV *pcx_call2(pTHX_ SV *h, SV *a, SV *b, int *died) {
    dSP; SV *r; int count;
    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, 2); PUSHs(a); PUSHs(b); PUTBACK;
    count = call_sv(h, G_SCALAR | G_EVAL);
    SPAGAIN;
    r = count > 0 ? SvREFCNT_inc(POPs) : NULL;
    PUTBACK; FREETMPS; LEAVE;
    *died = SvTRUE(ERRSV) ? 1 : 0;
    return r;
}

/* Is $ret already a PSGI triplet [ $status, \@headers, \@body ]? */
static int pcx_is_triplet(pTHX_ SV *ret) {
    AV *a;
    SV **s, **h;
    if (!SvROK(ret) || SvTYPE(SvRV(ret)) != SVt_PVAV) return 0;
    a = (AV *)SvRV(ret);
    if (av_len(a) != 2) return 0;
    s = av_fetch(a, 0, 0);
    h = av_fetch(a, 1, 0);
    if (!(s && *s && SvOK(*s) && !SvROK(*s))) return 0;
    if (!(h && *h && SvROK(*h) && SvTYPE(SvRV(*h)) == SVt_PVAV)) return 0;
    {
        STRLEN l;
        const char *p = SvPV_const(*s, l);
        return (l == 3 && p[0] >= '1' && p[0] <= '5'
                && isDIGIT(p[1]) && isDIGIT(p[2]));
    }
}

/* Coerce a handler return into a PSGI triplet: a triplet passes through, a
 * Punk::Response finalizes, a Future is awaited and re-coerced, anything else
 * is JSON-encoded (folding in the context's pending status/headers). +1. */
static SV *punk_coerce(pTHX_ SV *c, SV *ret) {
    /* a coderef is a PSGI streaming / delayed-response body (SSE uses this on
     * a psgi.streaming server) - hand it straight to the server */
    if (SvROK(ret) && SvTYPE(SvRV(ret)) == SVt_PVCV) return SvREFCNT_inc(ret);
    if (pcx_is_triplet(aTHX_ ret)) return SvREFCNT_inc(ret);
    if (SvROK(ret) && SvOBJECT(SvRV(ret))) {
        if (sv_derived_from(ret, "Punk::Response"))
            return pcx_call_meth(aTHX_ ret, "finalize", NULL, 0, 1);
        if (pcx_can(aTHX_ ret, "on_ready")) {
            SV *got = pcx_call_meth(aTHX_ ret, "get", NULL, 0, 1);
            SV *r   = punk_coerce(aTHX_ c, got ? got : &PL_sv_undef);
            if (got) SvREFCNT_dec(got);
            return r;
        }
    }
    {
        AV *res   = pcx_res_av(aTHX_ pcx_av(aTHX_ c));
        IV  st    = pcx_res_status(aTHX_ res);
        SV *bytes = punk_frj(aTHX)->encode(aTHX_ ret, NULL);
        if (!st) st = 200;
        return punk_triplet(aTHX_ st,
                   sv_2mortal(newSVpvs("application/json")),
                   bytes, res ? pcx_res_headers(aTHX_ res) : NULL);
    }
}

/* Finish a response: coerce if needed, run the after-dispatch hooks (each may
 * replace the triplet), and blank the body on HEAD. +1. */
static SV *punk_deliver(pTHX_ SV *c, SV *resp, int is_head, AV *after) {
    SV *r = pcx_is_triplet(aTHX_ resp) ? SvREFCNT_inc(resp)
                                       : punk_coerce(aTHX_ c, resp);
    /* a streaming coderef has no triplet to mutate: skip after-hooks and HEAD */
    if (SvROK(r) && SvTYPE(SvRV(r)) == SVt_PVCV) {
        if (PK_OBS_WANT_RES) pk_obs_fire_res(aTHX_ c, r);
        return r;
    }
    if (after) {
        SSize_t i, n = av_len(after) + 1;
        for (i = 0; i < n; i++) {
            SV **hp = av_fetch(after, i, 0);
            int died = 0;
            SV *hr;
            if (!hp || !*hp) continue;
            hr = pcx_call2(aTHX_ *hp, c, r, &died);
            if (!died && hr && pcx_is_triplet(aTHX_ hr)) {
                SvREFCNT_dec(r);
                r = SvREFCNT_inc(hr);
            }
            if (hr) SvREFCNT_dec(hr);
        }
    }
    if (is_head && SvROK(r) && SvTYPE(SvRV(r)) == SVt_PVAV) {
        AV *ra = (AV *)SvRV(r);
        SV **b = av_fetch(ra, 2, 0);
        if (b && *b && SvROK(*b) && SvTYPE(SvRV(*b)) == SVt_PVAV) {
            AV *empty = newAV();
            av_push(empty, newSVpvs(""));
            (void)av_store(ra, 2, newRV_noinc((SV *)empty));
        }
    }
    /* The C ABI's response observers. Here rather than in the dispatcher
     * because this is the ONE place a final triplet is produced: the
     * synchronous path reaches it through punk_finish_c, and every
     * asynchronous completion reaches it from punk_compile.h when the future
     * settles - so an observer sees the response that was actually sent, at
     * the moment it was, and sees it exactly once either way. The four
     * dispatcher exits that never come through here fire it themselves. */
    if (PK_OBS_WANT_RES) pk_obs_fire_res(aTHX_ c, r);
    return r;
}

/* Is this a same-origin relative path - somewhere on this site, and nowhere
 * else? Backs $c->safe_path, the guard for a redirect destination that came
 * out of the request (?to=, ?return=, ?next=).
 *
 * Checking for a leading '/' and no leading '//' is NOT enough, because the
 * browser does not read the string byte for byte the way this does:
 *
 *   - it removes every TAB, CR and LF from a URL before parsing it, so
 *     "/<TAB>/evil.example" is parsed as "//evil.example";
 *   - under a special scheme it treats '\' as '/', so "/\evil.example" is
 *     protocol-relative too.
 *
 * Either one leaves the site, which is why this refuses the whole class -
 * every C0 control, DEL, and a backslash anywhere - rather than trying to
 * enumerate the bytes some parser somewhere might drop. The same rule (and
 * the same reasoning) as Punk::OAuth2's same_origin_path, which is where it
 * was learned the expensive way: CVE-2026-75628. A path that genuinely wants
 * one of these spells it percent-encoded. */
static int pk_same_origin_path(pTHX_ SV *path) {
    STRLEN n, i;
    const char *p;
    if (!path || !SvOK(path)) return 0;
    p = SvPV_const(path, n);
    if (n < 1 || p[0] != '/') return 0;
    if (n >= 2 && p[1] == '/') return 0;
    for (i = 0; i < n; i++) {
        const unsigned char ch = (unsigned char)p[i];
        if (ch < 0x20 || ch == 0x7f || ch == '\\') return 0;
    }
    return 1;
}

#endif /* PUNK_CONTEXT_H */

/* punk_url.h - named routes: what a name may be, and the URL a name builds.
 *
 * A route carries a `name` option, the keyword records it, to_app stamps it
 * onto the compiled record and resolves the whole set into one name ->
 * record index hash. $c->url_for reads that hash and walks the pr_seg array
 * punk_route.h already parsed at to_app.
 *
 * The validator lives here rather than in xs/app.xs because three callers
 * want one answer: the route option, the websocket/sse keywords, and the
 * documentation that has to say what a name is.
 */

#ifndef PUNK_URL_H
#define PUNK_URL_H

/* Reserved argument words in url_for. A route named for one of these would
 * be callable and un-passable at once: url_for('query', query => {...}) has
 * no reading that names the route AND its query string. */
static const char *const PK_URL_RESERVED[] = { "absolute", "query" };
#define PK_URL_N_RESERVED 2

/* Is this a usable route name? A name is an IDENTIFIER, not a string: it is
 * written in url_for('book'), in {% url.book %}, in `punk routes --name
 * book` and in a Punk::Test arrayref, and only an identifier works in all
 * four. Croaks with the reason, at the keyword, so a bad name fails on the
 * line that wrote it rather than at to_app or at a render.
 *
 * `what` names the caller for the message ("route", "websocket", "sse").
 */
static void pk_url_check_name(pTHX_ SV *name, const char *what,
                              SV *method, SV *path) {
    const char *n;
    STRLEN nl, i;
    int k;

    if (SvROK(name))
        croak("Punk: %s name must be a string, not a %s - a route has one "
              "name, and aliases are not a thing", what,
              sv_reftype(SvRV(name), 0));
    if (!SvOK(name) || !SvCUR(name))
        croak("Punk: %s name on %s %s is empty - a name is what url_for "
              "asks for", what,
              method ? SvPV_nolen(method) : "?", path ? SvPV_nolen(path) : "?");

    n = SvPV_const(name, nl);
    for (i = 0; i < nl; i++) {
        const unsigned char ch = (unsigned char)n[i];
        if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')
            || (ch >= '0' && ch <= '9') || ch == '_')
            continue;
        /* A dot is the one wrong character worth its own message: it is the
         * natural way to namespace a plugin's routes, it reads fine, and it
         * produces a name a handler can build and a template cannot reach -
         * Template::Stencil resolves {% url.queue.jobs %} as
         * url->{queue}{jobs}, so the name would be invisible at exactly the
         * seam it was written for. */
        if (ch == '.')
            croak("Punk: %s name '%.*s' may not contain '.' - a template "
                  "reads {%% url.%.*s %%} as a path through nested hashes, "
                  "so a dotted name cannot be reached from one. Namespace "
                  "with an underscore: '%.*s' -> 'queue_jobs'",
                  what, (int)nl, n, (int)nl, n, (int)nl, n);
        croak("Punk: %s name '%.*s' is not an identifier - names are "
              "[A-Za-z0-9_]+, because one name is written in url_for, in a "
              "template, in `punk routes --name` and in a test",
              what, (int)nl, n);
    }
    for (k = 0; k < PK_URL_N_RESERVED; k++)
        if (strEQ(n, PK_URL_RESERVED[k]))
            croak("Punk: '%s' is reserved and cannot be a %s name - url_for "
                  "takes it as an option, so the route could be named and "
                  "never called", PK_URL_RESERVED[k], what);
}


/* ---- the encoder --------------------------------------------------------
 *
 * RFC 3986: unreserved (A-Za-z0-9-._~) passes, everything else becomes %XX
 * with uppercase hex. `keep_slash` passes '/' through as well, which is the
 * difference between a *splat (a path tail, slashes and all) and a :param
 * (one segment, where a slash would change the shape of the URL).
 *
 * Space is %20 and never '+': '+' is a form-body convention, and a path has
 * no forms. Using one encoder on both sides of the '?' means a query value
 * built here decodes identically and does not have to know which side it is
 * on.
 */
static void pk_pct_cat(pTHX_ SV *out, const char *s, STRLEN len, int keep_slash) {
    static const char hex[] = "0123456789ABCDEF";
    STRLEN i, run = 0;
    for (i = 0; i < len; i++) {
        const unsigned char ch = (unsigned char)s[i];
        if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')
            || (ch >= '0' && ch <= '9') || ch == '-' || ch == '_'
            || ch == '.' || ch == '~' || (keep_slash && ch == '/')) {
            run++;                       /* copy passing bytes in one go */
            continue;
        }
        if (run) { sv_catpvn(out, s + i - run, run); run = 0; }
        {
            char e[3];
            e[0] = '%'; e[1] = hex[ch >> 4]; e[2] = hex[ch & 15];
            sv_catpvn(out, e, 3);
        }
    }
    if (run) sv_catpvn(out, s + len - run, run);
}

static SV *pk_pct_encode(pTHX_ const char *s, STRLEN len, int keep_slash) {
    SV *out = newSVpvs("");
    pk_pct_cat(aTHX_ out, s, len, keep_slash);
    return out;
}

/* The UTF-8 BYTES of a value, for encoding.
 *
 * A URL carries bytes, and the bytes a browser will send back for a
 * non-ASCII capture are UTF-8. An SV with the flag on already holds those;
 * one with the flag off holds Latin-1 semantics, where a 0xE9 means U+00E9
 * and has to become %C3%A9 rather than %E9. Upgrading a MORTAL COPY rather
 * than the caller's SV matters: the value is usually a field of a model row
 * the handler still holds, and a read-only SV would croak.
 *
 * Pure ASCII - almost every id - takes neither the copy nor the scan twice.
 */
static const char *pk_url_bytes(pTHX_ SV *sv, STRLEN *lenp) {
    STRLEN i, l;
    const char *p = SvPV_const(sv, l);
    if (SvUTF8(sv)) { *lenp = l; return p; }
    for (i = 0; i < l; i++)
        if ((unsigned char)p[i] & 0x80) {
            SV *cp = sv_mortalcopy(sv);
            sv_utf8_upgrade(cp);
            return SvPV_const(cp, *lenp);
        }
    *lenp = l;
    return p;
}

/* ---- the query string ---------------------------------------------------
 *
 * Keys sorted bytewise, because a URL that reorders itself between runs is
 * one nobody can test or cache and a hash walk in C has no order worth
 * relying on. An undef value is the bare key (?flag); an arrayref repeats
 * the key in the array's order, which is what Punk::Request reads back for
 * a repeated key.
 */
static void pk_url_query_cat(pTHX_ SV *out, HV *q) {
    AV *keys = (AV *)sv_2mortal((SV *)newAV());
    SSize_t i, n = 0;
    HE *he;
    int first = 1;

    hv_iterinit(q);
    while ((he = hv_iternext(q))) { av_push(keys, newSVsv(hv_iterkeysv(he))); n++; }
    if (!n) return;
    if (n > 1) sortsv(AvARRAY(keys), (STRLEN)n, Perl_sv_cmp);

    for (i = 0; i < n; i++) {
        SV *k = *av_fetch(keys, i, 0);
        HE *e = hv_fetch_ent(q, k, 0, 0);
        SV *v = e ? HeVAL(e) : &PL_sv_undef;
        STRLEN kl;
        const char *kp = pk_url_bytes(aTHX_ k, &kl);
        AV *multi = (v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVAV)
                    ? (AV *)SvRV(v) : NULL;
        SSize_t j, jn = multi ? av_len(multi) + 1 : 1;

        for (j = 0; j < jn; j++) {
            SV *one = multi ? *av_fetch(multi, j, 0) : v;
            sv_catpvn(out, first ? "?" : "&", 1);
            first = 0;
            pk_pct_cat(aTHX_ out, kp, kl, 0);
            if (one && SvOK(one)) {          /* undef is the bare key */
                STRLEN vl;
                const char *vp = pk_url_bytes(aTHX_ one, &vl);
                sv_catpvn(out, "=", 1);
                pk_pct_cat(aTHX_ out, vp, vl, 0);
            }
        }
    }
}

/* ---- the build ----------------------------------------------------------
 *
 * One pass over the segments punk_route.h already parsed at to_app, or the
 * declared path for a static route. Free of the request: everything that
 * varies per request - the prefix, the origin - is passed in, so the
 * template filter and the API mount can call this with their own.
 *
 *   rt      the compiled router
 *   idx     the record index the name resolved to
 *   args    the caller's pairs; capture names are consumed from here and
 *           whatever is left becomes the query string
 *   query   an explicit query hash, or NULL. With one, a leftover argument
 *           is a mistake rather than a query key
 *   prefix  SCRIPT_NAME and the path on `host`, or NULL
 *   origin  scheme://host for an absolute URL, or NULL
 *   name    the route's name, for the messages
 */
/* Fill one hole from the arguments, percent-encoded, and mark the argument
 * used so it does not also become a query pair.
 *
 * `splat` passes slashes through: it is the one place in a URL where a
 * capture may legitimately contain one. Everywhere else a '/' croaks rather
 * than being encoded, because PATH_INFO reaches the router percent-DECODED -
 * the %2F would be a '/' again, the path would have one segment too many,
 * and the request would 404. A URL that cannot work is a bug at the call
 * site, not a value to return.
 */
#define PK_CAP_PARAM 0   /* :param - one segment of a Punk route      */
#define PK_CAP_SPLAT 1   /* *splat - the tail, slashes and all          */
#define PK_CAP_HOLE  2   /* {hole} - one OpenAPI path-template variable */

static void pk_url_cap_cat(pTHX_ SV *out, HV *args, HV *used, SV *capname,
                           int kind, const char *name) {
    const int splat = (kind == PK_CAP_SPLAT);
    HE *he = hv_fetch_ent(args, capname, 0, 0);
    SV *v  = he ? HeVAL(he) : NULL;
    const char *cn = SvPV_nolen(capname);
    STRLEN vl, i;
    const char *vp;

    if (!v || !SvOK(v)) {
        SvREFCNT_dec(out);
        croak("Punk: url_for('%s'): no value for :%s - a URL with a hole in "
              "it is a bug, not a value", name, cn);
    }
    if (SvROK(v)) {
        SvREFCNT_dec(out);
        croak("Punk: url_for('%s'): :%s is a %s - a capture is one value",
              name, cn, sv_reftype(SvRV(v), 0));
    }
    vp = pk_url_bytes(aTHX_ v, &vl);
    if (!vl) {
        SvREFCNT_dec(out);
        croak("Punk: url_for('%s'): :%s is empty - the route needs one "
              "character there and would not match the URL this built",
              name, cn);
    }
    if (!splat) for (i = 0; i < vl; i++)
        if (vp[i] == '/') {
            SvREFCNT_dec(out);
            /* Encoding it would be right on the wire and wrong on arrival:
             * PATH_INFO reaches the router percent-DECODED, so the %2F is a
             * '/' again and the path has one segment too many. The hint
             * differs because OpenAPI has no splat to point at. */
            croak("Punk: url_for('%s'): :%s contains '/' and cannot be "
                  "expressed on this route - PATH_INFO arrives "
                  "percent-DECODED, so a %%2F would split into two segments "
                  "and 404.%s", name, cn,
                  kind == PK_CAP_HOLE
                    ? " An OpenAPI path template has no segment that takes"
                      " slashes"
                    : " A *splat is the segment that takes slashes");
        }
    pk_pct_cat(aTHX_ out, vp, vl, splat);
    (void)hv_store_ent(used, capname, PUNK_SET_TRUE, 0);
}

/* Whatever named no hole is the query string - or, with an explicit `query`
 * hash, a mistake. The two conventions do not mix in one call. */
static void pk_url_leftovers(pTHX_ SV *out, HV *args, HV *used, HV *query,
                             const char *name) {
    HV *q;
    HE *he;
    if (query) {
        hv_iterinit(args);
        while ((he = hv_iternext(args))) {
            SV *k = hv_iterkeysv(he);
            if (hv_exists_ent(used, k, 0)) continue;
            SvREFCNT_dec(out);
            croak("Punk: url_for('%s'): '%s' names no capture, and `query` "
                  "was given - with an explicit query hash every other "
                  "argument must be a capture", name, SvPV_nolen(k));
        }
        q = query;
    }
    else {
        q = (HV *)sv_2mortal((SV *)newHV());
        hv_iterinit(args);
        while ((he = hv_iternext(args))) {
            SV *k = hv_iterkeysv(he);
            if (hv_exists_ent(used, k, 0)) continue;
            (void)hv_store_ent(q, k, newSVsv(HeVAL(he)), 0);
        }
    }
    pk_url_query_cat(aTHX_ out, q);
}

static SV *pk_url_build(pTHX_ pr_router *rt, IV idx, HV *args, HV *query,
                        SV *prefix, SV *origin, const char *name) {
    SV *out = newSVpvs("");
    HV *used = (HV *)sv_2mortal((SV *)newHV());
    IV dyn;

    if (origin && SvOK(origin)) sv_catsv(out, origin);
    if (prefix && SvOK(prefix)) sv_catsv(out, prefix);

    if (idx < 0 || idx >= (IV)rt->nrecs) {
        SvREFCNT_dec(out);
        croak("Punk: url_for('%s'): the route table has no record %" IVdf
              " - the application was compiled from a different table",
              name, idx);
    }
    dyn = rt->dyn_of[idx];

    if (dyn < 0) {                       /* static: the path IS the URL */
        SV **rr = av_fetch(rt->records, (SSize_t)idx, 0);
        HV *rec = (rr && *rr && SvROK(*rr)) ? (HV *)SvRV(*rr) : NULL;
        SV **pp = rec ? hv_fetchs(rec, "path", 0) : NULL;
        if (pp && *pp) sv_catsv(out, *pp);
    }
    else {
        pr_rec *r = &rt->recs[dyn];
        int k;
        for (k = 0; k < r->nsegs; k++) {
            pr_seg *s = &r->segs[k];
            sv_catpvn(out, "/", 1);
            if (s->type == PR_LIT) {
                if (s->litlen) sv_catpvn(out, s->lit, s->litlen);
                continue;
            }
            pk_url_cap_cat(aTHX_ out, args, used, s->name,
                           s->type == PR_SPLAT ? PK_CAP_SPLAT : PK_CAP_PARAM,
                           name);
        }
    }

    pk_url_leftovers(aTHX_ out, args, used, query, name);
    return out;
}

/* ---- an OpenAPI operation -----------------------------------------------
 *
 * An operation has an operationId and a path template with {holes}, which is
 * a named route by another spelling - so an application with an `api`
 * keyword is half-named until url_for speaks it.
 *
 * The template does NOT reuse pr_seg. `/files/{name}.json` is legal OpenAPI
 * and the router has no mid-segment holes, so the mount parses its own flat
 * form at to_app: an AV with literals at even indices and hole names at odd
 * ones, always odd length. `/books/{id}` is [ "/books/", "id", "" ].
 *
 * There is no splat in OpenAPI, so the slash rule applies to every hole.
 */
static SV *pk_url_build_op(pTHX_ AV *tmpl, SV *mount_prefix, HV *args,
                           HV *query, SV *prefix, SV *origin,
                           const char *name) {
    SV *out = newSVpvs("");
    HV *used = (HV *)sv_2mortal((SV *)newHV());
    SSize_t i, n = av_len(tmpl) + 1;

    if (origin && SvOK(origin)) sv_catsv(out, origin);
    if (prefix && SvOK(prefix)) sv_catsv(out, prefix);
    if (mount_prefix && SvOK(mount_prefix)) sv_catsv(out, mount_prefix);

    for (i = 0; i < n; i++) {
        SV **e = av_fetch(tmpl, i, 0);
        if (!(e && *e)) continue;
        if (!(i & 1)) {                       /* even: a literal */
            if (SvCUR(*e)) sv_catsv(out, *e);
        }
        else                                  /* odd: a hole */
            pk_url_cap_cat(aTHX_ out, args, used, *e,
                           PK_CAP_HOLE, name);
    }

    pk_url_leftovers(aTHX_ out, args, used, query, name);
    return out;
}


/* ---- the prefix ---------------------------------------------------------
 *
 * A route matches PATH_INFO, and what the browser saw is whatever sat in
 * front of it. Two things can, and they are LAYERS rather than alternatives:
 *
 *   - the path on `host` - a proxy strips /site before Punk sees the
 *     request, so SCRIPT_NAME is empty and only configuration knows. Split
 *     off `host` once at to_app (K_HOST_PATH_C), because $c->origin
 *     deliberately drops it: an origin, to a browser, is scheme://host.
 *   - SCRIPT_NAME - a PSGI mount, which the request carries.
 *
 * A proxy strips /a, a builder mounts at /b, the browser sees /a/b/books/42.
 * Returns a mortal SV, or NULL when there is no prefix at all - which is
 * nearly every deployment, and costs two hv_fetchs that find nothing.
 */
static SV *pk_url_prefix(pTHX_ HV *app, HV *env) {
    SV **hp = app ? hv_fetchs(app, K_HOST_PATH_C, 0) : NULL;
    SV **sn = env ? hv_fetchs(env, "SCRIPT_NAME", 0) : NULL;
    int have_hp = (hp && *hp && SvOK(*hp) && SvCUR(*hp));
    int have_sn = (sn && *sn && SvOK(*sn) && SvCUR(*sn));
    SV *out;
    if (!have_hp && !have_sn) return NULL;
    out = sv_2mortal(newSVpvs(""));
    if (have_hp) sv_catsv(out, *hp);
    if (have_sn) sv_catsv(out, *sn);
    return out;
}

/* What a name resolves to, or NULL: an IV record index for a route, an
 * arrayref [ mount prefix, parsed template ] for an API operation. */
static SV *pk_url_target(pTHX_ HV *app, SV *name) {
    SV **nm = app ? hv_fetchs(app, K_NAMES_C, 0) : NULL;
    HE *he;
    if (!(nm && *nm && SvROK(*nm) && SvTYPE(SvRV(*nm)) == SVt_PVHV)) return NULL;
    he = hv_fetch_ent((HV *)SvRV(*nm), name, 0, 0);
    return he ? HeVAL(he) : NULL;
}

/* The record index a ROUTE name resolves to, or -1 (an API operation has
 * none, and answers -1 too). */
static IV pk_url_idx(pTHX_ HV *app, SV *name) {
    SV *v = pk_url_target(aTHX_ app, name);
    return (v && !SvROK(v)) ? SvIV(v) : -1;
}

/* The compiled router off the application. */
static pr_router *pk_url_router(pTHX_ HV *app) {
    SV **r = app ? hv_fetchs(app, K_ROUTER, 0) : NULL;
    if (!(r && *r && SvROK(*r) && SvIOK(SvRV(*r)))) return NULL;
    return (pr_router *)INT2PTR(void *, SvIV(SvRV(*r)));
}

/* ---- the template filter ------------------------------------------------
 *
 *     <a href="{% book.id | url_for('book') %}">   a scalar fills one capture
 *     <a href="{% book    | url_for('book') %}">   a hashref fills by name
 *
 * A Stencil filter receives the value and one literal argument, so the
 * argument names the route and the value carries the captures. A scalar
 * fills a route with exactly one capture; more than one has no way to say
 * which, and croaks rather than guessing.
 *
 * The shape is pa_asset_filter's, and so is the ownership: a magic CV over
 * the application, held WEAKLY, because the app owns the view registry which
 * owns the engine which owns this filter, and a strong reference would close
 * that loop and keep the whole application alive for ever.
 *
 * Slot 1 is the request's prefix, an SV this closure and the application
 * both hold. asset never needed one - a content-addressed URL is application
 * state - but a route URL under a prefix is not, and a filter cannot see $c.
 * The binder below sets it per render.
 */
#define PKU_CAP_APP    0
#define PKU_CAP_PREFIX 1

XS_INTERNAL(pk_url_filter_cb);
XS_INTERNAL(pk_url_filter_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *appsv, *prefix, *value, *name, *target;
    HV *app, *args;
    pr_router *rt;
    IV idx;
    int is_op;

    if (!cap || items < 2)
        croak("Punk: the url_for filter takes a route name: "
              "{%% value | url_for('name') %%}");
    value  = ST(0);
    name   = ST(1);
    appsv  = *av_fetch(cap, PKU_CAP_APP, 0);
    prefix = *av_fetch(cap, PKU_CAP_PREFIX, 0);

    /* The weak reference can have gone: the engine may outlive the
     * application if something else kept it. Returning the name would put a
     * link to /book on the page, so this croaks like every other way of
     * failing to build a URL. */
    if (!(appsv && SvROK(appsv) && SvTYPE(SvRV(appsv)) == SVt_PVHV))
        croak("Punk: url_for('%s'): the application is gone",
              SvOK(name) ? SvPV_nolen(name) : "?");
    app = (HV *)SvRV(appsv);

    if (!SvOK(name) || !SvCUR(name))
        croak("Punk: the url_for filter takes a route name: "
              "{%% value | url_for('name') %%}");
    target = pk_url_target(aTHX_ app, name);
    if (!target)
        croak("Punk: url_for('%s'): no route is named that", SvPV_nolen(name));
    is_op = (SvROK(target) && SvTYPE(SvRV(target)) == SVt_PVAV);
    idx = is_op ? -1 : SvIV(target);
    rt = pk_url_router(aTHX_ app);
    if (!rt) croak("Punk: url_for('%s'): the application is not compiled",
                   SvPV_nolen(name));

    args = (HV *)sv_2mortal((SV *)newHV());
    if (value && SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVHV) {
        HV *in = (HV *)SvRV(value);          /* a row: captures by name */
        HE *he;
        hv_iterinit(in);
        while ((he = hv_iternext(in)))
            (void)hv_store_ent(args, hv_iterkeysv(he), newSVsv(HeVAL(he)), 0);
    }
    else if (value && SvOK(value)) {         /* a scalar: the one capture */
        SV *only = NULL;
        int n = 0;
        if (is_op) {                         /* the odd slots are the holes */
            AV *tmpl = (AV *)SvRV(*av_fetch((AV *)SvRV(target), 1, 0));
            SSize_t j, jn = av_len(tmpl) + 1;
            for (j = 1; j < jn; j += 2) { only = *av_fetch(tmpl, j, 0); n++; }
        }
        else if (idx >= 0 && idx < (IV)rt->nrecs && rt->dyn_of[idx] >= 0) {
            pr_rec *r = &rt->recs[rt->dyn_of[idx]];
            int k;
            for (k = 0; k < r->nsegs; k++)
                if (r->segs[k].type != PR_LIT) { only = r->segs[k].name; n++; }
        }
        if (n != 1)
            croak("Punk: url_for('%s'): the value is a scalar and this route "
                  "has %d captures - pass a hashref so each one is named",
                  SvPV_nolen(name), n);
        (void)hv_store_ent(args, only, newSVsv(value), 0);
    }

    if (is_op) {
        AV *pair = (AV *)SvRV(target);
        SV **mp = av_fetch(pair, 0, 0);
        SV **tm = av_fetch(pair, 1, 0);
        ST(0) = sv_2mortal(pk_url_build_op(aTHX_ (AV *)SvRV(*tm),
                    (mp && *mp) ? *mp : NULL, args, NULL,
                    (prefix && SvCUR(prefix)) ? prefix : NULL,
                    NULL, SvPV_nolen(name)));
    }
    else
        ST(0) = sv_2mortal(pk_url_build(aTHX_ rt, idx, args, NULL,
                                    (prefix && SvCUR(prefix)) ? prefix : NULL,
                                    NULL, SvPV_nolen(name)));
    XSRETURN(1);
}

static SV *pk_url_filter(pTHX_ SV *app, SV *prefix_slot) {
    AV *cap = newAV();
    SV *weak = newSVsv(app);
    sv_rvweaken(weak);
    av_store(cap, PKU_CAP_APP,    weak);
    av_store(cap, PKU_CAP_PREFIX, SvREFCNT_inc_simple_NN(prefix_slot));
    return punk_closure(aTHX_ pk_url_filter_cb, cap);
}

/* ---- the `url` hash -----------------------------------------------------
 *
 *     <a href="{% url.books %}">
 *
 * Static routes by name, so the commonest link on a page costs a hash lookup
 * inside the engine rather than the filter's call boundary. Dynamic routes
 * are not in it: they need captures, which is what the filter is for.
 *
 * TIED, for the reason punk_i18n.h gives about its catalogue, sharpened:
 * Stencil resolves a missing path to the empty string, so a plain hash would
 * render `{% url.typo %}` as `href=""` - a link to the current page that
 * looks like it works. A name that does not exist is the template-side
 * spelling of a capture with no value, and that already croaks. Needs
 * Template::Stencil 0.10, where tied hashes started resolving in a path.
 */
#define PKU_T_APP    0
#define PKU_T_PREFIX 1

static SV *pk_url_tied(pTHX_ SV *app, SV *prefix_slot) {
    AV *o = newAV();
    HV *h = newHV();
    SV *obj;
    av_extend(o, 2);
    av_store(o, PKU_T_APP,    newSVsv(app));
    av_store(o, PKU_T_PREFIX, prefix_slot ? newSVsv(prefix_slot) : newSV(0));
    obj = sv_bless(newRV_noinc((SV *)o), gv_stashpv("Punk::URL", GV_ADD));
    hv_magic(h, (GV *)obj, PERL_MAGIC_tied);
    SvREFCNT_dec(obj);                  /* hv_magic took its own reference */
    return newRV_noinc((SV *)h);
}

/* Is this name a static route - one the `url` hash can answer for? */
static int pk_url_static_path(pTHX_ HV *app, SV *name, SV **path_out) {
    pr_router *rt = pk_url_router(aTHX_ app);
    IV idx = pk_url_idx(aTHX_ app, name);
    SV **rr;
    HV *rec;
    if (!rt || idx < 0 || idx >= (IV)rt->nrecs) return 0;
    if (rt->dyn_of[idx] >= 0) return 0;              /* dynamic: not here */
    rr = av_fetch(rt->records, (SSize_t)idx, 0);
    rec = (rr && *rr && SvROK(*rr)) ? (HV *)SvRV(*rr) : NULL;
    if (!rec) return 0;
    if (path_out) {
        SV **pp = hv_fetchs(rec, "path", 0);
        *path_out = (pp && *pp) ? *pp : NULL;
    }
    return 1;
}

/* Parse an OpenAPI path template into the flat form pk_url_build_op walks:
 * literals at even indices, hole names at odd ones, always odd length.
 *
 *   /books/{id}          -> [ "/books/", "id", "" ]
 *   /files/{name}.json   -> [ "/files/", "name", ".json" ]
 *   /a/{x}/b/{y}         -> [ "/a/", "x", "/b/", "y", "" ]
 *
 * An unclosed '{' is left as a literal rather than croaking: the spec is the
 * application's, it has already been through Open::API, and a URL builder is
 * not the place to start rejecting documents that route perfectly well.
 */
static AV *pk_url_parse_template(pTHX_ const char *p, STRLEN pl) {
    AV *out = newAV();
    STRLEN i = 0, lit = 0;
    while (i < pl) {
        if (p[i] == '{') {
            STRLEN close = i + 1;
            while (close < pl && p[close] != '}') close++;
            if (close < pl) {
                av_push(out, newSVpvn(p + lit, i - lit));        /* literal */
                av_push(out, newSVpvn(p + i + 1, close - i - 1)); /* hole */
                i = close + 1;
                lit = i;
                continue;
            }
        }
        i++;
    }
    av_push(out, newSVpvn(p + lit, pl - lit));   /* the trailing literal */
    return out;
}

/* Put this request's `url` hash and prefix where a template can reach them.
 *
 * SET, not set-if-absent: the reason pi_bind_vars gives about a handler that
 * keeps a data hashref between requests.
 *
 * The prefix slot is shared with the filter closure, and getting it back to
 * empty afterwards matters as much as setting it: a mail template rendered
 * from a queue job has no request, and must not link under the prefix of
 * whatever page this worker served last. It cannot be cleared from here -
 * without a context there is no application to find the slot through - so it
 * is `save_item`d instead, and the caller's ENTER/LEAVE puts it back. That
 * also covers the two cases an explicit reset would not: a render that
 * croaks part way, and a render nested inside another.
 *
 * The tied hash takes a COPY of the prefix, so restoring the slot afterwards
 * does not reach back into a `url` hash the handler still holds.
 *
 * Must be called inside an ENTER scope.
 */
static void pk_url_bind_vars(pTHX_ SV *c, SV *data) {
    SV *appsv = NULL, *slot;
    HV *app = NULL, *env = NULL;
    AV *av;
    SV **sp;

    if (!(data && SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV)) return;

    if (c && SvROK(c)) {
        av = pcx_av(aTHX_ c);
        if (av) {
            SV *a = pcx_get(aTHX_ av, PCX_APP);
            SV *e = pcx_get(aTHX_ av, PCX_ENV);
            if (a && SvROK(a) && SvTYPE(SvRV(a)) == SVt_PVHV) {
                appsv = a;
                app = (HV *)SvRV(a);
            }
            if (e && SvROK(e) && SvTYPE(SvRV(e)) == SVt_PVHV)
                env = (HV *)SvRV(e);
        }
    }
    if (!app) return;                       /* nothing named, nothing to bind */
    sp = hv_fetchs(app, K_URL_PREFIX_C, 0);
    if (!(sp && *sp)) return;               /* no shipped engine at boot */
    slot = *sp;

    {   /* the filter reads this slot for the length of the render, and the
         * savestack puts it back at LEAVE */
        SV *pfx = pk_url_prefix(aTHX_ app, env);
        save_item(slot);
        if (pfx) sv_setsv(slot, pfx);
        else     sv_setpvs(slot, "");
    }
    (void)hv_stores((HV *)SvRV(data), "url", pk_url_tied(aTHX_ appsv, slot));
}

#endif /* PUNK_URL_H */

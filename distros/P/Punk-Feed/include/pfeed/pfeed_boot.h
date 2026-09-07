#ifndef PFEED_BOOT_H
#define PFEED_BOOT_H

/* Boot: the options, the `feed` keyword, the origin, and the build at to_app.
 *
 * State lives as keys on the application's own hash rather than in a struct,
 * which is what punk_sitemap.h does and for the same reason - the application
 * is already the thing whose lifetime this state shares, and a struct would be
 * a second one to keep in step with it.
 *
 *   feed_opts       the validated option hash
 *   feed_base       the absolute origin, no trailing slash
 *   feed_list       AV of [name, code, overrides] in declaration order
 *   feed_entries    HV of name -> AV of records
 *   feed_built_at   the TTL anchor
 *
 * Must be included after pfeed_reg.h and pfeed_entry.h.
 */

static const char *const PFEED_OPTS[] = {
    "title", "author", "base", "path", "format", "ttl", "limit",
    "description", "subtitle", "link", "id", "language", "copyright", NULL
};

/* What a single feed may restate for itself. `base`, `ttl` and `format` are
 * not here: they are properties of the plugin, not of a feed, and a feed that
 * disagreed about the origin would be a feed pointing somewhere else. */
static const char *const PFEED_FEED_OPTS[] = {
    "entries", "title", "description", "subtitle", "author", "link", "id",
    "limit", NULL
};

/* ---- options -------------------------------------------------------------- */

static SV *pfeed_opt_str(pTHX_ HV *opts, const char *k, const char *alt,
                         const char *dflt)
{
    SV *v = pfeed_hget(aTHX_ opts, k);
    if (!v && alt) v = pfeed_hget(aTHX_ opts, alt);
    if (v && SvOK(v)) return newSVsv(v);
    return dflt ? newSVpv(dflt, 0) : NULL;
}

/* Validate and normalise, at the `plugin` line.
 *
 * `title` croaks here and not at to_app because nothing declared later can
 * supply it - unlike the origin, which `host` may state on either side of this
 * call.
 */
static HV *pfeed_opts(pTHX_ SV *app, SV *optsv)
{
    HV *in = pfeed_is_hash(optsv) ? (HV *)SvRV(optsv) : NULL;
    HV *out = newHV();
    SV *v;

    pfeed_check_opts(aTHX_ "option", in, PFEED_OPTS);

    v = in ? pfeed_hget(aTHX_ in, "title") : NULL;
    if (!(v && SvOK(v) && SvCUR(v)))
        croak("%s: `title` is required - both formats demand one, and a feed "
              "without it reads as a blank row", PFEED_WHO);
    (void)hv_stores(out, "title", newSVsv(v));

    {   /* format */
        SV *f = in ? pfeed_hget(aTHX_ in, "format") : NULL;
        const char *fp = "both";
        STRLEN fl = 4;
        if (f && SvOK(f)) fp = SvPV_const(f, fl);
        if (!((fl == 4 && memEQ(fp, "both", 4))
              || (fl == 4 && memEQ(fp, "atom", 4))
              || (fl == 3 && memEQ(fp, "rss", 3))))
            croak("%s: `format` must be 'atom', 'rss' or 'both', not '%.*s'",
                  PFEED_WHO, (int)fl, fp);
        (void)hv_stores(out, "format", newSVpvn(fp, fl));
    }

    {   /* path: the stem the routes hang off, so it is a path like any other */
        SV *p = in ? pfeed_hget(aTHX_ in, "path") : NULL;
        SV *keep;
        STRLEN pl;
        const char *pp;
        keep = (p && SvOK(p) && SvCUR(p)) ? newSVsv(p) : newSVpvs("/feed");
        pp = SvPV_const(keep, pl);
        /* a trailing slash would make the routes /feed/.xml */
        while (pl > 1 && pp[pl - 1] == '/') { SvCUR_set(keep, --pl); }
        pp = SvPV_const(keep, pl);
        if (!pfeed_loc_ok(pp, pl)) {
            SV *bad = sv_2mortal(keep);
            croak("%s: `path` must be a rooted, concrete path, not '%" SVf "'",
                  PFEED_WHO, SVfARG(bad));
        }
        (void)hv_stores(out, "path", keep);
    }

    {   /* ttl */
        SV *t = in ? pfeed_hget(aTHX_ in, "ttl") : NULL;
        NV ttl = (t && SvOK(t)) ? SvNV(t) : 3600.0;
        if (!(ttl >= 0.0))
            croak("%s: `ttl` must not be negative", PFEED_WHO);
        (void)hv_stores(out, "ttl", newSVnv(ttl));
    }

    {   /* limit */
        SV *l = in ? pfeed_hget(aTHX_ in, "limit") : NULL;
        IV lim = (l && SvOK(l)) ? SvIV(l) : 50;
        if (lim < 1)
            croak("%s: `limit` must be at least 1", PFEED_WHO);
        if (lim > PFEED_MAX_ENTRIES)
            croak("%s: `limit` may not exceed %d", PFEED_WHO,
                  (int)PFEED_MAX_ENTRIES);
        (void)hv_stores(out, "limit", newSViv(lim));
    }

    { SV *s = in ? pfeed_opt_str(aTHX_ in, "author", NULL, NULL) : NULL;
      if (s) (void)hv_stores(out, "author", s); }
    /* Atom calls it subtitle and RSS calls it description; they are the same
     * sentence, so either spelling is accepted and `description` wins. */
    { SV *s = in ? pfeed_opt_str(aTHX_ in, "description", "subtitle", NULL) : NULL;
      if (s) (void)hv_stores(out, "description", s); }
    { SV *s = in ? pfeed_opt_str(aTHX_ in, "link", NULL, "/") : newSVpvs("/");
      (void)hv_stores(out, "link", s); }
    { SV *s = in ? pfeed_opt_str(aTHX_ in, "id", NULL, NULL) : NULL;
      if (s) (void)hv_stores(out, "id", s); }
    { SV *s = in ? pfeed_opt_str(aTHX_ in, "language", NULL, NULL) : NULL;
      if (s) (void)hv_stores(out, "language", s); }
    { SV *s = in ? pfeed_opt_str(aTHX_ in, "copyright", NULL, NULL) : NULL;
      if (s) (void)hv_stores(out, "copyright", s); }
    { SV *s = in ? pfeed_opt_str(aTHX_ in, "base", NULL, NULL) : NULL;
      if (s) (void)hv_stores(out, "base", s); }

    PERL_UNUSED_ARG(app);
    return out;
}

/* ---- the origin ----------------------------------------------------------- */

/* `base` explicit, else the application's declared `host`, else a croak.
 *
 * The request is never consulted. The obvious place to get a scheme and host
 * is the request that asked for the feed, and that is a host-header injection
 * with a long tail: a request carrying `Host: evil.example` produces a feed
 * naming that host for every item, the owner's own request produces a correct
 * one so nothing looks wrong, and every reader that fetched the poisoned copy
 * keeps it for as long as somebody stays subscribed.
 *
 * At to_app rather than at the `plugin` line, so `host` may be declared on
 * either side of it.
 */
static void pfeed_resolve_base(pTHX_ SV *app)
{
    HV *h = pfeed_app_hv(aTHX_ app);
    HV *opts;
    SV *base;
    STRLEN bl;
    const char *bp;
    SV *o;

    if (!h) return;
    o = pfeed_hget(aTHX_ h, "feed_opts");
    opts = pfeed_is_hash(o) ? (HV *)SvRV(o) : NULL;

    base = opts ? pfeed_hget(aTHX_ opts, "base") : NULL;
    if (base && SvOK(base) && SvCUR(base)) base = newSVsv(base);
    else {
        SV *host = pfeed_can(aTHX_ app, "host")
                 ? sv_2mortal(pfeed_call(aTHX_ app, "host", NULL, 0)) : NULL;
        if (!(host && SvOK(host) && SvCUR(host)))
            croak("%s: no origin to build URLs on. Declare `host` on the "
                  "application, or pass `base` to the plugin - a feed's URLs "
                  "are absolute and the request's Host is not a safe source "
                  "for them", PFEED_WHO);
        base = newSVsv(host);
    }

    bp = SvPV_const(base, bl);
    /* a trailing slash would double against a loc that starts with one */
    while (bl > 0 && bp[bl - 1] == '/') { SvCUR_set(base, --bl); }
    bp = SvPV_const(base, bl);
    if (!(bl > 8 && (memEQ(bp, "http://", 7) || memEQ(bp, "https://", 8)))) {
        SV *bad = sv_2mortal(base);
        croak("%s: the origin must be an absolute http or https URL, not "
              "'%" SVf "'", PFEED_WHO, SVfARG(bad));
    }
    (void)hv_stores(h, "feed_base", base);
}

/* ---- the build ------------------------------------------------------------ */

static NV pfeed_now(pTHX)
{
    PERL_UNUSED_CONTEXT;
    return (NV)time(NULL);
}

/* One feed's limit: its own override, else the plugin's. */
static IV pfeed_limit_for(pTHX_ HV *opts, SV *over)
{
    SV *v = NULL;
    if (pfeed_is_hash(over)) v = pfeed_hget(aTHX_ (HV *)SvRV(over), "limit");
    if (!v) v = pfeed_hget(aTHX_ opts, "limit");
    return (v && SvOK(v)) ? SvIV(v) : 50;
}

/* Does this plugin serve `fmt` at all? */
static int pfeed_wants(pTHX_ HV *opts, const char *fmt)
{
    SV *f = pfeed_hget(aTHX_ opts, "format");
    STRLEN l;
    const char *p;
    if (!f) return 1;
    p = SvPV_const(f, l);
    if (l == 4 && memEQ(p, "both", 4)) return 1;
    return strlen(fmt) == l && memEQ(p, fmt, l);
}

/* The key a rendered document is stored under: "name\0atom". One lookup, and
 * the NUL keeps a feed called "news\0rss" from being a thing. */
static SV *pfeed_doc_key(pTHX_ SV *name, const char *fmt)
{
    STRLEN nl;
    const char *np = pfeed_u8(aTHX_ name, &nl);
    /* Normalised to UTF-8 bytes, because the declared name and the name parsed
     * out of a route capture reach here as different SV shapes. A flagged
     * declaration and a byte capture would hash differently and a feed that
     * exists would 404. */
    SV *k = sv_2mortal(newSVpvn(np, nl));
    sv_catpvn(k, "\0", 1);
    sv_catpv(k, fmt);
    return k;
}

/* Render one feed into the document and etag stores. */
static void pfeed_render_into(pTHX_ HV *docs, HV *etags, HV *opts, SV *over,
                              SV *name, AV *recs, SV *base, IV built_at)
{
    if (pfeed_wants(aTHX_ opts, "atom")) {
        SV *doc = pfeed_render_atom(aTHX_ opts, over, name, recs, base, built_at);
        SV *key = pfeed_doc_key(aTHX_ name, "atom");
        (void)hv_store_ent(docs, key, doc, 0);
        (void)hv_store_ent(etags, key, pfeed_etag(aTHX_ doc), 0);
    }
    if (pfeed_wants(aTHX_ opts, "rss")) {
        SV *doc = pfeed_render_rss(aTHX_ opts, over, name, recs, base, built_at);
        SV *key = pfeed_doc_key(aTHX_ name, "rss");
        (void)hv_store_ent(docs, key, doc, 0);
        (void)hv_store_ent(etags, key, pfeed_etag(aTHX_ doc), 0);
    }
}

/* Run every section, render what they returned, and stash all of it.
 *
 * Once at to_app, and again when the TTL has passed (phase 5). A request for a
 * feed is then a write of bytes that already exist.
 *
 * The records are kept as well as the documents: an application with a host
 * allowlist renders a document naming the asking tenant from them, so the
 * sections run once per TTL however many hosts ask.
 */
static void pfeed_build(pTHX_ SV *app)
{
    HV *h = pfeed_app_hv(aTHX_ app);
    SV *o, *b;
    HV *opts, *store, *docs, *etags, *stamps, *prev = NULL;
    AV *list;
    SSize_t i, n;
    IV built_at;
    SV *pv;

    if (!h) return;
    o = pfeed_hget(aTHX_ h, "feed_opts");
    if (!pfeed_is_hash(o)) return;
    opts = (HV *)SvRV(o);
    b = pfeed_hget(aTHX_ h, "feed_base");
    built_at = (IV)pfeed_now(aTHX);

    /* what the last good build collected, for a section that dies on a rebuild */
    pv = pfeed_hget(aTHX_ h, "feed_entries");
    if (pfeed_is_hash(pv)) prev = (HV *)SvRV(pv);

    list   = pfeed_app_av(aTHX_ h, "feed_list");
    store  = newHV();
    docs   = newHV();
    etags  = newHV();
    stamps = newHV();

    n = av_len(list) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(list, i, 0);
        AV *ent;
        SV *name, *code, *over;
        AV *recs;
        int died = 0;
        if (!(e && *e && pfeed_is_array(*e))) continue;
        ent  = (AV *)SvRV(*e);
        name = *av_fetch(ent, 0, 0);
        code = *av_fetch(ent, 1, 0);
        over = *av_fetch(ent, 2, 0);
        recs = pfeed_section(aTHX_ name, code, b,
                             pfeed_limit_for(aTHX_ opts, over), &died);

        /* A section that died on a REBUILD keeps what the last good build
         * collected. Replacing it with nothing would publish an empty feed,
         * and a reader handed one concludes every item was deleted and says so
         * to the person subscribed - the same reason an unknown feed is a 404
         * rather than an empty document.
         *
         * A database that is away for a minute must not look like a site that
         * deleted its archive. The first build has nothing to fall back on, so
         * there the feed really is empty. */
        if (died && prev) {
            HE *he = hv_fetch_ent(prev, name, 0, 0);
            SV *old = he ? HeVAL(he) : NULL;
            if (pfeed_is_array(old) && av_len((AV *)SvRV(old)) >= 0) {
                warn("%s: feed '%" SVf "' keeps the entries from its last "
                     "good build", PFEED_WHO, SVfARG(name));
                SvREFCNT_dec((SV *)recs);
                recs = (AV *)SvRV(old);
                SvREFCNT_inc((SV *)recs);
            }
        }

        (void)hv_store_ent(store, name, newRV_noinc((SV *)recs), 0);
        (void)hv_store_ent(stamps, name,
                           newSViv(pfeed_newest(aTHX_ recs, built_at)), 0);
        pfeed_render_into(aTHX_ docs, etags, opts, over, name, recs, b,
                          built_at);
    }

    (void)hv_stores(h, "feed_entries", newRV_noinc((SV *)store));
    (void)hv_stores(h, "feed_docs",    newRV_noinc((SV *)docs));
    (void)hv_stores(h, "feed_etags",   newRV_noinc((SV *)etags));
    (void)hv_stores(h, "feed_stamp",   newRV_noinc((SV *)stamps));
    (void)hv_stores(h, "feed_built_at", newSVnv((NV)built_at));
}

/* Does this feed's document need rebuilding before it is served?
 *
 * A section reads a database, so its answer changes underneath us. Running it
 * per request would be a query nobody is watching, on a schedule somebody else
 * chooses; running it once at boot would produce a feed correct on the day of
 * the deploy and progressively wrong afterwards. So it is rebuilt when the TTL
 * has passed, and THE DOCUMENT IS STALE BY UP TO THAT LONG - which is worth
 * saying rather than engineering away.
 *
 * There is no stampede to guard against inside a worker. Hyperman is
 * single-threaded and a worker serves its requests one after another, so the
 * second of two simultaneous requests finds what the first built. The cost
 * across a pool is one rebuild per worker per TTL.
 */
static void pfeed_ensure(pTHX_ SV *app)
{
    HV *h = pfeed_app_hv(aTHX_ app);
    SV *o, *at, *ttl;
    HV *opts;

    if (!h) return;
    /* nothing declared: no clock read, no rebuild, ever */
    {
        SV *l = pfeed_hget(aTHX_ h, "feed_list");
        if (!(pfeed_is_array(l) && av_len((AV *)SvRV(l)) >= 0)) return;
    }
    o = pfeed_hget(aTHX_ h, "feed_opts");
    if (!pfeed_is_hash(o)) return;
    opts = (HV *)SvRV(o);

    at  = pfeed_hget(aTHX_ h, "feed_built_at");
    ttl = pfeed_hget(aTHX_ opts, "ttl");
    if (at && ttl && pfeed_now(aTHX) - SvNV(at) < SvNV(ttl)) return;
    pfeed_build(aTHX_ app);
}

/* ---- serving -------------------------------------------------------------- */

/* One feed's declared overrides, or NULL. */
static SV *pfeed_over_for(pTHX_ HV *h, SV *name)
{
    SV *l = pfeed_hget(aTHX_ h, "feed_list");
    AV *list;
    SSize_t i, n;
    if (!pfeed_is_array(l)) return NULL;
    list = (AV *)SvRV(l);
    n = av_len(list) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(list, i, 0);
        AV *rec;
        if (!(e && *e && pfeed_is_array(*e))) continue;
        rec = (AV *)SvRV(*e);
        if (sv_eq(*av_fetch(rec, 0, 0), name)) {
            SV **o = av_fetch(rec, 2, 0);
            return (o && *o && SvOK(*o)) ? *o : NULL;
        }
    }
    return NULL;
}

/* Render this feed against an origin that is not the canonical one.
 *
 * From the cached records, so the sections still run once per TTL however many
 * tenant hosts ask. NOT cached: a wildcard allow makes the set of hosts
 * unbounded, and a cache keyed by hostnames a client chooses is a memory leak
 * with a name. Mortal.
 */
static SV *pfeed_doc_for(pTHX_ HV *h, SV *name, const char *fmt, SV *origin)
{
    SV *o = pfeed_hget(aTHX_ h, "feed_opts");
    SV *st = pfeed_hget(aTHX_ h, "feed_entries");
    HV *opts;
    AV *recs = NULL;
    IV built_at = 0;
    SV *at;

    if (!pfeed_is_hash(o)) return NULL;
    opts = (HV *)SvRV(o);
    if (pfeed_is_hash(st)) {
        HE *he = hv_fetch_ent((HV *)SvRV(st), name, 0, 0);
        SV *v = he ? HeVAL(he) : NULL;
        if (pfeed_is_array(v)) recs = (AV *)SvRV(v);
    }
    if (!recs) return NULL;
    at = pfeed_hget(aTHX_ h, "feed_built_at");
    if (at) built_at = (IV)SvNV(at);

    return sv_2mortal(strEQ(fmt, "rss")
        ? pfeed_render_rss(aTHX_ opts, pfeed_over_for(aTHX_ h, name), name,
                           recs, origin, built_at)
        : pfeed_render_atom(aTHX_ opts, pfeed_over_for(aTHX_ h, name), name,
                            recs, origin, built_at));
}

static void pfeed_hdr(pTHX_ AV *headers, const char *k, SV *v)
{
    av_push(headers, newSVpv(k, 0));
    av_push(headers, v);
}

/* Serve one feed. cap = [app, name-or-undef, fmt-or-undef].
 *
 * A capture-free route knows its own name and format. The /feed/:name route
 * carries neither and reads both off the capture.
 */
XS_INTERNAL(pfeed_serve_cb);
XS_INTERNAL(pfeed_serve_cb)
{
    dXSARGS;
    SV *app  = pfeed_cap_slot(aTHX_ cv, 0);
    SV *cname = pfeed_cap_slot(aTHX_ cv, 1);
    SV *cfmt  = pfeed_cap_slot(aTHX_ cv, 2);
    SV *c = items > 0 ? ST(0) : NULL;
    HV *h = app ? pfeed_app_hv(aTHX_ app) : NULL;
    SV *name = NULL, *doc = NULL, *etag = NULL, *base;
    const char *fmt = "atom";
    IV stamp = 0;
    AV *resp, *headers, *body;
    int not_modified = 0;

    if (!h) XSRETURN_EMPTY;
    /* a section may have gone stale since the last hit */
    pfeed_ensure(aTHX_ app);

    if (cname && SvOK(cname)) {
        name = cname;
        if (cfmt && SvOK(cfmt)) fmt = SvPV_nolen(cfmt);
    }
    else if (c) {
        /* Punk captures whole SEGMENTS, so the pattern is /feed/:name and the
         * capture arrives as "news.xml" rather than "news". Split at the LAST
         * dot and check the extension, rather than matching loosely - a loose
         * parse serves a document for a URL nobody published. */
        SV *arg = sv_2mortal(newSVpvs("name"));
        SV *v = sv_2mortal(pfeed_call(aTHX_ c, "param", &arg, 1));
        if (v && SvOK(v)) {
            STRLEN vl;
            const char *vp = SvPV_const(v, vl);
            const char *dot = NULL;
            STRLEN i;
            for (i = 0; i < vl; i++) if (vp[i] == '.') dot = vp + i;
            if (dot) {
                STRLEN el = vl - (STRLEN)(dot + 1 - vp);
                if (el == 3 && memEQ(dot + 1, "xml", 3))      fmt = "atom";
                else if (el == 3 && memEQ(dot + 1, "rss", 3)) fmt = "rss";
                else dot = NULL;
                if (dot) name = sv_2mortal(newSVpvn(vp, (STRLEN)(dot - vp)));
            }
        }
    }

    if (name) {
        SV *st = pfeed_hget(aTHX_ h, "feed_docs");
        SV *key = pfeed_doc_key(aTHX_ name, fmt);
        HE *he = pfeed_is_hash(st)
               ? hv_fetch_ent((HV *)SvRV(st), key, 0, 0) : NULL;
        doc = he ? HeVAL(he) : NULL;
        if (doc) {
            SV *es = pfeed_hget(aTHX_ h, "feed_etags");
            HE *eh = pfeed_is_hash(es)
                   ? hv_fetch_ent((HV *)SvRV(es), key, 0, 0) : NULL;
            etag = eh ? HeVAL(eh) : NULL;
        }
        {
            SV *ss = pfeed_hget(aTHX_ h, "feed_stamp");
            HE *sh = pfeed_is_hash(ss)
                   ? hv_fetch_ent((HV *)SvRV(ss), name, 0, 0) : NULL;
            if (sh) stamp = SvIV(HeVAL(sh));
        }
    }

    /* A feed nobody declared is a 404, not an empty document: a reader
     * following a link to a feed that was renamed must be told it is gone.
     * Handed an empty but valid feed it concludes every item was deleted, and
     * says so to the person subscribed. */
    if (!(doc && SvOK(doc))) {
        SV *r = c ? pfeed_call(aTHX_ c, "not_found", NULL, 0) : NULL;
        if (r) { ST(0) = sv_2mortal(r); XSRETURN(1); }
        XSRETURN_EMPTY;
    }

    base = pfeed_hget(aTHX_ h, "feed_base");

    /* A tenant host on the allowlist gets a document naming itself. $c->origin
     * returns the request's scheme and host ONLY when the host is the
     * canonical one or matches an allow entry, and the canonical origin
     * otherwise - so an unknown Host lands on the frozen document and the raw
     * header never reaches a subscriber. */
    if (c && pfeed_can(aTHX_ c, "origin")) {
        SV *origin = sv_2mortal(pfeed_call(aTHX_ c, "origin", NULL, 0));
        if (origin && SvOK(origin) && SvCUR(origin)
            && !(base && sv_eq(origin, base))) {
            SV *alt = pfeed_doc_for(aTHX_ h, name, fmt, origin);
            if (alt) {
                doc  = alt;
                /* its own tag: handing a tenant the canonical one would say a
                 * document it has never seen is unchanged */
                etag = sv_2mortal(pfeed_etag(aTHX_ doc));
            }
        }
    }

    /* ---- conditional GET -------------------------------------------------
     *
     * A reader is a fetcher on a schedule: it asks for this URL every few
     * minutes for years, and between rebuilds the answer is bytes that already
     * exist. If-None-Match is checked first and wins outright when present,
     * per RFC 9110; the date is honoured too because some readers only ever
     * send that. */
    if (c) {
        SV *inm = pfeed_env(aTHX_ c, "HTTP_IF_NONE_MATCH");
        if (inm && etag) {
            STRLEN il, el;
            const char *ip = SvPV_const(inm, il);
            const char *ep = SvPV_const(etag, el);
            /* a weak validator matches a strong one for this purpose */
            if (il > 2 && ip[0] == 'W' && ip[1] == '/') { ip += 2; il -= 2; }
            if ((il == 1 && ip[0] == '*')
                || (il == el && memEQ(ip, ep, el))) not_modified = 1;
        }
        else if (!inm) {
            SV *ims = pfeed_env(aTHX_ c, "HTTP_IF_MODIFIED_SINCE");
            IV since;
            if (ims && pfeed_parse_http_date(aTHX_ ims, &since) && stamp <= since)
                not_modified = 1;
        }
    }

    resp = newAV(); headers = newAV(); body = newAV();

    if (etag) pfeed_hdr(aTHX_ headers, "ETag", newSVsv(etag));
    {
        SV *lm = newSVpvs("");
        pfeed_http_date(aTHX_ lm, stamp);
        pfeed_hdr(aTHX_ headers, "Last-Modified", lm);
    }
    {   /* telling a client to come back sooner than the document can change is
         * asking for a request that can only produce a 304 */
        SV *o = pfeed_hget(aTHX_ h, "feed_opts");
        SV *ttl = pfeed_is_hash(o)
                ? pfeed_hget(aTHX_ (HV *)SvRV(o), "ttl") : NULL;
        SV *cc = newSVpvs("max-age=");
        sv_catpvf(cc, "%" IVdf, ttl ? (IV)SvNV(ttl) : (IV)3600);
        pfeed_hdr(aTHX_ headers, "Cache-Control", cc);
    }

    if (not_modified) {
        av_push(resp, newSViv(304));
    }
    else {
        pfeed_hdr(aTHX_ headers, "Content-Type",
                  newSVpv(strEQ(fmt, "rss")
                          ? "application/rss+xml; charset=utf-8"
                          : "application/atom+xml; charset=utf-8", 0));
        pfeed_hdr(aTHX_ headers, "Content-Length", newSViv((IV)SvCUR(doc)));
        av_push(body, newSVsv(doc));
        av_push(resp, newSViv(200));
    }
    av_push(resp, newRV_noinc((SV *)headers));
    av_push(resp, newRV_noinc((SV *)body));
    ST(0) = sv_2mortal(newRV_noinc((SV *)resp));
    XSRETURN(1);
}

/* $c->feed_links - the autodiscovery tags for a layout. cap = [app].
 *
 * It exists because autodiscovery is the only way a browser or a reader finds
 * the feed from the page, and hand-writing those four attributes in a layout
 * is where the URL goes stale the first time `path` changes.
 */
XS_INTERNAL(pfeed_links_cb);
XS_INTERNAL(pfeed_links_cb)
{
    dXSARGS;
    SV *app = pfeed_cap_slot(aTHX_ cv, 0);
    SV *c = items > 0 ? ST(0) : NULL;
    HV *h = app ? pfeed_app_hv(aTHX_ app) : NULL;
    SV *out = sv_2mortal(newSVpvs(""));
    SV *o, *base;
    HV *opts;
    AV *list;
    SSize_t i, n;

    if (!h) { ST(0) = out; XSRETURN(1); }
    o = pfeed_hget(aTHX_ h, "feed_opts");
    if (!pfeed_is_hash(o)) { ST(0) = out; XSRETURN(1); }
    opts = (HV *)SvRV(o);

    base = pfeed_hget(aTHX_ h, "feed_base");
    if (c && pfeed_can(aTHX_ c, "origin")) {
        SV *origin = sv_2mortal(pfeed_call(aTHX_ c, "origin", NULL, 0));
        if (origin && SvOK(origin) && SvCUR(origin)) base = origin;
    }

    {
        SV *l = pfeed_hget(aTHX_ h, "feed_list");
        list = pfeed_is_array(l) ? (AV *)SvRV(l) : NULL;
    }
    n = list ? av_len(list) + 1 : 0;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(list, i, 0);
        AV *rec;
        SV *name, *over, *title;
        int k;
        if (!(e && *e && pfeed_is_array(*e))) continue;
        rec  = (AV *)SvRV(*e);
        name = *av_fetch(rec, 0, 0);
        over = *av_fetch(rec, 2, 0);
        title = pfeed_opt_of(aTHX_ opts, over, "title");

        for (k = 0; k < 2; k++) {
            const char *fmt  = k ? "rss" : "atom";
            const char *ext  = k ? "rss" : "xml";
            const char *type = k ? "application/rss+xml" : "application/atom+xml";
            if (!pfeed_wants(aTHX_ opts, fmt)) continue;
            if (SvCUR(out)) sv_catpvs(out, "\n");
            sv_catpvs(out, "<link rel=\"alternate\" type=\"");
            sv_catpv(out, type);
            sv_catpvs(out, "\" title=\"");
            pfeed_xml_sv(aTHX_ out, title);
            sv_catpvs(out, "\" href=\"");
            pfeed_url_sv(aTHX_ out, base,
                         pfeed_self_path(aTHX_ opts, name, ext));
            sv_catpvs(out, "\">");
        }
    }
    ST(0) = out;
    XSRETURN(1);
}

/* ---- the callbacks -------------------------------------------------------- */

/* The `feed` keyword. cap = [app].
 *
 *     feed sub { ... };                    the default feed, named ''
 *     feed news => sub { ... };
 *     feed news => { entries => sub {...}, title => '...' };
 *
 * NAMED, so a second declaration of the same name REPLACES rather than
 * appends: a base class can declare a feed and a subclass override it, and an
 * application reloading its own definition does not end up serving it twice.
 * Declaration order is the route order, and a replaced feed keeps its original
 * position so the set does not reshuffle.
 */
XS_INTERNAL(pfeed_kw_cb);
XS_INTERNAL(pfeed_kw_cb)
{
    dXSARGS;
    SV *app = pfeed_cap_slot(aTHX_ cv, 0);
    HV *h = app ? pfeed_app_hv(aTHX_ app) : NULL;
    SV *name = NULL, *code = NULL, *over = NULL;
    AV *list;
    SSize_t i, n;

    if (!h) XSRETURN_EMPTY;

    if (items == 1) {
        /* One argument is the default feed's body, or a name whose body was
         * left off. Told apart by what it is, so the second case can croak
         * with the name in hand rather than reporting the default feed.
         *
         * A bare string is a name UNLESS it holds a '#', which is how Punk
         * tells a 'Controller#method' target from anything else - so
         * `feed 'Web::Root#posts'` is the default feed served by a controller,
         * and `feed 'news'` is still a name that forgot its body. */
        int is_target = 0;
        if (!pfeed_is_code(ST(0)) && SvOK(ST(0)) && !SvROK(ST(0))) {
            STRLEN sl;
            const char *sp = SvPV_const(ST(0), sl);
            is_target = (memchr(sp, '#', sl) != NULL);
        }
        if (pfeed_is_code(ST(0)) || is_target) {
            name = sv_2mortal(newSVpvs(""));
            code = ST(0);
        }
        else name = ST(0);
    }
    else if (items >= 2) {
        name = ST(0);
        if (pfeed_is_hash(ST(1))) {
            HV *ov = (HV *)SvRV(ST(1));
            pfeed_check_opts(aTHX_ "feed option", ov, PFEED_FEED_OPTS);
            code = pfeed_hget(aTHX_ ov, "entries");
            over = ST(1);
        }
        else code = ST(1);
    }

    if (!(name && SvOK(name)))
        croak("%s: feed needs a name or a code reference - "
              "feed sub { ... } or feed 'news' => sub { ... }", PFEED_WHO);

    /* A coderef, or a 'Controller#method' target like any route takes. The
     * string is not resolved here: the controller may not be loaded yet, and
     * `feed` is declared in the same package body as the routes that have the
     * same problem. It is resolved at to_app, by Punk's own resolver, so a
     * feed target follows exactly the rules a route target does. */
    {
        int usable = 0;
        if (pfeed_is_code(code)) usable = 1;
        else if (code && SvOK(code) && !SvROK(code)) {
            STRLEN cl;
            (void)SvPV_const(code, cl);
            usable = (cl > 0);
        }
        if (!usable)
            croak("%s: feed '%" SVf "' needs a code reference or a "
                  "'Controller#method' target that returns entries",
                  PFEED_WHO, SVfARG(name));
    }

    list = pfeed_app_av(aTHX_ h, "feed_list");
    n = av_len(list) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(list, i, 0);
        AV *rec;
        if (!(e && *e && pfeed_is_array(*e))) continue;
        rec = (AV *)SvRV(*e);
        if (sv_eq(*av_fetch(rec, 0, 0), name)) {
            (void)av_store(rec, 1, newSVsv(code));            /* keep position */
            (void)av_store(rec, 2, over ? newSVsv(over) : newSV(0));
            XSRETURN_EMPTY;
        }
    }
    {
        AV *rec = newAV();
        av_push(rec, newSVsv(name));
        av_push(rec, newSVsv(code));
        av_push(rec, over ? newSVsv(over) : newSV(0));
        av_push(list, newRV_noinc((SV *)rec));
    }
    XSRETURN_EMPTY;
}

/* Turn any 'Controller#method' target into the coderef it names.
 *
 * Through $app->_resolve_target, which is what Punk uses for a route target -
 * so a feed target obeys the same rules, loads the class the same way, and
 * fails with the same diagnostic. Reimplementing the lookup here would be a
 * second set of rules to keep in step with the first.
 *
 * At to_app, because a controller declared after the `feed` line is the
 * ordinary case.
 */
static void pfeed_resolve_targets(pTHX_ SV *app)
{
    HV *h = pfeed_app_hv(aTHX_ app);
    AV *list;
    SSize_t i, n;

    if (!h) return;
    list = pfeed_app_av(aTHX_ h, "feed_list");
    n = av_len(list) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(list, i, 0);
        AV *rec;
        SV *code, *name, *what, *argv[2], *res;
        int failed = 0;

        if (!(e && *e && pfeed_is_array(*e))) continue;
        rec  = (AV *)SvRV(*e);
        code = *av_fetch(rec, 1, 0);
        if (pfeed_is_code(code)) continue;

        name = *av_fetch(rec, 0, 0);
        what = sv_2mortal(newSVpvs("feed "));
        if (SvCUR(name)) sv_catpvf(what, "'%" SVf "'", SVfARG(name));
        else             sv_catpvs(what, "(the default feed)");

        argv[0] = code;
        argv[1] = what;
        /* G_EVAL: _resolve_target croaks by design, and a croak through an
         * ordinary call_method would leave the stack short. */
        res = pfeed_try(aTHX_ app, "_resolve_target", argv, 2, &failed);
        if (failed || !pfeed_is_code(res)) {
            if (res) SvREFCNT_dec(res);
            croak("%" SVf, SVfARG(ERRSV));
        }
        (void)av_store(rec, 1, res);
    }
}

/* One capture-free route: /feed.xml, /feed.rss. */
static void pfeed_fixed_route(pTHX_ SV *app, HV *opts, const char *ext,
                              const char *fmt)
{
    AV *cap;
    SV *path;
    if (!pfeed_wants(aTHX_ opts, fmt)) return;
    path = sv_2mortal(newSVsv(pfeed_hget(aTHX_ opts, "path")));
    sv_catpvs(path, ".");
    sv_catpv(path, ext);
    cap = newAV();
    av_push(cap, newSVsv(app));
    av_push(cap, newSVpvs(""));        /* the default feed */
    av_push(cap, newSVpv(fmt, 0));
    pfeed_route(aTHX_ app, path, pfeed_serve_cb, cap);
}

/* Are there any feeds with names, and so anything for /feed/:name to serve? */
static int pfeed_has_named(pTHX_ HV *h)
{
    SV *l = pfeed_hget(aTHX_ h, "feed_list");
    AV *list;
    SSize_t i, n;
    if (!pfeed_is_array(l)) return 0;
    list = (AV *)SvRV(l);
    n = av_len(list) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(list, i, 0);
        if (e && *e && pfeed_is_array(*e)
            && SvCUR(*av_fetch((AV *)SvRV(*e), 0, 0))) return 1;
    }
    return 0;
}

/* Is there a default feed - one declared with no name? */
static int pfeed_has_default(pTHX_ HV *h)
{
    SV *l = pfeed_hget(aTHX_ h, "feed_list");
    AV *list;
    SSize_t i, n;
    if (!pfeed_is_array(l)) return 0;
    list = (AV *)SvRV(l);
    n = av_len(list) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(list, i, 0);
        if (e && *e && pfeed_is_array(*e)
            && !SvCUR(*av_fetch((AV *)SvRV(*e), 0, 0))) return 1;
    }
    return 0;
}

static void pfeed_routes(pTHX_ SV *app)
{
    HV *h = pfeed_app_hv(aTHX_ app);
    SV *o = h ? pfeed_hget(aTHX_ h, "feed_opts") : NULL;
    HV *opts;

    if (!pfeed_is_hash(o)) return;
    opts = (HV *)SvRV(o);

    /* Once per application, whatever else happens. Punk refuses a second
     * to_app on its own account, so this should be unreachable - but if
     * on_compile ever runs twice, adding the same route again croaks "cannot
     * add after compile", which reports a fault in this plugin as a fault in
     * the router. Cheap insurance against a confusing diagnosis. */
    if (pfeed_hget(aTHX_ h, "feed_routed")) return;
    (void)hv_stores(h, "feed_routed", newSViv(1));

    /* Only when something was declared. A route that can do nothing but 404
     * puts a row in `punk routes` that means nothing, and tells a reader the
     * feed exists but is broken rather than that it was never offered. */
    if (pfeed_has_default(aTHX_ h)) {
        pfeed_fixed_route(aTHX_ app, opts, "xml", "atom");
        pfeed_fixed_route(aTHX_ app, opts, "rss", "rss");
    }

    /* Only when something is named. A route that can nothing but 404 puts a
     * row in `punk routes` that means nothing. */
    if (pfeed_has_named(aTHX_ h)) {
        AV *cap = newAV();
        SV *path = sv_2mortal(newSVsv(pfeed_hget(aTHX_ opts, "path")));
        sv_catpvs(path, "/:name");
        av_push(cap, newSVsv(app));
        av_push(cap, newSV(0));        /* name and format come off the capture */
        av_push(cap, newSV(0));
        pfeed_route(aTHX_ app, path, pfeed_serve_cb, cap);
    }

    {
        AV *cap = newAV();
        av_push(cap, newSVsv(app));
        pfeed_helper(aTHX_ app, "feed_links", pfeed_links_cb, cap);
    }
}

/* to_app. cap = [app]. Punk hands the callback the application; this returns
 * nothing and lets the compile carry on.
 *
 * Routes are added here rather than in `register` because a named feed is
 * declared AFTER the `plugin` line, so at register time there is no way to
 * know whether /feed/:name has anything to serve. on_compile runs after every
 * keyword has recorded and before anything is compiled, so what it adds is
 * compiled with the rest.
 */
XS_INTERNAL(pfeed_compile_cb);
XS_INTERNAL(pfeed_compile_cb)
{
    dXSARGS;
    SV *app = pfeed_cap_slot(aTHX_ cv, 0);
    PERL_UNUSED_VAR(items);
    if (app) {
        pfeed_resolve_base(aTHX_ app);
        pfeed_resolve_targets(aTHX_ app);
        pfeed_routes(aTHX_ app);
        pfeed_build(aTHX_ app);
    }
    XSRETURN_EMPTY;
}

/* The keyword, installed on an app. Idempotent per owner, so `import` and
 * `register` may both ask and only the first does anything. */
static void pfeed_install_kw(pTHX_ SV *app)
{
    AV *cap = newAV();
    av_push(cap, newSVsv(app));
    pfeed_keyword(aTHX_ app, "feed", pfeed_kw_cb, cap);
}

#endif /* PFEED_BOOT_H */

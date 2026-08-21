/* punk_sitemap.h - which of an application's routes are actually URLs.
 *
 * Punk compiles every route at boot, so the application already holds a
 * complete list of what it serves. A sitemap is that list with a filter over
 * it, and this is the filter.
 *
 * WHAT GOES IN, AND WHY THE RULES ARE THESE.
 *
 * A route is a candidate when its method is GET, its path holds no capture,
 * it carries no guard, and it did not opt out. Everything else is out, and
 * OUT IS THE SAFE DIRECTION: a page missing from a sitemap is still crawled
 * if anything links to it, while a page wrongly present is a crawler fetching
 * a 404 or a login redirect on a schedule, for as long as the site exists.
 *
 * A ROUTE WITH A CAPTURE IS NOT A URL. `/users/:id` names a shape, and the
 * ids are not something the route table knows. Those come from the
 * application through the `sitemap` keyword instead.
 *
 * A GUARDED ROUTE IS EXCLUDED WITHOUT ANYONE MAINTAINING A LIST. `guards` is
 * on the route record and `under($prefix, $guard)` copies its chain into
 * every route declared inside it, so the filter can see what a human writing
 * a sitemap by hand has to remember. That is the whole argument for this
 * living in the framework rather than in a script beside it.
 *
 * Must be included after punk_route.h (pr_router and the raw records),
 * punk_names.h (the K_* keys) and punk_app.h (app_hv / app_av).
 */

#ifndef PUNK_SITEMAP_H
#define PUNK_SITEMAP_H

/* Is this path a concrete URL rather than a pattern?
 *
 * DELIBERATELY the same test punk_route.h's pr_build uses to decide whether a
 * route is static:
 *
 *     if (!memchr(p, ':', pl) && !memchr(p, '*', pl))
 *
 * If the two ever disagree, the sitemap lists a path the router does not
 * serve as written - so the rule is copied rather than reinvented, and this
 * comment is the reminder to change both. */
static int pks_concrete(const char *p, STRLEN pl) {
    if (!p || !pl || p[0] != '/') return 0;
    return !memchr(p, ':', pl) && !memchr(p, '*', pl);
}

/* GET only. HEAD is served off GET and is not a page; anything else is not
 * something a crawler should be fetching at all. `route`'s ANY form does
 * include GET, so it counts. */
static int pks_method_ok(const char *m, STRLEN ml) {
    if (!m) return 0;
    if (ml == 3 && memEQ(m, "GET", 3)) return 1;
    if (ml == 3 && memEQ(m, "ANY", 3)) return 1;
    return 0;
}

/* A guard chain of any length means the page is behind authentication. The
 * chain is the DECLARED one here rather than the resolved one - `under`
 * copies names in before anything resolves them - and emptiness is the only
 * question being asked, which resolution does not change. */
static int pks_guarded(pTHX_ HV *rec) {
    SV **g = hv_fetchs(rec, K_GUARDS, 0);
    if (!(g && *g && SvROK(*g) && SvTYPE(SvRV(*g)) == SVt_PVAV)) return 0;
    return av_len((AV *)SvRV(*g)) >= 0;
}

/* What did this method+path say about itself?
 *
 *   -1  nothing
 *    0  sitemap => 0, keep it out
 *    1  sitemap => 1, put it in even though something above excluded it
 *
 * The records are the ones app.xs pushed at declaration time, the way it does
 * for validate, compress and max_body. */
static int pks_override(pTHX_ HV *app, const char *m, STRLEN ml,
                        const char *p, STRLEN pl) {
    SV **x = hv_fetchs(app, K_SITEMAP_ROUTES, 0);
    AV *av;
    SSize_t i, n;
    if (!(x && *x && SvROK(*x) && SvTYPE(SvRV(*x)) == SVt_PVAV)) return -1;
    av = (AV *)SvRV(*x);
    n = av_len(av) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        HV *r;
        SV **rm, **rp;
        STRLEN xl, yl;
        const char *xm, *xp;
        if (!(e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)) continue;
        r  = (HV *)SvRV(*e);
        rm = hv_fetchs(r, K_METHOD, 0);
        rp = hv_fetchs(r, K_PATH, 0);
        if (!(rm && *rm && rp && *rp)) continue;
        xm = SvPV_const(*rm, xl);
        xp = SvPV_const(*rp, yl);
        if (xl == ml && yl == pl && memEQ(xm, m, ml) && memEQ(xp, p, pl)) {
            SV **f = hv_fetchs(r, K_SITEMAP, 0);
            return (f && *f && SvTRUE(*f)) ? 1 : 0;
        }
    }
    return -1;
}

/* The router's raw records: {method, path, target, guards}, one per declared
 * route, in declaration order.
 *
 * The RAW list and not the compiled one, because the compiled records only
 * exist after `compile` has run and this wants to be answerable from
 * anywhere. Raw already carries the full path and the full guard chain -
 * scopes concatenate the prefix and copy the guards in before `route` is
 * reached - so nothing is missing for the questions above. */
static AV *pks_raw(pTHX_ HV *app) {
    SV *router = app_get(aTHX_ app, K_ROUTER);
    pr_router *rt;
    if (!(router && SvROK(router) && SvIOK(SvRV(router)) && SvIV(SvRV(router))))
        return NULL;
    rt = INT2PTR(pr_router *, SvIV(SvRV(router)));
    return rt ? rt->raw : NULL;
}

/* Sort helper: paths compare as bytes, so two boots of one application
 * produce a byte-identical list. Hash order would make the sitemap's ETag
 * and Last-Modified move on a deploy that changed nothing, and would make a
 * diff of two environments noise. */
static I32 pks_cmp(pTHX_ SV *a, SV *b) {
    STRLEN al, bl;
    const char *ap = SvPV_const(a, al);
    const char *bp = SvPV_const(b, bl);
    STRLEN n = al < bl ? al : bl;
    int c = n ? memcmp(ap, bp, n) : 0;
    if (c) return c < 0 ? -1 : 1;
    return al == bl ? 0 : (al < bl ? -1 : 1);
}

/* The same ordering, over [loc, lastmod] pairs. */
static I32 pks_cmp_pair(pTHX_ SV *a, SV *b) {
    SV **x = av_fetch((AV *)SvRV(a), 0, 0);
    SV **y = av_fetch((AV *)SvRV(b), 0, 0);
    return pks_cmp(aTHX_ x ? *x : &PL_sv_undef, y ? *y : &PL_sv_undef);
}

/* The candidate paths, sorted and de-duplicated (+1).
 *
 * Paths, not URLs: the absolute form needs the configured base, and taking
 * that from the request would be a host-header injection delivered to search
 * engines - see plan_punk_sitemap/phase-0. Joining happens where the base is
 * known to be configuration. */
static AV *pks_paths(pTHX_ SV *appsv) {
    HV *app = app_hv(aTHX_ appsv);
    AV *raw = app ? pks_raw(aTHX_ app) : NULL;
    AV *out = newAV();
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    SSize_t i, n;

    if (!raw) return out;
    n = av_len(raw) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(raw, i, 0);
        HV *rec;
        SV **msv, **psv;
        STRLEN ml, pl;
        const char *m, *p;

        if (!(e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)) continue;
        rec = (HV *)SvRV(*e);
        msv = hv_fetchs(rec, K_METHOD, 0);
        psv = hv_fetchs(rec, K_PATH, 0);
        if (!(msv && *msv && psv && *psv)) continue;
        m = SvPV_const(*msv, ml);
        p = SvPV_const(*psv, pl);

        {
            int said = pks_override(aTHX_ app, m, ml, p, pl);
            if (said == 0) continue;                     /* sitemap => 0 */

            /* Method and shape are never overridable: a POST is not a page
             * and `/users/:id` is not a URL, so `sitemap => 1` on either is a
             * mistake rather than an instruction. The guard is the only
             * exclusion an application can argue with, because it is the only
             * one this cannot read the intent of. */
            if (!pks_method_ok(m, ml)) continue;
            if (!pks_concrete(p, pl))  continue;
            if (said != 1 && pks_guarded(aTHX_ rec)) continue;
        }
        if (hv_exists(seen, p, (I32)pl))        continue;   /* ANY + GET */

        /* newSViv and not &PL_sv_yes: hv_store takes ownership of the value's
         * refcount, and an immortal handed to it is decremented when the hash
         * is freed - which before 5.20 is a real decrement of a value that
         * has no protection, and eventually a free underneath the
         * interpreter. */
        (void)hv_store(seen, p, (I32)pl, newSViv(1), 0);
        av_push(out, newSVpvn(p, pl));
    }

    if (av_len(out) > 0)
        sortsv(AvARRAY(out), (size_t)(av_len(out) + 1), pks_cmp);
    return out;
}

/* ---- rendering -------------------------------------------------------------
 *
 * The protocol caps a sitemap at 50,000 URLs AND 50MB uncompressed, and past
 * either one crawlers reject the file - the whole file, not the excess. So
 * both are counted as the document is written and whichever binds first
 * starts a new part.
 *
 * The byte cap binds more often than people expect: 50,000 URLs at 1KB each
 * is 50MB, and a long path inside its <url> element is not far off 200 bytes.
 * Which is why it is counted as written rather than estimated. */
#define PKS_MAX_URLS   50000
#define PKS_MAX_BYTES  (50UL * 1024 * 1024)

/* XML escaping, over every emitted URL without exception.
 *
 * One unescaped `&` makes the document not well-formed, and a crawler
 * rejects ALL of it rather than the offending entry - so this is a
 * correctness problem before it is a security one. The route half rarely
 * contains anything needing it; the dynamic half of phase 3 routinely will,
 * because a slug with an ampersand in it is ordinary. */
static void pks_xml_cat(pTHX_ SV *out, const char *s, STRLEN l) {
    STRLEN i, start = 0;
    for (i = 0; i < l; i++) {
        const char *rep;
        switch (s[i]) {
            case '&':  rep = "&amp;";  break;
            case '<':  rep = "&lt;";   break;
            case '>':  rep = "&gt;";   break;
            case '"':  rep = "&quot;"; break;
            case '\'': rep = "&apos;"; break;
            default:   continue;
        }
        if (i > start) sv_catpvn(out, s + start, i - start);
        sv_catpv(out, rep);
        start = i + 1;
    }
    if (l > start) sv_catpvn(out, s + start, l - start);
}

/* Percent-encoding, which is a DIFFERENT job from escaping and comes first.
 *
 * A path holding a space or a non-ASCII byte has to be percent-encoded to be
 * a URL at all; escaping alone would produce a well-formed document
 * containing an invalid URL. Encoding first also means everything reaching
 * the escaper is ASCII, so a route path that is not valid UTF-8 cannot make
 * the document unparseable - the encoder turned it into %XX long before.
 *
 * Unreserved plus '/' is kept and everything else encoded. Over-encoding a
 * sub-delimiter is legal and costs three bytes; under-encoding one is a
 * different URL. */
static void pks_pct_cat(pTHX_ SV *out, const char *s, STRLEN l) {
    static const char hex[] = "0123456789ABCDEF";
    STRLEN i;
    for (i = 0; i < l; i++) {
        unsigned char c = (unsigned char)s[i];
        if (isALNUM(c) || c == '-' || c == '.' || c == '_' || c == '~'
            || c == '/') {
            sv_catpvn(out, (const char *)&c, 1);
        }
        else {
            char e[3];
            e[0] = '%'; e[1] = hex[c >> 4]; e[2] = hex[c & 0xF];
            sv_catpvn(out, e, 3);
        }
    }
}

/* One <url> element onto `out`, base + path, encoded then escaped. */
/* ---- the dynamic half -------------------------------------------------------
 *
 * A section is application code returning data that goes straight into a
 * structured document, so every field is checked on the way in. The route
 * half needs none of this because its paths are declarations; a section's are
 * database rows.
 */

/* Is this a location this application may publish?
 *
 * Rooted, concrete, same-origin, and free of anything that would break out of
 * the element it lands in:
 *
 *   - it must start with '/', because the base supplies the origin;
 *   - it must NOT start with '//', which is protocol-relative and names
 *     another host - `//evil.example/x` in a sitemap is somebody else's pages
 *     published under your name;
 *   - it must hold no ':' or '*', which means a section returned the route
 *     PATTERN by mistake and a literal `:id` would go in the file;
 *   - no control bytes and no backslash, the bug class
 *     reference_reflected_request_bytes exists for.
 *
 * `$c->safe_path` encodes the same rules for redirects, and the reasoning is
 * identical: bytes the application did not write, reaching somewhere
 * structured. */
static int pks_loc_ok(const char *p, STRLEN l) {
    STRLEN i;
    if (!p || !l || p[0] != '/') return 0;
    if (l > 1 && p[1] == '/')    return 0;
    if (memchr(p, ':', l) || memchr(p, '*', l)) return 0;
    for (i = 0; i < l; i++) {
        unsigned char c = (unsigned char)p[i];
        if (c < 0x20 || c == 0x7F || c == '\\') return 0;
    }
    return 1;
}

/* W3C Datetime, which is what <lastmod> takes: a date, optionally with a
 * time. Parsed rather than passed through, because one unparseable value
 * makes the whole document invalid and a crawler rejects all of it. Anything
 * that does not fit is DROPPED and the URL still goes in - a missing lastmod
 * costs nothing, and losing the page would. */
static int pks_lastmod_ok(const char *s, STRLEN l) {
    STRLEN i;
    if (l < 10) return 0;
    for (i = 0; i < 10; i++) {
        if (i == 4 || i == 7) { if (s[i] != '-') return 0; }
        else if (!isDIGIT(s[i])) return 0;
    }
    if (l == 10) return 1;
    if (s[10] != 'T') return 0;
    /* the rest is time and zone: digits, ':', '+', '-', '.', 'Z' */
    for (i = 11; i < l; i++) {
        char c = s[i];
        if (!(isDIGIT(c) || c == ':' || c == '+' || c == '-' || c == '.'
              || c == 'Z')) return 0;
    }
    return 1;
}

/* One <url> element, with the optional <lastmod>. */
static void pks_url_cat_lm(pTHX_ SV *out, SV *base, const char *p, STRLEN pl,
                           SV *lastmod);

static void pks_url_cat(pTHX_ SV *out, SV *base, const char *p, STRLEN pl) {
    SV *loc = sv_2mortal(newSVpvn("", 0));
    STRLEN bl;
    const char *bp = SvPV_const(base, bl);
    /* A trailing slash on the base would double the one every path starts
     * with, and `https://x//about` is a different URL to a crawler. */
    while (bl && bp[bl - 1] == '/') bl--;
    sv_catpvn(loc, bp, bl);
    pks_pct_cat(aTHX_ loc, p, pl);

    sv_catpvs(out, "  <url><loc>");
    {
        STRLEN ll;
        const char *lp = SvPV_const(loc, ll);
        pks_xml_cat(aTHX_ out, lp, ll);
    }
    sv_catpvs(out, "</loc></url>\n");
}

static void pks_url_cat_lm(pTHX_ SV *out, SV *base, const char *p, STRLEN pl,
                           SV *lastmod) {
    SV *loc = sv_2mortal(newSVpvn("", 0));
    STRLEN bl;
    const char *bp = SvPV_const(base, bl);
    while (bl && bp[bl - 1] == '/') bl--;
    sv_catpvn(loc, bp, bl);
    pks_pct_cat(aTHX_ loc, p, pl);

    sv_catpvs(out, "  <url><loc>");
    {
        STRLEN ll;
        const char *lp = SvPV_const(loc, ll);
        pks_xml_cat(aTHX_ out, lp, ll);
    }
    sv_catpvs(out, "</loc>");
    if (lastmod && SvOK(lastmod)) {
        STRLEN ml;
        const char *mp = SvPV_const(lastmod, ml);
        if (pks_lastmod_ok(mp, ml)) {
            sv_catpvs(out, "<lastmod>");
            pks_xml_cat(aTHX_ out, mp, ml);
            sv_catpvs(out, "</lastmod>");
        }
    }
    sv_catpvs(out, "</url>\n");
}

/* Run one section and collect what it returned as [loc, lastmod] pairs.
 *
 * G_EVAL: a section reads a database, and a section that died must not take
 * the request with it. A failed section warns and contributes nothing, which
 * degrades the sitemap rather than the site. */
static void pks_run_section(pTHX_ SV *code, SV *name, AV *out) {
    dSP;
    int count, i;
    AV *got = (AV *)sv_2mortal((SV *)newAV());
    IV kept = 0;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    count = call_sv(code, G_ARRAY | G_EVAL);
    SPAGAIN;
    for (i = count - 1; i >= 0; i--) av_store(got, (SSize_t)i, newSVsv(POPs));
    PUTBACK;
    if (SvTRUE(ERRSV))
        warn("Punk::Plugin::Sitemap: section '%" SVf "' died, and contributes "
             "nothing: %" SVf, SVfARG(name), SVfARG(ERRSV));
    FREETMPS; LEAVE;

    for (i = 0; i < count; i++) {
        SV **e = av_fetch(got, (SSize_t)i, 0);
        SV *loc = NULL, *lm = NULL;
        STRLEN ll;
        const char *lp;
        if (!(e && *e && SvOK(*e))) continue;

        if (SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV) {
            HV *r = (HV *)SvRV(*e);
            SV **x = hv_fetchs(r, "loc", 0);
            SV **m = hv_fetchs(r, "lastmod", 0);
            loc = (x && *x) ? *x : NULL;
            lm  = (m && *m && SvOK(*m)) ? *m : NULL;
        }
        else loc = *e;               /* a bare string is a loc */

        if (!(loc && SvOK(loc))) continue;
        lp = SvPV_const(loc, ll);

        if (!pks_loc_ok(lp, ll)) {
            warn("Punk::Plugin::Sitemap: section '%" SVf "' returned a loc "
                 "that is not a rooted, same-origin path and is dropped: "
                 "'%" SVf "'", SVfARG(name), SVfARG(loc));
            continue;
        }
        /* A section walking a table that grew is how this becomes an
         * out-of-memory at boot rather than a large file. */
        if (kept >= PKS_MAX_URLS) {
            warn("Punk::Plugin::Sitemap: section '%" SVf "' returned more "
                 "than %d locations and is truncated there",
                 SVfARG(name), (int)PKS_MAX_URLS);
            break;
        }
        {
            AV *pair = newAV();
            av_push(pair, newSVsv(loc));
            av_push(pair, lm ? newSVsv(lm) : newSV(0));
            av_push(out, newRV_noinc((SV *)pair));
            kept++;
        }
    }
}

/* Every entry that goes in the document: the route half first, then each
 * section in declaration order.
 *
 * Both halves are sorted within themselves and de-duplicated across the
 * whole, so a page that is both a static route and a section row appears
 * once - a duplicated <url> is something crawlers dislike and nobody meant.
 * Determinism survives the dynamic half this way: a section returning rows in
 * database order would otherwise make every regeneration a different file. */
static AV *pks_entries(pTHX_ SV *appsv) {
    HV *app = app_hv(aTHX_ appsv);
    AV *paths = (AV *)sv_2mortal((SV *)pks_paths(aTHX_ appsv));
    AV *out = newAV();
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    SV *secs;
    SSize_t i, n;

    n = av_len(paths) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(paths, i, 0);
        AV *pair;
        STRLEN pl;
        const char *p;
        if (!(e && *e)) continue;
        p = SvPV_const(*e, pl);
        if (hv_exists(seen, p, (I32)pl)) continue;
        (void)hv_store(seen, p, (I32)pl, newSViv(1), 0);
        pair = newAV();
        av_push(pair, newSVsv(*e));
        av_push(pair, newSV(0));
        av_push(out, newRV_noinc((SV *)pair));
    }

    secs = app ? app_get(aTHX_ app, "sitemap_sections") : NULL;
    if (secs && SvROK(secs) && SvTYPE(SvRV(secs)) == SVt_PVAV) {
        AV *list = (AV *)SvRV(secs);
        SSize_t si, sn = av_len(list) + 1;
        for (si = 0; si < sn; si++) {
            SV **se = av_fetch(list, si, 0);
            AV *rec;
            AV *got;
            SSize_t gi, gn;
            if (!(se && *se && SvROK(*se) && SvTYPE(SvRV(*se)) == SVt_PVAV))
                continue;
            rec = (AV *)SvRV(*se);
            got = (AV *)sv_2mortal((SV *)newAV());
            pks_run_section(aTHX_ *av_fetch(rec, 1, 0),
                            *av_fetch(rec, 0, 0), got);
            if (av_len(got) > 0)
                sortsv(AvARRAY(got), (size_t)(av_len(got) + 1), pks_cmp_pair);
            gn = av_len(got) + 1;
            for (gi = 0; gi < gn; gi++) {
                SV **g = av_fetch(got, gi, 0);
                AV *pair;
                STRLEN pl;
                const char *p;
                if (!(g && *g && SvROK(*g))) continue;
                pair = (AV *)SvRV(*g);
                p = SvPV_const(*av_fetch(pair, 0, 0), pl);
                if (hv_exists(seen, p, (I32)pl)) continue;
                (void)hv_store(seen, p, (I32)pl, newSViv(1), 0);
                av_push(out, newSVsv(*g));
            }
        }
    }
    return out;
}

#define PKS_HEAD "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" \
                 "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
#define PKS_TAIL "</urlset>\n"
#define PKS_IHEAD "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" \
                  "<sitemapindex xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
#define PKS_ITAIL "</sitemapindex>\n"

/* Render every candidate path into one or more <urlset> documents (+1 each).
 *
 * No <lastmod> on this half: "when did this static page last change" is not
 * something the route table knows, and stamping boot time would tell crawlers
 * every page changed on every deploy - the fastest way to have the file
 * ignored. The dynamic half supplies its own, where the application does
 * know. */
static AV *pks_render_parts(pTHX_ SV *appsv, SV *base) {
    AV *ents = (AV *)sv_2mortal((SV *)pks_entries(aTHX_ appsv));
    AV *parts = newAV();
    SSize_t i, n = av_len(ents) + 1;
    SV *cur = NULL;
    IV urls = 0;

    for (i = 0; i < n; i++) {
        SV **e = av_fetch(ents, i, 0);
        AV *pair;
        SV *lm;
        STRLEN pl;
        const char *p;
        if (!(e && *e && SvROK(*e))) continue;
        pair = (AV *)SvRV(*e);
        p  = SvPV_const(*av_fetch(pair, 0, 0), pl);
        lm = *av_fetch(pair, 1, 0);

        if (cur) {
            /* Would this one take the part past either cap? The URL is
             * rendered into a scratch buffer so the byte cost is known
             * rather than guessed. */
            SV *probe = sv_2mortal(newSVpvn("", 0));
            pks_url_cat_lm(aTHX_ probe, base, p, pl, lm);
            if (urls + 1 > PKS_MAX_URLS
                || SvCUR(cur) + SvCUR(probe) + (sizeof(PKS_TAIL) - 1)
                   > PKS_MAX_BYTES) {
                sv_catpvs(cur, PKS_TAIL);
                av_push(parts, cur);
                cur = NULL;
                urls = 0;
            }
            else {
                sv_catsv(cur, probe);
                urls++;
                continue;
            }
        }
        if (!cur) {
            cur = newSVpvn(PKS_HEAD, sizeof(PKS_HEAD) - 1);
            urls = 0;
        }
        pks_url_cat_lm(aTHX_ cur, base, p, pl, lm);
        urls++;
    }

    if (cur) { sv_catpvs(cur, PKS_TAIL); av_push(parts, cur); }
    /* An application with no listable route still serves a valid, empty
     * document rather than a 404 - a crawler asking gets an answer, and an
     * empty urlset is a legitimate one. */
    if (av_len(parts) < 0) {
        SV *empty = newSVpvn(PKS_HEAD, sizeof(PKS_HEAD) - 1);
        sv_catpvs(empty, PKS_TAIL);
        av_push(parts, empty);
    }
    return parts;
}

/* The index over the parts (+1), when there is more than one.
 *
 * With one part there is no index and /sitemap.xml is that part: an index
 * wrapping a single sitemap is a second fetch for nothing. */
static SV *pks_render_index(pTHX_ SV *base, SSize_t nparts) {
    SV *out = newSVpvn(PKS_IHEAD, sizeof(PKS_IHEAD) - 1);
    STRLEN bl;
    const char *bp = SvPV_const(base, bl);
    SSize_t i;
    while (bl && bp[bl - 1] == '/') bl--;
    for (i = 0; i < nparts; i++) {
        SV *loc = sv_2mortal(newSVpvn(bp, bl));
        sv_catpvf(loc, "/sitemap/%" IVdf ".xml", (IV)(i + 1));
        sv_catpvs(out, "  <sitemap><loc>");
        {
            STRLEN ll;
            const char *lp = SvPV_const(loc, ll);
            pks_xml_cat(aTHX_ out, lp, ll);
        }
        sv_catpvs(out, "</loc></sitemap>\n");
    }
    sv_catpvs(out, PKS_ITAIL);
    return out;
}

/* Render everything and stash it on the app: "sitemap_parts" is the AV of
 * <urlset> documents, "sitemap_index" the index when there is more than one.
 *
 * Once, at to_app. The route half changes only when the routes do, which is
 * never while the process runs, so a request for the document is a write of
 * bytes that already exist. */
static void pks_build(pTHX_ SV *appsv) {
    HV *h = app_hv(aTHX_ appsv);
    SV *base = h ? app_get(aTHX_ h, "sitemap_base") : NULL;
    AV *parts;
    if (!(h && base && SvOK(base))) return;
    parts = pks_render_parts(aTHX_ appsv, base);
    (void)hv_stores(h, "sitemap_parts", newRV_noinc((SV *)parts));
    (void)hv_stores(h, "sitemap_index",
                    av_len(parts) > 0
                        ? pks_render_index(aTHX_ base, av_len(parts) + 1)
                        : newSV(0));
    (void)hv_stores(h, "sitemap_built_at", newSVnv(pc_now(aTHX)));
}

/* Does the document need rebuilding before it is served?
 *
 * The route half never does - routes cannot change while the process runs -
 * so an application with no sections keeps phase 2's behaviour exactly: built
 * at to_app, served from memory, never rebuilt.
 *
 * A section reads a database, so its answer changes underneath us. Running it
 * per request would be a query nobody is watching, on a schedule somebody
 * else chooses; running it once at boot would produce a sitemap that is
 * correct on the day of the deploy and progressively wrong afterwards. So it
 * is rebuilt when the TTL has passed, and the document is stale by up to that
 * long.
 *
 * That staleness is fine and is worth stating rather than engineering away: a
 * crawler learning about a page an hour late is a crawler behaving normally,
 * and no search engine promises to fetch a sitemap promptly anyway.
 *
 * There is no stampede to guard against inside a worker. Hyperman is
 * single-threaded and a worker serves its requests one after another, so the
 * second of two simultaneous crawler requests finds what the first built. The
 * cost across a pool is one rebuild per worker per TTL. */
static void pks_ensure(pTHX_ SV *appsv) {
    HV *h = app_hv(aTHX_ appsv);
    SV *secs, *at, *ttl;
    if (!h) return;
    secs = app_get(aTHX_ h, "sitemap_sections");
    if (!(secs && SvROK(secs) && av_len((AV *)SvRV(secs)) >= 0)) return;

    at  = app_get(aTHX_ h, "sitemap_built_at");
    ttl = app_get(aTHX_ h, "sitemap_ttl");
    if (at && SvOK(at) && ttl && SvOK(ttl)
        && pc_now(aTHX) - SvNV(at) < SvNV(ttl)) return;
    pks_build(aTHX_ appsv);
}

/* Serve a rendered document. cap = [app, is_part].
 *
 * The bytes already exist - the whole document was built at to_app - so a
 * request is a write of something in memory and not a render. */
XS_INTERNAL(pks_serve_cb);
XS_INTERNAL(pks_serve_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *app = cap ? *av_fetch(cap, 0, 0) : NULL;
    int is_part = cap ? (int)SvIV(*av_fetch(cap, 1, 0)) : 0;
    SV *c = items > 0 ? ST(0) : NULL;
    HV *h = app ? app_hv(aTHX_ app) : NULL;
    IV n = 0;
    SV *doc = NULL;
    AV *resp, *headers, *body;

    if (!h) XSRETURN_EMPTY;
    pks_ensure(aTHX_ app);   /* a section may have gone stale since the last hit */

    if (is_part && c) {
        /* Punk captures whole SEGMENTS, so the pattern is /sitemap/:n and the
         * capture arrives as "1.xml" rather than "1". Parsed rather than
         * handed to SvIV, which would take "9evil.xml" as 9 and serve a part
         * for a URL nobody published. */
        SV *arg = sv_2mortal(newSVpvs("n"));
        SV *v = pcx_call_meth(aTHX_ c, "param", &arg, 1, 1);
        if (v) {
            if (SvOK(v)) {
                STRLEN vl;
                const char *vp = SvPV_const(v, vl);
                STRLEN d = 0;
                while (d < vl && isDIGIT(vp[d])) d++;
                if (d > 0 && d < vl && vl - d == 4 && memEQ(vp + d, ".xml", 4)) {
                    STRLEN k;
                    for (k = 0; k < d; k++) n = n * 10 + (vp[k] - '0');
                }
            }
            SvREFCNT_dec(v);
        }
    }

    if (!is_part) {
        doc = app_get(aTHX_ h, "sitemap_index");
        if (!(doc && SvOK(doc))) n = 1;
    }
    if (n > 0) {
        SV *ps = app_get(aTHX_ h, "sitemap_parts");
        AV *parts = (ps && SvROK(ps) && SvTYPE(SvRV(ps)) == SVt_PVAV)
                    ? (AV *)SvRV(ps) : NULL;
        SV **e = (parts && n >= 1) ? av_fetch(parts, (SSize_t)(n - 1), 0) : NULL;
        doc = (e && *e) ? *e : NULL;
    }

    /* A part number nobody generated is a 404 and not an empty document: a
     * crawler following a stale index should be told the part is gone. */
    if (!(doc && SvOK(doc))) {
        SV *r = pcx_call_meth(aTHX_ c, "not_found", NULL, 0, 1);
        if (r) { ST(0) = sv_2mortal(r); XSRETURN(1); }
        XSRETURN_EMPTY;
    }

    resp = newAV(); headers = newAV(); body = newAV();
    av_push(headers, newSVpvs("Content-Type"));
    av_push(headers, newSVpvs("application/xml; charset=utf-8"));
    av_push(headers, newSVpvs("Content-Length"));
    av_push(headers, newSViv((IV)SvCUR(doc)));
    av_push(body, newSVsv(doc));
    av_push(resp, newSViv(200));
    av_push(resp, newRV_noinc((SV *)headers));
    av_push(resp, newRV_noinc((SV *)body));
    ST(0) = sv_2mortal(newRV_noinc((SV *)resp));
    XSRETURN(1);
}

static SV *pks_robots(pTHX_ SV *appsv);

/* Serve robots.txt. Rebuilt on demand like the sitemap, because a dynamic
 * section cannot change it but a rebuilt document should not disagree with a
 * stale robots either. */
XS_INTERNAL(pks_robots_cb);
XS_INTERNAL(pks_robots_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *app = cap ? *av_fetch(cap, 0, 0) : NULL;
    SV *body;
    AV *resp, *headers, *bodyav;
    PERL_UNUSED_VAR(items);

    if (!app) XSRETURN_EMPTY;
    body = sv_2mortal(pks_robots(aTHX_ app));

    resp = newAV(); headers = newAV(); bodyav = newAV();
    av_push(headers, newSVpvs("Content-Type"));
    av_push(headers, newSVpvs("text/plain; charset=utf-8"));
    av_push(headers, newSVpvs("Content-Length"));
    av_push(headers, newSViv((IV)SvCUR(body)));
    av_push(bodyav, newSVsv(body));
    av_push(resp, newSViv(200));
    av_push(resp, newRV_noinc((SV *)headers));
    av_push(resp, newRV_noinc((SV *)bodyav));
    ST(0) = sv_2mortal(newRV_noinc((SV *)resp));
    XSRETURN(1);
}

/* The `sitemap` keyword. cap = [app].
 *
 *     sitemap 'users' => sub { ... };
 *
 * NAMED, so a second declaration of the same name REPLACES rather than
 * appends: a base class can declare a section and a subclass override it, and
 * an application reloading its own definition does not end up with the
 * section twice. Declaration order is the emission order, and a replaced
 * section keeps its original position so the document does not reshuffle. */
XS_INTERNAL(pks_kw_cb);
XS_INTERNAL(pks_kw_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *app = cap ? *av_fetch(cap, 0, 0) : NULL;
    HV *h = app ? app_hv(aTHX_ app) : NULL;
    SV *name = items > 0 ? ST(0) : NULL;
    SV *code = items > 1 ? ST(1) : NULL;
    AV *list;
    SSize_t i, n;

    if (!h) XSRETURN_EMPTY;
    if (!(name && SvOK(name) && SvCUR(name)))
        croak("Punk: sitemap needs a name - sitemap 'users' => sub { ... }");
    if (!(code && SvROK(code) && SvTYPE(SvRV(code)) == SVt_PVCV))
        croak("Punk: sitemap '%" SVf "' needs a code reference that returns "
              "locations", SVfARG(name));

    list = app_av(aTHX_ h, "sitemap_sections");
    n = av_len(list) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(list, i, 0);
        AV *rec;
        if (!(e && *e && SvROK(*e))) continue;
        rec = (AV *)SvRV(*e);
        if (sv_eq(*av_fetch(rec, 0, 0), name)) {
            av_store(rec, 1, newSVsv(code));      /* replace, keep position */
            XSRETURN_EMPTY;
        }
    }
    {
        AV *rec = newAV();
        av_push(rec, newSVsv(name));
        av_push(rec, newSVsv(code));
        av_push(list, newRV_noinc((SV *)rec));
    }
    XSRETURN_EMPTY;
}

/* ---- robots.txt -------------------------------------------------------------
 *
 * The same decision, made once, spelled twice. A sitemap says "crawl these"
 * and robots.txt says "do not crawl those"; written apart they drift within a
 * release, and the drift is silent in both directions - a path disallowed but
 * listed is a crawler told two things, and a path excluded but not disallowed
 * is crawled anyway, which is how a staging environment gets indexed.
 *
 * So both come out of one pass over the same records.
 *
 * ROBOTS.TXT IS NOT ACCESS CONTROL. It is a request to well-behaved crawlers,
 * ignored by everything else, and a Disallow line is a signpost to anything
 * hostile - a published list of the paths worth attacking. The guarding is
 * auth_guard's job; this only tells Google not to bother.
 */

/* Is this one of the routes the plugin registered for itself? */
static int pks_is_own(pTHX_ HV *app, const char *p, STRLEN pl) {
    SV *own = app_get(aTHX_ app, "sitemap_own");
    AV *av;
    SSize_t i, n;
    if (!(own && SvROK(own) && SvTYPE(SvRV(own)) == SVt_PVAV)) return 0;
    av = (AV *)SvRV(own);
    n = av_len(av) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        STRLEN ol;
        const char *op;
        if (!(e && *e)) continue;
        op = SvPV_const(*e, ol);
        if (ol == pl && memEQ(op, p, pl)) return 1;
    }
    return 0;
}

/* How much of a path to disallow.
 *
 * A capture makes the rest of the path meaningless as a literal - nobody
 * benefits from `Disallow: /account/orders/:id` - so the path is truncated at
 * the first capture segment and the prefix stands for everything under it,
 * which is exactly the set the route matches. `/account/orders/:id` becomes
 * `/account/orders/`, and `/account/settings` stays as it is. */
static SV *pks_disallow_form(pTHX_ const char *p, STRLEN pl) {
    STRLEN i, cut = pl;
    for (i = 0; i < pl; i++) {
        if (p[i] == ':' || p[i] == '*') {
            /* back up to the segment boundary, keeping the slash */
            cut = i;
            while (cut > 1 && p[cut - 1] != '/') cut--;
            break;
        }
    }
    return newSVpvn(p, cut);
}

/* Does `pfx` cover `path`? A robots prefix match: everything starting with
 * it. */
static int pks_covers(const char *pfx, STRLEN fl, const char *path, STRLEN pl) {
    if (fl > pl) return 0;
    return memEQ(pfx, path, fl);
}

/* Every prefix this application asks crawlers to leave alone (+1).
 *
 * Guarded routes and routes that said `sitemap => 0`, plus whatever the
 * `disallow` option added - then filtered against what the SITEMAP lists, so
 * a Disallow can never shadow a URL the same file is advertising. That filter
 * is the whole "they cannot disagree" property, and it is cheaper to enforce
 * than to test for afterwards. */
static AV *pks_disallows(pTHX_ SV *appsv) {
    HV *app = app_hv(aTHX_ appsv);
    AV *listed = (AV *)sv_2mortal((SV *)pks_paths(aTHX_ appsv));
    AV *raw = app ? pks_raw(aTHX_ app) : NULL;
    AV *cand = (AV *)sv_2mortal((SV *)newAV());
    AV *out = newAV();
    HV *seen = (HV *)sv_2mortal((SV *)newHV());
    SV *extra;
    SSize_t i, n;

    n = raw ? av_len(raw) + 1 : 0;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(raw, i, 0);
        HV *rec;
        SV **msv, **psv;
        STRLEN ml, pl;
        const char *m, *p;
        int said;

        if (!(e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)) continue;
        rec = (HV *)SvRV(*e);
        msv = hv_fetchs(rec, K_METHOD, 0);
        psv = hv_fetchs(rec, K_PATH, 0);
        if (!(msv && *msv && psv && *psv)) continue;
        m = SvPV_const(*msv, ml);
        p = SvPV_const(*psv, pl);

        /* Only what a crawler would have fetched. A guarded POST is not
         * something to disallow: crawlers do not POST, and the same path may
         * carry a public GET that must stay listed. */
        if (!pks_method_ok(m, ml)) continue;
        said = pks_override(aTHX_ app, m, ml, p, pl);
        if (said == 1) continue;                       /* explicitly public */
        if (!(said == 0 || pks_guarded(aTHX_ rec))) continue;
        /* The plugin's OWN routes are kept out of the sitemap - a sitemap
         * listing itself is noise - but they are emphatically not "do not
         * crawl". Disallowing /sitemap.xml while the Sitemap: line below
         * advertises it is precisely the self-contradiction this file exists
         * to prevent, and /robots.txt disallowing itself is nonsense. */
        if (pks_is_own(aTHX_ app, p, pl)) continue;
        av_push(cand, pks_disallow_form(aTHX_ p, pl));
    }

    extra = app ? app_get(aTHX_ app, "sitemap_disallow") : NULL;
    if (extra && SvROK(extra) && SvTYPE(SvRV(extra)) == SVt_PVAV) {
        AV *ex = (AV *)SvRV(extra);
        SSize_t xi, xn = av_len(ex) + 1;
        for (xi = 0; xi < xn; xi++) {
            SV **e = av_fetch(ex, xi, 0);
            if (e && *e && SvOK(*e)) av_push(cand, newSVsv(*e));
        }
    }

    if (av_len(cand) > 0)
        sortsv(AvARRAY(cand), (size_t)(av_len(cand) + 1), pks_cmp);

    n = av_len(cand) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(cand, i, 0);
        STRLEN fl;
        const char *f;
        SSize_t j, ln;
        int shadows = 0, covered = 0;

        if (!(e && *e)) continue;
        f = SvPV_const(*e, fl);
        if (!fl || f[0] != '/') continue;
        if (hv_exists(seen, f, (I32)fl)) continue;

        /* Never disallow something the sitemap lists. */
        ln = av_len(listed) + 1;
        for (j = 0; j < ln; j++) {
            SV **l = av_fetch(listed, j, 0);
            STRLEN pl;
            const char *p;
            if (!(l && *l)) continue;
            p = SvPV_const(*l, pl);
            if (pks_covers(f, fl, p, pl)) { shadows = 1; break; }
        }
        if (shadows) continue;

        /* and drop what a shorter prefix already covers */
        ln = av_len(out) + 1;
        for (j = 0; j < ln; j++) {
            SV **o = av_fetch(out, j, 0);
            STRLEN ol;
            const char *op;
            if (!(o && *o)) continue;
            op = SvPV_const(*o, ol);
            if (pks_covers(op, ol, f, fl)) { covered = 1; break; }
        }
        if (covered) continue;

        (void)hv_store(seen, f, (I32)fl, newSViv(1), 0);
        av_push(out, newSVpvn(f, fl));
    }
    return out;
}

/* The robots.txt body (+1). */
static SV *pks_robots(pTHX_ SV *appsv) {
    HV *app = app_hv(aTHX_ appsv);
    SV *base = app ? app_get(aTHX_ app, "sitemap_base") : NULL;
    SV *all  = app ? app_get(aTHX_ app, "sitemap_disallow_all") : NULL;
    SV *out = newSVpvs("User-agent: *\n");

    if (all && SvTRUE(all)) {
        /* A staging environment being indexed is routine, embarrassing and
         * slow to undo, and it is usually a robots.txt copied from
         * production. No Sitemap line here: advertising a sitemap while
         * disallowing everything says two opposite things. */
        sv_catpvs(out, "Disallow: /\n");
        return out;
    }

    {
        AV *dis = (AV *)sv_2mortal((SV *)pks_disallows(aTHX_ appsv));
        SSize_t i, n = av_len(dis) + 1;
        for (i = 0; i < n; i++) {
            SV **e = av_fetch(dis, i, 0);
            STRLEN l;
            const char *p;
            if (!(e && *e)) continue;
            p = SvPV_const(*e, l);
            sv_catpvs(out, "Disallow: ");
            /* percent-encoded, so a path with a space or a newline in it
             * cannot become a second directive */
            pks_pct_cat(aTHX_ out, p, l);
            sv_catpvs(out, "\n");
        }
    }

    /* The line most hand-written robots.txt files are missing, and the one
     * that makes a sitemap discoverable without anybody being told. */
    if (base && SvOK(base)) {
        STRLEN bl;
        const char *bp = SvPV_const(base, bl);
        while (bl && bp[bl - 1] == '/') bl--;
        sv_catpvs(out, "\nSitemap: ");
        sv_catpvn(out, bp, bl);
        sv_catpvs(out, "/sitemap.xml\n");
    }
    return out;
}

/* Does this class have that method? A `can` through the ordinary lookup, so
 * inheritance and AUTOLOAD behave as they would anywhere else. */
static int pkc_can_meth(pTHX_ SV *obj, const char *meth) {
    SV *m = sv_2mortal(newSVpv(meth, 0));
    SV *r = pcx_call_meth(aTHX_ obj, "can", &m, 1, 1);
    int ok = (r && SvTRUE(r)) ? 1 : 0;
    if (r) SvREFCNT_dec(r);
    return ok;
}

/* Install the `sitemap` keyword on this app. Idempotent: install_kw treats a
 * second install by the same owner as a no-op, so `use` and `plugin` can both
 * ask and only the first does anything. */
static void pks_install_kw(pTHX_ SV *app) {
    AV *cap = newAV();
    SV *argv[3], *r;
    av_push(cap, newSVsv(app));
    argv[0] = sv_2mortal(newSVpvs("sitemap"));
    argv[1] = sv_2mortal(punk_closure(aTHX_ pks_kw_cb, cap));
    argv[2] = sv_2mortal(newSVpvs("Punk::Plugin::Sitemap"));
    r = pcx_call_meth(aTHX_ app, "install_kw", argv, 3, 1);
    if (r) SvREFCNT_dec(r);
}

/* The to_app seam. Punk calls every registered middleware wrapper while it
 * compiles, which is the one moment every route has been declared and nothing
 * has been served - so the document is built there and the wrapper hands the
 * application back untouched. */
XS_INTERNAL(pks_mw_cb);
XS_INTERNAL(pks_mw_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *app = cap ? *av_fetch(cap, 0, 0) : NULL;
    if (app) pks_build(aTHX_ app);
    if (items > 0) XSRETURN(1);      /* ST(0) is the inner app, unchanged */
    XSRETURN_EMPTY;
}

#endif /* PUNK_SITEMAP_H */

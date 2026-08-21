/* punk_static.h - serving files from a directory.
 *
 * `static '/static' => 'root/static'` compiles to a PSGI coderef: a magic
 * CV carrying the directory it serves (the closure pattern Open::API's
 * oa_plack.h uses), whose whole request path is here - method check, the
 * traversal guard, stat, the conditional-request comparison and the header
 * block. The body is a real filehandle, so the server can stream or
 * sendfile it rather than slurping the file into memory.
 */

#ifndef PUNK_STATIC_H
#define PUNK_STATIC_H

/* ---- closures: a CV carrying captured SVs -------------------------------- */

typedef struct punk_clos { AV *cap; } punk_clos;

static int punk_clos_free(pTHX_ SV *sv, MAGIC *mg) {
    punk_clos *c = (punk_clos *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (c) { if (c->cap) SvREFCNT_dec((SV *)c->cap); Safefree(c); }
    return 0;
}
static MGVTBL punk_clos_vtbl = { NULL, NULL, NULL, NULL, punk_clos_free,
                                 NULL, NULL, NULL };

static SV *punk_closure(pTHX_ XSUBADDR_t body, AV *cap) {
    CV *cv = (CV *)newXS(NULL, body, __FILE__);
    punk_clos *c;
    Newxz(c, 1, punk_clos);
    c->cap = cap;                                   /* takes ownership */
    sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &punk_clos_vtbl, (char *)c, 0);
    return newRV_noinc((SV *)cv);
}

/* The same, but installed into a named glob rather than handed back as a
 * coderef: for keywords, where a croak or a stack trace should name the
 * keyword and the class it landed in rather than __ANON__. */
static CV *punk_closure_named(pTHX_ const char *name, XSUBADDR_t body, AV *cap)
    PERL_UNUSED_DECL;
static CV *punk_closure_named(pTHX_ const char *name, XSUBADDR_t body, AV *cap) {
    CV *cv = newXS((char *)name, body, (char *)__FILE__);
    punk_clos *c;
    Newxz(c, 1, punk_clos);
    c->cap = cap;                                   /* takes ownership */
    sv_magicext((SV *)cv, NULL, PERL_MAGIC_ext, &punk_clos_vtbl, (char *)c, 0);
    return cv;
}

static AV *punk_clos_cap(pTHX_ CV *cv) {
    MAGIC *mg = mg_findext((SV *)cv, PERL_MAGIC_ext, &punk_clos_vtbl);
    return mg ? ((punk_clos *)mg->mg_ptr)->cap : NULL;
}

/* ---- content types -------------------------------------------------------- */

static const char *ps_content_type(const char *path, STRLEN len) {
    static const struct { const char *ext; const char *type; } map[] = {
        { "html", "text/html; charset=utf-8" },
        { "htm",  "text/html; charset=utf-8" },
        { "css",  "text/css; charset=utf-8" },
        { "js",   "application/javascript; charset=utf-8" },
        { "mjs",  "application/javascript; charset=utf-8" },
        { "json", "application/json" },
        { "txt",  "text/plain; charset=utf-8" },
        { "xml",  "application/xml" },
        { "svg",  "image/svg+xml" },
        { "png",  "image/png" },
        { "jpg",  "image/jpeg" },
        { "jpeg", "image/jpeg" },
        { "gif",  "image/gif" },
        { "ico",  "image/x-icon" },
        { "webp", "image/webp" },
        { "avif", "image/avif" },
        { "woff", "font/woff" },
        { "woff2","font/woff2" },
        { "ttf",  "font/ttf" },
        { "otf",  "font/otf" },
        { "pdf",  "application/pdf" },
        { "wasm", "application/wasm" },
        { "map",  "application/json" },
        { "mp4",  "video/mp4" },
        { "webm", "video/webm" },
        { "mp3",  "audio/mpeg" },
        { "zip",  "application/zip" },
        { NULL, NULL }
    };
    const char *dot = NULL;
    STRLEN i;
    char ext[16];
    int n = 0;
    for (i = len; i > 0; i--) {
        if (path[i - 1] == '/') break;
        if (path[i - 1] == '.') { dot = path + i; break; }
    }
    if (!dot) return "application/octet-stream";
    /* index, not *dot++: toLOWER is a macro that evaluates its argument
     * more than once, so a side effect inside it runs more than once */
    while (dot + n < path + len && n < (int)sizeof(ext) - 1) {
        ext[n] = (char)toLOWER((U8)dot[n]);
        n++;
    }
    ext[n] = '\0';
    for (i = 0; map[i].ext; i++)
        if (strEQ(ext, map[i].ext)) return map[i].type;
    return "application/octet-stream";
}

/* ---- helpers -------------------------------------------------------------- */

/* An RFC 7231 IMF-fixdate, in C: strftime would drag the locale in, and
 * these names are fixed by the spec in any case. */
static void ps_http_date(char *out, size_t outlen, time_t when) {
    static const char *const days[]  = { "Sun","Mon","Tue","Wed","Thu",
                                         "Fri","Sat" };
    static const char *const months[] = { "Jan","Feb","Mar","Apr","May","Jun",
                                          "Jul","Aug","Sep","Oct","Nov","Dec" };
    struct tm tm;
#ifdef HAS_GMTIME_R
    gmtime_r(&when, &tm);
#else
    tm = *gmtime(&when);
#endif
    my_snprintf(out, outlen, "%s, %02d %s %04d %02d:%02d:%02d GMT",
                days[tm.tm_wday % 7], tm.tm_mday, months[tm.tm_mon % 12],
                tm.tm_year + 1900, tm.tm_hour, tm.tm_min, tm.tm_sec);
}

/* A short text response (405/404), built like any other triplet. */
static SV *ps_plain(pTHX_ IV status, const char *msg,
                    const char *hk, const char *hv) {
    AV *resp = newAV(), *headers = newAV(), *body = newAV();
    STRLEN len = strlen(msg);
    av_push(headers, newSVpvs("Content-Type"));
    av_push(headers, newSVpvs("text/plain; charset=utf-8"));
    av_push(headers, newSVpvs("Content-Length"));
    av_push(headers, newSViv((IV)len));
    if (hk) { av_push(headers, newSVpv(hk, 0)); av_push(headers, newSVpv(hv, 0)); }
    av_push(body, newSVpvn(msg, len));
    av_push(resp, newSViv(status));
    av_push(resp, newRV_noinc((SV *)headers));
    av_push(resp, newRV_noinc((SV *)body));
    return newRV_noinc((SV *)resp);
}

/* Any '..' segment, an absolute-looking escape or a NUL is a 404 rather
 * than something to normalise: a request that contains one is not asking
 * for a file we serve. */
static int ps_path_unsafe(const char *p, STRLEN len) {
    STRLEN i, seg = 0;
    if (memchr(p, '\0', len)) return 1;
    for (i = 0; i <= len; i++) {
        /* A backslash ends a segment too. On this side of the world it is an
         * ordinary filename byte and "..\.." traverses nothing, but Windows
         * reads it as a separator, so a guard that only splits on '/' sees one
         * harmless segment where the OS sees two levels up. Splitting on both
         * costs a comparison and does not depend on which platform the build
         * is for - the wrong place to find out is a port. */
        if (i == len || p[i] == '/' || p[i] == '\\') {
            STRLEN n = i - seg;
            if (n == 2 && p[seg] == '.' && p[seg + 1] == '.') return 1;
            seg = i + 1;
        }
    }
    return 0;
}

/* ---- serving one file ------------------------------------------------------
 * The stat / conditional-request / range / header / body half of a static
 * response, split out so the markdown mount can serve the images and other
 * assets sitting alongside its documents with exactly this behaviour rather
 * than a second implementation that drifts from it. Since 0.13 it is the
 * send_file decision core with a fixed option block - the implementation
 * lives in punk_sendfile.h (included right after this header), which is
 * what gives static files their ETag, 304-on-If-None-Match and 206/416
 * range answers; the If-Modified-Since exact-match convention is one
 * branch of that core.
 *
 * Returns the finished triplet (+1 owned), or NULL when `file` is not a
 * regular file or cannot be opened - the caller decides what its own 404
 * looks like. The path is used as given: the traversal guard belongs to
 * whoever built it out of untrusted input. */

/* What a caller may say about freshness. Borrowed, never owned. */
typedef struct ps_fopts {
    SV *cache_control;         /* the header value, or NULL for none   */
} ps_fopts;

static SV *ps_serve_file_opt(pTHX_ HV *env, const char *file, STRLEN flen,
                             int is_head, ps_fopts *fo);

/* The same with nothing to say about freshness - what a caller that has no
 * cache policy of its own (the markdown mount's assets) wants. */
static SV *ps_serve_file(pTHX_ HV *env, const char *file, STRLEN flen,
                         int is_head);

/* ---- the app ---------------------------------------------------------------
 * The PSGI coderef's body: a magic CV whose capture is the mount's whole
 * configuration. Everything a request needs happens here, with no Perl
 * frame at all. */

enum {
    PSC_DIR    = 0,   /* the directory served, no trailing slash          */
    PSC_CC     = 1,   /* Cache-Control for a plain URL, or undef          */
    PSC_CC_IMM = 2,   /* ... and for a URL whose digest checked out       */
    PSC_CACHE  = 3,   /* the digest cache (hashref), or undef: no         */
                      /* fingerprinting on this mount                    */
    PSC_DEV    = 4    /* re-stat cached digests (development)             */
};

static SV *psc_cap(pTHX_ AV *cap, int slot) {
    SV **s = av_fetch(cap, slot, 0);
    return (s && *s && SvOK(*s)) ? *s : NULL;
}

XS_INTERNAL(punk_static_cb);
XS_INTERNAL(punk_static_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *dirsv, *cachesv;
    HV *env;
    SV **e;
    const char *dir, *path, *method;
    STRLEN dlen, plen, mlen = 3, flen;
    char file[MAXPATHLEN + 1];
    SV *resp;
    ps_fopts fo;
    int is_head = 0;

    if (!cap || items < 1) XSRETURN_EMPTY;
    dirsv = *av_fetch(cap, 0, 0);
    dir   = SvPV_const(dirsv, dlen);
    Zero(&fo, 1, ps_fopts);
    fo.cache_control = psc_cap(aTHX_ cap, PSC_CC);
    cachesv = psc_cap(aTHX_ cap, PSC_CACHE);

    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVHV)
        croak("Punk::Static: the app takes a PSGI env hashref");
    env = (HV *)SvRV(ST(0));

    e = hv_fetchs(env, "REQUEST_METHOD", 0);
    method = (e && *e && SvOK(*e)) ? SvPV_const(*e, mlen) : "GET";
    if (mlen == 4 && memEQ(method, "HEAD", 4)) is_head = 1;
    else if (!(mlen == 3 && memEQ(method, "GET", 3))) {
        ST(0) = sv_2mortal(ps_plain(aTHX_ 405, "Method Not Allowed",
                                    "Allow", "GET, HEAD"));
        XSRETURN(1);
    }

    e = hv_fetchs(env, "PATH_INFO", 0);
    if (e && *e && SvOK(*e)) path = SvPV_const(*e, plen);
    else { path = "/"; plen = 1; }

    if (ps_path_unsafe(path, plen) || dlen + plen > MAXPATHLEN) {
        ST(0) = sv_2mortal(ps_plain(aTHX_ 404, "Not Found", NULL, NULL));
        XSRETURN(1);
    }
    memcpy(file, dir, dlen);
    memcpy(file + dlen, path, plen);
    file[dlen + plen] = '\0';
    flen = dlen + plen;

    /* A content-addressed URL: `/app.9f3a1c2b0d4e5f60.css` is the file
     * `/app.css`, and gets a year plus `immutable` when the digest it names
     * is the digest that file now has.
     *
     * The literal path is tried first, so a file genuinely called
     * `app.9f3a1c2b0d4e5f60.css` - a build tool's output, checked in under
     * that name - still serves as itself. That costs one extra stat, and
     * only on a request whose path parses as fingerprinted. */
    if (cachesv && SvROK(cachesv) && SvTYPE(SvRV(cachesv)) == SVt_PVHV) {
        char base[MAXPATHLEN + 1], digest[PA_DIGEST_LEN + 1];
        STRLEN blen;
        Stat_t st;
        if ((blen = pa_defingerprint(file, flen, base, digest)) != 0
            && (PerlLIO_stat(file, &st) < 0 || !S_ISREG(st.st_mode))) {
            SV *have = pa_digest_cached(aTHX_ (HV *)SvRV(cachesv), base, blen,
                                        psc_cap(aTHX_ cap, PSC_DEV) ? 1 : 0);
            memcpy(file, base, blen + 1);
            flen = blen;
            /* A digest that does not match is a URL from an older deploy:
             * the current bytes are still the right answer, but `immutable`
             * would be a lie about a URL whose meaning has already changed
             * once. It revalidates instead. */
            if (have && SvCUR(have) == PA_DIGEST_LEN
                && memEQ(SvPVX(have), digest, PA_DIGEST_LEN))
                fo.cache_control = psc_cap(aTHX_ cap, PSC_CC_IMM);
        }
    }

    resp = ps_serve_file_opt(aTHX_ env, file, flen, is_head, &fo);
    if (!resp) resp = ps_plain(aTHX_ 404, "Not Found", NULL, NULL);
    ST(0) = sv_2mortal(resp);
    XSRETURN(1);
}

/* ---- the other direction: naming a file ------------------------------------
 * Given a static mount's coderef and a path within it, the content-addressed
 * URL for that path: `/app.css` -> `/app.9f3a1c2b0d4e5f60.css`. NULL when
 * this mount does not fingerprint, when the path has no extension to put a
 * digest in front of, or when the file cannot be read - in every one of
 * those the caller wants the URL it already had, which still works. */
static SV *pa_asset_url(pTHX_ SV *appsv, SV *relsv) {
    CV *appcv;
    AV *cap;
    SV *cachesv, *digest;
    const char *dir, *rel;
    STRLEN dlen, rlen;
    char file[MAXPATHLEN + 1];

    if (!(appsv && SvROK(appsv) && SvTYPE(SvRV(appsv)) == SVt_PVCV))
        return NULL;
    appcv = (CV *)SvRV(appsv);
    cap   = punk_clos_cap(aTHX_ appcv);
    if (!cap) return NULL;                    /* not one of our closures */
    cachesv = psc_cap(aTHX_ cap, PSC_CACHE);
    if (!(cachesv && SvROK(cachesv) && SvTYPE(SvRV(cachesv)) == SVt_PVHV))
        return NULL;

    dir = SvPV_const(*av_fetch(cap, PSC_DIR, 0), dlen);
    rel = SvPV_const(relsv, rlen);
    if (!rlen || rel[0] != '/') return NULL;
    if (ps_path_unsafe(rel, rlen) || dlen + rlen > MAXPATHLEN) return NULL;
    memcpy(file, dir, dlen);
    memcpy(file + dlen, rel, rlen);
    file[dlen + rlen] = '\0';

    digest = pa_digest_cached(aTHX_ (HV *)SvRV(cachesv), file, dlen + rlen,
                              psc_cap(aTHX_ cap, PSC_DEV) ? 1 : 0);
    if (!digest || SvCUR(digest) != PA_DIGEST_LEN) return NULL;
    return pa_fingerprint(aTHX_ rel, rlen, SvPVX(digest));
}

/* $c->asset's half: the compiled mount table, longest prefix first (compile
 * sorted it), and the first static mount whose prefix this URL sits under
 * gets to name it. A URL under no static mount, or under one that does not
 * fingerprint, comes back unchanged. */
static SV *pa_asset_for(pTHX_ AV *mounts, SV *url) {
    SSize_t i, n;
    STRLEN ulen;
    const char *u = SvPV_const(url, ulen);
    if (!mounts) return NULL;
    n = av_len(mounts) + 1;
    for (i = 0; i < n; i++) {
        SV **mp = av_fetch(mounts, i, 0);
        HV *m;
        SV **pp, **ap;
        STRLEN pl;
        const char *p;
        if (!(mp && *mp && SvROK(*mp))) continue;
        m  = (HV *)SvRV(*mp);
        pp = hv_fetchs(m, K_PREFIX, 0);
        ap = hv_fetchs(m, K_APP, 0);
        if (!(pp && *pp && ap && *ap)) continue;
        p = SvPV_const(*pp, pl);
        if (ulen <= pl || memNE(u, p, pl) || u[pl] != '/') continue;
        {
            /* the first prefix match decides, even when it declines: a
             * shorter mount further down would resolve this path against a
             * different directory, and dispatch would never send the
             * request there anyway */
            SV *rel = sv_2mortal(newSVpvn(u + pl, ulen - pl));
            SV *fp  = pa_asset_url(aTHX_ *ap, rel);
            SV *out;
            if (!fp) return NULL;
            out = newSVpvn(p, pl);
            sv_catsv(out, fp);
            SvREFCNT_dec(fp);
            return out;
        }
    }
    return NULL;
}

/* The same thing as a template filter - `{% "/static/app.css" | asset %}` -
 * so a layout can name an asset without the handler having to pass the URL
 * in. A magic CV over the application, registered on the shipped Stencil
 * engine at boot; the mount table is read at call time, so it does not
 * matter that the views are compiled before the mounts.
 *
 * The captured application is a WEAK reference: the app owns the view
 * registry, which owns the engine, which owns this filter, and a strong
 * one would close that loop and keep the whole application alive forever. */
XS_INTERNAL(pa_asset_filter_cb);
XS_INTERNAL(pa_asset_filter_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *app, *out = NULL;

    if (!cap || items < 1) XSRETURN_EMPTY;
    app = *av_fetch(cap, 0, 0);
    if (app && SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV) {
        SV *mp = app_get(aTHX_ (HV *)SvRV(app), K_MOUNTS_C);
        if (mp && SvROK(mp) && SvTYPE(SvRV(mp)) == SVt_PVAV)
            out = pa_asset_for(aTHX_ (AV *)SvRV(mp), ST(0));
    }
    if (out) ST(0) = sv_2mortal(out);
    XSRETURN(1);
}

static SV *pa_asset_filter(pTHX_ SV *app) {
    AV *cap = newAV();
    SV *weak = newSVsv(app);
    sv_rvweaken(weak);
    av_push(cap, weak);
    return punk_closure(aTHX_ pa_asset_filter_cb, cap);
}

#endif /* PUNK_STATIC_H */

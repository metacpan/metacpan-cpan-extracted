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
        if (i == len || p[i] == '/') {
            STRLEN n = i - seg;
            if (n == 2 && p[seg] == '.' && p[seg + 1] == '.') return 1;
            seg = i + 1;
        }
    }
    return 0;
}

/* ---- serving one file ------------------------------------------------------
 * The stat / conditional-request / header / body half of a static response,
 * split out so the markdown mount can serve the images and other assets
 * sitting alongside its documents with exactly this behaviour rather than a
 * second implementation that drifts from it.
 *
 * Returns the finished triplet (+1 owned), or NULL when `file` is not a
 * regular file or cannot be opened - the caller decides what its own 404
 * looks like. The path is used as given: the traversal guard belongs to
 * whoever built it out of untrusted input. */

static SV *ps_serve_file(pTHX_ HV *env, const char *file, STRLEN flen,
                         int is_head) {
    Stat_t st;
    char date[64];
    SV **e;

    if (PerlLIO_stat(file, &st) < 0 || !S_ISREG(st.st_mode)) return NULL;
    ps_http_date(date, sizeof date, (time_t)st.st_mtime);

    /* If-Modified-Since: an exact match is all a static file needs - the
     * date we would send is the date they were given. */
    e = env ? hv_fetchs(env, "HTTP_IF_MODIFIED_SINCE", 0) : NULL;
    if (e && *e && SvOK(*e) && strEQ(SvPV_nolen(*e), date)) {
        AV *resp = newAV(), *headers = newAV(), *body = newAV();
        av_push(headers, newSVpvs("Last-Modified"));
        av_push(headers, newSVpv(date, 0));
        av_push(body, newSVpvs(""));
        av_push(resp, newSViv(304));
        av_push(resp, newRV_noinc((SV *)headers));
        av_push(resp, newRV_noinc((SV *)body));
        return newRV_noinc((SV *)resp);
    }

    {
        AV *resp = newAV(), *headers = newAV();
        av_push(headers, newSVpvs("Content-Type"));
        av_push(headers, newSVpv(ps_content_type(file, flen), 0));
        av_push(headers, newSVpvs("Content-Length"));
        av_push(headers, newSViv((IV)st.st_size));
        av_push(headers, newSVpvs("Last-Modified"));
        av_push(headers, newSVpv(date, 0));
        av_push(resp, newSViv(200));
        av_push(resp, newRV_noinc((SV *)headers));

        if (is_head) {                        /* the headers, no body */
            AV *body = newAV();
            av_push(body, newSVpvs(""));
            av_push(resp, newRV_noinc((SV *)body));
        }
        else {
            /* a real filehandle: the server streams or sendfiles it rather
             * than us slurping the file into memory */
            PerlIO *fp = PerlIO_open(file, "rb");
            GV *gv;
            IO *io;
            if (!fp) {
                SvREFCNT_dec((SV *)resp);
                return NULL;
            }
            gv = newGVgen("Punk::Static");
            io = GvIOn(gv);
            IoIFP(io)  = fp;
            IoTYPE(io) = IoTYPE_RDONLY;
            av_push(resp, newRV_inc((SV *)gv));
        }
        return newRV_noinc((SV *)resp);
    }
}

/* ---- the app ---------------------------------------------------------------
 * The PSGI coderef's body: a magic CV whose capture is [ $dir ]. Everything
 * a request needs happens here, with no Perl frame at all. */

XS_INTERNAL(punk_static_cb);
XS_INTERNAL(punk_static_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV *dirsv;
    HV *env;
    SV **e;
    const char *dir, *path, *method;
    STRLEN dlen, plen, mlen = 3;
    char file[MAXPATHLEN + 1];
    SV *resp;
    int is_head = 0;

    if (!cap || items < 1) XSRETURN_EMPTY;
    dirsv = *av_fetch(cap, 0, 0);
    dir   = SvPV_const(dirsv, dlen);

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

    resp = ps_serve_file(aTHX_ env, file, dlen + plen, is_head);
    if (!resp) resp = ps_plain(aTHX_ 404, "Not Found", NULL, NULL);
    ST(0) = sv_2mortal(resp);
    XSRETURN(1);
}

#endif /* PUNK_STATIC_H */

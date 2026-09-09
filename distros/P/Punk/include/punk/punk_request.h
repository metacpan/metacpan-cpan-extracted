/* punk_request.h - C request parsing (the Punk::Request hot methods).
 *
 * The object is a plain blessed AV whose slot layout is shared with
 * lib/Punk/Request.pm (the pure-Perl reference tier) - keep the enum
 * below in sync with the constants there. Parsing semantics mirror the
 * Perl exactly: pairs split on '&'/';', keys split on the first '=',
 * '+' and %XX percent-decoding, repeated keys promote to arrayrefs,
 * cookie values decode with first-value-wins. body() stays Perl (I/O);
 * form() calls it through the method interface once, then caches.
 */

#ifndef PUNK_REQUEST_H
#define PUNK_REQUEST_H

enum {
    PQ_ENV     = 0,
    PQ_QUERY   = 1,
    PQ_FORM    = 2,
    PQ_COOKIES = 3,
    PQ_BODY    = 4,
    PQ_READ    = 5,
    PQ_UPLOADS = 6,
    PQ_TEMPFILES = 7,  /* spilled upload paths, removed when the request ends */
    PQ_XML     = 8     /* the body parsed as XML, once per request */
};

static AV *punk_req_av(pTHX_ SV *self) {
    if (!SvROK(self) || SvTYPE(SvRV(self)) != SVt_PVAV)
        croak("Punk::Request: not a request object");
    return (AV *)SvRV(self);
}

static HV *punk_req_env(pTHX_ AV *req) {
    SV **e = av_fetch(req, PQ_ENV, 0);
    if (!e || !*e || !SvROK(*e) || SvTYPE(SvRV(*e)) != SVt_PVHV)
        croak("Punk::Request: no PSGI environment");
    return (HV *)SvRV(*e);
}

/* Every request header, as a hash keyed the way HTTP/2 and most Perl web
 * code spell them: HTTP_X_FORWARDED_FOR -> 'x-forwarded-for', lowercased
 * with dashes. CONTENT_TYPE is folded in because PSGI stores it (and
 * CONTENT_LENGTH) without the HTTP_ prefix, so a caller walking HTTP_*
 * alone would silently miss it.
 *
 * content-length is deliberately left to the caller: Punk::Request takes it
 * from the environment, while the OpenAPI validation path takes the length
 * it actually read off psgi.input, which is the one the body was framed by.
 *
 * Owned (+1). */
static HV *pq_headers(pTHX_ HV *env) {
    HV *out = newHV();
    HE *he;
    SV **e;
    if (!env) return out;

    hv_iterinit(env);
    while ((he = hv_iternext(env))) {
        I32 kl;
        const char *k = hv_iterkey(he, &kl);
        char stackbuf[64], *lname;
        STRLEN nl, i;
        if (!(kl > 5 && memEQ(k, "HTTP_", 5))) continue;
        nl = (STRLEN)(kl - 5);
        lname = nl < sizeof stackbuf ? stackbuf : (char *)safemalloc(nl);
        for (i = 0; i < nl; i++) {
            char c = k[5 + i];
            lname[i] = (c == '_') ? '-' : (char)toLOWER((U8)c);
        }
        (void)hv_store(out, lname, (I32)nl,
                       newSVsv(hv_iterval(env, he)), 0);
        if (lname != stackbuf) safefree(lname);
    }

    e = hv_fetchs(env, "CONTENT_TYPE", 0);
    if (e && *e && SvOK(*e)) {
        STRLEN vl;
        (void)SvPV_const(*e, vl);      /* not SvCUR: it may not be a PV yet */
        if (vl) (void)hv_stores(out, "content-type", newSVsv(*e));
    }
    return out;
}

/* %XX / '+' decode of [s, s+len) into a fresh SV (owned). */
static SV *pq_decode(pTHX_ const char *s, STRLEN len) {
    SV *out = newSV(len + 1);
    char *d;
    STRLEN i, o = 0;
    SvPOK_on(out);
    d = SvPVX(out);
    for (i = 0; i < len; i++) {
        char c = s[i];
        if (c == '+') d[o++] = ' ';
        else if (c == '%' && i + 2 < len
                 && isXDIGIT((U8)s[i + 1]) && isXDIGIT((U8)s[i + 2])) {
            unsigned hi = isDIGIT((U8)s[i+1]) ? (unsigned)(s[i+1] - '0')
                        : (unsigned)((s[i+1] | 0x20) - 'a' + 10);
            unsigned lo = isDIGIT((U8)s[i+2]) ? (unsigned)(s[i+2] - '0')
                        : (unsigned)((s[i+2] | 0x20) - 'a' + 10);
            d[o++] = (char)((hi << 4) | lo);
            i += 2;
        }
        else d[o++] = c;
    }
    d[o] = '\0';
    SvCUR_set(out, o);
    return out;
}

/* One decoded pair into the hash, promoting repeats to an arrayref. */
static void pq_store_pair(pTHX_ HV *out,
                          const char *k, STRLEN kl,
                          const char *v, STRLEN vl) {
    SV *key = sv_2mortal(pq_decode(aTHX_ k, kl));
    SV *val = pq_decode(aTHX_ v, vl);
    HE *he  = hv_fetch_ent(out, key, 0, 0);
    if (he) {
        SV *have = HeVAL(he);
        AV *list;
        if (SvROK(have) && SvTYPE(SvRV(have)) == SVt_PVAV)
            list = (AV *)SvRV(have);
        else {
            list = newAV();
            av_push(list, newSVsv(have));
            (void)hv_store_ent(out, key, newRV_noinc((SV *)list), 0);
        }
        av_push(list, val);
    }
    else (void)hv_store_ent(out, key, val, 0);
}

/* application/x-www-form-urlencoded pairs -> owned HV. */
static HV *pq_parse_pairs(pTHX_ const char *s, STRLEN len) {
    HV *out = newHV();
    STRLEN start = 0, i;
    for (i = 0; i <= len; i++) {
        if (i == len || s[i] == '&' || s[i] == ';') {
            if (i > start) {
                const char *pair = s + start;
                STRLEN plen = i - start, j, eq = plen;
                for (j = 0; j < plen; j++)
                    if (pair[j] == '=') { eq = j; break; }
                pq_store_pair(aTHX_ out, pair, eq,
                              eq < plen ? pair + eq + 1 : "",
                              eq < plen ? plen - eq - 1 : 0);
            }
            start = i + 1;
        }
    }
    return out;
}

/* The Cookie header -> owned HV; first value wins, values decoded. */
static HV *pq_parse_cookies(pTHX_ const char *s, STRLEN len) {
    HV *out = newHV();
    STRLEN start = 0, i;
    for (i = 0; i <= len; i++) {
        if (i == len || s[i] == ';') {
            if (i > start) {
                const char *pair = s + start;
                STRLEN plen = i - start, j, eq = plen;
                for (j = 0; j < plen; j++)
                    if (pair[j] == '=') { eq = j; break; }
                if (eq > 0) {
                    SV *key = sv_2mortal(newSVpvn(pair, eq));
                    if (!hv_exists_ent(out, key, 0)) {
                        SV *val = eq < plen
                            ? pq_decode(aTHX_ pair + eq + 1, plen - eq - 1)
                            : newSVpvs("");
                        (void)hv_store_ent(out, key, val, 0);
                    }
                }
            }
            start = i + 1;
            /* Perl splits on semicolon-plus-whitespace: eat the spaces */
            while (start < len && isSPACE((U8)s[start])) start++;
            i = start - 1;
        }
    }
    return out;
}

/* Cached-slot access: return the slot's hashref, building it with
 * `build` on first use. The returned SV is the live cached ref. */
static SV *pq_cached(pTHX_ AV *req, I32 slot, HV *built) {
    SV *rv = newRV_noinc((SV *)built);
    (void)av_store(req, slot, rv);
    return rv;
}

/* The query or form table, built through the accessor of that name on
 * first use so the parse lands in the slot exactly once. Borrowed, or
 * NULL when the accessor gave back something that is not a hashref. */
static HV *pq_table(pTHX_ SV *self, AV *req, I32 slot, const char *meth) {
    SV **c = av_fetch(req, slot, 0);
    if (!(c && *c && SvROK(*c))) {
        dSP;
        PUSHMARK(SP); XPUSHs(self); PUTBACK;
        call_method(meth, G_SCALAR);
        SPAGAIN; (void)POPs; PUTBACK;
        c = av_fetch(req, slot, 0);
    }
    return (c && *c && SvROK(*c) && SvTYPE(SvRV(*c)) == SVt_PVHV)
        ? (HV *)SvRV(*c) : NULL;
}

/* One parameter: query first, then form body. Borrowed, NULL when the
 * name is in neither - which the callers keep distinct from a present
 * undef, so params(@keys) can leave an absent key out of its hash. */
static SV *pq_param_get(pTHX_ SV *self, AV *req, SV *name) {
    HV *t  = pq_table(aTHX_ self, req, PQ_QUERY, "query");
    HE *he = t ? hv_fetch_ent(t, name, 0, 0) : NULL;
    if (!he) {
        t  = pq_table(aTHX_ self, req, PQ_FORM, "form");
        he = t ? hv_fetch_ent(t, name, 0, 0) : NULL;
    }
    return he ? HeVAL(he) : NULL;
}

/* Copy every pair of `src` over `out`, so a caller can stack tables in
 * precedence order. NULL sources are skipped. */
static void pq_overlay_hv(pTHX_ HV *out, HV *src) {
    HE *he;
    if (!src) return;
    hv_iterinit(src);
    while ((he = hv_iternext(src)))
        (void)hv_store_ent(out, HeSVKEY_force(he), newSVsv(HeVAL(he)), 0);
}

/* The same, taking whatever an accessor returned: anything that is not a
 * hashref overlays nothing. */
static void pq_overlay(pTHX_ HV *out, SV *src) {
    if (src && SvROK(src) && SvTYPE(SvRV(src)) == SVt_PVHV)
        pq_overlay_hv(aTHX_ out, (HV *)SvRV(src));
}

/* What has become of the body: PQ_UNREAD, PQ_SLURPED (cached whole in
 * PQ_BODY, the ->body semantics), or PQ_STREAMED (handed to a caller a chunk
 * at a time and gone). The third state exists so that reading the body twice
 * is an error somebody sees rather than an empty string somebody ships. */
#define PQ_UNREAD   0
#define PQ_SLURPED  1
#define PQ_STREAMED 2

static IV pq_read_state(pTHX_ AV *req) {
    SV **flag = av_fetch(req, PQ_READ, 0);
    return (flag && *flag && SvOK(*flag)) ? SvIV(*flag) : PQ_UNREAD;
}

/* The raw request body: read CONTENT_LENGTH bytes from psgi.input via
 * PerlIO on first call (then rewind, matching the Perl semantics),
 * cache in the BODY slot. Returns the cached SV (borrowed) - undef SV
 * when there is no body. sv_2io croaks on a non-handle the same way
 * the read builtin would. */
static SV *pq_body(pTHX_ AV *req) {
    SV **flag = av_fetch(req, PQ_READ, 0);
    SV **b;
    if (pq_read_state(aTHX_ req) == PQ_STREAMED)
        croak("Punk::Request: the body was streamed and is gone - a body "
              "can be read once, either whole (body/json/form) or in chunks "
              "(body_each/body_to)");
    if (!(flag && *flag && SvTRUE(*flag))) {
        HV *env = punk_req_env(aTHX_ req);
        SV **in = hv_fetchs(env, "psgi.input", 0);
        SV **cl = hv_fetchs(env, "CONTENT_LENGTH", 0);
        IV len  = (cl && *cl && SvOK(*cl)) ? SvIV(*cl) : 0;
        (void)av_store(req, PQ_READ, newSViv(1));
        if (in && *in && SvTRUE(*in) && len > 0) {
            IO *io = sv_2io(*in);
            PerlIO *fp = io ? IoIFP(io) : NULL;
            if (fp) {
                SV *raw = newSV(len + 1);
                char *d;
                IV got = 0;
                SvPOK_on(raw);
                d = SvPVX(raw);
                while (got < len) {
                    SSize_t n = PerlIO_read(fp, d + got, (Size_t)(len - got));
                    if (n <= 0) break;
                    got += (IV)n;
                }
                d[got] = '\0';
                SvCUR_set(raw, (STRLEN)got);
                (void)PerlIO_seek(fp, 0, SEEK_SET);
                (void)av_store(req, PQ_BODY, raw);
            }
            else (void)av_store(req, PQ_BODY, newSV(0));
        }
        else (void)av_store(req, PQ_BODY, newSV(0));
    }
    b = av_fetch(req, PQ_BODY, 0);
    return b && *b ? *b : &PL_sv_undef;
}

/* ---- the body, a chunk at a time ------------------------------------------
 *
 * ->body copies the whole request into one scalar. That is right for JSON and
 * wrong for anything large: the server is already holding the bytes, and the
 * copy doubles them for as long as the handler runs. The multipart parser has
 * read the handle in chunks since uploads landed; this is the same window for
 * a body that is not multipart - an import, an octet-stream PUT, an NDJSON
 * feed - and the seam a server that drips the body in would arrive through.
 *
 * The sink returns 0 to carry on and non-zero to stop (which only the byte
 * ceiling does).
 */
typedef int (*pq_sink_fn)(pTHX_ void *ud, const char *buf, STRLEN len);

#define PQ_STREAM_CHUNK 65536

/* Feed a cached body through the sink: what happens when the body was already
 * read whole. The bytes are here, so serving them costs nothing and the
 * caller does not have to care which happened. */
static IV pq_stream_cached(pTHX_ SV *body, STRLEN chunk, pq_sink_fn sink,
                           void *ud) {
    STRLEN len, off = 0;
    const char *p;
    if (!body || !SvOK(body)) return 0;
    p = SvPV_const(body, len);
    while (off < len) {
        STRLEN n = len - off;
        if (n > chunk) n = chunk;
        if (sink(aTHX_ ud, p + off, n)) break;
        off += n;
    }
    return (IV)off;
}

/* Read the body off psgi.input in `chunk` byte windows, handing each to the
 * sink. Returns the number of bytes read.
 *
 * With a CONTENT_LENGTH exactly that many bytes are read, which is what PSGI
 * requires of an application.
 *
 * Without one, what happens turns on Transfer-Encoding, because that is what
 * decides whether there is a body at all. A request with neither header has
 * none, and this reads nothing - it does NOT go looking, which would turn an
 * ordinary bodyless POST into an error. A chunked request has a body of
 * unknown length, and that one is read to EOF - but only when the server says
 * its input is buffered, since reading to EOF on a live socket is how an
 * application hangs, and refusing with a reason beats hanging.
 *
 * `max` (0 for none) stops the read and croaks. It is the only ceiling there
 * is once no length was declared, which is exactly when max_body had nothing
 * to check either.
 */
static IV pq_body_stream(pTHX_ AV *req, STRLEN chunk, IV max,
                         pq_sink_fn sink, void *ud) {
    HV *env;
    SV **in, **cl, **buf;
    IV len, got = 0;
    IO *io;
    PerlIO *fp;
    SV *window;
    char *w;

    if (!chunk) chunk = PQ_STREAM_CHUNK;

    switch (pq_read_state(aTHX_ req)) {
    case PQ_STREAMED:
        croak("Punk::Request: the body was streamed and is gone - a body "
              "can be read once, either whole (body/json/form) or in chunks "
              "(body_each/body_to)");
    case PQ_SLURPED: {
        SV **b = av_fetch(req, PQ_BODY, 0);
        return pq_stream_cached(aTHX_ (b && *b) ? *b : NULL, chunk, sink, ud);
    }
    default: break;
    }

    env = punk_req_env(aTHX_ req);
    in  = hv_fetchs(env, "psgi.input", 0);
    cl  = hv_fetchs(env, "CONTENT_LENGTH", 0);
    len = (cl && *cl && SvOK(*cl)) ? SvIV(*cl) : -1;

    if (len < 0) {
        SV **te = hv_fetchs(env, "HTTP_TRANSFER_ENCODING", 0);
        if (!(te && *te && SvOK(*te) && SvCUR(*te))) {
            /* no length and no transfer coding: the request has no body */
            (void)av_store(req, PQ_READ, newSViv(PQ_STREAMED));
            return 0;
        }
        buf = hv_fetchs(env, "psgix.input.buffered", 0);
        if (!(buf && *buf && SvTRUE(*buf)))
            croak("Punk::Request: a chunked body with no CONTENT_LENGTH, and "
                  "this server does not declare psgix.input.buffered - there "
                  "is no length to read to and reading to EOF on a live "
                  "socket would hang");
    }

    /* the state changes before the first read: a sink that dies halfway
     * through has still consumed the input, and the next reader must be told
     * so rather than handed the remainder */
    (void)av_store(req, PQ_READ, newSViv(PQ_STREAMED));

    if (!(in && *in && SvTRUE(*in)) || len == 0) return 0;
    io = sv_2io(*in);
    fp = io ? IoIFP(io) : NULL;
    if (!fp) return 0;

    window = sv_2mortal(newSV(chunk + 1));
    SvPOK_on(window);
    w = SvPVX(window);

    while (len < 0 || got < len) {
        STRLEN want = chunk;
        SSize_t n;
        if (len >= 0 && (IV)want > len - got) want = (STRLEN)(len - got);
        n = PerlIO_read(fp, w, want);
        if (n <= 0) break;
        got += (IV)n;
        if (max && got > max)
            croak("Punk::Request: the request body passed %" IVdf " bytes, "
                  "the ceiling this read was given", max);
        if (sink(aTHX_ ud, w, (STRLEN)n)) break;
    }
    return got;
}

/* the two sinks: a Perl callback, and a handle */

typedef struct { SV *cb; SV *self; } pq_sink_cb_ud;

static int pq_sink_cb(pTHX_ void *ud, const char *buf, STRLEN len) {
    pq_sink_cb_ud *s = (pq_sink_cb_ud *)ud;
    dSP;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, 2);
    /* a fresh scalar per chunk: a callback that keeps one must be able to,
     * which a reused buffer would quietly break */
    PUSHs(sv_2mortal(newSVpvn(buf, len)));
    PUSHs(s->self);
    PUTBACK;
    (void)call_sv(s->cb, G_VOID | G_DISCARD);
    SPAGAIN;
    PUTBACK; FREETMPS; LEAVE;
    return 0;
}

/* body_to's handle, owned by the savestack for as long as the read runs */
typedef struct { PerlIO *fp; int open; } pq_out;

static void pq_out_cleanup(pTHX_ void *p) {
    pq_out *o = (pq_out *)p;
    if (o->open) { (void)PerlIO_close(o->fp); o->open = 0; }
}

static int pq_sink_io(pTHX_ void *ud, const char *buf, STRLEN len) {
    PerlIO *out = (PerlIO *)ud;
    STRLEN off = 0;
    while (off < len) {
        SSize_t n = PerlIO_write(out, buf + off, len - off);
        if (n <= 0) croak("Punk::Request: writing the body failed: %s",
                          Strerror(errno));
        off += (STRLEN)n;
    }
    return 0;
}

#endif /* PUNK_REQUEST_H */

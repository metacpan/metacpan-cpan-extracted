/* punk_sendfile.h - $c->send_file: downloads with validators and ranges.
 *
 * One decision core (psf_respond) turns a source - a file path or an
 * in-memory SV - plus the request's validator and Range headers into a
 * finished PSGI triplet: 200, 206 with Content-Range, 304, or 416. A 206
 * from a file rides Punk::SendFile::Reader, a bounded getline/close body,
 * so the range is byte-correct on any PSGI server without trusting it to
 * stop at Content-Length on a filehandle; a full-file 200 stays a real
 * glob, the Punk::Static convention. The path is used as given - the
 * traversal guard belongs to whoever built it out of untrusted input.
 */

#ifndef PUNK_SENDFILE_H
#define PUNK_SENDFILE_H

/* ---- Range: bytes=first-last / bytes=-suffix ------------------------------
 * Single range only. RFC 9110 lets a server ignore any Range header, so a
 * multi-range set, another unit or a malformed value is IGNORE (the full
 * 200); a syntactically valid range past the end is UNSAT (416). An
 * invalid spec (last < first) makes the header invalid: IGNORE, per the
 * RFC's "MUST ignore", not 416. */

enum {
    PSF_RANGE_NONE   = 0,   /* no Range header                      */
    PSF_RANGE_OK     = 1,   /* one satisfiable range in *off / *n   */
    PSF_RANGE_UNSAT  = 2,   /* valid but unsatisfiable: 416         */
    PSF_RANGE_IGNORE = 3    /* malformed or multi-range: full 200   */
};

/* 1*DIGIT into a UV; 1 ok, 0 no digits, -1 overflow. */
static int psf_digits(const char **pp, const char *end, UV *out) {
    const char *p = *pp;
    UV acc = 0;
    int any = 0;
    while (p < end && *p >= '0' && *p <= '9') {
        UV d = (UV)(*p - '0');
        if (acc > (UV_MAX - d) / 10) return -1;
        acc = acc * 10 + d;
        any = 1;
        p++;
    }
    if (!any) return 0;
    *pp = p;
    *out = acc;
    return 1;
}

static int psf_parse_range(const char *v, STRLEN len, UV size,
                           UV *off, UV *n) {
    const char *p = v, *end = v + len;
    static const char unit[5] = { 'b','y','t','e','s' };
    UV first = 0, last = 0;
    int have_last = 0, i, r;

    while (p < end && (*p == ' ' || *p == '\t')) p++;
    if (end - p < 6) return PSF_RANGE_IGNORE;
    for (i = 0; i < 5; i++)
        if (toLOWER((U8)p[i]) != unit[i]) return PSF_RANGE_IGNORE;
    if (p[5] != '=') return PSF_RANGE_IGNORE;
    p += 6;

    if (p < end && *p == '-') {                      /* suffix: -N */
        p++;
        if (psf_digits(&p, end, &first) != 1) return PSF_RANGE_IGNORE;
        while (p < end && (*p == ' ' || *p == '\t')) p++;
        if (p != end) return PSF_RANGE_IGNORE;       /* comma: multi-range */
        if (first == 0 || size == 0) return PSF_RANGE_UNSAT;
        if (first > size) first = size;
        *off = size - first;
        *n   = first;
        return PSF_RANGE_OK;
    }

    r = psf_digits(&p, end, &first);
    if (r != 1 || p >= end || *p != '-') return PSF_RANGE_IGNORE;
    p++;
    if (p < end && *p >= '0' && *p <= '9') {
        if (psf_digits(&p, end, &last) != 1) return PSF_RANGE_IGNORE;
        have_last = 1;
    }
    while (p < end && (*p == ' ' || *p == '\t')) p++;
    if (p != end) return PSF_RANGE_IGNORE;           /* comma or junk */
    if (have_last && last < first) return PSF_RANGE_IGNORE;
    if (first >= size) return PSF_RANGE_UNSAT;       /* covers size == 0 */
    if (!have_last || last > size - 1) last = size - 1;
    *off = first;
    *n   = last - first + 1;
    return PSF_RANGE_OK;
}

/* ---- validators ------------------------------------------------------------
 * The ETag is strong and nginx-shaped: "<hex mtime>-<hex size>". */

static void psf_etag(char *out, size_t outlen, UV mtime, UV size) {
    my_snprintf(out, outlen, "\"%" UVxf "-%" UVxf "\"", mtime, size);
}

/* Is `etag` in a comma-separated entity-tag list (If-None-Match)? Weak
 * comparison: a W/ prefix on a list entry is skipped. An entity-tag may
 * legally contain a comma, but a split fragment of one can never carry
 * both quotes, so it can never falsely equal our fully quoted tag. */
static int psf_etag_in(const char *h, STRLEN hlen,
                       const char *etag, STRLEN elen) {
    const char *p = h, *end = h + hlen;
    while (p < end) {
        const char *e;
        while (p < end && (*p == ' ' || *p == '\t' || *p == ',')) p++;
        if (p >= end) break;
        e = p;
        while (e < end && *e != ',') e++;
        {
            const char *q = e;
            while (q > p && (q[-1] == ' ' || q[-1] == '\t')) q--;
            if (q - p == 1 && *p == '*') return 1;
            if (q - p > 2 && p[0] == 'W' && p[1] == '/') p += 2;
            if ((STRLEN)(q - p) == elen && memEQ(p, etag, elen)) return 1;
        }
        p = e;
    }
    return 0;
}

/* If-None-Match wins over If-Modified-Since (RFC 9110 13.1.3); the date
 * comparison is the ps_serve_file convention - an exact match is all we
 * need, the date they were given is the date we would send. */
static int psf_not_modified(pTHX_ HV *env, const char *etag, STRLEN elen,
                            const char *date) {
    SV **e = hv_fetchs(env, "HTTP_IF_NONE_MATCH", 0);
    if (e && *e && SvOK(*e)) {
        STRLEN l;
        const char *h = SvPV(*e, l);
        return etag ? psf_etag_in(h, l, etag, elen) : 0;
    }
    e = hv_fetchs(env, "HTTP_IF_MODIFIED_SINCE", 0);
    if (e && *e && SvOK(*e) && date)
        return strEQ(SvPV_nolen(*e), date);
    return 0;
}

/* If-Range: ranges stay honoured only on an exact validator match. A weak
 * tag never matches (RFC 9110 13.1.5), a mismatch means the full 200. */
static int psf_if_range_ok(const char *h, STRLEN hlen,
                           const char *etag, STRLEN elen,
                           const char *date) {
    const char *p = h, *end = h + hlen;
    while (p < end && (*p == ' ' || *p == '\t')) p++;
    while (end > p && (end[-1] == ' ' || end[-1] == '\t')) end--;
    if (p >= end) return 0;
    if (end - p > 2 && p[0] == 'W' && p[1] == '/') return 0;
    if (*p == '"')
        return etag && (STRLEN)(end - p) == elen && memEQ(p, etag, elen);
    return date && (STRLEN)(end - p) == strlen(date)
        && memEQ(p, date, (STRLEN)(end - p));
}

/* ---- Content-Disposition (RFC 6266 / RFC 5987) ---------------------------- */

static SV *psf_disposition(pTHX_ SV *filename, int inline_) {
    SV *out = newSVpv(inline_ ? "inline" : "attachment", 0);
    if (filename && SvOK(filename)) {
        STRLEN flen, i;
        const char *fn = SvPVutf8(filename, flen);
        int ascii = 1;
        for (i = 0; i < flen; i++) {
            U8 c = (U8)fn[i];
            if (c < 0x20 || c > 0x7E) { ascii = 0; break; }
        }
        /* the plain parameter always: non-ASCII bytes degrade to '_' so
         * a client that ignores filename* still gets a usable name */
        sv_catpvs(out, "; filename=\"");
        for (i = 0; i < flen; i++) {
            U8 c = (U8)fn[i];
            if (c < 0x20 || c > 0x7E) sv_catpvs(out, "_");
            else {
                if (c == '"' || c == '\\') sv_catpvs(out, "\\");
                sv_catpvn(out, &fn[i], 1);
            }
        }
        sv_catpvs(out, "\"");
        if (!ascii) {
            static const char hex[] = "0123456789ABCDEF";
            sv_catpvs(out, "; filename*=UTF-8''");
            for (i = 0; i < flen; i++) {
                U8 c = (U8)fn[i];
                if (isALNUM(c) || (c && strchr("!#$&+-.^_`|~", c) != NULL))
                    sv_catpvn(out, &fn[i], 1);
                else {
                    char pct[3];
                    pct[0] = '%';
                    pct[1] = hex[c >> 4];
                    pct[2] = hex[c & 0xF];
                    sv_catpvn(out, pct, 3);
                }
            }
        }
    }
    return out;
}

/* ---- Punk::SendFile::Reader ------------------------------------------------
 * The bounded body for a 206 from a file: getline yields 64KB chunks until
 * `remaining` is spent, close closes the PerlIO. Satisfies the PSGI body
 * protocol everywhere (Hyperman's hm_slurp_body takes the getline branch);
 * fileno is the streaming seam - a server holding it plus the response's
 * Content-Length (Hyperman's hm_bsrc_lift) sends the window straight from
 * the fd at its current position and never calls getline. */

typedef struct psf_reader {
    PerlIO *fp;
    UV      remaining;
} psf_reader;

#define PSF_READER_CHUNK 65536
#define PSF_READER_CLASS "Punk::SendFile::Reader"

static int psf_reader_free(pTHX_ SV *sv, MAGIC *mg) {
    psf_reader *r = (psf_reader *)mg->mg_ptr;
    PERL_UNUSED_ARG(sv);
    if (r) {
        if (r->fp) PerlIO_close(r->fp);
        Safefree(r);
    }
    return 0;
}
static MGVTBL psf_reader_vtbl = { NULL, NULL, NULL, NULL, psf_reader_free,
                                  NULL, NULL, NULL };

static SV *psf_reader_new(pTHX_ PerlIO *fp, UV remaining) {
    SV *obj = newSV(0);
    SV *rv;
    psf_reader *r;
    Newxz(r, 1, psf_reader);
    r->fp = fp;
    r->remaining = remaining;
    sv_magicext(obj, NULL, PERL_MAGIC_ext, &psf_reader_vtbl, (char *)r, 0);
    rv = newRV_noinc(obj);
    return sv_bless(rv, gv_stashpvs(PSF_READER_CLASS, GV_ADD));
}

static psf_reader *psf_reader_of(pTHX_ SV *self) {
    MAGIC *mg;
    if (SvROK(self)
        && (mg = mg_findext(SvRV(self), PERL_MAGIC_ext, &psf_reader_vtbl)))
        return (psf_reader *)mg->mg_ptr;
    croak(PSF_READER_CLASS ": not a reader");
    return NULL;                                     /* not reached */
}

/* ---- the decision core ----------------------------------------------------- */

typedef struct psf_src {
    const char *path;          /* file source when non-NULL ...        */
    STRLEN      plen;
    const char *bytes;         /* ... else the in-memory source        */
    UV          size;
    UV          mtime;
    int         has_mtime;     /* scalar sources only via the option   */
} psf_src;

typedef struct psf_opts {
    SV *type;                  /* Content-Type, or NULL to infer       */
    SV *filename;              /* Content-Disposition filename         */
    int inline_;               /* disposition token                    */
    int has_disp;              /* emit Content-Disposition at all      */
    int ranges;                /* honour Range / advertise bytes       */
    SV *etag;                  /* override, quoted or bare, or NULL    */
    AV *extra;                 /* $c->header pairs (borrowed), or NULL */
} psf_opts;

static void psf_hdr(pTHX_ AV *h, const char *k, SV *v) {
    av_push(h, newSVpv(k, 0));
    av_push(h, v);
}

static void psf_hdr_extra(pTHX_ AV *h, AV *extra) {
    SSize_t i, n;
    if (!extra) return;
    n = av_len(extra) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(extra, i, 0);
        av_push(h, e && *e ? newSVsv(*e) : newSV(0));
    }
}

static SV *psf_wrap(pTHX_ IV status, AV *hdr, SV *body) {
    AV *resp   = newAV();
    AV *bodyav = NULL;
    av_extend(resp, 2);
    av_push(resp, newSViv(status));
    av_push(resp, newRV_noinc((SV *)hdr));
    if (body && SvROK(body)) {                       /* glob or reader */
        av_push(resp, body);
    }
    else {
        bodyav = newAV();
        av_push(bodyav, body ? body : newSVpvs(""));
        av_push(resp, newRV_noinc((SV *)bodyav));
    }
    return newRV_noinc((SV *)resp);
}

/* The finished triplet (+1 owned), or NULL when a file source vanished
 * between the caller's stat and the open here - the caller decides what
 * its missing-file answer looks like. */
static SV *psf_respond(pTHX_ HV *env, psf_src *src, psf_opts *opt) {
    char etagbuf[48], date[64];
    const char *etag = NULL, *ldate = NULL;
    STRLEN elen = 0;
    const char *method;
    STRLEN mlen = 3;
    int is_get = 0, is_head = 0;
    int rstat = PSF_RANGE_NONE;
    UV off = 0, n = 0;
    SV **e;
    SV *ct;
    AV *hdr;

    /* validators */
    if (opt->etag && SvOK(opt->etag)) {
        STRLEN ol;
        const char *ov = SvPV(opt->etag, ol);
        if (ol && ov[0] == '"')
            my_snprintf(etagbuf, sizeof etagbuf, "%.*s", (int)ol, ov);
        else
            my_snprintf(etagbuf, sizeof etagbuf, "\"%.*s\"", (int)ol, ov);
        etag = etagbuf;
        elen = strlen(etagbuf);
    }
    else if (src->has_mtime) {
        psf_etag(etagbuf, sizeof etagbuf, src->mtime, src->size);
        etag = etagbuf;
        elen = strlen(etagbuf);
    }
    if (src->has_mtime) {
        ps_http_date(date, sizeof date, (time_t)src->mtime);
        ldate = date;
    }

    e = hv_fetchs(env, "REQUEST_METHOD", 0);
    method = (e && *e && SvOK(*e)) ? SvPV(*e, mlen) : "GET";
    if (mlen == 3 && memEQ(method, "GET", 3)) is_get = 1;
    else if (mlen == 4 && memEQ(method, "HEAD", 4)) is_head = 1;

    /* 304: a validator match on GET/HEAD (RFC 9110 13.1.3) */
    if ((is_get || is_head)
        && psf_not_modified(aTHX_ env, etag, elen, ldate)) {
        hdr = newAV();
        if (etag)  psf_hdr(aTHX_ hdr, "ETag", newSVpv(etag, elen));
        if (ldate) psf_hdr(aTHX_ hdr, "Last-Modified", newSVpv(ldate, 0));
        psf_hdr_extra(aTHX_ hdr, opt->extra);
        return psf_wrap(aTHX_ 304, hdr, NULL);
    }

    /* Range applies to GET alone (RFC 9110 14.2) */
    if (is_get && opt->ranges) {
        e = hv_fetchs(env, "HTTP_RANGE", 0);
        if (e && *e && SvOK(*e)) {
            STRLEN l;
            const char *h = SvPV(*e, l);
            rstat = psf_parse_range(h, l, src->size, &off, &n);
            if (rstat == PSF_RANGE_OK || rstat == PSF_RANGE_UNSAT) {
                SV **ir = hv_fetchs(env, "HTTP_IF_RANGE", 0);
                if (ir && *ir && SvOK(*ir)) {
                    STRLEN il;
                    const char *iv = SvPV(*ir, il);
                    if (!psf_if_range_ok(iv, il, etag, elen, ldate))
                        rstat = PSF_RANGE_IGNORE;
                }
            }
        }
    }

    if (rstat == PSF_RANGE_UNSAT) {
        SV *cr = newSVpvs("bytes */");
        sv_catpvf(cr, "%" UVuf, src->size);
        hdr = newAV();
        psf_hdr(aTHX_ hdr, "Content-Range", cr);
        psf_hdr(aTHX_ hdr, "Content-Length", newSViv(0));
        if (opt->ranges) psf_hdr(aTHX_ hdr, "Accept-Ranges", newSVpvs("bytes"));
        psf_hdr_extra(aTHX_ hdr, opt->extra);
        return psf_wrap(aTHX_ 416, hdr, NULL);
    }

    /* content type: the option, else the path's extension, else the
     * filename option's extension, else octet-stream */
    if (opt->type && SvOK(opt->type)) ct = newSVsv(opt->type);
    else if (src->path)
        ct = newSVpv(ps_content_type(src->path, src->plen), 0);
    else if (opt->filename && SvOK(opt->filename)) {
        STRLEN fl;
        const char *fn = SvPV(opt->filename, fl);
        ct = newSVpv(ps_content_type(fn, fl), 0);
    }
    else ct = newSVpvs("application/octet-stream");

    {
        int   partial = (rstat == PSF_RANGE_OK);
        UV    bl      = partial ? n : src->size;
        SV   *body    = NULL;

        hdr = newAV();
        psf_hdr(aTHX_ hdr, "Content-Type", ct);
        psf_hdr(aTHX_ hdr, "Content-Length", newSVuv(bl));
        if (partial) {
            SV *cr = newSVpvs("bytes ");
            sv_catpvf(cr, "%" UVuf "-%" UVuf "/%" UVuf,
                      off, off + n - 1, src->size);
            psf_hdr(aTHX_ hdr, "Content-Range", cr);
        }
        if (opt->ranges) psf_hdr(aTHX_ hdr, "Accept-Ranges", newSVpvs("bytes"));
        if (etag)  psf_hdr(aTHX_ hdr, "ETag", newSVpv(etag, elen));
        if (ldate) psf_hdr(aTHX_ hdr, "Last-Modified", newSVpv(ldate, 0));
        if (opt->has_disp)
            psf_hdr(aTHX_ hdr, "Content-Disposition",
                    psf_disposition(aTHX_ opt->filename, opt->inline_));
        psf_hdr_extra(aTHX_ hdr, opt->extra);

        if (is_head)
            body = NULL;                             /* headers, no body */
        else if (src->path) {
            PerlIO *fp = PerlIO_open(src->path, "rb");
            if (!fp) {
                SvREFCNT_dec((SV *)hdr);
                return NULL;
            }
            if (partial) {
                if (PerlIO_seek(fp, (Off_t)off, SEEK_SET) < 0) {
                    PerlIO_close(fp);
                    SvREFCNT_dec((SV *)hdr);
                    return NULL;
                }
                body = psf_reader_new(aTHX_ fp, n);
            }
            else {
                /* a real filehandle, the Punk::Static convention */
                GV *gv = newGVgen("Punk::SendFile");
                IO *io = GvIOn(gv);
                IoIFP(io)  = fp;
                IoTYPE(io) = IoTYPE_RDONLY;
                body = newRV_inc((SV *)gv);
            }
        }
        else
            body = newSVpvn(src->bytes + (partial ? off : 0), bl);

        return psf_wrap(aTHX_ partial ? 206 : 200, hdr, body);
    }
}

/* ---- precompressed siblings -------------------------------------------------
 *
 * If `style.css.gz` sits next to `style.css` and the client accepts gzip, we
 * serve the sibling's BYTES under the original's IDENTITY: its Content-Type,
 * its URL, its cache entry keyed by an ETag of its own. Nothing is
 * compressed at request time - the win is a build step's, paid once - so
 * this needs no zlib and costs one stat.
 *
 * `.br` is listed first and preferred when the client offers both. Serving a
 * brotli file needs no brotli library, only this table entry: the bytes are
 * already encoded and we are choosing a file, not compressing one.
 */
typedef struct { const char *suffix; STRLEN slen; const char *token; STRLEN tlen; }
    psf_encoding;

static const psf_encoding PSF_ENCODINGS[] = {
    { ".br", 3, "br",   2 },
    { ".gz", 3, "gzip", 4 },
};
#define PSF_NENCODINGS 2

/* Is `token` an acceptable encoding per this Accept-Encoding header? A
 * left-to-right walk: no split, no hash, no SV. `q=0` is an explicit refusal
 * and loses to nothing; `*` matches anything not separately refused. */
static int psf_accepts(pTHX_ const char *ae, STRLEN len, const char *tok, STRLEN tlen) {
    STRLEN i = 0;
    int star = 0;
    while (i < len) {
        STRLEN start, end, j;
        int refused = 0, is_star, is_tok;
        while (i < len && (ae[i] == ' ' || ae[i] == '\t' || ae[i] == ',')) i++;
        start = i;
        while (i < len && ae[i] != ',' && ae[i] != ';') i++;
        end = i;
        while (end > start && (ae[end - 1] == ' ' || ae[end - 1] == '\t')) end--;
        /* parameters: only q matters, and only q=0 (with any zero spelling) */
        if (i < len && ae[i] == ';') {
            STRLEN ps = i;
            while (i < len && ae[i] != ',') i++;
            for (j = ps; j + 1 < i; j++) {
                if ((ae[j] | 32) != 'q') continue;
                while (j + 1 < i && (ae[j + 1] == ' ' || ae[j + 1] == '=')) j++;
                if (j + 1 < i && ae[j + 1] == '0') {
                    /* q=0, q=0.0, q=0.000 - anything that is not > 0 */
                    STRLEN k = j + 2;
                    int nonzero = 0;
                    if (k < i && ae[k] == '.')
                        for (k++; k < i && ae[k] >= '0' && ae[k] <= '9'; k++)
                            if (ae[k] != '0') nonzero = 1;
                    if (!nonzero) refused = 1;
                }
                break;
            }
        }
        is_star = (end - start == 1 && ae[start] == '*');
        is_tok  = (end - start == tlen && foldEQ(ae + start, tok, (I32)tlen));
        if (is_tok) return !refused;               /* named: it decides */
        if (is_star && !refused) star = 1;
    }
    return star;
}

/* The env's Accept-Encoding, or NULL. */
static const char *psf_accept_encoding(pTHX_ HV *env, STRLEN *len) {
    SV **e = hv_fetchs(env, "HTTP_ACCEPT_ENCODING", 0);
    if (!(e && *e && SvOK(*e))) return NULL;
    return SvPV_const(*e, *len);
}

/* ---- ps_serve_file ----------------------------------------------------------
 * The static/markdown "serve one file" (declared in punk_static.h): the
 * decision core with a fixed option block - no disposition, ranges on,
 * validators from the file itself. This is where a `static` mount's ETag,
 * If-None-Match 304 and 206/416 answers come from. The is_head flag the
 * callers computed is the same REQUEST_METHOD the core reads for itself. */

static SV *ps_serve_file(pTHX_ HV *env, const char *file, STRLEN flen,
                         int is_head) {
    Stat_t st, sst;
    psf_src  s;
    psf_opts o;
    char sib[MAXPATHLEN + 8];
    char etagbuf[52];
    AV *extra = NULL;
    const char *ae;
    STRLEN ael = 0;
    int i;
    PERL_UNUSED_ARG(is_head);
    if (PerlLIO_stat(file, &st) < 0 || !S_ISREG(st.st_mode)) return NULL;
    Zero(&s, 1, psf_src);
    Zero(&o, 1, psf_opts);
    s.path      = file;
    s.plen      = flen;
    s.size      = (UV)st.st_size;
    s.mtime     = (UV)st.st_mtime;
    s.has_mtime = 1;
    o.ranges    = 1;

    /* Vary goes on EVERY response from here, compressed or not: a shared
     * cache that stored the identity bytes without it would hand them to a
     * client that asked for gzip, and vice versa. It costs one header and
     * it is the only spelling that is correct for both. */
    extra = (AV *)sv_2mortal((SV *)newAV());
    av_push(extra, newSVpvs("Vary"));
    av_push(extra, newSVpvs("Accept-Encoding"));

    ae = psf_accept_encoding(aTHX_ env, &ael);
    if (ae && ael && flen + 4 < sizeof(sib)) {
        for (i = 0; i < PSF_NENCODINGS; i++) {
            const psf_encoding *enc = &PSF_ENCODINGS[i];
            if (!psf_accepts(aTHX_ ae, ael, enc->token, enc->tlen)) continue;
            memcpy(sib, file, flen);
            memcpy(sib + flen, enc->suffix, enc->slen + 1);
            if (PerlLIO_stat(sib, &sst) < 0 || !S_ISREG(sst.st_mode)) continue;
            /* A sibling older than its source is a stale build artefact.
             * Serving it would ship last week's CSS forever, silently,
             * which is the failure nobody thinks to look for. */
            if ((UV)sst.st_mtime < (UV)st.st_mtime) continue;

            /* the bytes, the length and the validators are the sibling's;
             * the Content-Type stays the original's, so ps_content_type
             * must never see the .gz/.br suffix */
            o.type  = sv_2mortal(newSVpv(ps_content_type(file, flen), 0));
            s.path  = sib;
            s.plen  = flen + enc->slen;
            s.size  = (UV)sst.st_size;
            s.mtime = (UV)sst.st_mtime;

            /* an encoding-tagged ETag, so an identity client and this one
             * never collide in a shared cache even if the two files should
             * ever share an mtime and a size */
            psf_etag(etagbuf, sizeof etagbuf, s.mtime, s.size);
            {
                STRLEN el = strlen(etagbuf);
                if (el > 1 && etagbuf[el - 1] == '"'
                    && el + enc->tlen + 1 < sizeof etagbuf) {
                    etagbuf[el - 1] = '-';
                    memcpy(etagbuf + el, enc->token, enc->tlen);
                    etagbuf[el + enc->tlen]     = '"';
                    etagbuf[el + enc->tlen + 1] = '\0';
                }
                o.etag = sv_2mortal(newSVpv(etagbuf, 0));
            }
            av_push(extra, newSVpvs("Content-Encoding"));
            av_push(extra, newSVpvn(enc->token, enc->tlen));
            break;
        }
    }
    o.extra = extra;
    return psf_respond(aTHX_ env, &s, &o);
}

#endif /* PUNK_SENDFILE_H */

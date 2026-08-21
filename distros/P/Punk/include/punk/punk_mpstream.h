#ifndef PUNK_MPSTREAM_H
#define PUNK_MPSTREAM_H

/* punk_mpstream.h - multipart/form-data, parsed as it arrives.
 *
 * The whole-buffer parser beside this one is correct and cheap for a form.
 * It is the wrong shape for a file, because it needs the entire body as one
 * contiguous scalar before it starts - and then copies each part out of it
 * again.
 *
 * Measured, on this machine, for a 64 MiB upload:
 *
 *     Punk adds 2.02x the file size in RSS   (the slurp, then the part copy)
 *     parsing and copying is 75% of the time (not the read)
 *
 * On top of the server's own buffer that is three resident copies of every
 * uploaded file, per concurrent upload, per worker - which is why Hyperman's
 * max_body defaults to 16 MB.
 *
 * This parser reads the handle in chunks and never holds more than a window,
 * so a file part costs a temp file and a few kilobytes rather than itself.
 *
 * ---- the hard part --------------------------------------------------------
 *
 * A boundary can straddle any read boundary. So content is never flushed
 * right up to the end of what has been read: the last (delimiter length + 3)
 * bytes are held back, because a delimiter cannot be entirely inside the
 * flushed region without having been found there. Everything before that is
 * safe to write out and forget, which is what makes the memory flat.
 */

#define PQ_MP_CHUNK      65536      /* read size                             */
#define PQ_MP_SPILL      65536      /* a part above this becomes a file      */
#define PQ_MP_HDR_MAX    16384      /* one part's headers; a MIME header set
                                     * larger than this is not a header set  */

/* Where spilled parts go.
 *
 * `upload_dir` on the app when it names one, else the system temp directory.
 * Named by the application because it decides which FILESYSTEM: save() is a
 * rename only within one, and that is the difference between free and another
 * whole copy of a large file. */
static SV *pq_upload_dir(pTHX_ AV *req) {
    HV *env = punk_req_env(aTHX_ req);
    SV **d = env ? hv_fetchs(env, "punk.upload_dir", 0) : NULL;
    if (d && *d && SvOK(*d) && SvCUR(*d)) return sv_2mortal(newSVsv(*d));
    {
        const char *e = PerlEnv_getenv("TMPDIR");
        return sv_2mortal(newSVpv(e && *e ? e : "/tmp", 0));
    }
}

/* Where the current part's bytes are going. */
typedef struct {
    SV  *sv;         /* small parts: accumulated here            */
    int  fd;         /* large parts: written here, or -1         */
    SV  *path;       /* the temp file's path, or NULL            */
    UV   len;        /* bytes seen                               */
    int  is_file;    /* a file part (has a filename)             */
} pq_sink;

/* Temp file for a part that outgrew the threshold.
 *
 * O_EXCL, and the name owes NOTHING to the client's filename: a name is
 * request bytes, and this workspace has enough reflected-path scars. It is
 * the request's own random id plus a counter, in the configured directory.
 */
static int pq_sink_spill(pTHX_ pq_sink *s, SV *dir, UV seq) {
    unsigned char rnd[9];
    SV *path;
    int fd;
    if (s->fd >= 0) return 1;
    pk_ent_take(aTHX_ rnd, sizeof rnd);
    path = newSVsv(dir);
    if (SvCUR(path) && SvEND(path)[-1] != '/') sv_catpvs(path, "/");
    sv_catpvs(path, "punk-up-");
    {   SV *b64 = pk_b64url(aTHX_ rnd, sizeof rnd);
        sv_catsv(path, b64);
        SvREFCNT_dec(b64);
    }
    sv_catpvf(path, "-%" UVuf, seq);
    fd = PerlLIO_open3(SvPVX(path), O_WRONLY | O_CREAT | O_EXCL, 0600);
    if (fd < 0) { SvREFCNT_dec(path); return 0; }
    /* whatever was accumulated before the threshold goes out first */
    if (s->sv && SvCUR(s->sv)) {
        if (PerlLIO_write(fd, SvPVX(s->sv), SvCUR(s->sv)) < 0) {
            PerlLIO_close(fd); SvREFCNT_dec(path); return 0;
        }
        SvCUR_set(s->sv, 0);
    }
    s->fd   = fd;
    s->path = path;
    return 1;
}

static void pq_sink_write(pTHX_ pq_sink *s, const char *p, STRLEN n,
                          SV *dir, UV seq) {
    if (!n) return;
    s->len += n;
    if (s->fd < 0 && s->is_file && s->len > PQ_MP_SPILL)
        (void)pq_sink_spill(aTHX_ s, dir, seq);
    if (s->fd >= 0) { (void)PerlLIO_write(s->fd, p, n); return; }
    if (!s->sv) s->sv = newSVpvs("");
    sv_catpvn(s->sv, p, n);
}

/* Read up to `want` more bytes onto the end of buf. Returns 0 at EOF with
 * nothing added. `left` counts down CONTENT_LENGTH when there is one, so a
 * body that lies about its length cannot make this read for ever. */
static int pq_mp_fill(pTHX_ PerlIO *fp, SV *buf, STRLEN want, IV *left) {
    STRLEN have = SvCUR(buf);
    SSize_t got;
    char *d;
    if (*left == 0) return 0;
    if (*left > 0 && (IV)want > *left) want = (STRLEN)*left;
    if (!want) return 0;
    d = SvGROW(buf, have + want + 1);
    got = PerlIO_read(fp, d + have, want);
    if (got <= 0) { *left = 0; return 0; }
    SvCUR_set(buf, have + (STRLEN)got);
    SvPVX(buf)[have + got] = '\0';
    if (*left > 0) *left -= got;
    return 1;
}

/* Drop the first n bytes of buf. */
static void pq_mp_consume(pTHX_ SV *buf, STRLEN n) {
    STRLEN have = SvCUR(buf);
    if (n >= have) { SvCUR_set(buf, 0); return; }
    Move(SvPVX(buf) + n, SvPVX(buf), have - n, char);
    SvCUR_set(buf, have - n);
    SvPVX(buf)[have - n] = '\0';
}

/* Removing the temp files.
 *
 * Attached as magic to the list itself, so it fires when the REQUEST is
 * freed - which happens on every exit path there is, including a handler
 * that died and a client that vanished. Hooking punk_deliver instead would
 * have leaked on the four dispatcher exits that never reach it, which is the
 * finding Punk::Plugin::RequestId already paid for.
 *
 * A part that save() renamed is marked `moved` and is not ours any more; the
 * entry is dropped from the list at that point rather than unlinked here,
 * because unlinking where the caller just put their file would be worse than
 * leaking.
 */
static int pq_tmp_free(pTHX_ SV *sv, MAGIC *mg) {
    AV *av = (AV *)sv;
    SSize_t i, n;
    PERL_UNUSED_ARG(mg);
    if (!av || SvTYPE((SV *)av) != SVt_PVAV) return 0;
    n = av_len(av) + 1;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(av, i, 0);
        if (e && *e && SvOK(*e) && SvCUR(*e))
            (void)PerlLIO_unlink(SvPVX(*e));
    }
    return 0;
}
static MGVTBL pq_tmp_vtbl = { NULL, NULL, NULL, NULL, pq_tmp_free,
                              NULL, NULL, NULL };

static void pq_tmp_own(pTHX_ AV *av) {
    sv_magicext((SV *)av, NULL, PERL_MAGIC_ext, &pq_tmp_vtbl, NULL, 0);
}

/* The parse. Returns the number of parts seen. */
static IV pq_parse_multipart_stream(pTHX_ PerlIO *fp, IV clen,
                                    const char *bnd, STRLEN bl,
                                    HV *form, HV *uploads, SV *dir,
                                    AV *tempfiles) {
    SV *buf  = sv_2mortal(newSVpvs(""));
    SV *dsv  = sv_2mortal(newSVpvs("--"));
    SV *ndsv = sv_2mortal(newSVpvs("\r\n--"));
    const char *D, *ND;
    STRLEN Dl, NDl, keep;
    IV left = clen > 0 ? clen : -1;
    IV parts = 0;
    UV seq = 0;

    sv_catpvn(dsv, bnd, bl);
    sv_catpvn(ndsv, bnd, bl);
    D = SvPVX(dsv);  Dl  = SvCUR(dsv);
    ND = SvPVX(ndsv); NDl = SvCUR(ndsv);
    keep = NDl + 3;                     /* a delimiter cannot hide in less  */

    /* the opening delimiter */
    for (;;) {
        char *b = SvPVX(buf);
        char *hit = SvCUR(buf) >= Dl
                  ? ninstr(b, b + SvCUR(buf), (char *)D, (char *)D + Dl) : NULL;
        if (hit) { pq_mp_consume(aTHX_ buf, (STRLEN)(hit - b) + Dl); break; }
        if (SvCUR(buf) > keep) pq_mp_consume(aTHX_ buf, SvCUR(buf) - keep);
        if (!pq_mp_fill(aTHX_ fp, buf, PQ_MP_CHUNK, &left)) return 0;
    }

    for (;;) {
        const char *hend = NULL;
        const char *disp = NULL, *ctype = NULL, *name = NULL, *fname = NULL;
        STRLEN displ = 0, ctypel = 0, namel = 0, fnamel = 0;
        pq_sink sink;

        /* "--" here is the closing delimiter; CRLF starts another part */
        while (SvCUR(buf) < 2)
            if (!pq_mp_fill(aTHX_ fp, buf, PQ_MP_CHUNK, &left)) return parts;
        if (SvPVX(buf)[0] == '-' && SvPVX(buf)[1] == '-') return parts;
        if (SvPVX(buf)[0] != '\r' || SvPVX(buf)[1] != '\n') return parts;
        pq_mp_consume(aTHX_ buf, 2);

        /* the part's headers, which are small by definition */
        for (;;) {
            char *b = SvPVX(buf);
            { const char *crlf2 = "\r\n\r\n";
              hend = ninstr(b, b + SvCUR(buf),
                            (char *)crlf2, (char *)crlf2 + 4); }
            if (hend) break;
            if (SvCUR(buf) > PQ_MP_HDR_MAX) return parts;
            if (!pq_mp_fill(aTHX_ fp, buf, PQ_MP_CHUNK, &left)) return parts;
        }
        {   /* the same header reading the whole-buffer parser does */
            const char *hp = SvPVX(buf);
            while (hp < hend) {
                const char *crlf = "\r\n";
                const char *le = ninstr((char *)hp, (char *)hend,
                                        (char *)crlf, (char *)crlf + 2);
                const char *lend = le ? le : hend;
                STRLEN ll = (STRLEN)(lend - hp);
                if (ll >= 20 && strncasecmp(hp, "Content-Disposition:", 20) == 0) {
                    disp = hp + 20; displ = ll - 20;
                }
                else if (ll >= 13 && strncasecmp(hp, "Content-Type:", 13) == 0) {
                    ctype = hp + 13;
                    while (ctype < hp + ll && *ctype == ' ') ctype++;
                    ctypel = (STRLEN)((hp + ll) - ctype);
                }
                if (!le) break;
                hp = le + 2;
            }
            if (disp) {
                name  = pq_hdr_param(disp, displ, "name", &namel);
                fname = pq_hdr_param(disp, displ, "filename", &fnamel);
            }
        }
        /* headers are copied out before the buffer moves under them */
        {
            SV *nsv = name  ? sv_2mortal(newSVpvn(name, namel))   : NULL;
            SV *fsv = fname ? sv_2mortal(newSVpvn(fname, fnamel)) : NULL;
            SV *tsv = (ctype && ctypel)
                    ? sv_2mortal(newSVpvn(ctype, ctypel)) : NULL;

            pq_mp_consume(aTHX_ buf, (STRLEN)((hend + 4) - SvPVX(buf)));

            sink.sv = NULL; sink.fd = -1; sink.path = NULL;
            sink.len = 0;   sink.is_file = fsv ? 1 : 0;
            seq++;

            /* the content, up to the next delimiter */
            for (;;) {
                char *b = SvPVX(buf);
                char *hit = SvCUR(buf) >= NDl
                    ? ninstr(b, b + SvCUR(buf), (char *)ND, (char *)ND + NDl)
                    : NULL;
                if (hit) {
                    pq_sink_write(aTHX_ &sink, b, (STRLEN)(hit - b), dir, seq);
                    pq_mp_consume(aTHX_ buf, (STRLEN)(hit - b) + NDl);
                    break;
                }
                if (SvCUR(buf) > keep) {
                    STRLEN flush = SvCUR(buf) - keep;
                    pq_sink_write(aTHX_ &sink, b, flush, dir, seq);
                    pq_mp_consume(aTHX_ buf, flush);
                }
                if (!pq_mp_fill(aTHX_ fp, buf, PQ_MP_CHUNK, &left)) {
                    /* truncated: the part never ended */
                    pq_sink_write(aTHX_ &sink, SvPVX(buf), SvCUR(buf), dir, seq);
                    pq_mp_consume(aTHX_ buf, SvCUR(buf));
                    break;
                }
            }
            if (sink.fd >= 0) { PerlLIO_close(sink.fd); sink.fd = -1; }

            parts++;
            if (!nsv) {                       /* a part with no name is noise */
                if (sink.sv) SvREFCNT_dec(sink.sv);
                if (sink.path) {
                    (void)PerlLIO_unlink(SvPVX(sink.path));
                    SvREFCNT_dec(sink.path);
                }
                continue;
            }

            if (fsv) {
                HV *up = newHV();
                SV *obj;
                (void)hv_stores(up, "name",     newSVsv(nsv));
                (void)hv_stores(up, "filename", newSVsv(fsv));
                (void)hv_stores(up, "type", tsv ? newSVsv(tsv)
                                    : newSVpvs("application/octet-stream"));
                (void)hv_stores(up, "size",    newSVuv(sink.len));
                if (sink.path) {
                    /* on disk: the path, and the request owns its removal.
                     * The upload keeps a reference to its own slot in that
                     * list, so save()'s rename can clear it - see
                     * pq_tmp_free on why unlinking a moved file would be
                     * worse than leaking one. */
                    (void)hv_stores(up, "path", newSVsv(sink.path));
                    if (tempfiles) {
                        SV *slot = newSVsv(sink.path);
                        av_push(tempfiles, slot);
                        (void)hv_stores(up, "tmpslot", newRV_inc(slot));
                    }
                    SvREFCNT_dec(sink.path);
                }
                else {
                    (void)hv_stores(up, "content",
                                    sink.sv ? sink.sv : newSVpvs(""));
                    sink.sv = NULL;
                }
                obj = sv_bless(newRV_noinc((SV *)up),
                               gv_stashpvs("Punk::Upload", GV_ADD));
                pq_hv_add(aTHX_ uploads, SvPVX(nsv), SvCUR(nsv), obj);
            }
            else {
                /* a field: it stays in memory, because a form value is
                 * something the application is about to read */
                if (sink.path) {
                    /* it outgrew the threshold anyway - read it back rather
                     * than hand a form value a path nobody expects */
                    SV *v = newSVpvs("");
                    int fd = PerlLIO_open(SvPVX(sink.path), O_RDONLY);
                    if (fd >= 0) {
                        char tmp[PQ_MP_CHUNK];
                        SSize_t n;
                        while ((n = PerlLIO_read(fd, tmp, sizeof tmp)) > 0)
                            sv_catpvn(v, tmp, (STRLEN)n);
                        PerlLIO_close(fd);
                    }
                    (void)PerlLIO_unlink(SvPVX(sink.path));
                    SvREFCNT_dec(sink.path);
                    pq_hv_add(aTHX_ form, SvPVX(nsv), SvCUR(nsv), v);
                    if (sink.sv) SvREFCNT_dec(sink.sv);
                }
                else {
                    pq_hv_add(aTHX_ form, SvPVX(nsv), SvCUR(nsv),
                              sink.sv ? sink.sv : newSVpvs(""));
                    sink.sv = NULL;
                }
            }
        }
    }
}

#endif /* PUNK_MPSTREAM_H */

/* punk_asset.h - content-addressed URLs for static files.
 *
 * A validator (ETag, Last-Modified) makes a stale copy cheap to detect; it
 * does not make it unnecessary to ask. With no freshness lifetime a browser
 * must revalidate every asset on every page load - correct, small on the
 * wire, and still a round trip each. The lifetime that would remove the
 * round trip cannot safely be given to `/static/app.css`, because that URL
 * means something different after every deploy.
 *
 * So the URL changes with the bytes: `/static/app.9f3a1c2b0d4e5f60.css` is
 * served from `root/static/app.css`, and gets a year and `immutable` -
 * which is true of that URL, whatever happens to the file. A URL whose
 * digest does NOT match what the file now holds (a page cached from an
 * older deploy) still serves the current bytes, just with the ordinary
 * revalidating headers. `immutable` is never sent for a URL that could
 * mean something else tomorrow.
 *
 * The digest is the first 8 bytes of SHA-256 over the file's contents, hex.
 * Not the mtime and size the ETag is built from: mtime differs per machine
 * and per deploy, so a fleet would serve a different URL per box for
 * identical bytes - every deploy a cold cache, and HTML from one box naming
 * an asset URL another box has never heard of. The bytes are the thing that
 * changed, so the bytes are what the URL is keyed on.
 *
 * Include after punk_session.h (the SHA-256 core).
 */

#ifndef PUNK_ASSET_H
#define PUNK_ASSET_H

/* 8 bytes of SHA-256, hex. Long enough that two versions of one file
 * colliding is not a thing that happens; short enough to read in a log. */
#define PA_DIGEST_LEN 16

/* Reading the whole file to hash it is not an option: a static directory may
 * hold a video. 64KB at a time, and the compression loop is punk_session.h's
 * so there is only ever one of it. */
#define PA_HASH_CHUNK 65536

static int pa_sha256_file(pTHX_ const char *path, unsigned char out[32]) {
    PerlIO *fp = PerlIO_open(path, "rb");
    unsigned char *buf;
    U32 h[8];
    size_t total = 0, rem = 0;
    int ok = 1;

    if (!fp) return 0;
    Newx(buf, PA_HASH_CHUNK + 64, unsigned char);
    memcpy(h, ps_sha256_iv, sizeof h);
    for (;;) {
        SSize_t got = PerlIO_read(fp, buf + rem, PA_HASH_CHUNK);
        size_t have, whole;
        if (got < 0) { ok = 0; break; }
        if (got == 0) break;
        have   = rem + (size_t)got;
        total += (size_t)got;
        whole  = have / 64;
        if (whole) ps_sha256_blocks(h, buf, whole);
        rem = have - whole * 64;
        if (rem) memmove(buf, buf + whole * 64, rem);
    }
    PerlIO_close(fp);
    if (ok) ps_sha256_final(h, buf, rem, total, out);
    Safefree(buf);
    return ok;
}

static void pa_hex(const unsigned char *in, int nbytes, char *out) {
    static const char hex[] = "0123456789abcdef";
    int i;
    for (i = 0; i < nbytes; i++) {
        out[2*i]     = hex[(in[i] >> 4) & 0xF];
        out[2*i + 1] = hex[in[i] & 0xF];
    }
    out[2*nbytes] = '\0';
}

/* The file's digest into out[PA_DIGEST_LEN + 1]; 0 when it cannot be read. */
static int pa_digest_file(pTHX_ const char *path, char *out) {
    unsigned char sum[32];
    if (!pa_sha256_file(aTHX_ path, sum)) return 0;
    pa_hex(sum, PA_DIGEST_LEN / 2, out);
    return 1;
}

/* ---- the digest cache -------------------------------------------------------
 * path => [ digest, mtime, size ], one per mount, filled on demand.
 *
 * In production a digest is computed once and then believed: the files are
 * not going to change under a running process, and re-reading them to find
 * that out would be the whole cost of the feature paid on every page. In
 * development the entry is checked against the file's mtime and size, so
 * editing a stylesheet and hitting reload shows the edit. */

enum { PA_CE_DIGEST = 0, PA_CE_MTIME = 1, PA_CE_SIZE = 2 };

/* The cached digest for `path` (a borrowed SV), or NULL when the file is
 * gone or unreadable. */
static SV *pa_digest_cached(pTHX_ HV *cache, const char *path, STRLEN plen,
                            int dev) {
    SV **slot = hv_fetch(cache, path, (I32)plen, 0);
    AV *ent = NULL;
    Stat_t st;
    char digest[PA_DIGEST_LEN + 1];
    int have_stat = 0;

    if (slot && *slot && SvROK(*slot) && SvTYPE(SvRV(*slot)) == SVt_PVAV) {
        ent = (AV *)SvRV(*slot);
        if (!dev) return *av_fetch(ent, PA_CE_DIGEST, 0);
        if (PerlLIO_stat(path, &st) < 0 || !S_ISREG(st.st_mode)) return NULL;
        have_stat = 1;
        if ((UV)st.st_mtime == SvUV(*av_fetch(ent, PA_CE_MTIME, 0))
            && (UV)st.st_size == SvUV(*av_fetch(ent, PA_CE_SIZE, 0)))
            return *av_fetch(ent, PA_CE_DIGEST, 0);
    }

    if (!have_stat && (PerlLIO_stat(path, &st) < 0 || !S_ISREG(st.st_mode)))
        return NULL;
    if (!pa_digest_file(aTHX_ path, digest)) return NULL;

    if (ent) {
        sv_setpvn(*av_fetch(ent, PA_CE_DIGEST, 0), digest, PA_DIGEST_LEN);
        sv_setuv(*av_fetch(ent, PA_CE_MTIME, 0), (UV)st.st_mtime);
        sv_setuv(*av_fetch(ent, PA_CE_SIZE, 0),  (UV)st.st_size);
        return *av_fetch(ent, PA_CE_DIGEST, 0);
    }
    ent = newAV();
    av_extend(ent, 2);
    av_push(ent, newSVpvn(digest, PA_DIGEST_LEN));
    av_push(ent, newSVuv((UV)st.st_mtime));
    av_push(ent, newSVuv((UV)st.st_size));
    (void)hv_store(cache, path, (I32)plen, newRV_noinc((SV *)ent), 0);
    return *av_fetch(ent, PA_CE_DIGEST, 0);
}

/* ---- the URL shape ----------------------------------------------------------
 * `<name>.<16 hex>.<ext>`, and only that: the digest goes before the final
 * extension so the file keeps its type to everything downstream that reads
 * the URL - a CDN, a log, a Content-Type guess of our own. A path with no
 * extension has nowhere to put the digest and is left alone; it serves with
 * the ordinary revalidating headers, which is what it did before.
 */

static int pa_is_digest(const char *p, STRLEN n) {
    STRLEN i;
    if (n != PA_DIGEST_LEN) return 0;
    for (i = 0; i < n; i++) {
        char c = p[i];
        if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f'))) return 0;
    }
    return 1;
}

/* The offset of the final '.' in the last path segment, or -1. */
static SSize_t pa_ext_dot(const char *p, STRLEN len) {
    STRLEN i;
    for (i = len; i > 0; i--) {
        if (p[i - 1] == '/' || p[i - 1] == '\\') return -1;
        if (p[i - 1] == '.') return (SSize_t)(i - 1);
    }
    return -1;
}

/* Strip a fingerprint: "app.9f3a....css" -> "app.css" in `out` (which must
 * hold `len` bytes plus a NUL), with the digest copied to `digest`. Returns
 * the length of the stripped path, or 0 when there was no fingerprint. */
static STRLEN pa_defingerprint(const char *p, STRLEN len, char *out,
                               char *digest) {
    SSize_t ext = pa_ext_dot(p, len);
    SSize_t dot;
    STRLEN dlen;
    if (ext <= 0) return 0;
    dot = pa_ext_dot(p, (STRLEN)ext);            /* the dot before the ext */
    if (dot < 0) return 0;
    dlen = (STRLEN)(ext - dot - 1);
    if (!pa_is_digest(p + dot + 1, dlen)) return 0;
    memcpy(digest, p + dot + 1, PA_DIGEST_LEN);
    digest[PA_DIGEST_LEN] = '\0';
    memcpy(out, p, (STRLEN)dot);
    memcpy(out + dot, p + ext, len - (STRLEN)ext);
    out[len - dlen - 1] = '\0';
    return len - dlen - 1;
}

/* The other direction: "/static/app.css" + digest -> a new SV holding
 * "/static/app.<digest>.css". NULL when the path has no extension to sit
 * in front of. */
static SV *pa_fingerprint(pTHX_ const char *p, STRLEN len, const char *digest) {
    SSize_t ext = pa_ext_dot(p, len);
    SV *out;
    if (ext <= 0) return NULL;
    out = newSVpvn(p, (STRLEN)ext);
    sv_catpvs(out, ".");
    sv_catpvn(out, digest, PA_DIGEST_LEN);
    sv_catpvn(out, p + ext, len - (STRLEN)ext);
    return out;
}

#endif /* PUNK_ASSET_H */

/* pmcp_rand.h - random bytes and the ids made from them.
 *
 * Needs: pmcp.h.
 * Gives: pmcp_random_bytes, pmcp_rand_id.
 *
 * getentropy where Makefile.PL's probe linked it, otherwise a cached
 * /dev/urandom descriptor (Punk's punk_csrf.h does the same). The probe builds
 * an executable, not an object: FreeBSD before 12 has no getentropy and an old
 * compiler takes the implicit declaration as a warning, so only the link tells
 * (the Punk 0.10 FreeBSD lesson). Croaks rather than falling back to anything
 * weaker: a guessable session id is worse than a server that will not start.
 */

#ifndef PMCP_RAND_H
#define PMCP_RAND_H

#include <errno.h>
#ifdef PMCP_HAVE_GETENTROPY
#  ifdef PMCP_GETENTROPY_SYS_RANDOM
#    include <sys/random.h>
#  else
#    include <unistd.h>
#  endif
#endif

#define PMCP_ID_BYTES 16
#define PMCP_ID_CHARS 22   /* base64url of 16 bytes, unpadded */

#ifndef PMCP_HAVE_GETENTROPY
static int pmcp_urandom_fd = -1;
#endif

static void pmcp_random_bytes(pTHX_ unsigned char *out, size_t n)
{
    size_t off = 0;
#ifdef PMCP_HAVE_GETENTROPY
    PERL_UNUSED_CONTEXT;
    while (off < n) {
        size_t want = n - off;
        if (want > 256) want = 256;    /* getentropy's documented maximum */
        if (getentropy(out + off, want) != 0)
            croak(PMCP_DIST ": getentropy failed: %s", Strerror(errno));
        off += want;
    }
#else
    if (pmcp_urandom_fd < 0) {
        pmcp_urandom_fd = PerlLIO_open3("/dev/urandom", O_RDONLY, 0);
        if (pmcp_urandom_fd < 0)
            croak(PMCP_DIST ": cannot open /dev/urandom: %s", Strerror(errno));
    }
    while (off < n) {
        SSize_t got = PerlLIO_read(pmcp_urandom_fd, out + off, n - off);
        if (got <= 0) croak(PMCP_DIST ": short read from /dev/urandom");
        off += (size_t)got;
    }
#endif
}

/* base64url, no padding, of n bytes into out, which holds 4 * ceil(n / 3)
 * bytes. Returns the length written. */
static size_t pmcp_b64url(const unsigned char *in, size_t n, char *out)
{
    static const char tbl[] =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    size_t i = 0, o = 0;

    while (i + 3 <= n) {
        U32 v = ((U32)in[i] << 16) | ((U32)in[i + 1] << 8) | in[i + 2];
        out[o++] = tbl[(v >> 18) & 63];
        out[o++] = tbl[(v >> 12) & 63];
        out[o++] = tbl[(v >> 6) & 63];
        out[o++] = tbl[v & 63];
        i += 3;
    }
    if (n - i == 1) {
        U32 v = (U32)in[i] << 16;
        out[o++] = tbl[(v >> 18) & 63];
        out[o++] = tbl[(v >> 12) & 63];
    }
    else if (n - i == 2) {
        U32 v = ((U32)in[i] << 16) | ((U32)in[i + 1] << 8);
        out[o++] = tbl[(v >> 18) & 63];
        out[o++] = tbl[(v >> 12) & 63];
        out[o++] = tbl[(v >> 6) & 63];
    }
    return o;
}

/* A fresh id: 16 random bytes as 22 base64url characters. Returns +1. */
static SV *pmcp_rand_id(pTHX)
{
    unsigned char raw[PMCP_ID_BYTES];
    char txt[24];
    size_t len;

    pmcp_random_bytes(aTHX_ raw, sizeof raw);
    len = pmcp_b64url(raw, sizeof raw, txt);
    return newSVpvn(txt, len);
}

#endif /* PMCP_RAND_H */

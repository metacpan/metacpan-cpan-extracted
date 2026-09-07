#ifndef PCHAL_SUBJECT_H
#define PCHAL_SUBJECT_H

/* The subject: what a puzzle and a clearance are bound to.
 *
 *     bind      subject
 *     prefix    the client's /24 for IPv4, /64 for IPv6     (the default)
 *     ip        the client address exactly
 *     none      the empty string
 *
 * The client address is REMOTE_ADDR, which under `proxy` is already the real
 * client. A prefix rather than the exact address by default, because mobile
 * clients move within a carrier's allocation between one request and the
 * next, and a clearance that expired every time a phone changed towers would
 * train users to expect the puzzle.
 *
 * The subject is never written into a token. It is an input to the MAC, so a
 * token presented from a different subject fails the MAC and the verifier
 * cannot tell that case from a forgery.
 *
 * An address that is neither IPv4 nor IPv6 text - a unix socket path, an
 * empty string - is used exactly as given under `prefix` and `ip`. Nothing
 * here guesses.
 *
 * Must be included after pchal_clos.h and pchal_boot.h.
 */

/* Strict dotted quad: four decimal groups of one to three digits, each at
 * most 255. */
static int pchal_parse_v4(const char *p, STRLEN l, unsigned char out[4])
{
    STRLEN i = 0;
    int g;
    for (g = 0; g < 4; g++) {
        unsigned v = 0;
        int digits = 0;
        while (i < l && isDIGIT(p[i]) && digits < 3) {
            v = v * 10 + (unsigned)(p[i] - '0');
            i++;
            digits++;
        }
        if (!digits || v > 255) return 0;
        out[g] = (unsigned char)v;
        if (g < 3) {
            if (i >= l || p[i] != '.') return 0;
            i++;
        }
    }
    return i == l;
}

static int pchal_hexval(unsigned char c)
{
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

/* RFC 4291 text: up to eight hex groups, one `::` run, an optional dotted
 * quad in the last 32 bits. No brackets, no zone id, no prefix length. */
static int pchal_parse_v6(const char *p, STRLEN l, unsigned char out[16])
{
    U16 g[8];
    int n = 0, gap = -1, i2;
    STRLEN i = 0;

    if (l < 2) return 0;
    if (p[0] == ':') {
        if (p[1] != ':') return 0;
        gap = 0;
        i = 2;
    }
    while (i < l) {
        U32 v = 0;
        int digits = 0;
        STRLEN start = i;
        while (i < l && pchal_hexval((unsigned char)p[i]) >= 0 && digits < 4) {
            v = v * 16 + (U32)pchal_hexval((unsigned char)p[i]);
            i++;
            digits++;
        }
        if (i < l && p[i] == '.') {
            unsigned char q[4];
            if (n > 6) return 0;
            if (!pchal_parse_v4(p + start, l - start, q)) return 0;
            g[n++] = (U16)(((U16)q[0] << 8) | q[1]);
            g[n++] = (U16)(((U16)q[2] << 8) | q[3]);
            i = l;
            break;
        }
        if (!digits || n >= 8) return 0;
        g[n++] = (U16)v;
        if (i == l) break;
        if (p[i] != ':') return 0;
        i++;
        if (i == l) return 0;                       /* a trailing lone colon */
        if (p[i] == ':') {
            if (gap >= 0) return 0;
            gap = n;
            i++;
        }
    }
    if (gap < 0) {
        if (n != 8) return 0;
    }
    else {
        int tail = n - gap, k;
        if (n > 7) return 0;
        for (k = 0; k < tail; k++) g[7 - k] = g[n - 1 - k];
        for (k = gap; k < 8 - tail; k++) g[k] = 0;
    }
    for (i2 = 0; i2 < 8; i2++) {
        out[2 * i2]     = (unsigned char)(g[i2] >> 8);
        out[2 * i2 + 1] = (unsigned char)(g[i2] & 0xff);
    }
    return 1;
}

/* Append the subject for `addr` under `bind` to `out`. */
static void pchal_subject_cat(pTHX_ SV *out, const char *addr, STRLEN al,
                              const char *bind, STRLEN bl)
{
    unsigned char b[16];
    if (bl == 4 && memEQ(bind, "none", 4)) return;
    if (bl == 2 && memEQ(bind, "ip", 2)) { sv_catpvn(out, addr, al); return; }
    if (pchal_parse_v4(addr, al, b)) {
        sv_catpvf(out, "%u.%u.%u.0/24", (unsigned)b[0], (unsigned)b[1],
                  (unsigned)b[2]);
        return;
    }
    if (pchal_parse_v6(addr, al, b)) {
        sv_catpvf(out, "%x:%x:%x:%x::/64",
                  (unsigned)(((unsigned)b[0] << 8) | b[1]),
                  (unsigned)(((unsigned)b[2] << 8) | b[3]),
                  (unsigned)(((unsigned)b[4] << 8) | b[5]),
                  (unsigned)(((unsigned)b[6] << 8) | b[7]));
        return;
    }
    sv_catpvn(out, addr, al);
}

/* The subject of a request under the plugin's `bind`. A new SV. A request
 * with no REMOTE_ADDR has the empty subject, which is the shared-subject
 * case the reverse-proxy warning is about. */
static SV *pchal_subject_of(pTHX_ SV *c, HV *opts)
{
    SV *out = newSVpvs("");
    SV *addr = pchal_env(aTHX_ c, "REMOTE_ADDR");
    SV *bind = pchal_hget(aTHX_ opts, "bind");
    STRLEN al = 0, bl = 6;
    const char *ap = "", *bp = "prefix";
    if (addr) ap = SvPV_const(addr, al);
    if (bind) bp = SvPV_const(bind, bl);
    pchal_subject_cat(aTHX_ out, ap, al, bp, bl);
    return out;
}

#endif /* PCHAL_SUBJECT_H */

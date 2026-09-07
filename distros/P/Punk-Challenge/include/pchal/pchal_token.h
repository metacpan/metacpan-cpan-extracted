#ifndef PCHAL_TOKEN_H
#define PCHAL_TOKEN_H

/* The puzzle and the clearance. Everything here is state-free: no table, no
 * cache, no replay set.
 *
 *   puzzle      v1.<ts>.<bits>.<salt>.<mac>
 *   solution    v1.<ts>.<bits>.<salt>.<mac>.<nonce>
 *   clearance   v1.<exp>.<bits>.<mac>
 *
 *   ts     issue time, epoch seconds, decimal
 *   exp    absolute expiry, epoch seconds, decimal
 *   bits   leading zero bits, decimal, 1..22
 *   salt   <pid>-<counter> in base 36
 *   mac    HMAC-SHA256(secret, msg), first 16 bytes, base64url (22 chars)
 *
 *   puzzle msg     "puzzle\0" subject "\0" ts "\0" bits "\0" salt
 *   clearance msg  "clear\0"  subject "\0" exp "\0" bits
 *
 * A solution is correct when SHA-256(puzzle "." nonce) begins with `bits`
 * zero bits. The hash is over the whole puzzle string including the MAC, so
 * a solution is tied to one puzzle and not to its parameters.
 *
 * The salt is not random, on purpose. Its only job is to make two puzzles
 * issued in the same second to the same subject distinct, so one solution
 * does not satisfy both, and a per-process counter beside the pid does that
 * exactly. A puzzle is public the moment it is issued, so unpredictability
 * buys nothing; the MAC is what makes it unforgeable, and the MAC has the
 * secret.
 *
 * Verification runs cheapest first and every failure is the same "no" to the
 * client; the reason is for the log. Nothing is allocated that a hostile
 * client can make larger: every field has a maximum length checked before
 * anything is computed.
 *
 * Must be included after pchal_sha256.h, pchal_b64.h, pchal_ct.h and
 * pchal_boot.h.
 */

#include <time.h>

#define PCHAL_MAC_LEN   22                 /* 16 bytes, base64url             */
#define PCHAL_MAC_BUF   PCHAL_B64_LEN(16)  /* what the encoder needs: 24      */
#define PCHAL_MAX_DEC   19                 /* digits an IV can always hold    */
#define PCHAL_MAX_SALT  32
#define PCHAL_MAX_TOKEN 160                /* generous over the longest shape */
#define PCHAL_FUTURE_SLACK 60              /* seconds a clock may run ahead   */

typedef enum {
    PCHAL_OK = 0,
    PCHAL_SHAPE,     /* not a token of this shape                             */
    PCHAL_STALE,     /* issued longer ago than puzzle_ttl                     */
    PCHAL_FUTURE,    /* issued more than the slack in the future              */
    PCHAL_MAC,       /* no configured secret signs it for this subject        */
    PCHAL_BITS,      /* fewer bits than this rule demands                     */
    PCHAL_HASH,      /* the nonce does not solve it                           */
    PCHAL_EXPIRED    /* a clearance past its exp                              */
} pchal_reason;

static const char *pchal_reason_str(pchal_reason r)
{
    switch (r) {
    case PCHAL_OK:      return "ok";
    case PCHAL_SHAPE:   return "shape";
    case PCHAL_STALE:   return "stale";
    case PCHAL_FUTURE:  return "future";
    case PCHAL_MAC:     return "mac";
    case PCHAL_BITS:    return "bits";
    case PCHAL_HASH:    return "hash";
    case PCHAL_EXPIRED: return "expired";
    }
    return "?";
}

/* ---- small parsers ---------------------------------------------------------- */

/* A decimal of one to PCHAL_MAX_DEC digits that fits an IV. No sign, no
 * whitespace. */
static int pchal_dec(const char *p, STRLEN l, IV *out)
{
    UV v = 0;
    STRLEN i;
    if (!l || l > PCHAL_MAX_DEC) return 0;
    for (i = 0; i < l; i++) {
        unsigned d;
        if (!isDIGIT(p[i])) return 0;
        d = (unsigned)(p[i] - '0');
        if (v > (UV)(IV_MAX / 10) || (v == (UV)(IV_MAX / 10) && d > (unsigned)(IV_MAX % 10)))
            return 0;
        v = v * 10 + d;
    }
    *out = (IV)v;
    return 1;
}

/* Split on '.' into at most `max` fields. The count, or -1 for more. */
static int pchal_split(const char *s, STRLEN l, const char **f, STRLEN *fl,
                       int max)
{
    int n = 0;
    STRLEN i, start = 0;
    for (i = 0; i <= l; i++) {
        if (i == l || s[i] == '.') {
            if (n == max) return -1;
            f[n] = s + start;
            fl[n] = i - start;
            n++;
            start = i + 1;
        }
    }
    return n;
}

static int pchal_salt_ok(const char *p, STRLEN l)
{
    STRLEN i;
    if (!l || l > PCHAL_MAX_SALT) return 0;
    for (i = 0; i < l; i++) {
        unsigned char c = (unsigned char)p[i];
        if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || c == '-'))
            return 0;
    }
    return 1;
}

static int pchal_mac_shape_ok(const char *p, STRLEN l)
{
    STRLEN i;
    if (l != PCHAL_MAC_LEN) return 0;
    for (i = 0; i < l; i++) {
        unsigned char c = (unsigned char)p[i];
        if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z')
              || (c >= 'A' && c <= 'Z') || c == '-' || c == '_'))
            return 0;
    }
    return 1;
}

/* ---- the MAC ------------------------------------------------------------------ */

/* "<dom>\0" subject "\0" a "\0" b ["\0" c]: the message a MAC is over. Mortal. */
static SV *pchal_mac_msg(pTHX_ const char *dom, STRLEN doml, SV *subject,
                         const char *a, STRLEN al, const char *b, STRLEN bl,
                         const char *c, STRLEN cl)
{
    STRLEN sl;
    const char *sp = SvPVbyte(subject, sl);
    SV *msg = sv_2mortal(newSVpvn(dom, doml));
    sv_catpvn(msg, "", 1);
    sv_catpvn(msg, sp, sl);
    sv_catpvn(msg, "", 1);
    sv_catpvn(msg, a, al);
    sv_catpvn(msg, "", 1);
    sv_catpvn(msg, b, bl);
    if (c) {
        sv_catpvn(msg, "", 1);
        sv_catpvn(msg, c, cl);
    }
    return msg;
}

/* HMAC under `key`, truncated to 16 bytes, base64url: PCHAL_MAC_LEN chars
 * into `out`, which must hold PCHAL_MAC_BUF. */
static void pchal_mac22(pTHX_ SV *key, SV *msg, char *out)
{
    STRLEN kl, ml;
    const unsigned char *k = (const unsigned char *)SvPVbyte(key, kl);
    const unsigned char *m = (const unsigned char *)SvPVbyte(msg, ml);
    unsigned char d[32];
    pchal_hmac_sha256(k, kl, m, ml, d);
    (void)pchal_b64url(d, 16, out);
}

/* The configured secrets, newest first. Never empty: boot refused that. */
static AV *pchal_secrets(pTHX_ HV *opts)
{
    SV *s = pchal_hget(aTHX_ opts, "secret");
    if (!pchal_is_array(s) || av_len((AV *)SvRV(s)) < 0)
        croak("%s: no secret configured", PCHAL_WHO);
    return (AV *)SvRV(s);
}

/* Does any configured secret sign `msg` as `mac`? First to last, so a
 * current secret costs one HMAC and a rotated-out one costs two. */
static int pchal_mac_any(pTHX_ HV *opts, SV *msg, const char *mac, STRLEN macl)
{
    AV *keys = pchal_secrets(aTHX_ opts);
    SSize_t i, n = av_len(keys) + 1;
    for (i = 0; i < n; i++) {
        SV **k = av_fetch(keys, i, 0);
        char out[PCHAL_MAC_BUF];
        if (!(k && *k)) continue;
        pchal_mac22(aTHX_ *k, msg, out);
        if (pchal_ct_eq(out, PCHAL_MAC_LEN, mac, macl)) return 1;
    }
    return 0;
}

static IV pchal_opt_iv_of(pTHX_ HV *opts, const char *k, IV dflt)
{
    SV *v = pchal_hget(aTHX_ opts, k);
    return v ? SvIV(v) : dflt;
}

static IV pchal_now(IV given)
{
    return given > 0 ? given : (IV)time(NULL);
}

/* ---- the puzzle --------------------------------------------------------------- */

static UV pchal_salt_counter = 0;

/* base 36, lowercase, into buf (at least 14 bytes). Returns the length. */
static STRLEN pchal_b36(UV v, char *buf)
{
    static const char digits[] = "0123456789abcdefghijklmnopqrstuvwxyz";
    char tmp[16];
    STRLEN n = 0, i;
    do { tmp[n++] = digits[v % 36]; v /= 36; } while (v);
    for (i = 0; i < n; i++) buf[i] = tmp[n - 1 - i];
    return n;
}

/* A fresh puzzle for `subject` at `bits`, signed with the first secret. A
 * new SV. */
static SV *pchal_puzzle_issue(pTHX_ HV *opts, SV *subject, IV bits, IV now)
{
    AV *keys = pchal_secrets(aTHX_ opts);
    SV *key = *av_fetch(keys, 0, 0);
    char salt[40], mac[PCHAL_MAC_BUF];
    STRLEN sl;
    SV *out, *msg;
    STRLEN tsl, bl, prefix;
    const char *tsp, *bp;

    sl = pchal_b36((UV)PerlProc_getpid(), salt);
    salt[sl++] = '-';
    sl += pchal_b36(pchal_salt_counter++, salt + sl);

    out = newSVpvs("v1.");
    prefix = SvCUR(out);
    sv_catpvf(out, "%" IVdf, pchal_now(now));
    tsp = SvPVX(out) + prefix;
    tsl = SvCUR(out) - prefix;
    sv_catpvs(out, ".");
    prefix = SvCUR(out);
    sv_catpvf(out, "%" IVdf, bits);
    /* the buffer may have moved: re-derive both */
    bp  = SvPVX(out) + prefix;
    bl  = SvCUR(out) - prefix;
    tsp = SvPVX(out) + 3;

    msg = pchal_mac_msg(aTHX_ "puzzle", 6, subject, tsp, tsl, bp, bl, salt, sl);
    pchal_mac22(aTHX_ key, msg, mac);

    sv_catpvs(out, ".");
    sv_catpvn(out, salt, sl);
    sv_catpvs(out, ".");
    sv_catpvn(out, mac, PCHAL_MAC_LEN);
    return out;
}

/* Verify a solution - a puzzle, a dot, a nonce - for `subject` against
 * `demanded` bits. On success *bits_out is the puzzle's own difficulty. */
static pchal_reason pchal_puzzle_verify(pTHX_ HV *opts, SV *subject,
                                        const char *s, STRLEN sl, IV demanded,
                                        IV now, IV *bits_out)
{
    const char *f[6];
    STRLEN fl[6];
    IV ts, bits, nonce;
    unsigned char d[32];

    /* 1. shape, with the size checked before anything looks inside */
    if (sl > PCHAL_MAX_TOKEN) return PCHAL_SHAPE;
    if (pchal_split(s, sl, f, fl, 6) != 6) return PCHAL_SHAPE;
    if (!(fl[0] == 2 && memEQ(f[0], "v1", 2))) return PCHAL_SHAPE;
    if (!pchal_dec(f[1], fl[1], &ts)) return PCHAL_SHAPE;
    if (fl[2] > 2 || !pchal_dec(f[2], fl[2], &bits)) return PCHAL_SHAPE;
    if (bits < 1 || bits > PCHAL_MAX_BITS) return PCHAL_SHAPE;
    if (!pchal_salt_ok(f[3], fl[3])) return PCHAL_SHAPE;
    if (!pchal_mac_shape_ok(f[4], fl[4])) return PCHAL_SHAPE;
    if (!pchal_dec(f[5], fl[5], &nonce)) return PCHAL_SHAPE;

    /* 2. freshness */
    now = pchal_now(now);
    if (ts > now && ts - now > PCHAL_FUTURE_SLACK) return PCHAL_FUTURE;
    if (ts < now && now - ts > pchal_opt_iv_of(aTHX_ opts, "puzzle_ttl", 300))
        return PCHAL_STALE;

    /* 3. the MAC, for this subject, against each secret */
    if (!pchal_mac_any(aTHX_ opts,
                       pchal_mac_msg(aTHX_ "puzzle", 6, subject, f[1], fl[1],
                                     f[2], fl[2], f[3], fl[3]),
                       f[4], fl[4]))
        return PCHAL_MAC;

    /* 4. at least what this rule demands */
    if (bits < demanded) return PCHAL_BITS;

    /* 5. the hash */
    pchal_sha256((const unsigned char *)s, sl, d);
    if (pchal_zero_bits(d, 32) < (int)bits) return PCHAL_HASH;

    *bits_out = bits;
    return PCHAL_OK;
}

/* ---- the clearance ------------------------------------------------------------ */

/* A clearance for `subject` at `bits`, expiring `ttl` from now. A new SV. */
static SV *pchal_clearance_issue(pTHX_ HV *opts, SV *subject, IV bits, IV now)
{
    AV *keys = pchal_secrets(aTHX_ opts);
    SV *key = *av_fetch(keys, 0, 0);
    char mac[PCHAL_MAC_BUF];
    SV *out, *msg;
    STRLEN el, bl, prefix;
    const char *ep, *bp;
    IV exp = pchal_now(now) + pchal_opt_iv_of(aTHX_ opts, "ttl", 3600);

    out = newSVpvs("v1.");
    prefix = SvCUR(out);
    sv_catpvf(out, "%" IVdf, exp);
    el = SvCUR(out) - prefix;
    sv_catpvs(out, ".");
    prefix = SvCUR(out);
    sv_catpvf(out, "%" IVdf, bits);
    bp = SvPVX(out) + prefix;
    bl = SvCUR(out) - prefix;
    ep = SvPVX(out) + 3;

    msg = pchal_mac_msg(aTHX_ "clear", 5, subject, ep, el, bp, bl, NULL, 0);
    pchal_mac22(aTHX_ key, msg, mac);

    sv_catpvs(out, ".");
    sv_catpvn(out, mac, PCHAL_MAC_LEN);
    return out;
}

/* One HMAC and two comparisons. On success *bits_out is the difficulty
 * that was solved. */
static pchal_reason pchal_clearance_verify(pTHX_ HV *opts, SV *subject,
                                           const char *s, STRLEN sl,
                                           IV demanded, IV now, IV *bits_out)
{
    const char *f[4];
    STRLEN fl[4];
    IV exp, bits;

    if (sl > PCHAL_MAX_TOKEN) return PCHAL_SHAPE;
    if (pchal_split(s, sl, f, fl, 4) != 4) return PCHAL_SHAPE;
    if (!(fl[0] == 2 && memEQ(f[0], "v1", 2))) return PCHAL_SHAPE;
    if (!pchal_dec(f[1], fl[1], &exp)) return PCHAL_SHAPE;
    if (fl[2] > 2 || !pchal_dec(f[2], fl[2], &bits)) return PCHAL_SHAPE;
    if (bits < 1 || bits > PCHAL_MAX_BITS) return PCHAL_SHAPE;
    if (!pchal_mac_shape_ok(f[3], fl[3])) return PCHAL_SHAPE;

    if (exp <= pchal_now(now)) return PCHAL_EXPIRED;

    if (!pchal_mac_any(aTHX_ opts,
                       pchal_mac_msg(aTHX_ "clear", 5, subject, f[1], fl[1],
                                     f[2], fl[2], NULL, 0),
                       f[3], fl[3]))
        return PCHAL_MAC;

    if (bits < demanded) return PCHAL_BITS;

    *bits_out = bits;
    return PCHAL_OK;
}

#endif /* PCHAL_TOKEN_H */

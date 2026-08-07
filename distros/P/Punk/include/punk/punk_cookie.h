/* punk_cookie.h - build a Set-Cookie header value, in C.
 *
 * The shared builder behind $c->cookie(...) and the session write-back. The
 * value is percent-encoded so it round-trips through Punk::Request's cookie
 * reader (pq_decode); a base64url session value passes through unchanged.
 * Options: path (default /), domain, max_age (seconds), samesite, secure,
 * httponly. An undef value emits a deletion cookie (Max-Age=0, past Expires).
 */

#ifndef PUNK_COOKIE_H
#define PUNK_COOKIE_H

/* percent-encode everything but the URI unreserved set, so ';' ',' space and
 * the rest cannot break the cookie and the reader decodes back exactly */
static void pk_cookie_encode(pTHX_ SV *out, const char *v, STRLEN vl) {
    static const char hex[] = "0123456789ABCDEF";
    STRLEN i;
    for (i = 0; i < vl; i++) {
        unsigned char c = (unsigned char)v[i];
        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
            || (c >= '0' && c <= '9')
            || c == '-' || c == '_' || c == '.' || c == '~')
            sv_catpvn(out, (const char *)&c, 1);
        else {
            char e[3];
            e[0] = '%'; e[1] = hex[c >> 4]; e[2] = hex[c & 0x0f];
            sv_catpvn(out, e, 3);
        }
    }
}

static SV *pk_build_cookie(pTHX_ SV *name, SV *value, HV *opts) {
    SV *out = newSVpvs("");
    STRLEN nl;
    const char *n = SvPV_const(name, nl);
    int deleting = !(value && SvOK(value));
    SV **o;
    sv_catpvn(out, n, nl);
    sv_catpvs(out, "=");
    if (!deleting) {
        STRLEN vl;
        const char *v = SvPV_const(value, vl);
        pk_cookie_encode(aTHX_ out, v, vl);
    }
    o = opts ? hv_fetchs(opts, "path", 0) : NULL;
    sv_catpvs(out, "; Path=");
    if (o && *o && SvOK(*o)) sv_catsv(out, *o); else sv_catpvs(out, "/");

    o = opts ? hv_fetchs(opts, "domain", 0) : NULL;
    if (o && *o && SvOK(*o)) { sv_catpvs(out, "; Domain="); sv_catsv(out, *o); }

    if (deleting)
        sv_catpvs(out, "; Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT");
    else {
        o = opts ? hv_fetchs(opts, "max_age", 0) : NULL;
        if (o && *o && SvOK(*o))
            sv_catpvf(out, "; Max-Age=%" IVdf, (IV)SvIV(*o));
    }

    o = opts ? hv_fetchs(opts, "samesite", 0) : NULL;
    if (o && *o && SvOK(*o)) { sv_catpvs(out, "; SameSite="); sv_catsv(out, *o); }

    o = opts ? hv_fetchs(opts, "secure", 0) : NULL;
    if (o && *o && SvTRUE(*o)) sv_catpvs(out, "; Secure");

    o = opts ? hv_fetchs(opts, "httponly", 0) : NULL;
    if (o && *o && SvTRUE(*o)) sv_catpvs(out, "; HttpOnly");

    return out;
}

#endif /* PUNK_COOKIE_H */

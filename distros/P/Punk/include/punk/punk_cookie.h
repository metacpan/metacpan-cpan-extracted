/* punk_cookie.h - build a Set-Cookie header value, in C.
 *
 * The shared builder behind $c->cookie(...) and the session write-back. The
 * value is percent-encoded so it round-trips through Punk::Request's cookie
 * reader (pq_decode); a base64url session value passes through unchanged.
 * Options: path (default /), domain, max_age (seconds), samesite, secure,
 * httponly. An undef value emits a deletion cookie (Max-Age=0, past Expires).
 *
 * The value is encoded; the name and the path, domain and samesite attributes
 * are not, so they are refused outright when they carry a `;` or a control
 * character. An attribute built from request input would otherwise be a way
 * to append attributes, or a header.
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

/* is `v` safe to write into a Set-Cookie verbatim? */
static int pk_cookie_safe(pTHX_ SV *v) {
    STRLEN l, i;
    const char *p = SvPV_const(v, l);
    for (i = 0; i < l; i++) {
        unsigned char c = (unsigned char)p[i];
        if (c < 0x20 || c == 0x7f || c == ';') return 0;
    }
    return 1;
}

static void pk_cookie_check(pTHX_ const char *what, SV *v) {
    if (!pk_cookie_safe(aTHX_ v))
        croak("Punk: a cookie %s may not contain ';' or a control "
              "character", what);
}

/* `secure_default` decides the Secure attribute when the options do not say:
 * the session passes whether the request arrived over https. */
static SV *pk_build_cookie_ex(pTHX_ SV *name, SV *value, HV *opts,
                              int secure_default) {
    SV *out;
    STRLEN nl;
    const char *n = SvPV_const(name, nl);
    int deleting = !(value && SvOK(value));
    SV **o;
    static const char *const attrs[] = { "path", "domain", "samesite", NULL };
    int i;
    if (!nl) croak("Punk: a cookie needs a name");
    pk_cookie_check(aTHX_ "name", name);
    if (memchr(n, '=', nl))
        croak("Punk: a cookie name may not contain '='");
    for (i = 0; opts && attrs[i]; i++) {
        o = hv_fetch(opts, attrs[i], (I32)strlen(attrs[i]), 0);
        if (o && *o && SvOK(*o)) pk_cookie_check(aTHX_ attrs[i], *o);
    }
    out = newSVpvs("");
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
    if ((o && *o && SvOK(*o)) ? SvTRUE(*o) : secure_default)
        sv_catpvs(out, "; Secure");

    o = opts ? hv_fetchs(opts, "httponly", 0) : NULL;
    if (o && *o && SvTRUE(*o)) sv_catpvs(out, "; HttpOnly");

    return out;
}

static SV *pk_build_cookie(pTHX_ SV *name, SV *value, HV *opts) {
    return pk_build_cookie_ex(aTHX_ name, value, opts, 0);
}

#endif /* PUNK_COOKIE_H */

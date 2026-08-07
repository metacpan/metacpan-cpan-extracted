/* punk_csrf.h - single-use CSRF tokens, in C.
 *
 * The token lives in the session (punk_session.h), which is a signed cookie:
 * mutating it dirties the session, and the after-dispatch write-back re-signs
 * the cookie for free. A successful check replaces the token, so a token is
 * good for exactly one unsafe request.
 *
 * What that does and does not give you, precisely: the server keeps no record
 * of spent tokens - there is no server-side session store - so this is
 * freshness, not one-time enforcement against a replayed *whole request*
 * (old cookie and old token together). For CSRF that is the right trade: the
 * attacker's whole problem is that they cannot read the token cross-origin,
 * and anyone who can present the session cookie already has the session.
 *
 * Include after punk_session.h (ps_cfg / ps_load / ps_stash) and
 * punk_cookie.h (pk_build_cookie).
 */

#ifndef PUNK_CSRF_H
#define PUNK_CSRF_H

#ifdef PUNK_HAVE_GETENTROPY
#  ifdef PUNK_GETENTROPY_SYS_RANDOM
#    include <sys/random.h>
#  else
#    include <unistd.h>
#  endif
#endif

/* the session key the token sits under - namespaced so an application's own
 * session data can never collide with it */
#define PC_SESSION_KEY "punk.csrf"
#define PC_STASH_DIRTY "punk.csrf.set"

/* ---- randomness ----------------------------------------------------------- */

/* Fill out with n cryptographically random bytes. getentropy where the build
 * probe found it, otherwise a cached /dev/urandom descriptor. Croaks rather
 * than falling back to anything weaker: a guessable CSRF token is worse than a
 * server that will not start. */
static int pk_urandom_fd = -1;

static void pk_random_bytes(pTHX_ unsigned char *out, size_t n) {
#ifdef PUNK_HAVE_GETENTROPY
    size_t off = 0;
    while (off < n) {
        size_t want = n - off;
        if (want > 256) want = 256;         /* getentropy's documented maximum */
        if (getentropy(out + off, want) != 0)
            croak("Punk::CSRF: getentropy failed: %s", Strerror(errno));
        off += want;
    }
#else
    size_t off = 0;
    if (pk_urandom_fd < 0) {
        pk_urandom_fd = PerlLIO_open3("/dev/urandom", O_RDONLY, 0);
        if (pk_urandom_fd < 0)
            croak("Punk::CSRF: cannot open /dev/urandom: %s", Strerror(errno));
    }
    while (off < n) {
        SSize_t got = PerlLIO_read(pk_urandom_fd, out + off, n - off);
        if (got <= 0) croak("Punk::CSRF: short read from /dev/urandom");
        off += (size_t)got;
    }
#endif
}

/* 32 random bytes as base64url, no padding - 43 characters. */
static SV *pcf_mint(pTHX) {
    unsigned char raw[32];
    pk_random_bytes(aTHX_ raw, sizeof raw);
    return pk_b64url(aTHX_ raw, sizeof raw);
}

/* Constant time, and length-independent in the branch it takes: a token
 * comparison that returned early would leak the matching prefix. */
static int pk_ct_eq(const char *a, STRLEN alen, const char *b, STRLEN blen) {
    volatile unsigned char diff = (unsigned char)((alen ^ blen) != 0);
    STRLEN i;
    if (!alen || !blen) return 0;
    for (i = 0; i < alen; i++)
        diff |= (unsigned char)(a[i] ^ b[i % blen]);
    return diff == 0;
}

/* Escape for an HTML attribute. The token is base64url and needs none of
 * this, but the field name is configurable and lands in the same markup. */
static void pcf_attr_escape(pTHX_ SV *out, const char *p, STRLEN len) {
    STRLEN i, start = 0;
    for (i = 0; i < len; i++) {
        const char *rep = NULL;
        switch (p[i]) {
            case '&':  rep = "&amp;";  break;
            case '<':  rep = "&lt;";   break;
            case '>':  rep = "&gt;";   break;
            case '"':  rep = "&quot;"; break;
            case '\'': rep = "&#39;";  break;
            default: continue;
        }
        if (i > start) sv_catpvn(out, p + start, i - start);
        sv_catpv(out, rep);
        start = i + 1;
    }
    if (len > start) sv_catpvn(out, p + start, len - start);
}

/* ---- configuration -------------------------------------------------------- */

/* the csrf config the keyword froze on the app, or NULL when it is not on */
static HV *pcf_cfg(pTHX_ SV *c) {
    SV *app = pcx_get(aTHX_ pcx_av(aTHX_ c), PCX_APP);
    SV **s;
    if (!(app && SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV)) return NULL;
    s = hv_fetchs((HV *)SvRV(app), K_CSRF, 0);
    return (s && *s && SvROK(*s) && SvTYPE(SvRV(*s)) == SVt_PVHV)
        ? (HV *)SvRV(*s) : NULL;
}

static IV pcf_cfg_iv(pTHX_ HV *cfg, const char *k, IV def) {
    SV **e = hv_fetch(cfg, k, (I32)strlen(k), 0);
    return (e && *e && SvOK(*e)) ? SvIV(*e) : def;
}

/* ---- the token in the session --------------------------------------------- */

/* The session hashref (+1 from ps_load, mortalised here for the caller). */
static HV *pcf_session(pTHX_ SV *c) {
    SV *rv = ps_load(aTHX_ c);
    sv_2mortal(rv);
    return (SvROK(rv) && SvTYPE(SvRV(rv)) == SVt_PVHV) ? (HV *)SvRV(rv) : NULL;
}

/* Mark the token changed, so the mirror cookie is written for this response. */
static void pcf_mark_dirty(pTHX_ SV *c) {
    HV *stash = ps_stash(aTHX_ pcx_av(aTHX_ c));
    (void)hv_stores(stash, PC_STASH_DIRTY, newSViv(1));
}

/* The current token, minting one when there is none. `keep` tokens are held
 * as a list; the shipped default is 1, which is the strict single-token
 * behaviour - the list exists so widening it later is configuration rather
 * than a redesign. Element 0 is always the newest. */
static SV *pcf_token(pTHX_ SV *c, int mint) {
    HV *sess = pcf_session(aTHX_ c);
    SV **slot;
    AV *toks;
    if (!sess) return NULL;

    slot = hv_fetchs(sess, PC_SESSION_KEY, 0);
    if (slot && *slot && SvROK(*slot) && SvTYPE(SvRV(*slot)) == SVt_PVAV) {
        toks = (AV *)SvRV(*slot);
        if (av_len(toks) >= 0) {
            SV **t = av_fetch(toks, 0, 0);
            if (t && *t && SvOK(*t)) return *t;      /* borrowed */
        }
    }
    else {
        if (!mint) return NULL;
        toks = newAV();
        (void)hv_stores(sess, PC_SESSION_KEY, newRV_noinc((SV *)toks));
    }
    if (!mint) return NULL;
    av_unshift(toks, 1);
    (void)av_store(toks, 0, pcf_mint(aTHX));
    pcf_mark_dirty(aTHX_ c);
    {
        SV **t = av_fetch(toks, 0, 0);
        return (t && *t) ? *t : NULL;
    }
}

/* Spend `given`: drop it from the list and put a fresh one at the head. The
 * drop is what makes the token single-use - the same value never validates
 * twice, because the session it was checked against no longer holds it. */
static void pcf_rotate(pTHX_ SV *c, SV *given, IV keep) {
    HV *sess = pcf_session(aTHX_ c);
    SV **slot;
    AV *toks, *next;
    SSize_t i, n;
    STRLEN gl;
    const char *g;
    if (!sess) return;
    slot = hv_fetchs(sess, PC_SESSION_KEY, 0);
    if (!(slot && *slot && SvROK(*slot) && SvTYPE(SvRV(*slot)) == SVt_PVAV))
        return;
    toks = (AV *)SvRV(*slot);
    g = SvPV_const(given, gl);

    next = newAV();
    av_push(next, pcf_mint(aTHX));
    n = av_len(toks) + 1;
    for (i = 0; i < n && av_len(next) + 1 < keep; i++) {
        SV **t = av_fetch(toks, i, 0);
        STRLEN tl;
        const char *tv;
        if (!(t && *t && SvOK(*t))) continue;
        tv = SvPV_const(*t, tl);
        if (tl == gl && memEQ(tv, g, tl)) continue;   /* the one just spent */
        av_push(next, newSVsv(*t));
    }
    (void)hv_stores(sess, PC_SESSION_KEY, newRV_noinc((SV *)next));
    pcf_mark_dirty(aTHX_ c);
}

/* Does any live token match? */
static int pcf_accepts(pTHX_ SV *c, SV *given) {
    HV *sess = pcf_session(aTHX_ c);
    SV **slot;
    AV *toks;
    SSize_t i, n;
    STRLEN gl;
    const char *g;
    if (!sess || !given || !SvOK(given)) return 0;
    g = SvPV_const(given, gl);
    if (!gl) return 0;
    slot = hv_fetchs(sess, PC_SESSION_KEY, 0);
    if (!(slot && *slot && SvROK(*slot) && SvTYPE(SvRV(*slot)) == SVt_PVAV))
        return 0;
    toks = (AV *)SvRV(*slot);
    n = av_len(toks) + 1;
    for (i = 0; i < n; i++) {
        SV **t = av_fetch(toks, i, 0);
        STRLEN tl;
        const char *tv;
        if (!(t && *t && SvOK(*t))) continue;
        tv = SvPV_const(*t, tl);
        if (pk_ct_eq(tv, tl, g, gl)) return 1;
    }
    return 0;
}

/* ---- reading what the client sent ----------------------------------------- */

static SV *pcf_env_str(pTHX_ SV *c, const char *key) {
    SV *env = pcx_get(aTHX_ pcx_av(aTHX_ c), PCX_ENV);
    SV **e;
    if (!(env && SvROK(env) && SvTYPE(SvRV(env)) == SVt_PVHV)) return NULL;
    e = hv_fetch((HV *)SvRV(env), key, (I32)strlen(key), 0);
    return (e && *e && SvOK(*e)) ? *e : NULL;
}

/* The submitted token: the header first, then the form field.
 *
 * The field is only looked at for urlencoded bodies under max_body, and this
 * is not fussiness - pq_body reads the whole body into memory on first touch,
 * so reaching for the field on a multipart upload would pull the upload into
 * memory before the mount's own max_body_size check could refuse it. Uploads
 * send the header. */
static SV *pcf_submitted(pTHX_ SV *c, HV *cfg) {
    STRLEN l;
    const char *hdr = ps_cfg_str(aTHX_ cfg, "header", "X-CSRF-Token", &l);
    SV *v;
    {   /* X-CSRF-Token -> HTTP_X_CSRF_TOKEN */
        char env[128];
        STRLEN i;
        if (l > sizeof(env) - 6) return NULL;
        memcpy(env, "HTTP_", 5);
        for (i = 0; i < l; i++) {
            char ch = hdr[i];
            env[5 + i] = (ch == '-') ? '_' : (char)toUPPER((U8)ch);
        }
        env[5 + l] = '\0';
        v = pcf_env_str(aTHX_ c, env);
        if (v && SvCUR(v)) return v;
    }

    {
        SV *ct = pcf_env_str(aTHX_ c, "CONTENT_TYPE");
        SV *cl = pcf_env_str(aTHX_ c, "CONTENT_LENGTH");
        IV  max = pcf_cfg_iv(aTHX_ cfg, "max_body", 65536);
        const char *field;
        STRLEN fl;
        SV *req, *argv[1], *got;
        if (!ct) return NULL;
        if (!strnEQ(SvPVX(ct), "application/x-www-form-urlencoded", 33))
            return NULL;
        if (cl && SvIV(cl) > max) return NULL;

        field = ps_cfg_str(aTHX_ cfg, "field", "_csrf", &fl);
        req = pcx_force(aTHX_ pcx_av(aTHX_ c), PCX_REQ, "Punk::Request",
                        pcx_get(aTHX_ pcx_av(aTHX_ c), PCX_ENV));
        argv[0] = sv_2mortal(newSVpvn(field, fl));
        got = pcx_call_meth(aTHX_ req, "param", argv, 1, 1);
        if (got) sv_2mortal(got);
        return (got && SvOK(got) && SvCUR(got)) ? got : NULL;
    }
}

/* ---- the check ------------------------------------------------------------ */

static int pcf_safe_method(const char *m, STRLEN l) {
    return (l == 3 && memEQ(m, "GET", 3))
        || (l == 4 && memEQ(m, "HEAD", 4))
        || (l == 7 && memEQ(m, "OPTIONS", 7))
        || (l == 5 && memEQ(m, "TRACE", 5));
}

static int pcf_exempt(pTHX_ HV *cfg, SV *path) {
    SV **e = hv_fetchs(cfg, "exempt", 0);
    AV *list;
    SSize_t i, n;
    STRLEN pl;
    const char *p;
    if (!(e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVAV)) return 0;
    if (!(path && SvOK(path))) return 0;
    list = (AV *)SvRV(*e);
    p = SvPV_const(path, pl);
    n = av_len(list) + 1;
    for (i = 0; i < n; i++) {
        SV **x = av_fetch(list, i, 0);
        STRLEN xl;
        const char *xv;
        if (!(x && *x && SvOK(*x))) continue;
        xv = SvPV_const(*x, xl);
        if (xl <= pl && memEQ(p, xv, xl)) return 1;   /* prefix match */
    }
    return 0;
}

/* The 403, in the shape everything else in Punk answers errors with. */
static SV *pcf_refuse(pTHX_ SV *c, HV *cfg) {
    SV **h = hv_fetchs(cfg, "on_error", 0);
    if (h && *h && SvROK(*h) && SvTYPE(SvRV(*h)) == SVt_PVCV) {
        int died = 0;
        SV *r = pcx_call2(aTHX_ *h, c, &PL_sv_undef, &died);
        if (!died && r) return r;
        if (r) SvREFCNT_dec(r);
    }
    return punk_triplet(aTHX_ 403,
        sv_2mortal(newSVpvs("application/json")),
        newSVpvs("{\"errors\":[{\"message\":\"invalid csrf token\"}]}"),
        NULL);
}

/* The before-dispatch hook: a reference return short-circuits the request, so
 * a refusal answers before any guard or handler runs. */
static SV *pcf_check(pTHX_ SV *c) {
    HV *cfg = pcf_cfg(aTHX_ c);
    SV *method, *given;
    STRLEN ml;
    const char *m;
    if (!cfg) return NULL;

    method = pcf_env_str(aTHX_ c, "REQUEST_METHOD");
    m = method ? SvPV_const(method, ml) : "GET";
    if (!method) ml = 3;
    if (pcf_safe_method(m, ml)) return NULL;

    /* Not riding on cookies, so not a CSRF target. */
    if (pcf_env_str(aTHX_ c, "HTTP_AUTHORIZATION")) return NULL;
    if (pcf_exempt(aTHX_ cfg, pcf_env_str(aTHX_ c, "PATH_INFO"))) return NULL;

    given = pcf_submitted(aTHX_ c, cfg);
    if (!pcf_accepts(aTHX_ c, given)) return pcf_refuse(aTHX_ c, cfg);

    pcf_rotate(aTHX_ c, given, pcf_cfg_iv(aTHX_ cfg, "keep", 1));
    return NULL;
}

/* ---- the mirror cookie ---------------------------------------------------- */

/* The token also goes out in a cookie the browser will let script read, which
 * is how fetch and Open::API::UI's try-it-out get hold of it. It is not the
 * authority - the session is - so a forged one proves nothing. */
static void pcf_writeback(pTHX_ SV *c, SV *resp) {
    HV *cfg = pcf_cfg(aTHX_ c);
    AV *av, *r, *headers;
    HV *stash, *ckopts;
    SV **hp, **dirty;
    SV *tok, *name;
    STRLEN nl;
    const char *cookie_name;
    if (!cfg) return;
    av = pcx_av(aTHX_ c);
    {
        SV *st = pcx_get(aTHX_ av, PCX_STASH);
        if (!(st && SvROK(st))) return;
        stash = (HV *)SvRV(st);
    }
    dirty = hv_fetchs(stash, PC_STASH_DIRTY, 0);
    if (!(dirty && *dirty && SvTRUE(*dirty))) return;
    if (!(SvROK(resp) && SvTYPE(SvRV(resp)) == SVt_PVAV)) return;
    r = (AV *)SvRV(resp);
    hp = av_fetch(r, 1, 0);
    if (!(hp && *hp && SvROK(*hp) && SvTYPE(SvRV(*hp)) == SVt_PVAV)) return;
    headers = (AV *)SvRV(*hp);

    tok = pcf_token(aTHX_ c, 0);
    if (!tok) return;

    /* the session's cookie attributes, minus HttpOnly - script has to read it */
    ckopts = (HV *)sv_2mortal((SV *)newHV());
    {
        HV *scfg = ps_cfg(aTHX_ c);
        static const char *const copy[] = { "path", "domain", "secure",
                                            "samesite", "max_age", NULL };
        int i;
        for (i = 0; scfg && copy[i]; i++) {
            SV **e = hv_fetch(scfg, copy[i], (I32)strlen(copy[i]), 0);
            if (e && *e && SvOK(*e))
                (void)hv_store(ckopts, copy[i], (I32)strlen(copy[i]),
                               newSVsv(*e), 0);
        }
        (void)hv_stores(ckopts, "httponly", newSViv(0));
    }

    cookie_name = ps_cfg_str(aTHX_ cfg, "cookie", "csrf", &nl);
    name = sv_2mortal(newSVpvn(cookie_name, nl));
    av_push(headers, newSVpvs("Set-Cookie"));
    av_push(headers, pk_build_cookie(aTHX_ name, tok, ckopts));
}

#endif /* PUNK_CSRF_H */

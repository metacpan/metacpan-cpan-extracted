#ifndef PUNK_LANG_H
#define PUNK_LANG_H

/* Accept-Language negotiation.
 *
 * ---- why this is not punk_accept.h ----------------------------------------
 *
 * punk_accept.h looks like it already does this, and it does the hard half:
 * q-values, the ordering they imply, and the rule that `q=0` is an EXCLUSION
 * rather than an absence. All of that is reused - pa_q_of is called directly.
 *
 * What it cannot do is parse the header. pa_parse accepts a segment only when
 * it finds a slash in it, or when the segment is a bare `*`:
 *
 *     if (slash < sub_end && slash > p && sub_end > slash + 1) { ... }
 *     else if (sub_end == p + 1 && *p == '*')                  { ... }
 *
 * A language tag has no slash, so `Accept-Language: en-GB,en;q=0.9` parses to
 * ZERO ranges through it, and pa_range has nowhere to put a tag that is not
 * type/subtype. Hence a sibling parser, in the same style: parse in place, a
 * bounded number of stack entries, no allocation, and a malformed header
 * ignored rather than fatal - a client must not be able to error a response
 * with a bad header.
 *
 * ---- and why the MATCH is not the same either -----------------------------
 *
 * Media ranges have a three-rung specificity ladder: exact, "type slash star", and the bare wildcard.
 * Language tags have prefix fallback, which is asymmetric:
 *
 *   - `en-GB` requested matches a catalogue holding `en`. Truncate the
 *     request at `-` and try again: zh-Hant-TW, zh-Hant, zh.
 *   - `en` requested does NOT match a catalogue holding only `en-GB`. Serving
 *     pt-BR to a request for pt is how a Portuguese speaker gets Brazilian
 *     spelling with no way to refuse. An application that wants that can
 *     configure an alias.
 *   - The truncation is on SUBTAG BOUNDARIES, never a byte prefix. `en` must
 *     not match `ens`, which is what a bare strncmp would do.
 */

#define PL_TAG_MAX_N 32        /* the sibling of PA_RANGE_MAX */

typedef struct pl_tag {
    const char *t; STRLEN tl;  /* the tag, pointing into the header */
    int q;                     /* per mille: 0..1000 */
} pl_tag;

/* Parse an Accept-Language into `out`. Returns how many tags were taken.
 * Anything past PL_TAG_MAX_N is ignored; so is a segment with no shape. */
static int pl_parse(const char *a, STRLEN al, pl_tag *out, int max) {
    const char *p = a, *end = a + al;
    int n = 0;
    while (p < end && n < max) {
        const char *seg_end = p, *tag_end, *par;
        while (seg_end < end && *seg_end != ',') seg_end++;
        while (p < seg_end && pa_ws(*p)) p++;
        par = p;
        while (par < seg_end && *par != ';') par++;
        tag_end = par;
        while (tag_end > p && pa_ws(tag_end[-1])) tag_end--;

        if (tag_end > p && (STRLEN)(tag_end - p) <= PI_TAG_MAX) {
            /* A tag is alphanumerics and hyphens, or the wildcard. Anything
             * else is a header this code should not be guessing about. */
            const char *q;
            int ok = 1;
            if (!(tag_end == p + 1 && *p == '*')) {
                for (q = p; q < tag_end; q++) {
                    char c = *q;
                    if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
                          || (c >= '0' && c <= '9') || c == '-')) { ok = 0; break; }
                }
            }
            if (ok) {
                out[n].t  = p;
                out[n].tl = (STRLEN)(tag_end - p);
                out[n].q  = pa_q_of(par, seg_end);
                n++;
            }
        }
        p = seg_end + 1;
    }
    return n;
}

static int pl_star(const char *s, STRLEN l) { return l == 1 && *s == '*'; }

/* Does the catalogue tag `c` satisfy the requested tag `t`?
 *
 * Returns the specificity of the match - 2 exact, 1 through prefix fallback,
 * 0 the wildcard, -1 no match - mirroring pa_match, because the RFC rule that
 * the MOST SPECIFIC match decides the q-value is the same rule here. */
static int pl_spec(const char *t, STRLEN tl, const char *c, STRLEN cl) {
    if (pl_star(t, tl)) return 0;
    if (pi_tag_eq(t, tl, c, cl)) return 2;
    /* The catalogue tag must be a prefix of the REQUESTED one, on a subtag
     * boundary. Never the other way round. */
    if (cl < tl && t[cl] == '-' && pi_tag_eq(t, cl, c, cl)) return 1;
    return -1;
}

/* Which catalogue does this header ask for? Returns an index into the arena,
 * or -1 when nothing is acceptable.
 *
 * A catalogue's score is the q of the most specific tag that matches it, and
 * a q of 0 there is an exclusion: `fr;q=0, *` means never French, including
 * through the wildcard, which is the case naive negotiators get wrong.
 * Ties break on specificity, then on the order the tags appeared. */
static int pl_pick(const pl_tag *tags, int n, const pi_arena *ar) {
    int i, best = -1, best_q = 0, best_spec = -1, best_order = 0;

    if (!ar) return -1;
    for (i = 0; i < ar->ncat; i++) {
        const pi_cat *c = &ar->cat[i];
        int j, q = -1, spec = -1, order = 0;

        for (j = 0; j < n; j++) {
            int s = pl_spec(tags[j].t, tags[j].tl, c->tag, c->taglen);
            if (s > spec) { spec = s; q = tags[j].q; order = j; }
        }
        if (spec < 0 || q <= 0) continue;   /* unmentioned, or excluded */

        if (q > best_q
            || (q == best_q && spec > best_spec)
            || (q == best_q && spec == best_spec && order < best_order)) {
            best = i; best_q = q; best_spec = spec; best_order = order;
        }
    }
    return best;
}

/* The whole header to an index, or -1. */
static int pl_negotiate(const char *hdr, STRLEN hl, const pi_arena *ar) {
    pl_tag tags[PL_TAG_MAX_N];
    int n;
    if (!hdr || !hl || !ar) return -1;
    n = pl_parse(hdr, hl, tags, PL_TAG_MAX_N);
    if (!n) return -1;
    return pl_pick(tags, n, ar);
}

/* An explicitly named locale - from ?lang= or a stored choice - to an index.
 *
 * Exact first, then the same prefix fallback the header gets, so `?lang=en-GB`
 * lands on the `en` catalogue rather than falling through to the default. A
 * name with no catalogue is NOT an error: it falls through to the next source.
 * A 500 on a hand-edited URL is a worse answer than the default language, and
 * ?lang= is exactly the parameter people hand-edit.
 */
static int pl_named(const char *tag, STRLEN tl, const pi_arena *ar) {
    int i, best = -1;
    STRLEN bestlen = 0;
    if (!tag || !tl || !ar || tl > PI_TAG_MAX) return -1;
    for (i = 0; i < ar->ncat; i++) {
        const pi_cat *c = &ar->cat[i];
        int s = pl_spec(tag, tl, c->tag, c->taglen);
        if (s == 2) return i;
        if (s == 1 && c->taglen > bestlen) { best = i; bestlen = c->taglen; }
    }
    return best;
}

/* ---- the order a language is chosen ---------------------------------------
 *
 * Explicit beats implicit, most explicit first:
 *
 *   1. ?lang=      - an explicit act by the user, on this request
 *   2. the stored choice (session, or a cookie) - an explicit act on an
 *      earlier one
 *   3. Accept-Language - what the browser was configured with, which is
 *      frequently not what the user wants and is never something they did on
 *      this site
 *   4. the configured default
 *
 * 2 is what makes a language switcher work on the SECOND page. Without it an
 * explicit choice loses to the browser on the next link, and the switcher
 * appears to be broken - which it is.
 */

#define PL_ENV_KEY "punk.i18n_locale"

typedef struct pl_choice {
    int  idx;        /* catalogue index */
    int  explicit_;  /* the request named it, so it is worth persisting */
} pl_choice;

/* Resolve, given the pieces. Kept free of the context so it can be tested
 * directly: every interesting case here is a table. */
static pl_choice pl_resolve(const char *param, STRLEN paraml,
                            const char *stored, STRLEN storedl,
                            const char *header, STRLEN headerl,
                            const pi_arena *ar) {
    pl_choice ch;
    ch.idx = -1;
    ch.explicit_ = 0;

    if (param && paraml) {
        ch.idx = pl_named(param, paraml, ar);
        if (ch.idx >= 0) { ch.explicit_ = 1; return ch; }
        /* named a locale with no catalogue: fall through, never 500 */
    }
    if (stored && storedl) {
        ch.idx = pl_named(stored, storedl, ar);
        if (ch.idx >= 0) return ch;
    }
    if (header && headerl) {
        ch.idx = pl_negotiate(header, headerl, ar);
        if (ch.idx >= 0) return ch;
    }
    ch.idx = ar ? ar->def : -1;
    return ch;
}

/* ---- one lookup, two callers ----------------------------------------------
 *
 * `$c->locale` and the template's `locale` hash must agree about what a key
 * resolves to, what counts as untranslated, and when a missing key warns.
 * Two implementations of that would drift, and the drift would be silent:
 * a page whose handler strings are fine and whose template strings are not.
 */
#define PI_HIT     0   /* a translation */
#define PI_LEVEL   1   /* a level - keys continue below this one */
#define PI_MISSING 2   /* nowhere at all */

static int pi_lookup(pTHX_ const pi_arena *ar, const pi_cat *cat,
                     const char *k, STRLEN kl, const char **vp, STRLEN *vl) {
    const pi_cat *d;

    *vp = pi_get(cat, k, kl, vl);
    if (*vp) return PI_HIT;

    /* The default catalogue before giving up: a key present in `en` and
     * missing from `fr-CA` is UNTRANSLATED, not missing. */
    d = (ar && ar->def >= 0) ? &ar->cat[ar->def] : NULL;
    if (d && d != cat) {
        *vp = pi_get(d, k, kl, vl);
        if (*vp) { pi_n_untranslated++; return PI_HIT; }
    }

    if (pi_is_prefix(cat, k, kl) || (d && d != cat && pi_is_prefix(d, k, kl)))
        return PI_LEVEL;

    pi_n_missing++;
    return PI_MISSING;
}

/* ---- the request side ------------------------------------------------------
 *
 * Everything below needs punk_context.h, so this header is included after it.
 */

/* The plugin's config, off the app the context carries. */
static HV *pi_cfg_of(pTHX_ SV *c) {
    AV *av;
    SV *app, **e;
    if (!c || !SvROK(c)) return NULL;
    av = pcx_av(aTHX_ c);
    if (!av) return NULL;
    app = pcx_get(aTHX_ av, PCX_APP);
    if (!(app && SvROK(app) && SvTYPE(SvRV(app)) == SVt_PVHV)) return NULL;
    e = hv_fetchs((HV *)SvRV(app), K_I18N, 0);
    return (e && *e && SvROK(*e) && SvTYPE(SvRV(*e)) == SVt_PVHV)
        ? (HV *)SvRV(*e) : NULL;
}

/* Is this application in development?
 *
 * Frozen into the config at compile time, the way CSP does it: `plugin` is
 * written at the top of an application and `config` below it, so at
 * registration time the answer is not known yet.
 *
 * A missing key on a production page is ALREADY visible - it renders as the
 * key - so warning about it there is a log line per request telling somebody
 * something they can see and cannot act on at that moment. */
static int pi_dev(pTHX_ HV *cfg) {
    SV **e = cfg ? hv_fetchs(cfg, "dev", 0) : NULL;
    PERL_UNUSED_CONTEXT;
    return (e && *e && SvTRUE(*e));
}

/* Warn once per key, through the application's own logger. */
static void pi_warn_missing(pTHX_ SV *c, const char *k, STRLEN kl) {
    dSP;
    SV *msg;

    if (!pi_seen) pi_seen = newHV();
    if (hv_exists(pi_seen, k, (I32)kl)) return;
    (void)hv_store(pi_seen, k, (I32)kl, &PL_sv_yes, 0);

    msg = sv_2mortal(newSVpvf(
        "i18n: no translation for '%.*s' in any catalogue - it is rendering "
        "as the key", (int)kl, k));

    ENTER; SAVETMPS;
    PUSHMARK(SP); EXTEND(SP, 1); PUSHs(c); PUTBACK;
    if (call_method("log", G_SCALAR | G_EVAL) > 0) {
        SV *lg = SvREFCNT_inc(POPs);
        PUTBACK;
        if (!SvTRUE(ERRSV) && SvOK(lg)) {
            PUSHMARK(SP); EXTEND(SP, 2);
            PUSHs(lg); PUSHs(msg);
            PUTBACK;
            (void)call_method("warn", G_DISCARD | G_EVAL);
            SPAGAIN;
        }
        SvREFCNT_dec(lg);
    }
    else PUTBACK;
    FREETMPS; LEAVE;
    pi_n_warned++;
}

/* One level of the `locale` hash a template reads. punk_i18n.h says why it is
 * tied rather than built, and what it needed from Template::Stencil 0.10. */
static SV *pi_tied_hash(pTHX_ pi_arena *ar, int idx, SV *prefix, HV *cfg,
                        SV *c) {
    AV *o = newAV();
    HV *h = newHV();
    SV *obj;

    av_extend(o, 4);
    av_store(o, PIT_ARENA,  newSViv(PTR2IV(ar)));
    av_store(o, PIT_CAT,    newSViv(idx));
    av_store(o, PIT_PREFIX, prefix ? newSVsv(prefix) : newSV(0));
    av_store(o, PIT_CFG,    cfg ? newRV_inc((SV *)cfg) : newSV(0));
    av_store(o, PIT_CTX,    c ? newSVsv(c) : newSV(0));

    obj = sv_bless(newRV_noinc((SV *)o),
                   gv_stashpv("Punk::Plugin::I18n::Cat", GV_ADD));
    hv_magic(h, (GV *)obj, PERL_MAGIC_tied);
    SvREFCNT_dec(obj);          /* hv_magic took its own reference */
    return newRV_noinc((SV *)h);
}

static pi_arena *pi_arena_of(pTHX_ HV *cfg) {
    SV **e = cfg ? hv_fetchs(cfg, "_arena", 0) : NULL;
    return (e && *e && SvIOK(*e)) ? INT2PTR(pi_arena *, SvIV(*e)) : NULL;
}

static const char *pi_cfg_str(pTHX_ HV *cfg, const char *k, const char *dflt,
                              STRLEN *len) {
    SV **e = cfg ? hv_fetch(cfg, k, (I32)strlen(k), 0) : NULL;
    if (e && *e && SvOK(*e)) return SvPV_const(*e, *len);
    *len = strlen(dflt);
    return dflt;
}

/* One cookie's value out of a Cookie header, or NULL. Points into the
 * header's own bytes. */
static const char *pi_cookie(const char *h, STRLEN hl, const char *n,
                             STRLEN nl, STRLEN *vl) {
    STRLEN i = 0;
    while (i < hl) {
        STRLEN start, eq, end;
        while (i < hl && (h[i] == ' ' || h[i] == ';' || h[i] == '\t')) i++;
        start = i;
        while (i < hl && h[i] != '=' && h[i] != ';') i++;
        if (i >= hl || h[i] != '=') { while (i < hl && h[i] != ';') i++; continue; }
        eq = i++;
        end = i;
        while (end < hl && h[end] != ';') end++;
        if (eq - start == nl && memcmp(h + start, n, nl) == 0) {
            *vl = end - i;
            return h + i;
        }
        i = end;
    }
    return NULL;
}

/* Resolve this request's catalogue, once, and remember it in the env.
 *
 * The env rather than a C static: Punk dispatches asynchronously through
 * Punk::Future, so a worker can have several requests in flight at once and a
 * "current locale" in a static would render one user's page in another user's
 * language - invisibly, and only under load.
 */
static const pi_cat *pi_for_request(pTHX_ SV *c, HV *cfg, pi_arena *ar) {
    AV *av;
    SV *esv, **cached;
    HV *env;
    const char *pp = NULL, *sp = NULL, *hp = NULL;
    STRLEN pl = 0, sl = 0, hl = 0;
    SV *pv = NULL;
    pl_choice ch;

    if (!ar || !ar->ncat) return NULL;
    av = pcx_av(aTHX_ c);
    if (!av) return NULL;
    esv = pcx_get(aTHX_ av, PCX_ENV);
    if (!(esv && SvROK(esv) && SvTYPE(SvRV(esv)) == SVt_PVHV))
        return (ar->def >= 0) ? &ar->cat[ar->def] : NULL;
    env = (HV *)SvRV(esv);

    cached = hv_fetchs(env, PL_ENV_KEY, 0);
    if (cached && *cached && SvIOK(*cached)) {
        IV i = SvIV(*cached);
        if (i >= 0 && i < ar->ncat) return &ar->cat[i];
    }

    {   /* 1. ?lang= */
        STRLEN nl;
        const char *pname = pi_cfg_str(aTHX_ cfg, "param", "lang", &nl);
        SV *nsv = sv_2mortal(newSVpvn(pname, nl));
        pv = pcx_param(aTHX_ av, nsv);
        if (pv && SvOK(pv)) pp = SvPV_const(pv, pl);
    }
    {   /* 2. the stored choice */
        STRLEN nl;
        const char *cname = pi_cfg_str(aTHX_ cfg, "cookie", "punk.lang", &nl);
        SV **ck = hv_fetchs(env, "HTTP_COOKIE", 0);
        if (ck && *ck && SvOK(*ck)) {
            STRLEN chl;
            const char *chp = SvPV_const(*ck, chl);
            sp = pi_cookie(chp, chl, cname, nl, &sl);
        }
    }
    {   /* 3. Accept-Language */
        SV **al = hv_fetchs(env, "HTTP_ACCEPT_LANGUAGE", 0);
        if (al && *al && SvOK(*al)) hp = SvPV_const(*al, hl);
    }

    ch = pl_resolve(pp, pl, sp, sl, hp, hl, ar);
    if (ch.idx < 0) return NULL;

    (void)hv_stores(env, PL_ENV_KEY, newSViv(ch.idx));
    /* An explicit choice is worth remembering, or the switcher works once and
     * appears broken on the next link. The env flag is what the response path
     * reads to decide whether to write the cookie. */
    if (ch.explicit_) (void)hv_stores(env, PL_ENV_KEY "_set", newSViv(1));
    return &ar->cat[ch.idx];
}

/* Put this request's catalogue into the variables a template is about to be
 * rendered with, so `{% locale.welcome %}` works with nothing passed by the
 * handler.
 *
 * SET, not set-if-absent, for the reason CSP gives about its nonce: a handler
 * rendering with a hashref it keeps between requests would otherwise serve
 * the first request's language for ever, and a page in the wrong language
 * looks like a page, which is the failure nobody reports. */
static void pi_bind_vars(pTHX_ SV *c, SV *data) {
    HV *cfg = pi_cfg_of(aTHX_ c);
    pi_arena *ar = pi_arena_of(aTHX_ cfg);
    const pi_cat *cat;

    if (!ar) return;                       /* the plugin is not registered */
    if (!(data && SvROK(data) && SvTYPE(SvRV(data)) == SVt_PVHV)) return;

    cat = pi_for_request(aTHX_ c, cfg, ar);
    if (!cat) return;

    /* SET, not set-if-absent, for the reason CSP gives about its nonce: a
     * handler rendering with a hashref it keeps between requests would
     * otherwise serve the first request's language for ever, and a page in
     * the wrong language still looks like a page. */
    (void)hv_stores((HV *)SvRV(data), "locale",
                    pi_tied_hash(aTHX_ ar, (int)(cat - ar->cat), NULL,
                                 cfg, c));
}

#endif /* PUNK_LANG_H */

#ifndef PUNK_I18N_H
#define PUNK_I18N_H

/* Punk::Plugin::I18n - translations and language negotiation.
 *
 * ---- the catalogue --------------------------------------------------------
 *
 * One JSON file per locale, named for the tag it holds:
 *
 *     i18n/en.json  i18n/en-GB.json  i18n/fr.json
 *     { "greeting": "Hello, {name}" }
 *
 * Placeholders are `{name}` and not `%s`, because positional formats cannot
 * be reordered and reordering is the entire reason a sentence needs
 * translating: German puts the verb where English does not.
 *
 * ---- why this is not a hash of SVs ----------------------------------------
 *
 * Catalogues are read-only at request time, so reading them before the fork
 * shares them across every worker. That is the argument, and it is wrong for
 * Perl data: the first READ of an SV touches its refcount, the page is
 * copied, and after a few minutes of traffic every worker holds a private
 * copy of the catalogue. The sharing lasts about as long as it takes to serve
 * the first request.
 *
 * So a catalogue is a flat block of bytes plus an index of offsets into it,
 * built once at boot and never written again. A lookup compares bytes and
 * returns a pointer into the block; nothing is allocated and no refcount is
 * touched, so the pages stay shared for the life of the pool.
 *
 * That is also what lets the lookup serve both callers: `$c->locale` in a
 * handler, and the per-request `locale` hash the templates read.
 *
 * ---- and not a cache ------------------------------------------------------
 *
 * Deliberately no `cache => 1` option. There is no per-request parse to cache
 * away - the catalogue is resident from boot - and a cache lookup per key
 * would be two orders of magnitude slower on the path that matters: a
 * Punk::Cache::File hit is about 7.2us, of which 6.2us is the open syscall,
 * so a page with forty translated strings would pay ~288us against a hash
 * probe now. plan_i18n/phase-0-the-catalogue.md has the whole argument.
 */

/* ---- why the files are read in Perl --------------------------------------
 *
 * Everything below builds the arena from an ALREADY DECODED hash. Finding the
 * catalogues and parsing them happens in Punk::Plugin::I18n::register, in
 * Perl, at boot, and that is deliberate twice over:
 *
 *   - `opendir`/`readdir` in XS is the Win32 trap. There is no ambient DIR on
 *     native Windows and reaching for one costs a FindFirstFile shim; Punk
 *     builds there now, and a directory walk is not worth a second
 *     implementation of one.
 *   - a decode that croaks needs the FILENAME in the message, and catching a
 *     croak in C means JMPENV by hand, in a header that has to compile on
 *     every perl from 5.10. Two lines of eval in Perl say the same thing.
 *
 * It costs nothing at request time: this runs once, before the fork.
 */

#define PI_TAG_MAX   35        /* RFC 5646 says 35 is enough for any tag */
#define PI_KEY_MAX   512

/* One key -> value pair. Offsets into the catalogue's block rather than
 * pointers, so the whole structure is position independent and one
 * allocation. */
typedef struct pi_entry {
    uint32_t koff, klen;
    uint32_t voff, vlen;
    uint32_t next;             /* 1-based index of the next in this bucket */
} pi_entry;

typedef struct pi_cat {
    char      tag[PI_TAG_MAX + 1];   /* case-folded, NUL terminated */
    STRLEN    taglen;
    char     *block;                 /* key and value bytes, one allocation */
    size_t    blocklen;
    pi_entry *ent;
    uint32_t  nent;
    uint32_t *bucket;                /* 1-based indices; 0 is empty */
    uint32_t  nbucket;               /* a power of two */
} pi_cat;

typedef struct pi_arena {
    pi_cat *cat;
    int     ncat;
    int     def;                     /* index of the default locale, or -1 */
} pi_arena;

/* ASCII fold. Language tags are case insensitive by RFC 5646 - `EN-gb` is
 * `en-GB` - and folding once at load means the match rule never has to. */
static char pi_fold(char c) {
    return (c >= 'A' && c <= 'Z') ? (char)(c - 'A' + 'a') : c;
}

static int pi_tag_eq(const char *a, STRLEN al, const char *b, STRLEN bl) {
    STRLEN i;
    if (al != bl) return 0;
    for (i = 0; i < al; i++)
        if (pi_fold(a[i]) != pi_fold(b[i])) return 0;
    return 1;
}

/* FNV-1a over the folded bytes. */
static uint32_t pi_hash(const char *s, STRLEN l) {
    uint32_t h = 2166136261u;
    STRLEN i;
    for (i = 0; i < l; i++) {
        h ^= (unsigned char)s[i];
        h *= 16777619u;
    }
    return h;
}

/* A `voff` of this is not an offset: it marks an entry that exists only to
 * say "keys continue below here". `items` is one, in a catalogue holding
 * `items.one` - it has no translation of its own, and the template hash needs
 * to know it can be descended into rather than reported missing.
 *
 * A marker rather than a flag field so pi_entry stays four uint32s. An empty
 * translation is vlen 0 with a real voff, which is why the test is on voff. */
#define PI_PREFIX 0xFFFFFFFFu

static const pi_entry *pi_find(const pi_cat *c, const char *k, STRLEN kl) {
    uint32_t i;
    if (!c || !c->nbucket) return NULL;
    i = c->bucket[pi_hash(k, kl) & (c->nbucket - 1)];
    while (i) {
        const pi_entry *e = &c->ent[i - 1];
        if (e->klen == (uint32_t)kl && memcmp(c->block + e->koff, k, kl) == 0)
            return e;
        i = e->next;
    }
    return NULL;
}

/* Is this key a level rather than a leaf? */
static int pi_is_prefix(const pi_cat *c, const char *k, STRLEN kl) {
    const pi_entry *e = pi_find(c, k, kl);
    return e && e->voff == PI_PREFIX;
}

/* The value for a key, or NULL. Returns bytes INTO the block - the caller
 * must not free them and must not hold them past the arena's life, which is
 * the life of the process. */
static const char *pi_get(const pi_cat *c, const char *k, STRLEN kl,
                          STRLEN *vlen) {
    uint32_t i;
    if (!c || !c->nbucket) return NULL;
    i = c->bucket[pi_hash(k, kl) & (c->nbucket - 1)];
    while (i) {
        const pi_entry *e = &c->ent[i - 1];
        if (e->klen == (uint32_t)kl && memcmp(c->block + e->koff, k, kl) == 0) {
            if (e->voff == PI_PREFIX) return NULL;   /* a level, not a leaf */
            if (vlen) *vlen = e->vlen;
            return c->block + e->voff;
        }
        i = e->next;
    }
    return NULL;
}

static pi_cat *pi_cat_of(pi_arena *ar, const char *tag, STRLEN tl) {
    int i;
    if (!ar) return NULL;
    for (i = 0; i < ar->ncat; i++)
        if (pi_tag_eq(ar->cat[i].tag, ar->cat[i].taglen, tag, tl))
            return &ar->cat[i];
    return NULL;
}

/* ---- loading -------------------------------------------------------------- */

/* Walk a decoded catalogue and size it: how many pairs, and how many bytes of
 * key and value. Two passes so the block is one allocation rather than a
 * realloc per key - the arena is built once and read forever, so the build
 * may as well be tidy.
 *
 * Nested objects are flattened with a dot, so { "items": { "one": ... } } is
 * reachable as `items.one`, which is what a translator writing either form
 * expects to mean. The template hash splits them back apart.
 */
static void pi_size(pTHX_ HV *h, const char *prefix, STRLEN plen,
                    uint32_t *nent, size_t *nbytes, const char *file) {
    HE *he;
    hv_iterinit(h);
    while ((he = hv_iternext(h))) {
        STRLEN kl;
        const char *k = HePV(he, kl);
        SV *v = HeVAL(he);
        STRLEN full = plen ? plen + 1 + kl : kl;

        if (full > PI_KEY_MAX)
            croak("Punk::Plugin::I18n: key too long in '%s' (max %d bytes)",
                  file, (int)PI_KEY_MAX);

        if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) {
            char sub[PI_KEY_MAX + 1];
            if (plen) {
                memcpy(sub, prefix, plen);
                sub[plen] = '.';
                memcpy(sub + plen + 1, k, kl);
            }
            else memcpy(sub, k, kl);
            sub[full] = '\0';
            pi_size(aTHX_ (HV *)SvRV(v), sub, full, nent, nbytes, file);
            continue;
        }
        if (SvROK(v))
            croak("Punk::Plugin::I18n: '%s' in '%s' is neither a string nor "
                  "an object - a catalogue holds translations, and an array "
                  "here is a mistake that would render as a reference",
                  k, file);
        {
            STRLEN vl, d;
            char key[PI_KEY_MAX + 1];
            (void)SvPV_const(v, vl);

            if (plen) {
                memcpy(key, prefix, plen);
                key[plen] = '.';
                memcpy(key + plen + 1, k, kl);
            }
            else memcpy(key, k, kl);

            /* The leaf, plus room for one PREFIX entry per dot in its key.
             * An over-count: prefixes are shared between sibling keys and
             * inserted once, so this leaves a few spare pi_entry slots rather
             * than counting distinct prefixes properly. Their key bytes cost
             * nothing at all - a prefix points at the leaf's own bytes with a
             * shorter length. */
            (*nent)++;
            for (d = 0; d < full; d++) if (key[d] == '.') (*nent)++;
            *nbytes += full + vl;
        }
    }
}

/* The second pass: copy the bytes in and record the offsets. */
static void pi_fill(pTHX_ HV *h, const char *prefix, STRLEN plen, pi_cat *c,
                    size_t *used) {
    HE *he;
    hv_iterinit(h);
    while ((he = hv_iternext(h))) {
        STRLEN kl;
        const char *k = HePV(he, kl);
        SV *v = HeVAL(he);
        STRLEN full = plen ? plen + 1 + kl : kl;
        char key[PI_KEY_MAX + 1];

        if (plen) {
            memcpy(key, prefix, plen);
            key[plen] = '.';
            memcpy(key + plen + 1, k, kl);
        }
        else memcpy(key, k, kl);
        key[full] = '\0';

        if (SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV) {
            pi_fill(aTHX_ (HV *)SvRV(v), key, full, c, used);
            continue;
        }
        {
            STRLEN vl, d;
            const char *vp = SvPV_const(v, vl);
            pi_entry *e = &c->ent[c->nent];
            uint32_t b;
            uint32_t koff = (uint32_t)*used;

            e->koff = koff;
            e->klen = (uint32_t)full;
            memcpy(c->block + *used, key, full);
            *used += full;

            /* Every level above this leaf, marked as a level. `items.one`
             * makes `items` descendable, which is what lets the template hash
             * answer `{% locale.items.one %}` a segment at a time.
             *
             * They point at THIS key's bytes with a shorter length, so a
             * level costs one entry and no bytes. Inserted only if absent:
             * sibling keys share their levels. */
            for (d = 0; d < full; d++) {
                if (key[d] != '.') continue;
                if (pi_find(c, key, d)) continue;
                {
                    pi_entry *p = &c->ent[c->nent];
                    uint32_t pb = pi_hash(key, d) & (c->nbucket - 1);
                    p->koff = koff;
                    p->klen = (uint32_t)d;
                    p->voff = PI_PREFIX;
                    p->vlen = 0;
                    p->next = c->bucket[pb];
                    c->bucket[pb] = c->nent + 1;
                    c->nent++;
                    e = &c->ent[c->nent];   /* the leaf moved along */
                    e->koff = koff;
                    e->klen = (uint32_t)full;
                }
            }

            e->voff = (uint32_t)*used;
            e->vlen = (uint32_t)vl;
            memcpy(c->block + *used, vp, vl);
            *used += vl;

            b = pi_hash(key, full) & (c->nbucket - 1);
            e->next = c->bucket[b];
            c->bucket[b] = c->nent + 1;
            c->nent++;
        }
    }
}


/* Build one catalogue from an already-decoded hash. */
static void pi_cat_build(pTHX_ pi_cat *c, HV *h, const char *tag,
                         STRLEN taglen, const char *where) {
    uint32_t nent = 0;
    size_t nbytes = 0, used = 0;
    uint32_t nb = 8;
    STRLEN i;

    if (taglen > PI_TAG_MAX)
        croak("Punk::Plugin::I18n: '%s' is not a language tag - too long",
              where);

    Zero(c, 1, pi_cat);
    for (i = 0; i < taglen; i++) c->tag[i] = pi_fold(tag[i]);
    c->tag[taglen] = '\0';
    c->taglen = taglen;

    pi_size(aTHX_ h, NULL, 0, &nent, &nbytes, where);

    while (nb < nent * 2 && nb < (1u << 24)) nb <<= 1;
    c->nbucket = nb;
    Newxz(c->bucket, nb, uint32_t);
    if (nent)   Newxz(c->ent, nent, pi_entry);
    if (nbytes) Newx(c->block, nbytes, char);
    c->blocklen = nbytes;
    c->nent = 0;

    pi_fill(aTHX_ h, NULL, 0, c, &used);
}

static void pi_cat_free(pi_cat *c) {
    if (!c) return;
    Safefree(c->block);  c->block = NULL;
    Safefree(c->ent);    c->ent = NULL;
    Safefree(c->bucket); c->bucket = NULL;
}

static void pi_arena_free(pi_arena *ar) {
    int i;
    if (!ar) return;
    for (i = 0; i < ar->ncat; i++) pi_cat_free(&ar->cat[i]);
    Safefree(ar->cat);
    Safefree(ar);
}

/* A catalogue that uses plural categories in a language with no rule is a
 * BOOT error, naming the locale.
 *
 * The alternative is to fall back to one/other, which is English's grammar
 * applied to a language that does not have it - wrong for a quarter of
 * Polish's numbers, and wrong in a way that reads perfectly well. An error
 * here is in front of whoever deployed it; the fallback is in front of a
 * user, in a language nobody on the team reads.
 */
static void pi_check_plural(pTHX_ const pi_cat *c, const pi_arena *ar,
                            const char *where) {
    uint32_t i;
    if (pi_rule_for(c->tag, c->taglen) != PR_NONE) return;
    PERL_UNUSED_ARG(ar);

    for (i = 0; i < c->nent; i++) {
        const pi_entry *e = &c->ent[i];
        const char *k = c->block + e->koff;
        STRLEN kl = e->klen, d;

        if (e->voff == PI_PREFIX) continue;
        /* the last segment of the key */
        d = kl;
        while (d > 0 && k[d - 1] != '.') d--;
        if (d == 0 || !pi_cat_name(k + d, kl - d)) continue;

        croak("Punk::Plugin::I18n: '%s' uses the plural category '%.*s' in "
              "'%.*s', and there is no plural rule for that language. A rule "
              "is a grammar, not a preference: falling back to one/other "
              "would be English's rule applied to a language that does not "
              "have it, and it would read perfectly well while being wrong. "
              "Add the rule to punk_plural.h, or use plain keys and choose "
              "between them in the application",
              where, (int)(kl - d), k + d, (int)(d - 1), k);
    }
}

/* Build the arena from { tag => \%catalogue, ... }, decoded in Perl. */
static pi_arena *pi_arena_build(pTHX_ HV *cats, const char *def,
                                STRLEN deflen) {
    pi_arena *ar;
    HE *he;
    int n = 0;

    hv_iterinit(cats);
    while ((he = hv_iternext(cats))) n++;
    if (!n)
        croak("Punk::Plugin::I18n: no catalogues - a plugin with nothing to "
              "translate is a typo in `dir`, not a working default");

    Newxz(ar, 1, pi_arena);
    ar->def = -1;
    Newxz(ar->cat, n, pi_cat);

    hv_iterinit(cats);
    while ((he = hv_iternext(cats))) {
        STRLEN tl;
        const char *tp = HePV(he, tl);
        SV *v = HeVAL(he);
        if (!(v && SvROK(v) && SvTYPE(SvRV(v)) == SVt_PVHV)) {
            pi_arena_free(ar);
            croak("Punk::Plugin::I18n: the catalogue for '%s' is not a JSON "
                  "object - a catalogue is a map of key to translation", tp);
        }
        pi_cat_build(aTHX_ &ar->cat[ar->ncat], (HV *)SvRV(v), tp, tl, tp);
        pi_check_plural(aTHX_ &ar->cat[ar->ncat], ar, tp);
        if (def && pi_tag_eq(ar->cat[ar->ncat].tag, ar->cat[ar->ncat].taglen,
                             def, deflen))
            ar->def = ar->ncat;
        ar->ncat++;
    }

    if (def && ar->def < 0) {
        char want[PI_TAG_MAX + 1];
        STRLEN i, w = deflen > PI_TAG_MAX ? PI_TAG_MAX : deflen;
        for (i = 0; i < w; i++) want[i] = def[i];
        want[w] = '\0';
        pi_arena_free(ar);
        croak("Punk::Plugin::I18n: the default locale '%s' has no catalogue - "
              "the default is the answer when negotiation finds nothing, so "
              "it is the one locale that must exist", want);
    }
    return ar;
}

/* ---- the view a template reads --------------------------------------------
 *
 * `{% locale.welcome %}` is an ordinary dotted path through a hashref, so the
 * template half needs no change to Stencil - the same seam CSP uses to make
 * `{% csp_nonce %}` resolve with nothing passed by the handler.
 *
 * The hash is TIED, and both halves of that decision were paid for.
 *
 * A plain hash would have to be materialised: per request it copies the
 * catalogue into SVs on every page, which is the cost the arena exists to
 * avoid, and cached per catalogue it is a second copy of every translation as
 * Perl data in whichever worker rendered in that locale. A tied hash copies
 * nothing - FETCH reads the arena and builds one SV for the string actually
 * asked for.
 *
 * It also keeps the missing-key rule true on BOTH paths. A template resolves
 * a missing path to the empty string, so a plain hash would silently swallow
 * `{% locale.typo %}` while `$c->locale('typo')` rendered the key - the same
 * omission visible in a handler and invisible in a template, which is the
 * worse half to lose.
 *
 * This needs Template::Stencil 0.10. Before it, a tied hash in a path
 * resolved to nothing at all: its resolver read hashes with hv_common and a
 * precomputed hash, which does not go through tie magic. That was fixed
 * there rather than worked around here.
 */
#define PIT_ARENA  0   /* the arena, as an IV */
#define PIT_CAT    1   /* which catalogue, as an index */
#define PIT_PREFIX 2   /* the dotted path so far, or undef at the top */
#define PIT_CFG    3   /* the plugin config, for the dev flag */
#define PIT_CTX    4   /* the context, for the logger */

/* ---- interpolation -------------------------------------------------------- */

/* ---- what an application can see ------------------------------------------
 *
 * Three numbers, because they answer three different questions and rolling
 * them together would answer none of them:
 *
 *   missing      - the key is in no catalogue at all. A bug.
 *   untranslated - the key is in the default catalogue but not in the
 *                  negotiated one. NOT a bug: it is what a partly translated
 *                  site is, and it is how an application measures coverage.
 *   warned       - how many times the missing-key warning actually fired.
 *                  Provable, so "it did not warn in production" is a number
 *                  rather than the absence of one.
 */
static UV pi_n_missing = 0;
static UV pi_n_untranslated = 0;
static UV pi_n_warned = 0;

/* Keys already warned about, so the same page does not warn on every request.
 * Twenty renders of one page must produce one line: noise is ignored, and
 * being ignored is how the omission survives. */
static HV *pi_seen = NULL;

/* `{name}` from a list of name => value pairs.
 *
 * Three rules, each of which exists because the alternative is worse:
 *
 *   - an UNKNOWN placeholder stays literal. `{nmae}` renders as `{nmae}`,
 *     visibly wrong, rather than as a gap nobody notices;
 *   - a MISSING substitution is not an error - a translator adding a
 *     placeholder the caller does not pass must not take the page down;
 *   - a value containing `{other}` is NOT re-scanned. One pass, left to
 *     right, or a user whose name is `{admin}` reaches into the catalogue.
 */
static SV *pi_interpolate(pTHX_ const char *v, STRLEN vl, SV **args,
                          int nargs) {
    SV *out = newSVpvn("", 0);
    STRLEN i = 0;

    while (i < vl) {
        const char *open = (const char *)memchr(v + i, '{', vl - i);
        STRLEN o, close;
        int j, done = 0;

        if (!open) { sv_catpvn(out, v + i, vl - i); break; }
        o = (STRLEN)(open - v);
        sv_catpvn(out, v + i, o - i);

        /* find the close on the same run of name characters */
        close = o + 1;
        while (close < vl && v[close] != '}' && v[close] != '{') close++;
        if (close >= vl || v[close] != '}') {
            sv_catpvn(out, v + o, 1);       /* a lone brace is a lone brace */
            i = o + 1;
            continue;
        }

        for (j = 0; j + 1 < nargs; j += 2) {
            STRLEN nl;
            const char *n = SvPV_const(args[j], nl);
            if (nl == close - o - 1 && memcmp(n, v + o + 1, nl) == 0) {
                if (SvOK(args[j + 1])) {
                    STRLEN sl;
                    const char *s = SvPV_const(args[j + 1], sl);
                    sv_catpvn(out, s, sl);
                }
                done = 1;
                break;
            }
        }
        if (!done) sv_catpvn(out, v + o, close - o + 1);   /* left literal */
        i = close + 1;
    }
    return out;
}

#endif /* PUNK_I18N_H */

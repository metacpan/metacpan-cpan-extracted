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
 * So a catalogue is a block of bytes addressed by offset, built once at boot
 * and never written again. A lookup compares bytes and returns a pointer
 * INTO the block; nothing is allocated and no refcount is touched, so the
 * pages stay shared for the life of the pool.
 *
 * That is also what lets the lookup serve both callers: `$c->locale` in a
 * handler, and the per-request `locale` hash the templates read.
 *
 * ---- the block is Frozen's ------------------------------------------------
 *
 * It used to be hand-rolled here: a char buffer, an array of pi_entry, and a
 * bucket array, three allocations per catalogue and two more for the arena.
 * It is now ONE Frozen container holding { folded-tag => catalogue }, read
 * through fz_abi.h - see punk_frozen.h for why that is the C table and not
 * Frozen's Perl surface.
 *
 * The thing that changed is not the storage, it is that the block holds a
 * TREE. The old form flattened { "a": { "b": x } } to the string "a.b" and
 * faked the levels with a sentinel, so a literal key "a.b" was the same key -
 * and which of the two answered was decided by the hash order of the process
 * that loaded it. Two workers could disagree. A level and a leaf are now
 * different nodes, so they are different keys, in every process.
 *
 * It costs one probe per level where the flat key cost one probe whatever
 * its depth. That is the trade and it is not recoverable without giving the
 * distinction back.
 *
 * ---- and not a cache ------------------------------------------------------
 *
 * Deliberately no `cache => 1` option. There is no per-request parse to cache
 * away - the catalogue is resident from boot - and a cache lookup per key
 * would be two orders of magnitude slower on the path that matters: a
 * Punk::Cache::File hit is about 7.2us, of which 6.2us is the open syscall,
 * so a page with forty translated strings would pay ~288us against a hash
 * probe now.
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

/* One catalogue: a language tag, and the node its translations hang off in
 * the block. The whole arena is ONE Frozen container holding
 * { folded-tag => catalogue }, so a catalogue is a handle rather than a
 * structure, and a tag lookup is a probe on a hash node.
 *
 * The tag is a char array rather than a pointer into the block because
 * _negotiate builds a pi_arena on the STACK, with tags and no container at
 * all, to test the Accept-Language rules without a catalogue. A borrowed
 * pointer would break that seam.
 *
 * `fz` is repeated per catalogue rather than reached through the arena so
 * that pi_get and pi_is_prefix keep the signatures punk_lang.h calls them
 * with. Eight bytes times the number of locales. */
typedef struct pi_cat {
    char          tag[PI_TAG_MAX + 1];   /* case-folded, NUL terminated */
    STRLEN        taglen;
    fz_container *fz;                    /* NULL in the _negotiate seam */
    uint32_t      node;                  /* this catalogue's hash node */
} pi_cat;

typedef struct pi_arena {
    fz_container *c;                 /* owned; lives as long as the process */
    uint32_t      root;              /* the hash of folded tag -> catalogue */
    pi_cat       *cat;
    int           ncat;
    int           def;               /* index of the default locale, or -1 */
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

/* A dotted key is a WALK now, not a joined string.
 *
 * `items.one` descends from the catalogue node through `items` to `one`,
 * which costs one probe per segment where the flat key cost one probe
 * whatever its depth. What it buys is that a level and a leaf are different
 * nodes rather than the same entry wearing a sentinel, so { "a.b": x } and
 * { "a": { "b": y } } stop being the same key. They were not merely
 * ambiguous before: which of the two won was decided by Perl's per-process
 * hash order, so two workers in one pool could answer differently.
 *
 * PUNK_FZ is read directly rather than passed in. It is a file-scope static
 * in this translation unit, resolved once at boot by punk_fz(), and reading
 * it here is what lets these two keep the signatures punk_lang.h calls them
 * with - so the negotiation code did not have to change at all.
 *
 * ---- the rule Frozen does not enforce --------------------------------------
 *
 * A node is a uint32_t, and Frozen validates its SHAPE on every entry: the
 * offset is in bounds, the alignment is right, the tag is a live kind. What
 * it cannot validate is PROVENANCE. A node that is valid in one container
 * names a different place in another, so reading it through the wrong
 * container returns wrong data rather than failing.
 *
 * So a node never leaves the pi_cat it came from. That is why `fz` sits
 * beside `node` in the struct instead of being reached through the arena:
 * the pair travels together, and there is no call here that takes a node
 * without the container it belongs to. */
static int pi_is_prefix(const pi_cat *c, const char *k, STRLEN kl) {
    uint32_t node;
    if (!c || !c->fz || !PUNK_FZ) return 0;
    node = (PUNK_FZ->path)(c->fz, c->node, k, kl, '.');
    if (node == FZ_NOHANDLE) return 0;
    return (PUNK_FZ->kind)(c->fz, node) == FZ_K_HASH;
}

/* The value for a key, or NULL. Returns bytes INTO the block - the caller
 * must not free them and must not hold them past the arena's life, which is
 * the life of the process.
 *
 * `utf8` is an out-param because the block records the flag per string. The
 * old arena did not, and _locale turned the flag on unconditionally, which
 * was correct only because File::Raw::JSON happens to decode to UTF-8. Any
 * other producer got mojibake. NULL is accepted for callers that do not
 * care - the plural path and EXISTS. */
static const char *pi_get(const pi_cat *c, const char *k, STRLEN kl,
                          STRLEN *vlen, int *utf8) {
    uint32_t node;
    if (!c || !c->fz || !PUNK_FZ) return NULL;
    node = (PUNK_FZ->path)(c->fz, c->node, k, kl, '.');
    if (node == FZ_NOHANDLE) return NULL;
    /* No `kind` call before this. str answers NULL for anything that is not
     * a string - it checks the tag and the bounds itself - so asking twice
     * is a second call through the table for an answer already being
     * computed. Two calls per lookup, not three, on the path that runs per
     * translated string per request. */
    return (PUNK_FZ->str)(c->fz, node, vlen, utf8);
}

/* ---- loading -------------------------------------------------------------- */

/* Free the arena. The block is one container, so this is one close plus the
 * tag table. The container is closed through the table because it was opened
 * through it, and (FZ->close) is PARENTHESISED: XSUB.h redefines `close` as a
 * macro under PERL_IMPLICIT_SYS, which is the build failure Frozen 0.02 was
 * released to fix in its own selftest. */
static void pi_arena_free(pTHX_ pi_arena *ar) {
    if (!ar) return;
    if (ar->c && PUNK_FZ) (PUNK_FZ->close)(aTHX_ ar->c);
    ar->c = NULL;
    Safefree(ar->cat);
    Safefree(ar);
}

/* What the boot walk found wrong, recorded rather than croaked.
 *
 * Nothing here croaks while the walk is running. Frozen's own fz_walk
 * mallocs a segment stack and frees it after the walk returns, so a croak
 * from inside longjmps past that free and leaks on every boot - a slow leak
 * with no visible cause in a `punk dev` rebuild loop. The recursion below
 * allocates nothing, but the same discipline is kept: the first fault is
 * recorded and raised by the caller, so the rule holds if this ever goes
 * back through the table. */
typedef struct pi_vcheck {
    int  err;                        /* 0 fine, else one of PI_V_* */
    int  plural;                     /* check plural categories? */
    char path[PI_KEY_MAX + 1];
    char what[32];                   /* the offending kind, or category */
} pi_vcheck;

#define PI_V_TYPE   1
#define PI_V_DOT    2
#define PI_V_PLURAL 3
#define PI_V_DEEP   4

static const char *pi_kind_name(int k) {
    switch (k) {
    case FZ_K_UNDEF: return "null";
    case FZ_K_FALSE: case FZ_K_TRUE: return "a boolean";
    case FZ_K_INT:   case FZ_K_UINT: return "a number";
    case FZ_K_NUM:   return "a number";
    case FZ_K_ARRAY: return "an array";
    case FZ_K_HASH:  return "an object";
    }
    return "not a string";
}

/* Walk a catalogue at boot, checking three things in one pass.
 *
 * fz_walk is not used, and the reason is not preference: it reports LEAVES
 * only, so an array reaches the callback as its elements and the array node
 * itself is never seen. An array is exactly one of the things that has to be
 * refused, because nothing in the i18n surface can reach it - fz_path
 * descends through hash nodes, so `list.0` stops at the array and answers
 * absent. Left alone it is a silent miss that renders as the key.
 *
 * The path is built as it descends rather than kept as a segment stack, so
 * the message has the joined path ready and the recursion allocates nothing.
 */
static void pi_walk_check(pi_vcheck *v, fz_container *fz, uint32_t node,
                          char *path, size_t plen, int depth) {
    int kind;
    uint32_t n, i;

    if (v->err) return;
    if (depth > 64) {                    /* Frozen allows 256; a catalogue
                                          * that deep is a bug, not a
                                          * translation */
        v->err = PI_V_DEEP;
        path[plen] = '\0';
        my_strlcpy(v->path, path, sizeof v->path);
        return;
    }

    kind = (PUNK_FZ->kind)(fz, node);

    if (kind == FZ_K_STR) {
        /* the last segment, for the plural rule */
        if (v->plural && depth >= 2) {
            size_t s = plen;
            while (s > 0 && path[s - 1] != '.') s--;
            if (pi_cat_name(path + s, (STRLEN)(plen - s))) {
                path[plen] = '\0';
                my_strlcpy(v->path, path, sizeof v->path);
                my_strlcpy(v->what, path + s, sizeof v->what);
                v->err = PI_V_PLURAL;
            }
        }
        return;
    }

    if (kind != FZ_K_HASH) {
        path[plen] = '\0';
        my_strlcpy(v->path, path, sizeof v->path);
        my_strlcpy(v->what, pi_kind_name(kind), sizeof v->what);
        v->err = PI_V_TYPE;
        return;
    }

    n = (PUNK_FZ->count)(fz, node);
    for (i = 0; i < n && !v->err; i++) {
        const char *k = NULL;
        STRLEN kl = 0;
        uint32_t child;
        size_t j, want;

        if (!(PUNK_FZ->key_at)(fz, node, i, &k, &kl, NULL)) continue;

        for (j = 0; j < (size_t)kl; j++) {
            if (k[j] != '.') continue;
            path[plen] = '\0';
            my_strlcpy(v->path, path, sizeof v->path);
            {
                size_t w = (size_t)kl < sizeof v->what ? (size_t)kl
                                                       : sizeof v->what - 1;
                memcpy(v->what, k, w);
                v->what[w] = '\0';
            }
            v->err = PI_V_DOT;
            return;
        }

        want = plen + (plen ? 1 : 0) + (size_t)kl;
        if (want >= PI_KEY_MAX) {        /* too long to name; refuse rather
                                          * than truncate into a message */
            path[plen] = '\0';
            my_strlcpy(v->path, path, sizeof v->path);
            my_strlcpy(v->what, "a key too long to address", sizeof v->what);
            v->err = PI_V_TYPE;
            return;
        }
        if (plen) path[plen] = '.';
        memcpy(path + plen + (plen ? 1 : 0), k, kl);

        child = (PUNK_FZ->val_at)(fz, node, i);
        pi_walk_check(v, fz, child, path, want, depth + 1);
    }
}

static void pi_validate(pTHX_ pi_arena *ar, int idx, const char *where) {
    pi_cat   *c = &ar->cat[idx];
    pi_vcheck v;
    char      path[PI_KEY_MAX + 2];

    memset(&v, 0, sizeof v);
    /* Only the plural check is conditional. The type and dotted-key checks
     * run for every catalogue, in every language - an earlier version
     * returned early here when the language HAD a rule, which silently
     * skipped both of them for en, fr and everything else with a rule. */
    v.plural = (pi_rule_for(c->tag, c->taglen) == PR_NONE);

    path[0] = '\0';
    /* The catalogue root is depth 0, so a TOP-LEVEL key's value is depth 1
     * and a category - which must sit under another key - is depth 2. Off by
     * one here and every top-level word named `one` or `few` is refused as a
     * plural category in any language whose rule is unknown. */
    pi_walk_check(&v, c->fz, c->node, path, 0, 0);

    if (!v.err) return;

    {   /* Copied out BEFORE the arena is freed. `where` is the arena's own
         * tag and v.path was built from bytes borrowed out of the block;
         * pi_arena_free closes the container, so a croak reading either
         * afterwards quotes freed memory - and reads as an empty string
         * often enough to survive a test suite. */
        char tag[PI_TAG_MAX + 1], p[PI_KEY_MAX + 1], w[32];
        int  err = v.err;
        my_strlcpy(tag, where,  sizeof tag);
        my_strlcpy(p,   v.path, sizeof p);
        my_strlcpy(w,   v.what, sizeof w);
        pi_arena_free(aTHX_ ar);

        if (err == PI_V_PLURAL)
            croak("Punk::Plugin::I18n: '%s' uses the plural category '%s' in "
                  "'%s', and there is no plural rule for that language. A rule "
                  "is a grammar, not a preference: falling back to one/other "
                  "would be English's rule applied to a language that does not "
                  "have it, and it would read perfectly well while being wrong. "
                  "Add the rule to punk_plural.h, or use plain keys and choose "
                  "between them in the application", tag, w, p);
        if (err == PI_V_DOT)
            croak("Punk::Plugin::I18n: '%s' has a key containing a dot, '%s', "
                  "under '%s'. A dot separates levels, so this key cannot be "
                  "reached - $c->locale would descend past it and a template "
                  "splits on dots before it ever gets here. Nest it instead",
                  tag, w, *p ? p : "the top level");
        if (err == PI_V_DEEP)
            croak("Punk::Plugin::I18n: '%s' nests more than 64 levels deep at "
                  "'%s', which is a mistake in the catalogue rather than a "
                  "translation", tag, p);
        croak("Punk::Plugin::I18n: '%s' has %s at '%s', and a translation is "
              "a string. Quote it in the catalogue, or move the value into "
              "the application - the lookup returns text and there is nothing "
              "for it to return here", tag, w, p);
    }
}

/* Build the arena from { folded-tag => \%catalogue, ... }, decoded in Perl.
 *
 * The whole thing becomes ONE Frozen block through freeze_container, which
 * builds and adopts in one step. Going through Frozen's Perl surface instead
 * would mean building the block and then COPYING it, because attach copies -
 * and it would make Punk depend on two contracts rather than one, since the
 * Perl API carries no append-only guarantee and the ABI table does.
 *
 * No `flat` option. Frozen's flat index is only consulted for a path from
 * the ROOT, and every catalogue lookup here starts one level down at a tag,
 * so it would occupy bytes and never be read.
 *
 * Tags are folded in Perl, at derivation from the filename, so that EN.json
 * and en.json produce the same block rather than two blocks that behave
 * differently. */
static pi_arena *pi_arena_build(pTHX_ SV *cats, const char *def,
                                STRLEN deflen) {
    pi_arena *ar;
    const fz_abi *FZ = punk_fz(aTHX);
    fz_container *c;
    uint32_t root, n, i;
    int err = 0;
    char bad[PI_TAG_MAX + 1];

    /* FZ_F_STRINGIFY: a translation is text, and JSON's 5 decodes to an IV
     * that would freeze as an integer - which `str` answers NULL for, so the
     * lookup would find nothing and render the key. The flag makes the block
     * hold strings only, which is also what lets the boot walk below say "a
     * translation is text" as ONE rule rather than a list of exceptions. */
    c = (FZ->freeze_container)(aTHX_ cats, FZ_F_STRINGIFY, NULL, &err);
    if (!c)
        croak("Punk::Plugin::I18n: the catalogues could not be frozen: %s",
              (FZ->error)(err));

    root = (FZ->root)(c);
    if ((FZ->kind)(c, root) != FZ_K_HASH) {
        (FZ->close)(aTHX_ c);
        croak("Punk::Plugin::I18n: the catalogues did not freeze to a map of "
              "tag to catalogue");
    }
    n = (FZ->count)(c, root);
    if (!n) {
        (FZ->close)(aTHX_ c);
        croak("Punk::Plugin::I18n: no catalogues - a plugin with nothing to "
              "translate is a typo in `dir`, not a working default");
    }

    Newxz(ar, 1, pi_arena);
    ar->c = c;
    ar->root = root;
    ar->def = -1;
    Newxz(ar->cat, n, pi_cat);

    for (i = 0; i < n; i++) {
        const char *k = NULL;
        STRLEN kl = 0;
        int kutf8 = 0;
        uint32_t node;
        STRLEN j;

        if (!(FZ->key_at)(c, root, i, &k, &kl, &kutf8)) {
            pi_arena_free(aTHX_ ar);
            croak("Punk::Plugin::I18n: the frozen catalogue map is short");
        }
        /* fz_at is array-only, so a hash value by index is val_at - added in
         * ABI v2 for exactly this. */
        node = (FZ->val_at)(c, root, i);

        /* Copied before anything can free the block: `k` borrows from it,
         * and every croak below closes the container first. */
        {
            STRLEN w = kl > PI_TAG_MAX ? PI_TAG_MAX : kl;
            memcpy(bad, k, w);
            bad[w] = '\0';
        }

        if (kutf8 || kl > PI_TAG_MAX) {
            pi_arena_free(aTHX_ ar);
            croak("Punk::Plugin::I18n: '%s' is not a usable language tag - "
                  "a tag is ASCII and at most %d bytes", bad, PI_TAG_MAX);
        }
        if ((FZ->kind)(c, node) != FZ_K_HASH) {
            pi_arena_free(aTHX_ ar);
            croak("Punk::Plugin::I18n: the catalogue for '%s' is not a JSON "
                  "object - a catalogue is a map of key to translation", bad);
        }
        for (j = 0; j < kl; j++) {
            if (pi_fold(k[j]) != k[j]) {
                pi_arena_free(aTHX_ ar);
                croak("Punk::Plugin::I18n: the tag '%s' reached the block "
                      "unfolded - tags are folded when they are derived from "
                      "the filename", bad);
            }
            ar->cat[i].tag[j] = k[j];
        }
        ar->cat[i].tag[kl] = '\0';
        ar->cat[i].taglen  = kl;
        ar->cat[i].fz      = c;
        ar->cat[i].node    = node;
        ar->ncat++;

        pi_validate(aTHX_ ar, (int)i, ar->cat[i].tag);

        if (def && pi_tag_eq(ar->cat[i].tag, ar->cat[i].taglen, def, deflen))
            ar->def = (int)i;
    }

    if (def && ar->def < 0) {
        char want[PI_TAG_MAX + 1];
        STRLEN j, w = deflen > PI_TAG_MAX ? PI_TAG_MAX : deflen;
        for (j = 0; j < w; j++) want[j] = def[j];
        want[w] = '\0';
        pi_arena_free(aTHX_ ar);
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
/* The tied object carries NODES, not just a path.
 *
 * It used to carry only the dotted path so far, so every FETCH rebuilt the
 * joined key and looked it up from the catalogue root again: resolving
 * {% locale.a.b.c %} cost 1 + 2 + 3 = six probes and three SV
 * concatenations. Carrying the node it already resolved makes each FETCH one
 * probe from where the last one stopped - three for that path, and no
 * concatenation at all.
 *
 * PIT_DNODE is the same position in the DEFAULT catalogue, carried in step.
 * Without it there is no way to tell "missing everywhere" from "present in
 * the default but not translated here" once the joined key is gone, and the
 * untranslated counter would stop being exact.
 *
 * PIT_PREFIX survives for one job only: the missing-key message, which
 * renders the full dotted path a template asked for. */
#define PIT_ARENA  0   /* the arena, as an IV */
#define PIT_CAT    1   /* which catalogue, as an index */
#define PIT_PREFIX 2   /* the dotted path so far, for the miss message */
#define PIT_CFG    3   /* the plugin config, for the dev flag */
#define PIT_CTX    4   /* the context, for the logger */
#define PIT_NODE   5   /* where we are in the negotiated catalogue */
#define PIT_DNODE  6   /* and in the default one */
#define PIT_ITER   7   /* the each/keys cursor */
#define PIT_MAX    8

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
/* `utf8` is the flag the BLOCK recorded for the catalogue string, because
 * `v` is a pointer and a length and carries none of its own.
 *
 * It has to be known here rather than applied by the caller afterwards. The
 * catalogue string and the substituted values are two different encodings
 * meeting in one buffer: appending a downgraded Latin-1 argument into a
 * string of UTF-8 octets and then labelling the result UTF-8 puts a raw
 * 0xE9 inside a string that claims to be UTF-8. That is corruption, it is
 * reachable from a form field today through
 * $c->locale($key, name => $value), and Frozen does not fix it - the block
 * hands back exactly what it was given. It is ordinary broken code that has
 * been sitting beside the interesting problem.
 *
 * So `out` is flagged UP FRONT and the values go in with sv_catsv, which is
 * the primitive that knows both sides' flags and upgrades whichever needs
 * it. sv_catpvn cannot: it sees bytes and a length, which is precisely what
 * loses the information. The catalogue runs still use sv_catpvn, and that
 * is correct - those octets already ARE out's encoding. */
static SV *pi_interpolate(pTHX_ const char *v, STRLEN vl, int utf8,
                          SV **args, int nargs) {
    SV *out = newSVpvn("", 0);
    STRLEN i = 0;

    if (utf8) SvUTF8_on(out);

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
                /* sv_catsv, not sv_catpvn(SvPV_const(...)): the argument
                 * carries its own flag and this is the only append that has
                 * to reconcile two encodings. */
                if (SvOK(args[j + 1])) sv_catsv(out, args[j + 1]);
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

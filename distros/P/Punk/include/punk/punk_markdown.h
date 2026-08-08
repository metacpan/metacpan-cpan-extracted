/* punk_markdown.h - a directory of markdown as a documentation site.
 *
 * `markdown '/docs' => 'docs', title => 'Guide'` compiles to a PSGI coderef:
 * a magic CV carrying the finished site, the closure pattern punk_static.h
 * uses. The whole site is built at boot - the tree walked, every page
 * rendered through Markdown::Simple and wrapped by Template::Stencil, the
 * search index filled - and frozen into a lookup table, so a request is a
 * hash hit and a triplet with no markdown parse, no template render and no
 * Perl frame. A bad template or an unreadable directory is a configuration
 * error and fails at boot with the rest of the configuration, which is the
 * same stance Open::API::UI takes.
 *
 * Two provider ABIs are resolved at runtime here: Markdown::Simple's mds_abi
 * for rendering, heading anchors and the plain text the index is built from,
 * and Search::Trigram's sg_abi for search. Both are consumed C to C.
 *
 * Rides the existing mount table, so include/punk/punk_serve.h needs no
 * change: prefix dispatch, longest-prefix ordering and the SCRIPT_NAME /
 * PATH_INFO rewrite come free, and the mount inherits the documented
 * behaviour that a mounted app bypasses before/after hooks, guards and CSRF,
 * exactly as `static` does.
 *
 * Include prerequisites: punk_names.h, punk_static.h (punk_closure,
 * ps_serve_file, ps_plain, ps_path_unsafe, ps_http_date), punk_stencil.h
 * (punk_st), punk_request.h (pq_parse_pairs), and the Perl headers.
 *
 * A note on the parser's globals: Markdown::Simple keeps a file-scope image
 * stack, so two interpreters must not render concurrently. Every render this
 * mount performs happens either at boot or under `reload`, both single
 * threaded and sequential, so that constraint is met and is not something to
 * work around here.
 */

#ifndef PUNK_MARKDOWN_H
#define PUNK_MARKDOWN_H

#include "mds_abi.h"
#include "sg_abi.h"

/* ---- the provider ABIs ---------------------------------------------------
 * The shape punk_stencil.h established: a static pointer plus a TRIED flag so
 * a failed probe is not retried, an eval_pv of the require followed by a
 * SPAGAIN (the require may have reallocated the value stack - the missing
 * SPAGAIN was a shipped bug in every resolver here once), and a >= gate,
 * since these tables only ever grow at the tail. The _try twin returns NULL
 * for a caller that has a fall-back; the plain one croaks naming the version
 * to upgrade to, because this mount has no fall-back worth having. */

static const mds_abi *PUNK_MDS = NULL;
static int            PUNK_MDS_TRIED = 0;

static const mds_abi *punk_mds_try(pTHX) {
    if (!PUNK_MDS && !PUNK_MDS_TRIED) {
        dSP; int count; IV p = 0;
        PUNK_MDS_TRIED = 1;
        if (PerlEnv_getenv("PUNK_FAKE_MDS_BAD")) return NULL;
        eval_pv(PK_REQUIRE("Markdown::Simple"), FALSE);
        SPAGAIN;
        if (!SvTRUE(ERRSV)) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("Markdown::Simple::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const mds_abi *a = INT2PTR(const mds_abi *, p);
                if (a && a->abi_version >= MDS_ABI_VERSION) PUNK_MDS = a;
            }
        }
    }
    return PUNK_MDS;
}

static const mds_abi *punk_mds(pTHX) {
    const mds_abi *a = punk_mds_try(aTHX);
    if (!a)
        croak("Punk: the markdown keyword needs Markdown::Simple 0.20+ "
              "with its C ABI (mds_abi version %d)", MDS_ABI_VERSION);
    return a;
}

static const sg_abi *PUNK_SG = NULL;
static int           PUNK_SG_TRIED = 0;

static const sg_abi *punk_sg_try(pTHX) {
    if (!PUNK_SG && !PUNK_SG_TRIED) {
        dSP; int count; IV p = 0;
        PUNK_SG_TRIED = 1;
        if (PerlEnv_getenv("PUNK_FAKE_SG_BAD")) return NULL;
        eval_pv(PK_REQUIRE("Search::Trigram"), FALSE);
        SPAGAIN;
        if (!SvTRUE(ERRSV)) {
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("Search::Trigram::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            if (!SvTRUE(ERRSV) && count > 0) p = POPi;
            else if (count > 0)             (void)POPs;
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const sg_abi *a = INT2PTR(const sg_abi *, p);
                if (a && a->abi_version >= SG_ABI_VERSION) PUNK_SG = a;
            }
        }
    }
    return PUNK_SG;
}

static const sg_abi *punk_sg(pTHX) {
    const sg_abi *a = punk_sg_try(aTHX);
    if (!a)
        croak("Punk: markdown search needs Search::Trigram 0.02+ with its "
              "C ABI (sg_abi version %d); pass search => 0 to do without it",
              SG_ABI_VERSION);
    return a;
}

/* ---- slots ---------------------------------------------------------------
 * A page and the mount's capture are both AVs with a fixed slot enum, the way
 * Punk::Context (PCX_*) and Punk::View::Stencil (PVS_*) do it: refcount
 * managed for free and cloneable under ithreads, which a C struct behind an
 * IV would not be. */

enum { PMD_URL = 0,      /* mount-relative, no trailing slash; "" is the root */
       PMD_FILE,         /* absolute source path */
       PMD_TITLE,        /* page title */
       PMD_NAV,          /* sidebar label, usually the title */
       PMD_SECTION,      /* top-level directory, "" at the root */
       PMD_ORDER,        /* front matter order:, else IV_MAX */
       PMD_BODY,         /* the finished response bytes for the whole page */
       PMD_MTIME,
       PMD_DOCID,        /* the Search::Trigram document id */
       PMD_PLAIN,        /* plain text, for snippets */
       PMD__COUNT };

enum { PMDC_DIR = 0,     /* the docs root, no trailing slash */
       PMDC_PAGES,       /* HV: url -> the page AV above */
       PMDC_ORDER,       /* AV of urls, in nav order */
       PMDC_OPTS,        /* HV of resolved options */
       PMDC_STENCIL,     /* the Template::Stencil object */
       PMDC_MD,          /* the Markdown::Simple object */
       PMDC_INDEX,       /* the Search::Trigram object, or undef */
       PMDC_DOCMAP,      /* HV: doc_id -> url */
       PMDC_PREFIX,      /* the mount prefix, for building hrefs */
       PMDC_NOTFOUND,    /* the pre-rendered 404 body */
       PMDC_CSS,         /* the shipped stylesheet, slurped at boot */
       PMDC__COUNT };

/* ---- small helpers -------------------------------------------------------- */

static SV *pmd_opt(pTHX_ HV *opts, const char *k) {
    SV **v = opts ? hv_fetch(opts, k, (I32)strlen(k), 0) : NULL;
    return (v && *v && SvOK(*v)) ? *v : NULL;
}

static int pmd_opt_bool(pTHX_ HV *opts, const char *k, int dflt) {
    SV *v = pmd_opt(aTHX_ opts, k);
    return v ? (SvTRUE(v) ? 1 : 0) : dflt;
}

static const char *pmd_opt_str(pTHX_ HV *opts, const char *k,
                               const char *dflt) {
    SV *v = pmd_opt(aTHX_ opts, k);
    return v ? SvPV_nolen(v) : dflt;
}

/* Read a file whole, as bytes. The UTF-8 flag stays off deliberately: a PSGI
 * body must be octets or Content-Length will not match what goes on the wire,
 * and the parser is byte-oriented throughout. Returns a mortal SV, or NULL. */
static SV *pmd_slurp(pTHX_ const char *path) {
    PerlIO *fp = PerlIO_open(path, "rb");
    SV *out;
    char buf[8192];
    SSize_t got;
    if (!fp) return NULL;
    out = sv_2mortal(newSVpvs(""));
    while ((got = PerlIO_read(fp, buf, sizeof buf)) > 0)
        sv_catpvn(out, buf, (STRLEN)got);
    PerlIO_close(fp);
    return out;
}

/* Append `n` bytes of `s` to `out` with the five HTML metacharacters escaped.
 * Used for everything the mount puts into its own markup: titles in the nav,
 * the query echoed on the search page. The rendered markdown is not escaped
 * here - Markdown::Simple has already made it safe. */
static void pmd_esc(pTHX_ SV *out, const char *s, STRLEN n) {
    STRLEN i, run = 0;
    for (i = 0; i < n; i++) {
        const char *rep = NULL;
        switch (s[i]) {
            case '<':  rep = "&lt;";   break;
            case '>':  rep = "&gt;";   break;
            case '&':  rep = "&amp;";  break;
            case '"':  rep = "&quot;"; break;
            case '\'': rep = "&#39;";  break;
            default: run++; continue;
        }
        if (run) { sv_catpvn(out, s + i - run, run); run = 0; }
        sv_catpv(out, rep);
    }
    if (run) sv_catpvn(out, s + n - run, run);
}

/* The same, with runs of whitespace collapsed to a single space and the
 * leading run dropped. Search snippets are cut out of a document's plain
 * text, which still carries its paragraph breaks; a snippet is one line. */
static void pmd_esc_collapsed(pTHX_ SV *out, const char *s, STRLEN n) {
    STRLEN i = 0, run = 0;
    int started = 0;
    while (i < n && (s[i] == ' ' || s[i] == '\t' || s[i] == '\n' ||
                     s[i] == '\r')) i++;
    for (; i < n; i++) {
        char c = s[i];
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
            if (run) { pmd_esc(aTHX_ out, s + i - run, run); run = 0; }
            started = 1;
            continue;
        }
        if (started && !run) sv_catpvs(out, " ");
        run++;
    }
    if (run) pmd_esc(aTHX_ out, s + n - run, run);
}

static void pmd_esc_sv(pTHX_ SV *out, SV *in) {
    STRLEN n;
    const char *s = SvPV_const(in, n);
    pmd_esc(aTHX_ out, s, n);
}

/* ---- front matter ---------------------------------------------------------
 * A restricted `---\n key: value \n---\n` block at byte 0. Scalar values
 * only, and the first line that is not `key: value` ends the block. This is
 * deliberately not YAML: running a YAML parser per page at boot to read two
 * scalars would put a dependency on the C path for no benefit. Unknown keys
 * are ignored rather than an error, so a document carrying front matter for
 * some other tool still renders.
 *
 * Returns the offset of the body, and fills `meta` with what it recognised. */
static STRLEN pmd_front_matter(pTHX_ const char *s, STRLEN n, HV *meta) {
    STRLEN i = 0, line;
    if (n < 4 || memNE(s, "---\n", 4)) return 0;
    i = 4;
    while (i < n) {
        STRLEN k0, kend, v0, vend;
        /* end of block? */
        if (n - i >= 4 && memEQ(s + i, "---\n", 4)) return i + 4;
        if (n - i == 3 && memEQ(s + i, "---", 3))   return n;
        line = i;
        while (line < n && s[line] != '\n') line++;
        /* key: value */
        k0 = i;
        kend = k0;
        while (kend < line && s[kend] != ':') kend++;
        if (kend >= line) return 0;              /* not a mapping: not ours */
        v0 = kend + 1;
        while (v0 < line && (s[v0] == ' ' || s[v0] == '\t')) v0++;
        vend = line;
        while (vend > v0 && (s[vend - 1] == ' ' || s[vend - 1] == '\t' ||
                             s[vend - 1] == '\r')) vend--;
        /* strip one layer of matching quotes */
        if (vend - v0 >= 2 && (s[v0] == '"' || s[v0] == '\'') &&
            s[vend - 1] == s[v0]) { v0++; vend--; }
        if (kend > k0)
            (void)hv_store(meta, s + k0, (I32)(kend - k0),
                           newSVpvn(s + v0, vend - v0), 0);
        i = line + 1;
    }
    return 0;                                    /* never closed: not ours */
}

/* The first `# H1`, as a title. Looks only at the top of the document, since
 * a title further down is a section heading and not the page's name. */
static SV *pmd_first_h1(pTHX_ const char *s, STRLEN n) {
    STRLEN i = 0;
    while (i < n) {
        STRLEN line = i;
        while (line < n && s[line] != '\n') line++;
        if (line > i + 1 && s[i] == '#' && s[i + 1] == ' ') {
            STRLEN t0 = i + 2, t1 = line;
            while (t0 < t1 && s[t0] == ' ') t0++;
            while (t1 > t0 && (s[t1 - 1] == ' ' || s[t1 - 1] == '\r' ||
                               s[t1 - 1] == '#')) t1--;
            if (t1 > t0) return newSVpvn(s + t0, t1 - t0);
        }
        i = line + 1;
    }
    return NULL;
}

/* A filename as a title: hyphens and underscores to spaces, each word
 * capitalised. The last resort, when there is neither front matter nor an
 * H1 to take the name from. */
static SV *pmd_title_from_name(pTHX_ const char *s, STRLEN n) {
    SV *out = newSVpvs("");
    STRLEN i;
    int start = 1;
    for (i = 0; i < n; i++) {
        char c = s[i];
        if (c == '-' || c == '_') { sv_catpvs(out, " "); start = 1; continue; }
        if (start && c >= 'a' && c <= 'z') c = (char)(c - 'a' + 'A');
        sv_catpvn(out, &c, 1);
        start = 0;
    }
    return out;
}

/* ---- walking the tree -----------------------------------------------------
 * Modelled on poa_walk_dir in punk_oamount.h - PerlDir_open, dot entries
 * skipped, sortsv for a traversal that is stable across filesystems, recurse
 * into directories - but that one is @INC-relative and builds class names out
 * of what it finds, so this is a sibling rather than a reuse.
 *
 * Only `.md` files are collected. Everything else in the tree is an asset and
 * is served on demand through ps_serve_file, so there is nothing to enumerate
 * for it here. */

static void pmd_walk_dir(pTHX_ const char *root, SV *rel, AV *out,
                         int recursive) {
    SV *dir = sv_2mortal(newSVpv(root, 0));
    DIR *dh;
    Direntry_t *de;
    AV *ents = (AV *)sv_2mortal((SV *)newAV());
    SSize_t i, n;

    if (SvCUR(rel)) { sv_catpvs(dir, "/"); sv_catsv(dir, rel); }
    dh = PerlDir_open(SvPV_nolen(dir));
    if (!dh) return;
    while ((de = PerlDir_read(dh))) {
        const char *nm = de->d_name;
        if (nm[0] == '.') continue;          /* . .. and dotfiles alike */
        av_push(ents, newSVpv(nm, 0));
    }
    PerlDir_close(dh);

    n = av_len(ents) + 1;
    if (n > 1) sortsv(AvARRAY(ents), (STRLEN)n, Perl_sv_cmp);

    for (i = 0; i < n; i++) {
        SV *ent = *av_fetch(ents, i, 0);
        STRLEN el;
        const char *es = SvPV_const(ent, el);
        SV *child = sv_2mortal(newSVsv(rel));
        SV *full  = sv_2mortal(newSVsv(dir));
        Stat_t st;
        if (SvCUR(child)) sv_catpvs(child, "/");
        sv_catsv(child, ent);
        sv_catpvs(full, "/"); sv_catsv(full, ent);

        if (PerlLIO_stat(SvPV_nolen(full), &st) == 0 && S_ISDIR(st.st_mode)) {
            if (recursive) pmd_walk_dir(aTHX_ root, child, out, recursive);
            continue;
        }
        if (el > 3 && memEQ(es + el - 3, ".md", 3))
            av_push(out, newSVsv(child));
    }
}

/* `guide/intro.md` -> `/guide/intro`, `index.md` -> ``, `guide/index.md` ->
 * `/guide`. The mount root is the empty string rather than "/" so that
 * joining it to the prefix cannot double a slash. */
static SV *pmd_url_for(pTHX_ SV *rel, const char *index_name) {
    STRLEN rl, il = strlen(index_name);
    const char *r = SvPV_const(rel, rl);
    SV *url;
    STRLEN keep = rl - 3;                    /* drop ".md" */

    /* an index file collapses to its containing directory */
    if (rl >= il && memEQ(r + rl - il, index_name, il)) {
        if (rl == il) return newSVpvs("");    /* the root index */
        if (r[rl - il - 1] == '/') keep = rl - il - 1;
    }
    url = newSVpvs("/");
    sv_catpvn(url, r, keep);
    return url;
}

/* The top-level directory a page sits in, or "" for one at the root. */
static SV *pmd_section_for(pTHX_ SV *rel) {
    STRLEN rl;
    const char *r = SvPV_const(rel, rl);
    const char *slash = (const char *)memchr(r, '/', rl);
    if (!slash) return newSVpvs("");
    return newSVpvn(r, (STRLEN)(slash - r));
}

/* ---- the navigation -------------------------------------------------------
 * Built in C and injected into the template with {% raw nav %}. Stencil has
 * no recursion and no dynamic includes, so an arbitrarily deep tree cannot be
 * looped in a template, and flattening to a fixed depth would silently
 * truncate a three-level docs tree.
 *
 * The nav is rebuilt per page so the current entry can carry a class, rather
 * than marking it in JavaScript. Every page is rendered at boot anyway, so
 * this costs pages x nav-size once at startup - nothing for a docs tree - and
 * it means the highlight works with JavaScript off. */

static SV *pmd_nav_html(pTHX_ AV *order, HV *pages, SV *prefix, SV *current) {
    SV *out = newSVpvs("");
    SSize_t i, n = av_len(order) + 1;
    SV *open_section = NULL;
    STRLEN cl;
    const char *cur = SvPV_const(current, cl);

    sv_catpvs(out, "<ul class=\"punk-md-nav\">\n");
    for (i = 0; i < n; i++) {
        SV **up = av_fetch(order, i, 0);
        HE *he;
        AV *page;
        SV *url, *label, *section;
        STRLEN ul;
        const char *us;
        if (!up || !*up) continue;
        he = hv_fetch_ent(pages, *up, 0, 0);
        if (!he || !HeVAL(he) || !SvROK(HeVAL(he))) continue;
        page = (AV *)SvRV(HeVAL(he));

        url     = *av_fetch(page, PMD_URL, 0);
        label   = *av_fetch(page, PMD_NAV, 0);
        section = *av_fetch(page, PMD_SECTION, 0);

        /* open or close a section group as the ordered list crosses one */
        if (!open_section || sv_cmp(open_section, section) != 0) {
            if (open_section && SvCUR(open_section))
                sv_catpvs(out, "</ul></details></li>\n");
            if (SvCUR(section)) {
                SV *lbl = sv_2mortal(pmd_title_from_name(aTHX_
                            SvPVX(section), SvCUR(section)));
                sv_catpvs(out, "<li class=\"punk-md-section\">"
                               "<details open><summary>");
                pmd_esc_sv(aTHX_ out, lbl);
                sv_catpvs(out, "</summary><ul>\n");
            }
            if (open_section) SvREFCNT_dec(open_section);
            open_section = newSVsv(section);
        }

        us = SvPV_const(url, ul);
        sv_catpvs(out, "<li><a href=\"");
        pmd_esc_sv(aTHX_ out, prefix);
        pmd_esc(aTHX_ out, us, ul);
        if (ul == cl && (ul == 0 || memEQ(us, cur, ul)))
            sv_catpvs(out, "\" class=\"current\" aria-current=\"page\">");
        else
            sv_catpvs(out, "\">");
        pmd_esc_sv(aTHX_ out, label);
        sv_catpvs(out, "</a></li>\n");
    }
    if (open_section) {
        if (SvCUR(open_section)) sv_catpvs(out, "</ul></details></li>\n");
        SvREFCNT_dec(open_section);
    }
    sv_catpvs(out, "</ul>\n");
    return out;
}

/* The per-page table of contents, from the heading list mds_abi handed back.
 * h2 and h3 only: h1 is the page title, and deeper than h3 is noise in a
 * sidebar. */
static SV *pmd_toc_html(pTHX_ AV *toc) {
    SV *out = newSVpvs("");
    SSize_t i, n = av_len(toc) + 1;
    int any = 0;
    for (i = 0; i < n; i++) {
        SV **e = av_fetch(toc, i, 0);
        HV *h;
        SV **lv, **tx, **id;
        IV level;
        if (!e || !*e || !SvROK(*e)) continue;
        h = (HV *)SvRV(*e);
        lv = hv_fetchs(h, "level", 0);
        tx = hv_fetchs(h, "text", 0);
        id = hv_fetchs(h, "id", 0);
        if (!lv || !tx || !id) continue;
        level = SvIV(*lv);
        if (level < 2 || level > 3) continue;
        if (!any) { sv_catpvs(out, "<ul class=\"punk-md-toc\">\n"); any = 1; }
        /* sv_catpvs wants a literal it can size at compile time, so the
         * branch has to be outside it rather than in a conditional. */
        if (level == 2) sv_catpvs(out, "<li class=\"lvl2\"><a href=\"#");
        else            sv_catpvs(out, "<li class=\"lvl3\"><a href=\"#");
        pmd_esc_sv(aTHX_ out, *id);
        sv_catpvs(out, "\">");
        pmd_esc_sv(aTHX_ out, *tx);
        sv_catpvs(out, "</a></li>\n");
    }
    if (any) sv_catpvs(out, "</ul>\n");
    return out;
}

/* ---- the page shell -------------------------------------------------------
 * One Stencil render, through the st_abi table. Per that ABI's contract
 * engine_of is called on every render and the pointer is never cached: an
 * ithread clone drops its engine and rebuilds lazily, so a cached handle
 * would outlive what it points at. That is nearly moot at boot but matters
 * under `reload`. */

/* Everything this mount handles is UTF-8 octets: the source files are read
 * raw, and Markdown::Simple renders bytes to bytes. Template::Stencil,
 * though, deals in characters and encodes its output, so handing it octets
 * would encode them a second time and turn every accented character into
 * mojibake.
 *
 * So decode on the way in and let Stencil do the one encode. sv_utf8_decode
 * validates: bytes that are not well-formed UTF-8 are left alone rather than
 * flagged, which keeps a mis-encoded source file from corrupting the render
 * of everything around it. */
static SV *pmd_chars(pTHX_ SV *sv) {
    if (sv && SvOK(sv) && !SvUTF8(sv)) (void)sv_utf8_decode(sv);
    return sv;
}

/* `kind` tells the template which of the three things it is rendering:
 * "page" for a document, "search" for the results page, "notfound" for the
 * 404. All three go through the same template, so without it an overriding
 * template has no way to tell them apart and cannot, say, drop the table of
 * contents from a results page. */
static SV *pmd_shell(pTHX_ AV *cap, const char *kind, SV *title, SV *nav,
                     SV *content, SV *toc, SV *url) {
    const st_abi *st = punk_st(aTHX);
    HV *opts = (HV *)SvRV(*av_fetch(cap, PMDC_OPTS, 0));
    SV *engine_sv = *av_fetch(cap, PMDC_STENCIL, 0);
    void *engine = st->engine_of(aTHX_ engine_sv);
    HV *data = (HV *)sv_2mortal((SV *)newHV());
    SV *tmpl = sv_2mortal(newSVpvs("page"));
    SV *err = NULL, *out;
    SV *site = pmd_opt(aTHX_ opts, "title");
    SV *foot = pmd_opt(aTHX_ opts, "footer");

    if (!engine)
        croak("Punk::Mount::Markdown: the view engine is not a "
              "Template::Stencil");

    (void)hv_stores(data, "kind",       newSVpv(kind, 0));
    (void)hv_stores(data, "title",      pmd_chars(aTHX_ newSVsv(title)));
    (void)hv_stores(data, "site_title", pmd_chars(aTHX_
                                            site ? newSVsv(site)
                                                 : newSVsv(title)));
    (void)hv_stores(data, "nav",        pmd_chars(aTHX_ newSVsv(nav)));
    (void)hv_stores(data, "content",    pmd_chars(aTHX_ newSVsv(content)));
    (void)hv_stores(data, "toc",        pmd_chars(aTHX_
                                            toc ? newSVsv(toc)
                                                : newSVpvs("")));
    (void)hv_stores(data, "url",        pmd_chars(aTHX_ newSVsv(url)));
    (void)hv_stores(data, "prefix",     newSVsv(*av_fetch(cap, PMDC_PREFIX, 0)));
    (void)hv_stores(data, "search",
        newSViv(SvOK(*av_fetch(cap, PMDC_INDEX, 0)) ? 1 : 0));
    (void)hv_stores(data, "search_path",
        newSVpv(pmd_opt_str(aTHX_ opts, "search_path", "/search"), 0));
    (void)hv_stores(data, "assets",
        newSVpv(pmd_opt_str(aTHX_ opts, "assets", "/_punk"), 0));
    (void)hv_stores(data, "footer",     pmd_chars(aTHX_
                                            foot ? newSVsv(foot)
                                                 : newSVpvs("")));

    out = st->render(aTHX_ engine, tmpl, data, NULL, &err);
    if (!out)
        croak_sv(err ? err
                     : sv_2mortal(newSVpvs("Punk::Mount::Markdown: the page "
                                           "template failed to render")));
    return out;
}

/* Render one page from its source and freeze the finished bytes into
 * PMD_BODY. Shared by the boot pass and the reload path. */
static void pmd_render_page(pTHX_ AV *cap, AV *page) {
    const mds_abi *md = punk_mds(aTHX);
    HV *pages = (HV *)SvRV(*av_fetch(cap, PMDC_PAGES, 0));
    AV *order = (AV *)SvRV(*av_fetch(cap, PMDC_ORDER, 0));
    HV *opts  = (HV *)SvRV(*av_fetch(cap, PMDC_OPTS, 0));
    SV *file  = *av_fetch(page, PMD_FILE, 0);
    SV *src, *html, *nav, *toc_html = NULL, *body, *err = NULL;
    AV *toc = NULL;
    STRLEN blen, off;
    const char *bytes;
    HV *meta = (HV *)sv_2mortal((SV *)newHV());

    src = pmd_slurp(aTHX_ SvPV_nolen(file));
    if (!src)
        croak("Punk::Mount::Markdown: cannot read '%s'", SvPV_nolen(file));
    bytes = SvPV_const(src, blen);
    off = pmd_front_matter(aTHX_ bytes, blen, meta);

    html = sv_2mortal(newSVpvs(""));
    if (pmd_opt_bool(aTHX_ opts, "toc", 1))
        toc = (AV *)sv_2mortal((SV *)newAV());
    if (md->session_render(aTHX_
            md->session_of(aTHX_ *av_fetch(cap, PMDC_MD, 0)),
            bytes + off, blen - off, html, toc, &err) != 0)
        croak_sv(err ? err : sv_2mortal(newSVpvs(
            "Punk::Mount::Markdown: a document failed to render")));

    if (toc) toc_html = sv_2mortal(pmd_toc_html(aTHX_ toc));

    nav  = sv_2mortal(pmd_nav_html(aTHX_ order, pages,
                                   *av_fetch(cap, PMDC_PREFIX, 0),
                                   *av_fetch(page, PMD_URL, 0)));
    body = pmd_shell(aTHX_ cap, "page", *av_fetch(page, PMD_TITLE, 0), nav,
                     html, toc_html, *av_fetch(page, PMD_URL, 0));
    av_store(page, PMD_BODY, body);
}

/* ---- responses ------------------------------------------------------------ */

/* An HTML triplet over frozen bytes, with the mount's header block. */
static SV *pmd_html_response(pTHX_ AV *cap, IV status, SV *body, int is_head) {
    AV *resp = newAV(), *headers = newAV(), *bodyav = newAV();
    HV *opts = (HV *)SvRV(*av_fetch(cap, PMDC_OPTS, 0));
    SV *hdrs = pmd_opt(aTHX_ opts, "headers");
    STRLEN n;
    const char *b = SvPV_const(body, n);

    av_push(headers, newSVpvs("Content-Type"));
    av_push(headers, newSVpvs("text/html; charset=utf-8"));
    av_push(headers, newSVpvs("Content-Length"));
    av_push(headers, newSViv((IV)n));
    if (hdrs && SvROK(hdrs) && SvTYPE(SvRV(hdrs)) == SVt_PVHV) {
        HV *hh = (HV *)SvRV(hdrs);
        HE *he;
        hv_iterinit(hh);
        while ((he = hv_iternext(hh))) {
            av_push(headers, newSVsv(hv_iterkeysv(he)));
            av_push(headers, newSVsv(hv_iterval(hh, he)));
        }
    }
    av_push(bodyav, is_head ? newSVpvs("") : newSVpvn(b, n));
    av_push(resp, newSViv(status));
    av_push(resp, newRV_noinc((SV *)headers));
    av_push(resp, newRV_noinc((SV *)bodyav));
    return newRV_noinc((SV *)resp);
}

/* A 301 to the canonical url for a page, so a trailing slash or a `.md`
 * suffix does not become a second address for the same document. */
static SV *pmd_redirect(pTHX_ SV *location) {
    AV *resp = newAV(), *headers = newAV(), *body = newAV();
    av_push(headers, newSVpvs("Location"));
    av_push(headers, newSVsv(location));
    av_push(headers, newSVpvs("Content-Type"));
    av_push(headers, newSVpvs("text/plain; charset=utf-8"));
    av_push(headers, newSVpvs("Content-Length"));
    av_push(headers, newSViv(0));
    av_push(body, newSVpvs(""));
    av_push(resp, newSViv(301));
    av_push(resp, newRV_noinc((SV *)headers));
    av_push(resp, newRV_noinc((SV *)body));
    return newRV_noinc((SV *)resp);
}

/* ---- search ---------------------------------------------------------------
 * The one request path that is not frozen. The query string is parsed with
 * pq_parse_pairs from punk_request.h, the index queried through sg_abi into a
 * stack array, and the hits mapped back to pages through the doc_id map. */

static SV *pmd_search_page(pTHX_ AV *cap, HV *env) {
    const sg_abi *sg = punk_sg_try(aTHX);
    SV *idx_sv = *av_fetch(cap, PMDC_INDEX, 0);
    HV *pages  = (HV *)SvRV(*av_fetch(cap, PMDC_PAGES, 0));
    AV *order  = (AV *)SvRV(*av_fetch(cap, PMDC_ORDER, 0));
    HV *docmap = (HV *)SvRV(*av_fetch(cap, PMDC_DOCMAP, 0));
    SV *prefix = *av_fetch(cap, PMDC_PREFIX, 0);
    SV *content = sv_2mortal(newSVpvs(""));
    SV *query = NULL, *nav, *title;
    void *idx;
    sg_abi_hit hits[64];
    uint32_t n = 0, i;

    {   /* ?q=... */
        SV **qs = hv_fetchs(env, "QUERY_STRING", 0);
        if (qs && *qs && SvOK(*qs)) {
            STRLEN ql;
            const char *q = SvPV_const(*qs, ql);
            HV *pairs = pq_parse_pairs(aTHX_ q, ql);
            SV **v = hv_fetchs(pairs, "q", 0);
            if (v && *v && SvOK(*v)) query = sv_2mortal(newSVsv(*v));
            SvREFCNT_dec((SV *)pairs);
        }
    }

    sv_catpvs(content, "<h1 class=\"punk-md-search-title\">Search</h1>\n");
    sv_catpvs(content, "<form class=\"punk-md-search\" method=\"get\">"
                       "<input type=\"search\" name=\"q\" value=\"");
    if (query) pmd_esc_sv(aTHX_ content, query);
    sv_catpvs(content, "\" placeholder=\"Search the docs\" autofocus>"
                       "</form>\n");

    if (!query || !SvCUR(query)) {
        sv_catpvs(content, "<p class=\"punk-md-hint\">"
                           "Type a query to search these pages.</p>\n");
    }
    else if (sg && SvOK(idx_sv) && (idx = sg->index_of(aTHX_ idx_sv)) != NULL) {
        STRLEN ql;
        const char *q = SvPV_const(query, ql);
        n = sg->search(idx, q, (uint32_t)ql, 20, hits,
                       (uint32_t)(sizeof hits / sizeof hits[0]));
        if (!n) {
            sv_catpvs(content, "<p class=\"punk-md-empty\">No results for "
                               "<strong>");
            pmd_esc_sv(aTHX_ content, query);
            sv_catpvs(content, "</strong>.</p>\n");
        }
        else {
            sv_catpvs(content, "<ol class=\"punk-md-results\">\n");
            for (i = 0; i < n; i++) {
                SV *key = sv_2mortal(newSVuv(hits[i].doc_id));
                HE *he = hv_fetch_ent(docmap, key, 0, 0);
                HE *pe;
                AV *page;
                SV *plain;
                if (!he || !HeVAL(he)) continue;
                pe = hv_fetch_ent(pages, HeVAL(he), 0, 0);
                if (!pe || !HeVAL(pe) || !SvROK(HeVAL(pe))) continue;
                page = (AV *)SvRV(HeVAL(pe));
                sv_catpvs(content, "<li><a href=\"");
                pmd_esc_sv(aTHX_ content, prefix);
                pmd_esc_sv(aTHX_ content, *av_fetch(page, PMD_URL, 0));
                sv_catpvs(content, "\">");
                pmd_esc_sv(aTHX_ content, *av_fetch(page, PMD_TITLE, 0));
                sv_catpvs(content, "</a>");
                plain = *av_fetch(page, PMD_PLAIN, 0);
                if (SvOK(plain) && SvCUR(plain)) {
                    STRLEN pl;
                    const char *p = SvPV_const(plain, pl);
                    STRLEN take = pl < 180 ? pl : 180;
                    /* do not cut a UTF-8 sequence in half */
                    while (take && take < pl &&
                           ((unsigned char)p[take] & 0xC0) == 0x80) take--;
                    sv_catpvs(content, "<p class=\"punk-md-snippet\">");
                    pmd_esc_collapsed(aTHX_ content, p, take);
                    if (take < pl) sv_catpvs(content, "...");
                    sv_catpvs(content, "</p>");
                }
                sv_catpvs(content, "</li>\n");
            }
            sv_catpvs(content, "</ol>\n");
        }
    }
    else {
        sv_catpvs(content, "<p class=\"punk-md-empty\">"
                           "Search is not available.</p>\n");
    }

    title = sv_2mortal(newSVpvs("Search"));
    nav = sv_2mortal(pmd_nav_html(aTHX_ order, pages, prefix,
                                  sv_2mortal(newSVpvs("\x01none"))));
    return pmd_shell(aTHX_ cap, "search", title, nav, content, NULL,
                     sv_2mortal(newSVpv(
                         pmd_opt_str(aTHX_
                             (HV *)SvRV(*av_fetch(cap, PMDC_OPTS, 0)),
                             "search_path", "/search"), 0)));
}

/* ---- the app ---------------------------------------------------------------
 * The PSGI coderef's body: a magic CV whose capture is the built site. */

XS_INTERNAL(punk_md_cb);
XS_INTERNAL(punk_md_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    HV *env, *pages, *opts;
    SV **e;
    const char *path, *method;
    STRLEN plen, mlen = 3;
    int is_head = 0;
    SV *key, *resp = NULL;
    HE *he;

    if (!cap || items < 1) XSRETURN_EMPTY;
    if (!SvROK(ST(0)) || SvTYPE(SvRV(ST(0))) != SVt_PVHV)
        croak("Punk::Mount::Markdown: the app takes a PSGI env hashref");
    env   = (HV *)SvRV(ST(0));
    pages = (HV *)SvRV(*av_fetch(cap, PMDC_PAGES, 0));
    opts  = (HV *)SvRV(*av_fetch(cap, PMDC_OPTS, 0));

    e = hv_fetchs(env, "REQUEST_METHOD", 0);
    method = (e && *e && SvOK(*e)) ? SvPV_const(*e, mlen) : "GET";
    if (mlen == 4 && memEQ(method, "HEAD", 4)) is_head = 1;
    else if (!(mlen == 3 && memEQ(method, "GET", 3))) {
        ST(0) = sv_2mortal(ps_plain(aTHX_ 405, "Method Not Allowed",
                                    "Allow", "GET, HEAD"));
        XSRETURN(1);
    }

    e = hv_fetchs(env, "PATH_INFO", 0);
    if (e && *e && SvOK(*e)) path = SvPV_const(*e, plen);
    else { path = "/"; plen = 1; }

    /* The mount loop hands us "/" for the bare prefix; the page table keys
     * the root as "". */
    if (plen == 1 && path[0] == '/') { path = ""; plen = 0; }

    /* Canonicalise: a trailing slash or a .md suffix redirects rather than
     * becoming a second address for the same document. */
    if ((plen > 1 && path[plen - 1] == '/') ||
        (plen > 3 && memEQ(path + plen - 3, ".md", 3))) {
        STRLEN keep = path[plen - 1] == '/' ? plen - 1 : plen - 3;
        SV *loc = sv_2mortal(newSVsv(*av_fetch(cap, PMDC_PREFIX, 0)));
        sv_catpvn(loc, path, keep);
        ST(0) = sv_2mortal(pmd_redirect(aTHX_ loc));
        XSRETURN(1);
    }

    /* the search page */
    {
        const char *sp = pmd_opt_str(aTHX_ opts, "search_path", "/search");
        STRLEN spl = strlen(sp);
        if (plen == spl && memEQ(path, sp, spl)) {
            SV *body = sv_2mortal(pmd_search_page(aTHX_ cap, env));
            ST(0) = sv_2mortal(pmd_html_response(aTHX_ cap, 200, body,
                                                 is_head));
            XSRETURN(1);
        }
    }

    /* the shipped stylesheet, slurped at boot and served from the mount's
     * assets path rather than from the documents directory */
    {
        const char *ap = pmd_opt_str(aTHX_ opts, "assets", "/_punk");
        STRLEN apl = strlen(ap);
        SV *css = *av_fetch(cap, PMDC_CSS, 0);
        if (plen == apl + 8 && memEQ(path, ap, apl) &&
            memEQ(path + apl, "/app.css", 8) && SvOK(css)) {
            AV *resp = newAV(), *headers = newAV(), *bodyav = newAV();
            STRLEN cn;
            const char *cb = SvPV_const(css, cn);
            av_push(headers, newSVpvs("Content-Type"));
            av_push(headers, newSVpvs("text/css; charset=utf-8"));
            av_push(headers, newSVpvs("Content-Length"));
            av_push(headers, newSViv((IV)cn));
            av_push(bodyav, is_head ? newSVpvs("") : newSVpvn(cb, cn));
            av_push(resp, newSViv(200));
            av_push(resp, newRV_noinc((SV *)headers));
            av_push(resp, newRV_noinc((SV *)bodyav));
            ST(0) = sv_2mortal(newRV_noinc((SV *)resp));
            XSRETURN(1);
        }
    }

    /* a page */
    key = sv_2mortal(newSVpvn(path, plen));
    he = hv_fetch_ent(pages, key, 0, 0);
    if (he && HeVAL(he) && SvROK(HeVAL(he))) {
        AV *page = (AV *)SvRV(HeVAL(he));
        if (pmd_opt_bool(aTHX_ opts, "reload", 0)) {
            Stat_t st;
            SV *file = *av_fetch(page, PMD_FILE, 0);
            if (PerlLIO_stat(SvPV_nolen(file), &st) == 0 &&
                (IV)st.st_mtime != SvIV(*av_fetch(page, PMD_MTIME, 0))) {
                av_store(page, PMD_MTIME, newSViv((IV)st.st_mtime));
                pmd_render_page(aTHX_ cap, page);
            }
        }
        resp = pmd_html_response(aTHX_ cap, 200,
                                 *av_fetch(page, PMD_BODY, 0), is_head);
        ST(0) = sv_2mortal(resp);
        XSRETURN(1);
    }

    /* A tree with no index file has nothing at its root, but answering the
     * mount's own address with a 404 while holding a nav full of pages is
     * unhelpful. Send them to the first page instead. */
    if (plen == 0) {
        AV *order = (AV *)SvRV(*av_fetch(cap, PMDC_ORDER, 0));
        if (av_len(order) >= 0) {
            SV *loc = sv_2mortal(newSVsv(*av_fetch(cap, PMDC_PREFIX, 0)));
            sv_catsv(loc, *av_fetch(order, 0, 0));
            ST(0) = sv_2mortal(pmd_redirect(aTHX_ loc));
            XSRETURN(1);
        }
    }

    /* an asset sitting in the tree: same stat / 304 / sendfile behaviour as
     * the static mount, because it is literally the same function */
    if (!ps_path_unsafe(path, plen)) {
        SV *dir = *av_fetch(cap, PMDC_DIR, 0);
        STRLEN dlen;
        const char *d = SvPV_const(dir, dlen);
        char file[MAXPATHLEN + 1];
        if (dlen + plen <= MAXPATHLEN) {
            memcpy(file, d, dlen);
            memcpy(file + dlen, path, plen);
            file[dlen + plen] = '\0';
            resp = ps_serve_file(aTHX_ env, file, dlen + plen, is_head);
            if (resp) { ST(0) = sv_2mortal(resp); XSRETURN(1); }
        }
    }

    ST(0) = sv_2mortal(pmd_html_response(aTHX_ cap, 404,
                        *av_fetch(cap, PMDC_NOTFOUND, 0), is_head));
    XSRETURN(1);
}

#endif /* PUNK_MARKDOWN_H */

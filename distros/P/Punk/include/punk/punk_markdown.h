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
        dSP; int count, ok; IV p = 0;
        PUNK_MDS_TRIED = 1;
        if (PerlEnv_getenv("PUNK_FAKE_MDS_BAD")) return NULL;
        ok = pk_require_once(aTHX_ "Markdown::Simple", FALSE);
        SPAGAIN;
        if (ok) {
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
        dSP; int count, ok; IV p = 0;
        PUNK_SG_TRIED = 1;
        if (PerlEnv_getenv("PUNK_FAKE_SG_BAD")) return NULL;
        ok = pk_require_once(aTHX_ "Search::Trigram", FALSE);
        SPAGAIN;
        if (ok) {
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
       PMD_META,         /* RV to the front-matter HV, every key as written */
       PMD_DATE,         /* front matter date:, as an epoch, else undef */
       PMD_UPDATED,      /* updated:, else the date, else undef */
       PMD_SECLABEL,     /* the section's sidebar label */
       PMD_SECORDER,     /* the section's place among the sections */
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
    punk_html_escape(aTHX_ out, s, n);
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

/* How many of `n` bytes to keep so that at most `max` survive and a UTF-8
 * sequence is not cut in half. Shared by the search snippets and the page
 * summaries. */
static STRLEN pmd_cut(const char *s, STRLEN n, STRLEN max) {
    STRLEN take = n < max ? n : max;
    while (take && take < n && ((unsigned char)s[take] & 0xC0) == 0x80) take--;
    return take;
}

/* Runs of whitespace collapsed to one space, the leading run dropped, NOT
 * escaped: for a summary handed to Perl, which escapes where it prints. */
static void pmd_collapsed(pTHX_ SV *out, const char *s, STRLEN n) {
    STRLEN i = 0;
    int space = 0;
    while (i < n && (s[i] == ' ' || s[i] == '\t' || s[i] == '\n' ||
                     s[i] == '\r')) i++;
    for (; i < n; i++) {
        char c = s[i];
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r') { space = 1; continue; }
        if (space) { sv_catpvs(out, " "); space = 0; }
        sv_catpvn(out, &c, 1);
    }
}

/* ---- front matter ---------------------------------------------------------
 * A restricted `---\n key: value \n---\n` block at byte 0. Scalar values
 * only, and the first line that is not `key: value` ends the block. This is
 * deliberately not YAML: running a YAML parser per page at boot to read two
 * scalars would put a dependency on the C path for no benefit. Unknown keys
 * are ignored rather than an error, so a document carrying front matter for
 * some other tool still renders, and every key, recognised or not, reaches
 * the templates as `meta`.
 *
 * Returns the offset of the body, and fills `meta` with every key it read. */
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

/* ---- dates ----------------------------------------------------------------
 * `date:` and `updated:` in front matter: YYYY-MM-DD (midnight UTC), or
 * YYYY-MM-DDTHH:MM[:SS] followed by Z or a +HH:MM / -HH:MM offset. Parsed by
 * hand rather than through strptime/timegm, which Windows lacks, with the
 * days-from-civil arithmetic (proleptic Gregorian) doing the calendar. */

static IV pmd_days_from_civil(IV y, IV m, IV d) {
    IV era, yoe, doy, doe;
    y -= m <= 2;
    era = (y >= 0 ? y : y - 399) / 400;
    yoe = y - era * 400;
    doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
    doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}

static void pmd_civil_from_days(IV z, IV *y, IV *m, IV *d) {
    IV era, doe, yoe, doy, mp;
    z += 719468;
    era = (z >= 0 ? z : z - 146096) / 146097;
    doe = z - era * 146097;
    yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    mp  = (5 * doy + 2) / 153;
    *d = doy - (153 * mp + 2) / 5 + 1;
    *m = mp + (mp < 10 ? 3 : -9);
    *y = yoe + era * 400 + (*m <= 2);
}

static int pmd_digits(const char *s, int n, IV *out) {
    int i;
    IV v = 0;
    for (i = 0; i < n; i++) {
        if (s[i] < '0' || s[i] > '9') return 0;
        v = v * 10 + (s[i] - '0');
    }
    *out = v;
    return 1;
}

/* Returns 1 and the epoch in *out, or 0 for anything that is not one of the
 * forms above, including an impossible day (2026-02-30) and an epoch past
 * what an IV holds on this perl. */
static int pmd_parse_date(const char *s, STRLEN n, IV *out) {
    IV y, mo, d, hh = 0, mi = 0, ss = 0, off = 0, days;
    static const int mdays[] = { 31,28,31,30,31,30,31,31,30,31,30,31 };
    NV secs;
    if (n < 10 || s[4] != '-' || s[7] != '-') return 0;
    if (!pmd_digits(s, 4, &y) || !pmd_digits(s + 5, 2, &mo)
        || !pmd_digits(s + 8, 2, &d)) return 0;
    if (mo < 1 || mo > 12 || d < 1) return 0;
    if (d > mdays[mo - 1] + (mo == 2 && ((y % 4 == 0 && y % 100 != 0)
                                         || y % 400 == 0)))
        return 0;
    if (n > 10) {
        STRLEN i = 16;
        if (n < 17 || (s[10] != 'T' && s[10] != ' ') || s[13] != ':')
            return 0;
        if (!pmd_digits(s + 11, 2, &hh) || !pmd_digits(s + 14, 2, &mi))
            return 0;
        if (n > 16 && s[16] == ':') {
            if (n < 19 || !pmd_digits(s + 17, 2, &ss)) return 0;
            i = 19;
        }
        if (hh > 23 || mi > 59 || ss > 59) return 0;
        if (i == n) return 0;                   /* a time needs its zone */
        if (s[i] == 'Z' && i + 1 == n) off = 0;
        else if ((s[i] == '+' || s[i] == '-') && i + 6 == n
                 && s[i + 3] == ':') {
            IV oh, om;
            if (!pmd_digits(s + i + 1, 2, &oh)
                || !pmd_digits(s + i + 4, 2, &om)
                || oh > 23 || om > 59) return 0;
            off = (oh * 3600 + om * 60) * (s[i] == '-' ? -1 : 1);
        }
        else return 0;
    }
    days = pmd_days_from_civil(y, mo, d);
    secs = (NV)days * 86400.0 + (NV)(hh * 3600 + mi * 60 + ss) - (NV)off;
    if (secs > (NV)IV_MAX || secs < (NV)IV_MIN) return 0;
    *out = (IV)secs;
    return 1;
}

/* An epoch as YYYY-MM-DDTHH:MM:SSZ, for <time datetime> and article:*_time. */
static SV *pmd_iso(pTHX_ IV t) {
    IV days = t / 86400, rem = t % 86400, y, m, d;
    if (rem < 0) { rem += 86400; days--; }
    pmd_civil_from_days(days, &y, &m, &d);
    return newSVpvf("%04" IVdf "-%02" IVdf "-%02" IVdf "T%02" IVdf ":%02"
                    IVdf ":%02" IVdf "Z", y, m, d, rem / 3600,
                    (rem % 3600) / 60, rem % 60);
}

/* An epoch as "19 October 2026", in UTC. English only: a site wanting
 * another language has the epoch. */
static SV *pmd_human(pTHX_ IV t) {
    static const char *const names[] = { "January", "February", "March",
        "April", "May", "June", "July", "August", "September", "October",
        "November", "December" };
    IV days = t / 86400, y, m, d;
    if (t % 86400 < 0) days--;
    pmd_civil_from_days(days, &y, &m, &d);
    return newSVpvf("%" IVdf " %s %" IVdf, d, names[m - 1], y);
}

/* Read date: and updated: from a page's front matter into its slots. A value
 * that does not parse croaks naming the file, at boot with the rest of the
 * configuration; under `reload` the same croak reaches the developer as an
 * error page on the request that read the bad edit. */
static void pmd_page_dates(pTHX_ AV *page, HV *meta) {
    SV *v, *file = *av_fetch(page, PMD_FILE, 0);
    IV t;
    int have = 0;
    if ((v = pmd_opt(aTHX_ meta, "date")) && SvCUR(v)) {
        STRLEN l;
        const char *p = SvPV_const(v, l);
        if (!pmd_parse_date(p, l, &t))
            croak("Punk::Mount::Markdown: %s has date '%s', which is not "
                  "YYYY-MM-DD or ISO-8601", SvPV_nolen(file), p);
        av_store(page, PMD_DATE, newSViv(t));
        have = 1;
    }
    else av_store(page, PMD_DATE, newSV(0));
    if ((v = pmd_opt(aTHX_ meta, "updated")) && SvCUR(v)) {
        STRLEN l;
        const char *p = SvPV_const(v, l);
        IV u;
        if (!pmd_parse_date(p, l, &u))
            croak("Punk::Mount::Markdown: %s has updated '%s', which is not "
                  "YYYY-MM-DD or ISO-8601", SvPV_nolen(file), p);
        av_store(page, PMD_UPDATED, newSViv(u));
    }
    else av_store(page, PMD_UPDATED, have ? newSViv(t) : newSV(0));
}

/* The `sort => 'date'` key: copied out of the page AVs so the comparator is
 * plain C and needs no interpreter. */
typedef struct {
    int dated;
    IV date;
    const char *title, *url;
    STRLEN tlen, ulen;
    SV *sv;
} pmd_sortkey;

static int pmd_bytecmp(const char *a, STRLEN al, const char *b, STRLEN bl) {
    int c = memcmp(a, b, al < bl ? al : bl);
    if (c) return c;
    return al < bl ? -1 : al > bl ? 1 : 0;
}

static int pmd_sortkey_cmp(const void *pa, const void *pb) {
    const pmd_sortkey *a = (const pmd_sortkey *)pa;
    const pmd_sortkey *b = (const pmd_sortkey *)pb;
    int c;
    if (a->dated != b->dated) return a->dated ? -1 : 1;
    if (a->dated && a->date != b->date) return a->date > b->date ? -1 : 1;
    if (a->dated) {
        c = pmd_bytecmp(a->title, a->tlen, b->title, b->tlen);
        if (c) return c;
    }
    return pmd_bytecmp(a->url, a->ulen, b->url, b->ulen);
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
                sv_catpvs(out, "<li class=\"punk-md-section\">"
                               "<details open><summary>");
                pmd_esc_sv(aTHX_ out, *av_fetch(page, PMD_SECLABEL, 0));
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

/* ---- SEO fields ----------------------------------------------------------
 * What the shipped wrapper needs to write a page's meta tags, worked out here
 * because a template cannot do path arithmetic:
 *
 *   host          the app's `host`, passed in at compile; "" without one
 *   canonical     front-matter `canonical`, else host + prefix + url; "" with
 *                 neither, and always "" off a page
 *   image         front-matter `image` made absolute: an http(s) URL as is, a
 *                 rooted path on the host, anything else beside the source
 *                 file (host + prefix + its directory)
 *   og_type       front-matter `og_type`, else `article` with a `date`, else
 *                 `website`
 *   twitter_card  `summary_large_image` with an image, else `summary`
 *
 * The origin is never the request's: the page is frozen at boot, before there
 * is one, and a canonical taken from a Host header is how a cache is taught
 * somebody else's hostname. */
/* The names the mount itself puts in front of the templates; `vars` may not
 * use them. */
static const char *const pmd_reserved[] = {
    "kind", "title", "site_title", "nav", "content", "toc", "url", "prefix",
    "search", "search_path", "assets", "footer", "meta", "host", "canonical",
    "image", "og_type", "twitter_card", "date", "updated", "date_iso",
    "updated_iso", "date_human", "updated_human", NULL
};

static void pmd_seo(pTHX_ AV *cap, HV *data, AV *page, HV *meta, SV *url) {
    HV *opts = (HV *)SvRV(*av_fetch(cap, PMDC_OPTS, 0));
    SV *host = pmd_opt(aTHX_ opts, "host");
    SV *prefix = *av_fetch(cap, PMDC_PREFIX, 0);
    SV *canon = newSVpvs(""), *image = newSVpvs("");
    SV *v, **dp, **up;
    const char *ogt = "website";

    if (page) {
        if (meta && (v = pmd_opt(aTHX_ meta, "canonical")) && SvCUR(v))
            sv_setsv(canon, v);
        else if (host && SvCUR(host)) {
            sv_setsv(canon, host);
            sv_catsv(canon, prefix);
            sv_catsv(canon, url);
            if (!SvCUR(prefix) && !SvCUR(url)) sv_catpvs(canon, "/");
        }

        if (meta && (v = pmd_opt(aTHX_ meta, "image")) && SvCUR(v)) {
            STRLEN il;
            const char *ip = SvPV_const(v, il);
            if ((il > 7 && memEQ(ip, "http://", 7)) ||
                (il > 8 && memEQ(ip, "https://", 8)))
                sv_setsv(image, v);
            else {
                if (host) sv_setsv(image, host);
                if (ip[0] == '/') sv_catpvn(image, ip, il);
                else {
                    /* beside the source file: its directory under the root */
                    SV *root = *av_fetch(cap, PMDC_DIR, 0);
                    SV *file = *av_fetch(page, PMD_FILE, 0);
                    STRLEN rl, fl, k, dend;
                    const char *fp = SvPV_const(file, fl);
                    (void)SvPV_const(root, rl);
                    dend = rl;
                    for (k = fl; k > rl; k--)
                        if (fp[k - 1] == '/') { dend = k - 1; break; }
                    sv_catsv(image, prefix);
                    if (dend > rl) sv_catpvn(image, fp + rl, dend - rl);
                    sv_catpvs(image, "/");
                    sv_catpvn(image, ip, il);
                }
            }
        }

        if (meta && (v = pmd_opt(aTHX_ meta, "og_type")) && SvCUR(v))
            ogt = NULL;
        else if ((dp = av_fetch(page, PMD_DATE, 0)) && *dp && SvOK(*dp))
            ogt = "article";

        dp = av_fetch(page, PMD_DATE, 0);
        up = av_fetch(page, PMD_UPDATED, 0);
        if (dp && *dp && SvOK(*dp)) {
            IV t = SvIV(*dp);
            (void)hv_stores(data, "date", newSViv(t));
            (void)hv_stores(data, "date_iso", pmd_iso(aTHX_ t));
            (void)hv_stores(data, "date_human", pmd_human(aTHX_ t));
        }
        if (up && *up && SvOK(*up)) {
            IV t = SvIV(*up);
            (void)hv_stores(data, "updated", newSViv(t));
            (void)hv_stores(data, "updated_iso", pmd_iso(aTHX_ t));
            (void)hv_stores(data, "updated_human", pmd_human(aTHX_ t));
        }
    }

    (void)hv_stores(data, "host",
        pmd_chars(aTHX_ host ? newSVsv(host) : newSVpvs("")));
    (void)hv_stores(data, "canonical", pmd_chars(aTHX_ canon));
    (void)hv_stores(data, "image", pmd_chars(aTHX_ image));
    (void)hv_stores(data, "og_type",
        ogt ? newSVpv(ogt, 0)
            : pmd_chars(aTHX_ newSVsv(pmd_opt(aTHX_ meta, "og_type"))));
    (void)hv_stores(data, "twitter_card",
        newSVpv(SvCUR(image) ? "summary_large_image" : "summary", 0));
}

/* `kind` tells the template which of the three things it is rendering:
 * "page" for a document, "search" for the results page, "notfound" for the
 * 404. All three go through the same template, so without it an overriding
 * template has no way to tell them apart and cannot, say, drop the table of
 * contents from a results page.
 *
 * `page` is the document being rendered, or NULL for the search page and the
 * 404. Its front matter arrives as `meta` (an empty hash without a page, so
 * `{% if meta.x %}` needs no kind check). The values are copied before
 * decoding: the page keeps its own bytes, and a reload renders from them
 * again. */
static SV *pmd_shell(pTHX_ AV *cap, const char *kind, SV *title, SV *nav,
                     SV *content, SV *toc, SV *url, AV *page) {
    const st_abi *st = punk_st(aTHX);
    HV *opts = (HV *)SvRV(*av_fetch(cap, PMDC_OPTS, 0));
    SV *engine_sv = *av_fetch(cap, PMDC_STENCIL, 0);
    void *engine = st->engine_of(aTHX_ engine_sv);
    HV *data = (HV *)sv_2mortal((SV *)newHV());
    SV *tmpl = sv_2mortal(newSVpvs("page"));
    SV *err = NULL, *out;
    SV *site = pmd_opt(aTHX_ opts, "title");
    SV *foot = pmd_opt(aTHX_ opts, "footer");
    HV *mcopy = newHV();
    HV *meta = NULL;

    if (page) {
        SV **mp = av_fetch(page, PMD_META, 0);
        if (mp && *mp && SvROK(*mp)) meta = (HV *)SvRV(*mp);
    }
    if (meta) {
        HE *he;
        hv_iterinit(meta);
        while ((he = hv_iternext(meta)))
            (void)hv_store_ent(mcopy, hv_iterkeysv(he),
                               pmd_chars(aTHX_ newSVsv(HeVAL(he))), 0);
    }
    (void)hv_stores(data, "meta", newRV_noinc((SV *)mcopy));
    pmd_seo(aTHX_ cap, data, page, meta, url);

    /* `vars`: the site's own values (its name, its links), the same on every
     * page. The names the mount fills are refused at boot, so nothing here
     * can shadow one; a value is a fresh copy so a template cannot reach the
     * caller's data. */
    {
        SV *vars = pmd_opt(aTHX_ opts, "vars");
        if (vars && SvROK(vars) && SvTYPE(SvRV(vars)) == SVt_PVHV) {
            HV *vh = (HV *)SvRV(vars);
            HE *he;
            hv_iterinit(vh);
            while ((he = hv_iternext(vh)))
                (void)hv_store_ent(data, hv_iterkeysv(he),
                                   newSVsv(HeVAL(he)), 0);
        }
    }

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
    av_store(page, PMD_META, newRV_inc((SV *)meta));
    pmd_page_dates(aTHX_ page, meta);
    body = pmd_shell(aTHX_ cap, "page", *av_fetch(page, PMD_TITLE, 0), nav,
                     html, toc_html, *av_fetch(page, PMD_URL, 0), page);
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
    STRLEN ll, i;
    const char *lp = SvPV_const(location, ll);
    /* A header value is \r-delimited, so one control byte in here is a
     * response split. Callers are supposed to hand us a location built from
     * the mount prefix and a page key, never from the request; stopping at
     * the first control byte is the belt to that braces. */
    for (i = 0; i < ll && (unsigned char)lp[i] >= 0x20 && lp[i] != 0x7f; i++)
        ;
    av_push(headers, newSVpvs("Location"));
    av_push(headers, newSVpvn(lp, i));
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
                    STRLEN take = pmd_cut(p, pl, 180);
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
                             "search_path", "/search"), 0)), NULL);
}

/* ---- the listing ----------------------------------------------------------
 * $app->markdown_pages($prefix): the built pages, in the mount's order, as
 * fresh Perl data, so a landing page, an index or a feed can be made from
 * the same table the mount serves. Drafts are not in it, since the walk
 * never kept them. Every value is a copy, decoded to characters: nothing a
 * caller does to the list reaches a frozen page. */

/* A page's summary: front-matter `description`, else its plain text with the
 * leading title dropped, whitespace collapsed, cut to 200 bytes on a UTF-8
 * boundary with "..." when anything was cut. */
static SV *pmd_summary(pTHX_ AV *page, HV *meta) {
    SV *v, *flat, *out;
    SV **pp = av_fetch(page, PMD_PLAIN, 0);
    SV *title = *av_fetch(page, PMD_TITLE, 0);
    STRLEN fl, tl, take;
    const char *f, *t;
    if (meta && (v = pmd_opt(aTHX_ meta, "description")) && SvCUR(v))
        return pmd_chars(aTHX_ newSVsv(v));
    flat = sv_2mortal(newSVpvs(""));
    if (pp && *pp && SvOK(*pp)) {
        STRLEN pl;
        const char *p = SvPV_const(*pp, pl);
        pmd_collapsed(aTHX_ flat, p, pl);
    }
    f = SvPV_const(flat, fl);
    t = SvPV_const(title, tl);
    if (tl && fl >= tl && memEQ(f, t, tl) && (fl == tl || f[tl] == ' ')) {
        f += tl; fl -= tl;
        while (fl && *f == ' ') { f++; fl--; }
    }
    take = pmd_cut(f, fl, 200);
    out = newSVpvn(f, take);
    if (take < fl) sv_catpvs(out, "...");
    return pmd_chars(aTHX_ out);
}

static AV *pmd_pages_av(pTHX_ AV *cap) {
    HV *pages  = (HV *)SvRV(*av_fetch(cap, PMDC_PAGES, 0));
    AV *order  = (AV *)SvRV(*av_fetch(cap, PMDC_ORDER, 0));
    SV *prefix = *av_fetch(cap, PMDC_PREFIX, 0);
    AV *out = newAV();
    SSize_t i, n = av_len(order) + 1;
    for (i = 0; i < n; i++) {
        SV **u = av_fetch(order, i, 0);
        HE *he;
        AV *page;
        HV *rec, *mcopy = newHV(), *meta = NULL;
        SV **mp, **dp, **up, *url, *path;
        if (!u || !*u) { SvREFCNT_dec((SV *)mcopy); continue; }
        he = hv_fetch_ent(pages, *u, 0, 0);
        if (!he || !HeVAL(he) || !SvROK(HeVAL(he))) {
            SvREFCNT_dec((SV *)mcopy);
            continue;
        }
        page = (AV *)SvRV(HeVAL(he));
        rec = newHV();

        mp = av_fetch(page, PMD_META, 0);
        if (mp && *mp && SvROK(*mp)) {
            HE *me;
            meta = (HV *)SvRV(*mp);
            hv_iterinit(meta);
            while ((me = hv_iternext(meta)))
                (void)hv_store_ent(mcopy, hv_iterkeysv(me),
                                   pmd_chars(aTHX_ newSVsv(HeVAL(me))), 0);
        }

        url = newSVsv(prefix);
        sv_catsv(url, *u);
        if (!SvCUR(url)) sv_catpvs(url, "/");
        path = SvCUR(*u) ? newSVsv(*u) : newSVpvs("/");

        (void)hv_stores(rec, "url",   pmd_chars(aTHX_ url));
        (void)hv_stores(rec, "path",  pmd_chars(aTHX_ path));
        (void)hv_stores(rec, "title",
            pmd_chars(aTHX_ newSVsv(*av_fetch(page, PMD_TITLE, 0))));
        dp = av_fetch(page, PMD_DATE, 0);
        up = av_fetch(page, PMD_UPDATED, 0);
        (void)hv_stores(rec, "date",
            (dp && *dp && SvOK(*dp)) ? newSViv(SvIV(*dp)) : newSV(0));
        (void)hv_stores(rec, "updated",
            (up && *up && SvOK(*up)) ? newSViv(SvIV(*up)) : newSV(0));
        (void)hv_stores(rec, "summary", pmd_summary(aTHX_ page, meta));
        (void)hv_stores(rec, "meta", newRV_noinc((SV *)mcopy));
        av_push(out, newRV_noinc((SV *)rec));
    }
    return out;
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
     * becoming a second address for the same document.
     *
     * The target has to be a page we actually hold before we will name it in
     * a Location header. PATH_INFO arrives percent-decoded, so reflecting it
     * means echoing bytes the client chose: "//evil.example/" would come back
     * as a protocol-relative 301 off the site, and a decoded CR/LF would end
     * the header and split the response. Looking the stripped target up in
     * the page table first means the only thing we can ever echo is one of
     * our own keys. A path that is not a page falls through to the 404 it was
     * always going to get. */
    if ((plen > 1 && path[plen - 1] == '/') ||
        (plen > 3 && memEQ(path + plen - 3, ".md", 3))) {
        STRLEN keep = path[plen - 1] == '/' ? plen - 1 : plen - 3;
        SV *ckey = sv_2mortal(newSVpvn(path, keep));
        if (hv_exists_ent(pages, ckey, 0)) {
            SV *loc = sv_2mortal(newSVsv(*av_fetch(cap, PMDC_PREFIX, 0)));
            sv_catsv(loc, ckey);
            ST(0) = sv_2mortal(pmd_redirect(aTHX_ loc));
            XSRETURN(1);
        }
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
     * the static mount, because it is literally the same function.
     *
     * Never a source. Anything that reaches here ending in .md is a document
     * the page table chose not to publish under that name - a draft, or an
     * index whose page lives at the directory's URL - and serving the file
     * would publish it anyway, front matter and all. The suffix is compared
     * without case because some filesystems open draft.MD as draft.md. And
     * never a dotfile, which the walk skipped for the same reason. */
    if (!ps_path_unsafe(path, plen) && !ps_path_dotted(path, plen, 0)
        && !(plen >= 3 && path[plen - 3] == '.'
             && toLOWER((U8)path[plen - 2]) == 'm'
             && toLOWER((U8)path[plen - 1]) == 'd')) {
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

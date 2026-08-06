#include "stencil.h"

#include <stdlib.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include <time.h>

UV stencil_stat_compiles   = 0;
UV stencil_stat_engines    = 0;
UV stencil_stat_cache_hits = 0;
UV stencil_stat_stats      = 0;

#define STENCIL_PATH_MAX 4096
#define STENCIL_N_BUCKETS 128u   /* fixed; chains handle the rest */

static const char *ent_name(const stencil_cache_ent *ent)
{
    return ent->abs_path ? ent->abs_path : "<string>";
}

static int looks_like_source(const char *p, STRLEN len);

/* Pretty preprocessing: drop whitespace-only lines (the artifacts of
 * block-tag indentation in templates) so the reformatter starts from
 * dense markup. */
static SV *pretty_strip_blank_lines(pTHX_ SV *html)
{
    STRLEN      len;
    const char *p   = SvPV(html, len);
    const char *end = p + len;
    SV         *out = newSV(len ? len : 1);
    char       *w;
    SvPOK_only(out);
    w = SvPVX(out);
    while (p < end) {
        const char *eol  = (const char *)memchr(p, '\n',
                                                (size_t)(end - p));
        const char *stop = eol ? eol : end;
        const char *q    = p;
        while (q < stop && (*q == ' ' || *q == '\t' || *q == '\r'))
            q++;
        if (q != stop) {   /* line has content */
            memcpy(w, p, (size_t)(stop - p));
            w += stop - p;
            if (eol)
                *w++ = '\n';
        }
        p = eol ? eol + 1 : end;
    }
    SvCUR_set(out, (STRLEN)(w - SvPVX(out)));
    SvPVX(out)[SvCUR(out)] = '\0';
    if (SvUTF8(html))
        SvUTF8_on(out);
    return out;
}

/* pretty => 1: hand the rendered HTML to Eshu->indent_html. Eshu is an
 * optional dependency, loaded lazily on first use; requesting pretty
 * without it is an error, not having it and never asking costs
 * nothing. Returns a fresh SV or NULL with *err set. */
static SV *eshu_prettify(pTHX_ SV *html, SV **err)
{
    static int eshu_state = 0;   /* 0 unknown, 1 ok, -1 unavailable */
    SV *ret = NULL;

    if (eshu_state == 0) {
        SV *ok = eval_pv("require Eshu; 1", FALSE);
        eshu_state = (ok && SvTRUE(ok)) ? 1 : -1;
    }
    if (eshu_state < 0) {
        if (err)
            *err = sv_2mortal(newSVpvs(
                "Template::Stencil: pretty => 1 requires the Eshu "
                "module"));
        return NULL;
    }
    {
        dSP;
        int count;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        EXTEND(SP, 2);
        mPUSHp("Eshu", 4);
        PUSHs(html);
        PUTBACK;
        count = call_method("indent_html", G_SCALAR | G_EVAL);
        SPAGAIN;
        if (SvTRUE(ERRSV)) {
            if (count)
                (void)POPs;
            PUTBACK;
            FREETMPS;
            LEAVE;
            if (err)
                *err = sv_2mortal(newSVpvf(
                    "Template::Stencil: Eshu->indent_html died: %s",
                    SvPV_nolen(ERRSV)));
            return NULL;
        }
        ret = count ? newSVsv(POPs) : newSVpvs("");
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
    return ret;
}

/* ---- path safety and resolution -------------------------------------- */

/* Templates never escape template_dir: no absolute paths, no '..'
 * segments anywhere. */
static int name_unsafe(const char *n, size_t len)
{
    size_t i = 0;
    if (!len || n[0] == '/')
        return 1;
    while (i < len) {
        size_t j = i;
        while (j < len && n[j] != '/')
            j++;
        if (j - i == 2 && n[i] == '.' && n[i + 1] == '.')
            return 1;
        i = j + 1;
    }
    return 0;
}

static int final_seg_has_dot(const char *n, size_t len)
{
    size_t i = len;
    while (i > 0 && n[i - 1] != '/') {
        if (n[i - 1] == '.')
            return 1;
        i--;
    }
    return 0;
}

static int try_stat(const char *path, struct stat *st)
{
    stencil_stat_stats++;
    return stat(path, st) == 0 && S_ISREG(st->st_mode);
}

/* Try template_dir/name[.tmpl], then cwd-relative name[.tmpl] (the
 * draft test renders 't/template/loops' with template_dir already set
 * to t/template). Returns 1 with out+st filled. */
static int resolve_file(const stencil_engine *e, const char *name,
                        size_t nlen, char *out, size_t outsz,
                        struct stat *st)
{
    int has_dot = final_seg_has_dot(name, nlen);
    if (name_unsafe(name, nlen))
        return 0;
    if (e->template_dir) {
        snprintf(out, outsz, "%s/%.*s", e->template_dir, (int)nlen, name);
        if (try_stat(out, st))
            return 1;
        if (!has_dot) {
            snprintf(out, outsz, "%s/%.*s.tmpl", e->template_dir,
                     (int)nlen, name);
            if (try_stat(out, st))
                return 1;
        }
    }
    snprintf(out, outsz, "%.*s", (int)nlen, name);
    if (try_stat(out, st))
        return 1;
    if (!has_dot) {
        snprintf(out, outsz, "%.*s.tmpl", (int)nlen, name);
        if (try_stat(out, st))
            return 1;
    }
    return 0;
}

/* Read a file: the (mtime,size) snapshot is taken before the read so a
 * mid-read write is caught by the next revalidation. */
static char *slurp(pTHX_ const char *path, STRLEN *lenp, time_t *mtime,
                   off_t *fsize, SV **err)
{
    struct stat st;
    char       *buf = NULL;
    ssize_t     got;
    size_t      have = 0;
    int         fd = open(path, O_RDONLY);
    if (fd < 0 || fstat(fd, &st) != 0 || !S_ISREG(st.st_mode)) {
        if (fd >= 0)
            close(fd);
        if (err)
            *err = sv_2mortal(newSVpvf(
                "Template::Stencil: cannot read template '%s'", path));
        return NULL;
    }
    *mtime = st.st_mtime;
    *fsize = st.st_size;
    buf = (char *)malloc((size_t)st.st_size + 1);
    if (!buf) {
        close(fd);
        if (err)
            *err = sv_2mortal(newSVpvs("Template::Stencil: out of memory"));
        return NULL;
    }
    while (have < (size_t)st.st_size) {
        got = read(fd, buf + have, (size_t)st.st_size - have);
        if (got <= 0)
            break;
        have += (size_t)got;
    }
    close(fd);
    buf[have] = '\0';
    *lenp = (STRLEN)have;
    return buf;
}

/* ---- cache table ------------------------------------------------------ */

static stencil_cache_ent **bucket_for(stencil_engine *e, uint64_t h)
{
    return &e->buckets[(uint32_t)h & (e->n_buckets - 1)];
}

static void lru_unlink(stencil_engine *e, stencil_cache_ent *ent)
{
    if (ent->lru_prev)
        ent->lru_prev->lru_next = ent->lru_next;
    else if (e->lru_head == ent)
        e->lru_head = ent->lru_next;
    if (ent->lru_next)
        ent->lru_next->lru_prev = ent->lru_prev;
    else if (e->lru_tail == ent)
        e->lru_tail = ent->lru_prev;
    ent->lru_next = ent->lru_prev = NULL;
}

static void lru_push_front(stencil_engine *e, stencil_cache_ent *ent)
{
    ent->lru_prev = NULL;
    ent->lru_next = e->lru_head;
    if (e->lru_head)
        e->lru_head->lru_prev = ent;
    e->lru_head = ent;
    if (!e->lru_tail)
        e->lru_tail = ent;
}

static void ent_free(pTHX_ stencil_cache_ent *ent)
{
    free(ent->abs_path);
    free(ent->src);
    if (ent->incs)
        Safefree(ent->incs);
    stencil_program_free(ent->prog);
    free(ent);
}

static void bucket_unlink(stencil_engine *e, stencil_cache_ent *ent,
                          uint64_t h)
{
    stencil_cache_ent **pp = bucket_for(e, h);
    while (*pp && *pp != ent)
        pp = &(*pp)->next;
    if (*pp)
        *pp = ent->next;
}

static void engine_cache_clear(pTHX_ stencil_engine *e)
{
    uint32_t i;
    for (i = 0; i < e->n_buckets; i++) {
        stencil_cache_ent *ent = e->buckets[i];
        while (ent) {
            stencil_cache_ent *next = ent->next;
            ent_free(aTHX_ ent);
            ent = next;
        }
        e->buckets[i] = NULL;
    }
    e->lru_head = e->lru_tail = NULL;
    e->n_ents = e->n_string = 0;
    e->generation++;
}

/* ---- compile + link --------------------------------------------------- */

static stencil_cache_ent *get_file_ent(pTHX_ stencil_engine *e,
                                       const char *name, size_t nlen,
                                       int *notfound, SV **err);

static int link_ent(pTHX_ stencil_engine *e, stencil_cache_ent *ent,
                    SV **err)
{
    stencil_program    *prog = ent->prog;
    const stencil_cinc *incs = stencil_prog_incs(prog);
    const char         *pool = stencil_prog_pool(prog);
    uint32_t            n    = prog->n_incs, i;

    ent->linked = 0;
    if (ent->incs) {
        Safefree(ent->incs);
        ent->incs = NULL;
    }
    if (!n) {
        ent->linked = 1;
        return 1;
    }
    Newxz(ent->incs, n, stencil_cache_ent *);
    ent->linking = 1;
    for (i = 0; i < n; i++) {
        int notfound = 0;
        stencil_cache_ent *child =
            get_file_ent(aTHX_ e, pool + incs[i].name_off,
                         incs[i].name_len, &notfound, err);
        if (!child) {
            /* resolve failures get the include-site context; deeper
             * errors (cycles, compile errors) pass through untouched */
            if (notfound && err)
                *err = sv_2mortal(newSVpvf(
                    "Template::Stencil: %s:%u:%u: cannot find include "
                    "'%.*s'", ent_name(ent), (unsigned)incs[i].line,
                    (unsigned)incs[i].col, (int)incs[i].name_len,
                    pool + incs[i].name_off));
            ent->linking = 0;
            return 0;
        }
        if (child->linking) {
            if (err)
                *err = sv_2mortal(newSVpvf(
                    "Template::Stencil: %s:%u:%u: include cycle: "
                    "%s -> %s", ent_name(ent), (unsigned)incs[i].line,
                    (unsigned)incs[i].col, ent_name(ent),
                    ent_name(child)));
            ent->linking = 0;
            return 0;
        }
        ent->incs[i] = child;
    }
    ent->linking = 0;
    ent->linked  = 1;
    return 1;
}

/* A cached entry whose earlier link failed (cycle, missing include)
 * retries on the next use - it may have been fixed on disk. Never
 * relink mid-DFS: the caller's cycle check handles that. */
static int ent_ready(pTHX_ stencil_engine *e, stencil_cache_ent *ent,
                     SV **err)
{
    if (ent->linking || ent->linked)
        return 1;
    return link_ent(aTHX_ e, ent, err);
}

/* User (non-builtin) filter names must be registered on the engine;
 * unknown names are compile-time errors listing what is registered. */
static int validate_filters(pTHX_ const stencil_engine *e,
                            const stencil_program *prog,
                            const char *name, SV **err)
{
    const stencil_cfilt *ft   = stencil_prog_filts(prog);
    const char          *pool = stencil_prog_pool(prog);
    uint32_t             i;
    for (i = 0; i < prog->n_filts; i++) {
        SV **cvp;
        if (ft[i].builtin_id >= 0)
            continue;
        cvp = e->filters
            ? hv_fetch(e->filters, pool + ft[i].name_off,
                       (I32)ft[i].name_len, 0)
            : NULL;
        if (cvp && SvROK(*cvp) && SvTYPE(SvRV(*cvp)) == SVt_PVCV)
            continue;
        if (err) {
            SV *msg = newSVpvf(
                "Template::Stencil: %s: unknown filter '%.*s'"
                " (registered:", name, (int)ft[i].name_len,
                pool + ft[i].name_off);
            if (e->filters && HvKEYS(e->filters)) {
                HE *he;
                int first = 1;
                hv_iterinit(e->filters);
                while ((he = hv_iternext(e->filters))) {
                    STRLEN klen;
                    const char *k = HePV(he, klen);
                    sv_catpvf(msg, "%s %.*s", first ? "" : ",",
                              (int)klen, k);
                    first = 0;
                }
            } else {
                sv_catpvs(msg, " none");
            }
            sv_catpvs(msg, ")");
            *err = sv_2mortal(msg);
        }
        return 0;
    }
    return 1;
}

static stencil_program *compile_source(pTHX_ stencil_engine *e,
                                       const char *src, STRLEN len,
                                       const char *name, uint32_t flags,
                                       SV **err)
{
    stencil_program *prog;
    stencil_stat_compiles++;
    prog = stencil_compile(aTHX_ src, len, name, flags, err);
    if (prog && !validate_filters(aTHX_ e, prog, name, err)) {
        stencil_program_free(prog);
        return NULL;
    }
    return prog;
}

static stencil_cache_ent *get_file_ent(pTHX_ stencil_engine *e,
                                       const char *name, size_t nlen,
                                       int *notfound, SV **err)
{
    char               path[STENCIL_PATH_MAX];
    struct stat        st;
    uint64_t           h;
    stencil_cache_ent *ent;
    char              *src;
    STRLEN             slen;
    time_t             mtime;
    off_t              fsize;
    stencil_program   *prog;

    if (notfound)
        *notfound = 0;
    if (!resolve_file(e, name, nlen, path, sizeof path, &st)) {
        if (notfound)
            *notfound = 1;
        return NULL;
    }
    h = stencil_fnv1a(path, strlen(path));
    for (ent = *bucket_for(e, h); ent; ent = ent->next) {
        if (ent->abs_path && strcmp(ent->abs_path, path) == 0) {
            stencil_stat_cache_hits++;
            if (!ent_ready(aTHX_ e, ent, err))
                return NULL;
            return ent;
        }
    }

    src = slurp(aTHX_ path, &slen, &mtime, &fsize, err);
    if (!src)
        return NULL;
    prog = compile_source(aTHX_ e, src, slen, path, 0, err);
    free(src);
    if (!prog)
        return NULL;

    ent = (stencil_cache_ent *)calloc(1, sizeof *ent);
    if (!ent) {
        stencil_program_free(prog);
        if (err)
            *err = sv_2mortal(newSVpvs("Template::Stencil: out of memory"));
        return NULL;
    }
    ent->abs_path   = strdup(path);
    ent->path_len   = (uint32_t)strlen(path);
    ent->mtime      = mtime;
    ent->fsize      = fsize;
    ent->checked_at = time(NULL);
    ent->prog       = prog;
    ent->next       = *bucket_for(e, h);
    *bucket_for(e, h) = ent;
    e->n_ents++;
    e->generation++;

    if (!link_ent(aTHX_ e, ent, err))
        return NULL;   /* entry stays cached but unusable; error out */
    return ent;
}

/* Insert a string-keyed (or alias) entry and enforce the LRU bound. */
static stencil_cache_ent *string_ent_insert(pTHX_ stencil_engine *e,
                                            const char *src, STRLEN len,
                                            uint64_t h,
                                            stencil_program *prog,
                                            stencil_cache_ent *alias,
                                            SV **err)
{
    stencil_cache_ent *ent =
        (stencil_cache_ent *)calloc(1, sizeof *ent);
    if (!ent)
        goto oom;
    ent->src = (char *)malloc(len ? len : 1);
    if (!ent->src) {
        free(ent);
        goto oom;
    }
    memcpy(ent->src, src, len);
    ent->src_len  = len;
    ent->src_hash = h;
    ent->prog     = prog;
    ent->alias    = alias;
    ent->next     = *bucket_for(e, h);
    *bucket_for(e, h) = ent;
    e->n_ents++;
    e->n_string++;
    e->generation++;
    lru_push_front(e, ent);
    while (e->n_string > e->cache_size && e->lru_tail
           && e->lru_tail != ent) {
        stencil_cache_ent *victim = e->lru_tail;
        lru_unlink(e, victim);
        bucket_unlink(e, victim, victim->src_hash);
        ent_free(aTHX_ victim);
        e->n_string--;
        e->n_ents--;
        e->generation++;
    }
    return ent;
oom:
    stencil_program_free(prog);
    if (err)
        *err = sv_2mortal(newSVpvs("Template::Stencil: out of memory"));
    return NULL;
}

static stencil_cache_ent *get_string_ent(pTHX_ stencil_engine *e,
                                         const char *src, STRLEN len,
                                         uint32_t cflags, SV **err)
{
    uint64_t           h = stencil_fnv1a(src, len);
    stencil_cache_ent *ent;
    stencil_program   *prog;

    for (ent = *bucket_for(e, h); ent; ent = ent->next) {
        if (!ent->abs_path && ent->src_hash == h && ent->src_len == len
            && memcmp(ent->src, src, len) == 0) {
            stencil_stat_cache_hits++;
            lru_unlink(e, ent);
            lru_push_front(e, ent);
            if (!ent_ready(aTHX_ e, ent, err))
                return NULL;
            return ent;
        }
    }

    prog = compile_source(aTHX_ e, src, len, "<string>", cflags, err);
    if (!prog)
        return NULL;
    ent = string_ent_insert(aTHX_ e, src, len, h, prog, NULL, err);
    if (!ent)
        return NULL;
    if (!link_ent(aTHX_ e, ent, err))
        return NULL;
    return ent;
}

/* Name-keyed lookup of a file entry (wrapper fetch): an alias hit
 * costs zero syscalls; a miss resolves and caches the alias. */
static stencil_cache_ent *get_named_file_ent(pTHX_ stencil_engine *e,
                                             const char *name,
                                             size_t nlen, SV **err)
{
    uint64_t           h = stencil_fnv1a(name, nlen);
    stencil_cache_ent *ent, *file;

    for (ent = *bucket_for(e, h); ent; ent = ent->next) {
        if (!ent->abs_path && ent->src_hash == h && ent->src_len == nlen
            && memcmp(ent->src, name, nlen) == 0 && ent->alias) {
            stencil_stat_cache_hits++;
            lru_unlink(e, ent);
            lru_push_front(e, ent);
            if (!ent_ready(aTHX_ e, ent->alias, err))
                return NULL;
            return ent->alias;
        }
    }
    {
        int notfound = 0;
        file = get_file_ent(aTHX_ e, name, nlen, &notfound, err);
        if (!file) {
            if (notfound && err)
                *err = sv_2mortal(newSVpvf(
                    "Template::Stencil: cannot find template '%.*s'",
                    (int)nlen, name));
            return NULL;
        }
    }
    if (!string_ent_insert(aTHX_ e, name, nlen, h, NULL, file, err))
        return NULL;
    return file;
}

/* Page dispatch: one cache lookup on the raw template argument. A hit
 * on an alias entry reaches the file entry with zero syscalls (the
 * stat_ttl => -1 steady state); a miss decides string-vs-file per the
 * overview rule and caches the decision. */
static stencil_cache_ent *get_page_ent(pTHX_ stencil_engine *e,
                                       const char *p, STRLEN len,
                                       uint32_t cflags, SV **err)
{
    uint64_t           h = stencil_fnv1a(p, len);
    stencil_cache_ent *ent;

    for (ent = *bucket_for(e, h); ent; ent = ent->next) {
        if (!ent->abs_path && ent->src_hash == h && ent->src_len == len
            && memcmp(ent->src, p, len) == 0) {
            stencil_stat_cache_hits++;
            lru_unlink(e, ent);
            lru_push_front(e, ent);
            if (!ent_ready(aTHX_ e, ent->alias ? ent->alias : ent, err))
                return NULL;
            return ent->alias ? ent->alias : ent;
        }
    }

    if (!looks_like_source(p, len)) {
        char        path[STENCIL_PATH_MAX];
        struct stat st;
        if (resolve_file(e, p, len, path, sizeof path, &st)) {
            int notfound = 0;
            stencil_cache_ent *file =
                get_file_ent(aTHX_ e, p, len, &notfound, err);
            if (!file) {
                if (notfound && err) /* raced away; treat as error */
                    *err = sv_2mortal(newSVpvf(
                        "Template::Stencil: cannot find template "
                        "'%.*s'", (int)len, p));
                return NULL;
            }
            if (!string_ent_insert(aTHX_ e, p, len, h, NULL, file, err))
                return NULL;
            return file;
        }
    }
    return get_string_ent(aTHX_ e, p, len, cflags, err);
}

/* ---- revalidation and effective sizes --------------------------------- */

static int revalidate_ent(pTHX_ stencil_engine *e, stencil_cache_ent *ent,
                          SV **err)
{
    struct stat st;
    time_t      now;
    if (!ent->abs_path || e->stat_ttl < 0)
        return 1;
    now = time(NULL);
    if (e->stat_ttl > 0
        && (double)(now - ent->checked_at) <= e->stat_ttl)
        return 1;
    ent->checked_at = now;
    stencil_stat_stats++;
    if (stat(ent->abs_path, &st) != 0) {
        if (err)
            *err = sv_2mortal(newSVpvf(
                "Template::Stencil: template '%s' disappeared",
                ent->abs_path));
        return 0;
    }
    if (st.st_mtime == ent->mtime && st.st_size == ent->fsize)
        return 1;
    {
        char            *src;
        STRLEN           slen;
        time_t           mtime;
        off_t            fsize;
        stencil_program *prog;
        src = slurp(aTHX_ ent->abs_path, &slen, &mtime, &fsize, err);
        if (!src)
            return 0;
        prog = compile_source(aTHX_ e, src, slen, ent->abs_path, 0, err);
        free(src);
        if (!prog)
            return 0;
        stencil_program_free(ent->prog);
        ent->prog  = prog;
        ent->mtime = mtime;
        ent->fsize = fsize;
        e->generation++;
        return link_ent(aTHX_ e, ent, err);
    }
}

/* Revalidate every node of an include graph once per render entry. The
 * visit serial keeps shared includes from being stat'd twice. */
static int revalidate_graph(pTHX_ stencil_engine *e,
                            stencil_cache_ent *ent, uint32_t visit,
                            SV **err)
{
    uint32_t i;
    if (ent->seen == visit)
        return 1;
    ent->seen = visit;
    if (!revalidate_ent(aTHX_ e, ent, err))
        return 0;
    for (i = 0; i < ent->prog->n_incs; i++)
        if (!revalidate_graph(aTHX_ e, ent->incs[i], visit, err))
            return 0;
    return 1;
}

/* Conservative render-state sizes across the include graph (sum along
 * the worst nesting), memoised per generation. */
static void ent_eff(stencil_engine *e, stencil_cache_ent *ent)
{
    uint32_t s, f, b, i;
    uint32_t cs = 0, cf = 0, cb = 0;
    if (ent->eff_gen == e->generation)
        return;
    ent->eff_gen = e->generation;
    s = ent->prog->max_stack;
    f = ent->prog->max_frames;
    b = ent->prog->max_binds;
    for (i = 0; i < ent->prog->n_incs; i++) {
        stencil_cache_ent *ch = ent->incs[i];
        ent_eff(e, ch);
        if (ch->eff_stack > cs)  cs = ch->eff_stack;
        if (ch->eff_frames > cf) cf = ch->eff_frames;
        if (ch->eff_binds > cb)  cb = ch->eff_binds;
    }
    ent->eff_stack  = s + cs;
    ent->eff_frames = f + cf;
    ent->eff_binds  = b + cb;
}

/* ---- engine lifecycle ------------------------------------------------- */

stencil_engine *stencil_engine_new(pTHX_ const char *template_dir,
                                   const char *wrapper, uint32_t flags,
                                   double stat_ttl, uint32_t cache_size,
                                   HV *filters)
{
    stencil_engine *e = (stencil_engine *)calloc(1, sizeof *e);
    if (!e)
        return NULL;
    if (template_dir && *template_dir) {
        size_t len = strlen(template_dir);
        while (len > 1 && template_dir[len - 1] == '/')
            len--;
        e->template_dir = (char *)malloc(len + 1);
        memcpy(e->template_dir, template_dir, len);
        e->template_dir[len]  = '\0';
        e->template_dir_len   = len;
    }
    if (wrapper && *wrapper)
        e->wrapper = strdup(wrapper);
    e->flags      = flags;
    e->stat_ttl   = stat_ttl;
    e->cache_size = cache_size ? cache_size : 256;
    e->n_buckets  = STENCIL_N_BUCKETS;
    e->buckets    = (stencil_cache_ent **)
        calloc(e->n_buckets, sizeof(stencil_cache_ent *));
    stencil_stat_engines++;
    e->generation = 1;
    if (filters)
        e->filters = (HV *)SvREFCNT_inc((SV *)filters);
    return e;
}

void stencil_engine_free(pTHX_ stencil_engine *e)
{
    if (!e)
        return;
    engine_cache_clear(aTHX_ e);
    free(e->buckets);
    free(e->template_dir);
    free(e->wrapper);
    /* during global destruction perl reclaims the filters HV itself */
    if (e->filters && !PL_dirty)
        SvREFCNT_dec((SV *)e->filters);
    free(e);
    stencil_stat_engines--;
}

/* ---- render entry ------------------------------------------------------ */

static int looks_like_source(const char *p, STRLEN len)
{
    const char *q, *end;
    if (memchr(p, '\n', len))
        return 1;
    if (len >= 2) {
        end = p + len - 1;
        for (q = p; (q = (const char *)memchr(q, '{',
                          (size_t)(end - q))) != NULL; q++)
            if (q[1] == '%')
                return 1;
    }
    return 0;
}

SV *stencil_engine_render(pTHX_ stencil_engine *e, SV *tmpl, HV *data,
                          SV *opts, SV **err)
{
    STRLEN             len;
    const char        *p = SvPV_const(tmpl, len);
    stencil_cache_ent *page = NULL, *wrap = NULL;
    const char        *wrap_name = e->wrapper;
    SV                *out;
    uint32_t           eff_s, eff_f, eff_b;
    uint32_t           rf = e->flags & (STENCIL_RF_STRICT
                                        | STENCIL_RF_NO_SORT_KEYS
                                        | STENCIL_RF_NO_ESCAPE
                                        | STENCIL_RF_CHARS
                                        | STENCIL_RF_PRETTY);

    /* the engine owns encoding: a latin-1-repped template string is
     * upgraded so compiled literals are always UTF-8 bytes */
    if (!SvUTF8(tmpl)) {
        STRLEN i;
        for (i = 0; i < len; i++) {
            if ((unsigned char)p[i] & 0x80) {
                tmpl = sv_mortalcopy(tmpl);
                sv_utf8_upgrade(tmpl);
                p = SvPV_const(tmpl, len);
                break;
            }
        }
    }

    if (opts && SvOK(opts)) {
        HV *oh;
        HE *he;
        if (!SvROK(opts) || SvTYPE(SvRV(opts)) != SVt_PVHV) {
            if (err)
                *err = sv_2mortal(newSVpvs(
                    "Template::Stencil: render options must be a hashref"));
            return NULL;
        }
        oh = (HV *)SvRV(opts);
        hv_iterinit(oh);
        while ((he = hv_iternext(oh))) {
            STRLEN      klen;
            const char *k = HePV(he, klen);
            SV         *v = HeVAL(he);
            if (klen == 7 && memEQ(k, "wrapper", 7)) {
                wrap_name = SvOK(v) ? SvPV_nolen(v) : NULL;
            } else if (klen == 6 && memEQ(k, "strict", 6)) {
                if (SvTRUE(v))
                    rf |= STENCIL_RF_STRICT;
                else
                    rf &= ~STENCIL_RF_STRICT;
            } else if (klen == 6 && memEQ(k, "pretty", 6)) {
                if (SvTRUE(v))
                    rf |= STENCIL_RF_PRETTY;
                else
                    rf &= ~STENCIL_RF_PRETTY;
            } else {
                if (err)
                    *err = sv_2mortal(newSVpvf(
                        "Template::Stencil: unknown render option "
                        "'%.*s'", (int)klen, k));
                return NULL;
            }
        }
    }

    page = get_page_ent(aTHX_ e, p, len,
                        SvUTF8(tmpl) ? STENCIL_PROG_SRC_UTF8 : 0, err);
    if (!page)
        return NULL;

    if (wrap_name) {
        wrap = get_named_file_ent(aTHX_ e, wrap_name, strlen(wrap_name),
                                  err);
        if (!wrap)
            return NULL;
        if (!(wrap->prog->flags & STENCIL_PROG_IS_WRAPPER)) {
            if (err)
                *err = sv_2mortal(newSVpvf(
                    "Template::Stencil: wrapper '%s' has no "
                    "{%% content %%}", ent_name(wrap)));
            return NULL;
        }
    }

    {
        static uint32_t visit_serial = 0;
        uint32_t visit = ++visit_serial;
        if (!revalidate_graph(aTHX_ e, page, visit, err))
            return NULL;
        if (wrap && !revalidate_graph(aTHX_ e, wrap, visit, err))
            return NULL;
    }
    ent_eff(e, page);
    eff_s = page->eff_stack;
    eff_f = page->eff_frames;
    eff_b = page->eff_binds;
    if (wrap) {
        ent_eff(e, wrap);
        eff_s += wrap->eff_stack;
        eff_f += wrap->eff_frames;
        eff_b += wrap->eff_binds;
    }

    out = stencil_render_core(aTHX_
        page->prog, page->incs, ent_name(page),
        wrap ? wrap->prog : NULL, wrap ? wrap->incs : NULL,
        wrap ? ent_name(wrap) : NULL,
        eff_s, eff_f, eff_b, data, e->filters, rf, err);

    if (out && (rf & STENCIL_RF_PRETTY)) {
        SV *dense  = pretty_strip_blank_lines(aTHX_ out);
        SV *shaped = eshu_prettify(aTHX_ dense, err);
        SvREFCNT_dec(out);
        SvREFCNT_dec(dense);
        if (!shaped)
            out = NULL;
        else {
            if (!(rf & STENCIL_RF_CHARS))
                SvUTF8_off(shaped);
            out = shaped;
        }
    }

    if (e->flags & STENCIL_EF_NO_CACHE)
        engine_cache_clear(aTHX_ e);
    return out;
}

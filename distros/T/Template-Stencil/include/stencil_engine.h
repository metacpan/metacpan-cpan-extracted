#ifndef STENCIL_ENGINE_H
#define STENCIL_ENGINE_H

/* Engine: template_dir resolution, compiled-template cache with mtime
 * revalidation, include linking, wrapper composition. One engine per
 * interpreter/worker - no locking anywhere by design. */

/* engine-level flag bits share the render-flags word */
#define STENCIL_EF_NO_CACHE 0x4u

typedef struct stencil_cache_ent {
    char            *abs_path;   /* malloc'd; NULL for string entries */
    uint32_t         path_len;
    char            *src;        /* string entries keep source bytes */
    STRLEN           src_len;
    uint64_t         src_hash;   /* FNV-1a of source (string entries) */
    time_t           mtime;
    off_t            fsize;
    time_t           checked_at; /* last stat time */
    stencil_program *prog;
    struct stencil_cache_ent **incs; /* n_incs link vector */
    struct stencil_cache_ent  *alias; /* name-keyed alias to a file
                                         entry: no stat on dispatch */
    /* effective render-state sizes across the include graph, memoised
     * against the engine generation */
    uint32_t         eff_stack, eff_frames, eff_binds;
    uint32_t         eff_gen;
    uint32_t         seen;       /* revalidation visit serial */
    int              linking;    /* DFS mark for cycle detection */
    int              linked;     /* link vector valid; retry when 0 */
    struct stencil_cache_ent *next;               /* bucket chain */
    struct stencil_cache_ent *lru_next, *lru_prev; /* string LRU */
} stencil_cache_ent;

typedef struct stencil_engine {
    char     *template_dir;
    size_t    template_dir_len;
    char     *wrapper;           /* default wrapper name or NULL */
    uint32_t  flags;             /* STENCIL_RF_* | STENCIL_EF_* */
    double    stat_ttl;          /* 1 default; 0 always stat; <0 never */
    uint32_t  cache_size;        /* string-entry LRU cap */
    uint32_t  n_string;
    uint32_t  generation;        /* bumped on any recompile */
    stencil_cache_ent **buckets;
    uint32_t  n_buckets;
    uint32_t  n_ents;
    stencil_cache_ent *lru_head, *lru_tail;
    HV       *filters;           /* user coderefs (phase 06/07) */
} stencil_engine;

/* filters may be NULL; when given it is an HV of name => coderef and
 * the engine takes a refcount. */
stencil_engine *stencil_engine_new(pTHX_ const char *template_dir,
                                   const char *wrapper, uint32_t flags,
                                   double stat_ttl, uint32_t cache_size,
                                   HV *filters);
void stencil_engine_free(pTHX_ stencil_engine *e);

/* Render a template (source string or file path - dispatch per the
 * overview rule) with the engine's wrapper unless overridden in opts
 * (hashref: wrapper => name | undef). Returns the buffer SV or NULL
 * with *err set mortal. */
SV *stencil_engine_render(pTHX_ stencil_engine *e, SV *tmpl, HV *data,
                          SV *opts, SV **err);

/* Observability counters (cumulative; engines is live count). */
extern UV stencil_stat_compiles;
extern UV stencil_stat_cache_hits;
extern UV stencil_stat_stats;
extern UV stencil_stat_engines;

#endif /* STENCIL_ENGINE_H */

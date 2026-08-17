#ifndef STENCIL_COMPILE_H
#define STENCIL_COMPILE_H

/* Compiled program: one arena block holding bytecode, literal/name
 * pool, path table, segment array, include table, filter table and the
 * line side table. Everything below the arena is offsets and counts;
 * pointers are materialised against arena.base only at render time. */

/* Interned identifier: shared by path segments and by for/set bind
 * names, so scope lookups compare a u32 name_id instead of bytes. */
typedef struct stencil_cname {
    uint32_t off;    /* bytes in the pool */
    uint32_t len;
    uint32_t hash;   /* PERL_HASH, computed at compile time */
} stencil_cname;

typedef struct stencil_seg {
    uint32_t name_id;   /* valid when !is_index */
    uint8_t  is_index;
    SSize_t  index;     /* valid when is_index */
} stencil_seg;

typedef struct stencil_cpath {
    uint16_t n_segs;
    uint16_t loop_rooted;   /* first segment is `loop` */
    uint32_t seg_idx;       /* first seg in the global seg array */
    uint32_t full_off;      /* normalised full path string (diagnostics) */
    uint32_t full_len;
} stencil_cpath;

typedef struct stencil_cinc {
    uint32_t name_off;  /* filename bytes in the pool */
    uint32_t name_len;
    uint32_t line, col; /* include site, for link-time errors */
} stencil_cinc;

/* Built-in filter ids, resolved at compile time; VM dispatch is a jump
 * on this id, never a name compare. */
enum {
    STENCIL_FILT_UPPER = 0,
    STENCIL_FILT_LOWER,
    STENCIL_FILT_TRIM,
    STENCIL_FILT_HTML,
    STENCIL_FILT_URI,
    STENCIL_FILT_DEFAULT,
    STENCIL_FILT_FMT,       /* sprintf, one conversion, validated at parse */
    STENCIL_FILT_USER = -1  /* engine-registered coderef, linked later */
};

typedef struct stencil_cfilt {
    uint32_t name_off, name_len;
    int32_t  builtin_id;    /* STENCIL_FILT_* or STENCIL_FILT_USER */
    uint8_t  has_arg;
    uint8_t  arg_is_num;
    double   num_arg;
    uint32_t str_off, str_len;
} stencil_cfilt;

/* Line side table entry: first op at or after code offset `off` came
 * from source line `line`. Binary-searched only on error paths. */
typedef struct stencil_cline {
    uint32_t off;
    uint32_t line;
} stencil_cline;

#define STENCIL_PROG_IS_WRAPPER 0x1u
#define STENCIL_PROG_SRC_UTF8   0x2u  /* template source SV was UTF-8 */

typedef struct stencil_program {
    stencil_arena arena;
    uint32_t code_off,  code_len;
    uint32_t pool_off,  pool_len;
    uint32_t names_off, n_names;
    uint32_t paths_off, n_paths;
    uint32_t segs_off,  n_segs;
    uint32_t incs_off,  n_incs;
    uint32_t filts_off, n_filts;
    uint32_t lines_off, n_lines;
    uint32_t max_stack;   /* value-stack high water, static */
    uint32_t max_frames;  /* for-loop nesting high water */
    uint32_t max_binds;   /* live set-bind high water */
    uint32_t flags;
    size_t   profiled_size;   /* phase 04 fills after first render */
    void    *jit;             /* reserved function-pointer slot */
} stencil_program;

#define stencil_prog_code(pr)  ((const uint8_t *)((pr)->arena.base + (pr)->code_off))
#define stencil_prog_pool(pr)  ((const char *)((pr)->arena.base + (pr)->pool_off))
#define stencil_prog_names(pr) ((const stencil_cname *)((pr)->arena.base + (pr)->names_off))
#define stencil_prog_paths(pr) ((const stencil_cpath *)((pr)->arena.base + (pr)->paths_off))
#define stencil_prog_segs(pr)  ((const stencil_seg *)((pr)->arena.base + (pr)->segs_off))
#define stencil_prog_incs(pr)  ((const stencil_cinc *)((pr)->arena.base + (pr)->incs_off))
#define stencil_prog_filts(pr) ((const stencil_cfilt *)((pr)->arena.base + (pr)->filts_off))
#define stencil_prog_lines(pr) ((const stencil_cline *)((pr)->arena.base + (pr)->lines_off))

/* Compile src[0..len) under the diagnostic name `name`. On success
 * returns the program; on failure returns NULL and sets *err to a
 * mortal SV holding "name:line:col: message". */
stencil_program *stencil_compile(pTHX_ const char *src, STRLEN len,
                                 const char *name, uint32_t flags,
                                 SV **err);
void stencil_program_free(stencil_program *prog);

/* Debug/test hook: decoded op stream + tables as a Perl hashref. */
SV *stencil_program_inspect(pTHX_ const stencil_program *prog);

#endif /* STENCIL_COMPILE_H */

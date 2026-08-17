#include "stencil.h"

#include <stdarg.h>

/* ====================================================================
 * Compiler
 *
 * During compile each region (bytecode, byte pool, tables) grows in
 * its own bump arena so offsets never move; finalise packs them all
 * into the program's single arena and frees the temporaries. All
 * compile-time allocation goes through stencil_arena / stencil_intern
 * - no stray mallocs.
 * ==================================================================== */

#define BLK_IF     1
#define BLK_UNLESS 2
#define BLK_FOR    3

#define STENCIL_MAX_DEPTH 64
#define STENCIL_MAX_SEGS  8
#define STENCIL_PATCH_END 0xFFFFFFFFu

typedef struct stencil_blk {
    uint8_t  kind;
    uint8_t  has_else;
    uint32_t line, col;        /* opener position for errors */
    uint32_t cond_patch;       /* pending TEST_JF/JT operand offset */
    uint32_t jump_chain;       /* end-jump patch sites, chained through
                                  the operand slots themselves */
    uint32_t body_start;       /* FOR: back-jump target */
    uint32_t for_end_patch;    /* FOR: end_target operand offset */
    int32_t  binds_at_entry;
} stencil_blk;

typedef struct stencil_compiler {
    const char *src, *p, *end;
    const char *name;            /* diagnostic template name */
    uint32_t    line;
    const char *line_start;

    stencil_arena  code, pool, names, paths, segs, incs, filts, lines;
    stencil_arena  pend;         /* pending literal run */
    stencil_intern lit_intern;   /* long literals + strings, into pool */

    uint32_t n_names, n_paths, n_segs, n_incs, n_filts, n_lines;

    stencil_blk blk[STENCIL_MAX_DEPTH];
    uint32_t    n_blk;

    int32_t cur_stack, max_stack;
    int32_t cur_frames, max_frames;
    int32_t cur_binds, max_binds;

    uint32_t flags;
    uint32_t last_line_rec;

#ifdef PERL_IMPLICIT_CONTEXT
    PerlInterpreter *perl;       /* for PERL_HASH's seed access */
#endif

    /* first error wins */
    int      failed;
    char     errbuf[192];
    uint32_t err_line, err_col;
} stencil_compiler;

/* Reserved words: first-position statement keywords plus 'in', which
 * cannot be a for/set binding name (is_keyword guards those). */
static const char *const kw_list[] = {
    "if", "unless", "elsif", "else", "end", "for", "set",
    "include", "raw", "content", "in", NULL
};

/* ---- error helpers ------------------------------------------------- */

static uint32_t ccol(const stencil_compiler *c, const char *at)
{
    return (uint32_t)(at - c->line_start) + 1;
}

static int cerror_at(stencil_compiler *c, uint32_t line, uint32_t col,
                     const char *fmt, ...)
{
    va_list ap;
    if (c->failed)
        return 0;
    c->failed   = 1;
    c->err_line = line;
    c->err_col  = col;
    va_start(ap, fmt);
    vsnprintf(c->errbuf, sizeof c->errbuf, fmt, ap);
    va_end(ap);
    return 0;
}

static int cerror(stencil_compiler *c, const char *at, const char *fmt, ...)
{
    va_list ap;
    if (c->failed)
        return 0;
    c->failed   = 1;
    c->err_line = c->line;
    c->err_col  = ccol(c, at);
    va_start(ap, fmt);
    vsnprintf(c->errbuf, sizeof c->errbuf, fmt, ap);
    va_end(ap);
    return 0;
}

static int coom(stencil_compiler *c)
{
    return cerror_at(c, c->line, 1, "out of memory");
}

/* ---- emit helpers --------------------------------------------------- */

static int emit_bytes(stencil_compiler *c, const void *p, size_t n)
{
    uint32_t off = stencil_arena_alloc(&c->code, n, 1);
    if (off == STENCIL_ARENA_NULL)
        return coom(c);
    memcpy(c->code.base + off, p, n);
    return 1;
}

static int emit_u8(stencil_compiler *c, uint8_t v)
{
    return emit_bytes(c, &v, 1);
}

static int emit_u32(stencil_compiler *c, uint32_t v)
{
    return emit_bytes(c, &v, 4);
}

static void patch_u32(stencil_compiler *c, uint32_t at, uint32_t v)
{
    memcpy(c->code.base + at, &v, 4);
}

static uint32_t read_code_u32(stencil_compiler *c, uint32_t at)
{
    uint32_t v;
    memcpy(&v, c->code.base + at, 4);
    return v;
}

static uint32_t code_pos(const stencil_compiler *c)
{
    return (uint32_t)c->code.used;
}

/* Record the source line for the op about to be emitted (delta table,
 * appended only when the line changes). */
static int record_line(stencil_compiler *c)
{
    stencil_cline *e;
    uint32_t off;
    if (c->line == c->last_line_rec)
        return 1;
    off = stencil_arena_alloc(&c->lines, sizeof(stencil_cline),
                              sizeof(uint32_t));
    if (off == STENCIL_ARENA_NULL)
        return coom(c);
    e = (stencil_cline *)(c->lines.base + off);
    e->off  = code_pos(c);
    e->line = c->line;
    c->n_lines++;
    c->last_line_rec = c->line;
    return 1;
}

static int emit_op(stencil_compiler *c, uint8_t op, int32_t stack_delta)
{
    if (!record_line(c) || !emit_u8(c, op))
        return 0;
    c->cur_stack += stack_delta;
    if (c->cur_stack > c->max_stack)
        c->max_stack = c->cur_stack;
    return 1;
}

/* Emit a jump-family op whose operand joins a patch chain threaded
 * through the operand slots themselves; returns via *chain. */
static int emit_jump_chained(stencil_compiler *c, uint8_t op,
                             int32_t stack_delta, uint32_t *chain)
{
    uint32_t site;
    if (!emit_op(c, op, stack_delta))
        return 0;
    site = code_pos(c);
    if (!emit_u32(c, *chain))
        return 0;
    *chain = site;
    return 1;
}

static void patch_chain(stencil_compiler *c, uint32_t chain,
                        uint32_t target)
{
    while (chain != STENCIL_PATCH_END) {
        uint32_t next = read_code_u32(c, chain);
        patch_u32(c, chain, target);
        chain = next;
    }
}

/* ---- pending-literal accumulation and flush ------------------------- */

static int lit_pend(stencil_compiler *c, const char *p, size_t n)
{
    uint32_t off;
    if (!n)
        return 1;
    off = stencil_arena_alloc(&c->pend, n, 1);
    if (off == STENCIL_ARENA_NULL)
        return coom(c);
    memcpy(c->pend.base + off, p, n);
    return 1;
}

static int lit_flush(stencil_compiler *c)
{
    size_t n = c->pend.used;
    if (!n)
        return 1;
    if (n <= 31) {
        if (!emit_op(c, SOP_LITERAL_SHORT, 0) ||
            !emit_u8(c, (uint8_t)n) ||
            !emit_bytes(c, c->pend.base, n))
            return 0;
    } else {
        uint32_t off = stencil_intern_get(&c->lit_intern, &c->pool,
                                          c->pend.base, (uint32_t)n);
        if (off == STENCIL_ARENA_NULL)
            return coom(c);
        if (!emit_op(c, SOP_LITERAL_LONG, 0) ||
            !emit_u32(c, off) || !emit_u32(c, (uint32_t)n))
            return 0;
    }
    c->pend.used = 0;
    return 1;
}

/* ---- source advance with line tracking ------------------------------- */

static void advance_lines(stencil_compiler *c, const char *from,
                          const char *to)
{
    const char *nl = from;
    for (;;) {
        nl = (const char *)memchr(nl, '\n', (size_t)(to - nl));
        if (!nl)
            break;
        c->line++;
        nl++;
        c->line_start = nl;
    }
}

/* ---- token helpers --------------------------------------------------- */

#define IS_WORD_START(ch) (isALPHA(ch) || (ch) == '_')
#define IS_WORD(ch)       (isALNUM(ch) || (ch) == '_')

static void skip_ws(stencil_compiler *c)
{
    while (c->p < c->end && isSPACE(*c->p)) {
        if (*c->p == '\n') {
            c->line++;
            c->line_start = c->p + 1;
        }
        c->p++;
    }
}

static size_t word_len(const char *p, const char *end)
{
    const char *q = p;
    if (q >= end || !IS_WORD_START(*q))
        return 0;
    q++;
    while (q < end && IS_WORD(*q))
        q++;
    return (size_t)(q - p);
}

static int word_is(const char *p, size_t n, const char *kw)
{
    return strlen(kw) == n && memcmp(p, kw, n) == 0;
}

static int is_keyword(const char *p, size_t n)
{
    int i;
    for (i = 0; kw_list[i]; i++)
        if (word_is(p, n, kw_list[i]))
            return 1;
    return 0;
}

static int expect_close(stencil_compiler *c)
{
    skip_ws(c);
    if (c->end - c->p >= 2 && c->p[0] == '%' && c->p[1] == '}') {
        c->p += 2;
        return 1;
    }
    return cerror(c, c->p, "expected '%%}'");
}

/* ---- name / path interning ------------------------------------------ */

static uint32_t name_intern(stencil_compiler *c, const char *p, uint32_t n)
{
    stencil_cname *tab = (stencil_cname *)c->names.base;
    uint32_t       i, off, hash, noff;
    stencil_cname *e;
#ifdef PERL_IMPLICIT_CONTEXT
    dTHXa(c->perl);
#endif
    for (i = 0; i < c->n_names; i++)
        if (tab[i].len == n
            && memcmp(c->pool.base + tab[i].off, p, n) == 0)
            return i;
    off = stencil_arena_alloc(&c->pool, n, 1);
    if (off == STENCIL_ARENA_NULL)
        return STENCIL_ARENA_NULL;
    memcpy(c->pool.base + off, p, n);
    PERL_HASH(hash, p, n);
    noff = stencil_arena_alloc(&c->names, sizeof(stencil_cname),
                               sizeof(uint32_t));
    if (noff == STENCIL_ARENA_NULL)
        return STENCIL_ARENA_NULL;
    e = (stencil_cname *)(c->names.base + noff);
    e->off  = off;
    e->len  = n;
    e->hash = hash;
    return c->n_names++;
}

/* Parse a dotted/indexed path at c->p; returns path_id or
 * STENCIL_ARENA_NULL after setting the error. */
static uint32_t path_parse(stencil_compiler *c)
{
    const char    *start = c->p;
    stencil_seg    segs[STENCIL_MAX_SEGS];
    uint32_t       n_segs = 0;
    uint32_t       i, seg_base, full_off, poff;
    size_t         full_len;
    stencil_cpath *tab, *e;

    for (;;) {
        if (n_segs >= STENCIL_MAX_SEGS) {
            cerror(c, c->p, "path has more than %d segments",
                   STENCIL_MAX_SEGS);
            return STENCIL_ARENA_NULL;
        }
        if (c->p < c->end && *c->p == '[') {
            const char *q  = c->p + 1;
            SSize_t     ix = 0;
            if (n_segs == 0) {
                cerror(c, c->p, "path cannot start with an index");
                return STENCIL_ARENA_NULL;
            }
            if (q >= c->end || !isDIGIT(*q)) {
                cerror(c, c->p, "expected digits in [index]");
                return STENCIL_ARENA_NULL;
            }
            while (q < c->end && isDIGIT(*q))
                ix = ix * 10 + (*q++ - '0');
            if (q >= c->end || *q != ']') {
                cerror(c, q, "expected ']'");
                return STENCIL_ARENA_NULL;
            }
            segs[n_segs].name_id  = 0;
            segs[n_segs].is_index = 1;
            segs[n_segs].index    = ix;
            n_segs++;
            c->p = q + 1;
        } else {
            size_t   wl = word_len(c->p, c->end);
            uint32_t id;
            if (!wl) {
                cerror(c, c->p, n_segs ? "expected name after '.'"
                                       : "expected a name");
                return STENCIL_ARENA_NULL;
            }
            id = name_intern(c, c->p, (uint32_t)wl);
            if (id == STENCIL_ARENA_NULL) {
                coom(c);
                return STENCIL_ARENA_NULL;
            }
            segs[n_segs].name_id  = id;
            segs[n_segs].is_index = 0;
            segs[n_segs].index    = 0;
            n_segs++;
            c->p += wl;
        }
        if (c->p < c->end && *c->p == '.') {
            c->p++;
            continue;
        }
        if (c->p < c->end && *c->p == '[')
            continue;
        break;
    }

    /* dedup by the normalised source slice */
    full_len = (size_t)(c->p - start);
    tab = (stencil_cpath *)c->paths.base;
    for (i = 0; i < c->n_paths; i++)
        if (tab[i].full_len == full_len
            && memcmp(c->pool.base + tab[i].full_off, start, full_len) == 0)
            return i;

    full_off = stencil_intern_get(&c->lit_intern, &c->pool, start,
                                  (uint32_t)full_len);
    if (full_off == STENCIL_ARENA_NULL) {
        coom(c);
        return STENCIL_ARENA_NULL;
    }
    seg_base = c->n_segs;
    for (i = 0; i < n_segs; i++) {
        uint32_t soff = stencil_arena_alloc(&c->segs, sizeof(stencil_seg),
                                            sizeof(SSize_t));
        if (soff == STENCIL_ARENA_NULL) {
            coom(c);
            return STENCIL_ARENA_NULL;
        }
        memcpy(c->segs.base + soff, &segs[i], sizeof(stencil_seg));
        c->n_segs++;
    }
    poff = stencil_arena_alloc(&c->paths, sizeof(stencil_cpath),
                               sizeof(uint32_t));
    if (poff == STENCIL_ARENA_NULL) {
        coom(c);
        return STENCIL_ARENA_NULL;
    }
    e = (stencil_cpath *)(c->paths.base + poff);
    {
        const stencil_cname *names = (const stencil_cname *)c->names.base;
        e->loop_rooted = !segs[0].is_index
            && names[segs[0].name_id].len == 4
            && memcmp(c->pool.base + names[segs[0].name_id].off,
                      "loop", 4) == 0;
    }
    e->n_segs   = (uint16_t)n_segs;
    e->seg_idx  = seg_base;
    e->full_off = full_off;
    e->full_len = (uint32_t)full_len;
    return c->n_paths++;
}

/* parse a path and emit its push */
static int parse_path_push(stencil_compiler *c)
{
    uint32_t pid = path_parse(c);
    if (pid == STENCIL_ARENA_NULL)
        return 0;
    return emit_op(c, SOP_PUSH_PATH, +1) && emit_u32(c, pid);
}

/* ====================================================================
 * Expression parser
 * precedence: or < and < not < comparison < primary
 * ==================================================================== */

static int parse_expr(stencil_compiler *c);

static int parse_primary(stencil_compiler *c)
{
    skip_ws(c);
    if (c->p >= c->end)
        return cerror(c, c->p, "expected an expression");

    if (*c->p == '(') {
        c->p++;
        if (!parse_expr(c))
            return 0;
        skip_ws(c);
        if (c->p >= c->end || *c->p != ')')
            return cerror(c, c->p, "expected ')'");
        c->p++;
        return 1;
    }

    if (*c->p == '\'' || *c->p == '"') {
        char        quote = *c->p;
        const char *q     = c->p + 1;
        int         esc   = 0;
        uint32_t    off, len;
        while (q < c->end && *q != quote) {
            if (*q == '\\' && q + 1 < c->end
                && (q[1] == quote || q[1] == '\\')) {
                esc = 1;
                q += 2;
            } else {
                if (*q == '\n') {
                    c->line++;
                    c->line_start = q + 1;
                }
                q++;
            }
        }
        if (q >= c->end)
            return cerror(c, c->p, "unterminated string literal");
        if (!esc) {
            len = (uint32_t)(q - (c->p + 1));
            off = len ? stencil_intern_get(&c->lit_intern, &c->pool,
                                           c->p + 1, len)
                      : 0;
        } else {
            /* copy with unescaping straight into the pool (no dedup) */
            const char *r = c->p + 1;
            char       *w;
            off = stencil_arena_alloc(&c->pool, (size_t)(q - r), 1);
            if (off == STENCIL_ARENA_NULL)
                return coom(c);
            w = c->pool.base + off;
            while (r < q) {
                if (*r == '\\' && (r[1] == quote || r[1] == '\\'))
                    r++;
                *w++ = *r++;
            }
            len = (uint32_t)(w - (c->pool.base + off));
            c->pool.used = (size_t)(w - c->pool.base);
        }
        if (off == STENCIL_ARENA_NULL)
            return coom(c);
        c->p = q + 1;
        return emit_op(c, SOP_PUSH_LIT_STR, +1)
            && emit_u32(c, off) && emit_u32(c, len);
    }

    if (isDIGIT(*c->p)
        || (*c->p == '-' && c->p + 1 < c->end && isDIGIT(c->p[1]))) {
        double val = 0.0, frac = 0.1;
        int    neg = 0;
        if (*c->p == '-') {
            neg = 1;
            c->p++;
        }
        while (c->p < c->end && isDIGIT(*c->p))
            val = val * 10.0 + (*c->p++ - '0');
        if (c->p < c->end && *c->p == '.') {
            if (c->p + 1 >= c->end || !isDIGIT(c->p[1]))
                return cerror(c, c->p, "expected digits after '.'");
            c->p++;
            while (c->p < c->end && isDIGIT(*c->p)) {
                val += (*c->p++ - '0') * frac;
                frac *= 0.1;
            }
        }
        if (neg)
            val = -val;
        return emit_op(c, SOP_PUSH_LIT_NUM, +1)
            && emit_bytes(c, &val, sizeof val);
    }

    {
        size_t wl = word_len(c->p, c->end);
        if (!wl)
            return cerror(c, c->p, "expected an expression");
        if (word_is(c->p, wl, "undef")) {
            c->p += wl;
            return emit_op(c, SOP_PUSH_UNDEF, +1);
        }
        if (word_is(c->p, wl, "defined")) {
            const char *kw = c->p;
            c->p += wl;
            skip_ws(c);
            if (c->p >= c->end || *c->p != '(')
                return cerror(c, kw, "defined needs (path)");
            c->p++;
            skip_ws(c);
            if (!parse_path_push(c))
                return 0;
            skip_ws(c);
            if (c->p >= c->end || *c->p != ')')
                return cerror(c, c->p, "expected ')'");
            c->p++;
            return emit_op(c, SOP_DEFINED, 0);
        }
        return parse_path_push(c);
    }
}

/* returns the comparison opcode at c->p (consuming it) or 0 */
static uint8_t scan_cmp_op(stencil_compiler *c)
{
    const char *p = c->p;
    size_t      left = (size_t)(c->end - p);
    size_t      wl;
    if (left >= 2) {
        if (p[0] == '=' && p[1] == '=') { c->p += 2; return SOP_EQ_NUM; }
        if (p[0] == '!' && p[1] == '=') { c->p += 2; return SOP_NE_NUM; }
        if (p[0] == '<' && p[1] == '=') { c->p += 2; return SOP_LE_NUM; }
        if (p[0] == '>' && p[1] == '=') { c->p += 2; return SOP_GE_NUM; }
    }
    if (left >= 1) {
        if (p[0] == '<') { c->p += 1; return SOP_LT_NUM; }
        if (p[0] == '>') { c->p += 1; return SOP_GT_NUM; }
    }
    wl = word_len(p, c->end);
    if (wl == 2) {
        if (word_is(p, 2, "eq")) { c->p += 2; return SOP_EQ_STR; }
        if (word_is(p, 2, "ne")) { c->p += 2; return SOP_NE_STR; }
        if (word_is(p, 2, "lt")) { c->p += 2; return SOP_LT_STR; }
        if (word_is(p, 2, "gt")) { c->p += 2; return SOP_GT_STR; }
        if (word_is(p, 2, "le")) { c->p += 2; return SOP_LE_STR; }
        if (word_is(p, 2, "ge")) { c->p += 2; return SOP_GE_STR; }
    }
    return 0;
}

static int parse_cmp(stencil_compiler *c)
{
    uint8_t op;
    if (!parse_primary(c))
        return 0;
    skip_ws(c);
    op = scan_cmp_op(c);
    if (!op)
        return 1;
    if (!parse_primary(c))
        return 0;
    return emit_op(c, op, -1);
}

static int parse_not(stencil_compiler *c)
{
    int negs = 0;
    for (;;) {
        skip_ws(c);
        if (c->p < c->end && *c->p == '!'
            && !(c->p + 1 < c->end && c->p[1] == '=')) {
            c->p++;
            negs++;
            continue;
        }
        {
            size_t wl = word_len(c->p, c->end);
            if (wl && word_is(c->p, wl, "not")) {
                c->p += wl;
                negs++;
                continue;
            }
        }
        break;
    }
    if (!parse_cmp(c))
        return 0;
    while (negs--)
        if (!emit_op(c, SOP_NOT, 0))
            return 0;
    return 1;
}

/* and-op at c->p? consume and return true */
static int scan_word_op(stencil_compiler *c, const char *sym,
                        const char *word)
{
    size_t wl;
    if ((size_t)(c->end - c->p) >= 2 && c->p[0] == sym[0]
        && c->p[1] == sym[1]) {
        c->p += 2;
        return 1;
    }
    wl = word_len(c->p, c->end);
    if (wl && word_is(c->p, wl, word)) {
        c->p += wl;
        return 1;
    }
    return 0;
}

static int parse_and(stencil_compiler *c)
{
    uint32_t chain = STENCIL_PATCH_END;
    if (!parse_not(c))
        return 0;
    for (;;) {
        skip_ws(c);
        if (!scan_word_op(c, "&&", "and"))
            break;
        if (!emit_jump_chained(c, SOP_JF_KEEP, 0, &chain) ||
            !emit_op(c, SOP_POP, -1) ||
            !parse_not(c))
            return 0;
    }
    patch_chain(c, chain, code_pos(c));
    return 1;
}

static int parse_or(stencil_compiler *c)
{
    uint32_t chain = STENCIL_PATCH_END;
    if (!parse_and(c))
        return 0;
    for (;;) {
        skip_ws(c);
        if (!scan_word_op(c, "||", "or"))
            break;
        if (!emit_jump_chained(c, SOP_JT_KEEP, 0, &chain) ||
            !emit_op(c, SOP_POP, -1) ||
            !parse_and(c))
            return 0;
    }
    patch_chain(c, chain, code_pos(c));
    return 1;
}

static int parse_expr(stencil_compiler *c)
{
    return parse_or(c);
}

/* ====================================================================
 * Filters
 * ==================================================================== */

static int32_t filter_builtin(const char *p, uint32_t n)
{
    if (word_is(p, n, "upper"))   return STENCIL_FILT_UPPER;
    if (word_is(p, n, "lower"))   return STENCIL_FILT_LOWER;
    if (word_is(p, n, "trim"))    return STENCIL_FILT_TRIM;
    if (word_is(p, n, "html"))    return STENCIL_FILT_HTML;
    if (word_is(p, n, "uri"))     return STENCIL_FILT_URI;
    if (word_is(p, n, "default")) return STENCIL_FILT_DEFAULT;
    if (word_is(p, n, "fmt"))     return STENCIL_FILT_FMT;
    return STENCIL_FILT_USER;
}

/* fmt's format string, checked here so the render can trust it blind:
 * literal text plus exactly one %-conversion of a known-safe shape.
 *
 *   %[-+ 0#]*[width][.precision]conv     conv in [diouxXeEfgGs]
 *
 * %% is a literal. No '*', no length modifiers, no %n; width and
 * precision are capped so the render-side output buffer cannot be
 * outgrown, and the whole format is capped so the rewritten format
 * (the render inserts perl's IVdf/UVxf length modifiers) fits its own
 * stack buffer. Returns NULL when valid, else the complaint. */
#define STENCIL_FMT_MAXLEN  48
#define STENCIL_FMT_MAXWID  256
static const char *fmt_check(const char *p, uint32_t n)
{
    const char *end = p + n;
    int convs = 0;
    if (n > STENCIL_FMT_MAXLEN)
        return "fmt: format is too long";
    while (p < end) {
        unsigned long w;
        if (*p != '%') { p++; continue; }
        p++;
        if (p < end && *p == '%') { p++; continue; }      /* literal %% */
        while (p < end && (*p == '-' || *p == '+' || *p == ' '
                           || *p == '0' || *p == '#'))
            p++;
        w = 0;
        while (p < end && *p >= '0' && *p <= '9')
            w = w * 10 + (unsigned long)(*p++ - '0');
        if (w > STENCIL_FMT_MAXWID)
            return "fmt: width is too large";
        if (p < end && *p == '.') {
            p++;
            w = 0;
            while (p < end && *p >= '0' && *p <= '9')
                w = w * 10 + (unsigned long)(*p++ - '0');
            if (w > STENCIL_FMT_MAXWID)
                return "fmt: precision is too large";
        }
        if (p >= end)
            return "fmt: format ends inside a conversion";
        if (*p == '*')
            return "fmt: '*' is not allowed";
        if (*p == '\0' || strchr("diouxXeEfgGs", *p) == NULL)
            return "fmt: conversion must be one of diouxXeEfgGs";
        p++;
        convs++;
    }
    if (convs != 1)
        return convs ? "fmt: only one conversion is allowed"
                     : "fmt: format needs one % conversion";
    return NULL;
}

/* parse `| name` / `| name(arg)` chains and emit SOP_FILTERs */
static int parse_filters(stencil_compiler *c)
{
    for (;;) {
        const char *fname;
        size_t      fnlen;
        stencil_cfilt f;
        uint32_t    foff;

        skip_ws(c);
        if (c->p >= c->end || *c->p != '|')
            return 1;
        c->p++;
        skip_ws(c);
        fnlen = word_len(c->p, c->end);
        if (!fnlen)
            return cerror(c, c->p, "expected a filter name after '|'");
        fname = c->p;
        c->p += fnlen;

        memset(&f, 0, sizeof f);
        f.name_off = stencil_intern_get(&c->lit_intern, &c->pool, fname,
                                        (uint32_t)fnlen);
        if (f.name_off == STENCIL_ARENA_NULL)
            return coom(c);
        f.name_len   = (uint32_t)fnlen;
        f.builtin_id = filter_builtin(fname, (uint32_t)fnlen);

        skip_ws(c);
        if (c->p < c->end && *c->p == '(') {
            c->p++;
            skip_ws(c);
            if (c->p < c->end && (*c->p == '\'' || *c->p == '"')) {
                char        quote = *c->p;
                const char *q     = c->p + 1;
                while (q < c->end && *q != quote) {
                    if (*q == '\\' && q + 1 < c->end
                        && (q[1] == quote || q[1] == '\\'))
                        q += 2;
                    else
                        q++;
                }
                if (q >= c->end)
                    return cerror(c, c->p, "unterminated filter argument");
                /* store raw (escapes are rare in filter args; unescape
                 * with the same rule as expression strings) */
                {
                    const char *r = c->p + 1;
                    char       *w;
                    uint32_t    off = stencil_arena_alloc(&c->pool,
                                          (size_t)(q - r), 1);
                    if (off == STENCIL_ARENA_NULL)
                        return coom(c);
                    w = c->pool.base + off;
                    while (r < q) {
                        if (*r == '\\' && (r[1] == quote || r[1] == '\\'))
                            r++;
                        *w++ = *r++;
                    }
                    f.str_off = off;
                    f.str_len = (uint32_t)(w - (c->pool.base + off));
                    c->pool.used = (size_t)(w - c->pool.base);
                }
                f.has_arg = 1;
                c->p = q + 1;
            } else if (c->p < c->end
                       && (isDIGIT(*c->p)
                           || (*c->p == '-' && c->p + 1 < c->end
                               && isDIGIT(c->p[1])))) {
                double val = 0.0, frac = 0.1;
                int    neg = 0;
                if (*c->p == '-') { neg = 1; c->p++; }
                while (c->p < c->end && isDIGIT(*c->p))
                    val = val * 10.0 + (*c->p++ - '0');
                if (c->p < c->end && *c->p == '.') {
                    c->p++;
                    while (c->p < c->end && isDIGIT(*c->p)) {
                        val += (*c->p++ - '0') * frac;
                        frac *= 0.1;
                    }
                }
                f.num_arg    = neg ? -val : val;
                f.arg_is_num = 1;
                f.has_arg    = 1;
            } else {
                return cerror(c, c->p,
                    "filter argument must be a quoted string or number");
            }
            skip_ws(c);
            if (c->p >= c->end || *c->p != ')')
                return cerror(c, c->p, "expected ')'");
            c->p++;
        }

        /* arity for built-ins is known at compile time */
        if (f.builtin_id == STENCIL_FILT_DEFAULT && !f.has_arg)
            return cerror(c, fname, "filter 'default' needs an argument");
        if (f.builtin_id == STENCIL_FILT_FMT) {
            const char *bad;
            if (!f.has_arg || f.arg_is_num)
                return cerror(c, fname,
                    "filter 'fmt' needs a quoted format argument");
            bad = fmt_check(c->pool.base + f.str_off, f.str_len);
            if (bad)
                return cerror(c, fname, "%s", bad);
        }
        if (f.builtin_id >= 0 && f.builtin_id != STENCIL_FILT_DEFAULT
            && f.builtin_id != STENCIL_FILT_FMT && f.has_arg)
            return cerror(c, fname, "filter '%.*s' takes no argument",
                          (int)fnlen, fname);

        foff = stencil_arena_alloc(&c->filts, sizeof(stencil_cfilt),
                                   sizeof(double));
        if (foff == STENCIL_ARENA_NULL)
            return coom(c);
        memcpy(c->filts.base + foff, &f, sizeof f);
        if (!emit_op(c, SOP_FILTER, 0) || !emit_u32(c, c->n_filts))
            return 0;
        c->n_filts++;
    }
}

/* ====================================================================
 * Statements
 * ==================================================================== */

static stencil_blk *blk_open(stencil_compiler *c, uint8_t kind,
                             uint32_t line, uint32_t col)
{
    stencil_blk *b;
    if (c->n_blk >= STENCIL_MAX_DEPTH) {
        cerror_at(c, line, col, "blocks nested deeper than %d",
                  STENCIL_MAX_DEPTH);
        return NULL;
    }
    b = &c->blk[c->n_blk++];
    memset(b, 0, sizeof *b);
    b->kind           = kind;
    b->line           = line;
    b->col            = col;
    b->cond_patch     = STENCIL_PATCH_END;
    b->jump_chain     = STENCIL_PATCH_END;
    b->binds_at_entry = c->cur_binds;
    return b;
}

static const char *blk_kind_name(uint8_t kind)
{
    return kind == BLK_FOR ? "for" : kind == BLK_UNLESS ? "unless" : "if";
}

/* A branch's set-binds are popped at run time when the branch's code
 * path leaves the block; each branch pops only its own binds (they are
 * counted per-branch, not per-block). */
static int emit_pop_binds(stencil_compiler *c, stencil_blk *b)
{
    int32_t delta = c->cur_binds - b->binds_at_entry;
    if (delta <= 0)
        return 1;
    c->cur_binds = b->binds_at_entry;
    return emit_op(c, SOP_POP_BINDS, 0) && emit_u32(c, (uint32_t)delta);
}

static int stmt_if(stencil_compiler *c, uint8_t kind, uint32_t line,
                   uint32_t col)
{
    stencil_blk *b = blk_open(c, kind, line, col);
    if (!b)
        return 0;
    if (!parse_expr(c) || !expect_close(c))
        return 0;
    if (!emit_op(c, kind == BLK_UNLESS ? SOP_TEST_JT : SOP_TEST_JF, -1))
        return 0;
    b->cond_patch = code_pos(c);
    return emit_u32(c, STENCIL_PATCH_END);
}

static int stmt_elsif(stencil_compiler *c, uint32_t line, uint32_t col)
{
    stencil_blk *b;
    if (!c->n_blk)
        return cerror_at(c, line, col, "'elsif' with no open 'if'");
    b = &c->blk[c->n_blk - 1];
    if (b->kind != BLK_IF)
        return cerror_at(c, line, col, "'elsif' inside '%s' block",
                         blk_kind_name(b->kind));
    if (b->has_else)
        return cerror_at(c, line, col, "'elsif' after 'else'");
    if (!emit_pop_binds(c, b))
        return 0;
    if (!emit_jump_chained(c, SOP_JUMP, 0, &b->jump_chain))
        return 0;
    patch_u32(c, b->cond_patch, code_pos(c));
    if (!parse_expr(c) || !expect_close(c))
        return 0;
    if (!emit_op(c, SOP_TEST_JF, -1))
        return 0;
    b->cond_patch = code_pos(c);
    return emit_u32(c, STENCIL_PATCH_END);
}

static int stmt_else(stencil_compiler *c, uint32_t line, uint32_t col)
{
    stencil_blk *b;
    if (!c->n_blk)
        return cerror_at(c, line, col, "'else' with no open block");
    b = &c->blk[c->n_blk - 1];
    if (b->kind == BLK_FOR)
        return cerror_at(c, line, col, "'else' inside 'for' block");
    if (b->has_else)
        return cerror_at(c, line, col, "duplicate 'else'");
    if (!expect_close(c))
        return 0;
    if (!emit_pop_binds(c, b))
        return 0;
    if (!emit_jump_chained(c, SOP_JUMP, 0, &b->jump_chain))
        return 0;
    patch_u32(c, b->cond_patch, code_pos(c));
    b->cond_patch = STENCIL_PATCH_END;
    b->has_else   = 1;
    return 1;
}

static int stmt_end(stencil_compiler *c, uint32_t line, uint32_t col)
{
    stencil_blk *b;
    if (!c->n_blk)
        return cerror_at(c, line, col, "'end' with no open block");
    if (!expect_close(c))
        return 0;
    b = &c->blk[--c->n_blk];
    if (!emit_pop_binds(c, b))
        return 0;
    if (b->kind == BLK_FOR) {
        /* the pops sit before FOR_NEXT so every iteration gets a fresh
         * bind scope */
        if (!emit_op(c, SOP_FOR_NEXT, 0) || !emit_u32(c, b->body_start))
            return 0;
        patch_u32(c, b->for_end_patch, code_pos(c));
        c->cur_frames--;
    } else {
        if (b->cond_patch != STENCIL_PATCH_END)
            patch_u32(c, b->cond_patch, code_pos(c));
        patch_chain(c, b->jump_chain, code_pos(c));
    }
    return 1;
}

static int stmt_for(stencil_compiler *c, uint32_t line, uint32_t col)
{
    const char *n1, *n2 = NULL;
    size_t      l1, l2 = 0;
    uint32_t    id1, id2 = 0;
    stencil_blk *b;

    skip_ws(c);
    l1 = word_len(c->p, c->end);
    if (!l1 || is_keyword(c->p, l1))
        return cerror(c, c->p, "expected a loop variable name");
    n1 = c->p;
    c->p += l1;
    skip_ws(c);
    if (c->p < c->end && *c->p == ',') {
        c->p++;
        skip_ws(c);
        l2 = word_len(c->p, c->end);
        if (!l2 || is_keyword(c->p, l2))
            return cerror(c, c->p, "expected a value variable name");
        n2 = c->p;
        c->p += l2;
        skip_ws(c);
    }
    {
        size_t wl = word_len(c->p, c->end);
        if (!wl || !word_is(c->p, wl, "in"))
            return cerror(c, c->p, "expected 'in'");
        c->p += wl;
    }
    skip_ws(c);
    if (!parse_path_push(c))
        return 0;
    if (!expect_close(c))
        return 0;

    id1 = name_intern(c, n1, (uint32_t)l1);
    if (id1 == STENCIL_ARENA_NULL)
        return coom(c);
    if (n2) {
        id2 = name_intern(c, n2, (uint32_t)l2);
        if (id2 == STENCIL_ARENA_NULL)
            return coom(c);
    }

    b = blk_open(c, BLK_FOR, line, col);
    if (!b)
        return 0;
    if (n2) {
        if (!emit_op(c, SOP_FOR_HASH, -1) ||
            !emit_u32(c, id1) || !emit_u32(c, id2))
            return 0;
    } else {
        if (!emit_op(c, SOP_FOR_ARY, -1) || !emit_u32(c, id1))
            return 0;
    }
    b->for_end_patch = code_pos(c);
    if (!emit_u32(c, STENCIL_PATCH_END))
        return 0;
    b->body_start = code_pos(c);
    c->cur_frames++;
    if (c->cur_frames > c->max_frames)
        c->max_frames = c->cur_frames;
    return 1;
}

static int stmt_set(stencil_compiler *c)
{
    const char *n1;
    size_t      l1;
    uint32_t    id;

    skip_ws(c);
    l1 = word_len(c->p, c->end);
    if (!l1 || is_keyword(c->p, l1))
        return cerror(c, c->p, "expected a variable name after 'set'");
    n1 = c->p;
    c->p += l1;
    if (c->p < c->end && (*c->p == '.' || *c->p == '['))
        return cerror(c, c->p, "'set' target must be a plain name");
    skip_ws(c);
    if (c->p >= c->end || *c->p != '='
        || (c->p + 1 < c->end && c->p[1] == '='))
        return cerror(c, c->p, "expected '=' after the 'set' name");
    c->p++;
    if (!parse_expr(c) || !expect_close(c))
        return 0;
    id = name_intern(c, n1, (uint32_t)l1);
    if (id == STENCIL_ARENA_NULL)
        return coom(c);
    if (!emit_op(c, SOP_SET, -1) || !emit_u32(c, id))
        return 0;
    c->cur_binds++;
    if (c->cur_binds > c->max_binds)
        c->max_binds = c->cur_binds;
    return 1;
}

static int stmt_include(stencil_compiler *c, uint32_t line, uint32_t col)
{
    const char *n;
    size_t      len;
    uint32_t    i, off, ioff;
    stencil_cinc *tab, *e;

    skip_ws(c);
    n = c->p;
    while (c->p < c->end && !isSPACE(*c->p) && *c->p != '%')
        c->p++;
    len = (size_t)(c->p - n);
    if (!len)
        return cerror(c, n, "expected a template name after 'include'");
    if (!expect_close(c))
        return 0;

    tab = (stencil_cinc *)c->incs.base;
    for (i = 0; i < c->n_incs; i++)
        if (tab[i].name_len == len
            && memcmp(c->pool.base + tab[i].name_off, n, len) == 0)
            return emit_op(c, SOP_INCLUDE, 0) && emit_u32(c, i);

    off = stencil_intern_get(&c->lit_intern, &c->pool, n, (uint32_t)len);
    if (off == STENCIL_ARENA_NULL)
        return coom(c);
    ioff = stencil_arena_alloc(&c->incs, sizeof(stencil_cinc),
                               sizeof(uint32_t));
    if (ioff == STENCIL_ARENA_NULL)
        return coom(c);
    e = (stencil_cinc *)(c->incs.base + ioff);
    e->name_off = off;
    e->name_len = (uint32_t)len;
    e->line     = line;
    e->col      = col;
    if (!emit_op(c, SOP_INCLUDE, 0) || !emit_u32(c, c->n_incs))
        return 0;
    c->n_incs++;
    return 1;
}

/* ====================================================================
 * Main scan loop
 * ==================================================================== */

static int scan_template(stencil_compiler *c)
{
    for (;;) {
        const char *run = c->p;
        const char *q   = c->p;

        /* literal run up to the next real '{%' */
        for (;;) {
            q = stencil_dispatch.scan(q, c->end);
            if (q == c->end)
                break;
            if (q + 1 < c->end && q[1] == '%')
                break;
            q++;
        }
        if (!lit_pend(c, run, (size_t)(q - run)))
            return 0;
        advance_lines(c, run, q);
        c->p = q;
        if (c->p == c->end)
            break;

        /* at '{%' */
        {
            uint32_t    tag_line = c->line;
            uint32_t    tag_col  = ccol(c, c->p);
            const char *tag_at   = c->p;
            c->p += 2;

            /* comment */
            if (c->p < c->end && *c->p == '#') {
                const char *r = c->p + 1;
                for (;;) {
                    r = (const char *)memchr(r, '%',
                                             (size_t)(c->end - r));
                    if (!r)
                        return cerror_at(c, tag_line, tag_col,
                                         "unterminated comment");
                    if (r + 1 < c->end && r[1] == '}')
                        break;
                    r++;
                }
                advance_lines(c, c->p, r);
                c->p = r + 2;
                continue;
            }

            skip_ws(c);

            /* empty tag = literal '{%' escape */
            if (c->end - c->p >= 2 && c->p[0] == '%' && c->p[1] == '}') {
                c->p += 2;
                if (!lit_pend(c, "{%", 2))
                    return 0;
                continue;
            }

            if (!lit_flush(c))
                return 0;

            {
                size_t wl = word_len(c->p, c->end);
                if (!wl)
                    return cerror(c, c->p, "expected a name or keyword");

                if (word_is(c->p, wl, "if")) {
                    c->p += wl;
                    if (!stmt_if(c, BLK_IF, tag_line, tag_col))
                        return 0;
                } else if (word_is(c->p, wl, "unless")) {
                    c->p += wl;
                    if (!stmt_if(c, BLK_UNLESS, tag_line, tag_col))
                        return 0;
                } else if (word_is(c->p, wl, "elsif")) {
                    c->p += wl;
                    if (!stmt_elsif(c, tag_line, tag_col))
                        return 0;
                } else if (word_is(c->p, wl, "else")) {
                    c->p += wl;
                    if (!stmt_else(c, tag_line, tag_col))
                        return 0;
                } else if (word_is(c->p, wl, "end")) {
                    c->p += wl;
                    if (!stmt_end(c, tag_line, tag_col))
                        return 0;
                } else if (word_is(c->p, wl, "for")) {
                    c->p += wl;
                    if (!stmt_for(c, tag_line, tag_col))
                        return 0;
                } else if (word_is(c->p, wl, "set")) {
                    c->p += wl;
                    if (!stmt_set(c))
                        return 0;
                } else if (word_is(c->p, wl, "include")) {
                    c->p += wl;
                    if (!stmt_include(c, tag_line, tag_col))
                        return 0;
                } else if (word_is(c->p, wl, "content")) {
                    c->p += wl;
                    if (!expect_close(c))
                        return 0;
                    if (!emit_op(c, SOP_CONTENT, 0))
                        return 0;
                    c->flags |= STENCIL_PROG_IS_WRAPPER;
                } else if (word_is(c->p, wl, "raw")) {
                    c->p += wl;
                    skip_ws(c);
                    if (!parse_path_push(c) || !parse_filters(c)
                        || !expect_close(c))
                        return 0;
                    if (!emit_op(c, SOP_PRINT_RAW, -1))
                        return 0;
                } else {
                    /* output tag */
                    if (!parse_path_push(c) || !parse_filters(c)
                        || !expect_close(c))
                        return 0;
                    if (!emit_op(c, SOP_PRINT_ESC, -1))
                        return 0;
                }
            }
            (void)tag_at;
        }
    }

    if (!lit_flush(c))
        return 0;
    if (c->n_blk) {
        stencil_blk *b = &c->blk[c->n_blk - 1];
        return cerror_at(c, b->line, b->col,
                         "unclosed '%s' block", blk_kind_name(b->kind));
    }
    return emit_op(c, SOP_END, 0);
}

/* ====================================================================
 * Compile driver: pack regions into the final arena
 * ==================================================================== */

static void compiler_free_temps(stencil_compiler *c)
{
    stencil_arena_free(&c->code);
    stencil_arena_free(&c->pool);
    stencil_arena_free(&c->names);
    stencil_arena_free(&c->paths);
    stencil_arena_free(&c->segs);
    stencil_arena_free(&c->incs);
    stencil_arena_free(&c->filts);
    stencil_arena_free(&c->lines);
    stencil_arena_free(&c->pend);
    stencil_intern_free(&c->lit_intern);
}

static uint32_t pack_region(stencil_arena *dst, const stencil_arena *src,
                            size_t align)
{
    uint32_t off = stencil_arena_alloc(dst, src->used ? src->used : 1,
                                       align);
    if (off == STENCIL_ARENA_NULL)
        return off;
    if (src->used)
        memcpy(dst->base + off, src->base, src->used);
    return off;
}

stencil_program *stencil_compile(pTHX_ const char *src, STRLEN len,
                                 const char *name, uint32_t flags,
                                 SV **err)
{
    stencil_compiler c;
    stencil_program *prog = NULL;
    int ok;

    memset(&c, 0, sizeof c);
    c.flags = flags & STENCIL_PROG_SRC_UTF8;
    c.src  = c.p = c.line_start = src;
    c.end  = src + len;
    c.name = name;
    c.line = 1;
    c.last_line_rec = 0;
#ifdef PERL_IMPLICIT_CONTEXT
    c.perl = aTHX;
#endif

    if (!stencil_arena_init(&c.code, 256) ||
        !stencil_arena_init(&c.pool, 256) ||
        !stencil_arena_init(&c.names, 256) ||
        !stencil_arena_init(&c.paths, 256) ||
        !stencil_arena_init(&c.segs, 256) ||
        !stencil_arena_init(&c.incs, 64) ||
        !stencil_arena_init(&c.filts, 64) ||
        !stencil_arena_init(&c.lines, 128) ||
        !stencil_arena_init(&c.pend, 256) ||
        !stencil_intern_init(&c.lit_intern)) {
        compiler_free_temps(&c);
        if (err)
            *err = sv_2mortal(newSVpvs("Template::Stencil: out of memory"));
        return NULL;
    }

    ok = scan_template(&c);

    if (ok) {
        prog = (stencil_program *)calloc(1, sizeof *prog);
        if (!prog) {
            ok = 0;
            cerror_at(&c, c.line, 1, "out of memory");
        }
    }
    if (ok) {
        size_t total = c.code.used + c.pool.used + c.names.used
                     + c.paths.used + c.segs.used + c.incs.used
                     + c.filts.used + c.lines.used + 128;
        if (!stencil_arena_init(&prog->arena, total)) {
            free(prog);
            prog = NULL;
            ok   = 0;
            cerror_at(&c, c.line, 1, "out of memory");
        }
    }
    if (ok) {
        prog->code_off  = pack_region(&prog->arena, &c.code, 1);
        prog->pool_off  = pack_region(&prog->arena, &c.pool, 1);
        prog->names_off = pack_region(&prog->arena, &c.names,
                                      sizeof(uint32_t));
        prog->paths_off = pack_region(&prog->arena, &c.paths,
                                      sizeof(uint32_t));
        prog->segs_off  = pack_region(&prog->arena, &c.segs,
                                      sizeof(SSize_t));
        prog->incs_off  = pack_region(&prog->arena, &c.incs,
                                      sizeof(uint32_t));
        prog->filts_off = pack_region(&prog->arena, &c.filts,
                                      sizeof(double));
        prog->lines_off = pack_region(&prog->arena, &c.lines,
                                      sizeof(uint32_t));
        if (prog->code_off == STENCIL_ARENA_NULL
            || prog->pool_off == STENCIL_ARENA_NULL
            || prog->names_off == STENCIL_ARENA_NULL
            || prog->paths_off == STENCIL_ARENA_NULL
            || prog->segs_off == STENCIL_ARENA_NULL
            || prog->incs_off == STENCIL_ARENA_NULL
            || prog->filts_off == STENCIL_ARENA_NULL
            || prog->lines_off == STENCIL_ARENA_NULL) {
            stencil_program_free(prog);
            prog = NULL;
            ok   = 0;
            cerror_at(&c, c.line, 1, "out of memory");
        }
    }
    if (ok) {
        prog->code_len   = (uint32_t)c.code.used;
        prog->pool_len   = (uint32_t)c.pool.used;
        prog->n_names    = c.n_names;
        prog->n_paths    = c.n_paths;
        prog->n_segs     = c.n_segs;
        prog->n_incs     = c.n_incs;
        prog->n_filts    = c.n_filts;
        prog->n_lines    = c.n_lines;
        prog->max_stack  = (uint32_t)c.max_stack;
        prog->max_frames = (uint32_t)c.max_frames;
        prog->max_binds  = (uint32_t)c.max_binds;
        prog->flags      = c.flags;
        stencil_arena_finalise(&prog->arena);
    }

    compiler_free_temps(&c);

    if (!ok) {
        if (err)
            *err = sv_2mortal(newSVpvf("Template::Stencil: %s:%u:%u: %s",
                                       c.name ? c.name : "<string>",
                                       (unsigned)c.err_line,
                                       (unsigned)c.err_col, c.errbuf));
        return NULL;
    }
    return prog;
}

void stencil_program_free(stencil_program *prog)
{
    if (!prog)
        return;
    stencil_arena_free(&prog->arena);
    free(prog);
}

/* ====================================================================
 * Inspect: decode the program for tests
 * ==================================================================== */

static const char *const op_names[] = {
#define STENCIL_X_NAME(n) #n,
    STENCIL_OPS(STENCIL_X_NAME)
#undef STENCIL_X_NAME
};

#define hv_store_lit(hv, key, sv) \
    (void)hv_store((hv), "" key "", sizeof(key) - 1, (sv), 0)

static SV *path_to_sv(pTHX_ const stencil_program *pr, uint32_t id)
{
    const stencil_cpath *p = &stencil_prog_paths(pr)[id];
    return newSVpvn(stencil_prog_pool(pr) + p->full_off, p->full_len);
}

static SV *name_to_sv(pTHX_ const stencil_program *pr, uint32_t id)
{
    const stencil_cname *n = &stencil_prog_names(pr)[id];
    return newSVpvn(stencil_prog_pool(pr) + n->off, n->len);
}

SV *stencil_program_inspect(pTHX_ const stencil_program *pr)
{
    HV *top = newHV();
    AV *ops = newAV();
    const uint8_t *code = stencil_prog_code(pr);
    uint32_t       pc   = 0;

    while (pc < pr->code_len) {
        uint8_t op = code[pc];
        HV *h = newHV();
        uint32_t at = pc;
        pc++;
        hv_store_lit(h, "at", newSVuv(at));
        hv_store_lit(h, "op", newSVpv(op < SOP__MAX ? op_names[op] : "?", 0));
        switch (op) {
        case SOP_LITERAL_SHORT: {
            uint8_t l = code[pc++];
            hv_store_lit(h, "len", newSVuv(l));
            hv_store_lit(h, "bytes",
                         newSVpvn((const char *)code + pc, l));
            pc += l;
            break;
        }
        case SOP_LITERAL_LONG: case SOP_PUSH_LIT_STR: {
            uint32_t off, l;
            memcpy(&off, code + pc, 4); pc += 4;
            memcpy(&l,   code + pc, 4); pc += 4;
            hv_store_lit(h, "off", newSVuv(off));
            hv_store_lit(h, "len", newSVuv(l));
            hv_store_lit(h, "bytes",
                         newSVpvn(stencil_prog_pool(pr) + off, l));
            break;
        }
        case SOP_PUSH_LIT_NUM: {
            double d;
            memcpy(&d, code + pc, 8); pc += 8;
            hv_store_lit(h, "num", newSVnv(d));
            break;
        }
        case SOP_PUSH_PATH: {
            uint32_t id;
            memcpy(&id, code + pc, 4); pc += 4;
            hv_store_lit(h, "path_id", newSVuv(id));
            hv_store_lit(h, "path", path_to_sv(aTHX_ pr, id));
            break;
        }
        case SOP_TEST_JF: case SOP_TEST_JT: case SOP_JF_KEEP:
        case SOP_JT_KEEP: case SOP_JUMP: case SOP_FOR_NEXT: {
            uint32_t t;
            memcpy(&t, code + pc, 4); pc += 4;
            hv_store_lit(h, "target", newSVuv(t));
            break;
        }
        case SOP_FOR_ARY: {
            uint32_t id, t;
            memcpy(&id, code + pc, 4); pc += 4;
            memcpy(&t,  code + pc, 4); pc += 4;
            hv_store_lit(h, "name", name_to_sv(aTHX_ pr, id));
            hv_store_lit(h, "target", newSVuv(t));
            break;
        }
        case SOP_FOR_HASH: {
            uint32_t k, v, t;
            memcpy(&k, code + pc, 4); pc += 4;
            memcpy(&v, code + pc, 4); pc += 4;
            memcpy(&t, code + pc, 4); pc += 4;
            hv_store_lit(h, "key", name_to_sv(aTHX_ pr, k));
            hv_store_lit(h, "val", name_to_sv(aTHX_ pr, v));
            hv_store_lit(h, "target", newSVuv(t));
            break;
        }
        case SOP_SET: {
            uint32_t id;
            memcpy(&id, code + pc, 4); pc += 4;
            hv_store_lit(h, "name", name_to_sv(aTHX_ pr, id));
            break;
        }
        case SOP_POP_BINDS: {
            uint32_t n;
            memcpy(&n, code + pc, 4); pc += 4;
            hv_store_lit(h, "count", newSVuv(n));
            break;
        }
        case SOP_INCLUDE: {
            uint32_t id;
            const stencil_cinc *inc;
            memcpy(&id, code + pc, 4); pc += 4;
            inc = &stencil_prog_incs(pr)[id];
            hv_store_lit(h, "file",
                newSVpvn(stencil_prog_pool(pr) + inc->name_off,
                         inc->name_len));
            break;
        }
        case SOP_FILTER: {
            uint32_t id;
            const stencil_cfilt *f;
            memcpy(&id, code + pc, 4); pc += 4;
            f = &stencil_prog_filts(pr)[id];
            hv_store_lit(h, "filter",
                newSVpvn(stencil_prog_pool(pr) + f->name_off,
                         f->name_len));
            hv_store_lit(h, "builtin_id", newSViv(f->builtin_id));
            if (f->has_arg) {
                if (f->arg_is_num)
                    hv_store_lit(h, "arg", newSVnv(f->num_arg));
                else
                    hv_store_lit(h, "arg",
                        newSVpvn(stencil_prog_pool(pr) + f->str_off,
                                 f->str_len));
            }
            break;
        }
        default:
            break;
        }
        av_push(ops, newRV_noinc((SV *)h));
    }
    hv_store_lit(top, "ops", newRV_noinc((SV *)ops));

    {
        AV *paths = newAV();
        uint32_t i, s;
        for (i = 0; i < pr->n_paths; i++) {
            const stencil_cpath *p = &stencil_prog_paths(pr)[i];
            HV *ph   = newHV();
            AV *segs = newAV();
            hv_store_lit(ph, "str", path_to_sv(aTHX_ pr, i));
            hv_store_lit(ph, "loop_rooted", newSViv(p->loop_rooted));
            for (s = 0; s < p->n_segs; s++) {
                const stencil_seg *sg =
                    &stencil_prog_segs(pr)[p->seg_idx + s];
                HV *sh = newHV();
                if (sg->is_index) {
                    hv_store_lit(sh, "index", newSViv((IV)sg->index));
                } else {
                    const stencil_cname *nm =
                        &stencil_prog_names(pr)[sg->name_id];
                    hv_store_lit(sh, "name", name_to_sv(aTHX_ pr,
                                                        sg->name_id));
                    hv_store_lit(sh, "hash", newSVuv(nm->hash));
                }
                av_push(segs, newRV_noinc((SV *)sh));
            }
            hv_store_lit(ph, "segs", newRV_noinc((SV *)segs));
            av_push(paths, newRV_noinc((SV *)ph));
        }
        hv_store_lit(top, "paths", newRV_noinc((SV *)paths));
    }
    {
        AV *incs = newAV();
        uint32_t i;
        for (i = 0; i < pr->n_incs; i++) {
            const stencil_cinc *inc = &stencil_prog_incs(pr)[i];
            av_push(incs, newSVpvn(stencil_prog_pool(pr) + inc->name_off,
                                   inc->name_len));
        }
        hv_store_lit(top, "includes", newRV_noinc((SV *)incs));
    }

    hv_store_lit(top, "max_stack",  newSVuv(pr->max_stack));
    hv_store_lit(top, "max_frames", newSVuv(pr->max_frames));
    hv_store_lit(top, "max_binds",  newSVuv(pr->max_binds));
    hv_store_lit(top, "code_len",   newSVuv(pr->code_len));
    hv_store_lit(top, "n_lines",    newSVuv(pr->n_lines));
    hv_store_lit(top, "is_wrapper",
                 newSViv(!!(pr->flags & STENCIL_PROG_IS_WRAPPER)));

    return newRV_noinc((SV *)top);
}

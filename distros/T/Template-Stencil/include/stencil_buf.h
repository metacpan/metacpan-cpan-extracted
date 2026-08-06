#ifndef STENCIL_BUF_H
#define STENCIL_BUF_H

/* SV-backed output buffer: the buffer IS the result SV, so a PSGI
 * server can hand the rendered body back with zero copies. The grow
 * path is out of line; the reserve fast path is a compare and fall
 * through. Under ithreads the owning interpreter is captured at init
 * so the escaper and VM can call through function pointers that carry
 * no pTHX. */

typedef struct stencil_buf {
    SV   *sv;
    char *cur;   /* write head */
    char *end;   /* last writable byte + 1 (the NUL slot is excluded) */
    int   utf8;  /* set when any contributing source/value was UTF-8 */
#ifdef PERL_IMPLICIT_CONTEXT
    PerlInterpreter *perl;
#endif
} stencil_buf;

void stencil_buf_init(pTHX_ stencil_buf *b, size_t hint);
void stencil_buf_grow(stencil_buf *b, size_t need);   /* slow path */
SV  *stencil_buf_done(stencil_buf *b);

STENCIL_INLINE void stencil_buf_reserve(stencil_buf *b, size_t n)
{
    if (STENCIL_UNLIKELY((size_t)(b->end - b->cur) < n))
        stencil_buf_grow(b, n);
}

STENCIL_INLINE void stencil_buf_write(stencil_buf *b, const char *p, size_t n)
{
    stencil_buf_reserve(b, n);
    memcpy(b->cur, p, n);
    b->cur += n;
}

/* Single unaligned 8-byte store for short known strings (escape
 * entities, the literal "{%"): pat8 points at 8 readable bytes, len is
 * how far the head advances. Faster than memcpy(len) on every codegen
 * we care about. */
STENCIL_INLINE void stencil_buf_write8(stencil_buf *b, const char *pat8,
                                       size_t len)
{
    stencil_buf_reserve(b, 8);
    memcpy(b->cur, pat8, 8);
    b->cur += len;
}

#endif /* STENCIL_BUF_H */

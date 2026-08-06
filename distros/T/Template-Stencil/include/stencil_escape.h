#ifndef STENCIL_ESCAPE_H
#define STENCIL_ESCAPE_H

/* HTML escaper variants: escape src[0..n) of < > & " ' into the
 * buffer, returning bytes written. Each variant reserves its own
 * worst-case space up front and then writes unchecked. Selection
 * happens once in stencil_boot(). */

size_t stencil_escape_swar(struct stencil_buf *b, const char *src, size_t n);
#ifdef STENCIL_HAVE_SSE2
size_t stencil_escape_sse2(struct stencil_buf *b, const char *src, size_t n);
#endif
#ifdef STENCIL_HAVE_AVX2
size_t stencil_escape_avx2(struct stencil_buf *b, const char *src, size_t n);
#endif
#ifdef STENCIL_HAVE_NEON
size_t stencil_escape_neon(struct stencil_buf *b, const char *src, size_t n);
#endif

/* SWAR count of escapable bytes (used to size the reserve for large
 * inputs instead of a 6x over-reserve). */
size_t stencil_count_specials(const char *src, size_t n);

#endif /* STENCIL_ESCAPE_H */

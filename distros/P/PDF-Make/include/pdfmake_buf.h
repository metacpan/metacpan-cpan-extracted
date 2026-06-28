/*
 * libpdfmake — growable byte buffer.
 *
 * A simple dynamic byte buffer for building output. Grows geometrically
 * on demand. Used by the object serializer to accumulate PDF syntax.
 */

#ifndef PDFMAKE_BUF_H
#define PDFMAKE_BUF_H

#include "pdfmake_types.h"
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Default initial capacity. */
#ifndef PDFMAKE_BUF_INIT_CAP
#define PDFMAKE_BUF_INIT_CAP 4096
#endif

/* Growable byte buffer. */
typedef struct pdfmake_buf {
    uint8_t *data;      /* heap-allocated bytes */
    size_t   len;       /* current byte count */
    size_t   cap;       /* allocated capacity */
} pdfmake_buf_t;

/*----------------------------------------------------------------------------
 * Lifecycle
 *--------------------------------------------------------------------------*/

/* Initialize a buffer with default capacity. Returns PDFMAKE_OK or PDFMAKE_ENOMEM. */
pdfmake_err_t pdfmake_buf_init(pdfmake_buf_t *buf);

/* Initialize with a specific initial capacity. */
pdfmake_err_t pdfmake_buf_init_cap(pdfmake_buf_t *buf, size_t cap);

/* Free buffer memory and reset to empty. Safe to call on zeroed buf. */
void pdfmake_buf_free(pdfmake_buf_t *buf);

/* Reset buffer length to 0, keeping allocated memory. */
void pdfmake_buf_clear(pdfmake_buf_t *buf);

/*----------------------------------------------------------------------------
 * Writing
 *--------------------------------------------------------------------------*/

/* Ensure at least `extra` more bytes can be written without realloc.
 * Returns PDFMAKE_OK or PDFMAKE_ENOMEM. */
pdfmake_err_t pdfmake_buf_reserve(pdfmake_buf_t *buf, size_t extra);

/* Append `len` bytes from `data`. Returns PDFMAKE_OK or PDFMAKE_ENOMEM. */
pdfmake_err_t pdfmake_buf_append(pdfmake_buf_t *buf, const void *data, size_t len);

/* Append a null-terminated string (not including the null). */
pdfmake_err_t pdfmake_buf_append_cstr(pdfmake_buf_t *buf, const char *s);

/* Append a single byte. */
pdfmake_err_t pdfmake_buf_append_byte(pdfmake_buf_t *buf, uint8_t byte);

/* Append formatted output (printf-style). Returns PDFMAKE_OK or PDFMAKE_ENOMEM.
 * Note: Uses vsnprintf internally; locale-dependent for %f/%g. Use the
 * dedicated number formatters for locale-independent output. */
pdfmake_err_t pdfmake_buf_appendf(pdfmake_buf_t *buf, const char *fmt, ...)
    __attribute__((format(printf, 2, 3)));

/* Append formatted output (va_list version). */
pdfmake_err_t pdfmake_buf_vappendf(pdfmake_buf_t *buf, const char *fmt, va_list ap);

/*----------------------------------------------------------------------------
 * Output
 *--------------------------------------------------------------------------*/

/* Transfer ownership of the buffer's data to the caller. Returns the data
 * pointer, sets *len_out to length, and resets buf to empty. Caller must
 * free() the returned pointer. Returns NULL if buffer is empty. */
uint8_t *pdfmake_buf_take(pdfmake_buf_t *buf, size_t *len_out);

/* Get a pointer to the buffer's data (not null-terminated). Valid until
 * next append or free. */
static PDFMAKE_INLINE const uint8_t *pdfmake_buf_data(const pdfmake_buf_t *buf) {
    return buf->data;
}

/* Get current buffer length. */
static PDFMAKE_INLINE size_t pdfmake_buf_len(const pdfmake_buf_t *buf) {
    return buf->len;
}

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_BUF_H */

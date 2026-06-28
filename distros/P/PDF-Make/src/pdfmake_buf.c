/*
 * libpdfmake — growable byte buffer implementation.
 */

#include "pdfmake_buf.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>

/*----------------------------------------------------------------------------
 * Internal helpers
 *--------------------------------------------------------------------------*/

/* Grow buffer to at least `needed` total capacity. */
static pdfmake_err_t buf_grow(pdfmake_buf_t *buf, size_t needed) {
    size_t new_cap;
    uint8_t *new_data;

    if (needed <= buf->cap) return PDFMAKE_OK;

    /* Geometric growth: double, but at least `needed`. */
    new_cap = buf->cap * 2;
    if (new_cap < needed) new_cap = needed;
    if (new_cap < PDFMAKE_BUF_INIT_CAP) new_cap = PDFMAKE_BUF_INIT_CAP;

    new_data = realloc(buf->data, new_cap);
    if (!new_data) return PDFMAKE_ENOMEM;

    buf->data = new_data;
    buf->cap = new_cap;
    return PDFMAKE_OK;
}

/*----------------------------------------------------------------------------
 * Lifecycle
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_buf_init(pdfmake_buf_t *buf) {
    return pdfmake_buf_init_cap(buf, PDFMAKE_BUF_INIT_CAP);
}

pdfmake_err_t pdfmake_buf_init_cap(pdfmake_buf_t *buf, size_t cap) {
    if (!buf) return PDFMAKE_EINVAL;

    buf->data = NULL;
    buf->len = 0;
    buf->cap = 0;

    if (cap > 0) {
        buf->data = malloc(cap);
        if (!buf->data) return PDFMAKE_ENOMEM;
        buf->cap = cap;
    }

    return PDFMAKE_OK;
}

void pdfmake_buf_free(pdfmake_buf_t *buf) {
    if (!buf) return;
    free(buf->data);
    buf->data = NULL;
    buf->len = 0;
    buf->cap = 0;
}

void pdfmake_buf_clear(pdfmake_buf_t *buf) {
    if (buf) buf->len = 0;
}

/*----------------------------------------------------------------------------
 * Writing
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_buf_reserve(pdfmake_buf_t *buf, size_t extra) {
    if (!buf) return PDFMAKE_EINVAL;
    return buf_grow(buf, buf->len + extra);
}

pdfmake_err_t pdfmake_buf_append(pdfmake_buf_t *buf, const void *data, size_t len) {
    pdfmake_err_t err;

    if (!buf) return PDFMAKE_EINVAL;
    if (len == 0) return PDFMAKE_OK;
    if (!data) return PDFMAKE_EINVAL;

    err = buf_grow(buf, buf->len + len);
    if (err != PDFMAKE_OK) return err;

    memcpy(buf->data + buf->len, data, len);
    buf->len += len;
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_buf_append_cstr(pdfmake_buf_t *buf, const char *s) {
    if (!s) return PDFMAKE_OK;
    return pdfmake_buf_append(buf, s, strlen(s));
}

pdfmake_err_t pdfmake_buf_append_byte(pdfmake_buf_t *buf, uint8_t byte) {
    return pdfmake_buf_append(buf, &byte, 1);
}

pdfmake_err_t pdfmake_buf_vappendf(pdfmake_buf_t *buf, const char *fmt, va_list ap) {
    va_list ap_copy;
    size_t avail;
    int needed;
    pdfmake_err_t err;

    if (!buf || !fmt) return PDFMAKE_EINVAL;

    /* First, try to format directly into remaining space. */
    PDFMAKE_VA_COPY(ap_copy, ap);

    avail = buf->cap - buf->len;
    needed = vsnprintf((char *)(buf->data + buf->len), avail, fmt, ap_copy);
    va_end(ap_copy);

    if (needed < 0) return PDFMAKE_EINVAL;  /* Encoding error. */

    if ((size_t)needed < avail) {
        /* Fit in existing space. */
        buf->len += (size_t)needed;
        return PDFMAKE_OK;
    }

    /* Need more space. Grow and retry. */
    err = buf_grow(buf, buf->len + (size_t)needed + 1);
    if (err != PDFMAKE_OK) return err;

    avail = buf->cap - buf->len;
    needed = vsnprintf((char *)(buf->data + buf->len), avail, fmt, ap);
    if (needed < 0) return PDFMAKE_EINVAL;

    buf->len += (size_t)needed;
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_buf_appendf(pdfmake_buf_t *buf, const char *fmt, ...) {
    va_list ap;
    pdfmake_err_t err;

    va_start(ap, fmt);
    err = pdfmake_buf_vappendf(buf, fmt, ap);
    va_end(ap);
    return err;
}

/*----------------------------------------------------------------------------
 * Output
 *--------------------------------------------------------------------------*/

uint8_t *pdfmake_buf_take(pdfmake_buf_t *buf, size_t *len_out) {
    uint8_t *data;
    size_t len;

    if (!buf) {
        if (len_out) *len_out = 0;
        return NULL;
    }

    data = buf->data;
    len = buf->len;

    buf->data = NULL;
    buf->len = 0;
    buf->cap = 0;

    if (len_out) *len_out = len;
    return data;
}

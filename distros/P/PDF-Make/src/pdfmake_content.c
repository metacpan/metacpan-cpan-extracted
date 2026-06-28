/*
 * pdfmake_content.c — Content stream builder implementation.
 *
 * Implements all PDF content stream operators per Annex A.
 * Each function appends the operator with its operands to a buffer.
 */

#include "pdfmake_content.h"
#include "pdfmake_writer.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/*----------------------------------------------------------------------------
 * Internal helpers
 *--------------------------------------------------------------------------*/

/* Append a formatted number (removes trailing zeros for cleaner output). */
static pdfmake_err_t append_number(pdfmake_buf_t *buf, double val)
{
    char tmp[32];
    int len = pdfmake_format_real(tmp, val);
    if (len < 0) return PDFMAKE_EINVAL;
    return pdfmake_buf_append(buf, (const uint8_t *)tmp, (size_t)len);
}

/* Append a name (with leading /). */
static pdfmake_err_t append_name(pdfmake_buf_t *buf, const char *name)
{
    if (pdfmake_buf_append_byte(buf, '/') != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return pdfmake_buf_append_cstr(buf, name);
}

/* Append a space. */
static PDFMAKE_INLINE pdfmake_err_t append_space(pdfmake_buf_t *buf)
{
    return pdfmake_buf_append_byte(buf, ' ');
}

/* Append a newline. */
static PDFMAKE_INLINE pdfmake_err_t append_newline(pdfmake_buf_t *buf)
{
    return pdfmake_buf_append_byte(buf, '\n');
}

/* Append a simple operator (no operands). */
static pdfmake_err_t append_op(pdfmake_buf_t *buf, const char *op)
{
    if (pdfmake_buf_append_cstr(buf, op) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_newline(buf);
}

/* Append a PDF string (with escaping). */
static pdfmake_err_t append_string(pdfmake_buf_t *buf,
                                       const uint8_t *str, size_t len)
{
    size_t i;
    if (pdfmake_buf_append_byte(buf, '(') != PDFMAKE_OK) return PDFMAKE_EINVAL;

    for (i = 0; i < len; i++) {
        uint8_t ch = str[i];
        switch (ch) {
            case '(':
            case ')':
            case '\\':
                if (pdfmake_buf_append_byte(buf, '\\') != PDFMAKE_OK)
                    return PDFMAKE_EINVAL;
                if (pdfmake_buf_append_byte(buf, ch) != PDFMAKE_OK)
                    return PDFMAKE_EINVAL;
                break;
            case '\n':
                if (pdfmake_buf_append_cstr(buf, "\\n") != PDFMAKE_OK)
                    return PDFMAKE_EINVAL;
                break;
            case '\r':
                if (pdfmake_buf_append_cstr(buf, "\\r") != PDFMAKE_OK)
                    return PDFMAKE_EINVAL;
                break;
            case '\t':
                if (pdfmake_buf_append_cstr(buf, "\\t") != PDFMAKE_OK)
                    return PDFMAKE_EINVAL;
                break;
            default:
                if (pdfmake_buf_append_byte(buf, ch) != PDFMAKE_OK)
                    return PDFMAKE_EINVAL;
        }
    }

    return pdfmake_buf_append_byte(buf, ')');
}

/*----------------------------------------------------------------------------
 * Lifecycle
 *--------------------------------------------------------------------------*/

pdfmake_content_t *pdfmake_content_new(pdfmake_arena_t *arena)
{
    pdfmake_content_t *c;
    if (!arena) return NULL;

    c = malloc(sizeof(pdfmake_content_t));
    if (!c) return NULL;

    c->arena = arena;
    if (pdfmake_buf_init(&c->buf) != PDFMAKE_OK) {
        free(c);
        return NULL;
    }

    return c;
}

void pdfmake_content_free(pdfmake_content_t *c)
{
    if (!c) return;
    pdfmake_buf_free(&c->buf);
    free(c);
}

const uint8_t *pdfmake_content_data(pdfmake_content_t *c)
{
    if (!c) return NULL;
    /* Ensure null-termination for string use */
    if (pdfmake_buf_append_byte(&c->buf, '\0') != PDFMAKE_OK)
        return NULL;
    c->buf.len--;  /* Don't count the null in length */
    return c->buf.data;
}

size_t pdfmake_content_len(pdfmake_content_t *c)
{
    return c ? c->buf.len : 0;
}

void pdfmake_content_clear(pdfmake_content_t *c)
{
    if (c) pdfmake_buf_clear(&c->buf);
}

/*----------------------------------------------------------------------------
 * General graphics state operators (§8.4.4)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_gs_q(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "q");
}

pdfmake_err_t pdfmake_gs_Q(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "Q");
}

pdfmake_err_t pdfmake_gs_cm(pdfmake_content_t *c,
                                double a, double b, double c_,
                                double d, double e, double f)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, a) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, b) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, c_) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, d) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, e) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, f) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "cm");
}

pdfmake_err_t pdfmake_gs_w(pdfmake_content_t *c, double width)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, width) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "w");
}

pdfmake_err_t pdfmake_gs_J(pdfmake_content_t *c, int cap)
{
    char tmp[16];
    if (!c) return PDFMAKE_EINVAL;
    snprintf(tmp, sizeof(tmp), "%d J\n", cap);
    return pdfmake_buf_append_cstr(&c->buf, tmp);
}

pdfmake_err_t pdfmake_gs_j(pdfmake_content_t *c, int join)
{
    char tmp[16];
    if (!c) return PDFMAKE_EINVAL;
    snprintf(tmp, sizeof(tmp), "%d j\n", join);
    return pdfmake_buf_append_cstr(&c->buf, tmp);
}

pdfmake_err_t pdfmake_gs_M(pdfmake_content_t *c, double limit)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, limit) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "M");
}

pdfmake_err_t pdfmake_gs_d(pdfmake_content_t *c,
                               const double *array, size_t count,
                               double phase)
{
    pdfmake_buf_t *buf;
    size_t i;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (pdfmake_buf_append_byte(buf, '[') != PDFMAKE_OK) return PDFMAKE_EINVAL;
    for (i = 0; i < count; i++) {
        if (i > 0 && append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
        if (append_number(buf, array[i]) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    }
    if (pdfmake_buf_append_cstr(buf, "] ") != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, phase) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "d");
}

pdfmake_err_t pdfmake_gs_ri(pdfmake_content_t *c, const char *intent)
{
    pdfmake_buf_t *buf;
    if (!c || !intent) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_name(buf, intent) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "ri");
}

pdfmake_err_t pdfmake_gs_i(pdfmake_content_t *c, double flatness)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, flatness) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "i");
}

pdfmake_err_t pdfmake_gs_gs(pdfmake_content_t *c, const char *name)
{
    pdfmake_buf_t *buf;
    if (!c || !name) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_name(buf, name) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "gs");
}

/*----------------------------------------------------------------------------
 * Path construction operators (§8.5.2)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_path_m(pdfmake_content_t *c, double x, double y)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, x) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, y) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "m");
}

pdfmake_err_t pdfmake_path_l(pdfmake_content_t *c, double x, double y)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, x) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, y) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "l");
}

pdfmake_err_t pdfmake_path_c(pdfmake_content_t *c,
                                 double x1, double y1,
                                 double x2, double y2,
                                 double x3, double y3)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, x1) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, y1) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, x2) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, y2) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, x3) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, y3) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "c");
}

pdfmake_err_t pdfmake_path_v(pdfmake_content_t *c,
                                 double x2, double y2,
                                 double x3, double y3)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, x2) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, y2) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, x3) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, y3) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "v");
}

pdfmake_err_t pdfmake_path_y(pdfmake_content_t *c,
                                 double x1, double y1,
                                 double x3, double y3)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, x1) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, y1) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, x3) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, y3) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "y");
}

pdfmake_err_t pdfmake_path_re(pdfmake_content_t *c,
                                  double x, double y,
                                  double width, double height)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, x) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, y) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, width) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, height) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "re");
}

pdfmake_err_t pdfmake_path_h(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "h");
}

/*----------------------------------------------------------------------------
 * Path painting operators (§8.5.3)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_paint_S(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "S");
}

pdfmake_err_t pdfmake_paint_s(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "s");
}

pdfmake_err_t pdfmake_paint_f(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "f");
}

pdfmake_err_t pdfmake_paint_f_star(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "f*");
}

pdfmake_err_t pdfmake_paint_B(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "B");
}

pdfmake_err_t pdfmake_paint_B_star(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "B*");
}

pdfmake_err_t pdfmake_paint_b(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "b");
}

pdfmake_err_t pdfmake_paint_b_star(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "b*");
}

pdfmake_err_t pdfmake_paint_n(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "n");
}

/*----------------------------------------------------------------------------
 * Clipping operators (§8.5.4)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_clip_W(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "W");
}

pdfmake_err_t pdfmake_clip_W_star(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "W*");
}

/*----------------------------------------------------------------------------
 * Colour operators (§8.6)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_color_CS(pdfmake_content_t *c, const char *name)
{
    pdfmake_buf_t *buf;
    if (!c || !name) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_name(buf, name) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "CS");
}

pdfmake_err_t pdfmake_color_cs(pdfmake_content_t *c, const char *name)
{
    pdfmake_buf_t *buf;
    if (!c || !name) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_name(buf, name) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "cs");
}

pdfmake_err_t pdfmake_color_SC(pdfmake_content_t *c,
                                   const double *components, size_t count)
{
    pdfmake_buf_t *buf;
    size_t i;
    if (!c || !components || count == 0) return PDFMAKE_EINVAL;
    buf = &c->buf;

    for (i = 0; i < count; i++) {
        if (append_number(buf, components[i]) != PDFMAKE_OK) return PDFMAKE_EINVAL;
        if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    }
    return append_op(buf, "SC");
}

pdfmake_err_t pdfmake_color_sc(pdfmake_content_t *c,
                                   const double *components, size_t count)
{
    pdfmake_buf_t *buf;
    size_t i;
    if (!c || !components || count == 0) return PDFMAKE_EINVAL;
    buf = &c->buf;

    for (i = 0; i < count; i++) {
        if (append_number(buf, components[i]) != PDFMAKE_OK) return PDFMAKE_EINVAL;
        if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    }
    return append_op(buf, "sc");
}

pdfmake_err_t pdfmake_color_SCN(pdfmake_content_t *c,
                                    const double *components, size_t count,
                                    const char *name)
{
    pdfmake_buf_t *buf;
    size_t i;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (components && count > 0) {
        for (i = 0; i < count; i++) {
            if (append_number(buf, components[i]) != PDFMAKE_OK) return PDFMAKE_EINVAL;
            if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
        }
    }
    if (name) {
        if (append_name(buf, name) != PDFMAKE_OK) return PDFMAKE_EINVAL;
        if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    }
    return append_op(buf, "SCN");
}

pdfmake_err_t pdfmake_color_scn(pdfmake_content_t *c,
                                    const double *components, size_t count,
                                    const char *name)
{
    pdfmake_buf_t *buf;
    size_t i;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (components && count > 0) {
        for (i = 0; i < count; i++) {
            if (append_number(buf, components[i]) != PDFMAKE_OK) return PDFMAKE_EINVAL;
            if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
        }
    }
    if (name) {
        if (append_name(buf, name) != PDFMAKE_OK) return PDFMAKE_EINVAL;
        if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    }
    return append_op(buf, "scn");
}

pdfmake_err_t pdfmake_color_G(pdfmake_content_t *c, double gray)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, gray) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "G");
}

pdfmake_err_t pdfmake_color_g(pdfmake_content_t *c, double gray)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, gray) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "g");
}

pdfmake_err_t pdfmake_color_RG(pdfmake_content_t *c,
                                   double r, double g, double b)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, r) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, g) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, b) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "RG");
}

pdfmake_err_t pdfmake_color_rg(pdfmake_content_t *c,
                                   double r, double g, double b)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, r) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, g) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, b) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "rg");
}

pdfmake_err_t pdfmake_color_K(pdfmake_content_t *c,
                                  double c_, double m, double y, double k)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, c_) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, m) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, y) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, k) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "K");
}

pdfmake_err_t pdfmake_color_k(pdfmake_content_t *c,
                                  double c_, double m, double y, double k)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, c_) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, m) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, y) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, k) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "k");
}

/*----------------------------------------------------------------------------
 * Text object operators (§9.4)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_text_BT(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "BT");
}

pdfmake_err_t pdfmake_text_ET(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "ET");
}

/*----------------------------------------------------------------------------
 * Text state operators (§9.3)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_text_Tc(pdfmake_content_t *c, double spacing)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, spacing) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "Tc");
}

pdfmake_err_t pdfmake_text_Tw(pdfmake_content_t *c, double spacing)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, spacing) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "Tw");
}

pdfmake_err_t pdfmake_text_Tz(pdfmake_content_t *c, double scale)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, scale) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "Tz");
}

pdfmake_err_t pdfmake_text_TL(pdfmake_content_t *c, double leading)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, leading) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "TL");
}

pdfmake_err_t pdfmake_text_Tf(pdfmake_content_t *c,
                                  const char *font_name, double size)
{
    pdfmake_buf_t *buf;
    if (!c || !font_name) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_name(buf, font_name) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, size) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "Tf");
}

pdfmake_err_t pdfmake_text_Tr(pdfmake_content_t *c, int mode)
{
    char tmp[16];
    if (!c) return PDFMAKE_EINVAL;
    snprintf(tmp, sizeof(tmp), "%d Tr\n", mode);
    return pdfmake_buf_append_cstr(&c->buf, tmp);
}

pdfmake_err_t pdfmake_text_Ts(pdfmake_content_t *c, double rise)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, rise) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "Ts");
}

/*----------------------------------------------------------------------------
 * Text positioning operators (§9.4.2)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_text_Td(pdfmake_content_t *c, double tx, double ty)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, tx) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, ty) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "Td");
}

pdfmake_err_t pdfmake_text_TD(pdfmake_content_t *c, double tx, double ty)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, tx) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, ty) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "TD");
}

pdfmake_err_t pdfmake_text_Tm(pdfmake_content_t *c,
                                  double a, double b, double c_,
                                  double d, double e, double f)
{
    pdfmake_buf_t *buf;
    if (!c) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, a) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, b) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, c_) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, d) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, e) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, f) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "Tm");
}

pdfmake_err_t pdfmake_text_Tstar(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "T*");
}

/*----------------------------------------------------------------------------
 * Text showing operators (§9.4.3)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_text_Tj(pdfmake_content_t *c,
                                  const uint8_t *str, size_t len)
{
    pdfmake_buf_t *buf;
    if (!c || !str) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_string(buf, str, len) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "Tj");
}

pdfmake_err_t pdfmake_text_Tj_cstr(pdfmake_content_t *c, const char *str)
{
    if (!str) return PDFMAKE_EINVAL;
    return pdfmake_text_Tj(c, (const uint8_t *)str, strlen(str));
}

pdfmake_err_t pdfmake_text_TJ(pdfmake_content_t *c, pdfmake_obj_t *array)
{
    pdfmake_buf_t *buf;
    size_t len;
    size_t i;
    if (!c || !array) return PDFMAKE_EINVAL;
    if (array->kind != PDFMAKE_ARRAY) return PDFMAKE_EINVAL;

    buf = &c->buf;

    if (pdfmake_buf_append_byte(buf, '[') != PDFMAKE_OK) return PDFMAKE_EINVAL;

    len = pdfmake_array_len(array);
    for (i = 0; i < len; i++) {
        pdfmake_obj_t *elem = pdfmake_array_get(array, i);
        if (!elem) continue;

        if (elem->kind == PDFMAKE_STR) {
            if (append_string(buf, elem->as.str.bytes, elem->as.str.len)
                != PDFMAKE_OK) return PDFMAKE_EINVAL;
        } else if (elem->kind == PDFMAKE_INT) {
            char tmp[32];
            snprintf(tmp, sizeof(tmp), "%ld", (long)elem->as.i);
            if (pdfmake_buf_append_cstr(buf, tmp) != PDFMAKE_OK) return PDFMAKE_EINVAL;
        } else if (elem->kind == PDFMAKE_REAL) {
            if (append_number(buf, elem->as.r) != PDFMAKE_OK) return PDFMAKE_EINVAL;
        }
    }

    if (pdfmake_buf_append_cstr(buf, "] TJ\n") != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_text_apostrophe(pdfmake_content_t *c,
                                          const uint8_t *str, size_t len)
{
    pdfmake_buf_t *buf;
    if (!c || !str) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_string(buf, str, len) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "'");
}

pdfmake_err_t pdfmake_text_quote(pdfmake_content_t *c,
                                     double aw, double ac,
                                     const uint8_t *str, size_t len)
{
    pdfmake_buf_t *buf;
    if (!c || !str) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_number(buf, aw) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_number(buf, ac) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_string(buf, str, len) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "\"");
}

/*----------------------------------------------------------------------------
 * XObject operator (§8.8)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_xobj_Do(pdfmake_content_t *c, const char *name)
{
    pdfmake_buf_t *buf;
    if (!c || !name) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_name(buf, name) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "Do");
}

/*----------------------------------------------------------------------------
 * Marked content operators (§14.6)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_mc_MP(pdfmake_content_t *c, const char *tag)
{
    pdfmake_buf_t *buf;
    if (!c || !tag) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_name(buf, tag) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "MP");
}

pdfmake_err_t pdfmake_mc_DP(pdfmake_content_t *c,
                                const char *tag, const char *props)
{
    pdfmake_buf_t *buf;
    if (!c || !tag || !props) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_name(buf, tag) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_name(buf, props) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "DP");
}

pdfmake_err_t pdfmake_mc_BMC(pdfmake_content_t *c, const char *tag)
{
    pdfmake_buf_t *buf;
    if (!c || !tag) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_name(buf, tag) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "BMC");
}

pdfmake_err_t pdfmake_mc_BDC(pdfmake_content_t *c,
                                 const char *tag, const char *props)
{
    pdfmake_buf_t *buf;
    if (!c || !tag || !props) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_name(buf, tag) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_name(buf, props) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "BDC");
}

pdfmake_err_t pdfmake_mc_EMC(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "EMC");
}

/*----------------------------------------------------------------------------
 * Shading operator (§8.7.4)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_sh(pdfmake_content_t *c, const char *name)
{
    pdfmake_buf_t *buf;
    if (!c || !name) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_name(buf, name) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_op(buf, "sh");
}

/*----------------------------------------------------------------------------
 * Inline image operators (§8.9.7)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_inline_BI(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "BI");
}

pdfmake_err_t pdfmake_inline_key(pdfmake_content_t *c,
                                     const char *key, const char *value)
{
    pdfmake_buf_t *buf;
    if (!c || !key || !value) return PDFMAKE_EINVAL;
    buf = &c->buf;

    if (append_name(buf, key) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    if (append_space(buf) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    /* Value might be a name or integer - just pass through */
    if (pdfmake_buf_append_cstr(buf, value) != PDFMAKE_OK) return PDFMAKE_EINVAL;
    return append_newline(buf);
}

pdfmake_err_t pdfmake_inline_ID(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    /* ID followed by single space before data */
    return pdfmake_buf_append_cstr(&c->buf, "ID ");
}

pdfmake_err_t pdfmake_inline_data(pdfmake_content_t *c,
                                      const uint8_t *data, size_t len)
{
    if (!c || !data) return PDFMAKE_EINVAL;
    return pdfmake_buf_append(&c->buf, data, len);
}

pdfmake_err_t pdfmake_inline_EI(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    /* Single space before EI per spec */
    return pdfmake_buf_append_cstr(&c->buf, " EI\n");
}

/*----------------------------------------------------------------------------
 * Compatibility operators (§8.4.5)
 *--------------------------------------------------------------------------*/

pdfmake_err_t pdfmake_compat_BX(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "BX");
}

pdfmake_err_t pdfmake_compat_EX(pdfmake_content_t *c)
{
    if (!c) return PDFMAKE_EINVAL;
    return append_op(&c->buf, "EX");
}

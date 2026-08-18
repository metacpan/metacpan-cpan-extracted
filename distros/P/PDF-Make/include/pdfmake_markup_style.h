/*
 * libpdfmake - markup attributes: the table, the coercions, the inheritance.
 *
 * One table describes every attribute a document can carry: its type, whether
 * children inherit it, and which tags accept it. The validator, the resolver
 * and the reference documentation all read it, so none of them can drift.
 *
 * This is the C half of what PDF::Make::Markup::Style used to do in Perl. It
 * holds no SVs and calls nothing in the interpreter: values come in as bytes
 * and go out as numbers, colours as #rrggbb, and errors as a message with the
 * offending value in it.
 */

#ifndef PDFMAKE_MARKUP_STYLE_H
#define PDFMAKE_MARKUP_STYLE_H

#include "pdfmake_types.h"
#include "pdfmake_markup.h"

#ifdef __cplusplus
extern "C" {
#endif

#define PDFMAKE_STYLE_ERR_LEN 256

/* Properties. Never renumber: the resolved-style struct is indexed by these
 * and a stale build would silently mean a different attribute. */
typedef enum {
    PDFMAKE_P_NONE = 0,
    /* inherited */
    PDFMAKE_P_SIZE,
    PDFMAKE_P_COLOUR,
    PDFMAKE_P_FONT,
    PDFMAKE_P_BOLD,
    PDFMAKE_P_ITALIC,
    PDFMAKE_P_LINE_HEIGHT,
    PDFMAKE_P_ALIGN,
    /* not inherited */
    PDFMAKE_P_BG,
    PDFMAKE_P_BORDER,
    PDFMAKE_P_BORDER_WIDTH,
    PDFMAKE_P_PAD,
    PDFMAKE_P_WEIGHT,
    PDFMAKE_P_WIDTH,
    PDFMAKE_P_HEIGHT,
    PDFMAKE_P_GAP,
    PDFMAKE_P_INDENT,
    PDFMAKE_P_SPACING,
    PDFMAKE_P_MARGIN,
    PDFMAKE_P_VALIGN,
    PDFMAKE_P_PAGE_SIZE,
    PDFMAKE_P_COLUMNS,
    PDFMAKE_P_BACKGROUND,
    PDFMAKE_P_SRC,
    PDFMAKE_P_TITLE,
    PDFMAKE_P_LEVEL,
    PDFMAKE_P_HEADER_REPEAT,
    PDFMAKE_P_PREFORMATTED,
    PDFMAKE_P_TAGGED,
    PDFMAKE_P_MAX
} pdfmake_prop_t;

typedef enum {
    PDFMAKE_T_LEN = 0,   /* points */
    PDFMAKE_T_NUM,
    PDFMAKE_T_COLOUR,    /* normalised to #rrggbb */
    PDFMAKE_T_BOOL,
    PDFMAKE_T_ALIGN,     /* left | center | right */
    PDFMAKE_T_VALIGN,    /* top | middle | bottom */
    PDFMAKE_T_STR
} pdfmake_ptype_t;

/* Alignment values, so callers do not compare strings. */
typedef enum {
    PDFMAKE_ALIGN_LEFT = 0,
    PDFMAKE_ALIGN_CENTER,
    PDFMAKE_ALIGN_RIGHT
} pdfmake_align_t;

typedef enum {
    PDFMAKE_VALIGN_TOP = 0,
    PDFMAKE_VALIGN_MIDDLE,
    PDFMAKE_VALIGN_BOTTOM
} pdfmake_valign_t;

/* One resolved value. Strings point into the parse arena or into static
 * storage and are never freed by the style layer. */
typedef struct {
    int          set;
    double       num;      /* LEN, NUM, BOOL (0/1), ALIGN, VALIGN */
    char         colour[8];/* "#rrggbb" */
    const char  *str;      /* STR: font family, page size, src, title */
    size_t       str_len;
} pdfmake_value_t;

/* A resolved style: every property, with a set flag. */
typedef struct {
    pdfmake_value_t v[PDFMAKE_P_MAX];
} pdfmake_style_t;

/* Name lookups. */
pdfmake_prop_t  pdfmake_style_prop(const char *name, size_t len);
const char     *pdfmake_style_prop_name(pdfmake_prop_t p);
pdfmake_ptype_t pdfmake_style_type(pdfmake_prop_t p);
int             pdfmake_style_inherits(pdfmake_prop_t p);

/* Whether a tag accepts a property, and the list it does accept (for the
 * error message, and for the generated reference). */
int         pdfmake_style_tag_allows(pdfmake_markup_tag_t tag, pdfmake_prop_t p);
const char *pdfmake_style_tag_allowed(pdfmake_markup_tag_t tag);

/* Coercions. Each returns 1 on success, or 0 with err filled in. */
int pdfmake_style_colour(const char *v, size_t len, char out[8],
                         char *err, size_t errlen);
int pdfmake_style_length(const char *v, size_t len, double *out,
                         char *err, size_t errlen);
int pdfmake_style_number(const char *v, size_t len, double *out,
                         char *err, size_t errlen);
int pdfmake_style_bool(const char *v, size_t len, int *out,
                       char *err, size_t errlen);

/*
 * Resolve one element's own attributes into `out`. Returns 1, or 0 with err
 * set to a message naming the attribute and, where it helps, what the tag
 * does accept.
 */
int pdfmake_style_attrs(const pdfmake_markup_node_t *node,
                        pdfmake_style_t *out,
                        char *err, size_t errlen);

/* Parse a <style> declaration list ("size:20;colour:#1a1a2e") for one tag. */
int pdfmake_style_declarations(const char *src, size_t len,
                               pdfmake_markup_tag_t tag,
                               pdfmake_style_t *out,
                               char *err, size_t errlen);

/* child = parent's inheritable properties, with own on top. */
void pdfmake_style_inherit(const pdfmake_style_t *parent,
                           const pdfmake_style_t *own,
                           pdfmake_style_t *out);

void pdfmake_style_init(pdfmake_style_t *s);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_MARKUP_STYLE_H */

/*
 * pdfmake_markup_style.c - the attribute table and its coercions.
 */

#include "pdfmake_markup_style.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <stdarg.h>
#include <strings.h>

/*----------------------------------------------------------------------------
 * The table
 *--------------------------------------------------------------------------*/

typedef struct {
    const char     *name;
    pdfmake_prop_t  id;
    pdfmake_ptype_t type;
    int             inherit;
} prop_ent_t;

static const prop_ent_t PROPS[] = {
    { "size",         PDFMAKE_P_SIZE,          PDFMAKE_T_LEN,    1 },
    { "colour",       PDFMAKE_P_COLOUR,        PDFMAKE_T_COLOUR, 1 },
    { "font",         PDFMAKE_P_FONT,          PDFMAKE_T_STR,    1 },
    { "bold",         PDFMAKE_P_BOLD,          PDFMAKE_T_BOOL,   1 },
    { "italic",       PDFMAKE_P_ITALIC,        PDFMAKE_T_BOOL,   1 },
    { "line-height",  PDFMAKE_P_LINE_HEIGHT,   PDFMAKE_T_LEN,    1 },
    { "align",        PDFMAKE_P_ALIGN,         PDFMAKE_T_ALIGN,  1 },

    { "bg",           PDFMAKE_P_BG,            PDFMAKE_T_COLOUR, 0 },
    { "border",       PDFMAKE_P_BORDER,        PDFMAKE_T_COLOUR, 0 },
    { "border-width", PDFMAKE_P_BORDER_WIDTH,  PDFMAKE_T_LEN,    0 },
    { "pad",          PDFMAKE_P_PAD,           PDFMAKE_T_LEN,    0 },
    { "weight",       PDFMAKE_P_WEIGHT,        PDFMAKE_T_NUM,    0 },
    { "width",        PDFMAKE_P_WIDTH,         PDFMAKE_T_LEN,    0 },
    { "height",       PDFMAKE_P_HEIGHT,        PDFMAKE_T_LEN,    0 },
    { "gap",          PDFMAKE_P_GAP,           PDFMAKE_T_LEN,    0 },
    { "indent",       PDFMAKE_P_INDENT,        PDFMAKE_T_NUM,    0 },
    { "spacing",      PDFMAKE_P_SPACING,       PDFMAKE_T_LEN,    0 },
    { "margin",       PDFMAKE_P_MARGIN,        PDFMAKE_T_LEN,    0 },
    { "valign",       PDFMAKE_P_VALIGN,        PDFMAKE_T_VALIGN, 0 },

    { "page-size",    PDFMAKE_P_PAGE_SIZE,     PDFMAKE_T_STR,    0 },
    { "columns",      PDFMAKE_P_COLUMNS,       PDFMAKE_T_NUM,    0 },
    { "background",   PDFMAKE_P_BACKGROUND,    PDFMAKE_T_COLOUR, 0 },

    { "src",          PDFMAKE_P_SRC,           PDFMAKE_T_STR,    0 },
    { "title",        PDFMAKE_P_TITLE,         PDFMAKE_T_STR,    0 },
    { "level",        PDFMAKE_P_LEVEL,         PDFMAKE_T_NUM,    0 },
    { "header-repeat",PDFMAKE_P_HEADER_REPEAT, PDFMAKE_T_BOOL,   0 },
    { "preformatted", PDFMAKE_P_PREFORMATTED,  PDFMAKE_T_BOOL,   0 },
    /* Accessibility is a property of the document, declared where the
     * document starts: <doc tagged="1"> turns the structure tree on. */
    { "tagged",       PDFMAKE_P_TAGGED,        PDFMAKE_T_BOOL,   0 }
};

#define PROP_COUNT (sizeof(PROPS) / sizeof(PROPS[0]))

/* Per-tag allowances, as bit sets over pdfmake_prop_t. A tag's set is what it
 * can actually act on: if the renderer cannot do anything with an attribute
 * here, it does not belong. */
#define BIT(p) (1ull << (p))

#define TEXT_PROPS (BIT(PDFMAKE_P_SIZE) | BIT(PDFMAKE_P_COLOUR) | \
                    BIT(PDFMAKE_P_FONT) | BIT(PDFMAKE_P_BOLD) | \
                    BIT(PDFMAKE_P_ITALIC) | BIT(PDFMAKE_P_LINE_HEIGHT) | \
                    BIT(PDFMAKE_P_ALIGN))

#define BLOCK_PROPS (BIT(PDFMAKE_P_INDENT) | BIT(PDFMAKE_P_SPACING) | \
                     BIT(PDFMAKE_P_MARGIN) | BIT(PDFMAKE_P_PAD) | \
                     BIT(PDFMAKE_P_PREFORMATTED))

#define PAGE_PROPS (BIT(PDFMAKE_P_PAGE_SIZE) | BIT(PDFMAKE_P_MARGIN) | \
                    BIT(PDFMAKE_P_COLUMNS) | BIT(PDFMAKE_P_BACKGROUND))

#define CELL_PROPS (TEXT_PROPS | BIT(PDFMAKE_P_WEIGHT) | BIT(PDFMAKE_P_PAD) | \
                    BIT(PDFMAKE_P_BG) | BIT(PDFMAKE_P_BORDER) | \
                    BIT(PDFMAKE_P_VALIGN) | BIT(PDFMAKE_P_WIDTH))

static uint64_t tag_allow(pdfmake_markup_tag_t tag) {
    switch (tag) {
    case PDFMAKE_MK_DOC:       return TEXT_PROPS | PAGE_PROPS |
                                      BIT(PDFMAKE_P_TAGGED);
    case PDFMAKE_MK_STYLE:     return 0;   /* validated as declaration lists */
    case PDFMAKE_MK_PAGE:      return PAGE_PROPS;
    case PDFMAKE_MK_PAGEBREAK: return 0;
    case PDFMAKE_MK_HEADER:
    case PDFMAKE_MK_FOOTER:    return TEXT_PROPS | BIT(PDFMAKE_P_PAD);

    case PDFMAKE_MK_H1: case PDFMAKE_MK_H2: case PDFMAKE_MK_H3:
    case PDFMAKE_MK_H4: case PDFMAKE_MK_H5: case PDFMAKE_MK_H6:
    case PDFMAKE_MK_P:  case PDFMAKE_MK_TEXT:
        return TEXT_PROPS | BLOCK_PROPS;

    case PDFMAKE_MK_HR:  return BIT(PDFMAKE_P_COLOUR) | BIT(PDFMAKE_P_WIDTH) |
                                BIT(PDFMAKE_P_HEIGHT) | BIT(PDFMAKE_P_SPACING);
    case PDFMAKE_MK_BOX: return TEXT_PROPS | BIT(PDFMAKE_P_BG) |
                                BIT(PDFMAKE_P_BORDER) |
                                BIT(PDFMAKE_P_BORDER_WIDTH) |
                                BIT(PDFMAKE_P_PAD) | BIT(PDFMAKE_P_WIDTH) |
                                BIT(PDFMAKE_P_HEIGHT);
    case PDFMAKE_MK_IMG: return BIT(PDFMAKE_P_SRC) | BIT(PDFMAKE_P_WIDTH) |
                                BIT(PDFMAKE_P_HEIGHT) | BIT(PDFMAKE_P_ALIGN);

    case PDFMAKE_MK_ROW:   return BIT(PDFMAKE_P_GAP) | BIT(PDFMAKE_P_HEIGHT) |
                                  BIT(PDFMAKE_P_SPACING);
    case PDFMAKE_MK_CELL:
    case PDFMAKE_MK_TH:
    case PDFMAKE_MK_TD:    return CELL_PROPS;
    case PDFMAKE_MK_TABLE: return TEXT_PROPS | BIT(PDFMAKE_P_GAP) |
                                  BIT(PDFMAKE_P_SPACING) |
                                  BIT(PDFMAKE_P_HEADER_REPEAT);
    case PDFMAKE_MK_TR:    return BIT(PDFMAKE_P_HEIGHT) | BIT(PDFMAKE_P_BG);

    case PDFMAKE_MK_BOOKMARK: return BIT(PDFMAKE_P_TITLE) | BIT(PDFMAKE_P_LEVEL);

    case PDFMAKE_MK_B: case PDFMAKE_MK_I: case PDFMAKE_MK_SPAN:
        return TEXT_PROPS;

    default: return 0;
    }
}

/* Named colours: the sixteen from HTML 4 plus the greys people reach for.
 * Deliberately short - a name that is not here is an error with a position,
 * not a guess at what was meant. */
typedef struct { const char *name; const char *hex; } colour_ent_t;

static const colour_ent_t COLOURS[] = {
    { "aqua", "#00ffff" }, { "black", "#000000" }, { "blue", "#0000ff" },
    { "fuchsia", "#ff00ff" }, { "gray", "#808080" }, { "green", "#008000" },
    { "grey", "#808080" }, { "lime", "#00ff00" }, { "maroon", "#800000" },
    { "navy", "#000080" }, { "olive", "#808000" }, { "purple", "#800080" },
    { "red", "#ff0000" }, { "silver", "#c0c0c0" }, { "teal", "#008080" },
    { "white", "#ffffff" }, { "yellow", "#ffff00" }
};

#define COLOUR_COUNT (sizeof(COLOURS) / sizeof(COLOURS[0]))

/*----------------------------------------------------------------------------
 * Lookups
 *--------------------------------------------------------------------------*/

static const prop_ent_t *prop_ent(pdfmake_prop_t p) {
    size_t i;
    for (i = 0; i < PROP_COUNT; i++)
        if (PROPS[i].id == p) return &PROPS[i];
    return NULL;
}

pdfmake_prop_t pdfmake_style_prop(const char *name, size_t len) {
    size_t i;
    if (!name) return PDFMAKE_P_NONE;
    /* Both spellings of the same thing, once. */
    if (len == 5 && memcmp(name, "color", 5) == 0) return PDFMAKE_P_COLOUR;
    for (i = 0; i < PROP_COUNT; i++) {
        if (strlen(PROPS[i].name) == len && memcmp(PROPS[i].name, name, len) == 0)
            return PROPS[i].id;
    }
    return PDFMAKE_P_NONE;
}

const char *pdfmake_style_prop_name(pdfmake_prop_t p) {
    const prop_ent_t *e = prop_ent(p);
    return e ? e->name : NULL;
}

pdfmake_ptype_t pdfmake_style_type(pdfmake_prop_t p) {
    const prop_ent_t *e = prop_ent(p);
    return e ? e->type : PDFMAKE_T_STR;
}

int pdfmake_style_inherits(pdfmake_prop_t p) {
    const prop_ent_t *e = prop_ent(p);
    return e ? e->inherit : 0;
}

int pdfmake_style_tag_allows(pdfmake_markup_tag_t tag, pdfmake_prop_t p) {
    if (p <= PDFMAKE_P_NONE || p >= PDFMAKE_P_MAX) return 0;
    return (tag_allow(tag) & BIT(p)) ? 1 : 0;
}

/* The accepted list, for an error message. Static buffer: this is only ever
 * used to build one message before it is copied. */
const char *pdfmake_style_tag_allowed(pdfmake_markup_tag_t tag) {
    static char buf[512];
    const char *names[PROP_COUNT];
    uint64_t allow = tag_allow(tag);
    size_t i, j, count = 0, n = 0;

    for (i = 0; i < PROP_COUNT; i++)
        if (allow & BIT(PROPS[i].id)) names[count++] = PROPS[i].name;

    /* Alphabetical: someone reading "it takes: ..." in an error message is
     * looking for one name, and the table's own grouping is no help there. */
    for (i = 1; i < count; i++) {
        const char *key = names[i];
        for (j = i; j > 0 && strcmp(names[j - 1], key) > 0; j--)
            names[j] = names[j - 1];
        names[j] = key;
    }

    buf[0] = '\0';
    for (i = 0; i < count; i++) {
        size_t l = strlen(names[i]);
        if (n && n + 2 < sizeof(buf)) { buf[n++] = ','; buf[n++] = ' '; }
        if (n + l + 1 >= sizeof(buf)) break;
        memcpy(buf + n, names[i], l);
        n += l;
    }
    buf[n] = '\0';
    return n ? buf : "(none)";
}

/*----------------------------------------------------------------------------
 * Coercions
 *--------------------------------------------------------------------------*/

static void trim(const char **s, size_t *len) {
    while (*len && isspace((unsigned char)(*s)[0])) { (*s)++; (*len)--; }
    while (*len && isspace((unsigned char)(*s)[*len - 1])) (*len)--;
}

static int fail(char *err, size_t errlen, const char *fmt, ...) {
    va_list ap;
    if (err && errlen) {
        va_start(ap, fmt);
        vsnprintf(err, errlen, fmt, ap);
        va_end(ap);
    }
    return 0;
}

static int hexval(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

int pdfmake_style_colour(const char *v, size_t len, char out[8],
                         char *err, size_t errlen) {
    size_t i;
    trim(&v, &len);

    if (len && v[0] == '#') {
        const char *h = v + 1;
        size_t hl = len - 1;
        if (hl == 3 || hl == 6) {
            char tmp[7];
            for (i = 0; i < hl; i++)
                if (hexval(h[i]) < 0) goto bad;
            if (hl == 3) {
                for (i = 0; i < 3; i++) {
                    tmp[i * 2]     = (char)tolower((unsigned char)h[i]);
                    tmp[i * 2 + 1] = (char)tolower((unsigned char)h[i]);
                }
            } else {
                for (i = 0; i < 6; i++)
                    tmp[i] = (char)tolower((unsigned char)h[i]);
            }
            out[0] = '#';
            memcpy(out + 1, tmp, 6);
            out[7] = '\0';
            return 1;
        }
        goto bad;
    }

    for (i = 0; i < COLOUR_COUNT; i++) {
        size_t nl = strlen(COLOURS[i].name);
        if (nl != len) continue;
        {
            size_t j;
            for (j = 0; j < len; j++)
                if (tolower((unsigned char)v[j]) != COLOURS[i].name[j]) break;
            if (j == len) { memcpy(out, COLOURS[i].hex, 8); return 1; }
        }
    }

bad:
    return fail(err, errlen,
        "'%.*s' is not a colour: use #rgb, #rrggbb or a colour name",
        (int)(len > 40 ? 40 : len), v);
}

/* A number, with an optional trailing "pt" for lengths. No other unit
 * exists, because the engine has no notion of one. */
static int parse_num(const char *v, size_t len, int allow_pt, double *out) {
    char buf[64];
    char *end;
    double d;

    trim(&v, &len);
    if (allow_pt && len > 2 &&
        (v[len - 2] == 'p' || v[len - 2] == 'P') &&
        (v[len - 1] == 't' || v[len - 1] == 'T'))
        len -= 2;
    if (!len || len >= sizeof(buf)) return 0;

    memcpy(buf, v, len);
    buf[len] = '\0';

    /* strtod would take "0x10", "inf" and leading whitespace; the grammar
     * here is a plain decimal number and nothing else. */
    {
        size_t i = 0;
        int digits = 0, dot = 0;
        if (buf[i] == '-' || buf[i] == '+') i++;
        for (; buf[i]; i++) {
            if (buf[i] == '.') { if (dot) return 0; dot = 1; continue; }
            if (buf[i] < '0' || buf[i] > '9') return 0;
            digits++;
        }
        if (!digits) return 0;
    }

    d = strtod(buf, &end);
    if (end == buf || *end) return 0;
    *out = d;
    return 1;
}

int pdfmake_style_length(const char *v, size_t len, double *out,
                         char *err, size_t errlen) {
    if (parse_num(v, len, 1, out)) return 1;
    return fail(err, errlen, "'%.*s' is not a number of points",
                (int)(len > 40 ? 40 : len), v);
}

int pdfmake_style_number(const char *v, size_t len, double *out,
                         char *err, size_t errlen) {
    if (parse_num(v, len, 0, out)) return 1;
    return fail(err, errlen, "'%.*s' is not a number",
                (int)(len > 40 ? 40 : len), v);
}

/* Booleans are written the way a template writes them, and nothing else is
 * guessed: "maybe" is a mistake, not a false. */
int pdfmake_style_bool(const char *v, size_t len, int *out,
                       char *err, size_t errlen) {
    static const char *T[] = { "1", "true", "yes", "on" };
    static const char *F[] = { "0", "false", "no", "off" };
    size_t i, j;
    trim(&v, &len);

    for (i = 0; i < 4; i++) {
        for (j = 0; j < 2; j++) {
            const char *w = j ? F[i] : T[i];
            size_t wl = strlen(w);
            size_t k;
            if (wl != len) continue;
            for (k = 0; k < len; k++)
                if (tolower((unsigned char)v[k]) != w[k]) break;
            if (k == len) { *out = j ? 0 : 1; return 1; }
        }
    }
    return fail(err, errlen,
        "'%.*s' is not a yes or no: use 1/0, true/false, yes/no, on/off",
        (int)(len > 40 ? 40 : len), v);
}

static int parse_align(const char *v, size_t len, double *out,
                       char *err, size_t errlen) {
    trim(&v, &len);
    if (len == 4 && strncasecmp(v, "left", 4) == 0)
        { *out = PDFMAKE_ALIGN_LEFT; return 1; }
    if (len == 5 && strncasecmp(v, "right", 5) == 0)
        { *out = PDFMAKE_ALIGN_RIGHT; return 1; }
    /* both spellings, one value */
    if ((len == 6 && strncasecmp(v, "center", 6) == 0) ||
        (len == 6 && strncasecmp(v, "centre", 6) == 0))
        { *out = PDFMAKE_ALIGN_CENTER; return 1; }
    return fail(err, errlen, "'%.*s' is not one of: left, center, right",
                (int)(len > 40 ? 40 : len), v);
}

static int parse_valign(const char *v, size_t len, double *out,
                        char *err, size_t errlen) {
    trim(&v, &len);
    if (len == 3 && strncasecmp(v, "top", 3) == 0)
        { *out = PDFMAKE_VALIGN_TOP; return 1; }
    if (len == 6 && strncasecmp(v, "middle", 6) == 0)
        { *out = PDFMAKE_VALIGN_MIDDLE; return 1; }
    if (len == 6 && strncasecmp(v, "bottom", 6) == 0)
        { *out = PDFMAKE_VALIGN_BOTTOM; return 1; }
    return fail(err, errlen, "'%.*s' is not one of: top, middle, bottom",
                (int)(len > 40 ? 40 : len), v);
}

/*----------------------------------------------------------------------------
 * Resolving
 *--------------------------------------------------------------------------*/

void pdfmake_style_init(pdfmake_style_t *s) {
    if (s) memset(s, 0, sizeof(*s));
}

static int coerce(pdfmake_prop_t p, const char *v, size_t vlen,
                  pdfmake_value_t *out, char *err, size_t errlen) {
    char sub[PDFMAKE_STYLE_ERR_LEN];
    int b = 0;

    switch (pdfmake_style_type(p)) {
    case PDFMAKE_T_LEN:
        if (!pdfmake_style_length(v, vlen, &out->num, sub, sizeof(sub)))
            return fail(err, errlen, "%s %s", pdfmake_style_prop_name(p), sub);
        break;
    case PDFMAKE_T_NUM:
        if (!pdfmake_style_number(v, vlen, &out->num, sub, sizeof(sub)))
            return fail(err, errlen, "%s %s", pdfmake_style_prop_name(p), sub);
        break;
    case PDFMAKE_T_COLOUR:
        if (!pdfmake_style_colour(v, vlen, out->colour, sub, sizeof(sub)))
            return fail(err, errlen, "%s %s", pdfmake_style_prop_name(p), sub);
        break;
    case PDFMAKE_T_BOOL:
        if (!pdfmake_style_bool(v, vlen, &b, sub, sizeof(sub)))
            return fail(err, errlen, "%s %s", pdfmake_style_prop_name(p), sub);
        out->num = b;
        break;
    case PDFMAKE_T_ALIGN:
        if (!parse_align(v, vlen, &out->num, sub, sizeof(sub)))
            return fail(err, errlen, "%s %s", pdfmake_style_prop_name(p), sub);
        break;
    case PDFMAKE_T_VALIGN:
        if (!parse_valign(v, vlen, &out->num, sub, sizeof(sub)))
            return fail(err, errlen, "%s %s", pdfmake_style_prop_name(p), sub);
        break;
    case PDFMAKE_T_STR:
    default:
        out->str = v;
        out->str_len = vlen;
        break;
    }
    out->set = 1;
    return 1;
}

int pdfmake_style_attrs(const pdfmake_markup_node_t *node,
                        pdfmake_style_t *out,
                        char *err, size_t errlen) {
    const pdfmake_markup_attr_t *a;
    const char *tag_name;

    pdfmake_style_init(out);
    if (!node) return 1;
    tag_name = pdfmake_markup_tag_name(node->tag);

    for (a = node->attrs; a; a = a->next) {
        pdfmake_prop_t p = pdfmake_style_prop(a->name, a->name_len);

        if (p == PDFMAKE_P_NONE)
            return fail(err, errlen, "unknown attribute '%.*s' on <%s>",
                        (int)a->name_len, a->name, tag_name ? tag_name : "?");

        if (!pdfmake_style_tag_allows(node->tag, p))
            return fail(err, errlen,
                        "<%s> does not take '%.*s' (it takes: %s)",
                        tag_name ? tag_name : "?",
                        (int)a->name_len, a->name,
                        pdfmake_style_tag_allowed(node->tag));

        if (!coerce(p, a->value, a->value_len, &out->v[p], err, errlen))
            return 0;
    }
    return 1;
}

int pdfmake_style_declarations(const char *src, size_t len,
                               pdfmake_markup_tag_t tag,
                               pdfmake_style_t *out,
                               char *err, size_t errlen) {
    const char *p = src, *end = src + len;
    const char *tag_name = pdfmake_markup_tag_name(tag);

    pdfmake_style_init(out);
    if (!src) return 1;
    if (!tag_name)
        return fail(err, errlen, "no such tag in <style>");

    while (p < end) {
        const char *decl = p, *colon = NULL, *q;
        size_t dlen;
        pdfmake_prop_t prop;
        const char *name, *value;
        size_t nlen, vlen;

        while (p < end && *p != ';') p++;
        dlen = (size_t)(p - decl);
        if (p < end) p++;              /* the ';' */

        {   /* skip an empty entry */
            const char *t = decl;
            size_t tl = dlen;
            trim(&t, &tl);
            if (!tl) continue;
        }

        for (q = decl; q < decl + dlen; q++)
            if (*q == ':') { colon = q; break; }
        if (!colon)
            return fail(err, errlen,
                        "<style> entry for '%s' is not name:value near '%.*s'",
                        tag_name, (int)(dlen > 40 ? 40 : dlen), decl);

        name  = decl;
        nlen  = (size_t)(colon - decl);
        value = colon + 1;
        vlen  = (size_t)((decl + dlen) - value);
        trim(&name, &nlen);
        trim(&value, &vlen);

        prop = pdfmake_style_prop(name, nlen);
        if (prop == PDFMAKE_P_NONE)
            return fail(err, errlen,
                        "unknown property '%.*s' in <style> for '%s'",
                        (int)nlen, name, tag_name);
        if (!pdfmake_style_tag_allows(tag, prop))
            return fail(err, errlen,
                        "'%.*s' does not apply to <%s> (it takes: %s)",
                        (int)nlen, name, tag_name,
                        pdfmake_style_tag_allowed(tag));

        if (!coerce(prop, value, vlen, &out->v[prop], err, errlen))
            return 0;
    }
    return 1;
}

void pdfmake_style_inherit(const pdfmake_style_t *parent,
                           const pdfmake_style_t *own,
                           pdfmake_style_t *out) {
    int i;
    pdfmake_style_init(out);

    /* Text properties pass down. Box properties - padding, background,
     * weights - stop where they are declared: a cell's padding is the
     * cell's, not that of every paragraph inside it. */
    if (parent) {
        for (i = 1; i < PDFMAKE_P_MAX; i++)
            if (parent->v[i].set && pdfmake_style_inherits((pdfmake_prop_t)i))
                out->v[i] = parent->v[i];
    }
    if (own) {
        for (i = 1; i < PDFMAKE_P_MAX; i++)
            if (own->v[i].set) out->v[i] = own->v[i];
    }
}

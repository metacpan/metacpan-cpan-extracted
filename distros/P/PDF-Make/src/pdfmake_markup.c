/*
 * pdfmake_markup.c - document markup parser.
 *
 * One pass, no backtracking, no recovery. See pdfmake_markup.h for why the
 * grammar is closed and why every failure is a hard error with a position.
 */

#include "pdfmake_markup.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdarg.h>

/*----------------------------------------------------------------------------
 * Tag table
 *--------------------------------------------------------------------------*/

typedef struct {
    const char          *name;
    pdfmake_markup_tag_t id;
    uint32_t             flags;
} tag_ent_t;

static const tag_ent_t TAGS[] = {
    { "doc",       PDFMAKE_MK_DOC,       PDFMAKE_MKF_CONTAINER },
    { "style",     PDFMAKE_MK_STYLE,     PDFMAKE_MKF_VOID },
    { "page",      PDFMAKE_MK_PAGE,      PDFMAKE_MKF_CONTAINER },
    { "pagebreak", PDFMAKE_MK_PAGEBREAK, PDFMAKE_MKF_VOID },
    { "header",    PDFMAKE_MK_HEADER,    PDFMAKE_MKF_CONTAINER },
    { "footer",    PDFMAKE_MK_FOOTER,    PDFMAKE_MKF_CONTAINER },
    { "h1",        PDFMAKE_MK_H1,        0 },
    { "h2",        PDFMAKE_MK_H2,        0 },
    { "h3",        PDFMAKE_MK_H3,        0 },
    { "h4",        PDFMAKE_MK_H4,        0 },
    { "h5",        PDFMAKE_MK_H5,        0 },
    { "h6",        PDFMAKE_MK_H6,        0 },
    { "p",         PDFMAKE_MK_P,         0 },
    { "text",      PDFMAKE_MK_TEXT,      0 },
    { "hr",        PDFMAKE_MK_HR,        PDFMAKE_MKF_VOID },
    { "box",       PDFMAKE_MK_BOX,       PDFMAKE_MKF_CONTAINER },
    { "img",       PDFMAKE_MK_IMG,       PDFMAKE_MKF_VOID },
    { "row",       PDFMAKE_MK_ROW,       PDFMAKE_MKF_CONTAINER },
    { "cell",      PDFMAKE_MK_CELL,      0 },
    { "table",     PDFMAKE_MK_TABLE,     PDFMAKE_MKF_CONTAINER },
    { "tr",        PDFMAKE_MK_TR,        PDFMAKE_MKF_CONTAINER },
    { "th",        PDFMAKE_MK_TH,        0 },
    { "td",        PDFMAKE_MK_TD,        0 },
    { "bookmark",  PDFMAKE_MK_BOOKMARK,  PDFMAKE_MKF_VOID },
    { "b",         PDFMAKE_MK_B,         PDFMAKE_MKF_INLINE },
    { "i",         PDFMAKE_MK_I,         PDFMAKE_MKF_INLINE },
    { "span",      PDFMAKE_MK_SPAN,      PDFMAKE_MKF_INLINE }
};

#define TAG_COUNT (sizeof(TAGS) / sizeof(TAGS[0]))

const char *pdfmake_markup_tag_name(pdfmake_markup_tag_t tag) {
    size_t i;
    for (i = 0; i < TAG_COUNT; i++)
        if (TAGS[i].id == tag) return TAGS[i].name;
    return NULL;
}

pdfmake_markup_tag_t pdfmake_markup_tag_id(const char *name, size_t len) {
    size_t i;
    if (!name) return PDFMAKE_MK_INVALID;
    for (i = 0; i < TAG_COUNT; i++) {
        if (strlen(TAGS[i].name) == len && memcmp(TAGS[i].name, name, len) == 0)
            return TAGS[i].id;
    }
    return PDFMAKE_MK_INVALID;
}

uint32_t pdfmake_markup_tag_flags(pdfmake_markup_tag_t tag) {
    size_t i;
    for (i = 0; i < TAG_COUNT; i++)
        if (TAGS[i].id == tag) return TAGS[i].flags;
    return 0;
}

/*----------------------------------------------------------------------------
 * Scanner state
 *--------------------------------------------------------------------------*/

typedef struct {
    const char           *p;      /* cursor */
    const char           *end;
    uint32_t              line;
    uint32_t              col;
    pdfmake_markup_doc_t *doc;
    int                   depth;
} scan_t;

static int at_end(const scan_t *s) { return s->p >= s->end; }

static char peek(const scan_t *s) { return at_end(s) ? '\0' : *s->p; }

static char peek_at(const scan_t *s, size_t off) {
    return (s->p + off >= s->end) ? '\0' : s->p[off];
}

static void advance(scan_t *s) {
    if (at_end(s)) return;
    if (*s->p == '\n') { s->line++; s->col = 1; }
    else               { s->col++; }
    s->p++;
}

static int is_space(char c) {
    return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}

/* Names are ASCII letters, digits, '-' and '_', starting with a letter. */
static int is_name_start(char c) {
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z');
}

static int is_name_char(char c) {
    return is_name_start(c) || (c >= '0' && c <= '9') || c == '-' || c == '_';
}

static void skip_space(scan_t *s) {
    while (!at_end(s) && is_space(peek(s))) advance(s);
}

/* Record the first error and stop. Later errors are noise: a parser without
 * recovery cannot say anything trustworthy about what follows. */
static void fail(scan_t *s, uint32_t line, uint32_t col, const char *fmt, ...) {
    va_list ap;
    if (!s->doc->ok) return;
    s->doc->ok = 0;
    s->doc->err_line = line;
    s->doc->err_col  = col;
    va_start(ap, fmt);
    vsnprintf(s->doc->err, PDFMAKE_MARKUP_ERR_LEN, fmt, ap);
    va_end(ap);
    s->p = s->end;              /* stop the scan */
}

/*----------------------------------------------------------------------------
 * Nodes
 *--------------------------------------------------------------------------*/

static pdfmake_markup_node_t *node_new(scan_t *s, pdfmake_markup_kind_t kind,
                                       uint32_t line, uint32_t col) {
    pdfmake_markup_node_t *n = (pdfmake_markup_node_t *)
        pdfmake_arena_calloc(s->doc->arena, sizeof(*n));
    if (!n) return NULL;
    n->kind = kind;
    n->line = line;
    n->col  = col;
    return n;
}

static void node_append(pdfmake_markup_node_t *parent,
                        pdfmake_markup_node_t *child) {
    child->parent = parent;
    if (parent->last_child) {
        parent->last_child->next_sibling = child;
        parent->last_child = child;
    } else {
        parent->first_child = parent->last_child = child;
    }
}

/*----------------------------------------------------------------------------
 * Entities
 *
 * A fixed five plus numeric character references. No entity table beyond
 * that: &nbsp; and friends are a slope that ends in an HTML spec.
 *--------------------------------------------------------------------------*/

/* Encode a code point as UTF-8 into out, returning bytes written. */
static size_t utf8_encode(uint32_t cp, char *out) {
    if (cp < 0x80) { out[0] = (char)cp; return 1; }
    if (cp < 0x800) {
        out[0] = (char)(0xC0 | (cp >> 6));
        out[1] = (char)(0x80 | (cp & 0x3F));
        return 2;
    }
    if (cp < 0x10000) {
        out[0] = (char)(0xE0 | (cp >> 12));
        out[1] = (char)(0x80 | ((cp >> 6) & 0x3F));
        out[2] = (char)(0x80 | (cp & 0x3F));
        return 3;
    }
    out[0] = (char)(0xF0 | (cp >> 18));
    out[1] = (char)(0x80 | ((cp >> 12) & 0x3F));
    out[2] = (char)(0x80 | ((cp >> 6) & 0x3F));
    out[3] = (char)(0x80 | (cp & 0x3F));
    return 4;
}

/*
 * Decode one entity at s->p (which points at '&'). Writes to out and returns
 * bytes written, or 0 on error (already reported).
 */
static size_t decode_entity(scan_t *s, char *out) {
    uint32_t line = s->line, col = s->col;
    const char *start = s->p;
    size_t n;

    advance(s);   /* '&' */

    if (peek(s) == '#') {
        uint32_t cp = 0;
        int digits = 0;
        int hex = 0;
        advance(s);
        if (peek(s) == 'x' || peek(s) == 'X') { hex = 1; advance(s); }
        while (!at_end(s) && peek(s) != ';') {
            char c = peek(s);
            uint32_t d;
            if (c >= '0' && c <= '9')                 d = (uint32_t)(c - '0');
            else if (hex && c >= 'a' && c <= 'f')     d = (uint32_t)(c - 'a' + 10);
            else if (hex && c >= 'A' && c <= 'F')     d = (uint32_t)(c - 'A' + 10);
            else {
                fail(s, line, col,
                     "bad character reference: '%c' is not a %s digit",
                     c, hex ? "hex" : "decimal");
                return 0;
            }
            if (cp > 0x10FFFF) {            /* clamp before overflow */
                fail(s, line, col, "character reference out of range");
                return 0;
            }
            cp = cp * (hex ? 16u : 10u) + d;
            digits++;
            advance(s);
        }
        if (peek(s) != ';') {
            fail(s, line, col, "unterminated character reference: missing ';'");
            return 0;
        }
        advance(s);   /* ';' */
        if (!digits) {
            fail(s, line, col, "empty character reference");
            return 0;
        }
        if (cp == 0 || cp > 0x10FFFF || (cp >= 0xD800 && cp <= 0xDFFF)) {
            fail(s, line, col,
                 "character reference is not a valid code point: %lu",
                 (unsigned long)cp);
            return 0;
        }
        return utf8_encode(cp, out);
    }

    /* Named: read up to ';' */
    {
        const char *nstart = s->p;
        size_t nlen;
        while (!at_end(s) && peek(s) != ';' && is_name_char(peek(s))) advance(s);
        nlen = (size_t)(s->p - nstart);
        if (peek(s) != ';') {
            fail(s, line, col,
                 "unterminated entity: missing ';' (write &amp; for a literal &)");
            return 0;
        }
        advance(s);   /* ';' */

        if (nlen == 2 && memcmp(nstart, "lt", 2) == 0)   { out[0] = '<';  return 1; }
        if (nlen == 2 && memcmp(nstart, "gt", 2) == 0)   { out[0] = '>';  return 1; }
        if (nlen == 3 && memcmp(nstart, "amp", 3) == 0)  { out[0] = '&';  return 1; }
        if (nlen == 4 && memcmp(nstart, "quot", 4) == 0) { out[0] = '"';  return 1; }
        if (nlen == 4 && memcmp(nstart, "apos", 4) == 0) { out[0] = '\''; return 1; }

        n = (size_t)(s->p - start);
        fail(s, line, col,
             "unknown entity '%.*s' (only &amp; &lt; &gt; &quot; &apos; and "
             "&#NNN; are defined)",
             (int)(n > 32 ? 32 : n), start);
        return 0;
    }
}

/*----------------------------------------------------------------------------
 * Text
 *--------------------------------------------------------------------------*/

/* Read a text run up to the next '<'. Returns NULL and leaves ok==0 on a bad
 * entity; returns NULL with ok==1 when the run is dropped as layout
 * whitespace. */
static pdfmake_markup_node_t *parse_text(scan_t *s,
                                         pdfmake_markup_node_t *parent) {
    uint32_t line = s->line, col = s->col;
    const char *start = s->p;
    char *buf;
    size_t cap, len = 0;
    int all_space = 1;
    pdfmake_markup_node_t *n;

    /* Decoded output is never longer than the source run. */
    {
        const char *q = s->p;
        while (q < s->end && *q != '<') q++;
        cap = (size_t)(q - s->p) + 4;
    }
    buf = (char *)pdfmake_arena_alloc(s->doc->arena, cap + 1);
    if (!buf) { fail(s, line, col, "out of memory"); return NULL; }

    while (!at_end(s) && peek(s) != '<') {
        if (peek(s) == '&') {
            size_t w = decode_entity(s, buf + len);
            if (!w) return NULL;
            len += w;
            all_space = 0;
        } else {
            char c = peek(s);
            if (!is_space(c)) all_space = 0;
            buf[len++] = c;
            advance(s);
        }
    }
    buf[len] = '\0';

    (void)start;

    /* Whitespace between the children of a container is indentation, not
     * content. Inside a text-bearing element it is a real space and has to
     * survive - "Total <b>due</b>" would otherwise lose its gap. */
    if (all_space &&
        (pdfmake_markup_tag_flags(parent->tag) & PDFMAKE_MKF_CONTAINER))
        return NULL;

    n = node_new(s, PDFMAKE_MARKUP_TEXT, line, col);
    if (!n) { fail(s, line, col, "out of memory"); return NULL; }
    n->text     = buf;
    n->text_len = len;
    return n;
}

/*----------------------------------------------------------------------------
 * Attributes
 *--------------------------------------------------------------------------*/

static pdfmake_markup_attr_t *parse_attr(scan_t *s) {
    uint32_t line = s->line, col = s->col;
    const char *nstart;
    size_t nlen;
    char quote;
    char *buf;
    size_t cap, len = 0;
    pdfmake_markup_attr_t *a;

    nstart = s->p;
    while (!at_end(s) && is_name_char(peek(s))) advance(s);
    nlen = (size_t)(s->p - nstart);
    if (!nlen) {
        fail(s, line, col, "expected an attribute name, found '%c'", peek(s));
        return NULL;
    }

    skip_space(s);
    if (peek(s) != '=') {
        fail(s, line, col,
             "attribute '%.*s' has no value (valueless attributes are not "
             "allowed; write %.*s=\"1\")",
             (int)nlen, nstart, (int)nlen, nstart);
        return NULL;
    }
    advance(s);
    skip_space(s);

    quote = peek(s);
    if (quote != '"' && quote != '\'') {
        fail(s, s->line, s->col,
             "attribute '%.*s' value must be quoted", (int)nlen, nstart);
        return NULL;
    }
    advance(s);

    {
        const char *q = s->p;
        while (q < s->end && *q != quote) q++;
        cap = (size_t)(q - s->p) + 4;
    }
    buf = (char *)pdfmake_arena_alloc(s->doc->arena, cap + 1);
    if (!buf) { fail(s, line, col, "out of memory"); return NULL; }

    while (!at_end(s) && peek(s) != quote) {
        if (peek(s) == '<') {
            /* Nearly always an unterminated quote rather than a literal '<',
             * so lead with that reading; the scanner cannot tell which, and
             * naming only the rarer cause sends the author looking in the
             * wrong place. */
            fail(s, s->line, s->col,
                 "'<' inside the value of attribute '%.*s': the opening quote "
                 "is probably unclosed (write &lt; for a literal '<')",
                 (int)nlen, nstart);
            return NULL;
        }
        if (peek(s) == '&') {
            size_t w = decode_entity(s, buf + len);
            if (!w) return NULL;
            len += w;
        } else {
            buf[len++] = peek(s);
            advance(s);
        }
    }
    if (peek(s) != quote) {
        fail(s, line, col, "unterminated value for attribute '%.*s'",
             (int)nlen, nstart);
        return NULL;
    }
    advance(s);
    buf[len] = '\0';

    a = (pdfmake_markup_attr_t *)
        pdfmake_arena_calloc(s->doc->arena, sizeof(*a));
    if (!a) { fail(s, line, col, "out of memory"); return NULL; }
    a->name      = pdfmake_arena_memdup(s->doc->arena, nstart, nlen + 1);
    if (!a->name) { fail(s, line, col, "out of memory"); return NULL; }
    ((char *)a->name)[nlen] = '\0';
    a->name_len  = nlen;
    a->value     = buf;
    a->value_len = len;
    a->line      = line;
    a->col       = col;
    return a;
}

/*----------------------------------------------------------------------------
 * Elements
 *--------------------------------------------------------------------------*/

static void parse_node(scan_t *s, pdfmake_markup_node_t *parent);

/* Comments are skipped. They are the one piece of syntax here that exists
 * purely for whoever maintains the template. */
static int skip_comment(scan_t *s) {
    uint32_t line = s->line, col = s->col;
    if (!(peek(s) == '<' && peek_at(s, 1) == '!' &&
          peek_at(s, 2) == '-' && peek_at(s, 3) == '-'))
        return 0;
    advance(s); advance(s); advance(s); advance(s);
    while (!at_end(s)) {
        if (peek(s) == '-' && peek_at(s, 1) == '-' && peek_at(s, 2) == '>') {
            advance(s); advance(s); advance(s);
            return 1;
        }
        advance(s);
    }
    fail(s, line, col, "unterminated comment: missing '-->'");
    return 1;
}

static void parse_element(scan_t *s, pdfmake_markup_node_t *parent) {
    uint32_t line = s->line, col = s->col;
    const char *nstart;
    size_t nlen;
    pdfmake_markup_tag_t tag;
    pdfmake_markup_node_t *n;
    pdfmake_markup_attr_t *last = NULL;
    int self_closing = 0;

    advance(s);   /* '<' */

    nstart = s->p;
    if (!is_name_start(peek(s))) {
        fail(s, line, col,
             "expected a tag name after '<' (write &lt; for a literal '<')");
        return;
    }
    while (!at_end(s) && is_name_char(peek(s))) advance(s);
    nlen = (size_t)(s->p - nstart);

    tag = pdfmake_markup_tag_id(nstart, nlen);
    if (tag == PDFMAKE_MK_INVALID) {
        fail(s, line, col, "unknown tag '<%.*s>'", (int)nlen, nstart);
        return;
    }

    n = node_new(s, PDFMAKE_MARKUP_ELEM, line, col);
    if (!n) { fail(s, line, col, "out of memory"); return; }
    n->tag = tag;

    /* attributes */
    for (;;) {
        skip_space(s);
        if (at_end(s)) {
            fail(s, line, col, "unterminated <%.*s>", (int)nlen, nstart);
            return;
        }
        if (peek(s) == '>') { advance(s); break; }
        if (peek(s) == '/') {
            advance(s);
            if (peek(s) != '>') {
                fail(s, s->line, s->col, "expected '>' after '/'");
                return;
            }
            advance(s);
            self_closing = 1;
            break;
        }
        {
            pdfmake_markup_attr_t *a = parse_attr(s);
            pdfmake_markup_attr_t *prev;
            if (!a) return;
            /* A repeated attribute is a typo with a silent winner. Refuse it
             * rather than pick one. */
            for (prev = n->attrs; prev; prev = prev->next) {
                if (prev->name_len == a->name_len &&
                    memcmp(prev->name, a->name, a->name_len) == 0) {
                    fail(s, a->line, a->col,
                         "duplicate attribute '%.*s' on <%.*s> (first at "
                         "line %lu)",
                         (int)a->name_len, a->name, (int)nlen, nstart,
                         (unsigned long)prev->line);
                    return;
                }
            }
            if (last) last->next = a; else n->attrs = a;
            last = a;
        }
    }

    node_append(parent, n);

    if (pdfmake_markup_tag_flags(tag) & PDFMAKE_MKF_VOID) {
        /* A void element may be written <hr/> or <hr>; either way it takes
         * no children and no close tag. */
        if (!self_closing) {
            /* <hr></hr> is tolerated. Anything else following - including a
             * close tag belonging to an ancestor - is not ours to consume, so
             * the scan position is restored and the parent decides. */
            const char *save_p = s->p;
            uint32_t save_line = s->line, save_col = s->col;
            skip_space(s);
            if (peek(s) == '<' && peek_at(s, 1) == '/') {
                const char *cstart;
                size_t clen;
                advance(s); advance(s);
                cstart = s->p;
                while (!at_end(s) && is_name_char(peek(s))) advance(s);
                clen = (size_t)(s->p - cstart);
                if (clen == nlen && memcmp(cstart, nstart, nlen) == 0) {
                    skip_space(s);
                    if (peek(s) == '>') { advance(s); return; }
                }
            }
            s->p = save_p; s->line = save_line; s->col = save_col;
        }
        return;
    }

    if (self_closing) return;

    /* children */
    if (++s->depth > PDFMAKE_MARKUP_MAX_DEPTH) {
        fail(s, line, col, "markup nested deeper than %d levels",
             PDFMAKE_MARKUP_MAX_DEPTH);
        return;
    }

    for (;;) {
        if (at_end(s)) {
            if (s->doc->ok)
                fail(s, line, col, "unclosed <%.*s> opened at line %lu",
                     (int)nlen, nstart, (unsigned long)line);
            return;
        }
        if (peek(s) == '<' && peek_at(s, 1) == '/') {
            uint32_t cline = s->line, ccol = s->col;
            const char *cstart;
            size_t clen;
            advance(s); advance(s);
            cstart = s->p;
            while (!at_end(s) && is_name_char(peek(s))) advance(s);
            clen = (size_t)(s->p - cstart);
            skip_space(s);
            if (peek(s) != '>') {
                fail(s, cline, ccol, "expected '>' to close </%.*s",
                     (int)clen, cstart);
                return;
            }
            advance(s);
            if (clen != nlen || memcmp(cstart, nstart, nlen) != 0) {
                /* A close tag naming a void element is a specific mistake
                 * with a specific fix, and deserves to be told apart from an
                 * ordinary mismatch. */
                pdfmake_markup_tag_t ctag = pdfmake_markup_tag_id(cstart, clen);
                if (ctag != PDFMAKE_MK_INVALID &&
                    (pdfmake_markup_tag_flags(ctag) & PDFMAKE_MKF_VOID)) {
                    fail(s, cline, ccol,
                         "<%.*s> takes no children: it is written <%.*s/> and "
                         "has no closing tag",
                         (int)clen, cstart, (int)clen, cstart);
                    return;
                }
                fail(s, cline, ccol,
                     "</%.*s> closes <%.*s> opened at line %lu",
                     (int)clen, cstart, (int)nlen, nstart, (unsigned long)line);
                return;
            }
            s->depth--;
            return;
        }
        parse_node(s, n);
        if (!s->doc->ok) return;
    }
}

static void parse_node(scan_t *s, pdfmake_markup_node_t *parent) {
    if (peek(s) == '<') {
        if (skip_comment(s)) return;
        if (peek_at(s, 1) == '!' || peek_at(s, 1) == '?') {
            fail(s, s->line, s->col,
                 "processing instructions and declarations are not part of "
                 "this markup");
            return;
        }
        parse_element(s, parent);
    } else {
        pdfmake_markup_node_t *t = parse_text(s, parent);
        if (t) node_append(parent, t);
    }
}

/*----------------------------------------------------------------------------
 * Entry point
 *--------------------------------------------------------------------------*/

/*
 * Validate UTF-8 before parsing, reporting the position of the first bad
 * byte. The alternative is copying invalid bytes into text nodes and letting
 * them surface as mojibake in somebody's invoice, which is precisely the
 * class of "renders slightly wrong" failure this parser exists to prevent.
 *
 * Overlong forms, surrogates and anything above U+10FFFF are rejected along
 * with truncated sequences: they are all ways of smuggling a character past
 * a checker that only looks at the shortest form.
 */
static int validate_utf8(scan_t *s, const char *p, const char *end) {
    uint32_t line = 1, col = 1;

    while (p < end) {
        unsigned char c = (unsigned char)*p;
        int extra;
        uint32_t cp;

        if (c < 0x80) {
            if (c == '\n') { line++; col = 1; } else { col++; }
            p++;
            continue;
        }

        if      ((c & 0xE0) == 0xC0) { extra = 1; cp = c & 0x1Fu; }
        else if ((c & 0xF0) == 0xE0) { extra = 2; cp = c & 0x0Fu; }
        else if ((c & 0xF8) == 0xF0) { extra = 3; cp = c & 0x07u; }
        else {
            fail(s, line, col, "invalid UTF-8: unexpected byte 0x%02X", c);
            return 0;
        }

        if (p + extra >= end) {
            fail(s, line, col, "invalid UTF-8: truncated sequence");
            return 0;
        }

        {
            int i;
            for (i = 1; i <= extra; i++) {
                unsigned char cc = (unsigned char)p[i];
                if ((cc & 0xC0) != 0x80) {
                    fail(s, line, col,
                         "invalid UTF-8: byte 0x%02X is not a continuation", cc);
                    return 0;
                }
                cp = (cp << 6) | (cc & 0x3Fu);
            }
        }

        if ((extra == 1 && cp < 0x80) ||
            (extra == 2 && cp < 0x800) ||
            (extra == 3 && cp < 0x10000)) {
            fail(s, line, col, "invalid UTF-8: overlong encoding");
            return 0;
        }
        if (cp >= 0xD800 && cp <= 0xDFFF) {
            fail(s, line, col, "invalid UTF-8: encoded surrogate U+%04lX",
                 (unsigned long)cp);
            return 0;
        }
        if (cp > 0x10FFFF) {
            fail(s, line, col, "invalid UTF-8: code point above U+10FFFF");
            return 0;
        }

        p += extra + 1;
        col++;
    }
    return 1;
}

pdfmake_markup_doc_t *pdfmake_markup_parse(const char *src, size_t len) {
    pdfmake_markup_doc_t *doc;
    scan_t s;

    doc = (pdfmake_markup_doc_t *)calloc(1, sizeof(*doc));
    if (!doc) return NULL;
    doc->arena = pdfmake_arena_new();
    if (!doc->arena) { free(doc); return NULL; }
    doc->ok = 1;

    if (!src) { src = ""; len = 0; }

    s.p     = src;
    s.end   = src + len;
    s.line  = 1;
    s.col   = 1;
    s.doc   = doc;
    s.depth = 0;

    if (!validate_utf8(&s, s.p, s.end)) return doc;

    /* Skip a UTF-8 BOM: editors add it, and it is not the author's fault. */
    if (len >= 3 && (unsigned char)src[0] == 0xEF &&
        (unsigned char)src[1] == 0xBB && (unsigned char)src[2] == 0xBF) {
        s.p += 3;
    }

    skip_space(&s);
    while (!at_end(&s) && s.doc->ok && peek(&s) == '<' &&
           peek_at(&s, 1) == '!' && peek_at(&s, 2) == '-') {
        skip_comment(&s);
        skip_space(&s);
    }

    if (at_end(&s)) {
        if (doc->ok)
            fail(&s, 1, 1, "empty document: expected <doc>");
        return doc;
    }

    if (peek(&s) != '<') {
        fail(&s, s.line, s.col, "text outside <doc>");
        return doc;
    }

    {
        /* The root must be <doc>. Checking here rather than in parse_element
         * keeps the error specific: "expected <doc>" beats "unknown tag". */
        const char *q = s.p + 1;
        size_t qlen = 0;
        while (q + qlen < s.end && is_name_char(q[qlen])) qlen++;
        if (qlen != 3 || memcmp(q, "doc", 3) != 0) {
            fail(&s, s.line, s.col,
                 "the root element must be <doc>, found '<%.*s>'",
                 (int)(qlen > 32 ? 32 : qlen), q);
            return doc;
        }
    }

    {
        pdfmake_markup_node_t *holder =
            node_new(&s, PDFMAKE_MARKUP_ELEM, 1, 1);
        if (!holder) { fail(&s, 1, 1, "out of memory"); return doc; }
        holder->tag = PDFMAKE_MK_INVALID;
        parse_element(&s, holder);
        if (doc->ok) doc->root = holder->first_child;
    }

    if (doc->ok) {
        skip_space(&s);
        while (!at_end(&s) && peek(&s) == '<' && peek_at(&s, 1) == '!' &&
               peek_at(&s, 2) == '-') {
            skip_comment(&s);
            skip_space(&s);
        }
        if (!at_end(&s))
            fail(&s, s.line, s.col, "content after </doc>");
    }

    return doc;
}

void pdfmake_markup_free(pdfmake_markup_doc_t *doc) {
    if (!doc) return;
    pdfmake_arena_free(doc->arena);
    free(doc);
}

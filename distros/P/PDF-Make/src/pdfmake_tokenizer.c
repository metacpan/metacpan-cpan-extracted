/*
 * pdfmake_tokenizer.c — PDF lexical tokenizer per §7.2
 */

#include "pdfmake_tokenizer.h"
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

/*============================================================================
 * Character classification table (§7.2.2)
 *
 * PDF whitespace:  NUL(0), TAB(9), LF(10), FF(12), CR(13), SPACE(32)
 * PDF delimiters:  ( ) < > [ ] { } / %
 *==========================================================================*/

const uint8_t pdfmake_char_class[256] = {
    /* 0x00-0x0F */
    PDFMAKE_CC_WHITESPACE,  /* NUL */
    PDFMAKE_CC_REGULAR,     /* SOH */
    PDFMAKE_CC_REGULAR,     /* STX */
    PDFMAKE_CC_REGULAR,     /* ETX */
    PDFMAKE_CC_REGULAR,     /* EOT */
    PDFMAKE_CC_REGULAR,     /* ENQ */
    PDFMAKE_CC_REGULAR,     /* ACK */
    PDFMAKE_CC_REGULAR,     /* BEL */
    PDFMAKE_CC_REGULAR,     /* BS */
    PDFMAKE_CC_WHITESPACE,  /* TAB */
    PDFMAKE_CC_WHITESPACE,  /* LF */
    PDFMAKE_CC_REGULAR,     /* VT */
    PDFMAKE_CC_WHITESPACE,  /* FF */
    PDFMAKE_CC_WHITESPACE,  /* CR */
    PDFMAKE_CC_REGULAR,     /* SO */
    PDFMAKE_CC_REGULAR,     /* SI */

    /* 0x10-0x1F */
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,

    /* 0x20-0x2F: SPACE ! " # $ % & ' ( ) * + , - . / */
    PDFMAKE_CC_WHITESPACE,                           /* SPACE */
    PDFMAKE_CC_REGULAR,                              /* ! */
    PDFMAKE_CC_REGULAR,                              /* " */
    PDFMAKE_CC_REGULAR,                              /* # */
    PDFMAKE_CC_REGULAR,                              /* $ */
    PDFMAKE_CC_DELIMITER,                            /* % comment start */
    PDFMAKE_CC_REGULAR,                              /* & */
    PDFMAKE_CC_REGULAR,                              /* ' */
    PDFMAKE_CC_DELIMITER,                            /* ( */
    PDFMAKE_CC_DELIMITER,                            /* ) */
    PDFMAKE_CC_REGULAR,                              /* * */
    PDFMAKE_CC_SIGN,                                 /* + */
    PDFMAKE_CC_REGULAR,                              /* , */
    PDFMAKE_CC_SIGN,                                 /* - */
    PDFMAKE_CC_REGULAR,                              /* . */
    PDFMAKE_CC_DELIMITER,                            /* / name start */

    /* 0x30-0x3F: 0-9 : ; < = > ? */
    PDFMAKE_CC_DIGIT | PDFMAKE_CC_HEX,  /* 0 */
    PDFMAKE_CC_DIGIT | PDFMAKE_CC_HEX,  /* 1 */
    PDFMAKE_CC_DIGIT | PDFMAKE_CC_HEX,  /* 2 */
    PDFMAKE_CC_DIGIT | PDFMAKE_CC_HEX,  /* 3 */
    PDFMAKE_CC_DIGIT | PDFMAKE_CC_HEX,  /* 4 */
    PDFMAKE_CC_DIGIT | PDFMAKE_CC_HEX,  /* 5 */
    PDFMAKE_CC_DIGIT | PDFMAKE_CC_HEX,  /* 6 */
    PDFMAKE_CC_DIGIT | PDFMAKE_CC_HEX,  /* 7 */
    PDFMAKE_CC_DIGIT | PDFMAKE_CC_HEX,  /* 8 */
    PDFMAKE_CC_DIGIT | PDFMAKE_CC_HEX,  /* 9 */
    PDFMAKE_CC_REGULAR,                 /* : */
    PDFMAKE_CC_REGULAR,                 /* ; */
    PDFMAKE_CC_DELIMITER,               /* < */
    PDFMAKE_CC_REGULAR,                 /* = */
    PDFMAKE_CC_DELIMITER,               /* > */
    PDFMAKE_CC_REGULAR,                 /* ? */

    /* 0x40-0x4F: @ A-O */
    PDFMAKE_CC_REGULAR,                              /* @ */
    PDFMAKE_CC_ALPHA | PDFMAKE_CC_HEX,  /* A */
    PDFMAKE_CC_ALPHA | PDFMAKE_CC_HEX,  /* B */
    PDFMAKE_CC_ALPHA | PDFMAKE_CC_HEX,  /* C */
    PDFMAKE_CC_ALPHA | PDFMAKE_CC_HEX,  /* D */
    PDFMAKE_CC_ALPHA | PDFMAKE_CC_HEX,  /* E */
    PDFMAKE_CC_ALPHA | PDFMAKE_CC_HEX,  /* F */
    PDFMAKE_CC_ALPHA,  /* G */
    PDFMAKE_CC_ALPHA,  /* H */
    PDFMAKE_CC_ALPHA,  /* I */
    PDFMAKE_CC_ALPHA,  /* J */
    PDFMAKE_CC_ALPHA,  /* K */
    PDFMAKE_CC_ALPHA,  /* L */
    PDFMAKE_CC_ALPHA,  /* M */
    PDFMAKE_CC_ALPHA,  /* N */
    PDFMAKE_CC_ALPHA,  /* O */

    /* 0x50-0x5F: P-Z [ \ ] ^ _ */
    PDFMAKE_CC_ALPHA,  /* P */
    PDFMAKE_CC_ALPHA,  /* Q */
    PDFMAKE_CC_ALPHA,  /* R */
    PDFMAKE_CC_ALPHA,  /* S */
    PDFMAKE_CC_ALPHA,  /* T */
    PDFMAKE_CC_ALPHA,  /* U */
    PDFMAKE_CC_ALPHA,  /* V */
    PDFMAKE_CC_ALPHA,  /* W */
    PDFMAKE_CC_ALPHA,  /* X */
    PDFMAKE_CC_ALPHA,  /* Y */
    PDFMAKE_CC_ALPHA,  /* Z */
    PDFMAKE_CC_DELIMITER,  /* [ */
    PDFMAKE_CC_REGULAR,    /* \ */
    PDFMAKE_CC_DELIMITER,  /* ] */
    PDFMAKE_CC_REGULAR,    /* ^ */
    PDFMAKE_CC_REGULAR,    /* _ */

    /* 0x60-0x6F: ` a-o */
    PDFMAKE_CC_REGULAR,                              /* ` */
    PDFMAKE_CC_ALPHA | PDFMAKE_CC_HEX,  /* a */
    PDFMAKE_CC_ALPHA | PDFMAKE_CC_HEX,  /* b */
    PDFMAKE_CC_ALPHA | PDFMAKE_CC_HEX,  /* c */
    PDFMAKE_CC_ALPHA | PDFMAKE_CC_HEX,  /* d */
    PDFMAKE_CC_ALPHA | PDFMAKE_CC_HEX,  /* e */
    PDFMAKE_CC_ALPHA | PDFMAKE_CC_HEX,  /* f */
    PDFMAKE_CC_ALPHA,  /* g */
    PDFMAKE_CC_ALPHA,  /* h */
    PDFMAKE_CC_ALPHA,  /* i */
    PDFMAKE_CC_ALPHA,  /* j */
    PDFMAKE_CC_ALPHA,  /* k */
    PDFMAKE_CC_ALPHA,  /* l */
    PDFMAKE_CC_ALPHA,  /* m */
    PDFMAKE_CC_ALPHA,  /* n */
    PDFMAKE_CC_ALPHA,  /* o */

    /* 0x70-0x7F: p-z { | } ~ DEL */
    PDFMAKE_CC_ALPHA,  /* p */
    PDFMAKE_CC_ALPHA,  /* q */
    PDFMAKE_CC_ALPHA,  /* r */
    PDFMAKE_CC_ALPHA,  /* s */
    PDFMAKE_CC_ALPHA,  /* t */
    PDFMAKE_CC_ALPHA,  /* u */
    PDFMAKE_CC_ALPHA,  /* v */
    PDFMAKE_CC_ALPHA,  /* w */
    PDFMAKE_CC_ALPHA,  /* x */
    PDFMAKE_CC_ALPHA,  /* y */
    PDFMAKE_CC_ALPHA,  /* z */
    PDFMAKE_CC_DELIMITER,  /* { */
    PDFMAKE_CC_REGULAR,    /* | */
    PDFMAKE_CC_DELIMITER,  /* } */
    PDFMAKE_CC_REGULAR,    /* ~ */
    PDFMAKE_CC_REGULAR,    /* DEL */

    /* 0x80-0xFF: High bytes - all regular in PDF */
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
    PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR, PDFMAKE_CC_REGULAR,
};

/*============================================================================
 * Token kind names (for debugging)
 *==========================================================================*/

static const char *tok_kind_names[] = {
    "EOF", "WS", "COMMENT",
    "INT", "REAL", "NAME", "LSTR", "HSTR",
    "ARR_OPEN", "ARR_CLOSE", "DICT_OPEN", "DICT_CLOSE",
    "KW_NULL", "KW_TRUE", "KW_FALSE",
    "KW_OBJ", "KW_ENDOBJ", "KW_STREAM", "KW_ENDSTREAM",
    "KW_R", "KW_XREF", "KW_TRAILER", "KW_STARTXREF",
    "ERROR"
};

const char *pdfmake_tok_kind_name(pdfmake_tok_kind_t kind) {
    if (kind >= 0 && kind <= PDFMAKE_TOK_ERROR) {
        return tok_kind_names[kind];
    }
    return "UNKNOWN";
}

/*============================================================================
 * Tokenizer initialization
 *==========================================================================*/

void pdfmake_tokenizer_init(pdfmake_tokenizer_t *t,
                            const uint8_t *buf, size_t len) {
    t->buf = buf;
    t->pos = 0;
    t->len = len;
    t->has_peeked = 0;
}

void pdfmake_tokenizer_seek(pdfmake_tokenizer_t *t, size_t pos) {
    t->pos = pos < t->len ? pos : t->len;
    t->has_peeked = 0;  /* Invalidate peek cache */
}

/*============================================================================
 * Whitespace lexer (§7.2.2)
 *==========================================================================*/

static pdfmake_tok_t lex_whitespace(pdfmake_tokenizer_t *t) {
    pdfmake_tok_t tok;
    tok.kind = PDFMAKE_TOK_WS;
    tok.offset = t->pos;

    while (t->pos < t->len && pdfmake_is_whitespace(t->buf[t->pos])) {
        t->pos++;
    }

    tok.length = t->pos - tok.offset;
    return tok;
}

/*============================================================================
 * Comment lexer (§7.2.3)
 * % through end of line (LF or CR or CRLF)
 *==========================================================================*/

static pdfmake_tok_t lex_comment(pdfmake_tokenizer_t *t) {
    pdfmake_tok_t tok;
    tok.kind = PDFMAKE_TOK_COMMENT;
    tok.offset = t->pos;

    t->pos++;  /* Skip % */

    while (t->pos < t->len) {
        uint8_t c = t->buf[t->pos];
        if (c == '\n') {
            t->pos++;
            break;
        }
        if (c == '\r') {
            t->pos++;
            if (t->pos < t->len && t->buf[t->pos] == '\n') {
                t->pos++;
            }
            break;
        }
        t->pos++;
    }

    tok.length = t->pos - tok.offset;
    return tok;
}

/*============================================================================
 * Number lexer (§7.3.3)
 * Integers: [+-]?\d+
 * Reals: [+-]?\d*\.\d* (at least one digit somewhere)
 * No scientific notation in PDF.
 *==========================================================================*/

static pdfmake_tok_t lex_number(pdfmake_tokenizer_t *t) {
    pdfmake_tok_t tok;
    int is_real = 0;
    int has_digits = 0;
    int is_negative = 0;
    double val = 0.0;
    double frac = 0.0;
    double frac_div = 1.0;
    int in_frac = 0;
    int64_t ival = 0;
    size_t i;

    tok.offset = t->pos;

    /* Optional sign */
    if (t->pos < t->len && (t->buf[t->pos] == '+' || t->buf[t->pos] == '-')) {
        if (t->buf[t->pos] == '-') is_negative = 1;
        t->pos++;
    }

    /* Digits before decimal point */
    while (t->pos < t->len && pdfmake_is_digit(t->buf[t->pos])) {
        has_digits = 1;
        t->pos++;
    }

    /* Decimal point */
    if (t->pos < t->len && t->buf[t->pos] == '.') {
        is_real = 1;
        t->pos++;

        /* Digits after decimal point */
        while (t->pos < t->len && pdfmake_is_digit(t->buf[t->pos])) {
            has_digits = 1;
            t->pos++;
        }
    }

    tok.length = t->pos - tok.offset;

    if (!has_digits) {
        /* Just a sign or just a dot — error */
        tok.kind = PDFMAKE_TOK_ERROR;
        return tok;
    }

    /* Parse the number */
    if (is_real) {
        tok.kind = PDFMAKE_TOK_REAL;
        /* Parse directly — no need for strtod locale issues */
        for (i = tok.offset; i < tok.offset + tok.length; i++) {
            uint8_t c = t->buf[i];
            if (c == '+' || c == '-') continue;
            if (c == '.') {
                in_frac = 1;
                continue;
            }
            if (in_frac) {
                frac_div *= 10.0;
                frac += (c - '0') / frac_div;
            } else {
                val = val * 10.0 + (c - '0');
            }
        }
        tok.payload.real_val = is_negative ? -(val + frac) : (val + frac);
    } else {
        tok.kind = PDFMAKE_TOK_INT;
        for (i = tok.offset; i < tok.offset + tok.length; i++) {
            uint8_t c = t->buf[i];
            if (c == '+' || c == '-') continue;
            ival = ival * 10 + (c - '0');
        }
        tok.payload.int_val = is_negative ? -ival : ival;
    }

    return tok;
}

/*============================================================================
 * Name lexer (§7.3.5)
 * /Name with #XX hex escape
 *==========================================================================*/

static pdfmake_tok_t lex_name(pdfmake_tokenizer_t *t) {
    pdfmake_tok_t tok;
    tok.kind = PDFMAKE_TOK_NAME;
    tok.offset = t->pos;

    t->pos++;  /* Skip / */

    /* Name continues until whitespace or delimiter */
    while (t->pos < t->len) {
        uint8_t c = t->buf[t->pos];
        if (pdfmake_is_whitespace(c) || pdfmake_is_delimiter(c)) {
            break;
        }
        if (c == '#') {
            /* Hex escape: skip #XX */
            if (t->pos + 2 < t->len &&
                pdfmake_is_hex(t->buf[t->pos + 1]) &&
                pdfmake_is_hex(t->buf[t->pos + 2])) {
                t->pos += 3;
            } else {
                /* Invalid escape — treat # as regular char */
                t->pos++;
            }
        } else {
            t->pos++;
        }
    }

    tok.length = t->pos - tok.offset;
    return tok;
}

/*============================================================================
 * Literal string lexer (§7.3.4.2)
 * (string) with balanced parens and escapes
 *==========================================================================*/

static pdfmake_tok_t lex_literal_string(pdfmake_tokenizer_t *t) {
    pdfmake_tok_t tok;
    int depth;
    tok.kind = PDFMAKE_TOK_LSTR;
    tok.offset = t->pos;

    t->pos++;  /* Skip opening ( */
    depth = 1;

    while (t->pos < t->len && depth > 0) {
        uint8_t c = t->buf[t->pos];

        if (c == '(') {
            depth++;
            t->pos++;
        } else if (c == ')') {
            depth--;
            t->pos++;
        } else if (c == '\\') {
            /* Escape sequence */
            t->pos++;
            if (t->pos < t->len) {
                uint8_t esc = t->buf[t->pos];
                if (esc >= '0' && esc <= '7') {
                    /* Octal: 1-3 digits */
                    t->pos++;
                    if (t->pos < t->len && t->buf[t->pos] >= '0' && t->buf[t->pos] <= '7') {
                        t->pos++;
                        if (t->pos < t->len && t->buf[t->pos] >= '0' && t->buf[t->pos] <= '7') {
                            t->pos++;
                        }
                    }
                } else if (esc == '\r') {
                    /* Line continuation: \CR or \CRLF */
                    t->pos++;
                    if (t->pos < t->len && t->buf[t->pos] == '\n') {
                        t->pos++;
                    }
                } else if (esc == '\n') {
                    /* Line continuation: \LF */
                    t->pos++;
                } else {
                    /* Single-char escape: n r t b f ( ) \ or unknown */
                    t->pos++;
                }
            }
        } else {
            t->pos++;
        }
    }

    tok.length = t->pos - tok.offset;

    if (depth != 0) {
        /* Unbalanced parens */
        tok.kind = PDFMAKE_TOK_ERROR;
    }

    return tok;
}

/*============================================================================
 * Hex string lexer (§7.3.4.3)
 * <hex> with whitespace ignored
 *==========================================================================*/

static pdfmake_tok_t lex_hex_string(pdfmake_tokenizer_t *t) {
    pdfmake_tok_t tok;
    tok.kind = PDFMAKE_TOK_HSTR;
    tok.offset = t->pos;

    t->pos++;  /* Skip < */

    while (t->pos < t->len) {
        uint8_t c = t->buf[t->pos];

        if (c == '>') {
            t->pos++;
            break;
        }

        /* Skip whitespace inside hex string */
        if (pdfmake_is_whitespace(c)) {
            t->pos++;
            continue;
        }

        /* Must be hex digit */
        if (!pdfmake_is_hex(c)) {
            /* Invalid character in hex string */
            tok.kind = PDFMAKE_TOK_ERROR;
            t->pos++;
            break;
        }

        t->pos++;
    }

    tok.length = t->pos - tok.offset;
    return tok;
}

/*============================================================================
 * Keyword/identifier lexer
 * Identifies: null, true, false, obj, endobj, stream, endstream, R,
 *             xref, trailer, startxref
 *==========================================================================*/

/* Keyword table for fast lookup */
typedef struct {
    const char    *text;
    size_t         len;
    pdfmake_tok_kind_t kind;
} keyword_entry_t;

static const keyword_entry_t keywords[] = {
    {"null",       4, PDFMAKE_TOK_KW_NULL},
    {"true",       4, PDFMAKE_TOK_KW_TRUE},
    {"false",      5, PDFMAKE_TOK_KW_FALSE},
    {"obj",        3, PDFMAKE_TOK_KW_OBJ},
    {"endobj",     6, PDFMAKE_TOK_KW_ENDOBJ},
    {"stream",     6, PDFMAKE_TOK_KW_STREAM},
    {"endstream",  9, PDFMAKE_TOK_KW_ENDSTREAM},
    {"R",          1, PDFMAKE_TOK_KW_R},
    {"xref",       4, PDFMAKE_TOK_KW_XREF},
    {"trailer",    7, PDFMAKE_TOK_KW_TRAILER},
    {"startxref", 9, PDFMAKE_TOK_KW_STARTXREF},
    {NULL,         0, PDFMAKE_TOK_ERROR}
};

static pdfmake_tok_t lex_keyword_or_error(pdfmake_tokenizer_t *t) {
    pdfmake_tok_t tok;
    const keyword_entry_t *kw;
    tok.offset = t->pos;

    /* Read until whitespace or delimiter */
    while (t->pos < t->len && pdfmake_is_regular(t->buf[t->pos])) {
        t->pos++;
    }

    tok.length = t->pos - tok.offset;

    /* Check against keyword table */
    for (kw = keywords; kw->text != NULL; kw++) {
        if (tok.length == kw->len &&
            memcmp(t->buf + tok.offset, kw->text, kw->len) == 0) {
            tok.kind = kw->kind;

            /* For 'stream', compute body offset */
            if (tok.kind == PDFMAKE_TOK_KW_STREAM) {
                /* §7.3.8.1: stream keyword followed by EOL (LF or CRLF)
                 * Body starts after the EOL */
                size_t body_start = t->pos;

                /* Skip optional whitespace before EOL (lenient) */
                while (body_start < t->len &&
                       (t->buf[body_start] == ' ' || t->buf[body_start] == '\t')) {
                    body_start++;
                }

                /* Must have EOL */
                if (body_start < t->len && t->buf[body_start] == '\r') {
                    body_start++;
                    if (body_start < t->len && t->buf[body_start] == '\n') {
                        body_start++;
                    }
                    /* Note: CR alone is technically not spec-compliant but
                     * we accept it for Adobe compatibility */
                } else if (body_start < t->len && t->buf[body_start] == '\n') {
                    body_start++;
                }

                tok.payload.body_offset = body_start;
            }

            return tok;
        }
    }

    /* Not a keyword — error (bare identifier not valid in PDF) */
    tok.kind = PDFMAKE_TOK_ERROR;
    return tok;
}

/*============================================================================
 * Main tokenizer
 *==========================================================================*/

pdfmake_tok_t pdfmake_tok_next(pdfmake_tokenizer_t *t) {
    pdfmake_tok_t tok;
    uint8_t c;
    /* Return peeked token if available */
    if (t->has_peeked) {
        t->has_peeked = 0;
        return t->peeked;
    }

    /* EOF check */
    if (t->pos >= t->len) {
        tok.kind = PDFMAKE_TOK_EOF;
        tok.offset = t->len;
        tok.length = 0;
        return tok;
    }

    c = t->buf[t->pos];

    /* Whitespace */
    if (pdfmake_is_whitespace(c)) {
        return lex_whitespace(t);
    }

    /* Comment */
    if (c == '%') {
        return lex_comment(t);
    }

    /* Number (starts with digit, +, -, or .) */
    if (pdfmake_is_digit(c) ||
        ((c == '+' || c == '-' || c == '.') &&
         t->pos + 1 < t->len &&
         (pdfmake_is_digit(t->buf[t->pos + 1]) || t->buf[t->pos + 1] == '.'))) {
        return lex_number(t);
    }

    /* Name */
    if (c == '/') {
        return lex_name(t);
    }

    /* Literal string */
    if (c == '(') {
        return lex_literal_string(t);
    }

    /* Hex string or dict delimiter */
    if (c == '<') {
        if (t->pos + 1 < t->len && t->buf[t->pos + 1] == '<') {
            /* << dict open */
            tok.kind = PDFMAKE_TOK_DICT_OPEN;
            tok.offset = t->pos;
            tok.length = 2;
            t->pos += 2;
            return tok;
        }
        return lex_hex_string(t);
    }

    /* Dict close */
    if (c == '>') {
        if (t->pos + 1 < t->len && t->buf[t->pos + 1] == '>') {
            tok.kind = PDFMAKE_TOK_DICT_CLOSE;
            tok.offset = t->pos;
            tok.length = 2;
            t->pos += 2;
            return tok;
        }
        /* Lone > is an error */
        tok.kind = PDFMAKE_TOK_ERROR;
        tok.offset = t->pos;
        tok.length = 1;
        t->pos++;
        return tok;
    }

    /* Array delimiters */
    if (c == '[') {
        tok.kind = PDFMAKE_TOK_ARR_OPEN;
        tok.offset = t->pos;
        tok.length = 1;
        t->pos++;
        return tok;
    }

    if (c == ']') {
        tok.kind = PDFMAKE_TOK_ARR_CLOSE;
        tok.offset = t->pos;
        tok.length = 1;
        t->pos++;
        return tok;
    }

    /* Braces (not used in PDF content, but are delimiters) */
    if (c == '{' || c == '}') {
        tok.kind = PDFMAKE_TOK_ERROR;
        tok.offset = t->pos;
        tok.length = 1;
        t->pos++;
        return tok;
    }

    /* Close paren without open (error) */
    if (c == ')') {
        tok.kind = PDFMAKE_TOK_ERROR;
        tok.offset = t->pos;
        tok.length = 1;
        t->pos++;
        return tok;
    }

    /* Keyword or unknown identifier */
    return lex_keyword_or_error(t);
}

/*============================================================================
 * Peek
 *==========================================================================*/

void pdfmake_tok_peek(pdfmake_tokenizer_t *t, pdfmake_tok_t *out) {
    if (!t->has_peeked) {
        t->peeked = pdfmake_tok_next(t);
        t->has_peeked = 1;
    }
    *out = t->peeked;
}

/*============================================================================
 * Skip whitespace/comments
 *==========================================================================*/

pdfmake_tok_t pdfmake_tok_next_significant(pdfmake_tokenizer_t *t) {
    pdfmake_tok_t tok;
    do {
        tok = pdfmake_tok_next(t);
    } while (tok.kind == PDFMAKE_TOK_WS || tok.kind == PDFMAKE_TOK_COMMENT);
    return tok;
}

void pdfmake_tok_peek_significant(pdfmake_tokenizer_t *t, pdfmake_tok_t *out) {
    /* Skip whitespace/comments, then peek */
    while (1) {
        pdfmake_tok_peek(t, out);
        if (out->kind != PDFMAKE_TOK_WS && out->kind != PDFMAKE_TOK_COMMENT) {
            break;
        }
        pdfmake_tok_next(t);  /* Consume and continue */
    }
}

/*
 * pdfmake_tokenizer.h — PDF lexical tokenizer per §7.2
 *
 * Splits a raw PDF byte buffer into tokens:
 * (kind, start_offset, length, payload)
 *
 * This is the innermost hot loop of parsing — keep it fast and tight.
 */

#ifndef PDFMAKE_TOKENIZER_H
#define PDFMAKE_TOKENIZER_H

#include <stdint.h>
#include <stddef.h>
#include "pdfmake_types.h"

/*============================================================================
 * Token kinds — per §7.2 lexical conventions
 *==========================================================================*/

typedef enum {
    PDFMAKE_TOK_EOF = 0,         /* End of input */
    PDFMAKE_TOK_WS,              /* Whitespace (§7.2.2) */
    PDFMAKE_TOK_COMMENT,         /* Comment % through EOL (§7.2.3) */

    /* Scalars */
    PDFMAKE_TOK_INT,             /* Integer: optional sign + digits */
    PDFMAKE_TOK_REAL,            /* Real: fixed-point with decimal point */
    PDFMAKE_TOK_NAME,            /* /Name (§7.3.5) */
    PDFMAKE_TOK_LSTR,            /* Literal string (string) (§7.3.4.2) */
    PDFMAKE_TOK_HSTR,            /* Hex string <hex> (§7.3.4.3) */

    /* Delimiters */
    PDFMAKE_TOK_ARR_OPEN,        /* [ */
    PDFMAKE_TOK_ARR_CLOSE,       /* ] */
    PDFMAKE_TOK_DICT_OPEN,       /* << */
    PDFMAKE_TOK_DICT_CLOSE,      /* >> */

    /* Keywords */
    PDFMAKE_TOK_KW_NULL,         /* null */
    PDFMAKE_TOK_KW_TRUE,         /* true */
    PDFMAKE_TOK_KW_FALSE,        /* false */
    PDFMAKE_TOK_KW_OBJ,          /* obj */
    PDFMAKE_TOK_KW_ENDOBJ,       /* endobj */
    PDFMAKE_TOK_KW_STREAM,       /* stream (followed by stream body) */
    PDFMAKE_TOK_KW_ENDSTREAM,    /* endstream */
    PDFMAKE_TOK_KW_R,            /* R (indirect reference marker) */
    PDFMAKE_TOK_KW_XREF,         /* xref */
    PDFMAKE_TOK_KW_TRAILER,      /* trailer */
    PDFMAKE_TOK_KW_STARTXREF,    /* startxref */

    /* Error */
    PDFMAKE_TOK_ERROR            /* Unexpected byte / malformed token */
} pdfmake_tok_kind_t;

/*============================================================================
 * Token structure — keep small (fits in register pair)
 *==========================================================================*/

typedef struct {
    pdfmake_tok_kind_t kind;     /* Token type */
    size_t             offset;   /* Byte offset in source buffer */
    size_t             length;   /* Byte length of token */
    /* For STREAM tokens, payload is offset where stream body starts */
    /* For numbers, the raw bytes can be re-parsed from offset/length */
    union {
        int64_t  int_val;        /* Parsed integer value */
        double   real_val;       /* Parsed real value */
        size_t   body_offset;    /* Stream body start offset */
    } payload;
} pdfmake_tok_t;

/*============================================================================
 * Tokenizer state
 *==========================================================================*/

typedef struct {
    const uint8_t *buf;          /* Source buffer (not owned) */
    size_t         pos;          /* Current position */
    size_t         len;          /* Buffer length */

    /* Peek state (for O(1) lookahead) */
    pdfmake_tok_t  peeked;
    int            has_peeked;
} pdfmake_tokenizer_t;

/*============================================================================
 * API
 *==========================================================================*/

/*
 * Initialize tokenizer with a byte buffer.
 * The buffer is not copied — caller must keep it alive.
 */
void pdfmake_tokenizer_init(pdfmake_tokenizer_t *t,
                            const uint8_t *buf, size_t len);

/*
 * Get the next token.
 * Returns PDFMAKE_TOK_EOF when no more tokens.
 */
pdfmake_tok_t pdfmake_tok_next(pdfmake_tokenizer_t *t);

/*
 * Peek at the next token without consuming it.
 * O(1) — caches the result.
 */
void pdfmake_tok_peek(pdfmake_tokenizer_t *t, pdfmake_tok_t *out);

/*
 * Get next significant token (skips whitespace and comments).
 */
pdfmake_tok_t pdfmake_tok_next_significant(pdfmake_tokenizer_t *t);

/*
 * Peek at next significant token.
 */
void pdfmake_tok_peek_significant(pdfmake_tokenizer_t *t, pdfmake_tok_t *out);

/*
 * Get token kind name for debugging.
 */
const char *pdfmake_tok_kind_name(pdfmake_tok_kind_t kind);

/*
 * Skip to position (for seeking after reading stream body).
 */
void pdfmake_tokenizer_seek(pdfmake_tokenizer_t *t, size_t pos);

/*============================================================================
 * Character classification (exported for tests)
 *==========================================================================*/

/* Character class bits */
#define PDFMAKE_CC_REGULAR    0x00   /* Regular character */
#define PDFMAKE_CC_WHITESPACE 0x01   /* NUL, TAB, LF, FF, CR, SPACE (§7.2.2) */
#define PDFMAKE_CC_DELIMITER  0x02   /* ( ) < > [ ] { } / % (§7.2.2) */
#define PDFMAKE_CC_DIGIT      0x04   /* 0-9 */
#define PDFMAKE_CC_HEX        0x08   /* 0-9 A-F a-f */
#define PDFMAKE_CC_ALPHA      0x10   /* A-Z a-z */
#define PDFMAKE_CC_SIGN       0x20   /* + - */

/* Character class lookup table */
extern const uint8_t pdfmake_char_class[256];

/* Inline helpers */
static PDFMAKE_INLINE int pdfmake_is_whitespace(uint8_t c) {
    return (pdfmake_char_class[c] & PDFMAKE_CC_WHITESPACE) != 0;
}

static PDFMAKE_INLINE int pdfmake_is_delimiter(uint8_t c) {
    return (pdfmake_char_class[c] & PDFMAKE_CC_DELIMITER) != 0;
}

static PDFMAKE_INLINE int pdfmake_is_digit(uint8_t c) {
    return (pdfmake_char_class[c] & PDFMAKE_CC_DIGIT) != 0;
}

static PDFMAKE_INLINE int pdfmake_is_hex(uint8_t c) {
    return (pdfmake_char_class[c] & PDFMAKE_CC_HEX) != 0;
}

static PDFMAKE_INLINE int pdfmake_is_regular(uint8_t c) {
    return (pdfmake_char_class[c] & (PDFMAKE_CC_WHITESPACE | PDFMAKE_CC_DELIMITER)) == 0;
}

#endif /* PDFMAKE_TOKENIZER_H */

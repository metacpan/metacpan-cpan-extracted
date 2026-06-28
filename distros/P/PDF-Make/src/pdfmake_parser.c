/*
 * pdfmake_parser.c — PDF object parser + cross-reference reader
 *
 * Implementation of recursive-descent parser for PDF objects and
 * xref table/stream parsing.
 */

#include "pdfmake_parser.h"
#include "pdfmake_filter.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

/*============================================================================
 * Internal helpers
 *==========================================================================*/

/* Set error state */
static void set_error(pdfmake_parser_t *p, pdfmake_err_t err, 
                      size_t offset, const char *msg) {
    p->last_err = err;
    p->err_offset = offset;
    if (msg) {
        strncpy(p->err_msg, msg, sizeof(p->err_msg) - 1);
        p->err_msg[sizeof(p->err_msg) - 1] = '\0';
    } else {
        p->err_msg[0] = '\0';
    }
}

/* Ensure xref table has capacity for object num */
static int ensure_xref_cap(pdfmake_parser_t *p, uint32_t num) {
    size_t new_cap;
    pdfmake_xref_entry_t *new_xref;

    if (num < p->xref_cap) return 1;
    
    new_cap = p->xref_cap ? p->xref_cap * 2 : 64;
    while (new_cap <= num) new_cap *= 2;
    
    new_xref = realloc(p->xref, new_cap * sizeof(pdfmake_xref_entry_t));
    if (!new_xref) return 0;
    
    /* Zero new entries */
    memset(new_xref + p->xref_cap, 0, (new_cap - p->xref_cap) * sizeof(pdfmake_xref_entry_t));
    p->xref = new_xref;
    p->xref_cap = new_cap;
    return 1;
}

/* Check if offset was already visited in /Prev chain (cycle detection) */
static int prev_visited(pdfmake_parser_t *p, uint64_t offset) {
    size_t i;
    for (i = 0; i < p->prev_count; i++) {
        if (p->prev_offsets[i] == offset) return 1;
    }
    return 0;
}

/* Add offset to /Prev visited list */
static int prev_add(pdfmake_parser_t *p, uint64_t offset) {
    if (p->prev_count >= p->prev_cap) {
        size_t new_cap = p->prev_cap ? p->prev_cap * 2 : 8;
        uint64_t *new_arr = realloc(p->prev_offsets, new_cap * sizeof(uint64_t));
        if (!new_arr) return 0;
        p->prev_offsets = new_arr;
        p->prev_cap = new_cap;
    }
    p->prev_offsets[p->prev_count++] = offset;
    return 1;
}

/* Get interned name ID from arena */
static uint32_t intern_name(pdfmake_parser_t *p, const char *bytes, size_t len) {
    return pdfmake_arena_intern_name(p->doc->arena, bytes, len);
}

/* Decode hex digit */
static int hex_digit(int c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

/*============================================================================
 * Parser lifecycle
 *==========================================================================*/

pdfmake_parser_t *pdfmake_parser_new(const uint8_t *buf, size_t len) {
    pdfmake_parser_t *p = calloc(1, sizeof(pdfmake_parser_t));
    if (!p) return NULL;
    
    p->buf = buf;
    p->buf_len = len;
    pdfmake_tokenizer_init(&p->tok, buf, len);
    
    p->doc = pdfmake_doc_new();
    if (!p->doc) {
        free(p);
        return NULL;
    }
    
    return p;
}

void pdfmake_parser_free(pdfmake_parser_t *parser) {
    if (!parser) return;
    free(parser->xref);
    free(parser->prev_offsets);
    /* Note: does NOT free doc - caller owns it */
    free(parser);
}

void pdfmake_parser_set_repair(pdfmake_parser_t *parser, int enable) {
    if (parser) parser->repair = enable ? 1 : 0;
}

const char *pdfmake_parser_errmsg(pdfmake_parser_t *parser) {
    return parser ? parser->err_msg : "NULL parser";
}

size_t pdfmake_parser_erroffset(pdfmake_parser_t *parser) {
    return parser ? parser->err_offset : 0;
}

/*============================================================================
 * PDF header validation
 *==========================================================================*/

pdfmake_err_t pdfmake_check_header(pdfmake_parser_t *p, int *major, int *minor) {
    /* Look for %PDF-N.M in first 1024 bytes */
    const char *needle = "%PDF-";
    size_t search_len = p->buf_len < 1024 ? p->buf_len : 1024;
    const uint8_t *found = NULL;
    int maj = 0, min = 0;
    const uint8_t *ptr;
    size_t i;
    
    for (i = 0; i + 7 < search_len; i++) {
        if (memcmp(p->buf + i, needle, 5) == 0) {
            found = p->buf + i;
            break;
        }
    }
    
    if (!found) {
        set_error(p, PDFMAKE_EHEADER, 0, "PDF header not found");
        return PDFMAKE_EHEADER;
    }
    
    /* Parse version */
    ptr = found + 5;
    while (isdigit(*ptr)) maj = maj * 10 + (*ptr++ - '0');
    if (*ptr == '.') ptr++;
    while (isdigit(*ptr)) min = min * 10 + (*ptr++ - '0');
    
    if (major) *major = maj;
    if (minor) *minor = min;
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Object parsing — recursive descent
 *==========================================================================*/

/* Forward declaration for mutual recursion */
static pdfmake_obj_t parse_object_internal(pdfmake_parser_t *p);

/* Parse name token - decode #XX escapes */
static pdfmake_obj_t parse_name(pdfmake_parser_t *p, pdfmake_tok_t *tok) {
    /* Skip leading / - use tok.buf since it may be repositioned */
    const uint8_t *src = p->tok.buf + tok->offset + 1;
    size_t src_len = tok->length - 1;
    int has_escape = 0;
    uint8_t *decoded;
    size_t out_len;
    size_t i;
    
    /* Check if we need to decode #XX */
    for (i = 0; i < src_len; i++) {
        if (src[i] == '#') { has_escape = 1; break; }
    }
    
    if (!has_escape) {
        return pdfmake_name(p->doc->arena, (const char *)src, src_len);
    }
    
    /* Decode escapes */
    decoded = pdfmake_arena_alloc(p->doc->arena, src_len);
    if (!decoded) return pdfmake_null();
    
    out_len = 0;
    for (i = 0; i < src_len; i++) {
        if (src[i] == '#' && i + 2 < src_len) {
            int hi = hex_digit(src[i + 1]);
            int lo = hex_digit(src[i + 2]);
            if (hi >= 0 && lo >= 0) {
                decoded[out_len++] = (uint8_t)((hi << 4) | lo);
                i += 2;
                continue;
            }
        }
        decoded[out_len++] = src[i];
    }
    
    return pdfmake_name(p->doc->arena, (const char *)decoded, out_len);
}

/* Parse literal string - decode escape sequences */
static pdfmake_obj_t parse_literal_string(pdfmake_parser_t *p, pdfmake_tok_t *tok) {
    /* Content is between ( and ) - skip outer parens - use tok.buf */
    const uint8_t *src = p->tok.buf + tok->offset + 1;
    size_t src_len = tok->length - 2;
    uint8_t *decoded;
    size_t out_len;
    int paren_depth;
    size_t i;
    
    /* Decode string escapes */
    decoded = pdfmake_arena_alloc(p->doc->arena, src_len + 1);
    if (!decoded) return pdfmake_null();
    
    out_len = 0;
    paren_depth = 0;
    
    for (i = 0; i < src_len; i++) {
        uint8_t c = src[i];
        
        if (c == '\\' && i + 1 < src_len) {
            uint8_t next = src[i + 1];
            switch (next) {
                case 'n':  decoded[out_len++] = '\n'; i++; continue;
                case 'r':  decoded[out_len++] = '\r'; i++; continue;
                case 't':  decoded[out_len++] = '\t'; i++; continue;
                case 'b':  decoded[out_len++] = '\b'; i++; continue;
                case 'f':  decoded[out_len++] = '\f'; i++; continue;
                case '(':  decoded[out_len++] = '(';  i++; continue;
                case ')':  decoded[out_len++] = ')';  i++; continue;
                case '\\': decoded[out_len++] = '\\'; i++; continue;
                case '\n': i++; continue; /* Line continuation LF */
                case '\r': /* Line continuation CR or CRLF */
                    i++;
                    if (i + 1 < src_len && src[i + 1] == '\n') i++;
                    continue;
                default:
                    /* Octal escape? */
                    if (next >= '0' && next <= '7') {
                        int val = next - '0';
                        i++;
                        if (i + 1 < src_len && src[i + 1] >= '0' && src[i + 1] <= '7') {
                            val = val * 8 + (src[++i] - '0');
                            if (i + 1 < src_len && src[i + 1] >= '0' && src[i + 1] <= '7') {
                                val = val * 8 + (src[++i] - '0');
                            }
                        }
                        decoded[out_len++] = (uint8_t)(val & 0xFF);
                        continue;
                    }
                    /* Unknown escape - just keep the backslash per PDF spec */
                    decoded[out_len++] = c;
                    continue;
            }
        }
        
        /* Track balanced parens (tokenizer already validated) */
        if (c == '(') paren_depth++;
        else if (c == ')') paren_depth--;
        
        decoded[out_len++] = c;
    }
    
    (void)paren_depth; /* Validated by tokenizer */
    return pdfmake_str(p->doc->arena, (const char *)decoded, out_len);
}

/* Parse hex string - decode hex pairs */
static pdfmake_obj_t parse_hex_string(pdfmake_parser_t *p, pdfmake_tok_t *tok) {
    /* Content is between < and > - use tok.buf */
    const uint8_t *src = p->tok.buf + tok->offset + 1;
    size_t src_len = tok->length - 2;
    uint8_t *decoded;
    size_t out_len;
    int high;
    size_t i;
    
    /* Decode hex pairs (skip whitespace) */
    decoded = pdfmake_arena_alloc(p->doc->arena, (src_len + 1) / 2);
    if (!decoded) return pdfmake_null();
    
    out_len = 0;
    high = -1;
    
    for (i = 0; i < src_len; i++) {
        uint8_t c = src[i];
        int digit;
        if (pdfmake_is_whitespace(c)) continue;
        
        digit = hex_digit(c);
        if (digit < 0) continue; /* Invalid hex digit - skip */
        
        if (high < 0) {
            high = digit;
        } else {
            decoded[out_len++] = (uint8_t)((high << 4) | digit);
            high = -1;
        }
    }
    
    /* Odd number of digits - pad with 0 */
    if (high >= 0) {
        decoded[out_len++] = (uint8_t)(high << 4);
    }
    
    return pdfmake_hexstr(p->doc->arena, decoded, out_len);
}

/* Parse array */
static pdfmake_obj_t parse_array(pdfmake_parser_t *p) {
    pdfmake_obj_t arr = pdfmake_array_new(p->doc->arena);
    pdfmake_tok_t tok;
    pdfmake_obj_t item;
    
    if (arr.kind != PDFMAKE_ARRAY) return pdfmake_null();
    
    while (1) {
        pdfmake_tok_peek_significant(&p->tok, &tok);
        
        if (tok.kind == PDFMAKE_TOK_ARR_CLOSE) {
            pdfmake_tok_next_significant(&p->tok); /* Consume ] */
            break;
        }
        if (tok.kind == PDFMAKE_TOK_EOF) {
            set_error(p, PDFMAKE_EPARSE, tok.offset, "Unterminated array");
            return pdfmake_null();
        }
        
        item = parse_object_internal(p);
        if (p->last_err != PDFMAKE_OK) return pdfmake_null();
        
        if (!pdfmake_array_push(p->doc->arena, &arr, item)) {
            set_error(p, PDFMAKE_ENOMEM, tok.offset, "Array push failed");
            return pdfmake_null();
        }
    }
    
    return arr;
}

/* Parse dictionary (and possibly stream) */
static pdfmake_obj_t parse_dict(pdfmake_parser_t *p) {
    pdfmake_obj_t dict = pdfmake_dict_new(p->doc->arena);
    pdfmake_tok_t tok;
    pdfmake_obj_t key_obj;
    pdfmake_obj_t value;
    pdfmake_tok_t next;
    pdfmake_obj_t stream;
    pdfmake_obj_t stream_dict_wrapper;
    pdfmake_dict_iter_t iter;
    const uint8_t *body_data;
    size_t body_len;
    pdfmake_err_t err;
    size_t endstream_pos;
    const char *endstream_kw;
    
    if (dict.kind != PDFMAKE_DICT) return pdfmake_null();
    
    while (1) {
        pdfmake_tok_peek_significant(&p->tok, &tok);
        
        if (tok.kind == PDFMAKE_TOK_DICT_CLOSE) {
            pdfmake_tok_next_significant(&p->tok); /* Consume >> */
            break;
        }
        if (tok.kind == PDFMAKE_TOK_EOF) {
            set_error(p, PDFMAKE_EPARSE, tok.offset, "Unterminated dictionary");
            return pdfmake_null();
        }
        
        /* Key must be a name */
        if (tok.kind != PDFMAKE_TOK_NAME) {
            set_error(p, PDFMAKE_EPARSE, tok.offset, "Dictionary key must be a name");
            return pdfmake_null();
        }
        
        pdfmake_tok_next_significant(&p->tok); /* Consume key */
        key_obj = parse_name(p, &tok);
        if (key_obj.kind != PDFMAKE_NAME) return pdfmake_null();
        
        /* Value */
        value = parse_object_internal(p);
        if (p->last_err != PDFMAKE_OK) return pdfmake_null();
        
        if (!pdfmake_dict_set(p->doc->arena, &dict, key_obj.as.name.id, value)) {
            set_error(p, PDFMAKE_ENOMEM, tok.offset, "Dict set failed");
            return pdfmake_null();
        }
    }
    
    /* Check if followed by stream keyword */
    pdfmake_tok_peek_significant(&p->tok, &next);
    
    if (next.kind == PDFMAKE_TOK_KW_STREAM) {
        pdfmake_tok_next_significant(&p->tok); /* Consume stream */
        
        /* Create stream object */
        stream = pdfmake_stream_new(p->doc->arena);
        if (stream.kind != PDFMAKE_STREAM) return pdfmake_null();
        
        /* Copy dict entries to stream dict - need a wrapper pdfmake_obj_t */
        stream_dict_wrapper.kind = PDFMAKE_DICT;
        stream_dict_wrapper.as.dict = stream.as.stream->dict;
        
        pdfmake_dict_iter_init(&iter, &dict);
        while (pdfmake_dict_iter_next(&iter)) {
            pdfmake_dict_set(p->doc->arena, &stream_dict_wrapper, 
                           iter.current_key, *iter.current_value);
        }
        
        /* Extract stream body */
        err = pdfmake_extract_stream_body(p, &dict, next.payload.body_offset,
                                          &body_data, &body_len);
        if (err != PDFMAKE_OK) return pdfmake_null();
        
        /* Copy stream data to arena */
        pdfmake_stream_set_data(p->doc->arena, &stream, body_data, body_len);
        
        /* Skip tokenizer past stream body to find endstream.
         * The tokenizer can't parse arbitrary binary stream content, 
         * so we manually position it after the stream body. */
        endstream_pos = next.payload.body_offset + body_len;
        
        /* Skip optional EOL before endstream */
        while (endstream_pos < p->buf_len && 
               (p->buf[endstream_pos] == '\r' || p->buf[endstream_pos] == '\n')) {
            endstream_pos++;
        }
        
        /* Verify endstream keyword */
        endstream_kw = "endstream";
        if (endstream_pos + 9 > p->buf_len ||
            memcmp(p->buf + endstream_pos, endstream_kw, 9) != 0) {
            set_error(p, PDFMAKE_ESTREAM, endstream_pos, "Expected endstream");
            return pdfmake_null();
        }
        
        /* Position tokenizer after endstream */
        p->tok.pos = endstream_pos + 9;
        p->tok.has_peeked = 0;
        
        return stream;
    }
    
    return dict;
}

/* Parse any object at current position */
static pdfmake_obj_t parse_object_internal(pdfmake_parser_t *p) {
    pdfmake_tok_t tok = pdfmake_tok_next_significant(&p->tok);
    
    switch (tok.kind) {
        case PDFMAKE_TOK_KW_NULL:
            return pdfmake_null();
            
        case PDFMAKE_TOK_KW_TRUE:
            return pdfmake_bool(1);
            
        case PDFMAKE_TOK_KW_FALSE:
            return pdfmake_bool(0);
            
        case PDFMAKE_TOK_INT: {
            /* Check for indirect reference: INT INT R */
            pdfmake_tok_t peek1, peek2;
            pdfmake_tok_peek_significant(&p->tok, &peek1);
            
            if (peek1.kind == PDFMAKE_TOK_INT) {
                /* Save tokenizer state */
                size_t saved_pos = p->tok.pos;
                int saved_peeked = p->tok.has_peeked;
                pdfmake_tok_t saved_peek = p->tok.peeked;
                
                pdfmake_tok_next_significant(&p->tok); /* Consume second int */
                pdfmake_tok_peek_significant(&p->tok, &peek2);
                
                if (peek2.kind == PDFMAKE_TOK_KW_R) {
                    pdfmake_tok_next_significant(&p->tok); /* Consume R */
                    return pdfmake_ref((uint32_t)tok.payload.int_val, 
                                       (uint16_t)peek1.payload.int_val);
                }
                
                /* Not a reference - restore state */
                p->tok.pos = saved_pos;
                p->tok.has_peeked = saved_peeked;
                p->tok.peeked = saved_peek;
            }
            return pdfmake_int(tok.payload.int_val);
        }
            
        case PDFMAKE_TOK_REAL:
            return pdfmake_real(tok.payload.real_val);
            
        case PDFMAKE_TOK_NAME:
            return parse_name(p, &tok);
            
        case PDFMAKE_TOK_LSTR:
            return parse_literal_string(p, &tok);
            
        case PDFMAKE_TOK_HSTR:
            return parse_hex_string(p, &tok);
            
        case PDFMAKE_TOK_ARR_OPEN:
            return parse_array(p);
            
        case PDFMAKE_TOK_DICT_OPEN:
            return parse_dict(p);
            
        case PDFMAKE_TOK_EOF:
            set_error(p, PDFMAKE_EPARSE, tok.offset, "Unexpected end of input");
            return pdfmake_null();
            
        default:
            set_error(p, PDFMAKE_EPARSE, tok.offset, "Unexpected token");
            return pdfmake_null();
    }
}

pdfmake_obj_t pdfmake_parse_object(pdfmake_parser_t *parser) {
    parser->last_err = PDFMAKE_OK;
    return parse_object_internal(parser);
}

/*============================================================================
 * Stream body extraction
 *==========================================================================*/

pdfmake_err_t pdfmake_extract_stream_body(pdfmake_parser_t *p,
                                          pdfmake_obj_t *stream_dict,
                                          size_t body_offset,
                                          const uint8_t **out_data,
                                          size_t *out_len) {
    /* Get /Length from dict */
    uint32_t length_id = intern_name(p, "Length", 6);
    pdfmake_obj_t *length_obj = pdfmake_dict_get(stream_dict, length_id);
    size_t declared_len = 0;
    int have_length = 0;
    const char *endstream_marker;
    size_t endstream_len;
    size_t scan_start;
    size_t scan_end;
    size_t i;
    
    if (length_obj) {
        if (length_obj->kind == PDFMAKE_INT) {
            declared_len = (size_t)length_obj->as.i;
            have_length = 1;
        } else if (length_obj->kind == PDFMAKE_REF) {
            /* /Length is indirect - need to resolve */
            pdfmake_obj_t *resolved = pdfmake_parser_resolve(p, length_obj->as.ref);
            if (resolved && resolved->kind == PDFMAKE_INT) {
                declared_len = (size_t)resolved->as.i;
                have_length = 1;
            }
        }
    }
    
    /* Find endstream */
    endstream_marker = "endstream";
    endstream_len = 9;
    scan_start = body_offset;
    scan_end = p->buf_len;
    
    /* If we have declared length, try it first */
    if (have_length && body_offset + declared_len + endstream_len <= p->buf_len) {
        size_t expected_end = body_offset + declared_len;
        
        /* Skip optional EOL before endstream */
        while (expected_end < p->buf_len && 
               (p->buf[expected_end] == '\r' || p->buf[expected_end] == '\n')) {
            expected_end++;
        }
        
        if (expected_end + endstream_len <= p->buf_len &&
            memcmp(p->buf + expected_end, endstream_marker, endstream_len) == 0) {
            *out_data = p->buf + body_offset;
            *out_len = declared_len;
            return PDFMAKE_OK;
        }
    }
    
    /* Fallback: scan for endstream */
    for (i = scan_start; i + endstream_len <= scan_end; i++) {
        if (memcmp(p->buf + i, endstream_marker, endstream_len) == 0) {
            /* Check preceding bytes for proper delimiter */
            size_t body_end = i;
            
            /* Back up over optional EOL */
            if (body_end > body_offset && p->buf[body_end - 1] == '\n') {
                body_end--;
            }
            if (body_end > body_offset && p->buf[body_end - 1] == '\r') {
                body_end--;
            }
            
            *out_data = p->buf + body_offset;
            *out_len = body_end - body_offset;
            return PDFMAKE_OK;
        }
    }
    
    set_error(p, PDFMAKE_ESTREAM, body_offset, "endstream not found");
    return PDFMAKE_ESTREAM;
}

/*============================================================================
 * Indirect object parsing
 *==========================================================================*/

pdfmake_err_t pdfmake_parse_indirect_object(pdfmake_parser_t *p) {
    pdfmake_tok_t num_tok;
    pdfmake_tok_t gen_tok;
    pdfmake_tok_t obj_tok;
    uint32_t num;
    uint16_t gen;
    pdfmake_obj_t obj;
    pdfmake_tok_t endobj_tok;
    size_t idx;
    
    /* Clear any residual error from previous operations */
    p->last_err = PDFMAKE_OK;
    
    num_tok = pdfmake_tok_next_significant(&p->tok);
    if (num_tok.kind != PDFMAKE_TOK_INT) {
        set_error(p, PDFMAKE_EPARSE, num_tok.offset, "Expected object number");
        return PDFMAKE_EPARSE;
    }
    
    gen_tok = pdfmake_tok_next_significant(&p->tok);
    if (gen_tok.kind != PDFMAKE_TOK_INT) {
        set_error(p, PDFMAKE_EPARSE, gen_tok.offset, "Expected generation number");
        return PDFMAKE_EPARSE;
    }
    
    obj_tok = pdfmake_tok_next_significant(&p->tok);
    if (obj_tok.kind != PDFMAKE_TOK_KW_OBJ) {
        set_error(p, PDFMAKE_EPARSE, obj_tok.offset, "Expected 'obj' keyword");
        return PDFMAKE_EPARSE;
    }
    
    num = (uint32_t)num_tok.payload.int_val;
    gen = (uint16_t)gen_tok.payload.int_val;
    
    /* Parse the object value */
    obj = parse_object_internal(p);
    if (p->last_err != PDFMAKE_OK) return p->last_err;
    
    /* Expect endobj */
    endobj_tok = pdfmake_tok_next_significant(&p->tok);
    if (endobj_tok.kind != PDFMAKE_TOK_KW_ENDOBJ) {
        /* Some PDFs omit endobj before stream - tolerate */
        if (endobj_tok.kind != PDFMAKE_TOK_KW_STREAM) {
            set_error(p, PDFMAKE_EPARSE, endobj_tok.offset, "Expected 'endobj' keyword");
            return PDFMAKE_EPARSE;
        }
    }
    
    /* Store in document */
    /* Grow objects array if needed - use num directly as we need capacity for num items */
    /* pdfmake_doc uses 1-based numbering with object N at index N-1 */
    while (num > p->doc->obj_cap) {
        size_t new_cap = p->doc->obj_cap ? p->doc->obj_cap * 2 : PDFMAKE_DOC_INIT_CAP;
        pdfmake_indirect_t *new_objs;
        while (new_cap < num) new_cap *= 2;
        new_objs = realloc(p->doc->objects, 
                           new_cap * sizeof(pdfmake_indirect_t));
        if (!new_objs) {
            set_error(p, PDFMAKE_ENOMEM, 0, "Failed to grow object table");
            return PDFMAKE_ENOMEM;
        }
        memset(new_objs + p->doc->obj_cap, 0, 
               (new_cap - p->doc->obj_cap) * sizeof(pdfmake_indirect_t));
        p->doc->objects = new_objs;
        p->doc->obj_cap = new_cap;
    }
    
    /* Store at index num-1 (1-based numbering) */
    idx = num - 1;
    p->doc->objects[idx].num = num;
    p->doc->objects[idx].gen = gen;
    p->doc->objects[idx].obj = obj;
    p->doc->objects[idx].in_use = 1;
    p->doc->objects[idx].byte_offset = num_tok.offset;
    
    if (num > p->doc->obj_count) {
        p->doc->obj_count = num;
    }
    
    /* Update xref if tracking */
    if (ensure_xref_cap(p, num)) {
        p->xref[num].num = num;
        p->xref[num].gen = gen;
        p->xref[num].type = PDFMAKE_XREF_UNCOMPRESSED;
        p->xref[num].loc.offset = num_tok.offset;
        p->xref[num].loaded = 1;
        if (num >= p->xref_size) p->xref_size = num + 1;
    }
    
    return PDFMAKE_OK;
}

/*============================================================================
 * startxref locator
 *==========================================================================*/

pdfmake_err_t pdfmake_locate_startxref(pdfmake_parser_t *p, uint64_t *offset) {
    /* Scan backward from EOF - check last 1024 bytes per spec */
    size_t search_start = p->buf_len > 1024 ? p->buf_len - 1024 : 0;
    const char *keyword = "startxref";
    size_t keyword_len = 9;
    const uint8_t *found = NULL;
    const uint8_t *ptr;
    const uint8_t *end;
    uint64_t off;
    size_t i;
    
    /* Find last occurrence of startxref */
    for (i = p->buf_len; i > search_start + keyword_len; ) {
        i--;
        if (memcmp(p->buf + i, keyword, keyword_len) == 0) {
            found = p->buf + i;
            break;
        }
    }
    
    if (!found) {
        set_error(p, PDFMAKE_EXREF, 0, "startxref not found");
        return PDFMAKE_EXREF;
    }
    
    /* Parse offset after startxref */
    ptr = found + keyword_len;
    end = p->buf + p->buf_len;
    
    /* Skip whitespace */
    while (ptr < end && (*ptr == ' ' || *ptr == '\t' || *ptr == '\r' || *ptr == '\n')) {
        ptr++;
    }
    
    /* Parse number */
    off = 0;
    while (ptr < end && isdigit(*ptr)) {
        off = off * 10 + (*ptr - '0');
        ptr++;
    }
    
    *offset = off;
    return PDFMAKE_OK;
}

/*============================================================================
 * Classic xref table parser (§7.5.4)
 *==========================================================================*/

/* Consume a "first_num count" pair that introduces a classic-xref
 * subsection. Caller must have already confirmed via peek that the next
 * token is not KW_TRAILER. */
static pdfmake_err_t
parse_xref_subsection_header(pdfmake_parser_t *p, uint64_t table_offset,
                             uint32_t *out_first, uint32_t *out_count)
{
    pdfmake_tok_t first_tok;
    pdfmake_tok_t count_tok;
    
    first_tok = pdfmake_tok_next_significant(&p->tok);
    if (first_tok.kind != PDFMAKE_TOK_INT) {
        set_error(p, PDFMAKE_EXREF, table_offset + first_tok.offset,
                  "Expected subsection start object number");
        return PDFMAKE_EXREF;
    }

    count_tok = pdfmake_tok_next_significant(&p->tok);
    if (count_tok.kind != PDFMAKE_TOK_INT) {
        set_error(p, PDFMAKE_EXREF, table_offset + count_tok.offset,
                  "Expected subsection entry count");
        return PDFMAKE_EXREF;
    }

    *out_first = (uint32_t)first_tok.payload.int_val;
    *out_count = (uint32_t)count_tok.payload.int_val;
    return PDFMAKE_OK;
}

/* Parse one classic-xref entry (offset, gen, n|f) from the token stream
 * and store it into p->xref[obj_num] unless the slot is already loaded
 * from a later xref section. The type byte is a single-character ERROR
 * token rather than a keyword — the tokenizer does not recognise 'n'/'f'
 * specially. */
static pdfmake_err_t
parse_xref_entry(pdfmake_parser_t *p, uint64_t table_offset, uint32_t obj_num)
{
    pdfmake_tok_t off_tok;
    pdfmake_tok_t gen_tok;
    pdfmake_tok_t type_tok;
    char type_char;
    
    off_tok = pdfmake_tok_next_significant(&p->tok);
    if (off_tok.kind != PDFMAKE_TOK_INT) {
        set_error(p, PDFMAKE_EXREF, table_offset + off_tok.offset,
                  "Expected xref entry offset");
        return PDFMAKE_EXREF;
    }

    gen_tok = pdfmake_tok_next_significant(&p->tok);
    if (gen_tok.kind != PDFMAKE_TOK_INT) {
        set_error(p, PDFMAKE_EXREF, table_offset + gen_tok.offset,
                  "Expected xref entry generation");
        return PDFMAKE_EXREF;
    }

    type_tok = pdfmake_tok_next(&p->tok);
    while (type_tok.kind == PDFMAKE_TOK_WS || type_tok.kind == PDFMAKE_TOK_COMMENT) {
        type_tok = pdfmake_tok_next(&p->tok);
    }

    type_char = 'n';
    if (type_tok.kind == PDFMAKE_TOK_ERROR && type_tok.length == 1) {
        type_char = (char)p->buf[table_offset + type_tok.offset];
    }

    if (!p->xref[obj_num].loaded) {
        p->xref[obj_num].num = obj_num;
        p->xref[obj_num].gen = (uint16_t)gen_tok.payload.int_val;

        if (type_char == 'n') {
            p->xref[obj_num].type = PDFMAKE_XREF_UNCOMPRESSED;
            p->xref[obj_num].loc.offset = (uint64_t)off_tok.payload.int_val;
        } else {
            p->xref[obj_num].type = PDFMAKE_XREF_FREE;
            p->xref[obj_num].loc.next_free = (uint32_t)off_tok.payload.int_val;
        }
    }

    if (obj_num >= p->xref_size) p->xref_size = obj_num + 1;
    return PDFMAKE_OK;
}

pdfmake_err_t pdfmake_parse_xref_table(pdfmake_parser_t *p, uint64_t offset) {
    pdfmake_tok_t tok;
    pdfmake_tok_t next;
    uint32_t first_num, count;
    pdfmake_err_t err;
    uint32_t i;
    
    if (offset >= p->buf_len) {
        set_error(p, PDFMAKE_EXREF, (size_t)offset, "Xref offset beyond EOF");
        return PDFMAKE_EXREF;
    }

    pdfmake_tokenizer_init(&p->tok, p->buf + offset, p->buf_len - offset);

    tok = pdfmake_tok_next_significant(&p->tok);
    if (tok.kind != PDFMAKE_TOK_KW_XREF) {
        set_error(p, PDFMAKE_EXREF, offset + tok.offset, "Expected 'xref' keyword");
        return PDFMAKE_EXREF;
    }

    for (;;) {
        pdfmake_tok_peek_significant(&p->tok, &next);
        if (next.kind == PDFMAKE_TOK_KW_TRAILER) break;  /* trailer follows */

        err = parse_xref_subsection_header(p, offset, &first_num, &count);
        if (err != PDFMAKE_OK) return err;

        if (!ensure_xref_cap(p, first_num + count)) {
            set_error(p, PDFMAKE_ENOMEM, 0, "Failed to allocate xref table");
            return PDFMAKE_ENOMEM;
        }

        for (i = 0; i < count; i++) {
            err = parse_xref_entry(p, offset, first_num + i);
            if (err != PDFMAKE_OK) return err;
        }
    }

    return PDFMAKE_OK;
}

/*============================================================================
 * Trailer parsing
 *==========================================================================*/

pdfmake_err_t pdfmake_parse_trailer(pdfmake_parser_t *p, pdfmake_obj_t *trailer) {
    pdfmake_tok_t tok;
    uint32_t root_id, info_id, size_id, prev_id, encrypt_id;
    pdfmake_obj_t *root;
    pdfmake_obj_t *info;
    pdfmake_obj_t *encrypt;
    uint32_t id_id;
    pdfmake_obj_t *id_arr;
    pdfmake_obj_t *size;
    pdfmake_obj_t *prev;
    
    tok = pdfmake_tok_next_significant(&p->tok);
    if (tok.kind != PDFMAKE_TOK_KW_TRAILER) {
        set_error(p, PDFMAKE_ETRAILER, tok.offset, "Expected 'trailer' keyword");
        return PDFMAKE_ETRAILER;
    }
    
    *trailer = parse_object_internal(p);
    if (p->last_err != PDFMAKE_OK) return p->last_err;
    
    if (trailer->kind != PDFMAKE_DICT) {
        set_error(p, PDFMAKE_ETRAILER, tok.offset, "Trailer must be a dictionary");
        return PDFMAKE_ETRAILER;
    }
    
    /* Extract trailer values */
    root_id = intern_name(p, "Root", 4);
    info_id = intern_name(p, "Info", 4);
    size_id = intern_name(p, "Size", 4);
    prev_id = intern_name(p, "Prev", 4);
    encrypt_id = intern_name(p, "Encrypt", 7);
    
    root = pdfmake_dict_get(trailer, root_id);
    if (root && root->kind == PDFMAKE_REF) {
        p->root_num = root->as.ref.num;
        p->root_gen = root->as.ref.gen;
    }
    
    info = pdfmake_dict_get(trailer, info_id);
    if (info && info->kind == PDFMAKE_REF) {
        p->info_num = info->as.ref.num;
        p->info_gen = info->as.ref.gen;
    }
    
    encrypt = pdfmake_dict_get(trailer, encrypt_id);
    if (encrypt && encrypt->kind == PDFMAKE_REF) {
        p->encrypt_num = encrypt->as.ref.num;
        p->encrypt_gen = encrypt->as.ref.gen;
    }

    /* Extract /ID array (needed for encryption key derivation) */
    id_id = intern_name(p, "ID", 2);
    id_arr = pdfmake_dict_get(trailer, id_id);
    if (id_arr && id_arr->kind == PDFMAKE_ARRAY && pdfmake_array_len(id_arr) >= 1) {
        pdfmake_obj_t *id0 = pdfmake_array_get(id_arr, 0);
        if (id0 && id0->kind == PDFMAKE_STR && p->doc_id_len == 0) {
            size_t len = id0->as.str.len;
            if (len > sizeof(p->doc_id)) len = sizeof(p->doc_id);
            memcpy(p->doc_id, id0->as.str.bytes, len);
            p->doc_id_len = len;
        }
    }
    
    size = pdfmake_dict_get(trailer, size_id);
    if (size && size->kind == PDFMAKE_INT) {
        if (!ensure_xref_cap(p, (uint32_t)size->as.i)) {
            return PDFMAKE_ENOMEM;
        }
        if ((size_t)size->as.i > p->xref_size) {
            p->xref_size = (size_t)size->as.i;
        }
    }
    
    /* Check for /Prev - incremental update chain */
    prev = pdfmake_dict_get(trailer, prev_id);
    if (prev && prev->kind == PDFMAKE_INT) {
        uint64_t prev_offset = (uint64_t)prev->as.i;
        pdfmake_err_t err;
        pdfmake_obj_t prev_trailer;
        
        /* Cycle detection */
        if (prev_visited(p, prev_offset)) {
            set_error(p, PDFMAKE_ECYCLE, 0, "Cycle detected in /Prev chain");
            return PDFMAKE_ECYCLE;
        }
        
        if (!prev_add(p, prev_offset)) {
            return PDFMAKE_ENOMEM;
        }
        
        /* Parse previous xref */
        err = pdfmake_parse_xref_table(p, prev_offset);
        if (err != PDFMAKE_OK) return err;
        
        /* Parse previous trailer */
        err = pdfmake_parse_trailer(p, &prev_trailer);
        if (err != PDFMAKE_OK) return err;
    }
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Xref stream parser (§7.5.8)
 *==========================================================================*/

/* Parsed shape of the xref-stream dictionary parameters. */
typedef struct {
    int w1, w2, w3;         /* /W field widths */
    int entry_size;         /* sum of w1+w2+w3 */
    pdfmake_obj_t *index;   /* /Index array (or NULL → default range) */
    int64_t size;           /* /Size value (total object count) */
} xref_stream_params_t;

/* Extract /W, /Index and /Size from the xref-stream dict. Returns
 * PDFMAKE_EXREF if /W is missing or malformed; /Index and /Size are
 * optional (callers fall back to a default range). */
static pdfmake_err_t
xref_stream_extract_params(pdfmake_parser_t *p, uint64_t offset,
                           pdfmake_obj_t *dict,
                           xref_stream_params_t *out)
{
    uint32_t w_id = intern_name(p, "W", 1);
    pdfmake_obj_t *w_arr = pdfmake_dict_get(dict, w_id);
    uint32_t index_id;
    uint32_t size_id;
    pdfmake_obj_t *size_obj;
    
    if (!w_arr || w_arr->kind != PDFMAKE_ARRAY || pdfmake_array_len(w_arr) < 3) {
        set_error(p, PDFMAKE_EXREF, offset, "Invalid /W array in xref stream");
        return PDFMAKE_EXREF;
    }

    out->w1 = (int)pdfmake_get_int(pdfmake_array_get(w_arr, 0));
    out->w2 = (int)pdfmake_get_int(pdfmake_array_get(w_arr, 1));
    out->w3 = (int)pdfmake_get_int(pdfmake_array_get(w_arr, 2));
    out->entry_size = out->w1 + out->w2 + out->w3;

    index_id = intern_name(p, "Index", 5);
    size_id  = intern_name(p, "Size", 4);
    out->index = pdfmake_dict_get(dict, index_id);

    size_obj = pdfmake_dict_get(dict, size_id);
    out->size = (size_obj && size_obj->kind == PDFMAKE_INT) ? size_obj->as.i : 0;

    return PDFMAKE_OK;
}

/* Propagate /Root, /Info and /Encrypt references from the xref-stream dict
 * into the parser state. Mirrors the trailer dict handling used by classic
 * xref tables. The /Prev chain is handled by the orchestrator because it
 * recurses. */
static void
xref_stream_apply_trailer(pdfmake_parser_t *p, pdfmake_obj_t *dict)
{
    uint32_t root_id    = intern_name(p, "Root", 4);
    uint32_t info_id    = intern_name(p, "Info", 4);
    uint32_t encrypt_id = intern_name(p, "Encrypt", 7);
    pdfmake_obj_t *root;
    pdfmake_obj_t *info;
    pdfmake_obj_t *encrypt;

    root = pdfmake_dict_get(dict, root_id);
    if (root && root->kind == PDFMAKE_REF) {
        p->root_num = root->as.ref.num;
        p->root_gen = root->as.ref.gen;
    }

    info = pdfmake_dict_get(dict, info_id);
    if (info && info->kind == PDFMAKE_REF) {
        p->info_num = info->as.ref.num;
        p->info_gen = info->as.ref.gen;
    }

    encrypt = pdfmake_dict_get(dict, encrypt_id);
    if (encrypt && encrypt->kind == PDFMAKE_REF) {
        p->encrypt_num = encrypt->as.ref.num;
        p->encrypt_gen = encrypt->as.ref.gen;
    }
}

/* Read one variable-width xref-stream entry at *pp (advancing it) and store
 * it into p->xref[obj_num] unless that slot is already loaded from a later
 * xref section. Called from both the /Index subsection loop and the
 * default-range loop, which are otherwise identical. */
static PDFMAKE_INLINE void
xref_stream_read_entry(pdfmake_parser_t *p,
                       const uint8_t **pp,
                       int w1, int w2, int w3,
                       uint32_t obj_num)
{
    const uint8_t *ptr = *pp;
    uint64_t field1 = 0, field2 = 0, field3 = 0;
    int j;
    int type;

    for (j = 0; j < w1; j++) field1 = (field1 << 8) | *ptr++;
    for (j = 0; j < w2; j++) field2 = (field2 << 8) | *ptr++;
    for (j = 0; j < w3; j++) field3 = (field3 << 8) | *ptr++;
    *pp = ptr;

    /* Default type is 1 when /W specifies a zero-width type field. */
    type = (w1 == 0) ? 1 : (int)field1;

    if (!p->xref[obj_num].loaded) {
        p->xref[obj_num].num = obj_num;
        switch (type) {
            case 0: /* Free object */
                p->xref[obj_num].type = PDFMAKE_XREF_FREE;
                p->xref[obj_num].loc.next_free = (uint32_t)field2;
                p->xref[obj_num].gen = (uint16_t)field3;
                break;
            case 1: /* Uncompressed object */
                p->xref[obj_num].type = PDFMAKE_XREF_UNCOMPRESSED;
                p->xref[obj_num].loc.offset = field2;
                p->xref[obj_num].gen = (uint16_t)field3;
                break;
            case 2: /* Compressed object */
                p->xref[obj_num].type = PDFMAKE_XREF_COMPRESSED;
                p->xref[obj_num].loc.compressed.obj_stm_num = (uint32_t)field2;
                p->xref[obj_num].loc.compressed.index = (uint32_t)field3;
                p->xref[obj_num].gen = 0;
                break;
        }
    }

    if (obj_num >= p->xref_size) {
        p->xref_size = obj_num + 1;
    }
}

pdfmake_err_t pdfmake_parse_xref_stream(pdfmake_parser_t *p, uint64_t offset) {
    pdfmake_tok_t num_tok;
    pdfmake_tok_t gen_tok;
    pdfmake_tok_t obj_tok;
    pdfmake_obj_t stream;
    pdfmake_obj_t stream_dict_obj;
    xref_stream_params_t params;
    pdfmake_err_t err;
    uint8_t *decoded_data;
    size_t decoded_len;
    const uint8_t *ptr;
    const uint8_t *end;
    uint32_t prev_id;
    pdfmake_obj_t *prev;
    
    if (offset >= p->buf_len) {
        set_error(p, PDFMAKE_EXREF, (size_t)offset, "Xref stream offset beyond EOF");
        return PDFMAKE_EXREF;
    }
    
    /* Position tokenizer at xref stream object */
    pdfmake_tokenizer_init(&p->tok, p->buf + offset, p->buf_len - offset);
    
    /* Parse as indirect object */
    num_tok = pdfmake_tok_next_significant(&p->tok);
    if (num_tok.kind != PDFMAKE_TOK_INT) {
        set_error(p, PDFMAKE_EXREF, offset, "Expected xref stream object number");
        return PDFMAKE_EXREF;
    }
    
    gen_tok = pdfmake_tok_next_significant(&p->tok);
    if (gen_tok.kind != PDFMAKE_TOK_INT) {
        set_error(p, PDFMAKE_EXREF, offset, "Expected xref stream generation");
        return PDFMAKE_EXREF;
    }
    
    obj_tok = pdfmake_tok_next_significant(&p->tok);
    if (obj_tok.kind != PDFMAKE_TOK_KW_OBJ) {
        set_error(p, PDFMAKE_EXREF, offset, "Expected 'obj' keyword");
        return PDFMAKE_EXREF;
    }
    
    /* Parse stream object */
    stream = parse_object_internal(p);
    if (p->last_err != PDFMAKE_OK) return p->last_err;
    
    if (stream.kind != PDFMAKE_STREAM) {
        set_error(p, PDFMAKE_EXREF, offset, "Xref stream is not a stream");
        return PDFMAKE_EXREF;
    }
    
    /* Wrap the stream dict so we can call pdfmake_dict_get on it. */
    stream_dict_obj.kind = PDFMAKE_DICT;
    stream_dict_obj.as.dict = stream.as.stream->dict;

    err = xref_stream_extract_params(p, offset, &stream_dict_obj, &params);
    if (err != PDFMAKE_OK) return err;

    /* Decode stream data */
    err = pdfmake_decode_stream(p, stream.as.stream, &decoded_data, &decoded_len);
    if (err != PDFMAKE_OK) return err;

    /* Parse entries */
    ptr = decoded_data;
    end = decoded_data + decoded_len;

    if (params.index && params.index->kind == PDFMAKE_ARRAY) {
        /* Multiple subsections */
        size_t num_pairs = pdfmake_array_len(params.index) / 2;
        size_t pair;
        for (pair = 0; pair < num_pairs; pair++) {
            pdfmake_obj_t *first = pdfmake_array_get(params.index, pair * 2);
            pdfmake_obj_t *count = pdfmake_array_get(params.index, pair * 2 + 1);
            uint32_t first_num;
            uint32_t entry_count;
            uint32_t i;
            if (!first || !count) continue;

            first_num   = (uint32_t)pdfmake_get_int(first);
            entry_count = (uint32_t)pdfmake_get_int(count);

            if (!ensure_xref_cap(p, first_num + entry_count)) return PDFMAKE_ENOMEM;

            for (i = 0; i < entry_count && ptr + params.entry_size <= end; i++) {
                xref_stream_read_entry(p, &ptr, params.w1, params.w2, params.w3,
                                       first_num + i);
            }
        }
    } else {
        /* Default: single subsection from 0 to Size-1 */
        uint32_t entry_count = (uint32_t)params.size;
        uint32_t obj_num;
        if (!ensure_xref_cap(p, entry_count)) return PDFMAKE_ENOMEM;

        for (obj_num = 0;
             obj_num < entry_count && ptr + params.entry_size <= end;
             obj_num++) {
            xref_stream_read_entry(p, &ptr, params.w1, params.w2, params.w3, obj_num);
        }
    }

    /* Propagate trailer-equivalent refs from the stream dict. */
    xref_stream_apply_trailer(p, &stream_dict_obj);

    /* Check for /Prev - incremental update chain */
    prev_id = intern_name(p, "Prev", 4);
    prev = pdfmake_dict_get(&stream_dict_obj, prev_id);
    if (prev && prev->kind == PDFMAKE_INT) {
        uint64_t prev_offset = (uint64_t)prev->as.i;
        pdfmake_tokenizer_t save_tok;
        pdfmake_err_t prev_err;
        
        if (prev_visited(p, prev_offset)) {
            set_error(p, PDFMAKE_ECYCLE, 0, "Cycle detected in /Prev chain");
            return PDFMAKE_ECYCLE;
        }
        
        if (!prev_add(p, prev_offset)) {
            return PDFMAKE_ENOMEM;
        }
        
        /* Could be classic xref or xref stream */
        /* Try xref stream first, fall back to classic */
        save_tok = p->tok;
        prev_err = pdfmake_parse_xref_stream(p, prev_offset);
        if (prev_err != PDFMAKE_OK) {
            p->tok = save_tok;
            prev_err = pdfmake_parse_xref_table(p, prev_offset);
            if (prev_err == PDFMAKE_OK) {
                pdfmake_obj_t prev_trailer;
                prev_err = pdfmake_parse_trailer(p, &prev_trailer);
            }
        }
        if (prev_err != PDFMAKE_OK) return prev_err;
    }
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Stream decoding helper
 *==========================================================================*/

pdfmake_err_t pdfmake_decode_stream(pdfmake_parser_t *p,
                                     pdfmake_stream_t *stream,
                                     uint8_t **out_data,
                                     size_t *out_len) {
    pdfmake_obj_t dict_obj;
    uint32_t filter_id;
    uint32_t parms_id;
    pdfmake_obj_t *filter;
    pdfmake_obj_t *parms;
    pdfmake_buf_t out;
    pdfmake_err_t err;
    size_t len;
    uint8_t *data;
    
    if (stream->filtered) {
        /* Already decoded - just return raw data */
        *out_data = (uint8_t *)stream->raw;
        *out_len = stream->raw_len;
        return PDFMAKE_OK;
    }
    
    /* Get /Filter and /DecodeParms from stream dict */
    dict_obj.kind = PDFMAKE_DICT;
    dict_obj.as.dict = stream->dict;
    
    filter_id = intern_name(p, "Filter", 6);
    parms_id = intern_name(p, "DecodeParms", 11);
    
    filter = pdfmake_dict_get(&dict_obj, filter_id);
    parms = pdfmake_dict_get(&dict_obj, parms_id);
    
    if (!filter) {
        /* No filter - raw data */
        *out_data = (uint8_t *)stream->raw;
        *out_len = stream->raw_len;
        return PDFMAKE_OK;
    }
    
    /* Decode through filter chain */
    pdfmake_buf_init(&out);
    
    err = pdfmake_filter_chain_decode(p->doc->arena, filter, parms,
                                       stream->raw, stream->raw_len, &out);
    if (err != PDFMAKE_OK) {
        pdfmake_buf_free(&out);
        set_error(p, err, 0, "Stream decode failed");
        return err;
    }
    
    /* Copy to arena */
    len = pdfmake_buf_len(&out);
    data = pdfmake_arena_alloc(p->doc->arena, len);
    if (!data) {
        pdfmake_buf_free(&out);
        return PDFMAKE_ENOMEM;
    }
    memcpy(data, pdfmake_buf_data(&out), len);
    pdfmake_buf_free(&out);
    
    *out_data = data;
    *out_len = len;
    return PDFMAKE_OK;
}

/*============================================================================
 * Repair mode (§7.5 fallback)
 *==========================================================================*/

pdfmake_err_t pdfmake_repair_xref(pdfmake_parser_t *p) {
    size_t trailer_offset = 0;
    
    /* Scan entire file for "N G obj" patterns */
    pdfmake_tokenizer_init(&p->tok, p->buf, p->buf_len);
    
    while (1) {
        pdfmake_tok_t tok = pdfmake_tok_next_significant(&p->tok);
        if (tok.kind == PDFMAKE_TOK_EOF) break;
        
        if (tok.kind == PDFMAKE_TOK_INT) {
            size_t save_pos = p->tok.pos;
            pdfmake_tok_t gen_tok;
            
            gen_tok = pdfmake_tok_next_significant(&p->tok);
            if (gen_tok.kind == PDFMAKE_TOK_INT) {
                pdfmake_tok_t obj_tok = pdfmake_tok_next_significant(&p->tok);
                if (obj_tok.kind == PDFMAKE_TOK_KW_OBJ) {
                    /* Found object definition */
                    uint32_t num = (uint32_t)tok.payload.int_val;
                    uint16_t gen = (uint16_t)gen_tok.payload.int_val;
                    
                    if (ensure_xref_cap(p, num + 1)) {
                        p->xref[num].num = num;
                        p->xref[num].gen = gen;
                        p->xref[num].type = PDFMAKE_XREF_UNCOMPRESSED;
                        p->xref[num].loc.offset = tok.offset;
                        if (num >= p->xref_size) {
                            p->xref_size = num + 1;
                        }
                    }
                    
                    /* Skip to endobj */
                    while (1) {
                        pdfmake_tok_t skip = pdfmake_tok_next_significant(&p->tok);
                        if (skip.kind == PDFMAKE_TOK_KW_ENDOBJ ||
                            skip.kind == PDFMAKE_TOK_EOF) {
                            break;
                        }
                    }
                    continue;
                }
            }
            
            /* Not an object - restore position */
            p->tok.pos = save_pos;
            p->tok.has_peeked = 0;
        }
    }
    
    /* Look for trailer dict */
    pdfmake_tokenizer_init(&p->tok, p->buf, p->buf_len);
    
    /* Find last trailer keyword */
    while (1) {
        pdfmake_tok_t tok = pdfmake_tok_next(&p->tok);
        if (tok.kind == PDFMAKE_TOK_EOF) break;
        if (tok.kind == PDFMAKE_TOK_KW_TRAILER) {
            trailer_offset = tok.offset;
        }
    }
    
    if (trailer_offset > 0) {
        pdfmake_obj_t trailer;
        pdfmake_err_t trailer_err;
        pdfmake_tokenizer_init(&p->tok, p->buf + trailer_offset, p->buf_len - trailer_offset);
        p->last_err = PDFMAKE_OK;  /* Clear any residual error from xref scan */
        trailer_err = pdfmake_parse_trailer(p, &trailer);
        (void)trailer_err;  /* Ignore errors - best effort */
    }
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Object resolution
 *==========================================================================*/

pdfmake_obj_t *pdfmake_parser_resolve(pdfmake_parser_t *p, pdfmake_ref_t ref) {
    pdfmake_xref_entry_t *entry;
    
    if (ref.num >= p->xref_size) return NULL;
    
    entry = &p->xref[ref.num];
    if (entry->type == PDFMAKE_XREF_FREE) return NULL;
    
    /* Check generation */
    if (entry->gen != ref.gen) return NULL;
    
    /* Already loaded? */
    if (entry->loaded && ref.num < p->doc->obj_count) {
        pdfmake_obj_t *obj = pdfmake_doc_get(p->doc, ref.num);
        if (obj) return obj;
    }
    
    /* Load object */
    if (entry->type == PDFMAKE_XREF_UNCOMPRESSED) {
        /* Save tokenizer state */
        pdfmake_tokenizer_t save_tok = p->tok;
        pdfmake_err_t err;
        
        /* Position at object - use full buffer but set position */
        pdfmake_tokenizer_init(&p->tok, p->buf, p->buf_len);
        p->tok.pos = entry->loc.offset;
        
        /* Parse indirect object */
        err = pdfmake_parse_indirect_object(p);
        
        /* Restore tokenizer */
        p->tok = save_tok;
        
        if (err == PDFMAKE_OK) {
            entry->loaded = 1;
            return pdfmake_doc_get(p->doc, ref.num);
        }
    }
    else if (entry->type == PDFMAKE_XREF_COMPRESSED) {
        /* Object is in an object stream - need to decompress and parse */
        /* First resolve the object stream */
        pdfmake_ref_t stm_ref;
        pdfmake_obj_t *stm_obj;
        uint8_t *decoded;
        size_t decoded_len;
        pdfmake_obj_t stm_dict_obj;
        uint32_t n_id;
        uint32_t first_id;
        pdfmake_obj_t *n_obj;
        pdfmake_obj_t *first_obj;
        int64_t n, first;
        pdfmake_tokenizer_t stm_tok;
        uint32_t target_index;
        int64_t target_offset;
        int64_t i;
        pdfmake_tokenizer_t save_tok;
        pdfmake_obj_t obj;
        size_t idx;
        
        stm_ref.num = entry->loc.compressed.obj_stm_num;
        stm_ref.gen = 0;
        stm_obj = pdfmake_parser_resolve(p, stm_ref);
        
        if (!stm_obj || stm_obj->kind != PDFMAKE_STREAM) return NULL;
        
        /* Decode stream */
        if (pdfmake_decode_stream(p, stm_obj->as.stream, &decoded, &decoded_len) != PDFMAKE_OK) {
            return NULL;
        }
        
        /* Parse object stream header */
        /* Format: N1 offset1 N2 offset2 ... followed by objects */
        stm_dict_obj.kind = PDFMAKE_DICT;
        stm_dict_obj.as.dict = stm_obj->as.stream->dict;
        
        n_id = intern_name(p, "N", 1);
        first_id = intern_name(p, "First", 5);
        
        n_obj = pdfmake_dict_get(&stm_dict_obj, n_id);
        first_obj = pdfmake_dict_get(&stm_dict_obj, first_id);
        
        if (!n_obj || !first_obj) return NULL;
        
        n = pdfmake_get_int(n_obj);
        first = pdfmake_get_int(first_obj);
        
        /* Parse header (pairs of obj_num offset) */
        pdfmake_tokenizer_init(&stm_tok, decoded, decoded_len);
        
        target_index = entry->loc.compressed.index;
        target_offset = -1;
        
        for (i = 0; i < n; i++) {
            pdfmake_tok_t num_tok = pdfmake_tok_next_significant(&stm_tok);
            pdfmake_tok_t off_tok = pdfmake_tok_next_significant(&stm_tok);
            
            if (num_tok.kind != PDFMAKE_TOK_INT || off_tok.kind != PDFMAKE_TOK_INT) {
                break;
            }
            
            if ((uint32_t)i == target_index) {
                target_offset = first + off_tok.payload.int_val;
                break;
            }
        }
        
        if (target_offset < 0 || (size_t)target_offset >= decoded_len) {
            return NULL;
        }
        
        /* Parse object at offset */
        save_tok = p->tok;
        pdfmake_tokenizer_init(&p->tok, decoded + target_offset, decoded_len - target_offset);
        
        obj = parse_object_internal(p);
        p->tok = save_tok;
        
        if (p->last_err != PDFMAKE_OK) return NULL;
        
        /* Store in document (1-based numbering: object N at index N-1) */
        while (ref.num > p->doc->obj_cap) {
            size_t new_cap = p->doc->obj_cap ? p->doc->obj_cap * 2 : PDFMAKE_DOC_INIT_CAP;
            pdfmake_indirect_t *new_objs;
            while (new_cap < ref.num) new_cap *= 2;
            new_objs = realloc(p->doc->objects, 
                               new_cap * sizeof(pdfmake_indirect_t));
            if (!new_objs) return NULL;
            memset(new_objs + p->doc->obj_cap, 0, 
                   (new_cap - p->doc->obj_cap) * sizeof(pdfmake_indirect_t));
            p->doc->objects = new_objs;
            p->doc->obj_cap = new_cap;
        }
        
        idx = ref.num - 1;
        p->doc->objects[idx].num = ref.num;
        p->doc->objects[idx].gen = 0;
        p->doc->objects[idx].obj = obj;
        p->doc->objects[idx].in_use = 1;
        
        if (ref.num > p->doc->obj_count) {
            p->doc->obj_count = ref.num;
        }
        
        entry->loaded = 1;
        return &p->doc->objects[idx].obj;
    }
    
    return NULL;
}

pdfmake_obj_t *pdfmake_doc_resolve(pdfmake_doc_t *doc, pdfmake_parser_t *parser, 
                                    uint32_t num, uint16_t gen) {
    pdfmake_ref_t ref;
    (void)doc; /* doc info is in parser->doc, used for consistency with other APIs */
    ref.num = num;
    ref.gen = gen;
    return pdfmake_parser_resolve(parser, ref);
}

/*============================================================================
 * Main parser entry point
 *==========================================================================*/

pdfmake_err_t pdfmake_parser_run(pdfmake_parser_t *p, pdfmake_doc_t **out_doc) {
    pdfmake_err_t err;
    int major, minor;
    uint64_t xref_offset;
    pdfmake_tok_t first;
    pdfmake_obj_t trailer;
    
    /* Check header */
    err = pdfmake_check_header(p, &major, &minor);
    if (err != PDFMAKE_OK) return err;
    
    /* Locate startxref */
    err = pdfmake_locate_startxref(p, &xref_offset);
    if (err != PDFMAKE_OK) {
        if (p->repair) {
            err = pdfmake_repair_xref(p);
            if (err != PDFMAKE_OK) return err;
        } else {
            return err;
        }
    } else {
        /* Add to visited list for cycle detection */
        if (!prev_add(p, xref_offset)) {
            return PDFMAKE_ENOMEM;
        }
        
        /* Try xref stream first (common in modern PDFs) */
        /* Check what's at the offset */
        if (xref_offset < p->buf_len) {
            pdfmake_tokenizer_init(&p->tok, p->buf + xref_offset, p->buf_len - xref_offset);
            pdfmake_tok_peek_significant(&p->tok, &first);
            
            if (first.kind == PDFMAKE_TOK_INT) {
                /* Xref stream */
                err = pdfmake_parse_xref_stream(p, xref_offset);
            } else if (first.kind == PDFMAKE_TOK_KW_XREF) {
                /* Classic xref */
                err = pdfmake_parse_xref_table(p, xref_offset);
                if (err == PDFMAKE_OK) {
                    err = pdfmake_parse_trailer(p, &trailer);
                }
            } else {
                err = PDFMAKE_EXREF;
                set_error(p, err, (size_t)xref_offset, "Invalid xref location");
            }
            
            if (err != PDFMAKE_OK) {
                if (p->repair) {
                    err = pdfmake_repair_xref(p);
                    if (err != PDFMAKE_OK) return err;
                } else {
                    return err;
                }
            }
        } else {
            /* Offset beyond file - try repair if enabled */
            if (p->repair) {
                err = pdfmake_repair_xref(p);
                if (err != PDFMAKE_OK) return err;
            } else {
                set_error(p, PDFMAKE_EXREF, (size_t)xref_offset, "Xref offset beyond EOF");
                return PDFMAKE_EXREF;
            }
        }
    }
    
    /* Set document trailer refs */
    if (p->root_num > 0) {
        pdfmake_doc_set_root(p->doc, p->root_num, p->root_gen);
    }
    if (p->info_num > 0) {
        pdfmake_doc_set_info(p->doc, p->info_num, p->info_gen);
    }
    
    *out_doc = p->doc;
    return PDFMAKE_OK;
}

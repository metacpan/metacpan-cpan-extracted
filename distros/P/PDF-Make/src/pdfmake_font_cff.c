/*
 * pdfmake_font_cff.c - CFF (Compact Font Format) parser
 *
 * Parses CFF fonts (Type 2 charstrings) for glyph outlines.
 * CFF is used in OpenType fonts with PostScript outlines.
 *
 * Reference:
 * - Adobe Tech Note #5176 "CFF Font Format Specification"
 * - Adobe Tech Note #5177 "Type 2 Charstring Format"
 */

#include "pdfmake_text.h"
#include "pdfmake_render.h"
#include "pdfmake_arena.h"
#include <string.h>
#include <stdlib.h>
#include <math.h>

/*============================================================================
 * CFF Structures
 *==========================================================================*/

/* CFF Index structure */
typedef struct {
    uint16_t count;
    uint8_t  off_size;
    const uint8_t *offsets;
    const uint8_t *data;
} cff_index_t;

/* CFF Dict entry types */
typedef enum {
    CFF_INT,
    CFF_REAL,
} cff_operand_type_t;

typedef struct {
    cff_operand_type_t type;
    union {
        int32_t i;
        double f;
    } val;
} cff_operand_t;

/* CFF Font info */
typedef struct {
    const uint8_t *data;
    size_t len;
    
    /* Header */
    uint8_t major;
    uint8_t minor;
    uint8_t hdr_size;
    uint8_t off_size;
    
    /* Indices */
    cff_index_t name_index;
    cff_index_t top_dict_index;
    cff_index_t string_index;
    cff_index_t gsubr_index;
    
    /* Top DICT values */
    int32_t charset_offset;
    int32_t encoding_offset;
    int32_t charstrings_offset;
    int32_t private_offset;
    int32_t private_size;
    int32_t fdarray_offset;
    int32_t fdselect_offset;
    
    /* CharStrings Index */
    cff_index_t charstrings_index;
    
    /* Subrs Index (from Private DICT) */
    cff_index_t subr_index;
    int32_t subr_bias;
    int32_t gsubr_bias;
    
    /* Font metrics */
    double font_matrix[6];
    double font_bbox[4];
    uint16_t default_width;
    uint16_t nominal_width;
} cff_font_t;

/*============================================================================
 * CFF Index Parsing
 *==========================================================================*/

static int parse_cff_index(const uint8_t *p, const uint8_t *end, cff_index_t *idx)
{
    size_t offsets_size;
    uint32_t last_offset;
    const uint8_t *op;
    int i;

    if (p + 2 > end) return -1;
    
    idx->count = ((uint16_t)p[0] << 8) | p[1];
    p += 2;
    
    if (idx->count == 0) {
        idx->off_size = 0;
        idx->offsets = NULL;
        idx->data = p;
        return 2;
    }
    
    if (p >= end) return -1;
    idx->off_size = *p++;
    
    if (idx->off_size < 1 || idx->off_size > 4) return -1;
    
    offsets_size = (idx->count + 1) * idx->off_size;
    if (p + offsets_size > end) return -1;
    
    idx->offsets = p;
    p += offsets_size;
    
    /* Get data start (first offset should be 1) */
    idx->data = p - 1; /* Offsets are 1-based */
    
    /* Calculate total size */
    last_offset = 0;
    op = idx->offsets + idx->count * idx->off_size;
    for (i = 0; i < idx->off_size; i++) {
        last_offset = (last_offset << 8) | op[i];
    }
    
    return 3 + offsets_size + last_offset - 1;
}

static uint32_t get_index_offset(const cff_index_t *idx, uint16_t i)
{
    const uint8_t *p;
    uint32_t offset;
    int j;

    if (!idx || i > idx->count) return 0;
    
    p = idx->offsets + i * idx->off_size;
    offset = 0;
    
    for (j = 0; j < idx->off_size; j++) {
        offset = (offset << 8) | p[j];
    }
    
    return offset;
}

static const uint8_t *get_index_data(const cff_index_t *idx, uint16_t i, 
                                      size_t *out_len)
{
    uint32_t start;
    uint32_t end;

    if (!idx || i >= idx->count) return NULL;
    
    start = get_index_offset(idx, i);
    end = get_index_offset(idx, i + 1);
    
    if (out_len) *out_len = end - start;
    return idx->data + start;
}

/*============================================================================
 * CFF DICT Parsing
 *==========================================================================*/

static int parse_cff_dict_operand(const uint8_t **pp, const uint8_t *end,
                                   cff_operand_t *op)
{
    uint8_t b0;
    double rval;
    int exp;
    int frac_digits;
    int in_frac;
    int negative;
    int exp_negative;
    int done;
    int n;
    int i;
    int32_t val;

    if (*pp >= end) return -1;
    
    b0 = *(*pp)++;
    
    if (b0 == 30) {
        /* Real number */
        op->type = CFF_REAL;
        /* Parse BCD-encoded real - simplified */
        rval = 0;
        exp = 0;
        frac_digits = 0;
        in_frac = 0;
        negative = 0;
        exp_negative = 0;
        done = 0;
        
        while (*pp < end && !done) {
            uint8_t byte = *(*pp)++;
            for (n = 0; n < 2 && !done; n++) {
                int nibble = (n == 0) ? (byte >> 4) : (byte & 0xF);

                switch (nibble) {
                    case 0x0: case 0x1: case 0x2: case 0x3: case 0x4:
                    case 0x5: case 0x6: case 0x7: case 0x8: case 0x9:
                        if (in_frac) {
                            rval = rval * 10 + nibble;
                            frac_digits++;
                        } else {
                            rval = rval * 10 + nibble;
                        }
                        break;
                    case 0xA: /* . */
                        in_frac = 1;
                        break;
                    case 0xB: /* E+ */
                        break;
                    case 0xC: /* E- */
                        exp_negative = 1;
                        break;
                    case 0xE: /* - */
                        negative = 1;
                        break;
                    case 0xF: /* end */
                        done = 1;
                        break;
                }
            }
        }
        
        for (i = 0; i < frac_digits; i++) {
            rval /= 10.0;
        }
        if (negative) rval = -rval;
        if (exp_negative) exp = -exp;
        rval *= pow(10.0, exp);
        
        op->val.f = rval;
        return 0;
    }
    
    /* Integer */
    op->type = CFF_INT;
    
    if (b0 >= 32 && b0 <= 246) {
        val = b0 - 139;
    } else if (b0 >= 247 && b0 <= 250) {
        if (*pp >= end) return -1;
        val = (b0 - 247) * 256 + *(*pp)++ + 108;
    } else if (b0 >= 251 && b0 <= 254) {
        if (*pp >= end) return -1;
        val = -(b0 - 251) * 256 - *(*pp)++ - 108;
    } else if (b0 == 28) {
        if (*pp + 2 > end) return -1;
        val = ((int16_t)(*pp)[0] << 8) | (*pp)[1];
        *pp += 2;
    } else if (b0 == 29) {
        if (*pp + 4 > end) return -1;
        val = ((int32_t)(*pp)[0] << 24) | ((int32_t)(*pp)[1] << 16) |
              ((int32_t)(*pp)[2] << 8) | (*pp)[3];
        *pp += 4;
    } else {
        return -1; /* Operator, not operand */
    }
    
    op->val.i = val;
    return 0;
}

/*============================================================================
 * Type 2 CharString Interpreter
 *==========================================================================*/

#define T2_STACK_MAX 48
#define T2_TRANS_MAX 32

typedef struct {
    pdfmake_path_t *path;
    pdfmake_arena_t *arena;
    
    /* Operand stack */
    double stack[T2_STACK_MAX];
    int sp;
    
    /* Current point */
    double x, y;
    
    /* Hints (ignored for outline) */
    int num_hints;
    
    /* Width */
    int width_parsed;
    double width;
    
    /* Subroutines */
    const cff_font_t *font;
    
    /* Call depth */
    int depth;
} t2_state_t;

static int t2_execute(t2_state_t *st, const uint8_t *cs, size_t len);

static void t2_push(t2_state_t *st, double val)
{
    if (st->sp < T2_STACK_MAX) {
        st->stack[st->sp++] = val;
    }
}

static double t2_pop(t2_state_t *st)
{
    return (st->sp > 0) ? st->stack[--st->sp] : 0;
}

static void t2_rmoveto(t2_state_t *st)
{
    double dx;
    double dy;

    if (st->sp < 2) return;
    
    dy = t2_pop(st);
    dx = t2_pop(st);
    
    st->x += dx;
    st->y += dy;
    
    pdfmake_path_move_to(st->path, st->x, st->y);
}

static void t2_rlineto(t2_state_t *st)
{
    int i;
    while (st->sp >= 2) {
        double dx = st->stack[0];
        double dy = st->stack[1];
        
        st->x += dx;
        st->y += dy;
        
        pdfmake_path_line_to(st->path, st->x, st->y);
        
        /* Shift stack */
        for (i = 2; i < st->sp; i++) {
            st->stack[i-2] = st->stack[i];
        }
        st->sp -= 2;
    }
}

static void t2_rrcurveto(t2_state_t *st)
{
    int i;
    while (st->sp >= 6) {
        double dx1 = st->stack[0];
        double dy1 = st->stack[1];
        double dx2 = st->stack[2];
        double dy2 = st->stack[3];
        double dx3 = st->stack[4];
        double dy3 = st->stack[5];
        
        double x1 = st->x + dx1;
        double y1 = st->y + dy1;
        double x2 = x1 + dx2;
        double y2 = y1 + dy2;
        double x3 = x2 + dx3;
        double y3 = y2 + dy3;
        
        pdfmake_path_curve_to(st->path, x1, y1, x2, y2, x3, y3);
        
        st->x = x3;
        st->y = y3;
        
        /* Shift stack */
        for (i = 6; i < st->sp; i++) {
            st->stack[i-6] = st->stack[i];
        }
        st->sp -= 6;
    }
}

static int t2_execute(t2_state_t *st, const uint8_t *cs, size_t len)
{
    const uint8_t *p = cs;
    const uint8_t *end = cs + len;
    int i;
    int subr_num;
    size_t subr_len;
    const uint8_t *subr;
    int32_t ival;
    int consumed;
    
    while (p < end) {
        uint8_t op = *p++;
        
        /* Operands */
        if (op >= 32) {
            double val;
            if (op >= 32 && op <= 246) {
                val = op - 139;
            } else if (op >= 247 && op <= 250) {
                if (p >= end) return -1;
                val = (op - 247) * 256 + *p++ + 108;
            } else if (op >= 251 && op <= 254) {
                if (p >= end) return -1;
                val = -(op - 251) * 256 - *p++ - 108;
            } else if (op == 255) {
                if (p + 4 > end) return -1;
                ival = ((int32_t)p[0] << 24) | ((int32_t)p[1] << 16) |
                               ((int32_t)p[2] << 8) | p[3];
                val = ival / 65536.0;
                p += 4;
            } else if (op == 28) {
                if (p + 2 > end) return -1;
                val = ((int16_t)p[0] << 8) | p[1];
                p += 2;
            } else {
                return -1;
            }
            t2_push(st, val);
            continue;
        }
        
        /* Operators */
        switch (op) {
            case 1: case 3: /* hstem, vstem */
            case 18: case 23: /* hstemhm, vstemhm */
                /* Parse width if first */
                if (!st->width_parsed && (st->sp & 1)) {
                    st->width = st->stack[0];
                    for (i = 1; i < st->sp; i++) {
                        st->stack[i-1] = st->stack[i];
                    }
                    st->sp--;
                    st->width_parsed = 1;
                }
                st->num_hints += st->sp / 2;
                st->sp = 0;
                break;
                
            case 4: /* vmoveto */
                if (!st->width_parsed && st->sp > 1) {
                    st->width = st->stack[0];
                    st->stack[0] = st->stack[1];
                    st->sp--;
                    st->width_parsed = 1;
                }
                st->width_parsed = 1;
                st->x += 0;
                st->y += t2_pop(st);
                pdfmake_path_move_to(st->path, st->x, st->y);
                break;
                
            case 5: /* rlineto */
                t2_rlineto(st);
                break;
                
            case 6: /* hlineto */
                while (st->sp > 0) {
                    st->x += t2_pop(st);
                    pdfmake_path_line_to(st->path, st->x, st->y);
                    if (st->sp > 0) {
                        st->y += t2_pop(st);
                        pdfmake_path_line_to(st->path, st->x, st->y);
                    }
                }
                break;
                
            case 7: /* vlineto */
                while (st->sp > 0) {
                    st->y += t2_pop(st);
                    pdfmake_path_line_to(st->path, st->x, st->y);
                    if (st->sp > 0) {
                        st->x += t2_pop(st);
                        pdfmake_path_line_to(st->path, st->x, st->y);
                    }
                }
                break;
                
            case 8: /* rrcurveto */
                t2_rrcurveto(st);
                break;
                
            case 10: { /* callsubr */
                if (st->sp < 1 || st->depth >= T2_TRANS_MAX) break;
                subr_num = (int)t2_pop(st) + st->font->subr_bias;
                subr = get_index_data(&st->font->subr_index, 
                                                     subr_num, &subr_len);
                if (subr) {
                    st->depth++;
                    t2_execute(st, subr, subr_len);
                    st->depth--;
                }
                break;
            }
                
            case 11: /* return */
                return 0;
                
            case 14: /* endchar */
                if (!st->width_parsed && st->sp > 0) {
                    st->width = st->stack[0];
                }
                pdfmake_path_close(st->path);
                return 0;
                
            case 19: case 20: /* hintmask, cntrmask */
                if (!st->width_parsed && (st->sp & 1)) {
                    st->width = st->stack[0];
                    st->sp--;
                    st->width_parsed = 1;
                }
                st->num_hints += st->sp / 2;
                st->sp = 0;
                /* Skip hint mask bytes */
                p += (st->num_hints + 7) / 8;
                break;
                
            case 21: /* rmoveto */
                if (!st->width_parsed && st->sp > 2) {
                    st->width = st->stack[0];
                    st->stack[0] = st->stack[1];
                    st->stack[1] = st->stack[2];
                    st->sp--;
                    st->width_parsed = 1;
                }
                st->width_parsed = 1;
                t2_rmoveto(st);
                break;
                
            case 22: /* hmoveto */
                if (!st->width_parsed && st->sp > 1) {
                    st->width = st->stack[0];
                    st->stack[0] = st->stack[1];
                    st->sp--;
                    st->width_parsed = 1;
                }
                st->width_parsed = 1;
                st->x += t2_pop(st);
                pdfmake_path_move_to(st->path, st->x, st->y);
                break;
                
            case 24: /* rcurveline */
                while (st->sp >= 8) {
                    t2_rrcurveto(st);
                }
                t2_rlineto(st);
                break;
                
            case 25: /* rlinecurve */
                while (st->sp >= 8) {
                    t2_rlineto(st);
                }
                t2_rrcurveto(st);
                break;
                
            case 26: /* vvcurveto */
                if (st->sp & 1) {
                    st->x += st->stack[0];
                    for (i = 1; i < st->sp; i++) {
                        st->stack[i-1] = st->stack[i];
                    }
                    st->sp--;
                }
                while (st->sp >= 4) {
                    double dy1 = st->stack[0];
                    double dx2 = st->stack[1];
                    double dy2 = st->stack[2];
                    double dy3 = st->stack[3];
                    
                    double x1 = st->x;
                    double y1 = st->y + dy1;
                    double x2 = x1 + dx2;
                    double y2 = y1 + dy2;
                    double x3 = x2;
                    double y3 = y2 + dy3;
                    
                    pdfmake_path_curve_to(st->path, x1, y1, x2, y2, x3, y3);
                    st->x = x3;
                    st->y = y3;
                    
                    for (i = 4; i < st->sp; i++) {
                        st->stack[i-4] = st->stack[i];
                    }
                    st->sp -= 4;
                }
                break;
                
            case 27: /* hhcurveto */
                if (st->sp & 1) {
                    st->y += st->stack[0];
                    for (i = 1; i < st->sp; i++) {
                        st->stack[i-1] = st->stack[i];
                    }
                    st->sp--;
                }
                while (st->sp >= 4) {
                    double dx1 = st->stack[0];
                    double dx2 = st->stack[1];
                    double dy2 = st->stack[2];
                    double dx3 = st->stack[3];
                    
                    double x1 = st->x + dx1;
                    double y1 = st->y;
                    double x2 = x1 + dx2;
                    double y2 = y1 + dy2;
                    double x3 = x2 + dx3;
                    double y3 = y2;
                    
                    pdfmake_path_curve_to(st->path, x1, y1, x2, y2, x3, y3);
                    st->x = x3;
                    st->y = y3;
                    
                    for (i = 4; i < st->sp; i++) {
                        st->stack[i-4] = st->stack[i];
                    }
                    st->sp -= 4;
                }
                break;
                
            case 29: { /* callgsubr */
                if (st->sp < 1 || st->depth >= T2_TRANS_MAX) break;
                subr_num = (int)t2_pop(st) + st->font->gsubr_bias;
                subr = get_index_data(&st->font->gsubr_index,
                                                     subr_num, &subr_len);
                if (subr) {
                    st->depth++;
                    t2_execute(st, subr, subr_len);
                    st->depth--;
                }
                break;
            }
                
            case 30: /* vhcurveto */
            case 31: /* hvcurveto */
                /* Alternating curves */
                {
                    int start_v = (op == 30);
                    while (st->sp >= 4) {
                        double d1 = st->stack[0];
                        double d2 = st->stack[1];
                        double d3 = st->stack[2];
                        double d4 = st->stack[3];
                        double d5 = (st->sp == 5) ? st->stack[4] : 0;
                        
                        double x1, y1, x2, y2, x3, y3;
                        
                        if (start_v) {
                            x1 = st->x;
                            y1 = st->y + d1;
                            x2 = x1 + d2;
                            y2 = y1 + d3;
                            x3 = x2 + d4;
                            y3 = y2 + d5;
                        } else {
                            x1 = st->x + d1;
                            y1 = st->y;
                            x2 = x1 + d2;
                            y2 = y1 + d3;
                            x3 = x2 + d5;
                            y3 = y2 + d4;
                        }
                        
                        pdfmake_path_curve_to(st->path, x1, y1, x2, y2, x3, y3);
                        st->x = x3;
                        st->y = y3;
                        
                        consumed = (st->sp == 5) ? 5 : 4;
                        for (i = consumed; i < st->sp; i++) {
                            st->stack[i-consumed] = st->stack[i];
                        }
                        st->sp -= consumed;
                        start_v = !start_v;
                    }
                }
                break;
                
            case 12: /* escape */
                if (p >= end) return -1;
                op = *p++;
                /* Handle two-byte operators - most not needed for outlines */
                break;
                
            default:
                /* Unknown operator - skip */
                break;
        }
    }
    
    return 0;
}

/*============================================================================
 * CFF Parsing
 *==========================================================================*/

static int compute_subr_bias(int count)
{
    if (count < 1240) return 107;
    if (count < 33900) return 1131;
    return 32768;
}

static int parse_cff_font(const uint8_t *data, size_t len, cff_font_t *font)
{
    const uint8_t *p;
    const uint8_t *end;
    int size;
    size_t dict_len;
    const uint8_t *dict;
    const uint8_t *dp;
    const uint8_t *dict_end;
    cff_operand_t operands[48];
    int num_operands;
    int i;
    const uint8_t *cs_start;
    const uint8_t *priv;
    const uint8_t *priv_end;
    int32_t subrs_offset;
    const uint8_t *subrs;

    memset(font, 0, sizeof(*font));
    font->data = data;
    font->len = len;
    
    if (len < 4) return -1;
    
    /* Parse header */
    font->major = data[0];
    font->minor = data[1];
    font->hdr_size = data[2];
    font->off_size = data[3];
    
    if (font->major != 1) return -1; /* Only CFF version 1 */
    
    p = data + font->hdr_size;
    end = data + len;
    
    /* Parse Name INDEX */
    size = parse_cff_index(p, end, &font->name_index);
    if (size < 0) return -1;
    p += size;
    
    /* Parse Top DICT INDEX */
    size = parse_cff_index(p, end, &font->top_dict_index);
    if (size < 0) return -1;
    p += size;
    
    /* Parse String INDEX */
    size = parse_cff_index(p, end, &font->string_index);
    if (size < 0) return -1;
    p += size;
    
    /* Parse Global Subr INDEX */
    size = parse_cff_index(p, end, &font->gsubr_index);
    if (size < 0) return -1;
    
    font->gsubr_bias = compute_subr_bias(font->gsubr_index.count);
    
    /* Parse Top DICT to find CharStrings offset */
    dict = get_index_data(&font->top_dict_index, 0, &dict_len);
    if (!dict) return -1;
    
    /* Default values */
    font->font_matrix[0] = 0.001;
    font->font_matrix[1] = 0;
    font->font_matrix[2] = 0;
    font->font_matrix[3] = 0.001;
    font->font_matrix[4] = 0;
    font->font_matrix[5] = 0;
    
    /* Parse Top DICT entries */
    dp = dict;
    dict_end = dict + dict_len;
    num_operands = 0;
    
    while (dp < dict_end) {
        uint8_t b = *dp;
        
        if (b >= 32 || b == 28 || b == 29 || b == 30) {
            /* Operand */
            if (num_operands < 48) {
                if (parse_cff_dict_operand(&dp, dict_end, 
                    &operands[num_operands]) == 0) {
                    num_operands++;
                }
            }
        } else {
            /* Operator */
            dp++;
            
            if (b == 12 && dp < dict_end) {
                /* Two-byte operator */
                uint8_t b2 = *dp++;
                
                if (b2 == 7 && num_operands >= 6) {
                    /* FontMatrix */
                    for (i = 0; i < 6; i++) {
                        font->font_matrix[i] = (operands[i].type == CFF_REAL) ?
                            operands[i].val.f : operands[i].val.i;
                    }
                }
            } else {
                switch (b) {
                    case 15: /* charset */
                        if (num_operands > 0) {
                            font->charset_offset = operands[0].val.i;
                        }
                        break;
                    case 16: /* Encoding */
                        if (num_operands > 0) {
                            font->encoding_offset = operands[0].val.i;
                        }
                        break;
                    case 17: /* CharStrings */
                        if (num_operands > 0) {
                            font->charstrings_offset = operands[0].val.i;
                        }
                        break;
                    case 18: /* Private */
                        if (num_operands >= 2) {
                            font->private_size = operands[0].val.i;
                            font->private_offset = operands[1].val.i;
                        }
                        break;
                }
            }
            num_operands = 0;
        }
    }
    
    /* Parse CharStrings INDEX */
    if (font->charstrings_offset > 0) {
        cs_start = data + font->charstrings_offset;
        parse_cff_index(cs_start, end, &font->charstrings_index);
    }
    
    /* Parse Private DICT for Subrs */
    if (font->private_offset > 0 && font->private_size > 0) {
        priv = data + font->private_offset;
        priv_end = priv + font->private_size;
        
        num_operands = 0;
        while (priv < priv_end) {
            uint8_t b = *priv;
            
            if (b >= 32 || b == 28 || b == 29 || b == 30) {
                if (num_operands < 48) {
                    parse_cff_dict_operand(&priv, priv_end, 
                        &operands[num_operands++]);
                }
            } else {
                priv++;
                
                if (b == 19 && num_operands > 0) {
                    /* Subrs */
                    subrs_offset = operands[0].val.i;
                    subrs = data + font->private_offset + subrs_offset;
                    parse_cff_index(subrs, end, &font->subr_index);
                    font->subr_bias = compute_subr_bias(font->subr_index.count);
                } else if (b == 20 && num_operands > 0) {
                    /* defaultWidthX */
                    font->default_width = operands[0].val.i;
                } else if (b == 21 && num_operands > 0) {
                    /* nominalWidthX */
                    font->nominal_width = operands[0].val.i;
                }
                
                num_operands = 0;
            }
        }
    }
    
    return 0;
}

/*============================================================================
 * Public API
 *==========================================================================*/

pdfmake_text_err_t pdfmake_cff_load_glyph(
    pdfmake_glyph_outline_t *outline,
    const uint8_t *cff_data,
    size_t cff_len,
    uint16_t glyph_id,
    pdfmake_arena_t *arena)
{
    cff_font_t font;
    size_t cs_len;
    const uint8_t *cs;
    pdfmake_path_t *path;
    t2_state_t st;

    if (!outline || !cff_data || !arena) {
        return PDFMAKE_TEXT_ERR_NULL;
    }
    
    /* Parse CFF */
    if (parse_cff_font(cff_data, cff_len, &font) < 0) {
        return PDFMAKE_TEXT_ERR_PARSE_ERROR;
    }
    
    /* Get charstring */
    if (glyph_id >= font.charstrings_index.count) {
        return PDFMAKE_TEXT_ERR_GLYPH_NOT_FOUND;
    }
    
    cs = get_index_data(&font.charstrings_index, glyph_id, &cs_len);
    if (!cs) {
        return PDFMAKE_TEXT_ERR_GLYPH_NOT_FOUND;
    }
    
    /* Create path */
    path = pdfmake_path_create();
    if (!path) {
        return PDFMAKE_TEXT_ERR_MEMORY;
    }
    
    /* Execute charstring */
    memset(&st, 0, sizeof(st));
    st.path = path;
    st.arena = arena;
    st.font = &font;
    st.width = font.default_width;
    
    if (t2_execute(&st, cs, cs_len) < 0) {
        return PDFMAKE_TEXT_ERR_PARSE_ERROR;
    }
    
    /* Set outline */
    outline->path = path;
    outline->glyph_id = glyph_id;
    outline->advance_width = st.width + font.nominal_width;
    outline->loaded = 1;
    
    return PDFMAKE_TEXT_OK;
}

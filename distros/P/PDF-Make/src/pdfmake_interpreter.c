/*
 * pdfmake_interpreter.c - Content stream interpreter implementation
 *
 * Reference: PDF 32000-1:2008
 * - §8.4 Graphics state
 * - §9.3 Text state parameters
 * - §9.4 Text objects
 * - Annex A Operators
 */

#include "pdfmake_interpreter.h"
#include "pdfmake_arena.h"
#include "pdfmake_tokenizer.h"
#include "pdfmake_reader.h"
#include "pdfmake_parser.h"
#include "pdfmake_buf.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>

/* Forward declaration — defined later in this file and used by interpret_form. */
static pdfmake_err_t parse_content_stream(pdfmake_interp_t *interp,
                                          const uint8_t *buf, size_t len);

/*============================================================================
 * Constants
 *==========================================================================*/

#define OPERAND_STACK_INIT  32
#define PATH_INIT_CAP       64
#define MC_STACK_INIT       16

/*============================================================================
 * Matrix operations
 *==========================================================================*/

void pdfmake_matrix_identity(double m[6]) {
    m[0] = 1.0; m[1] = 0.0;
    m[2] = 0.0; m[3] = 1.0;
    m[4] = 0.0; m[5] = 0.0;
}

void pdfmake_matrix_copy(double dst[6], const double src[6]) {
    memcpy(dst, src, 6 * sizeof(double));
}

/*
 * Matrix multiplication for 3x3 affine matrices stored as [a b c d e f]:
 * | a  b  0 |   | a'  b'  0 |   | aa'+cb'  ab'+db'  0        |
 * | c  d  0 | × | c'  d'  0 | = | ac'+cd'  bc'+dd'  0        |
 * | e  f  1 |   | e'  f'  1 |   | ae'+cf'+e'  be'+df'+f'  1  |
 */
void pdfmake_matrix_multiply(double result[6], const double a[6], const double b[6]) {
    double r[6];
    r[0] = a[0] * b[0] + a[1] * b[2];
    r[1] = a[0] * b[1] + a[1] * b[3];
    r[2] = a[2] * b[0] + a[3] * b[2];
    r[3] = a[2] * b[1] + a[3] * b[3];
    r[4] = a[4] * b[0] + a[5] * b[2] + b[4];
    r[5] = a[4] * b[1] + a[5] * b[3] + b[5];
    memcpy(result, r, 6 * sizeof(double));
}

void pdfmake_matrix_concat(double m[6], const double other[6]) {
    pdfmake_matrix_multiply(m, m, other);
}

void pdfmake_matrix_translate(double m[6], double tx, double ty) {
    pdfmake_matrix_identity(m);
    m[4] = tx;
    m[5] = ty;
}

void pdfmake_matrix_scale(double m[6], double sx, double sy) {
    pdfmake_matrix_identity(m);
    m[0] = sx;
    m[3] = sy;
}

void pdfmake_matrix_rotate(double m[6], double angle) {
    double c = cos(angle);
    double s = sin(angle);
    m[0] = c;  m[1] = s;
    m[2] = -s; m[3] = c;
    m[4] = 0;  m[5] = 0;
}

int pdfmake_matrix_invert(double result[6], const double m[6]) {
    double det;
    double inv_det;
    det = m[0] * m[3] - m[1] * m[2];
    if (fabs(det) < 1e-10) return -1;  /* Singular */
    
    inv_det = 1.0 / det;
    result[0] =  m[3] * inv_det;
    result[1] = -m[1] * inv_det;
    result[2] = -m[2] * inv_det;
    result[3] =  m[0] * inv_det;
    result[4] = (m[2] * m[5] - m[3] * m[4]) * inv_det;
    result[5] = (m[1] * m[4] - m[0] * m[5]) * inv_det;
    return 0;
}

void pdfmake_matrix_transform_point(const double m[6], double *x, double *y) {
    double px = *x, py = *y;
    *x = m[0] * px + m[2] * py + m[4];
    *y = m[1] * px + m[3] * py + m[5];
}

/*============================================================================
 * Graphics state helpers
 *==========================================================================*/

static void gstate_init(pdfmake_gstate_t *gs) {
    memset(gs, 0, sizeof(*gs));
    
    /* CTM = identity */
    pdfmake_matrix_identity(gs->ctm);
    
    /* Line state defaults (§8.4.3) */
    gs->line_width = 1.0;
    gs->line_cap = PDFMAKE_CAP_BUTT;
    gs->line_join = PDFMAKE_JOIN_MITER;
    gs->miter_limit = 10.0;
    gs->dash_array = NULL;
    gs->dash_count = 0;
    gs->dash_phase = 0.0;
    
    /* Color defaults - black */
    gs->stroke_color.space = PDFMAKE_CS_GRAY;
    gs->stroke_color.components[0] = 0.0;
    gs->stroke_color.n_components = 1;
    gs->fill_color.space = PDFMAKE_CS_GRAY;
    gs->fill_color.components[0] = 0.0;
    gs->fill_color.n_components = 1;
    
    /* Text state defaults (§9.3) */
    gs->char_space = 0.0;
    gs->word_space = 0.0;
    gs->h_scale = 100.0;  /* 100% */
    gs->leading = 0.0;
    gs->font_size = 0.0;
    gs->render_mode = PDFMAKE_RENDER_FILL;
    gs->rise = 0.0;
    gs->font_name = 0;
    gs->font = NULL;
    
    /* Text matrices = identity */
    pdfmake_matrix_identity(gs->text_matrix);
    pdfmake_matrix_identity(gs->text_line_matrix);
    
    /* Other */
    gs->clip_depth = 0;
    gs->flatness = 1.0;
    gs->rendering_intent = 0;
}

static void gstate_copy(pdfmake_gstate_t *dst, const pdfmake_gstate_t *src) {
    /* Copy everything except dash array */
    double *old_dash = dst->dash_array;
    memcpy(dst, src, sizeof(*dst));
    
    /* Deep copy dash array */
    if (src->dash_array && src->dash_count > 0) {
        dst->dash_array = malloc(src->dash_count * sizeof(double));
        if (dst->dash_array) {
            memcpy(dst->dash_array, src->dash_array, 
                   src->dash_count * sizeof(double));
        }
    } else {
        dst->dash_array = NULL;
    }
    
    /* Free old dash array if it was allocated */
    free(old_dash);
}

static void gstate_cleanup(pdfmake_gstate_t *gs) {
    free(gs->dash_array);
    gs->dash_array = NULL;
}

/*============================================================================
 * Interpreter lifecycle
 *==========================================================================*/

pdfmake_interp_t *pdfmake_interp_new(pdfmake_arena_t *arena) {
    pdfmake_interp_t *interp = calloc(1, sizeof(*interp));
    if (!interp) return NULL;
    
    interp->arena = arena;
    
    /* Allocate graphics state stack */
    interp->stack_cap = PDFMAKE_GSTATE_STACK_MAX;
    interp->stack = calloc(interp->stack_cap, sizeof(pdfmake_gstate_t));
    if (!interp->stack) {
        free(interp);
        return NULL;
    }
    
    /* Initialize first state on stack */
    interp->stack_size = 1;
    gstate_init(&interp->stack[0]);
    interp->gs = &interp->stack[0];
    
    /* Allocate operand stack */
    interp->op_cap = OPERAND_STACK_INIT;
    interp->operands = calloc(interp->op_cap, sizeof(pdfmake_obj_t));
    if (!interp->operands) {
        free(interp->stack);
        free(interp);
        return NULL;
    }
    
    /* Allocate path buffer */
    interp->path_cap = PATH_INIT_CAP;
    interp->path = calloc(interp->path_cap, sizeof(pdfmake_path_segment_t));
    if (!interp->path) {
        free(interp->operands);
        free(interp->stack);
        free(interp);
        return NULL;
    }
    
    /* Allocate marked content stack */
    interp->mc_cap = MC_STACK_INIT;
    interp->mc_stack = calloc(interp->mc_cap, sizeof(uint32_t));
    if (!interp->mc_stack) {
        free(interp->path);
        free(interp->operands);
        free(interp->stack);
        free(interp);
        return NULL;
    }
    
    return interp;
}

void pdfmake_interp_free(pdfmake_interp_t *interp) {
    size_t i;
    if (!interp) return;
    
    /* Clean up graphics states */
    for (i = 0; i < interp->stack_size; i++) {
        gstate_cleanup(&interp->stack[i]);
    }
    
    free(interp->stack);
    free(interp->operands);
    free(interp->path);
    free(interp->mc_stack);
    free(interp);
}

void pdfmake_interp_set_resources(pdfmake_interp_t *interp, pdfmake_obj_t *resources) {
    if (interp) {
        interp->resources = resources;
    }
}

void pdfmake_interp_set_visitor(pdfmake_interp_t *interp, const pdfmake_visitor_t *visitor) {
    if (interp) {
        interp->visitor = visitor;
    }
}

void pdfmake_interp_set_reader(pdfmake_interp_t *interp, void *reader) {
    if (interp) interp->reader = reader;
}

void pdfmake_interp_reset(pdfmake_interp_t *interp) {
    size_t i;
    if (!interp) return;
    
    /* Clean up all graphics states */
    for (i = 0; i < interp->stack_size; i++) {
        gstate_cleanup(&interp->stack[i]);
    }
    
    /* Reset to single identity state */
    interp->stack_size = 1;
    gstate_init(&interp->stack[0]);
    interp->gs = &interp->stack[0];
    
    /* Clear other state */
    interp->in_text_object = 0;
    interp->path_size = 0;
    interp->cur_x = interp->cur_y = 0;
    interp->have_cur_point = 0;
    interp->mc_depth = 0;
    interp->op_count = 0;
    
    /* Clear error */
    interp->last_err = PDFMAKE_OK;
    interp->errmsg[0] = '\0';
    interp->erroffset = 0;
}

const char *pdfmake_interp_errmsg(pdfmake_interp_t *interp) {
    return interp ? interp->errmsg : "";
}

size_t pdfmake_interp_erroffset(pdfmake_interp_t *interp) {
    return interp ? interp->erroffset : 0;
}

const pdfmake_gstate_t *pdfmake_interp_gstate(pdfmake_interp_t *interp) {
    return interp ? interp->gs : NULL;
}

int pdfmake_interp_in_text_object(pdfmake_interp_t *interp) {
    return interp ? interp->in_text_object : 0;
}

int pdfmake_interp_get_current_point(pdfmake_interp_t *interp, double *x, double *y) {
    if (!interp || !interp->have_cur_point) return 0;
    if (x) *x = interp->cur_x;
    if (y) *y = interp->cur_y;
    return 1;
}

/*============================================================================
 * Error handling
 *==========================================================================*/

static void set_error(pdfmake_interp_t *interp, pdfmake_err_t err,
                      size_t offset, const char *msg) {
    interp->last_err = err;
    interp->erroffset = offset;
    if (msg) {
        strncpy(interp->errmsg, msg, sizeof(interp->errmsg) - 1);
        interp->errmsg[sizeof(interp->errmsg) - 1] = '\0';
    }
}

/*============================================================================
 * Operand stack operations
 *==========================================================================*/

static int push_operand(pdfmake_interp_t *interp, pdfmake_obj_t obj) {
    if (interp->op_count >= interp->op_cap) {
        size_t new_cap = interp->op_cap * 2;
        pdfmake_obj_t *new_ops = realloc(interp->operands, 
                                          new_cap * sizeof(pdfmake_obj_t));
        if (!new_ops) return 0;
        interp->operands = new_ops;
        interp->op_cap = new_cap;
    }
    interp->operands[interp->op_count++] = obj;
    return 1;
}

static pdfmake_obj_t pop_operand(pdfmake_interp_t *interp) {
    if (interp->op_count == 0) {
        return pdfmake_null();
    }
    return interp->operands[--interp->op_count];
}

static void clear_operands(pdfmake_interp_t *interp) {
    interp->op_count = 0;
}

/* Helper to get numeric operand */
static double get_number(pdfmake_obj_t obj) {
    if (obj.kind == PDFMAKE_INT) return (double)obj.as.i;
    if (obj.kind == PDFMAKE_REAL) return obj.as.r;
    return 0.0;
}

/*============================================================================
 * Graphics state stack operations (q/Q)
 *==========================================================================*/

static pdfmake_err_t gstate_push(pdfmake_interp_t *interp) {
    pdfmake_gstate_t *new_gs;
    if (interp->stack_size >= PDFMAKE_GSTATE_STACK_MAX) {
        set_error(interp, PDFMAKE_ESTACK_OVER, 0, 
                  "Graphics state stack overflow");
        return PDFMAKE_ESTACK_OVER;
    }
    
    /* Deep copy current state to new top */
    new_gs = &interp->stack[interp->stack_size];
    gstate_init(new_gs);  /* Initialize to clear any garbage */
    gstate_copy(new_gs, interp->gs);
    
    interp->stack_size++;
    interp->gs = new_gs;
    
    return PDFMAKE_OK;
}

static pdfmake_err_t gstate_pop(pdfmake_interp_t *interp) {
    if (interp->stack_size <= 1) {
        set_error(interp, PDFMAKE_ESTACK_UNDER, 0,
                  "Graphics state stack underflow");
        return PDFMAKE_ESTACK_UNDER;
    }
    
    /* Clean up current state */
    gstate_cleanup(interp->gs);
    
    interp->stack_size--;
    interp->gs = &interp->stack[interp->stack_size - 1];
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Path operations
 *==========================================================================*/

static int path_ensure_cap(pdfmake_interp_t *interp, size_t need) {
    size_t new_cap;
    pdfmake_path_segment_t *new_path;
    if (interp->path_size + need > interp->path_cap) {
        new_cap = interp->path_cap * 2;
        while (new_cap < interp->path_size + need) new_cap *= 2;
        new_path = realloc(interp->path,
                           new_cap * sizeof(pdfmake_path_segment_t));
        if (!new_path) return 0;
        interp->path = new_path;
        interp->path_cap = new_cap;
    }
    return 1;
}

static void path_add_segment(pdfmake_interp_t *interp, pdfmake_path_segment_t seg) {
    if (path_ensure_cap(interp, 1)) {
        interp->path[interp->path_size++] = seg;
    }
}

static void path_clear(pdfmake_interp_t *interp) {
    interp->path_size = 0;
    interp->have_cur_point = 0;
}

/*============================================================================
 * Resource lookup
 *==========================================================================*/

static pdfmake_obj_t *lookup_resource(pdfmake_interp_t *interp,
                                       const char *category,
                                       uint32_t name_id) {
    uint32_t cat_id;
    pdfmake_obj_t *cat_dict;
    if (!interp->resources || interp->resources->kind != PDFMAKE_DICT) {
        return NULL;
    }

    /* Get category dict */
    cat_id = pdfmake_arena_intern_name(interp->arena, category, strlen(category));
    cat_dict = pdfmake_dict_get(interp->resources, cat_id);
    if (!cat_dict || cat_dict->kind != PDFMAKE_DICT) {
        return NULL;
    }

    /* Get resource by name */
    return pdfmake_dict_get(cat_dict, name_id);
}

/*============================================================================
 * Text operators
 *==========================================================================*/

/* BT - Begin text object */
static pdfmake_err_t op_BT(pdfmake_interp_t *interp) {
    if (interp->in_text_object) {
        set_error(interp, PDFMAKE_ETEXTOBJ, 0, "Nested BT");
        return PDFMAKE_ETEXTOBJ;
    }
    interp->in_text_object = 1;
    
    /* Reset text matrices to identity */
    pdfmake_matrix_identity(interp->gs->text_matrix);
    pdfmake_matrix_identity(interp->gs->text_line_matrix);
    
    return PDFMAKE_OK;
}

/* ET - End text object */
static pdfmake_err_t op_ET(pdfmake_interp_t *interp) {
    if (!interp->in_text_object) {
        set_error(interp, PDFMAKE_ETEXTOBJ, 0, "ET without BT");
        return PDFMAKE_ETEXTOBJ;
    }
    interp->in_text_object = 0;
    return PDFMAKE_OK;
}

/* Tc - Set character spacing */
static pdfmake_err_t op_Tc(pdfmake_interp_t *interp) {
    pdfmake_obj_t charSpace = pop_operand(interp);
    interp->gs->char_space = get_number(charSpace);
    return PDFMAKE_OK;
}

/* Tw - Set word spacing */
static pdfmake_err_t op_Tw(pdfmake_interp_t *interp) {
    pdfmake_obj_t wordSpace = pop_operand(interp);
    interp->gs->word_space = get_number(wordSpace);
    return PDFMAKE_OK;
}

/* Tz - Set horizontal scaling */
static pdfmake_err_t op_Tz(pdfmake_interp_t *interp) {
    pdfmake_obj_t scale = pop_operand(interp);
    interp->gs->h_scale = get_number(scale);
    return PDFMAKE_OK;
}

/* TL - Set text leading */
static pdfmake_err_t op_TL(pdfmake_interp_t *interp) {
    pdfmake_obj_t leading = pop_operand(interp);
    interp->gs->leading = get_number(leading);
    return PDFMAKE_OK;
}

/* Tf - Set text font and size */
static pdfmake_err_t op_Tf(pdfmake_interp_t *interp) {
    pdfmake_obj_t size = pop_operand(interp);
    pdfmake_obj_t font = pop_operand(interp);
    
    interp->gs->font_size = get_number(size);
    
    if (font.kind == PDFMAKE_NAME) {
        interp->gs->font_name = font.as.name.id;
        /* Look up font in resources */
        interp->gs->font = lookup_resource(interp, "Font", font.as.name.id);
    }
    
    return PDFMAKE_OK;
}

/* Tr - Set text rendering mode */
static pdfmake_err_t op_Tr(pdfmake_interp_t *interp) {
    pdfmake_obj_t render = pop_operand(interp);
    int mode = (int)get_number(render);
    if (mode >= 0 && mode <= 7) {
        interp->gs->render_mode = mode;
    }
    return PDFMAKE_OK;
}

/* Ts - Set text rise */
static pdfmake_err_t op_Ts(pdfmake_interp_t *interp) {
    pdfmake_obj_t rise = pop_operand(interp);
    interp->gs->rise = get_number(rise);
    return PDFMAKE_OK;
}

/* Td - Move text position */
static pdfmake_err_t op_Td(pdfmake_interp_t *interp) {
    pdfmake_obj_t ty = pop_operand(interp);
    pdfmake_obj_t tx = pop_operand(interp);
    
    double m[6];
    pdfmake_matrix_translate(m, get_number(tx), get_number(ty));
    pdfmake_matrix_multiply(interp->gs->text_line_matrix, 
                            m, interp->gs->text_line_matrix);
    pdfmake_matrix_copy(interp->gs->text_matrix, interp->gs->text_line_matrix);
    
    return PDFMAKE_OK;
}

/* TD - Move text position and set leading */
static pdfmake_err_t op_TD(pdfmake_interp_t *interp) {
    pdfmake_obj_t ty = pop_operand(interp);
    pdfmake_obj_t tx = pop_operand(interp);
    double m[6];
    
    interp->gs->leading = -get_number(ty);
    
    pdfmake_matrix_translate(m, get_number(tx), get_number(ty));
    pdfmake_matrix_multiply(interp->gs->text_line_matrix,
                            m, interp->gs->text_line_matrix);
    pdfmake_matrix_copy(interp->gs->text_matrix, interp->gs->text_line_matrix);
    
    return PDFMAKE_OK;
}

/* Tm - Set text matrix */
static pdfmake_err_t op_Tm(pdfmake_interp_t *interp) {
    pdfmake_obj_t f = pop_operand(interp);
    pdfmake_obj_t e = pop_operand(interp);
    pdfmake_obj_t d = pop_operand(interp);
    pdfmake_obj_t c = pop_operand(interp);
    pdfmake_obj_t b = pop_operand(interp);
    pdfmake_obj_t a = pop_operand(interp);
    
    interp->gs->text_matrix[0] = get_number(a);
    interp->gs->text_matrix[1] = get_number(b);
    interp->gs->text_matrix[2] = get_number(c);
    interp->gs->text_matrix[3] = get_number(d);
    interp->gs->text_matrix[4] = get_number(e);
    interp->gs->text_matrix[5] = get_number(f);
    
    pdfmake_matrix_copy(interp->gs->text_line_matrix, interp->gs->text_matrix);
    
    return PDFMAKE_OK;
}

/* T* - Move to start of next line */
static pdfmake_err_t op_Tstar(pdfmake_interp_t *interp) {
    double m[6];
    pdfmake_matrix_translate(m, 0, -interp->gs->leading);
    pdfmake_matrix_multiply(interp->gs->text_line_matrix,
                            m, interp->gs->text_line_matrix);
    pdfmake_matrix_copy(interp->gs->text_matrix, interp->gs->text_line_matrix);
    return PDFMAKE_OK;
}

/* Helper: advance text matrix by string width */
static void advance_text_matrix(pdfmake_interp_t *interp,
                                 const uint8_t *bytes, size_t len) {
    double width;
    size_t char_count;
    size_t space_count;
    size_t i;
    double avg_glyph_width;
    int vertical;
    double m[6];

    width = 0;

    /* Phase 8: if the visitor can compute the real text-space advance
     * (using resolved font widths), use that. This keeps text_matrix in
     * sync with the visitor's glyph positions across Tj/TJ calls, which
     * is essential for accurate inter-run gap detection. */
    if (interp->visitor && interp->visitor->get_string_advance) {
        width = interp->visitor->get_string_advance(
            interp->visitor->ctx, interp->gs, bytes, len);
    }

    if (width <= 0) {
        /* Fallback: 0.6-em placeholder per character, plus char/word space */
        char_count = len;
        space_count = 0;
        for (i = 0; i < len; i++) {
            if (bytes[i] == ' ') space_count++;
        }
        avg_glyph_width = 0.6 * interp->gs->font_size;
        width = char_count * avg_glyph_width
              + char_count * interp->gs->char_space
              + space_count * interp->gs->word_space;
    }

    width *= interp->gs->h_scale / 100.0;

    /* Phase 14: vertical writing advances along -y, not +x. */
    vertical = 0;
    if (interp->visitor && interp->visitor->is_vertical_writing) {
        vertical = interp->visitor->is_vertical_writing(
            interp->visitor->ctx, interp->gs);
    }

    if (vertical) {
        pdfmake_matrix_translate(m, 0, -width);
    } else {
        pdfmake_matrix_translate(m, width, 0);
    }
    pdfmake_matrix_multiply(interp->gs->text_matrix,
                            m, interp->gs->text_matrix);
}

/* Tj - Show text string */
/* Convert ASCII hex-digit byte to its 0-15 value, or -1 if not a hex digit. */
static int hex_val(uint8_t c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

/* If the string is a hex string (`<AB CD>` form), decode it into a fresh
 * arena-backed byte array. Whitespace is skipped; odd trailing nibble is
 * padded with 0 per PDF spec.
 * Returns 1 if decoded (caller uses *out_bytes), 0 if not a hex string. */
static int maybe_decode_hex_string(pdfmake_arena_t *arena,
                                    const pdfmake_obj_t *str,
                                    const uint8_t **out_bytes,
                                    size_t *out_len)
{
    const uint8_t *in;
    size_t in_len;
    uint8_t *out;
    size_t written;
    int nibble;
    size_t i;

    if (!str || str->kind != PDFMAKE_STR || !str->as.str.hex) return 0;

    in = str->as.str.bytes;
    in_len = str->as.str.len;

    /* Max output is ceil(in_len / 2) — safe upper bound */
    out = pdfmake_arena_alloc(arena, (in_len / 2) + 1);
    if (!out) return 0;

    written = 0;
    nibble = -1;
    for (i = 0; i < in_len; i++) {
        int v = hex_val(in[i]);
        if (v < 0) continue;          /* skip whitespace, ignore garbage */
        if (nibble < 0) {
            nibble = v;
        } else {
            out[written++] = (uint8_t)((nibble << 4) | v);
            nibble = -1;
        }
    }
    if (nibble >= 0) out[written++] = (uint8_t)(nibble << 4);

    *out_bytes = out;
    *out_len = written;
    return 1;
}

static pdfmake_err_t op_Tj(pdfmake_interp_t *interp) {
    pdfmake_obj_t str;
    const uint8_t *bytes;
    size_t len;

    if (!interp->in_text_object) {
        /* Lenient: just skip */
        clear_operands(interp);
        return PDFMAKE_OK;
    }

    str = pop_operand(interp);

    bytes = NULL;
    len = 0;

    if (str.kind == PDFMAKE_STR) {
        if (str.as.str.hex) {
            /* Decode <ABCD...> → raw bytes */
            if (!maybe_decode_hex_string(interp->arena, &str, &bytes, &len)) {
                bytes = str.as.str.bytes;
                len = str.as.str.len;
            }
        } else {
            bytes = str.as.str.bytes;
            len = str.as.str.len;
        }
    }
    
    /* Fire visitor callback */
    if (interp->visitor && interp->visitor->on_text_show && bytes) {
        interp->visitor->on_text_show(interp->visitor->ctx, 
                                       interp->gs, bytes, len);
    }
    
    /* Advance text matrix */
    if (bytes && len > 0) {
        advance_text_matrix(interp, bytes, len);
    }
    
    return PDFMAKE_OK;
}

/* TJ - Show text with positioning */
static pdfmake_err_t op_TJ(pdfmake_interp_t *interp) {
    pdfmake_obj_t arr;
    size_t arr_len;
    size_t i;

    if (!interp->in_text_object) {
        clear_operands(interp);
        return PDFMAKE_OK;
    }
    
    arr = pop_operand(interp);
    
    if (arr.kind != PDFMAKE_ARRAY) {
        return PDFMAKE_OK;
    }
    
    arr_len = pdfmake_array_len(&arr);
    
    for (i = 0; i < arr_len; i++) {
        pdfmake_obj_t *elem = pdfmake_array_get(&arr, i);
        if (!elem) continue;
        
        if (elem->kind == PDFMAKE_STR) {
            /* String element - show text. Decode hex strings first. */
            const uint8_t *bytes;
            size_t len;
            if (elem->as.str.hex) {
                if (!maybe_decode_hex_string(interp->arena, elem, &bytes, &len)) {
                    bytes = elem->as.str.bytes;
                    len   = elem->as.str.len;
                }
            } else {
                bytes = elem->as.str.bytes;
                len   = elem->as.str.len;
            }

            if (interp->visitor && interp->visitor->on_text_show) {
                interp->visitor->on_text_show(interp->visitor->ctx,
                                               interp->gs, bytes, len);
            }

            advance_text_matrix(interp, bytes, len);
            
        } else if (elem->kind == PDFMAKE_INT || elem->kind == PDFMAKE_REAL) {
            /* Numeric element - adjust position.
             * Value is in thousandths of a text space unit.
             * Positive moves left (decreases position). */
            double adj = get_number(*elem);
            double tx = -adj * interp->gs->font_size / 1000.0 
                       * interp->gs->h_scale / 100.0;
            
            double m[6];
            pdfmake_matrix_translate(m, tx, 0);
            pdfmake_matrix_multiply(interp->gs->text_matrix,
                                    m, interp->gs->text_matrix);
        }
    }
    
    return PDFMAKE_OK;
}

/* ' - Move to next line and show text */
static pdfmake_err_t op_quote(pdfmake_interp_t *interp) {
    op_Tstar(interp);
    return op_Tj(interp);
}

/* " - Set spacing, move to next line, show text */
static pdfmake_err_t op_dquote(pdfmake_interp_t *interp) {
    pdfmake_obj_t str = pop_operand(interp);
    pdfmake_obj_t ac = pop_operand(interp);
    pdfmake_obj_t aw = pop_operand(interp);
    
    interp->gs->word_space = get_number(aw);
    interp->gs->char_space = get_number(ac);
    
    push_operand(interp, str);
    op_Tstar(interp);
    return op_Tj(interp);
}

/*============================================================================
 * Graphics state operators
 *==========================================================================*/

/* q - Save graphics state */
static pdfmake_err_t op_q(pdfmake_interp_t *interp) {
    return gstate_push(interp);
}

/* Q - Restore graphics state */
static pdfmake_err_t op_Q(pdfmake_interp_t *interp) {
    return gstate_pop(interp);
}

/* cm - Concatenate matrix */
static pdfmake_err_t op_cm(pdfmake_interp_t *interp) {
    pdfmake_obj_t f = pop_operand(interp);
    pdfmake_obj_t e = pop_operand(interp);
    pdfmake_obj_t d = pop_operand(interp);
    pdfmake_obj_t c = pop_operand(interp);
    pdfmake_obj_t b = pop_operand(interp);
    pdfmake_obj_t a = pop_operand(interp);
    
    double m[6];
    m[0] = get_number(a);
    m[1] = get_number(b);
    m[2] = get_number(c);
    m[3] = get_number(d);
    m[4] = get_number(e);
    m[5] = get_number(f);
    
    pdfmake_matrix_concat(interp->gs->ctm, m);
    
    return PDFMAKE_OK;
}

/* w - Set line width */
static pdfmake_err_t op_w(pdfmake_interp_t *interp) {
    pdfmake_obj_t width = pop_operand(interp);
    interp->gs->line_width = get_number(width);
    return PDFMAKE_OK;
}

/* J - Set line cap */
static pdfmake_err_t op_J(pdfmake_interp_t *interp) {
    pdfmake_obj_t cap = pop_operand(interp);
    int c = (int)get_number(cap);
    if (c >= 0 && c <= 2) {
        interp->gs->line_cap = c;
    }
    return PDFMAKE_OK;
}

/* j - Set line join */
static pdfmake_err_t op_j(pdfmake_interp_t *interp) {
    pdfmake_obj_t join = pop_operand(interp);
    int j = (int)get_number(join);
    if (j >= 0 && j <= 2) {
        interp->gs->line_join = j;
    }
    return PDFMAKE_OK;
}

/* M - Set miter limit */
static pdfmake_err_t op_M(pdfmake_interp_t *interp) {
    pdfmake_obj_t ml = pop_operand(interp);
    interp->gs->miter_limit = get_number(ml);
    return PDFMAKE_OK;
}

/* d - Set dash pattern */
static pdfmake_err_t op_d(pdfmake_interp_t *interp) {
    pdfmake_obj_t phase = pop_operand(interp);
    pdfmake_obj_t array = pop_operand(interp);
    size_t i;
    
    /* Free old dash array */
    free(interp->gs->dash_array);
    interp->gs->dash_array = NULL;
    interp->gs->dash_count = 0;
    interp->gs->dash_phase = get_number(phase);
    
    if (array.kind == PDFMAKE_ARRAY) {
        size_t n = pdfmake_array_len(&array);
        if (n > 0) {
            interp->gs->dash_array = malloc(n * sizeof(double));
            if (interp->gs->dash_array) {
                interp->gs->dash_count = n;
                for (i = 0; i < n; i++) {
                    pdfmake_obj_t *v = pdfmake_array_get(&array, i);
                    interp->gs->dash_array[i] = v ? get_number(*v) : 0;
                }
            }
        }
    }
    
    return PDFMAKE_OK;
}

/* i - Set flatness */
static pdfmake_err_t op_i(pdfmake_interp_t *interp) {
    pdfmake_obj_t flat = pop_operand(interp);
    interp->gs->flatness = get_number(flat);
    return PDFMAKE_OK;
}

/* gs - Set graphics state from ExtGState dict */
static pdfmake_err_t op_gs(pdfmake_interp_t *interp) {
    pdfmake_obj_t name = pop_operand(interp);
    pdfmake_obj_t *dict;
    
    if (name.kind != PDFMAKE_NAME) {
        return PDFMAKE_OK;
    }
    
    /* Look up in ExtGState resources */
    dict = lookup_resource(interp, "ExtGState", name.as.name.id);
    if (!dict || dict->kind != PDFMAKE_DICT) {
        return PDFMAKE_OK;
    }
    
    /* Apply relevant settings from dict */
    /* This is simplified - full implementation would handle all ExtGState keys */
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Path construction operators
 *==========================================================================*/

/* m - moveto */
static pdfmake_err_t op_m(pdfmake_interp_t *interp) {
    pdfmake_obj_t y = pop_operand(interp);
    pdfmake_obj_t x = pop_operand(interp);
    
    pdfmake_path_segment_t seg = {0};
    seg.op = PDFMAKE_PATH_MOVE;
    seg.x1 = get_number(x);
    seg.y1 = get_number(y);
    
    path_add_segment(interp, seg);
    interp->cur_x = seg.x1;
    interp->cur_y = seg.y1;
    interp->have_cur_point = 1;
    
    return PDFMAKE_OK;
}

/* l - lineto */
static pdfmake_err_t op_l(pdfmake_interp_t *interp) {
    pdfmake_obj_t y = pop_operand(interp);
    pdfmake_obj_t x = pop_operand(interp);
    
    pdfmake_path_segment_t seg = {0};
    seg.op = PDFMAKE_PATH_LINE;
    seg.x1 = get_number(x);
    seg.y1 = get_number(y);
    
    path_add_segment(interp, seg);
    interp->cur_x = seg.x1;
    interp->cur_y = seg.y1;
    
    return PDFMAKE_OK;
}

/* c - curveto (cubic Bézier) */
static pdfmake_err_t op_c(pdfmake_interp_t *interp) {
    pdfmake_obj_t y3 = pop_operand(interp);
    pdfmake_obj_t x3 = pop_operand(interp);
    pdfmake_obj_t y2 = pop_operand(interp);
    pdfmake_obj_t x2 = pop_operand(interp);
    pdfmake_obj_t y1 = pop_operand(interp);
    pdfmake_obj_t x1 = pop_operand(interp);
    
    pdfmake_path_segment_t seg = {0};
    seg.op = PDFMAKE_PATH_CURVE;
    seg.x1 = get_number(x1);
    seg.y1 = get_number(y1);
    seg.x2 = get_number(x2);
    seg.y2 = get_number(y2);
    seg.x3 = get_number(x3);
    seg.y3 = get_number(y3);
    
    path_add_segment(interp, seg);
    interp->cur_x = seg.x3;
    interp->cur_y = seg.y3;
    
    return PDFMAKE_OK;
}

/* v - curveto (initial point replicated) */
static pdfmake_err_t op_v(pdfmake_interp_t *interp) {
    pdfmake_obj_t y3 = pop_operand(interp);
    pdfmake_obj_t x3 = pop_operand(interp);
    pdfmake_obj_t y2 = pop_operand(interp);
    pdfmake_obj_t x2 = pop_operand(interp);
    
    pdfmake_path_segment_t seg = {0};
    seg.op = PDFMAKE_PATH_CURVE_V;
    seg.x1 = interp->cur_x;  /* First control point = current point */
    seg.y1 = interp->cur_y;
    seg.x2 = get_number(x2);
    seg.y2 = get_number(y2);
    seg.x3 = get_number(x3);
    seg.y3 = get_number(y3);
    
    path_add_segment(interp, seg);
    interp->cur_x = seg.x3;
    interp->cur_y = seg.y3;
    
    return PDFMAKE_OK;
}

/* y - curveto (final point replicated) */
static pdfmake_err_t op_y(pdfmake_interp_t *interp) {
    pdfmake_obj_t y3 = pop_operand(interp);
    pdfmake_obj_t x3 = pop_operand(interp);
    pdfmake_obj_t y1 = pop_operand(interp);
    pdfmake_obj_t x1 = pop_operand(interp);
    
    pdfmake_path_segment_t seg = {0};
    seg.op = PDFMAKE_PATH_CURVE_Y;
    seg.x1 = get_number(x1);
    seg.y1 = get_number(y1);
    seg.x2 = get_number(x3);  /* Second control point = endpoint */
    seg.y2 = get_number(y3);
    seg.x3 = get_number(x3);
    seg.y3 = get_number(y3);
    
    path_add_segment(interp, seg);
    interp->cur_x = seg.x3;
    interp->cur_y = seg.y3;
    
    return PDFMAKE_OK;
}

/* h - closepath */
static pdfmake_err_t op_h(pdfmake_interp_t *interp) {
    pdfmake_path_segment_t seg = {0};
    seg.op = PDFMAKE_PATH_CLOSE;
    path_add_segment(interp, seg);
    return PDFMAKE_OK;
}

/* re - rectangle */
static pdfmake_err_t op_re(pdfmake_interp_t *interp) {
    pdfmake_obj_t height = pop_operand(interp);
    pdfmake_obj_t width = pop_operand(interp);
    pdfmake_obj_t y = pop_operand(interp);
    pdfmake_obj_t x = pop_operand(interp);
    
    pdfmake_path_segment_t seg = {0};
    seg.op = PDFMAKE_PATH_RECT;
    seg.x1 = get_number(x);
    seg.y1 = get_number(y);
    seg.width = get_number(width);
    seg.height = get_number(height);
    
    path_add_segment(interp, seg);
    interp->cur_x = seg.x1;
    interp->cur_y = seg.y1;
    interp->have_cur_point = 1;
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Path painting operators
 *==========================================================================*/

static void fire_path_callback(pdfmake_interp_t *interp, 
                                int stroke, int fill, int even_odd) {
    if (interp->visitor && interp->visitor->on_path && interp->path_size > 0) {
        interp->visitor->on_path(interp->visitor->ctx,
                                  interp->gs,
                                  interp->path,
                                  interp->path_size,
                                  stroke, fill, even_odd);
    }
    path_clear(interp);
}

/* S - Stroke path */
static pdfmake_err_t op_S(pdfmake_interp_t *interp) {
    fire_path_callback(interp, 1, 0, 0);
    return PDFMAKE_OK;
}

/* s - Close and stroke path */
static pdfmake_err_t op_s(pdfmake_interp_t *interp) {
    op_h(interp);
    fire_path_callback(interp, 1, 0, 0);
    return PDFMAKE_OK;
}

/* f / F - Fill path (nonzero winding) */
static pdfmake_err_t op_f(pdfmake_interp_t *interp) {
    fire_path_callback(interp, 0, 1, 0);
    return PDFMAKE_OK;
}

/* f* - Fill path (even-odd rule) */
static pdfmake_err_t op_fstar(pdfmake_interp_t *interp) {
    fire_path_callback(interp, 0, 1, 1);
    return PDFMAKE_OK;
}

/* B - Fill and stroke path (nonzero winding) */
static pdfmake_err_t op_B(pdfmake_interp_t *interp) {
    fire_path_callback(interp, 1, 1, 0);
    return PDFMAKE_OK;
}

/* B* - Fill and stroke path (even-odd rule) */
static pdfmake_err_t op_Bstar(pdfmake_interp_t *interp) {
    fire_path_callback(interp, 1, 1, 1);
    return PDFMAKE_OK;
}

/* b - Close, fill, and stroke path (nonzero winding) */
static pdfmake_err_t op_b(pdfmake_interp_t *interp) {
    op_h(interp);
    fire_path_callback(interp, 1, 1, 0);
    return PDFMAKE_OK;
}

/* b* - Close, fill, and stroke path (even-odd rule) */
static pdfmake_err_t op_bstar(pdfmake_interp_t *interp) {
    op_h(interp);
    fire_path_callback(interp, 1, 1, 1);
    return PDFMAKE_OK;
}

/* n - End path without filling or stroking */
static pdfmake_err_t op_n(pdfmake_interp_t *interp) {
    path_clear(interp);
    return PDFMAKE_OK;
}

/*============================================================================
 * Clipping path operators
 *==========================================================================*/

/* W - Set clipping path (nonzero) */
static pdfmake_err_t op_W(pdfmake_interp_t *interp) {
    interp->gs->clip_depth++;
    return PDFMAKE_OK;
}

/* W* - Set clipping path (even-odd) */
static pdfmake_err_t op_Wstar(pdfmake_interp_t *interp) {
    interp->gs->clip_depth++;
    return PDFMAKE_OK;
}

/*============================================================================
 * Color operators (simplified)
 *==========================================================================*/

/* g - Set gray fill color */
static pdfmake_err_t op_g(pdfmake_interp_t *interp) {
    pdfmake_obj_t gray = pop_operand(interp);
    interp->gs->fill_color.space = PDFMAKE_CS_GRAY;
    interp->gs->fill_color.components[0] = get_number(gray);
    interp->gs->fill_color.n_components = 1;
    return PDFMAKE_OK;
}

/* G - Set gray stroke color */
static pdfmake_err_t op_G(pdfmake_interp_t *interp) {
    pdfmake_obj_t gray = pop_operand(interp);
    interp->gs->stroke_color.space = PDFMAKE_CS_GRAY;
    interp->gs->stroke_color.components[0] = get_number(gray);
    interp->gs->stroke_color.n_components = 1;
    return PDFMAKE_OK;
}

/* rg - Set RGB fill color */
static pdfmake_err_t op_rg(pdfmake_interp_t *interp) {
    pdfmake_obj_t b = pop_operand(interp);
    pdfmake_obj_t g = pop_operand(interp);
    pdfmake_obj_t r = pop_operand(interp);
    interp->gs->fill_color.space = PDFMAKE_CS_RGB;
    interp->gs->fill_color.components[0] = get_number(r);
    interp->gs->fill_color.components[1] = get_number(g);
    interp->gs->fill_color.components[2] = get_number(b);
    interp->gs->fill_color.n_components = 3;
    return PDFMAKE_OK;
}

/* RG - Set RGB stroke color */
static pdfmake_err_t op_RG(pdfmake_interp_t *interp) {
    pdfmake_obj_t b = pop_operand(interp);
    pdfmake_obj_t g = pop_operand(interp);
    pdfmake_obj_t r = pop_operand(interp);
    interp->gs->stroke_color.space = PDFMAKE_CS_RGB;
    interp->gs->stroke_color.components[0] = get_number(r);
    interp->gs->stroke_color.components[1] = get_number(g);
    interp->gs->stroke_color.components[2] = get_number(b);
    interp->gs->stroke_color.n_components = 3;
    return PDFMAKE_OK;
}

/* k - Set CMYK fill color */
static pdfmake_err_t op_k(pdfmake_interp_t *interp) {
    pdfmake_obj_t kk = pop_operand(interp);
    pdfmake_obj_t y = pop_operand(interp);
    pdfmake_obj_t m = pop_operand(interp);
    pdfmake_obj_t c = pop_operand(interp);
    interp->gs->fill_color.space = PDFMAKE_CS_CMYK;
    interp->gs->fill_color.components[0] = get_number(c);
    interp->gs->fill_color.components[1] = get_number(m);
    interp->gs->fill_color.components[2] = get_number(y);
    interp->gs->fill_color.components[3] = get_number(kk);
    interp->gs->fill_color.n_components = 4;
    return PDFMAKE_OK;
}

/* K - Set CMYK stroke color */
static pdfmake_err_t op_K(pdfmake_interp_t *interp) {
    pdfmake_obj_t kk = pop_operand(interp);
    pdfmake_obj_t y = pop_operand(interp);
    pdfmake_obj_t m = pop_operand(interp);
    pdfmake_obj_t c = pop_operand(interp);
    interp->gs->stroke_color.space = PDFMAKE_CS_CMYK;
    interp->gs->stroke_color.components[0] = get_number(c);
    interp->gs->stroke_color.components[1] = get_number(m);
    interp->gs->stroke_color.components[2] = get_number(y);
    interp->gs->stroke_color.components[3] = get_number(kk);
    interp->gs->stroke_color.n_components = 4;
    return PDFMAKE_OK;
}

/*============================================================================
 * XObject operators
 *==========================================================================*/

/* Look up XObject in resources, returning (obj, num, gen).
 * If the resource is stored by reference, num/gen are filled; otherwise 0. */
static pdfmake_obj_t *lookup_xobject_with_ref(pdfmake_interp_t *interp,
                                                uint32_t name_id,
                                                uint32_t *out_num,
                                                uint16_t *out_gen) {
    uint32_t cat_id;
    pdfmake_obj_t *cat;
    pdfmake_obj_t *entry;

    *out_num = 0;
    *out_gen = 0;
    if (!interp->resources || interp->resources->kind != PDFMAKE_DICT)
        return NULL;

    cat_id = pdfmake_arena_intern_name(interp->arena, "XObject", 7);
    cat = pdfmake_dict_get(interp->resources, cat_id);
    if (!cat) return NULL;
    /* Follow indirect ref */
    if (cat->kind == PDFMAKE_REF && interp->reader) {
        pdfmake_reader_t *rd = (pdfmake_reader_t *)interp->reader;
        if (rd->parser) {
            cat = pdfmake_parser_resolve(rd->parser, cat->as.ref);
        }
    }
    if (!cat || cat->kind != PDFMAKE_DICT) return NULL;

    entry = pdfmake_dict_get(cat, name_id);
    if (!entry) return NULL;
    if (entry->kind == PDFMAKE_REF) {
        *out_num = entry->as.ref.num;
        *out_gen = entry->as.ref.gen;
        /* Resolve to concrete object via the reader's parser */
        if (interp->reader) {
            pdfmake_reader_t *rd = (pdfmake_reader_t *)interp->reader;
            if (rd->parser)
                return pdfmake_parser_resolve(rd->parser, entry->as.ref);
        }
        return NULL;
    }
    return entry;
}

/* Interpret a Form XObject's content stream with the form's Matrix + Resources
 * pushed onto the current state. Depth-guarded to prevent pathological cycles. */
static pdfmake_err_t interpret_form(pdfmake_interp_t *interp,
                                     pdfmake_obj_t *form,
                                     uint32_t form_num,
                                     uint16_t form_gen) {
    pdfmake_buf_t content;
    pdfmake_err_t err;
    pdfmake_obj_t *saved_resources;
    int saved_in_text;
    pdfmake_obj_t stream_dict;
    uint32_t matrix_k;
    pdfmake_obj_t *mat;
    uint32_t res_k;
    pdfmake_obj_t *form_res;
    int i;

    if (!form || form->kind != PDFMAKE_STREAM) return PDFMAKE_OK;

    if (interp->form_depth >= 32) {
        /* Cycle guard — spec doesn't allow cycles; silently stop. */
        return PDFMAKE_OK;
    }

    /* Decode the form's content stream (decrypt + FlateDecode). */
    if (pdfmake_buf_init(&content) != PDFMAKE_OK) return PDFMAKE_ENOMEM;

    err = PDFMAKE_OK;
    if (interp->reader && form_num > 0) {
        err = pdfmake_reader_resolve_stream(
            (pdfmake_reader_t *)interp->reader, form_num, form_gen, &content);
    } else {
        /* No reader attached: use parser-level decode without decryption.
         * Will likely fail for encrypted PDFs but works for simple ones. */
        err = PDFMAKE_EINVAL;
    }

    if (err != PDFMAKE_OK || pdfmake_buf_len(&content) == 0) {
        pdfmake_buf_free(&content);
        return PDFMAKE_OK;
    }

    /* Save state: push gstate, stash current resources. */
    gstate_push(interp);
    saved_resources = interp->resources;
    saved_in_text = interp->in_text_object;
    interp->in_text_object = 0;

    /* Apply form's /Matrix to CTM (default = identity). */
    stream_dict.kind = PDFMAKE_DICT;
    stream_dict.as.dict = form->as.stream->dict;

    matrix_k = pdfmake_arena_intern_name(interp->arena, "Matrix", 6);
    mat = pdfmake_dict_get(&stream_dict, matrix_k);
    if (mat && mat->kind == PDFMAKE_ARRAY && pdfmake_array_len(mat) == 6) {
        double m[6];
        for (i = 0; i < 6; i++) {
            pdfmake_obj_t *v = pdfmake_array_get(mat, i);
            if (!v) { m[i] = 0; continue; }
            if (v->kind == PDFMAKE_INT)       m[i] = (double)v->as.i;
            else if (v->kind == PDFMAKE_REAL) m[i] = v->as.r;
            else                              m[i] = 0;
        }
        /* CTM = form_matrix × CTM */
        pdfmake_matrix_multiply(interp->gs->ctm, m, interp->gs->ctm);
    }

    /* Swap resources: form's /Resources (if any) overlays. If the form has
     * no /Resources, keep the outer page's — matches §7.8.3 "If the form
     * XObject does not have its own Resources dictionary, the form uses
     * the page's". */
    res_k = pdfmake_arena_intern_name(interp->arena, "Resources", 9);
    form_res = pdfmake_dict_get(&stream_dict, res_k);
    if (form_res && form_res->kind == PDFMAKE_REF && interp->reader) {
        pdfmake_reader_t *rd = (pdfmake_reader_t *)interp->reader;
        if (rd->parser)
            form_res = pdfmake_parser_resolve(rd->parser, form_res->as.ref);
    }
    if (form_res && form_res->kind == PDFMAKE_DICT) {
        interp->resources = form_res;
    }

    /* Recurse with the already-initialized interpreter */
    interp->form_depth++;
    (void)parse_content_stream(interp,
                               pdfmake_buf_data(&content),
                               pdfmake_buf_len(&content));
    interp->form_depth--;

    /* Restore */
    interp->in_text_object = saved_in_text;
    interp->resources = saved_resources;
    gstate_pop(interp);

    pdfmake_buf_free(&content);
    return PDFMAKE_OK;
}

/* Do - Paint XObject */
static pdfmake_err_t op_Do(pdfmake_interp_t *interp) {
    pdfmake_obj_t name = pop_operand(interp);
    uint32_t xobj_num;
    uint16_t xobj_gen;
    pdfmake_obj_t *xobj;

    if (name.kind != PDFMAKE_NAME) {
        return PDFMAKE_OK;
    }

    xobj_num = 0;
    xobj_gen = 0;
    xobj = lookup_xobject_with_ref(interp, name.as.name.id,
                                    &xobj_num, &xobj_gen);
    if (!xobj) {
        return PDFMAKE_OK;
    }

    /* Check subtype */
    if (xobj->kind == PDFMAKE_STREAM) {
        /* Get /Subtype from stream dict */
        uint32_t subtype_id = pdfmake_arena_intern_name(interp->arena, "Subtype", 7);
        pdfmake_obj_t stream_dict;
        pdfmake_obj_t *subtype;
        stream_dict.kind = PDFMAKE_DICT;
        stream_dict.as.dict = xobj->as.stream->dict;
        subtype = pdfmake_dict_get(&stream_dict, subtype_id);

        if (subtype && subtype->kind == PDFMAKE_NAME) {
            const char *subtype_str = pdfmake_arena_name_bytes(interp->arena,
                                                                subtype->as.name.id);
            if (subtype_str) {
                if (strcmp(subtype_str, "Image") == 0) {
                    /* Image XObject */
                    if (interp->visitor && interp->visitor->on_image) {
                        interp->visitor->on_image(interp->visitor->ctx,
                                                   interp->gs,
                                                   name.as.name.id, xobj);
                    }
                } else if (strcmp(subtype_str, "Form") == 0) {
                    /* Form XObject - recursive interpretation */
                    if (interp->visitor && interp->visitor->on_form_begin) {
                        interp->visitor->on_form_begin(interp->visitor->ctx,
                                                        interp->gs,
                                                        name.as.name.id, xobj);
                    }

                    interpret_form(interp, xobj, xobj_num, xobj_gen);

                    if (interp->visitor && interp->visitor->on_form_end) {
                        interp->visitor->on_form_end(interp->visitor->ctx,
                                                      interp->gs,
                                                      name.as.name.id);
                    }
                }
            }
        }
    }

    return PDFMAKE_OK;
}

/*============================================================================
 * Marked content operators
 *==========================================================================*/

static int mc_push(pdfmake_interp_t *interp, uint32_t tag) {
    if (interp->mc_depth >= interp->mc_cap) {
        size_t new_cap = interp->mc_cap * 2;
        uint32_t *new_stack = realloc(interp->mc_stack, 
                                       new_cap * sizeof(uint32_t));
        if (!new_stack) return 0;
        interp->mc_stack = new_stack;
        interp->mc_cap = new_cap;
    }
    interp->mc_stack[interp->mc_depth++] = tag;
    return 1;
}

/* BMC - Begin marked content */
static pdfmake_err_t op_BMC(pdfmake_interp_t *interp) {
    pdfmake_obj_t tag = pop_operand(interp);
    
    uint32_t tag_id = 0;
    if (tag.kind == PDFMAKE_NAME) {
        tag_id = tag.as.name.id;
    }
    
    mc_push(interp, tag_id);
    
    if (interp->visitor && interp->visitor->on_marked_content_begin) {
        interp->visitor->on_marked_content_begin(interp->visitor->ctx,
                                                  interp->gs, tag_id, NULL);
    }
    
    return PDFMAKE_OK;
}

/* BDC - Begin marked content with properties */
static pdfmake_err_t op_BDC(pdfmake_interp_t *interp) {
    pdfmake_obj_t props = pop_operand(interp);
    pdfmake_obj_t tag = pop_operand(interp);
    uint32_t tag_id;
    pdfmake_obj_t *props_ptr;
    
    tag_id = 0;
    if (tag.kind == PDFMAKE_NAME) {
        tag_id = tag.as.name.id;
    }
    
    props_ptr = NULL;
    if (props.kind == PDFMAKE_DICT) {
        props_ptr = &props;
    } else if (props.kind == PDFMAKE_NAME) {
        /* Look up in Properties resource */
        props_ptr = lookup_resource(interp, "Properties", props.as.name.id);
    }
    
    mc_push(interp, tag_id);
    
    if (interp->visitor && interp->visitor->on_marked_content_begin) {
        interp->visitor->on_marked_content_begin(interp->visitor->ctx,
                                                  interp->gs, tag_id, props_ptr);
    }
    
    return PDFMAKE_OK;
}

/* EMC - End marked content */
static pdfmake_err_t op_EMC(pdfmake_interp_t *interp) {
    if (interp->mc_depth > 0) {
        interp->mc_depth--;
    }
    
    if (interp->visitor && interp->visitor->on_marked_content_end) {
        interp->visitor->on_marked_content_end(interp->visitor->ctx, interp->gs);
    }
    
    return PDFMAKE_OK;
}

/* MP - Marked content point */
static pdfmake_err_t op_MP(pdfmake_interp_t *interp) {
    pop_operand(interp);  /* tag */
    return PDFMAKE_OK;
}

/* DP - Marked content point with properties */
static pdfmake_err_t op_DP(pdfmake_interp_t *interp) {
    pop_operand(interp);  /* properties */
    pop_operand(interp);  /* tag */
    return PDFMAKE_OK;
}

/*============================================================================
 * Compatibility operators
 *==========================================================================*/

/* BX - Begin compatibility section */
static pdfmake_err_t op_BX(pdfmake_interp_t *interp) {
    (void)interp;
    return PDFMAKE_OK;
}

/* EX - End compatibility section */
static pdfmake_err_t op_EX(pdfmake_interp_t *interp) {
    (void)interp;
    return PDFMAKE_OK;
}

/*============================================================================
 * Color space operators (simplified - just consume operands)
 *==========================================================================*/

/* cs - Set fill color space */
static pdfmake_err_t op_cs(pdfmake_interp_t *interp) {
    pop_operand(interp);
    return PDFMAKE_OK;
}

/* CS - Set stroke color space */
static pdfmake_err_t op_CS(pdfmake_interp_t *interp) {
    pop_operand(interp);
    return PDFMAKE_OK;
}

/* sc/scn - Set fill color (arbitrary color space) */
static pdfmake_err_t op_sc(pdfmake_interp_t *interp) {
    /* Just consume operands for now */
    clear_operands(interp);
    return PDFMAKE_OK;
}

/* SC/SCN - Set stroke color (arbitrary color space) */
static pdfmake_err_t op_SC(pdfmake_interp_t *interp) {
    clear_operands(interp);
    return PDFMAKE_OK;
}

/*============================================================================
 * Rendering intent
 *==========================================================================*/

/* ri - Set rendering intent */
static pdfmake_err_t op_ri(pdfmake_interp_t *interp) {
    pdfmake_obj_t intent = pop_operand(interp);
    if (intent.kind == PDFMAKE_NAME) {
        interp->gs->rendering_intent = intent.as.name.id;
    }
    return PDFMAKE_OK;
}

/*============================================================================
 * Inline image operators (simplified)
 *==========================================================================*/

/* BI - Begin inline image */
static pdfmake_err_t op_BI(pdfmake_interp_t *interp) {
    /* Inline images are handled specially during tokenization */
    (void)interp;
    return PDFMAKE_OK;
}

/*============================================================================
 * Shading operator
 *==========================================================================*/

/* sh - Paint shading */
static pdfmake_err_t op_sh(pdfmake_interp_t *interp) {
    pop_operand(interp);
    return PDFMAKE_OK;
}

/*============================================================================
 * Operator dispatch table
 *==========================================================================*/

typedef pdfmake_err_t (*op_handler_t)(pdfmake_interp_t *interp);

typedef struct {
    const char *name;
    op_handler_t handler;
} op_entry_t;

static const op_entry_t op_table[] = {
    /* Graphics state */
    {"q",  op_q},
    {"Q",  op_Q},
    {"cm", op_cm},
    {"w",  op_w},
    {"J",  op_J},
    {"j",  op_j},
    {"M",  op_M},
    {"d",  op_d},
    {"ri", op_ri},
    {"i",  op_i},
    {"gs", op_gs},
    
    /* Text state */
    {"Tc", op_Tc},
    {"Tw", op_Tw},
    {"Tz", op_Tz},
    {"TL", op_TL},
    {"Tf", op_Tf},
    {"Tr", op_Tr},
    {"Ts", op_Ts},
    
    /* Text positioning */
    {"Td", op_Td},
    {"TD", op_TD},
    {"Tm", op_Tm},
    {"T*", op_Tstar},
    
    /* Text showing */
    {"Tj", op_Tj},
    {"TJ", op_TJ},
    {"'",  op_quote},
    {"\"", op_dquote},
    
    /* Text object */
    {"BT", op_BT},
    {"ET", op_ET},
    
    /* Path construction */
    {"m",  op_m},
    {"l",  op_l},
    {"c",  op_c},
    {"v",  op_v},
    {"y",  op_y},
    {"h",  op_h},
    {"re", op_re},
    
    /* Path painting */
    {"S",  op_S},
    {"s",  op_s},
    {"f",  op_f},
    {"F",  op_f},     /* F is same as f */
    {"f*", op_fstar},
    {"B",  op_B},
    {"B*", op_Bstar},
    {"b",  op_b},
    {"b*", op_bstar},
    {"n",  op_n},
    
    /* Clipping */
    {"W",  op_W},
    {"W*", op_Wstar},
    
    /* Color */
    {"g",  op_g},
    {"G",  op_G},
    {"rg", op_rg},
    {"RG", op_RG},
    {"k",  op_k},
    {"K",  op_K},
    {"cs", op_cs},
    {"CS", op_CS},
    {"sc", op_sc},
    {"SC", op_SC},
    {"scn", op_sc},
    {"SCN", op_SC},
    
    /* XObject */
    {"Do", op_Do},
    
    /* Marked content */
    {"BMC", op_BMC},
    {"BDC", op_BDC},
    {"EMC", op_EMC},
    {"MP",  op_MP},
    {"DP",  op_DP},
    
    /* Compatibility */
    {"BX", op_BX},
    {"EX", op_EX},
    
    /* Inline image */
    {"BI", op_BI},
    
    /* Shading */
    {"sh", op_sh},
    
    {NULL, NULL}
};

static op_handler_t find_operator(const char *name, size_t len) {
    const op_entry_t *e;
    for (e = op_table; e->name; e++) {
        if (strlen(e->name) == len && memcmp(e->name, name, len) == 0) {
            return e->handler;
        }
    }
    return NULL;
}

/*============================================================================
 * Content stream tokenizer (simplified)
 *==========================================================================*/

/* Build a pdfmake_obj_t from a token (numbers, names, strings, booleans,
 * null).  Returns 1 if populated, 0 if the token isn't a primitive value
 * (arrays/dicts are handled inline by the callers because they recurse via
 * the tokenizer). */
static int token_to_primitive(const uint8_t *bytes,
                               pdfmake_tok_t t,
                               pdfmake_obj_t *out)
{
    switch (t.kind) {
    case PDFMAKE_TOK_INT:
        *out = pdfmake_int(t.payload.int_val);
        return 1;
    case PDFMAKE_TOK_REAL:
        *out = pdfmake_real(t.payload.real_val);
        return 1;
    case PDFMAKE_TOK_LSTR:
        out->kind = PDFMAKE_STR;
        out->as.str.bytes = bytes + t.offset + 1;
        out->as.str.len = t.length - 2;
        out->as.str.hex = 0;
        return 1;
    case PDFMAKE_TOK_HSTR:
        out->kind = PDFMAKE_STR;
        out->as.str.bytes = bytes + t.offset + 1;
        out->as.str.len = t.length - 2;
        out->as.str.hex = 1;
        return 1;
    case PDFMAKE_TOK_KW_TRUE:  *out = pdfmake_bool(1); return 1;
    case PDFMAKE_TOK_KW_FALSE: *out = pdfmake_bool(0); return 1;
    case PDFMAKE_TOK_KW_NULL:  *out = pdfmake_null();  return 1;
    default: return 0;
    }
}

/* Parse an inline dictionary starting just after the '<<' token.
 * Handles nested dicts and arrays so BDC property dicts like
 * `/P << /MCID 7 /Lang (en) >>` are usable by visitors. */
static pdfmake_obj_t parse_inline_dict(pdfmake_interp_t *interp,
                                        const uint8_t *bytes,
                                        pdfmake_tokenizer_t *tok);

static pdfmake_obj_t parse_inline_array(pdfmake_interp_t *interp,
                                         const uint8_t *bytes,
                                         pdfmake_tokenizer_t *tok)
{
    pdfmake_obj_t arr;
    pdfmake_tok_t t;
    pdfmake_obj_t v;

    arr = pdfmake_array_new(interp->arena);
    while (1) {
        t = pdfmake_tok_next_significant(tok);
        if (t.kind == PDFMAKE_TOK_EOF || t.kind == PDFMAKE_TOK_ARR_CLOSE) break;
        if (t.kind == PDFMAKE_TOK_ARR_OPEN) {
            v = parse_inline_array(interp, bytes, tok);
        } else if (t.kind == PDFMAKE_TOK_DICT_OPEN) {
            v = parse_inline_dict(interp, bytes, tok);
        } else if (t.kind == PDFMAKE_TOK_NAME) {
            const char *name_str = (const char *)(bytes + t.offset + 1);
            uint32_t id = pdfmake_arena_intern_name(
                interp->arena, name_str, t.length - 1);
            v.kind = PDFMAKE_NAME;
            v.as.name.id = id;
        } else if (!token_to_primitive(bytes, t, &v)) {
            continue;
        }
        pdfmake_array_push(interp->arena, &arr, v);
    }
    return arr;
}

static pdfmake_obj_t parse_inline_dict(pdfmake_interp_t *interp,
                                        const uint8_t *bytes,
                                        pdfmake_tokenizer_t *tok)
{
    pdfmake_obj_t dict;
    pdfmake_tok_t kt;
    pdfmake_tok_t vt;
    const char *name_str;
    uint32_t key;
    pdfmake_obj_t v;

    dict = pdfmake_dict_new(interp->arena);
    while (1) {
        kt = pdfmake_tok_next_significant(tok);
        if (kt.kind == PDFMAKE_TOK_EOF || kt.kind == PDFMAKE_TOK_DICT_CLOSE) break;
        if (kt.kind != PDFMAKE_TOK_NAME) continue;  /* malformed — skip */
        name_str = (const char *)(bytes + kt.offset + 1);
        key = pdfmake_arena_intern_name(
            interp->arena, name_str, kt.length - 1);

        vt = pdfmake_tok_next_significant(tok);
        if (vt.kind == PDFMAKE_TOK_EOF || vt.kind == PDFMAKE_TOK_DICT_CLOSE) break;
        if (vt.kind == PDFMAKE_TOK_DICT_OPEN) {
            v = parse_inline_dict(interp, bytes, tok);
        } else if (vt.kind == PDFMAKE_TOK_ARR_OPEN) {
            v = parse_inline_array(interp, bytes, tok);
        } else if (vt.kind == PDFMAKE_TOK_NAME) {
            const char *vstr = (const char *)(bytes + vt.offset + 1);
            uint32_t vid = pdfmake_arena_intern_name(
                interp->arena, vstr, vt.length - 1);
            v.kind = PDFMAKE_NAME;
            v.as.name.id = vid;
        } else if (!token_to_primitive(bytes, vt, &v)) {
            continue;  /* unknown — drop the key/value pair */
        }
        pdfmake_dict_set(interp->arena, &dict, key, v);
    }
    return dict;
}

/* Simple content stream parser using the existing tokenizer */
static pdfmake_err_t parse_content_stream(pdfmake_interp_t *interp,
                                           const uint8_t *bytes,
                                           size_t len) {
    pdfmake_tokenizer_t tok;
    pdfmake_tokenizer_init(&tok, bytes, len);
    
    while (1) {
        pdfmake_tok_t t = pdfmake_tok_next_significant(&tok);
        
        if (t.kind == PDFMAKE_TOK_EOF) {
            break;
        }
        
        switch (t.kind) {
        case PDFMAKE_TOK_INT: {
            pdfmake_obj_t obj = pdfmake_int(t.payload.int_val);
            if (!push_operand(interp, obj)) {
                set_error(interp, PDFMAKE_ENOMEM, t.offset, "Operand stack overflow");
                return PDFMAKE_ENOMEM;
            }
            break;
        }
        
        case PDFMAKE_TOK_REAL: {
            pdfmake_obj_t obj = pdfmake_real(t.payload.real_val);
            if (!push_operand(interp, obj)) {
                set_error(interp, PDFMAKE_ENOMEM, t.offset, "Operand stack overflow");
                return PDFMAKE_ENOMEM;
            }
            break;
        }
        
        case PDFMAKE_TOK_NAME: {
            /* Intern the name */
            const char *name_str = (const char *)(bytes + t.offset + 1);  /* Skip / */
            uint32_t name_id = pdfmake_arena_intern_name(interp->arena, 
                                                          name_str, t.length - 1);
            pdfmake_obj_t obj;
            obj.kind = PDFMAKE_NAME;
            obj.as.name.id = name_id;
            if (!push_operand(interp, obj)) {
                set_error(interp, PDFMAKE_ENOMEM, t.offset, "Operand stack overflow");
                return PDFMAKE_ENOMEM;
            }
            break;
        }
        
        case PDFMAKE_TOK_LSTR: {
            pdfmake_obj_t obj;
            obj.kind = PDFMAKE_STR;
            obj.as.str.bytes = bytes + t.offset + 1;  /* Skip ( */
            obj.as.str.len = t.length - 2;           /* Exclude parens */
            obj.as.str.hex = 0;
            if (!push_operand(interp, obj)) {
                set_error(interp, PDFMAKE_ENOMEM, t.offset, "Operand stack overflow");
                return PDFMAKE_ENOMEM;
            }
            break;
        }
        
        case PDFMAKE_TOK_HSTR: {
            pdfmake_obj_t obj;
            obj.kind = PDFMAKE_STR;
            obj.as.str.bytes = bytes + t.offset + 1;  /* Skip < */
            obj.as.str.len = t.length - 2;           /* Exclude angle brackets */
            obj.as.str.hex = 1;
            if (!push_operand(interp, obj)) {
                set_error(interp, PDFMAKE_ENOMEM, t.offset, "Operand stack overflow");
                return PDFMAKE_ENOMEM;
            }
            break;
        }
        
        case PDFMAKE_TOK_ARR_OPEN: {
            /* Parse array - simple recursive handling */
            /* For now, use a temporary array */
            pdfmake_obj_t arr = pdfmake_array_new(interp->arena);
            int depth = 1;
            while (depth > 0) {
                pdfmake_tok_t at = pdfmake_tok_next_significant(&tok);
                if (at.kind == PDFMAKE_TOK_EOF) {
                    break;
                }
                if (at.kind == PDFMAKE_TOK_ARR_OPEN) {
                    depth++;
                    /* Nested arrays not fully handled */
                } else if (at.kind == PDFMAKE_TOK_ARR_CLOSE) {
                    depth--;
                } else if (at.kind == PDFMAKE_TOK_INT) {
                    pdfmake_obj_t elem = pdfmake_int(at.payload.int_val);
                    pdfmake_array_push(interp->arena, &arr, elem);
                } else if (at.kind == PDFMAKE_TOK_REAL) {
                    pdfmake_obj_t elem = pdfmake_real(at.payload.real_val);
                    pdfmake_array_push(interp->arena, &arr, elem);
                } else if (at.kind == PDFMAKE_TOK_LSTR) {
                    pdfmake_obj_t elem;
                    elem.kind = PDFMAKE_STR;
                    elem.as.str.bytes = bytes + at.offset + 1;
                    elem.as.str.len = at.length - 2;
                    elem.as.str.hex = 0;
                    pdfmake_array_push(interp->arena, &arr, elem);
                } else if (at.kind == PDFMAKE_TOK_HSTR) {
                    pdfmake_obj_t elem;
                    elem.kind = PDFMAKE_STR;
                    elem.as.str.bytes = bytes + at.offset + 1;
                    elem.as.str.len = at.length - 2;
                    elem.as.str.hex = 1;
                    pdfmake_array_push(interp->arena, &arr, elem);
                }
            }
            if (!push_operand(interp, arr)) {
                set_error(interp, PDFMAKE_ENOMEM, t.offset, "Operand stack overflow");
                return PDFMAKE_ENOMEM;
            }
            break;
        }
        
        case PDFMAKE_TOK_DICT_OPEN: {
            pdfmake_obj_t dict = parse_inline_dict(interp, bytes, &tok);
            if (!push_operand(interp, dict)) {
                set_error(interp, PDFMAKE_ENOMEM, t.offset, "Operand stack overflow");
                return PDFMAKE_ENOMEM;
            }
            break;
        }
        
        case PDFMAKE_TOK_KW_TRUE: {
            pdfmake_obj_t obj = pdfmake_bool(1);
            if (!push_operand(interp, obj)) {
                set_error(interp, PDFMAKE_ENOMEM, t.offset, "Operand stack overflow");
                return PDFMAKE_ENOMEM;
            }
            break;
        }
        
        case PDFMAKE_TOK_KW_FALSE: {
            pdfmake_obj_t obj = pdfmake_bool(0);
            if (!push_operand(interp, obj)) {
                set_error(interp, PDFMAKE_ENOMEM, t.offset, "Operand stack overflow");
                return PDFMAKE_ENOMEM;
            }
            break;
        }
        
        case PDFMAKE_TOK_KW_NULL: {
            pdfmake_obj_t obj = pdfmake_null();
            if (!push_operand(interp, obj)) {
                set_error(interp, PDFMAKE_ENOMEM, t.offset, "Operand stack overflow");
                return PDFMAKE_ENOMEM;
            }
            break;
        }
        
        case PDFMAKE_TOK_ERROR:
        default: {
            /* Try to interpret as operator */
            const char *op_str = (const char *)(bytes + t.offset);
            op_handler_t handler = find_operator(op_str, t.length);
            
            if (handler) {
                pdfmake_err_t err = handler(interp);
                if (err != PDFMAKE_OK) {
                    return err;
                }
            } else {
                /* Unknown operator - skip */
            }
            break;
        }
        }
    }
    
    return PDFMAKE_OK;
}

/*============================================================================
 * Main interpret function
 *==========================================================================*/

pdfmake_err_t pdfmake_interpret(pdfmake_interp_t *interp,
                                 const uint8_t *bytes,
                                 size_t len) {
    if (!interp || !bytes) {
        return PDFMAKE_EINVAL;
    }
    
    pdfmake_interp_reset(interp);
    
    return parse_content_stream(interp, bytes, len);
}

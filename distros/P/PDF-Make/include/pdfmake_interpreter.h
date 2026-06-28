/*
 * pdfmake_interpreter.h - Content stream interpreter
 *
 * Executes PDF content streams, tracking graphics state on a stack.
 * Uses a visitor pattern to fire callbacks for text, path, and image operations.
 *
 * Reference: PDF 32000-1:2008
 * - §8.4 Graphics state
 * - §8.5 Path operators
 * - §9.3 Text state parameters
 * - §9.4 Text objects
 * - §14.6 Marked content
 * - Annex A Operators
 */

#ifndef PDFMAKE_INTERPRETER_H
#define PDFMAKE_INTERPRETER_H

#include <stddef.h>
#include <stdint.h>
#include "pdfmake.h"
#include "pdfmake_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/*============================================================================
 * Error codes
 *==========================================================================*/

#define PDFMAKE_EINTERP       40   /* Generic interpreter error */
#define PDFMAKE_ESTACK_OVER   41   /* Graphics state stack overflow */
#define PDFMAKE_ESTACK_UNDER  42   /* Graphics state stack underflow */
#define PDFMAKE_ETEXTOBJ      43   /* Text object error (BT/ET mismatch) */
#define PDFMAKE_EOPERAND      44   /* Invalid operand */
#define PDFMAKE_EOPERATOR     45   /* Unknown operator */

/*============================================================================
 * Constants
 *==========================================================================*/

/* Maximum graphics state stack depth (§8.4.5 recommends ≥28) */
#define PDFMAKE_GSTATE_STACK_MAX  32

/* Line cap styles (§8.4.3.3) */
#define PDFMAKE_CAP_BUTT    0
#define PDFMAKE_CAP_ROUND   1
#define PDFMAKE_CAP_SQUARE  2

/* Line join styles (§8.4.3.4) */
#define PDFMAKE_JOIN_MITER  0
#define PDFMAKE_JOIN_ROUND  1
#define PDFMAKE_JOIN_BEVEL  2

/* Text rendering modes (§9.3.6) */
#define PDFMAKE_RENDER_FILL             0
#define PDFMAKE_RENDER_STROKE           1
#define PDFMAKE_RENDER_FILL_STROKE      2
#define PDFMAKE_RENDER_INVISIBLE        3
#define PDFMAKE_RENDER_FILL_CLIP        4
#define PDFMAKE_RENDER_STROKE_CLIP      5
#define PDFMAKE_RENDER_FILL_STROKE_CLIP 6
#define PDFMAKE_RENDER_CLIP             7

/*============================================================================
 * Forward declarations
 *==========================================================================*/

typedef struct pdfmake_gstate pdfmake_gstate_t;
typedef struct pdfmake_interp pdfmake_interp_t;
typedef struct pdfmake_visitor pdfmake_visitor_t;
typedef struct pdfmake_path_segment pdfmake_path_segment_t;

/*============================================================================
 * Color representation
 *==========================================================================*/

typedef struct pdfmake_color {
    int   space;          /* Color space type */
    double components[4]; /* Color components (up to CMYK) */
    int   n_components;   /* Number of components */
} pdfmake_color_t;

/* Color space types */
#define PDFMAKE_CS_GRAY     0
#define PDFMAKE_CS_RGB      1
#define PDFMAKE_CS_CMYK     2

/*============================================================================
 * Path segment (for path visitor callback)
 *==========================================================================*/

#ifndef PDFMAKE_PATH_OP_DEFINED
#define PDFMAKE_PATH_OP_DEFINED
typedef enum {
    PDFMAKE_PATH_MOVE,      /* m - moveto */
    PDFMAKE_PATH_LINE,      /* l - lineto */
    PDFMAKE_PATH_CURVE,     /* c - curveto */
    PDFMAKE_PATH_CURVE_V,   /* v - curveto (initial point replicated) */
    PDFMAKE_PATH_CURVE_Y,   /* y - curveto (final point replicated) */
    PDFMAKE_PATH_CLOSE,     /* h - closepath */
    PDFMAKE_PATH_RECT       /* re - rectangle */
} pdfmake_path_op_t;
#endif

struct pdfmake_path_segment {
    pdfmake_path_op_t op;
    double x1, y1;          /* First point */
    double x2, y2;          /* Second point (for curves) */
    double x3, y3;          /* Third point (for cubic curves) */
    double width, height;   /* For rectangle */
};

/*============================================================================
 * Graphics state (§8.4)
 *==========================================================================*/

struct pdfmake_gstate {
    /* Current transformation matrix (§8.3.2) - a, b, c, d, e, f */
    double ctm[6];
    
    /* Line state (§8.4.3) */
    double line_width;
    int    line_cap;
    int    line_join;
    double miter_limit;
    double *dash_array;
    size_t dash_count;
    double dash_phase;
    
    /* Color state */
    pdfmake_color_t stroke_color;
    pdfmake_color_t fill_color;
    
    /* Text state (§9.3) */
    double char_space;      /* Tc - character spacing */
    double word_space;      /* Tw - word spacing */
    double h_scale;         /* Tz - horizontal scaling (percentage) */
    double leading;         /* TL - leading */
    double font_size;       /* Tf second operand */
    int    render_mode;     /* Tr - text rendering mode */
    double rise;            /* Ts - text rise */
    
    /* Font reference (name from Tf, resolved from Resources) */
    uint32_t font_name;     /* Interned font name from /Tf */
    pdfmake_obj_t *font;    /* Font dictionary (resolved) */
    
    /* Text matrices (§9.4.2) */
    double text_matrix[6];       /* Tm - current text matrix */
    double text_line_matrix[6];  /* Tlm - text line matrix */
    
    /* Clipping path (simplified - just track nesting) */
    int clip_depth;
    
    /* Flatness tolerance */
    double flatness;
    
    /* Rendering intent */
    uint32_t rendering_intent;
};

/*============================================================================
 * Visitor callbacks (observer pattern)
 *==========================================================================*/

struct pdfmake_visitor {
    void *ctx;  /* User context passed to all callbacks */
    
    /* Text showing operations (Tj, TJ, ', ") */
    void (*on_text_show)(void *ctx, 
                         const pdfmake_gstate_t *gs,
                         const uint8_t *bytes, 
                         size_t len);
    
    /* Path painting operations (S, s, f, F, f*, B, B*, b, b*, n) */
    void (*on_path)(void *ctx,
                    const pdfmake_gstate_t *gs,
                    const pdfmake_path_segment_t *segments,
                    size_t n_segments,
                    int stroke,    /* 1 if stroke */
                    int fill,      /* 1 if fill */
                    int even_odd); /* 1 if even-odd fill rule */
    
    /* Image XObject (Do with /Subtype /Image) */
    void (*on_image)(void *ctx,
                     const pdfmake_gstate_t *gs,
                     uint32_t xobj_name,
                     pdfmake_obj_t *image_obj);
    
    /* Form XObject begin/end (Do with /Subtype /Form) */
    void (*on_form_begin)(void *ctx,
                          const pdfmake_gstate_t *gs,
                          uint32_t xobj_name,
                          pdfmake_obj_t *form_obj);
    void (*on_form_end)(void *ctx,
                        const pdfmake_gstate_t *gs,
                        uint32_t xobj_name);
    
    /* Marked content (BMC, BDC, EMC) */
    void (*on_marked_content_begin)(void *ctx,
                                    const pdfmake_gstate_t *gs,
                                    uint32_t tag,
                                    pdfmake_obj_t *properties);
    void (*on_marked_content_end)(void *ctx,
                                  const pdfmake_gstate_t *gs);
    
    /* Inline image (BI ... ID ... EI) */
    void (*on_inline_image)(void *ctx,
                            const pdfmake_gstate_t *gs,
                            pdfmake_obj_t *dict,
                            const uint8_t *data,
                            size_t len);

    /* Phase 8: optional hook — return the actual text-space advance for a
     * string so the interpreter can propagate accurate positioning into the
     * text matrix between Tj calls. Return 0 to fall back to the
     * interpreter's 0.6-em placeholder. Units: text-space (multiply by
     * font_size * h_scale when applying). */
    double (*get_string_advance)(void *ctx,
                                  const pdfmake_gstate_t *gs,
                                  const uint8_t *bytes,
                                  size_t len);

    /* Phase 14: optional hook — return 1 if the current font renders in
     * vertical writing mode (WMode 1), so the interpreter knows to advance
     * text_matrix along -y instead of +x.  Returning 0 (or omitting the
     * hook) preserves the horizontal default. */
    int (*is_vertical_writing)(void *ctx,
                                const pdfmake_gstate_t *gs);
};

/*============================================================================
 * Interpreter context
 *==========================================================================*/

struct pdfmake_interp {
    /* Graphics state stack */
    pdfmake_gstate_t *stack;
    size_t stack_size;
    size_t stack_cap;
    
    /* Current graphics state (top of stack) */
    pdfmake_gstate_t *gs;
    
    /* Text object state */
    int in_text_object;     /* Between BT and ET */
    
    /* Current path */
    pdfmake_path_segment_t *path;
    size_t path_size;
    size_t path_cap;
    
    /* Current point */
    double cur_x, cur_y;
    int have_cur_point;
    
    /* Marked content stack */
    uint32_t *mc_stack;     /* Tag names */
    size_t mc_depth;
    size_t mc_cap;
    
    /* Resources dictionary */
    pdfmake_obj_t *resources;

    /* Arena for name interning */
    pdfmake_arena_t *arena;

    /* Optional reader pointer — enables Form XObject recursion.
     * When set, op_Do can fetch decoded Form content streams.
     * Opaque to avoid a circular include; cast to pdfmake_reader_t* at use. */
    void *reader;

    /* Form XObject recursion depth (to catch cycles). */
    int form_depth;

    /* Visitor callbacks */
    const pdfmake_visitor_t *visitor;
    
    /* Error state */
    pdfmake_err_t last_err;
    char errmsg[256];
    size_t erroffset;
    
    /* Operand stack for operator execution */
    pdfmake_obj_t *operands;
    size_t op_count;
    size_t op_cap;
};

/*============================================================================
 * Matrix operations
 *==========================================================================*/

/* Initialize to identity matrix */
void pdfmake_matrix_identity(double m[6]);

/* Multiply: result = a × b */
void pdfmake_matrix_multiply(double result[6], const double a[6], const double b[6]);

/* Concatenate: m = m × other (post-multiply) */
void pdfmake_matrix_concat(double m[6], const double other[6]);

/* Create translation matrix */
void pdfmake_matrix_translate(double m[6], double tx, double ty);

/* Create scale matrix */
void pdfmake_matrix_scale(double m[6], double sx, double sy);

/* Create rotation matrix (angle in radians) */
void pdfmake_matrix_rotate(double m[6], double angle);

/* Invert matrix. Returns 0 on success, -1 if singular */
int pdfmake_matrix_invert(double result[6], const double m[6]);

/* Transform a point */
void pdfmake_matrix_transform_point(const double m[6], 
                                     double *x, double *y);

/* Copy matrix */
void pdfmake_matrix_copy(double dst[6], const double src[6]);

/*============================================================================
 * Interpreter lifecycle
 *==========================================================================*/

/* Create new interpreter */
pdfmake_interp_t *pdfmake_interp_new(pdfmake_arena_t *arena);

/* Free interpreter */
void pdfmake_interp_free(pdfmake_interp_t *interp);

/* Set resources dictionary for name resolution */
void pdfmake_interp_set_resources(pdfmake_interp_t *interp,
                                   pdfmake_obj_t *resources);

/* Set visitor callbacks */
void pdfmake_interp_set_visitor(pdfmake_interp_t *interp,
                                 const pdfmake_visitor_t *visitor);

/* Attach a reader for Form XObject recursion. Pass NULL to disable. */
void pdfmake_interp_set_reader(pdfmake_interp_t *interp, void *reader);

/* Reset interpreter state (for reuse) */
void pdfmake_interp_reset(pdfmake_interp_t *interp);

/*============================================================================
 * Interpretation
 *==========================================================================*/

/* Interpret a content stream */
pdfmake_err_t pdfmake_interpret(pdfmake_interp_t *interp,
                                 const uint8_t *bytes,
                                 size_t len);

/* Get last error message */
const char *pdfmake_interp_errmsg(pdfmake_interp_t *interp);

/* Get error offset in stream */
size_t pdfmake_interp_erroffset(pdfmake_interp_t *interp);

/*============================================================================
 * Graphics state access
 *==========================================================================*/

/* Get current graphics state (read-only) */
const pdfmake_gstate_t *pdfmake_interp_gstate(pdfmake_interp_t *interp);

/* Check if in text object (between BT and ET) */
int pdfmake_interp_in_text_object(pdfmake_interp_t *interp);

/* Get current point (if set) */
int pdfmake_interp_get_current_point(pdfmake_interp_t *interp,
                                      double *x, double *y);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_INTERPRETER_H */

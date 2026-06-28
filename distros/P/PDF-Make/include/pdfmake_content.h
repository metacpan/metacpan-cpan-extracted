/*
 * pdfmake_content.h — Content stream builder.
 *
 * Provides a typed, chainable API to build PDF content streams covering
 * every operator in Annex A. This is the "Canvas" of PDF generation.
 *
 * Operators are grouped per PDF spec:
 *   - General graphics state (§8.4.4)
 *   - Path construction (§8.5.2)
 *   - Path painting (§8.5.3)
 *   - Clipping (§8.5.4)
 *   - Colour (§8.6)
 *   - Text object/state/positioning/showing (§9.3-9.4)
 *   - XObject (§8.8)
 *   - Marked content (§14.6)
 *   - Shading (§8.7.4)
 *   - Inline image (§8.9.7)
 */

#ifndef PDFMAKE_CONTENT_H
#define PDFMAKE_CONTENT_H

#include "pdfmake_types.h"
#include "pdfmake_arena.h"
#include "pdfmake_buf.h"

#ifdef __cplusplus
extern "C" {
#endif

/*----------------------------------------------------------------------------
 * Content stream builder structure
 *--------------------------------------------------------------------------*/

typedef struct pdfmake_content {
    pdfmake_arena_t *arena;     /* Memory arena for allocations */
    pdfmake_buf_t    buf;       /* Output buffer for stream bytes */
} pdfmake_content_t;

/*----------------------------------------------------------------------------
 * Lifecycle
 *--------------------------------------------------------------------------*/

/* Create a new content stream builder. Returns NULL on error. */
pdfmake_content_t *pdfmake_content_new(pdfmake_arena_t *arena);

/* Free the content builder (buffer is freed, arena is not). */
void pdfmake_content_free(pdfmake_content_t *c);

/* Get the raw bytes of the content stream. */
const uint8_t *pdfmake_content_data(pdfmake_content_t *c);

/* Get the length of the content stream bytes. */
size_t pdfmake_content_len(pdfmake_content_t *c);

/* Clear the content buffer for reuse. */
void pdfmake_content_clear(pdfmake_content_t *c);

/*----------------------------------------------------------------------------
 * General graphics state operators (§8.4.4)
 *--------------------------------------------------------------------------*/

/* q - Save graphics state */
pdfmake_err_t pdfmake_gs_q(pdfmake_content_t *c);

/* Q - Restore graphics state */
pdfmake_err_t pdfmake_gs_Q(pdfmake_content_t *c);

/* cm - Concatenate matrix: [a b c d e f] */
pdfmake_err_t pdfmake_gs_cm(pdfmake_content_t *c,
                                double a, double b, double c_,
                                double d, double e, double f);

/* w - Set line width */
pdfmake_err_t pdfmake_gs_w(pdfmake_content_t *c, double width);

/* J - Set line cap style (0=butt, 1=round, 2=square) */
pdfmake_err_t pdfmake_gs_J(pdfmake_content_t *c, int cap);

/* j - Set line join style (0=miter, 1=round, 2=bevel) */
pdfmake_err_t pdfmake_gs_j(pdfmake_content_t *c, int join);

/* M - Set miter limit */
pdfmake_err_t pdfmake_gs_M(pdfmake_content_t *c, double limit);

/* d - Set dash pattern: [array] phase */
pdfmake_err_t pdfmake_gs_d(pdfmake_content_t *c,
                               const double *array, size_t count,
                               double phase);

/* ri - Set rendering intent */
pdfmake_err_t pdfmake_gs_ri(pdfmake_content_t *c, const char *intent);

/* i - Set flatness tolerance */
pdfmake_err_t pdfmake_gs_i(pdfmake_content_t *c, double flatness);

/* gs - Set parameters from ExtGState dictionary */
pdfmake_err_t pdfmake_gs_gs(pdfmake_content_t *c, const char *name);

/*----------------------------------------------------------------------------
 * Path construction operators (§8.5.2)
 *--------------------------------------------------------------------------*/

/* m - Move to (begin new subpath) */
pdfmake_err_t pdfmake_path_m(pdfmake_content_t *c, double x, double y);

/* l - Line to */
pdfmake_err_t pdfmake_path_l(pdfmake_content_t *c, double x, double y);

/* c - Cubic Bezier curve (two control points) */
pdfmake_err_t pdfmake_path_c(pdfmake_content_t *c,
                                 double x1, double y1,
                                 double x2, double y2,
                                 double x3, double y3);

/* v - Cubic Bezier curve (first control point = current point) */
pdfmake_err_t pdfmake_path_v(pdfmake_content_t *c,
                                 double x2, double y2,
                                 double x3, double y3);

/* y - Cubic Bezier curve (second control point = endpoint) */
pdfmake_err_t pdfmake_path_y(pdfmake_content_t *c,
                                 double x1, double y1,
                                 double x3, double y3);

/* re - Append rectangle to path */
pdfmake_err_t pdfmake_path_re(pdfmake_content_t *c,
                                  double x, double y,
                                  double width, double height);

/* h - Close subpath */
pdfmake_err_t pdfmake_path_h(pdfmake_content_t *c);

/*----------------------------------------------------------------------------
 * Path painting operators (§8.5.3)
 *--------------------------------------------------------------------------*/

/* S - Stroke path */
pdfmake_err_t pdfmake_paint_S(pdfmake_content_t *c);

/* s - Close and stroke path */
pdfmake_err_t pdfmake_paint_s(pdfmake_content_t *c);

/* f - Fill path (nonzero winding rule) */
pdfmake_err_t pdfmake_paint_f(pdfmake_content_t *c);

/* f* - Fill path (even-odd rule) */
pdfmake_err_t pdfmake_paint_f_star(pdfmake_content_t *c);

/* B - Fill and stroke path (nonzero) */
pdfmake_err_t pdfmake_paint_B(pdfmake_content_t *c);

/* B* - Fill and stroke path (even-odd) */
pdfmake_err_t pdfmake_paint_B_star(pdfmake_content_t *c);

/* b - Close, fill and stroke path (nonzero) */
pdfmake_err_t pdfmake_paint_b(pdfmake_content_t *c);

/* b* - Close, fill and stroke path (even-odd) */
pdfmake_err_t pdfmake_paint_b_star(pdfmake_content_t *c);

/* n - End path without filling or stroking */
pdfmake_err_t pdfmake_paint_n(pdfmake_content_t *c);

/*----------------------------------------------------------------------------
 * Clipping operators (§8.5.4)
 *--------------------------------------------------------------------------*/

/* W - Set clipping path (nonzero winding rule) */
pdfmake_err_t pdfmake_clip_W(pdfmake_content_t *c);

/* W* - Set clipping path (even-odd rule) */
pdfmake_err_t pdfmake_clip_W_star(pdfmake_content_t *c);

/*----------------------------------------------------------------------------
 * Colour operators (§8.6)
 *--------------------------------------------------------------------------*/

/* CS - Set stroke colour space */
pdfmake_err_t pdfmake_color_CS(pdfmake_content_t *c, const char *name);

/* cs - Set fill colour space */
pdfmake_err_t pdfmake_color_cs(pdfmake_content_t *c, const char *name);

/* SC - Set stroke colour (up to 4 components) */
pdfmake_err_t pdfmake_color_SC(pdfmake_content_t *c,
                                   const double *components, size_t count);

/* sc - Set fill colour (up to 4 components) */
pdfmake_err_t pdfmake_color_sc(pdfmake_content_t *c,
                                   const double *components, size_t count);

/* SCN - Set stroke colour (Pattern and special spaces) */
pdfmake_err_t pdfmake_color_SCN(pdfmake_content_t *c,
                                    const double *components, size_t count,
                                    const char *name);

/* scn - Set fill colour (Pattern and special spaces) */
pdfmake_err_t pdfmake_color_scn(pdfmake_content_t *c,
                                    const double *components, size_t count,
                                    const char *name);

/* G - Set stroke gray level */
pdfmake_err_t pdfmake_color_G(pdfmake_content_t *c, double gray);

/* g - Set fill gray level */
pdfmake_err_t pdfmake_color_g(pdfmake_content_t *c, double gray);

/* RG - Set stroke RGB colour */
pdfmake_err_t pdfmake_color_RG(pdfmake_content_t *c,
                                   double r, double g, double b);

/* rg - Set fill RGB colour */
pdfmake_err_t pdfmake_color_rg(pdfmake_content_t *c,
                                   double r, double g, double b);

/* K - Set stroke CMYK colour */
pdfmake_err_t pdfmake_color_K(pdfmake_content_t *c,
                                  double c_, double m, double y, double k);

/* k - Set fill CMYK colour */
pdfmake_err_t pdfmake_color_k(pdfmake_content_t *c,
                                  double c_, double m, double y, double k);

/*----------------------------------------------------------------------------
 * Text object operators (§9.4)
 *--------------------------------------------------------------------------*/

/* BT - Begin text object */
pdfmake_err_t pdfmake_text_BT(pdfmake_content_t *c);

/* ET - End text object */
pdfmake_err_t pdfmake_text_ET(pdfmake_content_t *c);

/*----------------------------------------------------------------------------
 * Text state operators (§9.3)
 *--------------------------------------------------------------------------*/

/* Tc - Set character spacing */
pdfmake_err_t pdfmake_text_Tc(pdfmake_content_t *c, double spacing);

/* Tw - Set word spacing */
pdfmake_err_t pdfmake_text_Tw(pdfmake_content_t *c, double spacing);

/* Tz - Set horizontal scaling (percent) */
pdfmake_err_t pdfmake_text_Tz(pdfmake_content_t *c, double scale);

/* TL - Set text leading */
pdfmake_err_t pdfmake_text_TL(pdfmake_content_t *c, double leading);

/* Tf - Set font and size */
pdfmake_err_t pdfmake_text_Tf(pdfmake_content_t *c,
                                  const char *font_name, double size);

/* Tr - Set text rendering mode */
pdfmake_err_t pdfmake_text_Tr(pdfmake_content_t *c, int mode);

/* Ts - Set text rise */
pdfmake_err_t pdfmake_text_Ts(pdfmake_content_t *c, double rise);

/*----------------------------------------------------------------------------
 * Text positioning operators (§9.4.2)
 *--------------------------------------------------------------------------*/

/* Td - Move text position */
pdfmake_err_t pdfmake_text_Td(pdfmake_content_t *c, double tx, double ty);

/* TD - Move text position and set leading */
pdfmake_err_t pdfmake_text_TD(pdfmake_content_t *c, double tx, double ty);

/* Tm - Set text matrix */
pdfmake_err_t pdfmake_text_Tm(pdfmake_content_t *c,
                                  double a, double b, double c_,
                                  double d, double e, double f);

/* T* - Move to start of next line */
pdfmake_err_t pdfmake_text_Tstar(pdfmake_content_t *c);

/*----------------------------------------------------------------------------
 * Text showing operators (§9.4.3)
 *--------------------------------------------------------------------------*/

/* Tj - Show text string */
pdfmake_err_t pdfmake_text_Tj(pdfmake_content_t *c,
                                  const uint8_t *str, size_t len);

/* Tj - Show text string (null-terminated convenience) */
pdfmake_err_t pdfmake_text_Tj_cstr(pdfmake_content_t *c, const char *str);

/* TJ - Show text with positioning array (mixed strings and numbers).
 * Each element is either:
 *   - A string (type PDFMAKE_STRING)
 *   - A number (type PDFMAKE_INT or PDFMAKE_REAL) for positioning adjustment
 */
pdfmake_err_t pdfmake_text_TJ(pdfmake_content_t *c,
                                  pdfmake_obj_t *array);

/* ' - Move to next line and show text */
pdfmake_err_t pdfmake_text_apostrophe(pdfmake_content_t *c,
                                          const uint8_t *str, size_t len);

/* " - Set word/char spacing, move to next line, show text */
pdfmake_err_t pdfmake_text_quote(pdfmake_content_t *c,
                                     double aw, double ac,
                                     const uint8_t *str, size_t len);

/*----------------------------------------------------------------------------
 * XObject operator (§8.8)
 *--------------------------------------------------------------------------*/

/* Do - Paint XObject */
pdfmake_err_t pdfmake_xobj_Do(pdfmake_content_t *c, const char *name);

/*----------------------------------------------------------------------------
 * Marked content operators (§14.6)
 *--------------------------------------------------------------------------*/

/* MP - Marked content point */
pdfmake_err_t pdfmake_mc_MP(pdfmake_content_t *c, const char *tag);

/* DP - Marked content point with property dict */
pdfmake_err_t pdfmake_mc_DP(pdfmake_content_t *c,
                                const char *tag, const char *props);

/* BMC - Begin marked content sequence */
pdfmake_err_t pdfmake_mc_BMC(pdfmake_content_t *c, const char *tag);

/* BDC - Begin marked content sequence with property dict */
pdfmake_err_t pdfmake_mc_BDC(pdfmake_content_t *c,
                                 const char *tag, const char *props);

/* EMC - End marked content sequence */
pdfmake_err_t pdfmake_mc_EMC(pdfmake_content_t *c);

/*----------------------------------------------------------------------------
 * Shading operator (§8.7.4)
 *--------------------------------------------------------------------------*/

/* sh - Paint shading pattern */
pdfmake_err_t pdfmake_sh(pdfmake_content_t *c, const char *name);

/*----------------------------------------------------------------------------
 * Inline image operators (§8.9.7)
 *--------------------------------------------------------------------------*/

/* BI - Begin inline image (followed by key-value pairs) */
pdfmake_err_t pdfmake_inline_BI(pdfmake_content_t *c);

/* Add key-value pair for inline image header */
pdfmake_err_t pdfmake_inline_key(pdfmake_content_t *c,
                                     const char *key, const char *value);

/* ID - Begin inline image data */
pdfmake_err_t pdfmake_inline_ID(pdfmake_content_t *c);

/* Write raw inline image data */
pdfmake_err_t pdfmake_inline_data(pdfmake_content_t *c,
                                      const uint8_t *data, size_t len);

/* EI - End inline image */
pdfmake_err_t pdfmake_inline_EI(pdfmake_content_t *c);

/*----------------------------------------------------------------------------
 * Compatibility operators (§8.4.5)
 *--------------------------------------------------------------------------*/

/* BX - Begin compatibility section */
pdfmake_err_t pdfmake_compat_BX(pdfmake_content_t *c);

/* EX - End compatibility section */
pdfmake_err_t pdfmake_compat_EX(pdfmake_content_t *c);

#ifdef __cplusplus
}
#endif

#endif /* PDFMAKE_CONTENT_H */

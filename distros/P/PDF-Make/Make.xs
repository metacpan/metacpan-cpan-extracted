#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "pdfmake.h"
#include "pdfmake_buf.h"
#include "pdfmake_writer.h"
#include "pdfmake_doc.h"
#include "pdfmake_meta.h"
#include "pdfmake_page.h"
#include "pdfmake_content.h"
#include "pdfmake_parser.h"
#include "pdfmake_arena.h"
#include "pdfmake_reader.h"
#include "pdfmake_image.h"
#include "pdfmake_font.h"
#include "pdfmake_interpreter.h"
#include "pdfmake_textract.h"
#include "pdfmake_edit.h"
#include "pdfmake_import.h"
#include "pdfmake_ocg.h"
#include "pdfmake_attach.h"
#include "pdfmake_tag.h"
#include "pdfmake_redact.h"
#include "pdfmake_color_mgmt.h"
#include "pdfmake_annot.h"
#include "pdfmake_outline.h"
#include "pdfmake_action.h"
#include "pdfmake_crypt.h"
#include "pdfmake_form.h"
#include "pdfmake_watermark.h"
#include "pdfmake_signature.h"
#include "pdfmake_x509.h"
#include "pdfmake_pkcs12.h"
#include "pdfmake_linear.h"
#include "pdfmake_image_render.h"
#include "pdfmake_custom_ops.h"
#include "pdfmake_filter.h"

/* -------------------------------------------------------------------------
 * Render API forward declarations
 * ------------------------------------------------------------------------- */
struct pdfmake_render_ctx {
    uint32_t *pixels;
    int width;
    int height;
    int stride;
};
#ifndef PDFMAKE_RENDER_CTX_T_DEFINED
#define PDFMAKE_RENDER_CTX_T_DEFINED
typedef struct pdfmake_render_ctx pdfmake_render_ctx_t;
#endif

typedef pdfmake_render_ctx_t* PDF__Make__Render;

typedef enum {
    PDFMAKE_RENDER_OK = 0,
    PDFMAKE_RENDER_ERR_NULL,
    PDFMAKE_RENDER_ERR_MEMORY,
    PDFMAKE_RENDER_ERR_INVALID,
    PDFMAKE_RENDER_ERR_OVERFLOW,
    PDFMAKE_RENDER_ERR_EMPTY_PATH,
} pdfmake_render_err_t;

typedef int pdfmake_line_cap_t;
typedef int pdfmake_line_join_t;
typedef int pdfmake_fill_rule_t;

typedef struct {
    double a, b, c, d, e, f;
} pdfmake_matrix_t;

pdfmake_render_ctx_t *pdfmake_render_create(int width, int height);
void pdfmake_render_destroy(pdfmake_render_ctx_t *ctx);
void pdfmake_render_clear(pdfmake_render_ctx_t *ctx, pdfmake_color_t color);
pdfmake_render_err_t pdfmake_render_save(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_restore(pdfmake_render_ctx_t *ctx);
void pdfmake_render_set_fill_color(pdfmake_render_ctx_t *ctx, double r, double g, double b, double a);
void pdfmake_render_set_stroke_color(pdfmake_render_ctx_t *ctx, double r, double g, double b, double a);
void pdfmake_render_set_line_width(pdfmake_render_ctx_t *ctx, double width);
void pdfmake_render_set_line_cap(pdfmake_render_ctx_t *ctx, pdfmake_line_cap_t cap);
void pdfmake_render_set_line_join(pdfmake_render_ctx_t *ctx, pdfmake_line_join_t join);
void pdfmake_render_set_miter_limit(pdfmake_render_ctx_t *ctx, double limit);
pdfmake_render_err_t pdfmake_render_set_dash(pdfmake_render_ctx_t *ctx, double *array, size_t count, double phase);
void pdfmake_render_set_fill_rule(pdfmake_render_ctx_t *ctx, pdfmake_fill_rule_t rule);
void pdfmake_render_translate(pdfmake_render_ctx_t *ctx, double tx, double ty);
void pdfmake_render_scale(pdfmake_render_ctx_t *ctx, double sx, double sy);
void pdfmake_render_rotate(pdfmake_render_ctx_t *ctx, double angle);
void pdfmake_render_set_matrix(pdfmake_render_ctx_t *ctx, pdfmake_matrix_t *m);
pdfmake_render_err_t pdfmake_render_move_to(pdfmake_render_ctx_t *ctx, double x, double y);
pdfmake_render_err_t pdfmake_render_line_to(pdfmake_render_ctx_t *ctx, double x, double y);
pdfmake_render_err_t pdfmake_render_curve_to(pdfmake_render_ctx_t *ctx, double x1, double y1, double x2, double y2, double x3, double y3);
pdfmake_render_err_t pdfmake_render_close_path(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_rect(pdfmake_render_ctx_t *ctx, double x, double y, double w, double h);
void pdfmake_render_new_path(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_fill(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_fill_preserve(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_stroke(pdfmake_render_ctx_t *ctx);
pdfmake_render_err_t pdfmake_render_clip(pdfmake_render_ctx_t *ctx);
void pdfmake_render_reset_clip(pdfmake_render_ctx_t *ctx);
uint32_t pdfmake_render_get_pixel(pdfmake_render_ctx_t *ctx, int x, int y);

#ifndef PDFMAKE_FILL_NONZERO
#define PDFMAKE_FILL_NONZERO 0
#endif
#ifndef PDFMAKE_FILL_EVENODD
#define PDFMAKE_FILL_EVENODD 1
#endif

/* -------------------------------------------------------------------------
 * Render-page API forward declarations
 * ------------------------------------------------------------------------- */
typedef enum {
    PDFMAKE_SCALE_NEAREST  = 0,
    PDFMAKE_SCALE_BILINEAR = 1,
    PDFMAKE_SCALE_BICUBIC  = 2,
} pdfmake_scale_mode_t;

typedef struct pdfmake_render_opts {
    double dpi;
    double scale;
    pdfmake_scale_mode_t scale_mode;
    int antialias;
    double flatness;
    pdfmake_rotation_t rotation;
    uint32_t background;
    double clip_x, clip_y;
    double clip_width, clip_height;
    int use_clip;
    int render_text;
    int render_images;
    int render_vectors;
    int render_annotations;
    int show_text_bounds;
    int show_image_bounds;
    int show_clip_regions;
} pdfmake_render_opts_t;

typedef struct pdfmake_page_render {
    uint32_t *pixels;
    int width;
    int height;
    int stride;
    double page_width;
    double page_height;
    double effective_dpi;
    int text_objects;
    int path_objects;
    int image_objects;
    double render_time_ms;
    int error_count;
    char error_msg[256];
} pdfmake_page_render_t;

void pdfmake_render_opts_init(pdfmake_render_opts_t *opts);
pdfmake_err_t pdfmake_render_page_to_pixels(pdfmake_reader_t *reader, int page_num, const pdfmake_render_opts_t *opts, pdfmake_page_render_t *result);
pdfmake_err_t pdfmake_render_page_region(pdfmake_reader_t *reader, int page_num, double region_x, double region_y, double region_w, double region_h, const pdfmake_render_opts_t *opts, pdfmake_page_render_t *result);
void pdfmake_page_render_free(pdfmake_page_render_t *result);
void pdfmake_page_get_render_size(pdfmake_reader_t *reader, int page_num, double dpi, int *width, int *height);

/* Missing prototype in header, implemented in src/pdfmake_image_scale.c */
pdfmake_imgr_err_t pdfmake_decoded_image_resize(
    pdfmake_decoded_image_t *img,
    int new_w, int new_h,
    pdfmake_interp_mode_t mode,
    pdfmake_arena_t *arena);

/* Shared helper for render_page.xs */
static void hv_to_render_opts(pTHX_ HV *hv, pdfmake_render_opts_t *opts)
{
    SV **sv;

    pdfmake_render_opts_init(opts);

    if (!hv) return;

    if ((sv = hv_fetchs(hv, "dpi", 0)) && SvOK(*sv)) {
        opts->dpi = SvNV(*sv);
    }
    if ((sv = hv_fetchs(hv, "scale", 0)) && SvOK(*sv)) {
        opts->scale = SvNV(*sv);
    }
    if ((sv = hv_fetchs(hv, "scale_mode", 0)) && SvOK(*sv)) {
        opts->scale_mode = (pdfmake_scale_mode_t)SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "antialias", 0)) && SvOK(*sv)) {
        opts->antialias = SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "flatness", 0)) && SvOK(*sv)) {
        opts->flatness = SvNV(*sv);
    }
    if ((sv = hv_fetchs(hv, "rotation", 0)) && SvOK(*sv)) {
        opts->rotation = (pdfmake_rotation_t)SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "background", 0)) && SvOK(*sv)) {
        opts->background = (uint32_t)SvUV(*sv);
    }
    if ((sv = hv_fetchs(hv, "render_text", 0)) && SvOK(*sv)) {
        opts->render_text = SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "render_images", 0)) && SvOK(*sv)) {
        opts->render_images = SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "render_vectors", 0)) && SvOK(*sv)) {
        opts->render_vectors = SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "render_annotations", 0)) && SvOK(*sv)) {
        opts->render_annotations = SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "show_text_bounds", 0)) && SvOK(*sv)) {
        opts->show_text_bounds = SvIV(*sv);
    }
    if ((sv = hv_fetchs(hv, "show_image_bounds", 0)) && SvOK(*sv)) {
        opts->show_image_bounds = SvIV(*sv);
    }
}

/* XOP descriptors — registered once in main BOOT, used by all modules */
static XOP pdfmake_chain_xop;
static XOP pdfmake_getter_xop;

/* Writer wrapper struct for XS binding. */
typedef struct {
    pdfmake_buf_t buf;
} pdfmake_writer_xs_t;

/* Arena wrapper struct - owns the arena. */
typedef struct {
    pdfmake_arena_t *arena;
} pdfmake_arena_xs_t;

/* Parser wrapper struct - owns parser, keeps buffer alive. */
typedef struct {
    pdfmake_parser_t *parser;
    SV               *bytes_sv;  /* Keep input buffer alive for parser */
    pdfmake_doc_t    *doc;       /* Parsed document (NULL until parsed) */
    int               parsed;    /* Whether parse() has been called */
} pdfmake_parser_xs_t;

/* Reader wrapper struct - owns reader, references parser. */
typedef struct {
    pdfmake_reader_t *reader;
    SV               *parser_sv;  /* SV ref to parser to keep it alive */
} pdfmake_reader_xs_t;

/* Reader page wrapper - references reader. */
typedef struct {
    pdfmake_reader_page_t *page;
    SV                    *reader_sv;  /* SV ref to reader to keep it alive */
} pdfmake_reader_page_xs_t;

/* Obj wrapper struct - holds arena and pointer to obj in arena. */
typedef struct {
    pdfmake_arena_xs_t *arena_xs;  /* Ref to arena wrapper (kept alive via SV) */
    SV                 *arena_sv;  /* SV ref to arena to prevent GC */
    pdfmake_obj_t      *obj;       /* Pointer to obj allocated in arena */
} pdfmake_obj_xs_t;
/* Encryption context wrapper. */
typedef struct {
    pdfmake_crypt_ctx_t ctx;
} pdfmake_crypt_xs_t;

MODULE = PDF::Make  PACKAGE = PDF::Make
PROTOTYPES: ENABLE

const char *
version()
    CODE:
        RETVAL = pdfmake_version();
    OUTPUT:
        RETVAL

BOOT:
{
    /* Register custom op XOPs */
    PDFMAKE_REGISTER_XOP(pdfmake_chain_xop, pp_pdfmake_chain,
                         "pdfmake_chain", "PDF::Make chainable method");
    PDFMAKE_REGISTER_XOP(pdfmake_getter_xop, pp_pdfmake_getter,
                         "pdfmake_getter", "PDF::Make struct getter");

    /* Register additional XOPs */
    static XOP pdfmake_meta_xop;
    PDFMAKE_REGISTER_XOP(pdfmake_meta_xop, pp_pdfmake_meta,
                         "pdfmake_meta", "PDF::Make metadata getter/setter");
    static XOP pdfmake_indirect_xop;
    PDFMAKE_REGISTER_XOP(pdfmake_indirect_xop, pp_pdfmake_indirect_getter,
                         "pdfmake_indirect", "PDF::Make indirect getter");
    static XOP pdfmake_typetest_xop;
    PDFMAKE_REGISTER_XOP(pdfmake_typetest_xop, pp_pdfmake_typetest,
                         "pdfmake_typetest", "PDF::Make type test");
    static XOP pdfmake_arena_ctor_xop;
    PDFMAKE_REGISTER_XOP(pdfmake_arena_ctor_xop, pp_pdfmake_arena_ctor,
                         "pdfmake_arena_ctor", "PDF::Make arena constructor");

    /* Per-module BOOT sections register their own getters, constants,
     * and chain dispatch tables via INCLUDE: directives below */
}

INCLUDE: xs/writer.xs
INCLUDE: xs/document.xs
INCLUDE: xs/page.xs
INCLUDE: xs/canvas.xs
INCLUDE: xs/parser.xs
INCLUDE: xs/arena.xs
INCLUDE: xs/obj.xs
INCLUDE: xs/reader.xs
INCLUDE: xs/image.xs
INCLUDE: xs/font.xs
INCLUDE: xs/extract.xs
INCLUDE: xs/outline.xs
INCLUDE: xs/action.xs
INCLUDE: xs/crypt.xs
INCLUDE: xs/form.xs
INCLUDE: xs/layer.xs
INCLUDE: xs/attach.xs
INCLUDE: xs/tag.xs
INCLUDE: xs/redact.xs
INCLUDE: xs/color.xs
INCLUDE: xs/watermark.xs
INCLUDE: xs/signature.xs
INCLUDE: xs/linear.xs
INCLUDE: xs/render.xs
INCLUDE: xs/render_page.xs
INCLUDE: xs/image_render.xs
INCLUDE: xs/import.xs
INCLUDE: xs/filter.xs

MODULE = PDF::Make::Render    PACKAGE = PDF::Make::Render    PREFIX = pdfmake_render_

PROTOTYPES: DISABLE

#
# Constructor / Destructor
#

PDF::Make::Render
pdfmake_render_new(class, width, height)
    char *class
    int width
    int height
CODE:
    PERL_UNUSED_VAR(class);
    RETVAL = pdfmake_render_create(width, height);
    if (!RETVAL) {
        croak("Failed to create render context");
    }
OUTPUT:
    RETVAL

void
pdfmake_render_DESTROY(ctx)
    PDF::Make::Render ctx
CODE:
    pdfmake_render_destroy(ctx);

#
# Context Properties
#

int
pdfmake_render_width(ctx)
    PDF::Make::Render ctx
CODE:
    RETVAL = ctx->width;
OUTPUT:
    RETVAL

int
pdfmake_render_height(ctx)
    PDF::Make::Render ctx
CODE:
    RETVAL = ctx->height;
OUTPUT:
    RETVAL

#
# Clear
#

void
pdfmake_render_clear(ctx, r=1.0, g=1.0, b=1.0, a=1.0)
    PDF::Make::Render ctx
    double r
    double g
    double b
    double a
CODE:
    pdfmake_color_t color = {r, g, b, a};
    pdfmake_render_clear(ctx, color);

#
# Graphics State
#

void
pdfmake_render_save(ctx)
    PDF::Make::Render ctx
CODE:
    pdfmake_render_err_t err = pdfmake_render_save(ctx);
    if (err != PDFMAKE_RENDER_OK) {
        croak("Failed to save graphics state: %d", err);
    }

void
pdfmake_render_restore(ctx)
    PDF::Make::Render ctx
CODE:
    pdfmake_render_err_t err = pdfmake_render_restore(ctx);
    if (err != PDFMAKE_RENDER_OK) {
        croak("Failed to restore graphics state: %d", err);
    }

#
# Colors
#

void
pdfmake_render_set_fill_color(ctx, r, g, b, a=1.0)
    PDF::Make::Render ctx
    double r
    double g
    double b
    double a
CODE:
    pdfmake_render_set_fill_color(ctx, r, g, b, a);

void
pdfmake_render_set_stroke_color(ctx, r, g, b, a=1.0)
    PDF::Make::Render ctx
    double r
    double g
    double b
    double a
CODE:
    pdfmake_render_set_stroke_color(ctx, r, g, b, a);

#
# Stroke Style
#

void
pdfmake_render_set_line_width(ctx, width)
    PDF::Make::Render ctx
    double width
CODE:
    pdfmake_render_set_line_width(ctx, width);

void
pdfmake_render_set_line_cap(ctx, cap)
    PDF::Make::Render ctx
    int cap
CODE:
    pdfmake_render_set_line_cap(ctx, (pdfmake_line_cap_t)cap);

void
pdfmake_render_set_line_join(ctx, join)
    PDF::Make::Render ctx
    int join
CODE:
    pdfmake_render_set_line_join(ctx, (pdfmake_line_join_t)join);

void
pdfmake_render_set_miter_limit(ctx, limit)
    PDF::Make::Render ctx
    double limit
CODE:
    pdfmake_render_set_miter_limit(ctx, limit);

void
pdfmake_render_set_dash(ctx, ...)
    PDF::Make::Render ctx
PREINIT:
    double *array = NULL;
    size_t count = 0;
    double phase = 0;
CODE:
    if (items > 1) {
        AV *dash_av;
        if (SvROK(ST(1)) && SvTYPE(SvRV(ST(1))) == SVt_PVAV) {
            dash_av = (AV*)SvRV(ST(1));
            count = av_len(dash_av) + 1;
            if (count > 0) {
                array = malloc(count * sizeof(double));
                for (size_t i = 0; i < count; i++) {
                    SV **elem = av_fetch(dash_av, i, 0);
                    array[i] = elem ? SvNV(*elem) : 0;
                }
            }
        }
        if (items > 2) {
            phase = SvNV(ST(2));
        }
    }
    pdfmake_render_set_dash(ctx, array, count, phase);
    if (array) free(array);

#
# Fill Rule
#

void
pdfmake_render_set_fill_rule(ctx, rule)
    PDF::Make::Render ctx
    int rule
CODE:
    pdfmake_render_set_fill_rule(ctx, (pdfmake_fill_rule_t)rule);

#
# Transformations
#

void
pdfmake_render_translate(ctx, tx, ty)
    PDF::Make::Render ctx
    double tx
    double ty
CODE:
    pdfmake_render_translate(ctx, tx, ty);

void
pdfmake_render_scale(ctx, sx, sy)
    PDF::Make::Render ctx
    double sx
    double sy
CODE:
    pdfmake_render_scale(ctx, sx, sy);

void
pdfmake_render_rotate(ctx, angle)
    PDF::Make::Render ctx
    double angle
CODE:
    pdfmake_render_rotate(ctx, angle);

void
pdfmake_render_set_matrix(ctx, a, b, c, d, e, f)
    PDF::Make::Render ctx
    double a
    double b
    double c
    double d
    double e
    double f
CODE:
    pdfmake_matrix_t m = {a, b, c, d, e, f};
    pdfmake_render_set_matrix(ctx, &m);

#
# Path Construction
#

void
pdfmake_render_move_to(ctx, x, y)
    PDF::Make::Render ctx
    double x
    double y
CODE:
    pdfmake_render_move_to(ctx, x, y);

void
pdfmake_render_line_to(ctx, x, y)
    PDF::Make::Render ctx
    double x
    double y
CODE:
    pdfmake_render_line_to(ctx, x, y);

void
pdfmake_render_curve_to(ctx, x1, y1, x2, y2, x3, y3)
    PDF::Make::Render ctx
    double x1
    double y1
    double x2
    double y2
    double x3
    double y3
CODE:
    pdfmake_render_curve_to(ctx, x1, y1, x2, y2, x3, y3);

void
pdfmake_render_close_path(ctx)
    PDF::Make::Render ctx
CODE:
    pdfmake_render_close_path(ctx);

void
pdfmake_render_rect(ctx, x, y, w, h)
    PDF::Make::Render ctx
    double x
    double y
    double w
    double h
CODE:
    pdfmake_render_rect(ctx, x, y, w, h);

void
pdfmake_render_new_path(ctx)
    PDF::Make::Render ctx
CODE:
    pdfmake_render_new_path(ctx);

#
# Path Painting
#

void
pdfmake_render_fill(ctx)
    PDF::Make::Render ctx
CODE:
    pdfmake_render_err_t err = pdfmake_render_fill(ctx);
    if (err != PDFMAKE_RENDER_OK && err != PDFMAKE_RENDER_ERR_EMPTY_PATH) {
        croak("Fill failed: %d", err);
    }

void
pdfmake_render_stroke(ctx)
    PDF::Make::Render ctx
CODE:
    pdfmake_render_err_t err = pdfmake_render_stroke(ctx);
    if (err != PDFMAKE_RENDER_OK && err != PDFMAKE_RENDER_ERR_EMPTY_PATH) {
        croak("Stroke failed: %d", err);
    }

void
pdfmake_render_fill_stroke(ctx)
    PDF::Make::Render ctx
CODE:
    pdfmake_render_fill_preserve(ctx);
    pdfmake_render_stroke(ctx);

#
# Clipping
#

void
pdfmake_render_clip(ctx)
    PDF::Make::Render ctx
CODE:
    pdfmake_render_err_t err = pdfmake_render_clip(ctx);
    if (err != PDFMAKE_RENDER_OK && err != PDFMAKE_RENDER_ERR_EMPTY_PATH) {
        croak("Clip failed: %d", err);
    }

void
pdfmake_render_reset_clip(ctx)
    PDF::Make::Render ctx
CODE:
    pdfmake_render_reset_clip(ctx);

#
# Pixel Access
#

SV *
pdfmake_render_get_pixel(ctx, x, y)
    PDF::Make::Render ctx
    int x
    int y
CODE:
    uint32_t packed = pdfmake_render_get_pixel(ctx, x, y);
    HV *hv = newHV();
    hv_store(hv, "r", 1, newSViv((packed >> 16) & 0xFF), 0);
    hv_store(hv, "g", 1, newSViv((packed >> 8) & 0xFF), 0);
    hv_store(hv, "b", 1, newSViv(packed & 0xFF), 0);
    hv_store(hv, "a", 1, newSViv((packed >> 24) & 0xFF), 0);
    RETVAL = newRV_noinc((SV*)hv);
OUTPUT:
    RETVAL

SV *
pdfmake_render_get_pixels(ctx)
    PDF::Make::Render ctx
CODE:
    size_t size = ctx->width * ctx->height * 4;
    RETVAL = newSVpvn((char*)ctx->pixels, size);
OUTPUT:
    RETVAL

#
# Constants
#

int
CAP_BUTT()
CODE:
    RETVAL = PDFMAKE_CAP_BUTT;
OUTPUT:
    RETVAL

int
CAP_ROUND()
CODE:
    RETVAL = PDFMAKE_CAP_ROUND;
OUTPUT:
    RETVAL

int
CAP_SQUARE()
CODE:
    RETVAL = PDFMAKE_CAP_SQUARE;
OUTPUT:
    RETVAL

int
JOIN_MITER()
CODE:
    RETVAL = PDFMAKE_JOIN_MITER;
OUTPUT:
    RETVAL

int
JOIN_ROUND()
CODE:
    RETVAL = PDFMAKE_JOIN_ROUND;
OUTPUT:
    RETVAL

int
JOIN_BEVEL()
CODE:
    RETVAL = PDFMAKE_JOIN_BEVEL;
OUTPUT:
    RETVAL

int
FILL_NONZERO()
CODE:
    RETVAL = PDFMAKE_FILL_NONZERO;
OUTPUT:
    RETVAL

int
FILL_EVENODD()
CODE:
    RETVAL = PDFMAKE_FILL_EVENODD;
OUTPUT:
    RETVAL

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Render", GV_ADD);
    PDFMAKE_REGISTER_CONST(stash, "CAP_BUTT",     PDFMAKE_CAP_BUTT);
    PDFMAKE_REGISTER_CONST(stash, "CAP_ROUND",    PDFMAKE_CAP_ROUND);
    PDFMAKE_REGISTER_CONST(stash, "CAP_SQUARE",   PDFMAKE_CAP_SQUARE);
    PDFMAKE_REGISTER_CONST(stash, "JOIN_MITER",   PDFMAKE_JOIN_MITER);
    PDFMAKE_REGISTER_CONST(stash, "JOIN_ROUND",   PDFMAKE_JOIN_ROUND);
    PDFMAKE_REGISTER_CONST(stash, "JOIN_BEVEL",   PDFMAKE_JOIN_BEVEL);
    PDFMAKE_REGISTER_CONST(stash, "FILL_NONZERO", PDFMAKE_FILL_NONZERO);
    PDFMAKE_REGISTER_CONST(stash, "FILL_EVENODD", PDFMAKE_FILL_EVENODD);

    /* TODO: Render dispatch table — pending header conflict fix
     * The pdfmake_render.h has enum/struct redefinitions when
     * compiled as part of Make.xs. Enable once headers are fixed.
     */
#if 0
    enum {
        ROP_SAVE, ROP_RESTORE,
        ROP_SET_LINE_WIDTH, ROP_SET_LINE_CAP, ROP_SET_LINE_JOIN,
        ROP_SET_MITER_LIMIT, ROP_SET_FILL_RULE,
        ROP_TRANSLATE, ROP_SCALE, ROP_ROTATE,
        ROP_MOVE_TO, ROP_LINE_TO, ROP_CLOSE_PATH,
        ROP_RECT, ROP_NEW_PATH,
        ROP_SET_MATRIX, ROP_CURVE_TO,
        ROP_COUNT
    };
    static pdfmake_chain_entry_t render_dispatch[ROP_COUNT] = {
        [ROP_SAVE]           = { (void*)pdfmake_render_save,           0, {}, .ret_mode=2 },
        [ROP_RESTORE]        = { (void*)pdfmake_render_restore,        0, {}, .ret_mode=2 },
        [ROP_SET_LINE_WIDTH] = { (void*)pdfmake_render_set_line_width, 1, {PDFMAKE_ARG_DOUBLE}, .ret_mode=2 },
        [ROP_SET_LINE_CAP]   = { (void*)pdfmake_render_set_line_cap,   1, {PDFMAKE_ARG_INT}, .ret_mode=2 },
        [ROP_SET_LINE_JOIN]  = { (void*)pdfmake_render_set_line_join,  1, {PDFMAKE_ARG_INT}, .ret_mode=2 },
        [ROP_SET_MITER_LIMIT]= { (void*)pdfmake_render_set_miter_limit,1, {PDFMAKE_ARG_DOUBLE}, .ret_mode=2 },
        [ROP_SET_FILL_RULE]  = { (void*)pdfmake_render_set_fill_rule,  1, {PDFMAKE_ARG_INT}, .ret_mode=2 },
        [ROP_TRANSLATE]      = { (void*)pdfmake_render_translate,      2, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE}, .ret_mode=2 },
        [ROP_SCALE]          = { (void*)pdfmake_render_scale,          2, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE}, .ret_mode=2 },
        [ROP_ROTATE]         = { (void*)pdfmake_render_rotate,         1, {PDFMAKE_ARG_DOUBLE}, .ret_mode=2 },
        [ROP_MOVE_TO]        = { (void*)pdfmake_render_move_to,        2, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE}, .ret_mode=2 },
        [ROP_LINE_TO]        = { (void*)pdfmake_render_line_to,        2, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE}, .ret_mode=2 },
        [ROP_CLOSE_PATH]     = { (void*)pdfmake_render_close_path,     0, {}, .ret_mode=2 },
        [ROP_RECT]           = { (void*)pdfmake_render_rect,           4, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE}, .ret_mode=2 },
        [ROP_NEW_PATH]       = { (void*)pdfmake_render_new_path,       0, {}, .ret_mode=2 },
        [ROP_SET_MATRIX]     = { (void*)pdfmake_render_set_matrix,     6, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE}, .ret_mode=2 },
        [ROP_CURVE_TO]       = { (void*)pdfmake_render_curve_to,       6, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE}, .ret_mode=2 },
    };
    int render_table_id = pdfmake_chain_table_count++;
    pdfmake_chain_tables[render_table_id] = render_dispatch;

    /* Method names after PREFIX strip: pdfmake_render_save -> save */
    struct { const char *name; int idx; } render_methods[] = {
        {"save", ROP_SAVE},
        {"restore", ROP_RESTORE},
        {"set_line_width", ROP_SET_LINE_WIDTH},
        {"set_line_cap", ROP_SET_LINE_CAP},
        {"set_line_join", ROP_SET_LINE_JOIN},
        {"set_miter_limit", ROP_SET_MITER_LIMIT},
        {"set_fill_rule", ROP_SET_FILL_RULE},
        {"translate", ROP_TRANSLATE},
        {"scale", ROP_SCALE},
        {"rotate", ROP_ROTATE},
        {"move_to", ROP_MOVE_TO},
        {"line_to", ROP_LINE_TO},
        {"close_path", ROP_CLOSE_PATH},
        {"rect", ROP_RECT},
        {"new_path", ROP_NEW_PATH},
        {"set_matrix", ROP_SET_MATRIX},
        {"curve_to", ROP_CURVE_TO},
        {NULL, 0}
    };
    int ri;
    for (ri = 0; render_methods[ri].name; ri++) {
        PDFMAKE_REGISTER_CHAIN(stash, render_methods[ri].name,
            render_table_id, render_methods[ri].idx);
    }
#endif
}

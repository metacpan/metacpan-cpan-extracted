MODULE = PDF::Make  PACKAGE = PDF::Make::Canvas
PROTOTYPES: ENABLE

pdfmake_content_t *
new(class)
    char *class
    PREINIT:
        pdfmake_arena_t *arena;
    CODE:
        PERL_UNUSED_VAR(class);
        arena = pdfmake_arena_new();
        if (!arena) {
            croak("PDF::Make::Canvas::new: failed to create arena");
        }
        RETVAL = pdfmake_content_new(arena);
        if (!RETVAL) {
            pdfmake_arena_free(arena);
            croak("PDF::Make::Canvas::new: failed to create content");
        }
    OUTPUT:
        RETVAL

SV *
to_bytes(self)
    pdfmake_content_t *self
    CODE:
        const uint8_t *data = pdfmake_content_data(self);
        size_t len = pdfmake_content_len(self);
        RETVAL = newSVpvn((char *)data, len);
    OUTPUT:
        RETVAL

UV
len(self)
    pdfmake_content_t *self
    CODE:
        RETVAL = pdfmake_content_len(self);
    OUTPUT:
        RETVAL

SV *
clear(self)
    pdfmake_content_t *self
    CODE:
        pdfmake_content_clear(self);
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_content_t *self
    CODE:
        if (self) {
            pdfmake_arena_t *arena = self->arena;
            pdfmake_content_free(self);
            pdfmake_arena_free(arena);
        }

#
# Graphics State Operators
#

SV *
q(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_gs_q(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::q: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
Q(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_gs_Q(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::Q: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
cm(self, a, b, c, d, e, f)
    pdfmake_content_t *self
    double a
    double b
    double c
    double d
    double e
    double f
    CODE:
        if (pdfmake_gs_cm(self, a, b, c, d, e, f) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::cm: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
w(self, width)
    pdfmake_content_t *self
    double width
    CODE:
        if (pdfmake_gs_w(self, width) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::w: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
J(self, cap)
    pdfmake_content_t *self
    int cap
    CODE:
        if (pdfmake_gs_J(self, cap) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::J: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
j(self, join)
    pdfmake_content_t *self
    int join
    CODE:
        if (pdfmake_gs_j(self, join) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::j: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
M(self, miter)
    pdfmake_content_t *self
    double miter
    CODE:
        if (pdfmake_gs_M(self, miter) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::M: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
d(self, dash_array, dash_phase)
    pdfmake_content_t *self
    AV *dash_array
    double dash_phase
    PREINIT:
        SSize_t array_len;
        double *pattern;
        SSize_t i;
    CODE:
        array_len = av_len(dash_array) + 1;
        Newx(pattern, array_len, double);
        for (i = 0; i < array_len; i++) {
            SV **elem = av_fetch(dash_array, i, 0);
            pattern[i] = elem ? SvNV(*elem) : 0.0;
        }
        pdfmake_err_t err = pdfmake_gs_d(self, pattern, (size_t)array_len, dash_phase);
        Safefree(pattern);
        if (err != PDFMAKE_OK)
            croak("PDF::Make::Canvas::d: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
ri(self, intent)
    pdfmake_content_t *self
    const char *intent
    CODE:
        if (pdfmake_gs_ri(self, intent) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::ri: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
i(self, flatness)
    pdfmake_content_t *self
    double flatness
    CODE:
        if (pdfmake_gs_i(self, flatness) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::i: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
gs(self, name)
    pdfmake_content_t *self
    const char *name
    CODE:
        if (pdfmake_gs_gs(self, name) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::gs: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

#
# Path Construction Operators
#

SV *
m(self, x, y)
    pdfmake_content_t *self
    double x
    double y
    CODE:
        if (pdfmake_path_m(self, x, y) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::m: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
l(self, x, y)
    pdfmake_content_t *self
    double x
    double y
    CODE:
        if (pdfmake_path_l(self, x, y) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::l: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
c(self, x1, y1, x2, y2, x3, y3)
    pdfmake_content_t *self
    double x1
    double y1
    double x2
    double y2
    double x3
    double y3
    CODE:
        if (pdfmake_path_c(self, x1, y1, x2, y2, x3, y3) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::c: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
v(self, x2, y2, x3, y3)
    pdfmake_content_t *self
    double x2
    double y2
    double x3
    double y3
    CODE:
        if (pdfmake_path_v(self, x2, y2, x3, y3) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::v: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
y(self, x1, y1, x3, y3)
    pdfmake_content_t *self
    double x1
    double y1
    double x3
    double y3
    CODE:
        if (pdfmake_path_y(self, x1, y1, x3, y3) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::y: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
re(self, x, y, width, height)
    pdfmake_content_t *self
    double x
    double y
    double width
    double height
    CODE:
        if (pdfmake_path_re(self, x, y, width, height) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::re: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
h(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_path_h(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::h: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

#
# Path Painting Operators
#

SV *
S(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_paint_S(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::S: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
s(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_paint_s(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::s: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
f(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_paint_f(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::f: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
f_star(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_paint_f_star(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::f_star: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
B(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_paint_B(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::B: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
B_star(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_paint_B_star(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::B_star: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
b(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_paint_b(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::b: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
b_star(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_paint_b_star(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::b_star: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
n(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_paint_n(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::n: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

#
# Clipping Path Operators
#

SV *
W(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_clip_W(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::W: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
W_star(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_clip_W_star(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::W_star: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

#
# Color Operators
#

SV *
CS(self, name)
    pdfmake_content_t *self
    const char *name
    CODE:
        if (pdfmake_color_CS(self, name) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::CS: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
cs(self, name)
    pdfmake_content_t *self
    const char *name
    CODE:
        if (pdfmake_color_cs(self, name) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::cs: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
G(self, gray)
    pdfmake_content_t *self
    double gray
    CODE:
        if (pdfmake_color_G(self, gray) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::G: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
g(self, gray)
    pdfmake_content_t *self
    double gray
    CODE:
        if (pdfmake_color_g(self, gray) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::g: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
RG(self, r, g, b)
    pdfmake_content_t *self
    double r
    double g
    double b
    CODE:
        if (pdfmake_color_RG(self, r, g, b) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::RG: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
rg(self, r, g, b)
    pdfmake_content_t *self
    double r
    double g
    double b
    CODE:
        if (pdfmake_color_rg(self, r, g, b) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::rg: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
K(self, c, m, y, k)
    pdfmake_content_t *self
    double c
    double m
    double y
    double k
    CODE:
        if (pdfmake_color_K(self, c, m, y, k) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::K: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
k(self, c, m, y, k)
    pdfmake_content_t *self
    double c
    double m
    double y
    double k
    CODE:
        if (pdfmake_color_k(self, c, m, y, k) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::k: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

#
# Text Operators
#

SV *
BT(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_text_BT(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::BT: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
ET(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_text_ET(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::ET: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
Tc(self, charSpace)
    pdfmake_content_t *self
    double charSpace
    CODE:
        if (pdfmake_text_Tc(self, charSpace) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::Tc: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
Tw(self, wordSpace)
    pdfmake_content_t *self
    double wordSpace
    CODE:
        if (pdfmake_text_Tw(self, wordSpace) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::Tw: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
Tz(self, scale)
    pdfmake_content_t *self
    double scale
    CODE:
        if (pdfmake_text_Tz(self, scale) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::Tz: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
TL(self, leading)
    pdfmake_content_t *self
    double leading
    CODE:
        if (pdfmake_text_TL(self, leading) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::TL: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
Tf(self, font, size)
    pdfmake_content_t *self
    const char *font
    double size
    CODE:
        if (pdfmake_text_Tf(self, font, size) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::Tf: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
Tr(self, render)
    pdfmake_content_t *self
    int render
    CODE:
        if (pdfmake_text_Tr(self, render) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::Tr: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
Ts(self, rise)
    pdfmake_content_t *self
    double rise
    CODE:
        if (pdfmake_text_Ts(self, rise) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::Ts: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
Td(self, tx, ty)
    pdfmake_content_t *self
    double tx
    double ty
    CODE:
        if (pdfmake_text_Td(self, tx, ty) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::Td: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
TD(self, tx, ty)
    pdfmake_content_t *self
    double tx
    double ty
    CODE:
        if (pdfmake_text_TD(self, tx, ty) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::TD: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
Tm(self, a, b, c, d, e, f)
    pdfmake_content_t *self
    double a
    double b
    double c
    double d
    double e
    double f
    CODE:
        if (pdfmake_text_Tm(self, a, b, c, d, e, f) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::Tm: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
T_star(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_text_Tstar(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::T_star: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
Tj(self, text)
    pdfmake_content_t *self
    SV *text
    PREINIT:
        STRLEN len;
        const char *str;
    CODE:
        str = SvPV(text, len);
        if (pdfmake_text_Tj(self, (const uint8_t *)str, len) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::Tj: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
TJ(self, array)
    pdfmake_content_t *self
    AV *array
    PREINIT:
        pdfmake_arena_t *arena;
        SSize_t array_len;
        pdfmake_obj_t arr_obj;
        SSize_t i;
    CODE:
        arena = self->arena;
        array_len = av_len(array) + 1;

        /* Create a PDF array object */
        arr_obj = pdfmake_array_new(arena);
        if (arr_obj.kind != PDFMAKE_ARRAY)
            croak("PDF::Make::Canvas::TJ: failed to create array");

        for (i = 0; i < array_len; i++) {
            SV **elem = av_fetch(array, i, 0);
            pdfmake_obj_t item;
            if (!elem) {
                item = pdfmake_null();
            } else if (SvIOK(*elem) || SvNOK(*elem)) {
                item = pdfmake_real(SvNV(*elem));
            } else if (SvPOK(*elem)) {
                STRLEN len;
                const char *str = SvPV(*elem, len);
                item = pdfmake_str(arena, str, len);
            } else {
                croak("PDF::Make::Canvas::TJ: unsupported element type");
            }
            if (!pdfmake_array_push(arena, &arr_obj, item))
                croak("PDF::Make::Canvas::TJ: failed to push element");
        }

        pdfmake_err_t err = pdfmake_text_TJ(self, &arr_obj);
        if (err != PDFMAKE_OK)
            croak("PDF::Make::Canvas::TJ: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
apostrophe(self, text)
    pdfmake_content_t *self
    SV *text
    PREINIT:
        STRLEN len;
        const char *str;
    CODE:
        str = SvPV(text, len);
        if (pdfmake_text_apostrophe(self, (const uint8_t *)str, len) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::apostrophe: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
double_quote(self, aw, ac, text)
    pdfmake_content_t *self
    double aw
    double ac
    SV *text
    PREINIT:
        STRLEN len;
        const char *str;
    CODE:
        str = SvPV(text, len);
        if (pdfmake_text_quote(self, aw, ac, (const uint8_t *)str, len) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::double_quote: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

#
# XObject Operators
#

SV *
Do(self, name)
    pdfmake_content_t *self
    const char *name
    CODE:
        if (pdfmake_xobj_Do(self, name) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::Do: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

#
# Shading Operators
#

SV *
sh(self, name)
    pdfmake_content_t *self
    const char *name
    CODE:
        if (pdfmake_sh(self, name) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::sh: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

#
# Marked Content Operators
#

SV *
BMC(self, tag)
    pdfmake_content_t *self
    const char *tag
    CODE:
        if (pdfmake_mc_BMC(self, tag) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::BMC: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
EMC(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_mc_EMC(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::EMC: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

#
# Compatibility Operators
#

SV *
BX(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_compat_BX(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::BX: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
EX(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_compat_EX(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::EX: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

#
# Image placement: q cm /Name Do Q
#

SV *
image(self, name, x, y, width, height)
    pdfmake_content_t *self
    const char *name
    double x
    double y
    double width
    double height
    CODE:
        if (pdfmake_gs_q(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::image: q failed");
        if (pdfmake_gs_cm(self, width, 0, 0, height, x, y) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::image: cm failed");
        if (pdfmake_xobj_Do(self, name) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::image: Do failed");
        if (pdfmake_gs_Q(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::image: Q failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

#
# Layer (OCG) operators
#

SV *
begin_layer(self, res_name)
    pdfmake_content_t *self
    const char *res_name
    CODE:
        if (pdfmake_content_begin_ocg(self, res_name) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::begin_layer: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
end_layer(self)
    pdfmake_content_t *self
    CODE:
        if (pdfmake_content_end_ocg(self) != PDFMAKE_OK)
            croak("PDF::Make::Canvas::end_layer: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

BOOT:
{
    /* Canvas dispatch table IDs */
    enum {
        COP_q, COP_Q, COP_BT, COP_ET,
        COP_S, COP_s, COP_f, COP_f_star, COP_B, COP_B_star,
        COP_b, COP_b_star, COP_n, COP_h,
        COP_W, COP_W_star, COP_BX, COP_EX, COP_EMC, COP_T_star,
        COP_w, COP_J, COP_j, COP_M, COP_i,
        COP_G, COP_g, COP_TL, COP_Tr, COP_Ts, COP_Tc, COP_Tw, COP_Tz,
        COP_Tj, COP_ri, COP_gs, COP_CS, COP_cs, COP_sh, COP_Do, COP_BMC,
        COP_m, COP_l, COP_Td, COP_TD, COP_Tf,
        COP_RG, COP_rg, COP_v, COP_y,
        COP_re, COP_K, COP_k,
        COP_c, COP_cm, COP_Tm,
        COP_end_layer, COP_begin_layer, COP_apostrophe,
        COP_COUNT
    };

    static pdfmake_chain_entry_t canvas_dispatch[COP_COUNT] = {
        [COP_q]  = { (void*)pdfmake_gs_q,  0, {} },
        [COP_Q]  = { (void*)pdfmake_gs_Q,  0, {} },
        [COP_BT] = { (void*)pdfmake_text_BT, 0, {} },
        [COP_ET] = { (void*)pdfmake_text_ET, 0, {} },
        [COP_S]  = { (void*)pdfmake_paint_S, 0, {} },
        [COP_s]  = { (void*)pdfmake_paint_s, 0, {} },
        [COP_f]  = { (void*)pdfmake_paint_f, 0, {} },
        [COP_f_star] = { (void*)pdfmake_paint_f_star, 0, {} },
        [COP_B]  = { (void*)pdfmake_paint_B, 0, {} },
        [COP_B_star] = { (void*)pdfmake_paint_B_star, 0, {} },
        [COP_b]  = { (void*)pdfmake_paint_b, 0, {} },
        [COP_b_star] = { (void*)pdfmake_paint_b_star, 0, {} },
        [COP_n]  = { (void*)pdfmake_paint_n, 0, {} },
        [COP_h]  = { (void*)pdfmake_path_h, 0, {} },
        [COP_W]  = { (void*)pdfmake_clip_W, 0, {} },
        [COP_W_star] = { (void*)pdfmake_clip_W_star, 0, {} },
        [COP_BX] = { (void*)pdfmake_compat_BX, 0, {} },
        [COP_EX] = { (void*)pdfmake_compat_EX, 0, {} },
        [COP_EMC] = { (void*)pdfmake_mc_EMC, 0, {} },
        [COP_T_star] = { (void*)pdfmake_text_Tstar, 0, {} },
        [COP_w]  = { (void*)pdfmake_gs_w,    1, {PDFMAKE_ARG_DOUBLE} },
        [COP_J]  = { (void*)pdfmake_gs_J,    1, {PDFMAKE_ARG_INT} },
        [COP_j]  = { (void*)pdfmake_gs_j,    1, {PDFMAKE_ARG_INT} },
        [COP_M]  = { (void*)pdfmake_gs_M,    1, {PDFMAKE_ARG_DOUBLE} },
        [COP_i]  = { (void*)pdfmake_gs_i,    1, {PDFMAKE_ARG_DOUBLE} },
        [COP_G]  = { (void*)pdfmake_color_G, 1, {PDFMAKE_ARG_DOUBLE} },
        [COP_g]  = { (void*)pdfmake_color_g, 1, {PDFMAKE_ARG_DOUBLE} },
        [COP_TL] = { (void*)pdfmake_text_TL, 1, {PDFMAKE_ARG_DOUBLE} },
        [COP_Tr] = { (void*)pdfmake_text_Tr, 1, {PDFMAKE_ARG_INT} },
        [COP_Ts] = { (void*)pdfmake_text_Ts, 1, {PDFMAKE_ARG_DOUBLE} },
        [COP_Tc] = { (void*)pdfmake_text_Tc, 1, {PDFMAKE_ARG_DOUBLE} },
        [COP_Tw] = { (void*)pdfmake_text_Tw, 1, {PDFMAKE_ARG_DOUBLE} },
        [COP_Tz] = { (void*)pdfmake_text_Tz, 1, {PDFMAKE_ARG_DOUBLE} },
        [COP_Tj] = { (void*)pdfmake_text_Tj_cstr, 1, {PDFMAKE_ARG_STRING} },
        [COP_ri] = { (void*)pdfmake_gs_ri,   1, {PDFMAKE_ARG_STRING} },
        [COP_gs] = { (void*)pdfmake_gs_gs,   1, {PDFMAKE_ARG_STRING} },
        [COP_CS] = { (void*)pdfmake_color_CS, 1, {PDFMAKE_ARG_STRING} },
        [COP_cs] = { (void*)pdfmake_color_cs, 1, {PDFMAKE_ARG_STRING} },
        [COP_sh] = { (void*)pdfmake_sh,      1, {PDFMAKE_ARG_STRING} },
        [COP_Do] = { (void*)pdfmake_xobj_Do, 1, {PDFMAKE_ARG_STRING} },
        [COP_BMC] = { (void*)pdfmake_mc_BMC, 1, {PDFMAKE_ARG_STRING} },
        [COP_m]  = { (void*)pdfmake_path_m,  2, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_l]  = { (void*)pdfmake_path_l,  2, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_Td] = { (void*)pdfmake_text_Td, 2, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_TD] = { (void*)pdfmake_text_TD, 2, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_Tf] = { (void*)pdfmake_text_Tf, 2, {PDFMAKE_ARG_STRING, PDFMAKE_ARG_DOUBLE} },
        [COP_RG] = { (void*)pdfmake_color_RG, 3, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_rg] = { (void*)pdfmake_color_rg, 3, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_v]  = { (void*)pdfmake_path_v,  3, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_y]  = { (void*)pdfmake_path_y,  3, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_re] = { (void*)pdfmake_path_re, 4, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_K]  = { (void*)pdfmake_color_K, 4, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_k]  = { (void*)pdfmake_color_k, 4, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_c]  = { (void*)pdfmake_path_c,  6, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_cm] = { (void*)pdfmake_gs_cm,   6, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_Tm] = { (void*)pdfmake_text_Tm, 6, {PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE, PDFMAKE_ARG_DOUBLE} },
        [COP_end_layer] = { (void*)pdfmake_content_end_ocg, 0, {} },
        [COP_begin_layer] = { (void*)pdfmake_content_begin_ocg, 1, {PDFMAKE_ARG_STRING} },
        [COP_apostrophe] = { (void*)pdfmake_text_Tj_cstr, 1, {PDFMAKE_ARG_STRING} },
    };

    /* Register dispatch table */
    int canvas_table_id = pdfmake_chain_table_count++;
    pdfmake_chain_tables[canvas_table_id] = canvas_dispatch;

    HV *stash = gv_stashpv("PDF::Make::Canvas", GV_ADD);
    struct { const char *name; int idx; } methods[] = {
        /* Nullary */
        {"q", COP_q}, {"Q", COP_Q}, {"BT", COP_BT}, {"ET", COP_ET},
        {"S", COP_S}, {"s", COP_s}, {"f", COP_f}, {"f_star", COP_f_star},
        {"B", COP_B}, {"B_star", COP_B_star}, {"b", COP_b}, {"b_star", COP_b_star},
        {"n", COP_n}, {"h", COP_h}, {"W", COP_W}, {"W_star", COP_W_star},
        {"BX", COP_BX}, {"EX", COP_EX}, {"EMC", COP_EMC}, {"T_star", COP_T_star},
        /* 1-arg double */
        {"w", COP_w}, {"J", COP_J}, {"j", COP_j}, {"M", COP_M}, {"i", COP_i},
        {"G", COP_G}, {"g", COP_g}, {"TL", COP_TL}, {"Tr", COP_Tr},
        {"Ts", COP_Ts}, {"Tc", COP_Tc}, {"Tw", COP_Tw}, {"Tz", COP_Tz},
        /* 1-arg string */
        {"Tj", COP_Tj}, {"ri", COP_ri}, {"gs", COP_gs},
        {"CS", COP_CS}, {"cs", COP_cs}, {"sh", COP_sh}, {"Do", COP_Do},
        {"BMC", COP_BMC},
        /* 2-arg double */
        {"m", COP_m}, {"l", COP_l}, {"Td", COP_Td}, {"TD", COP_TD},
        /* string + double */
        {"Tf", COP_Tf},
        /* 3-arg double */
        {"RG", COP_RG}, {"rg", COP_rg}, {"v", COP_v}, {"y", COP_y},
        /* 4-arg double */
        {"re", COP_re}, {"K", COP_K}, {"k", COP_k},
        /* 6-arg double */
        {"c", COP_c}, {"cm", COP_cm}, {"Tm", COP_Tm},
        /* Additional */
        {"end_layer", COP_end_layer}, {"begin_layer", COP_begin_layer},
        {"apostrophe", COP_apostrophe},
        {NULL, 0}
    };
    int ci;
    for (ci = 0; methods[ci].name; ci++) {
        PDFMAKE_REGISTER_CHAIN(stash, methods[ci].name, canvas_table_id, methods[ci].idx);
    }
}

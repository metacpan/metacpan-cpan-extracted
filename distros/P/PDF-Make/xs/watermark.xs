##############################################################################
# Watermark XS bindings
##############################################################################

MODULE = PDF::Make  PACKAGE = PDF::Make::Watermark
PROTOTYPES: ENABLE

pdfmake_watermark_t *
text(class, text_sv, ...)
    const char *class
    SV *text_sv
    PREINIT:
        pdfmake_watermark_opts_t opts;
        const char *text;
        int i;
    CODE:
        PERL_UNUSED_VAR(class);
        if (!SvOK(text_sv) || SvCUR(text_sv) == 0)
            croak("Text required");

        text = SvPV_nolen(text_sv);
        if (!text || !*text)
            croak("Text required");

        pdfmake_watermark_opts_init(&opts);

        for (i = 2; i < items; i += 2) {
            const char *key;
            SV *val;
            const char *pos;

            if (i + 1 >= items) break;
            key = SvPV_nolen(ST(i));
            val = ST(i + 1);

            if (strEQ(key, "position")) {
                if (!SvOK(val)) {
                    opts.position = PDFMAKE_WM_POS_CENTER;
                } else if (SvIOK(val) || SvNOK(val)) {
                    opts.position = (pdfmake_wm_position_t)SvIV(val);
                } else {
                    pos = SvPV_nolen(val);
                    if (strEQ(pos, "center")) opts.position = PDFMAKE_WM_POS_CENTER;
                    else if (strEQ(pos, "diagonal")) opts.position = PDFMAKE_WM_POS_DIAGONAL;
                    else if (strEQ(pos, "tile")) opts.position = PDFMAKE_WM_POS_TILE;
                    else if (strEQ(pos, "custom")) opts.position = PDFMAKE_WM_POS_CUSTOM;
                    else if (strEQ(pos, "top_left")) opts.position = PDFMAKE_WM_POS_TOP_LEFT;
                    else if (strEQ(pos, "top_center")) opts.position = PDFMAKE_WM_POS_TOP_CENTER;
                    else if (strEQ(pos, "top_right")) opts.position = PDFMAKE_WM_POS_TOP_RIGHT;
                    else if (strEQ(pos, "bottom_left")) opts.position = PDFMAKE_WM_POS_BOTTOM_LEFT;
                    else if (strEQ(pos, "bottom_center")) opts.position = PDFMAKE_WM_POS_BOTTOM_CENTER;
                    else if (strEQ(pos, "bottom_right")) opts.position = PDFMAKE_WM_POS_BOTTOM_RIGHT;
                    else if (strEQ(pos, "left_center")) opts.position = PDFMAKE_WM_POS_LEFT_CENTER;
                    else if (strEQ(pos, "right_center")) opts.position = PDFMAKE_WM_POS_RIGHT_CENTER;
                    else croak("Unknown position: %s", pos);
                }
            }
            else if (strEQ(key, "opacity")) {
                opts.opacity = SvNV(val);
            }
            else if (strEQ(key, "rotation")) {
                opts.rotation = SvNV(val);
            }
            else if (strEQ(key, "scale")) {
                opts.scale = SvNV(val);
            }
            else if (strEQ(key, "x_offset")) {
                opts.x_offset = SvNV(val);
            }
            else if (strEQ(key, "y_offset")) {
                opts.y_offset = SvNV(val);
            }
            else if (strEQ(key, "overlay")) {
                opts.as_overlay = SvIV(val);
            }
            else if (strEQ(key, "font")) {
                opts.font_name = SvPV_nolen(val);
            }
            else if (strEQ(key, "size")) {
                opts.font_size = SvNV(val);
            }
            else if (strEQ(key, "color")) {
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    AV *av = (AV*)SvRV(val);
                    if (av_len(av) >= 2) {
                        opts.color[0] = SvNV(*av_fetch(av, 0, 0));
                        opts.color[1] = SvNV(*av_fetch(av, 1, 0));
                        opts.color[2] = SvNV(*av_fetch(av, 2, 0));
                    }
                }
            }
            else if (strEQ(key, "tile_spacing_x")) {
                opts.tile_spacing_x = SvNV(val);
            }
            else if (strEQ(key, "tile_spacing_y")) {
                opts.tile_spacing_y = SvNV(val);
            }
        }

        RETVAL = pdfmake_watermark_text(NULL, text, &opts);
        if (!RETVAL)
            croak("PDF::Make::Watermark: failed to create text watermark");
    OUTPUT:
        RETVAL

pdfmake_watermark_t *
image(class, image_obj, ...)
    const char *class
    UV image_obj
    PREINIT:
        pdfmake_watermark_opts_t opts;
        int i;
        double width = 0.0;
        double height = 0.0;
        int have_width = 0;
        int have_height = 0;
    CODE:
        PERL_UNUSED_VAR(class);
        if (!image_obj)
            croak("Image object required");

        pdfmake_watermark_opts_init(&opts);

        for (i = 2; i < items; i += 2) {
            const char *key;
            SV *val;
            const char *pos;

            if (i + 1 >= items) break;
            key = SvPV_nolen(ST(i));
            val = ST(i + 1);

            if (strEQ(key, "width")) {
                width = SvNV(val);
                have_width = 1;
            }
            else if (strEQ(key, "height")) {
                height = SvNV(val);
                have_height = 1;
            }
            else if (strEQ(key, "position")) {
                if (!SvOK(val)) {
                    opts.position = PDFMAKE_WM_POS_CENTER;
                } else if (SvIOK(val) || SvNOK(val)) {
                    opts.position = (pdfmake_wm_position_t)SvIV(val);
                } else {
                    pos = SvPV_nolen(val);
                    if (strEQ(pos, "center")) opts.position = PDFMAKE_WM_POS_CENTER;
                    else if (strEQ(pos, "diagonal")) opts.position = PDFMAKE_WM_POS_DIAGONAL;
                    else if (strEQ(pos, "tile")) opts.position = PDFMAKE_WM_POS_TILE;
                    else if (strEQ(pos, "custom")) opts.position = PDFMAKE_WM_POS_CUSTOM;
                    else if (strEQ(pos, "top_left")) opts.position = PDFMAKE_WM_POS_TOP_LEFT;
                    else if (strEQ(pos, "top_center")) opts.position = PDFMAKE_WM_POS_TOP_CENTER;
                    else if (strEQ(pos, "top_right")) opts.position = PDFMAKE_WM_POS_TOP_RIGHT;
                    else if (strEQ(pos, "bottom_left")) opts.position = PDFMAKE_WM_POS_BOTTOM_LEFT;
                    else if (strEQ(pos, "bottom_center")) opts.position = PDFMAKE_WM_POS_BOTTOM_CENTER;
                    else if (strEQ(pos, "bottom_right")) opts.position = PDFMAKE_WM_POS_BOTTOM_RIGHT;
                    else if (strEQ(pos, "left_center")) opts.position = PDFMAKE_WM_POS_LEFT_CENTER;
                    else if (strEQ(pos, "right_center")) opts.position = PDFMAKE_WM_POS_RIGHT_CENTER;
                    else croak("Unknown position: %s", pos);
                }
            }
            else if (strEQ(key, "opacity")) {
                opts.opacity = SvNV(val);
            }
            else if (strEQ(key, "rotation")) {
                opts.rotation = SvNV(val);
            }
            else if (strEQ(key, "scale")) {
                opts.scale = SvNV(val);
            }
            else if (strEQ(key, "x_offset")) {
                opts.x_offset = SvNV(val);
            }
            else if (strEQ(key, "y_offset")) {
                opts.y_offset = SvNV(val);
            }
            else if (strEQ(key, "overlay")) {
                opts.as_overlay = SvIV(val);
            }
            else if (strEQ(key, "tile_spacing_x")) {
                opts.tile_spacing_x = SvNV(val);
            }
            else if (strEQ(key, "tile_spacing_y")) {
                opts.tile_spacing_y = SvNV(val);
            }
        }

        if (!have_width)
            croak("Width required for image watermark");
        if (!have_height)
            croak("Height required for image watermark");

        RETVAL = pdfmake_watermark_image(NULL, (uint32_t)image_obj, width, height, &opts);
        if (!RETVAL)
            croak("PDF::Make::Watermark: failed to create image watermark");
    OUTPUT:
        RETVAL

pdfmake_watermark_t *
_new_text(class, doc, text, ...)
    const char *class
    SV *doc
    const char *text
    PREINIT:
        pdfmake_watermark_opts_t opts;
        int i;
    CODE:
        PERL_UNUSED_VAR(doc);
        PERL_UNUSED_VAR(class);
        pdfmake_watermark_opts_init(&opts);
        
        /* Parse optional hash arguments */
        for (i = 3; i < items; i += 2) {
            if (i + 1 >= items) break;
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            
            if (strEQ(key, "position")) {
                opts.position = (pdfmake_wm_position_t)SvIV(val);
            }
            else if (strEQ(key, "opacity")) {
                opts.opacity = SvNV(val);
            }
            else if (strEQ(key, "rotation")) {
                opts.rotation = SvNV(val);
            }
            else if (strEQ(key, "scale")) {
                opts.scale = SvNV(val);
            }
            else if (strEQ(key, "x_offset")) {
                opts.x_offset = SvNV(val);
            }
            else if (strEQ(key, "y_offset")) {
                opts.y_offset = SvNV(val);
            }
            else if (strEQ(key, "overlay")) {
                opts.as_overlay = SvIV(val);
            }
            else if (strEQ(key, "font")) {
                opts.font_name = SvPV_nolen(val);
            }
            else if (strEQ(key, "size")) {
                opts.font_size = SvNV(val);
            }
            else if (strEQ(key, "color")) {
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    AV *av = (AV*)SvRV(val);
                    if (av_len(av) >= 2) {
                        opts.color[0] = SvNV(*av_fetch(av, 0, 0));
                        opts.color[1] = SvNV(*av_fetch(av, 1, 0));
                        opts.color[2] = SvNV(*av_fetch(av, 2, 0));
                    }
                }
            }
            else if (strEQ(key, "tile_spacing_x")) {
                opts.tile_spacing_x = SvNV(val);
            }
            else if (strEQ(key, "tile_spacing_y")) {
                opts.tile_spacing_y = SvNV(val);
            }
        }
        
        RETVAL = pdfmake_watermark_text(NULL, text, &opts);
        if (!RETVAL)
            croak("PDF::Make::Watermark: failed to create text watermark");
    OUTPUT:
        RETVAL

pdfmake_watermark_t *
_new_image(class, doc, image_obj, width, height, ...)
    const char *class
    SV *doc
    UV image_obj
    double width
    double height
    PREINIT:
        pdfmake_watermark_opts_t opts;
        int i;
    CODE:
        PERL_UNUSED_VAR(doc);
        PERL_UNUSED_VAR(class);
        pdfmake_watermark_opts_init(&opts);
        
        /* Parse optional hash arguments */
        for (i = 5; i < items; i += 2) {
            if (i + 1 >= items) break;
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            
            if (strEQ(key, "position")) {
                opts.position = (pdfmake_wm_position_t)SvIV(val);
            }
            else if (strEQ(key, "opacity")) {
                opts.opacity = SvNV(val);
            }
            else if (strEQ(key, "rotation")) {
                opts.rotation = SvNV(val);
            }
            else if (strEQ(key, "scale")) {
                opts.scale = SvNV(val);
            }
            else if (strEQ(key, "x_offset")) {
                opts.x_offset = SvNV(val);
            }
            else if (strEQ(key, "y_offset")) {
                opts.y_offset = SvNV(val);
            }
            else if (strEQ(key, "overlay")) {
                opts.as_overlay = SvIV(val);
            }
            else if (strEQ(key, "tile_spacing_x")) {
                opts.tile_spacing_x = SvNV(val);
            }
            else if (strEQ(key, "tile_spacing_y")) {
                opts.tile_spacing_y = SvNV(val);
            }
        }
        
        RETVAL = pdfmake_watermark_image(NULL, (uint32_t)image_obj, width, height, &opts);
        if (!RETVAL)
            croak("PDF::Make::Watermark: failed to create image watermark");
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_watermark_t *self
    CODE:
        pdfmake_watermark_free(self);

const char *
type(self)
    pdfmake_watermark_t *self
    CODE:
        RETVAL = (self->type == PDFMAKE_WM_TYPE_TEXT) ? "text" : "image";
    OUTPUT:
        RETVAL

const char *
text_content(self)
    pdfmake_watermark_t *self
    CODE:
        if (self->type == PDFMAKE_WM_TYPE_TEXT)
            RETVAL = self->data.text.text ? self->data.text.text : "";
        else
            RETVAL = "";
    OUTPUT:
        RETVAL

int
position(self)
    pdfmake_watermark_t *self
    CODE:
        RETVAL = self->opts.position;
    OUTPUT:
        RETVAL

double
opacity(self)
    pdfmake_watermark_t *self
    CODE:
        RETVAL = self->opts.opacity;
    OUTPUT:
        RETVAL

double
rotation(self)
    pdfmake_watermark_t *self
    CODE:
        RETVAL = self->opts.rotation;
    OUTPUT:
        RETVAL

double
scale(self)
    pdfmake_watermark_t *self
    CODE:
        RETVAL = self->opts.scale;
    OUTPUT:
        RETVAL

double
x_offset(self)
    pdfmake_watermark_t *self
    CODE:
        RETVAL = self->opts.x_offset;
    OUTPUT:
        RETVAL

double
y_offset(self)
    pdfmake_watermark_t *self
    CODE:
        RETVAL = self->opts.y_offset;
    OUTPUT:
        RETVAL

int
overlay(self)
    pdfmake_watermark_t *self
    CODE:
        RETVAL = self->opts.as_overlay;
    OUTPUT:
        RETVAL

const char *
font(self)
    pdfmake_watermark_t *self
    CODE:
        RETVAL = self->opts.font_name ? self->opts.font_name : "Helvetica-Bold";
    OUTPUT:
        RETVAL

double
size(self)
    pdfmake_watermark_t *self
    CODE:
        RETVAL = self->opts.font_size;
    OUTPUT:
        RETVAL

SV *
color(self)
    pdfmake_watermark_t *self
    PREINIT:
        AV *av;
    CODE:
        av = newAV();
        av_push(av, newSVnv(self->opts.color[0]));
        av_push(av, newSVnv(self->opts.color[1]));
        av_push(av, newSVnv(self->opts.color[2]));
        RETVAL = newRV_noinc((SV*)av);
    OUTPUT:
        RETVAL

double
width(self)
    pdfmake_watermark_t *self
    CODE:
        if (self->type == PDFMAKE_WM_TYPE_IMAGE)
            RETVAL = self->data.image.width;
        else
            RETVAL = self->data.text.text_width;
    OUTPUT:
        RETVAL

double
height(self)
    pdfmake_watermark_t *self
    CODE:
        if (self->type == PDFMAKE_WM_TYPE_IMAGE)
            RETVAL = self->data.image.height;
        else
            RETVAL = self->data.text.text_height;
    OUTPUT:
        RETVAL

double
tile_spacing_x(self)
    pdfmake_watermark_t *self
    CODE:
        RETVAL = self->opts.tile_spacing_x;
    OUTPUT:
        RETVAL

double
tile_spacing_y(self)
    pdfmake_watermark_t *self
    CODE:
        RETVAL = self->opts.tile_spacing_y;
    OUTPUT:
        RETVAL

UV
image_obj(self)
    pdfmake_watermark_t *self
    CODE:
        if (self->type == PDFMAKE_WM_TYPE_IMAGE)
            RETVAL = (UV)self->data.image.image_obj;
        else
            RETVAL = 0;
    OUTPUT:
        RETVAL

##############################################################################
# Stamp XS bindings
##############################################################################

MODULE = PDF::Make  PACKAGE = PDF::Make::Stamp
PROTOTYPES: ENABLE

pdfmake_stamp_t *
text(class, format_sv, ...)
    const char *class
    SV *format_sv
    PREINIT:
        pdfmake_stamp_opts_t opts;
        const char *format;
        int i;
    CODE:
        PERL_UNUSED_VAR(class);
        if (!SvOK(format_sv))
            croak("Format string required");

        format = SvPV_nolen(format_sv);
        pdfmake_stamp_opts_init(&opts);

        for (i = 2; i < items; i += 2) {
            const char *key;
            SV *val;
            const char *pos;

            if (i + 1 >= items) break;
            key = SvPV_nolen(ST(i));
            val = ST(i + 1);

            if (strEQ(key, "position")) {
                if (!SvOK(val)) {
                    opts.position = PDFMAKE_WM_POS_BOTTOM_CENTER;
                } else if (SvIOK(val) || SvNOK(val)) {
                    opts.position = (pdfmake_stamp_position_t)SvIV(val);
                } else {
                    pos = SvPV_nolen(val);
                    if (strEQ(pos, "center")) opts.position = PDFMAKE_WM_POS_CENTER;
                    else if (strEQ(pos, "diagonal")) opts.position = PDFMAKE_WM_POS_DIAGONAL;
                    else if (strEQ(pos, "tile")) opts.position = PDFMAKE_WM_POS_TILE;
                    else if (strEQ(pos, "custom")) opts.position = PDFMAKE_WM_POS_CUSTOM;
                    else if (strEQ(pos, "top_left")) opts.position = PDFMAKE_WM_POS_TOP_LEFT;
                    else if (strEQ(pos, "top_center")) opts.position = PDFMAKE_WM_POS_TOP_CENTER;
                    else if (strEQ(pos, "top_right")) opts.position = PDFMAKE_WM_POS_TOP_RIGHT;
                    else if (strEQ(pos, "bottom_left")) opts.position = PDFMAKE_WM_POS_BOTTOM_LEFT;
                    else if (strEQ(pos, "bottom_center")) opts.position = PDFMAKE_WM_POS_BOTTOM_CENTER;
                    else if (strEQ(pos, "bottom_right")) opts.position = PDFMAKE_WM_POS_BOTTOM_RIGHT;
                    else if (strEQ(pos, "left_center")) opts.position = PDFMAKE_WM_POS_LEFT_CENTER;
                    else if (strEQ(pos, "right_center")) opts.position = PDFMAKE_WM_POS_RIGHT_CENTER;
                    else croak("Unknown position: %s", pos);
                }
            }
            else if (strEQ(key, "margin_x") || strEQ(key, "margin")) {
                opts.margin_x = SvNV(val);
            }
            else if (strEQ(key, "margin_y")) {
                opts.margin_y = SvNV(val);
            }
            else if (strEQ(key, "font")) {
                opts.font_name = SvPV_nolen(val);
            }
            else if (strEQ(key, "size")) {
                opts.font_size = SvNV(val);
            }
            else if (strEQ(key, "color")) {
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    AV *av = (AV*)SvRV(val);
                    if (av_len(av) >= 2) {
                        opts.color[0] = SvNV(*av_fetch(av, 0, 0));
                        opts.color[1] = SvNV(*av_fetch(av, 1, 0));
                        opts.color[2] = SvNV(*av_fetch(av, 2, 0));
                    }
                }
            }
        }

        RETVAL = pdfmake_stamp_text(NULL, format, &opts);
        if (!RETVAL)
            croak("PDF::Make::Stamp: failed to create text stamp");
    OUTPUT:
        RETVAL

pdfmake_stamp_t *
bates(class, ...)
    const char *class
    PREINIT:
        pdfmake_stamp_opts_t opts;
        const char *prefix = "";
        const char *suffix = "";
        int start = 1;
        int digits = 6;
        int i;
    CODE:
        PERL_UNUSED_VAR(class);
        pdfmake_stamp_opts_init(&opts);

        for (i = 1; i < items; i += 2) {
            const char *key;
            SV *val;
            const char *pos;

            if (i + 1 >= items) break;
            key = SvPV_nolen(ST(i));
            val = ST(i + 1);

            if (strEQ(key, "prefix")) {
                prefix = SvPV_nolen(val);
            }
            else if (strEQ(key, "suffix")) {
                suffix = SvPV_nolen(val);
            }
            else if (strEQ(key, "start")) {
                start = SvIV(val);
            }
            else if (strEQ(key, "digits")) {
                digits = SvIV(val);
            }
            else if (strEQ(key, "position")) {
                if (!SvOK(val)) {
                    opts.position = PDFMAKE_WM_POS_BOTTOM_RIGHT;
                } else if (SvIOK(val) || SvNOK(val)) {
                    opts.position = (pdfmake_stamp_position_t)SvIV(val);
                } else {
                    pos = SvPV_nolen(val);
                    if (strEQ(pos, "center")) opts.position = PDFMAKE_WM_POS_CENTER;
                    else if (strEQ(pos, "diagonal")) opts.position = PDFMAKE_WM_POS_DIAGONAL;
                    else if (strEQ(pos, "tile")) opts.position = PDFMAKE_WM_POS_TILE;
                    else if (strEQ(pos, "custom")) opts.position = PDFMAKE_WM_POS_CUSTOM;
                    else if (strEQ(pos, "top_left")) opts.position = PDFMAKE_WM_POS_TOP_LEFT;
                    else if (strEQ(pos, "top_center")) opts.position = PDFMAKE_WM_POS_TOP_CENTER;
                    else if (strEQ(pos, "top_right")) opts.position = PDFMAKE_WM_POS_TOP_RIGHT;
                    else if (strEQ(pos, "bottom_left")) opts.position = PDFMAKE_WM_POS_BOTTOM_LEFT;
                    else if (strEQ(pos, "bottom_center")) opts.position = PDFMAKE_WM_POS_BOTTOM_CENTER;
                    else if (strEQ(pos, "bottom_right")) opts.position = PDFMAKE_WM_POS_BOTTOM_RIGHT;
                    else if (strEQ(pos, "left_center")) opts.position = PDFMAKE_WM_POS_LEFT_CENTER;
                    else if (strEQ(pos, "right_center")) opts.position = PDFMAKE_WM_POS_RIGHT_CENTER;
                    else croak("Unknown position: %s", pos);
                }
            }
            else if (strEQ(key, "margin_x") || strEQ(key, "margin")) {
                opts.margin_x = SvNV(val);
            }
            else if (strEQ(key, "margin_y")) {
                opts.margin_y = SvNV(val);
            }
            else if (strEQ(key, "font")) {
                opts.font_name = SvPV_nolen(val);
            }
            else if (strEQ(key, "size")) {
                opts.font_size = SvNV(val);
            }
            else if (strEQ(key, "color")) {
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    AV *av = (AV*)SvRV(val);
                    if (av_len(av) >= 2) {
                        opts.color[0] = SvNV(*av_fetch(av, 0, 0));
                        opts.color[1] = SvNV(*av_fetch(av, 1, 0));
                        opts.color[2] = SvNV(*av_fetch(av, 2, 0));
                    }
                }
            }
        }

        RETVAL = pdfmake_stamp_bates(NULL, prefix, start, digits, suffix, &opts);
        if (!RETVAL)
            croak("PDF::Make::Stamp: failed to create Bates stamp");
    OUTPUT:
        RETVAL

pdfmake_stamp_t *
_new_text(class, doc, format, ...)
    const char *class
    SV *doc
    const char *format
    PREINIT:
        pdfmake_stamp_opts_t opts;
        int i;
    CODE:
        PERL_UNUSED_VAR(doc);
        PERL_UNUSED_VAR(class);
        pdfmake_stamp_opts_init(&opts);
        
        /* Parse optional hash arguments */
        for (i = 3; i < items; i += 2) {
            if (i + 1 >= items) break;
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            
            if (strEQ(key, "position")) {
                opts.position = (pdfmake_stamp_position_t)SvIV(val);
            }
            else if (strEQ(key, "margin_x") || strEQ(key, "margin")) {
                opts.margin_x = SvNV(val);
            }
            else if (strEQ(key, "margin_y")) {
                opts.margin_y = SvNV(val);
            }
            else if (strEQ(key, "font")) {
                opts.font_name = SvPV_nolen(val);
            }
            else if (strEQ(key, "size")) {
                opts.font_size = SvNV(val);
            }
            else if (strEQ(key, "color")) {
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    AV *av = (AV*)SvRV(val);
                    if (av_len(av) >= 2) {
                        opts.color[0] = SvNV(*av_fetch(av, 0, 0));
                        opts.color[1] = SvNV(*av_fetch(av, 1, 0));
                        opts.color[2] = SvNV(*av_fetch(av, 2, 0));
                    }
                }
            }
        }
        
        /* If margin was set but margin_y wasn't explicitly set, use same value */
        /* This handles the common case of margin => 36 setting both */
        
        RETVAL = pdfmake_stamp_text(NULL, format, &opts);
        if (!RETVAL)
            croak("PDF::Make::Stamp: failed to create text stamp");
    OUTPUT:
        RETVAL

pdfmake_stamp_t *
_new_bates(class, doc, ...)
    const char *class
    SV *doc
    PREINIT:
        pdfmake_stamp_opts_t opts;
        const char *prefix = "";
        const char *suffix = "";
        int start = 1;
        int digits = 6;
        int i;
    CODE:
        PERL_UNUSED_VAR(doc);
        PERL_UNUSED_VAR(class);
        pdfmake_stamp_opts_init(&opts);
        
        /* Parse optional hash arguments */
        for (i = 2; i < items; i += 2) {
            if (i + 1 >= items) break;
            const char *key = SvPV_nolen(ST(i));
            SV *val = ST(i + 1);
            
            if (strEQ(key, "prefix")) {
                prefix = SvPV_nolen(val);
            }
            else if (strEQ(key, "suffix")) {
                suffix = SvPV_nolen(val);
            }
            else if (strEQ(key, "start")) {
                start = SvIV(val);
            }
            else if (strEQ(key, "digits")) {
                digits = SvIV(val);
            }
            else if (strEQ(key, "position")) {
                opts.position = (pdfmake_stamp_position_t)SvIV(val);
            }
            else if (strEQ(key, "margin_x") || strEQ(key, "margin")) {
                opts.margin_x = SvNV(val);
            }
            else if (strEQ(key, "margin_y")) {
                opts.margin_y = SvNV(val);
            }
            else if (strEQ(key, "font")) {
                opts.font_name = SvPV_nolen(val);
            }
            else if (strEQ(key, "size")) {
                opts.font_size = SvNV(val);
            }
            else if (strEQ(key, "color")) {
                if (SvROK(val) && SvTYPE(SvRV(val)) == SVt_PVAV) {
                    AV *av = (AV*)SvRV(val);
                    if (av_len(av) >= 2) {
                        opts.color[0] = SvNV(*av_fetch(av, 0, 0));
                        opts.color[1] = SvNV(*av_fetch(av, 1, 0));
                        opts.color[2] = SvNV(*av_fetch(av, 2, 0));
                    }
                }
            }
        }
        
        RETVAL = pdfmake_stamp_bates(NULL, prefix, start, digits, suffix, &opts);
        if (!RETVAL)
            croak("PDF::Make::Stamp: failed to create Bates stamp");
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_stamp_t *self
    CODE:
        pdfmake_stamp_free(self);

const char *
type(self)
    pdfmake_stamp_t *self
    CODE:
        RETVAL = (self->type == PDFMAKE_WM_STAMP_TEXT) ? "text" : "bates";
    OUTPUT:
        RETVAL

const char *
type_name(self)
    pdfmake_stamp_t *self
    CODE:
        RETVAL = (self->type == PDFMAKE_WM_STAMP_TEXT) ? "text" : "bates";
    OUTPUT:
        RETVAL

const char *
format(self)
    pdfmake_stamp_t *self
    CODE:
        if (self->type == PDFMAKE_WM_STAMP_TEXT)
            RETVAL = self->data.text.format ? self->data.text.format : "";
        else
            RETVAL = "";
    OUTPUT:
        RETVAL

const char *
prefix(self)
    pdfmake_stamp_t *self
    CODE:
        if (self->type == PDFMAKE_WM_STAMP_BATES)
            RETVAL = self->data.bates.prefix ? self->data.bates.prefix : "";
        else
            RETVAL = "";
    OUTPUT:
        RETVAL

const char *
suffix(self)
    pdfmake_stamp_t *self
    CODE:
        if (self->type == PDFMAKE_WM_STAMP_BATES)
            RETVAL = self->data.bates.suffix ? self->data.bates.suffix : "";
        else
            RETVAL = "";
    OUTPUT:
        RETVAL

int
start(self)
    pdfmake_stamp_t *self
    CODE:
        if (self->type == PDFMAKE_WM_STAMP_BATES)
            RETVAL = self->data.bates.start_number;
        else
            RETVAL = 0;
    OUTPUT:
        RETVAL

int
digits(self)
    pdfmake_stamp_t *self
    CODE:
        if (self->type == PDFMAKE_WM_STAMP_BATES)
            RETVAL = self->data.bates.digits;
        else
            RETVAL = 0;
    OUTPUT:
        RETVAL

int
position(self)
    pdfmake_stamp_t *self
    CODE:
        RETVAL = self->opts.position;
    OUTPUT:
        RETVAL

double
margin_x(self)
    pdfmake_stamp_t *self
    CODE:
        RETVAL = self->opts.margin_x;
    OUTPUT:
        RETVAL

double
margin_y(self)
    pdfmake_stamp_t *self
    CODE:
        RETVAL = self->opts.margin_y;
    OUTPUT:
        RETVAL

const char *
font(self)
    pdfmake_stamp_t *self
    CODE:
        RETVAL = self->opts.font_name ? self->opts.font_name : "Helvetica";
    OUTPUT:
        RETVAL

double
size(self)
    pdfmake_stamp_t *self
    CODE:
        RETVAL = self->opts.font_size;
    OUTPUT:
        RETVAL

SV *
color(self)
    pdfmake_stamp_t *self
    PREINIT:
        AV *av;
    CODE:
        av = newAV();
        av_push(av, newSVnv(self->opts.color[0]));
        av_push(av, newSVnv(self->opts.color[1]));
        av_push(av, newSVnv(self->opts.color[2]));
        RETVAL = newRV_noinc((SV*)av);
    OUTPUT:
        RETVAL

void
reset(self)
    pdfmake_stamp_t *self
    CODE:
        if (self->type == PDFMAKE_WM_STAMP_BATES)
            self->data.bates.current_number = self->data.bates.start_number;

SV *
next_bates(self)
    pdfmake_stamp_t *self
    PREINIT:
        char *text;
    CODE:
        if (self->type != PDFMAKE_WM_STAMP_BATES)
            XSRETURN_UNDEF;
        
        text = pdfmake_stamp_expand_bates(
            self->data.bates.prefix,
            self->data.bates.current_number,
            self->data.bates.digits,
            self->data.bates.suffix
        );
        self->data.bates.current_number++;
        
        if (text) {
            RETVAL = newSVpv(text, 0);
            free(text);
        } else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

SV *
expand(self, page_num, total_pages, ...)
    pdfmake_stamp_t *self
    int page_num
    int total_pages
    PREINIT:
        char *text;
        const char *filename = NULL;
    CODE:
        if (items > 3)
            filename = SvPV_nolen(ST(3));
        
        if (self->type == PDFMAKE_WM_STAMP_BATES) {
            text = pdfmake_stamp_expand_bates(
                self->data.bates.prefix,
                self->data.bates.current_number,
                self->data.bates.digits,
                self->data.bates.suffix
            );
            self->data.bates.current_number++;
        } else {
            text = pdfmake_stamp_expand_format(
                self->data.text.format,
                page_num,
                total_pages,
                filename
            );
        }
        
        if (text) {
            RETVAL = newSVpv(text, 0);
            free(text);
        } else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

##############################################################################
# Document watermark/stamp methods
##############################################################################

MODULE = PDF::Make  PACKAGE = PDF::Make::Document

void
add_watermark(self, wm)
    pdfmake_doc_t *self
    pdfmake_watermark_t *wm
    CODE:
        if (pdfmake_doc_add_watermark(self, wm) != PDFMAKE_OK)
            croak("PDF::Make::Document::add_watermark: failed");

void
apply_stamp(self, stamp)
    pdfmake_doc_t *self
    pdfmake_stamp_t *stamp
    CODE:
        if (pdfmake_doc_add_stamp(self, stamp) != PDFMAKE_OK)
            croak("PDF::Make::Document::apply_stamp: failed");


BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Watermark", GV_ADD);
    PDFMAKE_REGISTER_GETTER(stash, "position",       pdfmake_watermark_t, opts.position,       PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_GETTER(stash, "opacity",        pdfmake_watermark_t, opts.opacity,        PDFMAKE_FIELD_DOUBLE);
    PDFMAKE_REGISTER_GETTER(stash, "rotation",       pdfmake_watermark_t, opts.rotation,       PDFMAKE_FIELD_DOUBLE);
    PDFMAKE_REGISTER_GETTER(stash, "scale",          pdfmake_watermark_t, opts.scale,          PDFMAKE_FIELD_DOUBLE);
    PDFMAKE_REGISTER_GETTER(stash, "x_offset",       pdfmake_watermark_t, opts.x_offset,       PDFMAKE_FIELD_DOUBLE);
    PDFMAKE_REGISTER_GETTER(stash, "y_offset",       pdfmake_watermark_t, opts.y_offset,       PDFMAKE_FIELD_DOUBLE);
    PDFMAKE_REGISTER_GETTER(stash, "overlay",        pdfmake_watermark_t, opts.as_overlay,     PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_GETTER(stash, "font_size",      pdfmake_watermark_t, opts.font_size,      PDFMAKE_FIELD_DOUBLE);
    PDFMAKE_REGISTER_GETTER(stash, "tile_spacing_x", pdfmake_watermark_t, opts.tile_spacing_x, PDFMAKE_FIELD_DOUBLE);
    PDFMAKE_REGISTER_GETTER(stash, "tile_spacing_y", pdfmake_watermark_t, opts.tile_spacing_y, PDFMAKE_FIELD_DOUBLE);
}

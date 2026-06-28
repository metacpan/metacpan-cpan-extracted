MODULE = PDF::Make  PACKAGE = PDF::Make::ImageRender
PROTOTYPES: ENABLE

#
# Decoded Image Management
#

SV *
decode_jpeg(class, bytes_sv)
    char *class
    SV *bytes_sv
    PREINIT:
        STRLEN len;
        const uint8_t *buf;
        pdfmake_decoded_image_t *img = NULL;
        pdfmake_imgr_err_t err;
    CODE:
        PERL_UNUSED_VAR(class);
        buf = (const uint8_t *)SvPV(bytes_sv, len);
        
        err = pdfmake_decode_jpeg_to_image(buf, (size_t)len, &img, NULL);
        if (err != PDFMAKE_IMGR_OK || !img) {
            croak("PDF::Make::ImageRender: failed to decode JPEG (error %d)", err);
        }
        
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "PDF::Make::DecodedImage", (void *)img);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

SV *
from_raw(class, bytes_sv, width, height, colorspace, bits_per_component=8)
    char *class
    SV *bytes_sv
    int width
    int height
    int colorspace
    int bits_per_component
    PREINIT:
        STRLEN len;
        const uint8_t *buf;
        pdfmake_decoded_image_t *img;
        int components;
    CODE:
        PERL_UNUSED_VAR(class);
        buf = (const uint8_t *)SvPV(bytes_sv, len);
        
        /* Determine components from colorspace */
        switch (colorspace) {
            case PDFMAKE_RCS_GRAY:    components = 1; break;
            case PDFMAKE_RCS_RGB:     components = 3; break;
            case PDFMAKE_RCS_CMYK:    components = 4; break;
            case PDFMAKE_RCS_INDEXED: components = 1; break;
            case PDFMAKE_RCS_LAB:     components = 3; break;
            default:                  components = 3; break;
        }
        
        /* Validate data size */
        size_t expected = (size_t)width * height * components;
        if (len < expected) {
            croak("PDF::Make::ImageRender: buffer too small (got %lu, need %lu)",
                  (unsigned long)len, (unsigned long)expected);
        }
        
        img = pdfmake_decoded_image_create(NULL);
        if (!img) {
            croak("PDF::Make::ImageRender: failed to allocate image");
        }
        
        img->width = width;
        img->height = height;
        img->bits_per_component = bits_per_component;
        img->components = components;
        img->colorspace = (pdfmake_render_cs_t)colorspace;
        img->row_stride = width * components;
        img->pixels_len = expected;
        
        /* Copy pixel data */
        img->pixels = malloc(expected);
        if (!img->pixels) {
            free(img);
            croak("PDF::Make::ImageRender: failed to allocate pixels");
        }
        Copy(buf, img->pixels, expected, uint8_t);
        img->owns_data = 1;
        
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "PDF::Make::DecodedImage", (void *)img);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

void
DESTROY(img)
    pdfmake_decoded_image_t *img
    CODE:
        pdfmake_decoded_image_free(img);

MODULE = PDF::Make  PACKAGE = PDF::Make::DecodedImage
PROTOTYPES: ENABLE

#
# Decoded Image Properties
#

int
width(self)
    pdfmake_decoded_image_t *self
    CODE:
        RETVAL = self->width;
    OUTPUT:
        RETVAL

int
height(self)
    pdfmake_decoded_image_t *self
    CODE:
        RETVAL = self->height;
    OUTPUT:
        RETVAL

int
components(self)
    pdfmake_decoded_image_t *self
    CODE:
        RETVAL = self->components;
    OUTPUT:
        RETVAL

int
colorspace(self)
    pdfmake_decoded_image_t *self
    CODE:
        RETVAL = (int)self->colorspace;
    OUTPUT:
        RETVAL

int
bits_per_component(self)
    pdfmake_decoded_image_t *self
    CODE:
        RETVAL = self->bits_per_component;
    OUTPUT:
        RETVAL

int
has_alpha(self)
    pdfmake_decoded_image_t *self
    CODE:
        RETVAL = self->has_alpha;
    OUTPUT:
        RETVAL

#
# Pixel Access
#

SV *
get_pixel(self, x, y)
    pdfmake_decoded_image_t *self
    int x
    int y
    PREINIT:
        uint8_t comp[4];
        AV *av;
        int i;
    CODE:
        if (x < 0 || x >= self->width || y < 0 || y >= self->height) {
            XSRETURN_UNDEF;
        }
        
        pdfmake_decoded_image_get_pixel(self, x, y, comp);
        
        av = newAV();
        for (i = 0; i < self->components; i++) {
            av_push(av, newSViv(comp[i]));
        }
        
        RETVAL = newRV_noinc((SV *)av);
    OUTPUT:
        RETVAL

UV
get_rgba(self, x, y)
    pdfmake_decoded_image_t *self
    int x
    int y
    CODE:
        if (x < 0 || x >= self->width || y < 0 || y >= self->height) {
            RETVAL = 0;
        } else {
            RETVAL = pdfmake_decoded_image_get_rgba(self, x, y);
        }
    OUTPUT:
        RETVAL

UV
get_alpha(self, x, y)
    pdfmake_decoded_image_t *self
    int x
    int y
    CODE:
        RETVAL = pdfmake_decoded_image_get_alpha(self, x, y);
    OUTPUT:
        RETVAL

#
# Color Space Conversion
#

void
to_rgba(self)
    pdfmake_decoded_image_t *self
    PREINIT:
        pdfmake_imgr_err_t err;
    CODE:
        err = pdfmake_decoded_image_to_rgba(self, NULL);
        if (err != PDFMAKE_IMGR_OK) {
            croak("PDF::Make::DecodedImage: to_rgba failed (error %d)", err);
        }

void
expand_indexed(self)
    pdfmake_decoded_image_t *self
    PREINIT:
        pdfmake_imgr_err_t err;
    CODE:
        err = pdfmake_decoded_image_expand_indexed(self, NULL);
        if (err != PDFMAKE_IMGR_OK) {
            croak("PDF::Make::DecodedImage: expand_indexed failed (error %d)", err);
        }

void
apply_decode(self, decode_av)
    pdfmake_decoded_image_t *self
    AV *decode_av
    PREINIT:
        SSize_t i, len;
    CODE:
        len = av_len(decode_av) + 1;
        if (len > 0) {
            self->decode = malloc(len * sizeof(double));
            if (!self->decode) {
                croak("PDF::Make::DecodedImage: malloc failed");
            }
            for (i = 0; i < len; i++) {
                SV **sv = av_fetch(decode_av, i, 0);
                self->decode[i] = sv ? SvNV(*sv) : 0.0;
            }
            self->decode_len = len;
            pdfmake_decoded_image_apply_decode(self);
        }

#
# Scaling
#

SV *
scale(self, new_width, new_height, mode=PDFMAKE_INTERP_BILINEAR)
    pdfmake_decoded_image_t *self
    int new_width
    int new_height
    int mode
    PREINIT:
        pdfmake_decoded_image_t *scaled = NULL;
        pdfmake_imgr_err_t err;
    CODE:
        err = pdfmake_decoded_image_scale(self, new_width, new_height,
            (pdfmake_interp_mode_t)mode, &scaled, NULL);
        if (err != PDFMAKE_IMGR_OK || !scaled) {
            croak("PDF::Make::DecodedImage: scale failed (error %d)", err);
        }
        
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "PDF::Make::DecodedImage", (void *)scaled);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

void
resize(self, new_width, new_height, mode=PDFMAKE_INTERP_BILINEAR)
    pdfmake_decoded_image_t *self
    int new_width
    int new_height
    int mode
    PREINIT:
        pdfmake_imgr_err_t err;
    CODE:
        err = pdfmake_decoded_image_resize(self, new_width, new_height,
            (pdfmake_interp_mode_t)mode, NULL);
        if (err != PDFMAKE_IMGR_OK) {
            croak("PDF::Make::DecodedImage: resize failed (error %d)", err);
        }

#
# Palette for indexed images
#

void
set_palette(self, palette_sv)
    pdfmake_decoded_image_t *self
    SV *palette_sv
    PREINIT:
        STRLEN len;
        const uint8_t *buf;
    CODE:
        buf = (const uint8_t *)SvPV(palette_sv, len);
        if (len % 3 != 0) {
            croak("PDF::Make::DecodedImage: palette must be RGB triplets");
        }
        
        self->palette_entries = len / 3;
        self->palette = malloc(len);
        if (!self->palette) {
            croak("PDF::Make::DecodedImage: malloc failed");
        }
        Copy(buf, self->palette, len, uint8_t);

#
# Alpha channel
#

void
set_alpha(self, alpha_sv)
    pdfmake_decoded_image_t *self
    SV *alpha_sv
    PREINIT:
        STRLEN len;
        const uint8_t *buf;
        size_t expected;
    CODE:
        buf = (const uint8_t *)SvPV(alpha_sv, len);
        expected = (size_t)self->width * self->height;
        
        if (len < expected) {
            croak("PDF::Make::DecodedImage: alpha buffer too small");
        }
        
        if (self->alpha && self->owns_data) {
            free(self->alpha);
        }
        
        self->alpha = malloc(expected);
        if (!self->alpha) {
            croak("PDF::Make::DecodedImage: malloc failed");
        }
        Copy(buf, self->alpha, expected, uint8_t);
        self->alpha_len = expected;
        self->has_alpha = 1;

#
# Get RGBA buffer as bytes
#

SV *
get_rgba_buffer(self)
    pdfmake_decoded_image_t *self
    PREINIT:
        pdfmake_imgr_err_t err;
    CODE:
        /* Ensure RGBA is generated */
        if (!self->rgba) {
            err = pdfmake_decoded_image_to_rgba(self, NULL);
            if (err != PDFMAKE_IMGR_OK) {
                croak("PDF::Make::DecodedImage: to_rgba failed");
            }
        }
        
        RETVAL = newSVpvn((char *)self->rgba, self->rgba_len * sizeof(uint32_t));
    OUTPUT:
        RETVAL

#
# Clone
#

SV *
clone(self)
    pdfmake_decoded_image_t *self
    PREINIT:
        pdfmake_decoded_image_t *cloned;
    CODE:
        cloned = pdfmake_decoded_image_clone(self, NULL);
        if (!cloned) {
            croak("PDF::Make::DecodedImage: clone failed");
        }
        
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "PDF::Make::DecodedImage", (void *)cloned);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_decoded_image_t *self
    CODE:
        pdfmake_decoded_image_free(self);

MODULE = PDF::Make  PACKAGE = PDF::Make::Render
PROTOTYPES: ENABLE

#
# Render decoded image to context
#

void
render_image(ctx, img)
    pdfmake_render_ctx_t *ctx
    pdfmake_decoded_image_t *img
    PREINIT:
        pdfmake_imgr_err_t err;
    CODE:
        err = pdfmake_render_decoded_image(ctx, img);
        if (err != PDFMAKE_IMGR_OK) {
            croak("PDF::Make::Render: render_image failed (error %d)", err);
        }

void
render_image_at(ctx, img, x, y, width, height)
    pdfmake_render_ctx_t *ctx
    pdfmake_decoded_image_t *img
    double x
    double y
    double width
    double height
    PREINIT:
        pdfmake_imgr_err_t err;
    CODE:
        err = pdfmake_render_decoded_image_at(ctx, img, x, y, width, height);
        if (err != PDFMAKE_IMGR_OK) {
            croak("PDF::Make::Render: render_image_at failed (error %d)", err);
        }

void
blit_rgba(ctx, rgba_sv, img_w, img_h, dst_x, dst_y)
    pdfmake_render_ctx_t *ctx
    SV *rgba_sv
    int img_w
    int img_h
    int dst_x
    int dst_y
    PREINIT:
        STRLEN len;
        const uint32_t *rgba;
    CODE:
        rgba = (const uint32_t *)SvPV(rgba_sv, len);
        pdfmake_render_blit_rgba(ctx, rgba, img_w, img_h, dst_x, dst_y);

void
blit_scaled(ctx, rgba_sv, img_w, img_h, dst_x, dst_y, dst_w, dst_h, mode=PDFMAKE_INTERP_BILINEAR)
    pdfmake_render_ctx_t *ctx
    SV *rgba_sv
    int img_w
    int img_h
    int dst_x
    int dst_y
    int dst_w
    int dst_h
    int mode
    PREINIT:
        STRLEN len;
        const uint32_t *rgba;
    CODE:
        rgba = (const uint32_t *)SvPV(rgba_sv, len);
        pdfmake_render_blit_scaled(ctx, rgba, img_w, img_h, dst_x, dst_y,
            dst_w, dst_h, (pdfmake_interp_mode_t)mode);

MODULE = PDF::Make  PACKAGE = PDF::Make::ColorConvert
PROTOTYPES: ENABLE

#
# Standalone color conversion utilities
#

void
cmyk_to_rgb(c, m, y, k)
    int c
    int m
    int y
    int k
    PREINIT:
        uint8_t r, g, b;
    PPCODE:
        pdfmake_cmyk_to_rgb8(c, m, y, k, &r, &g, &b);
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(r)));
        PUSHs(sv_2mortal(newSViv(g)));
        PUSHs(sv_2mortal(newSViv(b)));

void
lab_to_rgb(L, a, b_val)
    double L
    double a
    double b_val
    PREINIT:
        uint8_t r, g, b;
    PPCODE:
        pdfmake_lab_to_rgb8(L, a, b_val, &r, &g, &b);
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSViv(r)));
        PUSHs(sv_2mortal(newSViv(g)));
        PUSHs(sv_2mortal(newSViv(b)));

#
# Interpolation mode constants
#

int
INTERP_NEAREST()
    CODE:
        RETVAL = PDFMAKE_INTERP_NEAREST;
    OUTPUT:
        RETVAL

int
INTERP_BILINEAR()
    CODE:
        RETVAL = PDFMAKE_INTERP_BILINEAR;
    OUTPUT:
        RETVAL

int
INTERP_BICUBIC()
    CODE:
        RETVAL = PDFMAKE_INTERP_BICUBIC;
    OUTPUT:
        RETVAL

#
# Colorspace constants
#

int
CS_GRAY()
    CODE:
        RETVAL = PDFMAKE_RCS_GRAY;
    OUTPUT:
        RETVAL

int
CS_RGB()
    CODE:
        RETVAL = PDFMAKE_RCS_RGB;
    OUTPUT:
        RETVAL

int
CS_CMYK()
    CODE:
        RETVAL = PDFMAKE_RCS_CMYK;
    OUTPUT:
        RETVAL

int
CS_INDEXED()
    CODE:
        RETVAL = PDFMAKE_RCS_INDEXED;
    OUTPUT:
        RETVAL

int
CS_LAB()
    CODE:
        RETVAL = PDFMAKE_RCS_LAB;
    OUTPUT:
        RETVAL

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::ImageRender", GV_ADD);
    PDFMAKE_REGISTER_GETTER(stash, "width",              pdfmake_decoded_image_t, width,              PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_GETTER(stash, "height",             pdfmake_decoded_image_t, height,             PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_GETTER(stash, "components",         pdfmake_decoded_image_t, components,         PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_GETTER(stash, "bits_per_component", pdfmake_decoded_image_t, bits_per_component, PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_GETTER(stash, "has_alpha",          pdfmake_decoded_image_t, has_alpha,          PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_CONST(stash, "INTERP_NEAREST",  PDFMAKE_INTERP_NEAREST);
    PDFMAKE_REGISTER_CONST(stash, "INTERP_BILINEAR", PDFMAKE_INTERP_BILINEAR);
    PDFMAKE_REGISTER_CONST(stash, "INTERP_BICUBIC",  PDFMAKE_INTERP_BICUBIC);
    PDFMAKE_REGISTER_CONST(stash, "RCS_GRAY",        PDFMAKE_RCS_GRAY);
    PDFMAKE_REGISTER_CONST(stash, "RCS_RGB",         PDFMAKE_RCS_RGB);
    PDFMAKE_REGISTER_CONST(stash, "RCS_CMYK",        PDFMAKE_RCS_CMYK);
    PDFMAKE_REGISTER_CONST(stash, "RCS_INDEXED",     PDFMAKE_RCS_INDEXED);
    PDFMAKE_REGISTER_CONST(stash, "RCS_LAB",         PDFMAKE_RCS_LAB);
}

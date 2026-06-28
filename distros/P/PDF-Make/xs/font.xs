MODULE = PDF::Make  PACKAGE = PDF::Make::Font
PROTOTYPES: ENABLE

# ============================================================================
# Constructors
# ============================================================================

SV *
standard14(class, base_font, ...)
    char *class
    const char *base_font
    PREINIT:
        pdfmake_arena_t *arena = NULL;
        pdfmake_font_t *font;
        SV *arena_sv = NULL;
    CODE:
        PERL_UNUSED_VAR(class);
        
        /* Optional arena parameter */
        if (items > 2 && SvOK(ST(2))) {
            if (sv_isobject(ST(2)) && sv_derived_from(ST(2), "PDF::Make::Arena")) {
                pdfmake_arena_xs_t *arena_xs = INT2PTR(pdfmake_arena_xs_t *, SvIV(SvRV(ST(2))));
                arena = arena_xs->arena;
                arena_sv = ST(2);
            }
        }
        
        /* Create arena if not provided */
        if (!arena) {
            arena = pdfmake_arena_new();
            if (!arena)
                croak("PDF::Make::Font: failed to allocate arena");
        }
        
        font = pdfmake_font_standard14(arena, base_font);
        if (!font)
            croak("PDF::Make::Font: unknown standard font '%s'", base_font);
        
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "PDF::Make::Font", (void *)font);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

SV *
from_file(class, path, ...)
    char *class
    const char *path
    PREINIT:
        FILE *fp;
        long file_len;
        uint8_t *buf;
        size_t nread;
        pdfmake_arena_t *arena = NULL;
        pdfmake_font_t *font;
        SV *arena_sv = NULL;
    CODE:
        PERL_UNUSED_VAR(class);
        
        /* Optional arena parameter */
        if (items > 2 && SvOK(ST(2))) {
            if (sv_isobject(ST(2)) && sv_derived_from(ST(2), "PDF::Make::Arena")) {
                pdfmake_arena_xs_t *arena_xs = INT2PTR(pdfmake_arena_xs_t *, SvIV(SvRV(ST(2))));
                arena = arena_xs->arena;
                arena_sv = ST(2);
            }
        }
        
        /* Create arena if not provided */
        if (!arena) {
            arena = pdfmake_arena_new();
            if (!arena)
                croak("PDF::Make::Font: failed to allocate arena");
        }
        
        fp = fopen(path, "rb");
        if (!fp)
            croak("PDF::Make::Font: cannot open '%s'", path);
        
        if (fseek(fp, 0, SEEK_END) != 0) { fclose(fp); croak("PDF::Make::Font: seek failed"); }
        file_len = ftell(fp);
        if (file_len < 0) { fclose(fp); croak("PDF::Make::Font: tell failed"); }
        rewind(fp);
        
        buf = malloc((size_t)file_len);
        if (!buf) { fclose(fp); croak("PDF::Make::Font: malloc failed"); }
        
        nread = fread(buf, 1, (size_t)file_len, fp);
        fclose(fp);
        if ((long)nread != file_len) { free(buf); croak("PDF::Make::Font: short read"); }
        
        font = pdfmake_font_from_ttf(arena, buf, (size_t)file_len);
        free(buf);
        if (!font)
            croak("PDF::Make::Font: failed to parse TTF '%s'", path);
        
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "PDF::Make::Font", (void *)font);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

SV *
from_bytes(class, bytes_sv, ...)
    char *class
    SV *bytes_sv
    PREINIT:
        STRLEN len;
        const uint8_t *buf;
        pdfmake_arena_t *arena = NULL;
        pdfmake_font_t *font;
        SV *arena_sv = NULL;
    CODE:
        PERL_UNUSED_VAR(class);
        
        /* Optional arena parameter */
        if (items > 2 && SvOK(ST(2))) {
            if (sv_isobject(ST(2)) && sv_derived_from(ST(2), "PDF::Make::Arena")) {
                pdfmake_arena_xs_t *arena_xs = INT2PTR(pdfmake_arena_xs_t *, SvIV(SvRV(ST(2))));
                arena = arena_xs->arena;
                arena_sv = ST(2);
            }
        }
        
        /* Create arena if not provided */
        if (!arena) {
            arena = pdfmake_arena_new();
            if (!arena)
                croak("PDF::Make::Font: failed to allocate arena");
        }
        
        buf = (const uint8_t *)SvPV(bytes_sv, len);
        font = pdfmake_font_from_ttf(arena, buf, len);
        if (!font)
            croak("PDF::Make::Font: failed to parse TTF bytes");
        
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "PDF::Make::Font", (void *)font);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

# ============================================================================
# Accessors
# ============================================================================

const char *
base_font(self)
    pdfmake_font_t *self
    CODE:
        RETVAL = self->base_font;
    OUTPUT:
        RETVAL

IV
type(self)
    pdfmake_font_t *self
    CODE:
        RETVAL = (IV)self->type;
    OUTPUT:
        RETVAL

IV
std14_id(self)
    pdfmake_font_t *self
    CODE:
        if (self->type != PDFMAKE_FONT_TYPE1)
            croak("PDF::Make::Font::std14_id: not a Standard 14 font");
        RETVAL = (IV)self->std14_id;
    OUTPUT:
        RETVAL

# ============================================================================
# Metrics
# ============================================================================

NV
advance(self, codepoint, font_size)
    pdfmake_font_t *self
    UV codepoint
    NV font_size
    CODE:
        RETVAL = pdfmake_font_advance(self, (uint32_t)codepoint, font_size);
    OUTPUT:
        RETVAL

NV
string_width(self, utf8_sv, font_size)
    pdfmake_font_t *self
    SV *utf8_sv
    NV font_size
    PREINIT:
        STRLEN len;
        const char *utf8;
    CODE:
        utf8 = SvPV(utf8_sv, len);
        RETVAL = pdfmake_font_string_width(self, utf8, len, font_size);
    OUTPUT:
        RETVAL

SV *
metrics(self)
    pdfmake_font_t *self
    PREINIT:
        const pdfmake_font_metrics_t *m;
        HV *hv;
        AV *bbox;
    CODE:
        m = pdfmake_font_metrics(self);
        hv = newHV();
        hv_store(hv, "ascent", 6, newSViv(m->ascent), 0);
        hv_store(hv, "descent", 7, newSViv(m->descent), 0);
        hv_store(hv, "cap_height", 10, newSViv(m->cap_height), 0);
        hv_store(hv, "x_height", 8, newSViv(m->x_height), 0);
        hv_store(hv, "stem_v", 6, newSViv(m->stem_v), 0);
        hv_store(hv, "stem_h", 6, newSViv(m->stem_h), 0);
        hv_store(hv, "italic_angle", 12, newSViv(m->italic_angle), 0);
        hv_store(hv, "flags", 5, newSVuv(m->flags), 0);

        bbox = newAV();
        av_push(bbox, newSViv(m->bbox[0]));
        av_push(bbox, newSViv(m->bbox[1]));
        av_push(bbox, newSViv(m->bbox[2]));
        av_push(bbox, newSViv(m->bbox[3]));
        hv_store(hv, "bbox", 4, newRV_noinc((SV *)bbox), 0);

        RETVAL = newRV_noinc((SV *)hv);
    OUTPUT:
        RETVAL

# ============================================================================
# Encoding
# ============================================================================

SV *
encode_utf8(self, utf8_sv)
    pdfmake_font_t *self
    SV *utf8_sv
    PREINIT:
        STRLEN len;
        const char *utf8;
        pdfmake_buf_t buf;
        pdfmake_err_t err;
    CODE:
        utf8 = SvPV(utf8_sv, len);
        pdfmake_buf_init(&buf);
        err = pdfmake_font_encode_utf8(self, utf8, len, &buf);
        if (err != PDFMAKE_OK) {
            pdfmake_buf_free(&buf);
            croak("PDF::Make::Font::encode_utf8: encoding failed");
        }
        RETVAL = newSVpvn((const char *)buf.data, buf.len);
        pdfmake_buf_free(&buf);
    OUTPUT:
        RETVAL

# ============================================================================
# PDF output
# ============================================================================

UV
write_to_doc(self, doc)
    pdfmake_font_t *self
    pdfmake_doc_t *doc
    PREINIT:
        pdfmake_ref_t ref;
    CODE:
        ref = pdfmake_font_write(self, doc);
        if (ref.num == 0 && ref.gen == 0)
            croak("PDF::Make::Font: failed to write font to document");
        RETVAL = ref.num;
    OUTPUT:
        RETVAL

# ============================================================================
# Cleanup
# ============================================================================

void
DESTROY(self)
    pdfmake_font_t *self
    CODE:
        pdfmake_font_free(self);


MODULE = PDF::Make  PACKAGE = PDF::Make::Font::Std14
PROTOTYPES: ENABLE

# ============================================================================
# Standard 14 font constants and utilities
# ============================================================================

IV
HELVETICA()
    CODE:
        RETVAL = PDFMAKE_STD14_HELVETICA;
    OUTPUT:
        RETVAL

IV
HELVETICA_BOLD()
    CODE:
        RETVAL = PDFMAKE_STD14_HELVETICA_BOLD;
    OUTPUT:
        RETVAL

IV
HELVETICA_OBLIQUE()
    CODE:
        RETVAL = PDFMAKE_STD14_HELVETICA_OBLIQUE;
    OUTPUT:
        RETVAL

IV
HELVETICA_BOLDOBLIQUE()
    CODE:
        RETVAL = PDFMAKE_STD14_HELVETICA_BOLDOBLIQUE;
    OUTPUT:
        RETVAL

IV
TIMES_ROMAN()
    CODE:
        RETVAL = PDFMAKE_STD14_TIMES_ROMAN;
    OUTPUT:
        RETVAL

IV
TIMES_BOLD()
    CODE:
        RETVAL = PDFMAKE_STD14_TIMES_BOLD;
    OUTPUT:
        RETVAL

IV
TIMES_ITALIC()
    CODE:
        RETVAL = PDFMAKE_STD14_TIMES_ITALIC;
    OUTPUT:
        RETVAL

IV
TIMES_BOLDITALIC()
    CODE:
        RETVAL = PDFMAKE_STD14_TIMES_BOLDITALIC;
    OUTPUT:
        RETVAL

IV
COURIER()
    CODE:
        RETVAL = PDFMAKE_STD14_COURIER;
    OUTPUT:
        RETVAL

IV
COURIER_BOLD()
    CODE:
        RETVAL = PDFMAKE_STD14_COURIER_BOLD;
    OUTPUT:
        RETVAL

IV
COURIER_OBLIQUE()
    CODE:
        RETVAL = PDFMAKE_STD14_COURIER_OBLIQUE;
    OUTPUT:
        RETVAL

IV
COURIER_BOLDOBLIQUE()
    CODE:
        RETVAL = PDFMAKE_STD14_COURIER_BOLDOBLIQUE;
    OUTPUT:
        RETVAL

IV
SYMBOL()
    CODE:
        RETVAL = PDFMAKE_STD14_SYMBOL;
    OUTPUT:
        RETVAL

IV
ZAPFDINGBATS()
    CODE:
        RETVAL = PDFMAKE_STD14_ZAPFDINGBATS;
    OUTPUT:
        RETVAL

IV
lookup(class, name)
    char *class
    const char *name
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pdfmake_std14_lookup(name);
    OUTPUT:
        RETVAL

IV
width(class, font_id, codepoint)
    char *class
    IV font_id
    UV codepoint
    CODE:
        PERL_UNUSED_VAR(class);
        RETVAL = pdfmake_std14_width((pdfmake_std14_id_t)font_id, (uint32_t)codepoint);
    OUTPUT:
        RETVAL

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Font", GV_ADD);
    PDFMAKE_REGISTER_GETTER(stash, "base_font", pdfmake_font_t, base_font, PDFMAKE_FIELD_STRING);
    PDFMAKE_REGISTER_GETTER(stash, "type",      pdfmake_font_t, type,      PDFMAKE_FIELD_INT);

    /* Standard 14 font constants (defined in Font::Std14, exported by Page) */
    HV *std14 = gv_stashpv("PDF::Make::Font::Std14", GV_ADD);
    PDFMAKE_REGISTER_CONST(std14, "HELVETICA",             PDFMAKE_STD14_HELVETICA);
    PDFMAKE_REGISTER_CONST(std14, "HELVETICA_BOLD",        PDFMAKE_STD14_HELVETICA_BOLD);
    PDFMAKE_REGISTER_CONST(std14, "HELVETICA_OBLIQUE",     PDFMAKE_STD14_HELVETICA_OBLIQUE);
    PDFMAKE_REGISTER_CONST(std14, "HELVETICA_BOLDOBLIQUE", PDFMAKE_STD14_HELVETICA_BOLDOBLIQUE);
    PDFMAKE_REGISTER_CONST(std14, "TIMES_ROMAN",           PDFMAKE_STD14_TIMES_ROMAN);
    PDFMAKE_REGISTER_CONST(std14, "TIMES_BOLD",            PDFMAKE_STD14_TIMES_BOLD);
    PDFMAKE_REGISTER_CONST(std14, "TIMES_ITALIC",          PDFMAKE_STD14_TIMES_ITALIC);
    PDFMAKE_REGISTER_CONST(std14, "TIMES_BOLDITALIC",      PDFMAKE_STD14_TIMES_BOLDITALIC);
    PDFMAKE_REGISTER_CONST(std14, "COURIER",               PDFMAKE_STD14_COURIER);
    PDFMAKE_REGISTER_CONST(std14, "COURIER_BOLD",          PDFMAKE_STD14_COURIER_BOLD);
    PDFMAKE_REGISTER_CONST(std14, "COURIER_OBLIQUE",       PDFMAKE_STD14_COURIER_OBLIQUE);
    PDFMAKE_REGISTER_CONST(std14, "COURIER_BOLDOBLIQUE",   PDFMAKE_STD14_COURIER_BOLDOBLIQUE);
    PDFMAKE_REGISTER_CONST(std14, "SYMBOL",                PDFMAKE_STD14_SYMBOL);
    PDFMAKE_REGISTER_CONST(std14, "ZAPFDINGBATS",          PDFMAKE_STD14_ZAPFDINGBATS);
}

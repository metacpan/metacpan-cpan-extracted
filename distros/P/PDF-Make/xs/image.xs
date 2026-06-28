MODULE = PDF::Make  PACKAGE = PDF::Make::Image
PROTOTYPES: ENABLE

SV *
from_file(class, path)
    char *class
    const char *path
    PREINIT:
        FILE *fp;
        long file_len;
        uint8_t *buf;
        size_t nread;
        pdfmake_image_t *img;
    CODE:
        PERL_UNUSED_VAR(class);
        fp = fopen(path, "rb");
        if (!fp)
            croak("PDF::Make::Image: cannot open '%s'", path);
        if (fseek(fp, 0, SEEK_END) != 0) { fclose(fp); croak("PDF::Make::Image: seek failed"); }
        file_len = ftell(fp);
        if (file_len < 0) { fclose(fp); croak("PDF::Make::Image: tell failed"); }
        rewind(fp);
        buf = malloc((size_t)file_len);
        if (!buf) { fclose(fp); croak("PDF::Make::Image: malloc failed"); }
        nread = fread(buf, 1, (size_t)file_len, fp);
        fclose(fp);
        if ((long)nread != file_len) { free(buf); croak("PDF::Make::Image: short read"); }

        /* Auto-detect and parse — pass NULL for doc since we don't need arena yet */
        img = pdfmake_image_from_bytes(NULL, buf, (size_t)file_len);
        free(buf);
        if (!img)
            croak("PDF::Make::Image: failed to parse image '%s'", path);

        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "PDF::Make::Image", (void *)img);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

SV *
from_bytes(class, bytes_sv)
    char *class
    SV *bytes_sv
    PREINIT:
        STRLEN len;
        const uint8_t *buf;
        pdfmake_image_t *img;
    CODE:
        PERL_UNUSED_VAR(class);
        buf = (const uint8_t *)SvPV(bytes_sv, len);
        img = pdfmake_image_from_bytes(NULL, buf, len);
        if (!img)
            croak("PDF::Make::Image: failed to parse image bytes");
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "PDF::Make::Image", (void *)img);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

UV
width(self)
    pdfmake_image_t *self
    CODE:
        RETVAL = self->width;
    OUTPUT:
        RETVAL

UV
height(self)
    pdfmake_image_t *self
    CODE:
        RETVAL = self->height;
    OUTPUT:
        RETVAL

IV
format(self)
    pdfmake_image_t *self
    CODE:
        RETVAL = self->format;
    OUTPUT:
        RETVAL

IV
components(self)
    pdfmake_image_t *self
    CODE:
        RETVAL = self->components;
    OUTPUT:
        RETVAL

int
has_alpha(self)
    pdfmake_image_t *self
    CODE:
        RETVAL = self->has_alpha;
    OUTPUT:
        RETVAL

UV
write_to_doc(self, doc)
    pdfmake_image_t *self
    pdfmake_doc_t *doc
    CODE:
        RETVAL = pdfmake_image_write(self, doc);
        if (RETVAL == 0)
            croak("PDF::Make::Image: failed to write image to document");
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_image_t *self
    CODE:
        pdfmake_image_free(self);

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Image", GV_ADD);
    PDFMAKE_REGISTER_GETTER(stash, "width",      pdfmake_image_t, width,      PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_GETTER(stash, "height",     pdfmake_image_t, height,     PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_GETTER(stash, "format",     pdfmake_image_t, format,     PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_GETTER(stash, "components", pdfmake_image_t, components, PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_GETTER(stash, "has_alpha",  pdfmake_image_t, has_alpha,  PDFMAKE_FIELD_INT);
}

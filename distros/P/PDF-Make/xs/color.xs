MODULE = PDF::Make  PACKAGE = PDF::Make::Color
PROTOTYPES: ENABLE

SV *
srgb(class)
    char *class
    CODE:
        PERL_UNUSED_VAR(class);
        pdfmake_colorspace_t *cs = pdfmake_cs_srgb(NULL);
        if (!cs) croak("PDF::Make::Color: failed to create sRGB");
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "PDF::Make::Color", (void *)cs);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

SV *
separation(class, spot_name, c, m, y, k)
    char *class
    const char *spot_name
    double c
    double m
    double y
    double k
    CODE:
        PERL_UNUSED_VAR(class);
        pdfmake_colorspace_t *cs = pdfmake_cs_separation(NULL, spot_name, c, m, y, k);
        if (!cs) croak("PDF::Make::Color: failed to create separation");
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "PDF::Make::Color", (void *)cs);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

const char *
name(self)
    pdfmake_colorspace_t *self
    CODE:
        RETVAL = self->name;
    OUTPUT:
        RETVAL

IV
components(self)
    pdfmake_colorspace_t *self
    CODE:
        RETVAL = self->components;
    OUTPUT:
        RETVAL

UV
write_to_doc(self, doc)
    pdfmake_colorspace_t *self
    pdfmake_doc_t *doc
    CODE:
        RETVAL = pdfmake_cs_write(self, doc);
    OUTPUT:
        RETVAL

void
rgb_to_cmyk(class, r, g, b)
    char *class
    double r
    double g
    double b
    PREINIT:
        double c, m, y, k;
    PPCODE:
        PERL_UNUSED_VAR(class);
        pdfmake_rgb_to_cmyk(r, g, b, &c, &m, &y, &k);
        EXTEND(SP, 4);
        PUSHs(sv_2mortal(newSVnv(c)));
        PUSHs(sv_2mortal(newSVnv(m)));
        PUSHs(sv_2mortal(newSVnv(y)));
        PUSHs(sv_2mortal(newSVnv(k)));

void
cmyk_to_rgb(class, c, m, y, k)
    char *class
    double c
    double m
    double y
    double k
    PREINIT:
        double r, g, b;
    PPCODE:
        PERL_UNUSED_VAR(class);
        pdfmake_cmyk_to_rgb(c, m, y, k, &r, &g, &b);
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSVnv(r)));
        PUSHs(sv_2mortal(newSVnv(g)));
        PUSHs(sv_2mortal(newSVnv(b)));

void
hex_to_rgb(class, hex)
    char *class
    const char *hex
    PREINIT:
        double r, g, b;
    PPCODE:
        PERL_UNUSED_VAR(class);
        if (pdfmake_hex_to_rgb(hex, &r, &g, &b) != 0)
            croak("PDF::Make::Color: invalid hex color '%s'", hex);
        EXTEND(SP, 3);
        PUSHs(sv_2mortal(newSVnv(r)));
        PUSHs(sv_2mortal(newSVnv(g)));
        PUSHs(sv_2mortal(newSVnv(b)));

void
DESTROY(self)
    pdfmake_colorspace_t *self
    CODE:
        pdfmake_cs_free(self);

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Color", GV_ADD);
    PDFMAKE_REGISTER_GETTER(stash, "name",       pdfmake_colorspace_t, name,       PDFMAKE_FIELD_STRING);
    PDFMAKE_REGISTER_GETTER(stash, "components", pdfmake_colorspace_t, components, PDFMAKE_FIELD_INT);
}

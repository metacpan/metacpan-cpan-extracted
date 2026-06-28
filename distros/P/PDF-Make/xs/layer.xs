MODULE = PDF::Make  PACKAGE = PDF::Make::Layer
PROTOTYPES: ENABLE

SV *
_create(class, doc, name)
    char *class
    pdfmake_doc_t *doc
    const char *name
    PREINIT:
        pdfmake_ocg_t *ocg;
    CODE:
        PERL_UNUSED_VAR(class);
        ocg = pdfmake_doc_create_ocg(doc, name);
        if (!ocg)
            croak("PDF::Make::Layer: failed to create layer '%s'", name);
        RETVAL = sv_newmortal();
        sv_setref_pv(RETVAL, "PDF::Make::Layer", (void *)ocg);
        SvREFCNT_inc(RETVAL);
    OUTPUT:
        RETVAL

const char *
name(self)
    pdfmake_ocg_t *self
    CODE:
        RETVAL = self->name;
    OUTPUT:
        RETVAL

const char *
res_name(self)
    pdfmake_ocg_t *self
    CODE:
        RETVAL = self->res_name;
    OUTPUT:
        RETVAL

int
visible(self, ...)
    pdfmake_ocg_t *self
    CODE:
        if (items > 1) {
            self->visible = SvIV(ST(1));
        }
        RETVAL = self->visible;
    OUTPUT:
        RETVAL

void
set_print_state(self, state)
    pdfmake_ocg_t *self
    int state
    CODE:
        self->print_state = (pdfmake_ocg_state_t)state;
        self->has_print_state = 1;

void
set_view_state(self, state)
    pdfmake_ocg_t *self
    int state
    CODE:
        self->view_state = (pdfmake_ocg_state_t)state;
        self->has_view_state = 1;

void
set_export_state(self, state)
    pdfmake_ocg_t *self
    int state
    CODE:
        self->export_state = (pdfmake_ocg_state_t)state;
        self->has_export_state = 1;

UV
write_to_doc(self, doc)
    pdfmake_ocg_t *self
    pdfmake_doc_t *doc
    CODE:
        RETVAL = pdfmake_ocg_write(self, doc);
        if (RETVAL == 0)
            croak("PDF::Make::Layer: failed to write layer");
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_ocg_t *self
    CODE:
        /* OCG is arena-allocated, freed with document */
        PERL_UNUSED_VAR(self);

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Layer", GV_ADD);
    PDFMAKE_REGISTER_GETTER(stash, "name",     pdfmake_ocg_t, name,     PDFMAKE_FIELD_STRING);
    PDFMAKE_REGISTER_GETTER(stash, "res_name", pdfmake_ocg_t, res_name, PDFMAKE_FIELD_STRING);
    PDFMAKE_REGISTER_GETTER(stash, "visible",  pdfmake_ocg_t, visible,  PDFMAKE_FIELD_INT);
}

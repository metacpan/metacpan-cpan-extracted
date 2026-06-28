MODULE = PDF::Make  PACKAGE = PDF::Make::Writer
PROTOTYPES: ENABLE

pdfmake_writer_xs_t *
new(class)
    char *class
    CODE:
        Newxz(RETVAL, 1, pdfmake_writer_xs_t);
        if (pdfmake_buf_init(&RETVAL->buf) != PDFMAKE_OK) {
            Safefree(RETVAL);
            croak("PDF::Make::Writer::new: buffer init failed");
        }
    OUTPUT:
        RETVAL

SV *
write(self, obj_sv)
    pdfmake_writer_xs_t *self
    SV *obj_sv
    CODE:
        /* For now, accept a simple scalar and serialize it.
         * Full object support requires Object::Proto integration in later phases.
         * This is a placeholder that demonstrates the binding works. */
        if (!SvOK(obj_sv)) {
            /* undef -> null */
            pdfmake_obj_t obj = pdfmake_null();
            pdfmake_write_obj(&self->buf, NULL, &obj);
        }
        else if (SvIOK(obj_sv)) {
            /* Integer */
            pdfmake_obj_t obj = pdfmake_int(SvIV(obj_sv));
            pdfmake_write_obj(&self->buf, NULL, &obj);
        }
        else if (SvNOK(obj_sv)) {
            /* Float */
            pdfmake_obj_t obj = pdfmake_real(SvNV(obj_sv));
            pdfmake_write_obj(&self->buf, NULL, &obj);
        }
        else if (SvPOK(obj_sv)) {
            /* String - emit as literal string for now */
            STRLEN len;
            const char *str = SvPV(obj_sv, len);
            /* Placeholder: write as raw bytes. Full implementation needs arena. */
            pdfmake_buf_append(&self->buf, (const uint8_t *)str, len);
        }
        else {
            croak("PDF::Make::Writer::write: unsupported object type");
        }
        /* Return self for chaining */
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

SV *
to_bytes(self)
    pdfmake_writer_xs_t *self
    CODE:
        RETVAL = newSVpvn((char *)self->buf.data, self->buf.len);
        pdfmake_buf_clear(&self->buf);
    OUTPUT:
        RETVAL

UV
len(self)
    pdfmake_writer_xs_t *self
    CODE:
        RETVAL = self->buf.len;
    OUTPUT:
        RETVAL

void *
buf(self)
    pdfmake_writer_xs_t *self
    CODE:
        RETVAL = self->buf.data;
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_writer_xs_t *self
    CODE:
        pdfmake_buf_free(&self->buf);
        Safefree(self);

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Writer", GV_ADD);
    PDFMAKE_REGISTER_GETTER(stash, "len", pdfmake_writer_xs_t, buf.len, PDFMAKE_FIELD_UV);
}

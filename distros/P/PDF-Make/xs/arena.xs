MODULE = PDF::Make  PACKAGE = PDF::Make::Arena
PROTOTYPES: ENABLE

pdfmake_arena_xs_t *
new(class)
    char *class
    CODE:
        PERL_UNUSED_VAR(class);
        Newxz(RETVAL, 1, pdfmake_arena_xs_t);
        RETVAL->arena = pdfmake_arena_new();
        if (!RETVAL->arena) {
            Safefree(RETVAL);
            croak("PDF::Make::Arena::new: failed to create arena");
        }
    OUTPUT:
        RETVAL

void
DESTROY(self)
    pdfmake_arena_xs_t *self
    CODE:
        if (self->arena) {
            pdfmake_arena_free(self->arena);
        }
        Safefree(self);

void
reset(self)
    pdfmake_arena_xs_t *self
    CODE:
        pdfmake_arena_reset(self->arena);

pdfmake_obj_xs_t *
null(self)
    pdfmake_arena_xs_t *self
    CODE:
        Newxz(RETVAL, 1, pdfmake_obj_xs_t);
        RETVAL->arena_xs = self;
        RETVAL->arena_sv = SvREFCNT_inc(ST(0));
        RETVAL->obj = pdfmake_arena_alloc(self->arena, sizeof(pdfmake_obj_t));
        if (!RETVAL->obj) {
            SvREFCNT_dec(RETVAL->arena_sv);
            Safefree(RETVAL);
            croak("PDF::Make::Arena::null: allocation failed");
        }
        *RETVAL->obj = pdfmake_null();
    OUTPUT:
        RETVAL

pdfmake_obj_xs_t *
bool(self, value)
    pdfmake_arena_xs_t *self
    int value
    CODE:
        Newxz(RETVAL, 1, pdfmake_obj_xs_t);
        RETVAL->arena_xs = self;
        RETVAL->arena_sv = SvREFCNT_inc(ST(0));
        RETVAL->obj = pdfmake_arena_alloc(self->arena, sizeof(pdfmake_obj_t));
        if (!RETVAL->obj) {
            SvREFCNT_dec(RETVAL->arena_sv);
            Safefree(RETVAL);
            croak("PDF::Make::Arena::bool: allocation failed");
        }
        *RETVAL->obj = pdfmake_bool(value);
    OUTPUT:
        RETVAL

pdfmake_obj_xs_t *
int(self, value)
    pdfmake_arena_xs_t *self
    IV value
    CODE:
        Newxz(RETVAL, 1, pdfmake_obj_xs_t);
        RETVAL->arena_xs = self;
        RETVAL->arena_sv = SvREFCNT_inc(ST(0));
        RETVAL->obj = pdfmake_arena_alloc(self->arena, sizeof(pdfmake_obj_t));
        if (!RETVAL->obj) {
            SvREFCNT_dec(RETVAL->arena_sv);
            Safefree(RETVAL);
            croak("PDF::Make::Arena::int: allocation failed");
        }
        *RETVAL->obj = pdfmake_int((int64_t)value);
    OUTPUT:
        RETVAL

pdfmake_obj_xs_t *
real(self, value)
    pdfmake_arena_xs_t *self
    double value
    CODE:
        Newxz(RETVAL, 1, pdfmake_obj_xs_t);
        RETVAL->arena_xs = self;
        RETVAL->arena_sv = SvREFCNT_inc(ST(0));
        RETVAL->obj = pdfmake_arena_alloc(self->arena, sizeof(pdfmake_obj_t));
        if (!RETVAL->obj) {
            SvREFCNT_dec(RETVAL->arena_sv);
            Safefree(RETVAL);
            croak("PDF::Make::Arena::real: allocation failed");
        }
        *RETVAL->obj = pdfmake_real(value);
    OUTPUT:
        RETVAL

pdfmake_obj_xs_t *
name(self, str)
    pdfmake_arena_xs_t *self
    SV *str
    PREINIT:
        STRLEN len;
        const char *bytes;
    CODE:
        bytes = SvPV(str, len);
        Newxz(RETVAL, 1, pdfmake_obj_xs_t);
        RETVAL->arena_xs = self;
        RETVAL->arena_sv = SvREFCNT_inc(ST(0));
        RETVAL->obj = pdfmake_arena_alloc(self->arena, sizeof(pdfmake_obj_t));
        if (!RETVAL->obj) {
            SvREFCNT_dec(RETVAL->arena_sv);
            Safefree(RETVAL);
            croak("PDF::Make::Arena::name: allocation failed");
        }
        *RETVAL->obj = pdfmake_name(self->arena, bytes, len);
    OUTPUT:
        RETVAL

pdfmake_obj_xs_t *
str(self, str)
    pdfmake_arena_xs_t *self
    SV *str
    PREINIT:
        STRLEN len;
        const char *bytes;
    CODE:
        bytes = SvPV(str, len);
        Newxz(RETVAL, 1, pdfmake_obj_xs_t);
        RETVAL->arena_xs = self;
        RETVAL->arena_sv = SvREFCNT_inc(ST(0));
        RETVAL->obj = pdfmake_arena_alloc(self->arena, sizeof(pdfmake_obj_t));
        if (!RETVAL->obj) {
            SvREFCNT_dec(RETVAL->arena_sv);
            Safefree(RETVAL);
            croak("PDF::Make::Arena::str: allocation failed");
        }
        *RETVAL->obj = pdfmake_str(self->arena, bytes, len);
    OUTPUT:
        RETVAL

pdfmake_obj_xs_t *
hexstr(self, str)
    pdfmake_arena_xs_t *self
    SV *str
    PREINIT:
        STRLEN len;
        const char *bytes;
    CODE:
        bytes = SvPV(str, len);
        Newxz(RETVAL, 1, pdfmake_obj_xs_t);
        RETVAL->arena_xs = self;
        RETVAL->arena_sv = SvREFCNT_inc(ST(0));
        RETVAL->obj = pdfmake_arena_alloc(self->arena, sizeof(pdfmake_obj_t));
        if (!RETVAL->obj) {
            SvREFCNT_dec(RETVAL->arena_sv);
            Safefree(RETVAL);
            croak("PDF::Make::Arena::hexstr: allocation failed");
        }
        *RETVAL->obj = pdfmake_hexstr(self->arena, (const uint8_t *)bytes, len);
    OUTPUT:
        RETVAL

pdfmake_obj_xs_t *
obj_ref(self, num, gen = 0)
    pdfmake_arena_xs_t *self
    UV num
    UV gen
    CODE:
        Newxz(RETVAL, 1, pdfmake_obj_xs_t);
        RETVAL->arena_xs = self;
        RETVAL->arena_sv = SvREFCNT_inc(ST(0));
        RETVAL->obj = pdfmake_arena_alloc(self->arena, sizeof(pdfmake_obj_t));
        if (!RETVAL->obj) {
            SvREFCNT_dec(RETVAL->arena_sv);
            Safefree(RETVAL);
            croak("PDF::Make::Arena::obj_ref: allocation failed");
        }
        *RETVAL->obj = pdfmake_ref((uint32_t)num, (uint16_t)gen);
    OUTPUT:
        RETVAL

pdfmake_obj_xs_t *
array(self)
    pdfmake_arena_xs_t *self
    CODE:
        Newxz(RETVAL, 1, pdfmake_obj_xs_t);
        RETVAL->arena_xs = self;
        RETVAL->arena_sv = SvREFCNT_inc(ST(0));
        RETVAL->obj = pdfmake_arena_alloc(self->arena, sizeof(pdfmake_obj_t));
        if (!RETVAL->obj) {
            SvREFCNT_dec(RETVAL->arena_sv);
            Safefree(RETVAL);
            croak("PDF::Make::Arena::array: allocation failed");
        }
        *RETVAL->obj = pdfmake_array_new(self->arena);
    OUTPUT:
        RETVAL

pdfmake_obj_xs_t *
dict(self)
    pdfmake_arena_xs_t *self
    CODE:
        Newxz(RETVAL, 1, pdfmake_obj_xs_t);
        RETVAL->arena_xs = self;
        RETVAL->arena_sv = SvREFCNT_inc(ST(0));
        RETVAL->obj = pdfmake_arena_alloc(self->arena, sizeof(pdfmake_obj_t));
        if (!RETVAL->obj) {
            SvREFCNT_dec(RETVAL->arena_sv);
            Safefree(RETVAL);
            croak("PDF::Make::Arena::dict: allocation failed");
        }
        *RETVAL->obj = pdfmake_dict_new(self->arena);
    OUTPUT:
        RETVAL

pdfmake_obj_xs_t *
stream(self)
    pdfmake_arena_xs_t *self
    CODE:
        Newxz(RETVAL, 1, pdfmake_obj_xs_t);
        RETVAL->arena_xs = self;
        RETVAL->arena_sv = SvREFCNT_inc(ST(0));
        RETVAL->obj = pdfmake_arena_alloc(self->arena, sizeof(pdfmake_obj_t));
        if (!RETVAL->obj) {
            SvREFCNT_dec(RETVAL->arena_sv);
            Safefree(RETVAL);
            croak("PDF::Make::Arena::stream: allocation failed");
        }
        *RETVAL->obj = pdfmake_stream_new(self->arena);
    OUTPUT:
        RETVAL

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Arena", GV_ADD);
    PDFMAKE_REGISTER_ARENA_CTOR(stash, "null",    PDFMAKE_ARENA_ARG_NONE,   pdfmake_null);
    PDFMAKE_REGISTER_ARENA_CTOR(stash, "bool",    PDFMAKE_ARENA_ARG_INT,    pdfmake_bool);
    PDFMAKE_REGISTER_ARENA_CTOR(stash, "int",     PDFMAKE_ARENA_ARG_INT,    pdfmake_int);
    PDFMAKE_REGISTER_ARENA_CTOR(stash, "real",    PDFMAKE_ARENA_ARG_DOUBLE, pdfmake_real);
    PDFMAKE_REGISTER_ARENA_CTOR(stash, "name",    PDFMAKE_ARENA_ARG_STRING, pdfmake_name);
    PDFMAKE_REGISTER_ARENA_CTOR(stash, "str",     PDFMAKE_ARENA_ARG_STRING, pdfmake_str);
    PDFMAKE_REGISTER_ARENA_CTOR(stash, "hexstr",  PDFMAKE_ARENA_ARG_STRING, pdfmake_hexstr);
    PDFMAKE_REGISTER_ARENA_CTOR(stash, "obj_ref", PDFMAKE_ARENA_ARG_REF,    pdfmake_ref);
    PDFMAKE_REGISTER_ARENA_CTOR(stash, "array",   PDFMAKE_ARENA_ARG_NONE,   pdfmake_array_new);
    PDFMAKE_REGISTER_ARENA_CTOR(stash, "dict",    PDFMAKE_ARENA_ARG_NONE,   pdfmake_dict_new);
    PDFMAKE_REGISTER_ARENA_CTOR(stash, "stream",  PDFMAKE_ARENA_ARG_NONE,   pdfmake_stream_new);
}

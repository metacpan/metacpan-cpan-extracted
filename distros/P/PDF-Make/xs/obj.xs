MODULE = PDF::Make  PACKAGE = PDF::Make::Obj
PROTOTYPES: ENABLE

void
DESTROY(self)
    pdfmake_obj_xs_t *self
    CODE:
        if (self->arena_sv) {
            SvREFCNT_dec(self->arena_sv);
        }
        Safefree(self);

IV
kind(self)
    pdfmake_obj_xs_t *self
    CODE:
        RETVAL = self->obj->kind;
    OUTPUT:
        RETVAL

int
is_null(self)
    pdfmake_obj_xs_t *self
    CODE:
        RETVAL = pdfmake_is_null(self->obj);
    OUTPUT:
        RETVAL

int
is_bool(self)
    pdfmake_obj_xs_t *self
    CODE:
        RETVAL = pdfmake_is_bool(self->obj);
    OUTPUT:
        RETVAL

int
is_int(self)
    pdfmake_obj_xs_t *self
    CODE:
        RETVAL = pdfmake_is_int(self->obj);
    OUTPUT:
        RETVAL

int
is_real(self)
    pdfmake_obj_xs_t *self
    CODE:
        RETVAL = pdfmake_is_real(self->obj);
    OUTPUT:
        RETVAL

int
is_numeric(self)
    pdfmake_obj_xs_t *self
    CODE:
        RETVAL = pdfmake_is_numeric(self->obj);
    OUTPUT:
        RETVAL

int
is_name(self)
    pdfmake_obj_xs_t *self
    CODE:
        RETVAL = pdfmake_is_name(self->obj);
    OUTPUT:
        RETVAL

int
is_str(self)
    pdfmake_obj_xs_t *self
    CODE:
        RETVAL = pdfmake_is_str(self->obj);
    OUTPUT:
        RETVAL

int
is_array(self)
    pdfmake_obj_xs_t *self
    CODE:
        RETVAL = pdfmake_is_array(self->obj);
    OUTPUT:
        RETVAL

int
is_dict(self)
    pdfmake_obj_xs_t *self
    CODE:
        RETVAL = pdfmake_is_dict(self->obj);
    OUTPUT:
        RETVAL

int
is_stream(self)
    pdfmake_obj_xs_t *self
    CODE:
        RETVAL = pdfmake_is_stream(self->obj);
    OUTPUT:
        RETVAL

int
is_indirect_ref(self)
    pdfmake_obj_xs_t *self
    CODE:
        RETVAL = pdfmake_is_ref(self->obj);
    OUTPUT:
        RETVAL

SV *
value(self)
    pdfmake_obj_xs_t *self
    PREINIT:
        const uint8_t *bytes;
        size_t len;
    CODE:
        switch (self->obj->kind) {
            case PDFMAKE_NULL:
                RETVAL = &PL_sv_undef;
                break;
            case PDFMAKE_BOOL:
                RETVAL = pdfmake_get_bool(self->obj) ? &PL_sv_yes : &PL_sv_no;
                break;
            case PDFMAKE_INT:
                RETVAL = newSViv(pdfmake_get_int(self->obj));
                break;
            case PDFMAKE_REAL:
                RETVAL = newSVnv(pdfmake_get_real(self->obj));
                break;
            case PDFMAKE_NAME:
                bytes = (const uint8_t *)pdfmake_get_name_bytes(self->arena_xs->arena, self->obj);
                RETVAL = bytes ? newSVpv((const char *)bytes, 0) : &PL_sv_undef;
                break;
            case PDFMAKE_STR:
                bytes = pdfmake_get_str_bytes(self->obj, &len);
                RETVAL = bytes ? newSVpvn((const char *)bytes, len) : &PL_sv_undef;
                break;
            default:
                /* For composites, return undef - use specific methods */
                RETVAL = &PL_sv_undef;
                break;
        }
    OUTPUT:
        RETVAL

# Array methods

SV *
push(self, item)
    pdfmake_obj_xs_t *self
    pdfmake_obj_xs_t *item
    CODE:
        if (self->obj->kind != PDFMAKE_ARRAY)
            croak("PDF::Make::Obj::push: not an array");
        if (!pdfmake_array_push(self->arena_xs->arena, self->obj, *item->obj))
            croak("PDF::Make::Obj::push: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

UV
len(self)
    pdfmake_obj_xs_t *self
    CODE:
        if (self->obj->kind == PDFMAKE_ARRAY) {
            RETVAL = pdfmake_array_len(self->obj);
        } else if (self->obj->kind == PDFMAKE_DICT) {
            RETVAL = pdfmake_dict_len(self->obj);
        } else if (self->obj->kind == PDFMAKE_STR) {
            size_t slen;
            pdfmake_get_str_bytes(self->obj, &slen);
            RETVAL = slen;
        } else {
            croak("PDF::Make::Obj::len: not an array, dict, or string");
        }
    OUTPUT:
        RETVAL

pdfmake_obj_xs_t *
get(self, index_or_key)
    pdfmake_obj_xs_t *self
    SV *index_or_key
    CODE:
        pdfmake_obj_t *result = NULL;
        if (self->obj->kind == PDFMAKE_ARRAY) {
            UV idx = SvUV(index_or_key);
            result = pdfmake_array_get(self->obj, idx);
        } else if (self->obj->kind == PDFMAKE_DICT) {
            /* Key is a name string - need to intern it */
            STRLEN len;
            const char *key = SvPV(index_or_key, len);
            uint32_t name_id = pdfmake_arena_intern_name(self->arena_xs->arena, key, len);
            result = pdfmake_dict_get(self->obj, name_id);
        } else {
            croak("PDF::Make::Obj::get: not an array or dict");
        }
        if (!result) {
            XSRETURN_UNDEF;
        }
        /* Wrap the result - it lives in the same arena */
        Newxz(RETVAL, 1, pdfmake_obj_xs_t);
        RETVAL->arena_xs = self->arena_xs;
        RETVAL->arena_sv = SvREFCNT_inc(self->arena_sv);
        RETVAL->obj = result;
    OUTPUT:
        RETVAL

# Dict methods

SV *
set(self, key, val)
    pdfmake_obj_xs_t *self
    SV *key
    pdfmake_obj_xs_t *val
    PREINIT:
        STRLEN len;
        const char *key_str;
        uint32_t name_id;
    CODE:
        if (self->obj->kind != PDFMAKE_DICT)
            croak("PDF::Make::Obj::set: not a dict");
        key_str = SvPV(key, len);
        name_id = pdfmake_arena_intern_name(self->arena_xs->arena, key_str, len);
        if (!pdfmake_dict_set(self->arena_xs->arena, self->obj, name_id, *val->obj))
            croak("PDF::Make::Obj::set: failed");
        RETVAL = SvREFCNT_inc(ST(0));
    OUTPUT:
        RETVAL

int
has(self, key)
    pdfmake_obj_xs_t *self
    SV *key
    PREINIT:
        STRLEN len;
        const char *key_str;
        uint32_t name_id;
    CODE:
        if (self->obj->kind != PDFMAKE_DICT)
            croak("PDF::Make::Obj::has: not a dict");
        key_str = SvPV(key, len);
        name_id = pdfmake_arena_intern_name(self->arena_xs->arena, key_str, len);
        RETVAL = pdfmake_dict_has(self->obj, name_id);
    OUTPUT:
        RETVAL

int
del(self, key)
    pdfmake_obj_xs_t *self
    SV *key
    PREINIT:
        STRLEN len;
        const char *key_str;
        uint32_t name_id;
    CODE:
        if (self->obj->kind != PDFMAKE_DICT)
            croak("PDF::Make::Obj::del: not a dict");
        key_str = SvPV(key, len);
        name_id = pdfmake_arena_intern_name(self->arena_xs->arena, key_str, len);
        RETVAL = pdfmake_dict_del(self->obj, name_id);
    OUTPUT:
        RETVAL

# Indirect reference accessors

UV
obj_ref_num(self)
    pdfmake_obj_xs_t *self
    CODE:
        if (self->obj->kind != PDFMAKE_REF)
            croak("PDF::Make::Obj::obj_ref_num: not a ref");
        RETVAL = self->obj->as.ref.num;
    OUTPUT:
        RETVAL

UV
obj_ref_gen(self)
    pdfmake_obj_xs_t *self
    CODE:
        if (self->obj->kind != PDFMAKE_REF)
            croak("PDF::Make::Obj::obj_ref_gen: not a ref");
        RETVAL = self->obj->as.ref.gen;
    OUTPUT:
        RETVAL

BOOT:
{
    HV *stash = gv_stashpv("PDF::Make::Obj", GV_ADD);
    /* Indirect getters: self->obj->field */
    PDFMAKE_REGISTER_INDIRECT_GETTER(stash, "kind",
        pdfmake_obj_xs_t, obj, pdfmake_obj_t, kind, PDFMAKE_FIELD_INT);
    PDFMAKE_REGISTER_INDIRECT_GETTER(stash, "obj_ref_num",
        pdfmake_obj_xs_t, obj, pdfmake_obj_t, as.ref.num, PDFMAKE_FIELD_UV);
    PDFMAKE_REGISTER_INDIRECT_GETTER(stash, "obj_ref_gen",
        pdfmake_obj_xs_t, obj, pdfmake_obj_t, as.ref.gen, PDFMAKE_FIELD_UV);
    /* Type tests: self->obj->kind == PDFMAKE_X */
    PDFMAKE_REGISTER_TYPETEST(stash, "is_null",
        pdfmake_obj_xs_t, obj, pdfmake_obj_t, kind, PDFMAKE_NULL);
    PDFMAKE_REGISTER_TYPETEST(stash, "is_bool",
        pdfmake_obj_xs_t, obj, pdfmake_obj_t, kind, PDFMAKE_BOOL);
    PDFMAKE_REGISTER_TYPETEST(stash, "is_int",
        pdfmake_obj_xs_t, obj, pdfmake_obj_t, kind, PDFMAKE_INT);
    PDFMAKE_REGISTER_TYPETEST(stash, "is_real",
        pdfmake_obj_xs_t, obj, pdfmake_obj_t, kind, PDFMAKE_REAL);
    PDFMAKE_REGISTER_TYPETEST(stash, "is_name",
        pdfmake_obj_xs_t, obj, pdfmake_obj_t, kind, PDFMAKE_NAME);
    PDFMAKE_REGISTER_TYPETEST(stash, "is_str",
        pdfmake_obj_xs_t, obj, pdfmake_obj_t, kind, PDFMAKE_STR);
    PDFMAKE_REGISTER_TYPETEST(stash, "is_array",
        pdfmake_obj_xs_t, obj, pdfmake_obj_t, kind, PDFMAKE_ARRAY);
    PDFMAKE_REGISTER_TYPETEST(stash, "is_dict",
        pdfmake_obj_xs_t, obj, pdfmake_obj_t, kind, PDFMAKE_DICT);
    PDFMAKE_REGISTER_TYPETEST(stash, "is_stream",
        pdfmake_obj_xs_t, obj, pdfmake_obj_t, kind, PDFMAKE_STREAM);
    PDFMAKE_REGISTER_TYPETEST(stash, "is_indirect_ref",
        pdfmake_obj_xs_t, obj, pdfmake_obj_t, kind, PDFMAKE_REF);
}

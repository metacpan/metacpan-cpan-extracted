#define PERL_NO_GET_CONTEXT
#include "easyxs/easyxs.h"

#include <stdbool.h>
#include <string.h>

#include "tomlc17.h"

/* Disabled for production because adding subprocess detection
   would entail having a separate struct for the objects, which
   seems likely to degrade performance.
*/
#define DETECT_LEAKS 0

#define DOCUMENT_CLASS "TOML::XS::Document"
#define TIMESTAMP_CLASS "TOML::XS::Timestamp"
#define BOOLEAN_CLASS "TOML::XS"

#define PERL_TRUE get_sv(BOOLEAN_CLASS "::true", 0)
#define PERL_FALSE get_sv(BOOLEAN_CLASS "::false", 0)

#define UNUSED(x) (void)(x)

#ifdef PL_phase
#define _IS_GLOBAL_DESTRUCT (PL_phase == PERL_PHASE_DESTRUCT)
#else
#define _IS_GLOBAL_DESTRUCT PL_dirty
#endif

#define _verify_no_null(tomlstr, tomllen)               \
    if (strchr(tomlstr, 0) != (tomlstr + tomllen)) {    \
        croak(                                          \
            "String contains a NUL at index %" UVf "!", \
            (UV)(strchr(tomlstr, 0) - tomlstr)          \
        );                                              \
    }

#define _verify_valid_utf8(tomlstr, tomllen)                    \
    if (!is_utf8_string( (const U8*)tomlstr, tomllen )) {       \
        U8* ep;                                                 \
        const U8** epptr = (const U8**) &ep;                    \
        is_utf8_string_loc((const U8*)tomlstr, tomllen, epptr); \
        croak(                                                  \
            "String contains non-UTF-8 at index %" UVf "!",     \
            (UV)((char*) ep - tomlstr)                          \
        );                                                      \
    }

const char* type_name[] = {
    [TOML_STRING] = "string",
    [TOML_INT64] = "integer",
    [TOML_FP64] = "float",
    [TOML_BOOLEAN] = "boolean",
    [TOML_DATE] = "date",
    [TOML_TIME] = "time",
    [TOML_DATETIME] = "datetime",
    [TOML_DATETIMETZ] = "datetime",
};

void append_tz_to_sv(pTHX_ int16_t minutes, SV* sv) {
    char sign = (minutes < 0) ? '-' : '+';
    int abs_minutes = abs(minutes);

    int hours = abs_minutes / 60;
    int mins = abs_minutes % 60;

    sv_catpvf(sv, "%c%02d:%02d", sign, hours, mins);
}

/* perlclib describes grok_atoUV(), but it’s not public. :( */
bool my_grok_atoUV(pTHX_ const char *pv, UV *valuep) {
    int numtype = grok_number(pv, strlen(pv), valuep);

    /* The presence of any other flag in numtype indicates that
       something besides a simple unsigned int was given. */
    if (numtype == IS_NUMBER_IN_UV) return true;

    return false;
}

static inline SV* _call_pv_scalar_1_1 (pTHX_ const char* fn, SV* arg) {
     dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    EXTEND(SP, 1);

    mPUSHs(arg);

    PUTBACK;

    unsigned count = call_pv(fn, G_SCALAR);

    SPAGAIN;

    SV* ret;

    if (count > 0) {
        ret = newSVsv(POPs);
    }
    else {
        ret = &PL_sv_undef;
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return ret;
}

static inline SV* _make_json_pointer_sv (pTHX_ SV** stack, unsigned stack_idx) {
    AV* pointer = newAV();

    for (unsigned i=0; i<=stack_idx; i++) {
        av_push(pointer, newSVsv(stack[i]));
    }

    SV* pointer_ar = newRV_noinc( (SV*) pointer );

    return _call_pv_scalar_1_1(aTHX_ "TOML::XS::_BUILD_JSON_POINTER", pointer_ar);
}

toml_datum_t _get_toml_timestamp_from_sv(pTHX_ SV *self_sv) {
    toml_datum_t* datum = exs_structref_ptr(self_sv);

    return *datum;
}

SV* _toml_datum_to_sv(pTHX_ toml_datum_t datum);

SV* _toml_table_to_sv(pTHX_ toml_datum_t datum) {
    ASSUME(datum.type == TOML_TABLE);

    /* Doesn’t need to be mortal since this should not throw.
        Should that ever change this will need to be mortal then
        de-mortalized.
    */
    HV* hv = newHV();

    for (int i = 0; i < datum.u.tab.size; i++) {
        SV* sv = _toml_datum_to_sv(aTHX_ datum.u.tab.value[i]);
        ASSUME(sv != NULL);

        const char* key = datum.u.tab.key[i];
        int keylen = datum.u.tab.len[i];

        hv_store(hv, key, -keylen, sv, 0);
    }

    return newRV_noinc( (SV *) hv );
}

SV* _toml_array_to_sv(pTHX_ toml_datum_t datum) {
    ASSUME(datum.type == TOML_ARRAY);

    /* Doesn’t need to be mortal since this should not throw.
        Should that ever change this will need to be mortal then
        de-mortalized.
    */
    AV* av = newAV();

    //int size = toml_array_nelem(arr);
    int size = datum.u.arr.size;

    av_extend(av, size - 1);

    for (int i = 0; i<size; i++) {
        SV* sv = _toml_datum_to_sv(aTHX_ datum.u.arr.elem[i]);
        ASSUME(sv != NULL);

        av_store(av, i, sv);
    }

    return newRV_noinc( (SV *) av );
}


SV* _toml_datum_to_sv(pTHX_ toml_datum_t datum) {
    SV* ret;

    switch (datum.type) {
    case TOML_UNKNOWN:
        ASSUME(FALSE);
    case TOML_STRING:
        return newSVpvn_utf8(datum.u.str.ptr, datum.u.str.len, TRUE);
    case TOML_INT64:
        return newSViv(datum.u.int64);
    case TOML_FP64:
        return newSVnv(datum.u.fp64);
    case TOML_BOOLEAN:
        return SvREFCNT_inc(datum.u.boolean ? PERL_TRUE : PERL_FALSE);
    case TOML_DATE:
    case TOML_TIME:
    case TOML_DATETIME:
    case TOML_DATETIMETZ:
        ret = exs_new_structref(toml_datum_t, TIMESTAMP_CLASS);
        memcpy(exs_structref_ptr(ret), &datum, sizeof(toml_datum_t));
        return ret;
    case TOML_ARRAY:
        return _toml_array_to_sv(aTHX_ datum);
    case TOML_TABLE:
        return _toml_table_to_sv(aTHX_ datum);
    default:
        break;
    }

    ASSUME(FALSE);
}

toml_datum_t _drill_into_array(pTHX_ toml_datum_t datum, SV** stack, unsigned stack_idx, unsigned drill_len);

static inline void _croak_on_nonfinal_drill( pTHX_ toml_type_t type, SV** stack, unsigned stack_idx, unsigned drill_len) {
    SV* jsonpointer = _make_json_pointer_sv(aTHX_ stack, stack_idx);
    sv_2mortal(jsonpointer);

    croak("Cannot descend into non-container (%s)! (JSON pointer: %" SVf ")", type_name[type], jsonpointer);

    assert(0);
}

toml_datum_t _drill_into_table(pTHX_ toml_datum_t tabin, SV** stack, unsigned stack_idx, unsigned drill_len) {
    ASSUME(tabin.type == TOML_TABLE);

    SV* key_sv = stack[stack_idx];

    if (!SvOK(key_sv)) {
        croak("Uninitialized value given in pointer (#%d)!", stack_idx);
    }

    char* key = SvPVutf8_nolen(key_sv);

    toml_datum_t next = toml_get(tabin, key);

    if (next.type == TOML_UNKNOWN) {
        SV* json_pointer = _make_json_pointer_sv(aTHX_ stack, stack_idx);
        sv_2mortal(json_pointer);
        croak("element not found (JSON pointer: %" SVf ")", json_pointer);
    }

    if (stack_idx == drill_len-1) {
        return next;
    }

    switch (next.type) {
    case TOML_UNKNOWN:
        assert(0);
    case TOML_TABLE:
        return _drill_into_table(aTHX_ next, stack, 1 + stack_idx, drill_len);
    case TOML_ARRAY:
        return _drill_into_array(aTHX_ next, stack, 1 + stack_idx, drill_len);
    default:
        break;
    }

    _croak_on_nonfinal_drill(aTHX_ next.type, stack, stack_idx, drill_len);

    ASSUME(FALSE);
    return next; // silence compiler warning
}

toml_datum_t _drill_into_array(pTHX_ toml_datum_t datum, SV** stack, unsigned stack_idx, unsigned drill_len) {
    ASSUME(datum.type == TOML_ARRAY);

    int i;

    SV* key_sv = stack[stack_idx];

    if (SvUOK(key_sv)) {
        i = SvUV(key_sv);
    }
    else if (!SvOK(key_sv)) {
        croak("Undef given as pointer value (#%d)!", stack_idx);
    }
    else {
        UV idx_uv;

        if (my_grok_atoUV(aTHX_ SvPVbyte_nolen(key_sv), &idx_uv)) {
            i = idx_uv;
        }
        else {
            SV* json_pointer = _make_json_pointer_sv(aTHX_ stack, stack_idx - 1);
            sv_2mortal(json_pointer);
            croak("Invalid array index (%" SVf ") given to array (JSON pointer: %" SVf ")!", key_sv, json_pointer);
        }
    }

    if (i >= datum.u.arr.size) {
        SV* json_pointer = _make_json_pointer_sv(aTHX_ stack, stack_idx);
        sv_2mortal(json_pointer);
        croak("Index exceeds max array index (%d; JSON pointer: %" SVf ")", datum.u.arr.size - 1, json_pointer);
    }

    toml_datum_t next = datum.u.arr.elem[i];

    if (stack_idx == drill_len-1) {
        return next;
    }

    switch (next.type) {
    case TOML_UNKNOWN:
        assert(0);
    case TOML_TABLE:
        return _drill_into_table(aTHX_ next, stack, 1 + stack_idx, drill_len);
    case TOML_ARRAY:
        return _drill_into_array(aTHX_ next, stack, 1 + stack_idx, drill_len);
    default:
        break;
    }

    _croak_on_nonfinal_drill(aTHX_ next.type, stack, stack_idx, drill_len);

    assert(0);
    return next; // silence compiler warning
}

/* ---------------------------------------------------------------------- */

MODULE = TOML::XS     PACKAGE = TOML::XS

PROTOTYPES: DISABLE

SV*
from_toml (SV* tomlsv)
    CODE:
        STRLEN tomllen;
        char* tomlstr = SvPVbyte(tomlsv, tomllen);

        _verify_no_null(tomlstr, tomllen);

        _verify_valid_utf8(tomlstr, tomllen);

        toml_result_t res = toml_parse(tomlstr, tomllen);

        if (!res.ok) {
            toml_free(res);
            croak("failed to parse TOML: %s", res.errmsg);
        }

        SV* retsv = exs_new_structref(toml_result_t, DOCUMENT_CLASS);
        memcpy(exs_structref_ptr(retsv), &res, sizeof(toml_result_t));

        RETVAL = retsv;
    OUTPUT:
        RETVAL

# ----------------------------------------------------------------------

INCLUDE: Document.xs
INCLUDE: Timestamp.xs

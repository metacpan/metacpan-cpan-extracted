#define PERL_NO_GET_CONTEXT
#include "xs/convert/sv_to_upb.h"
#include "xs/protobuf.h"
#include "xs/protobuf/message.h"
#include "xs/protobuf/utils.h"
#include "xs/repeated/repeated.h"
#include "xs/map/map.h"
#include "upb/base/descriptor_constants.h"
#include "upb/reflection/def.h"
#include "upb/reflection/message.h"
#include "upb/message/array.h"
#include "upb/message/copy.h"
#include "upb/message/map.h"
#include <stdint.h>
#include <errno.h>
#include <ctype.h>

#define CROAK_WRONG_TYPE(sv, expected, field) \
    croak("Expected %s for field '%s', but got %s", expected, upb_FieldDef_Name(field), sv_reftype(sv, TRUE))

static void verify_limits(pTHX_ SV* sv, const upb_FieldDef* f, double min, double max) {
    double val = SvNV(sv);
    if (val < min || val > max) {
        croak("Value %f out of range for field '%s' (type %d, limits %f to %f)",
              val, upb_FieldDef_Name(f), (int)upb_FieldDef_Type(f), min, max);
    }
}

static void verify_limits_64(pTHX_ SV* sv, const upb_FieldDef* f, bool is_signed) {
    if (SvROK(sv)) {
        if (sv_derived_from(sv, "Math::BigInt")) {
            if (!is_signed) {
                dSP; ENTER; SAVETMPS;
                PUSHMARK(SP); XPUSHs(sv); PUTBACK;
                call_method("is_neg", G_SCALAR);
                SPAGAIN; SV* neg_sv = POPs;
                bool is_neg = SvTRUE(neg_sv);
                PUTBACK; FREETMPS; LEAVE;
                if (is_neg) {
                    croak("Negative BigInt out of range for unsigned field '%s'", upb_FieldDef_Name(f));
                }
            }
            return;
        }
        CROAK_WRONG_TYPE(sv, is_signed ? "a 64-bit Integer" : "an Unsigned 64-bit Integer", f);
    }
    if (SvUOK(sv)) {
        if (is_signed && SvUV(sv) > (UV)INT64_MAX) {
            croak("Value %" UVuf " out of range for signed 64-bit field '%s'", SvUV(sv), upb_FieldDef_Name(f));
        }
        return;
    }
    if (SvIOK(sv)) {
        if (!is_signed && SvIV(sv) < 0) {
            croak("Value %" IVdf " out of range for unsigned field '%s'", SvIV(sv), upb_FieldDef_Name(f));
        }
        return;
    }
    if (SvNOK(sv)) {
        double nv = SvNV(sv);
        if (!is_signed && nv < 0) {
            croak("Value %f out of range for unsigned field '%s'", nv, upb_FieldDef_Name(f));
        }
        return;
    }
    if (SvPOK(sv) && looks_like_number(sv)) {
        STRLEN len = 0;
        const char* s = SvPV(sv, len);
        while (*s && isspace((unsigned char)*s)) s++;
        if (!is_signed && *s == '-') {
            croak("Negative string '%s' out of range for unsigned field '%s'", s, upb_FieldDef_Name(f));
        }
        errno = 0;
        char* endptr = NULL;
        if (is_signed) {
            (void)strtoll(s, &endptr, 10);
        } else {
            (void)strtoull(s, &endptr, 10);
        }
        while (endptr && *endptr && isspace((unsigned char)*endptr)) endptr++;
        if (errno == ERANGE || (endptr && *endptr != '\0' && *endptr != '.' && *endptr != 'e' && *endptr != 'E')) {
            croak("Value '%s' out of range or invalid for 64-bit field '%s'", s, upb_FieldDef_Name(f));
        }
        return;
    }
    CROAK_WRONG_TYPE(sv, is_signed ? "a 64-bit Integer" : "an Unsigned 64-bit Integer", f);
}

static bool convert_singular_sv_to_upb(pTHX_ SV *sv, const upb_FieldDef *f, upb_MessageValue *val, upb_Arena *arena) {
    upb_FieldType type = upb_FieldDef_Type(f);
    switch (type) {
        case kUpb_FieldType_Int32:
        case kUpb_FieldType_SInt32:
        case kUpb_FieldType_SFixed32:
            if (SvIOK(sv) || SvNOK(sv) || (SvPOK(sv) && looks_like_number(sv))) {
                verify_limits(aTHX_ sv, f, INT32_MIN, INT32_MAX);
                val->int32_val = (int32_t)SvIV(sv);
                return true;
            }
            CROAK_WRONG_TYPE(sv, "an Integer", f);
            return false;
        case kUpb_FieldType_String: {
            if (!SvPOK(sv)) CROAK_WRONG_TYPE(sv, "a String", f);
            STRLEN len;
            // Decode as UTF-8
            const char *ptr = SvPVutf8(sv, len);
            char *new_ptr = (char *)upb_Arena_Malloc(arena, len);
            if (!new_ptr) croak("Arena allocation failed for string");
            memcpy(new_ptr, ptr, len);
            val->str_val = upb_StringView_FromDataAndSize(new_ptr, len);
            return true;
        }
        case kUpb_FieldType_Bytes: {
            if (!SvPOK(sv)) CROAK_WRONG_TYPE(sv, "a Bytes", f);
            STRLEN len;
            // Treat as bytes
            const char *ptr = SvPVbyte(sv, len);
            char *new_ptr = (char *)upb_Arena_Malloc(arena, len);
            if (!new_ptr) croak("Arena allocation failed for bytes");
            memcpy(new_ptr, ptr, len);
            val->str_val = upb_StringView_FromDataAndSize(new_ptr, len);
            return true;
        }
        case kUpb_FieldType_Bool:
            val->bool_val = SvTRUE(sv);
            return true;
        case kUpb_FieldType_Float:
            if (SvNOK(sv) || SvIOK(sv) || (SvPOK(sv) && looks_like_number(sv))) {
                verify_limits(aTHX_ sv, f, -3.402823466e+38, 3.402823466e+38);
                val->float_val = (float)SvNV(sv);
                return true;
            }
            CROAK_WRONG_TYPE(sv, "a Number", f);
            return false;
        case kUpb_FieldType_Double:
            if (SvNOK(sv) || SvIOK(sv) || (SvPOK(sv) && looks_like_number(sv))) {
                // Double has huge range, but let's be consistent.
                val->double_val = SvNV(sv);
                return true;
            }
            CROAK_WRONG_TYPE(sv, "a Number", f);
            return false;
        case kUpb_FieldType_UInt32:
        case kUpb_FieldType_Fixed32: {
            if (SvUOK(sv) || SvIOK(sv) || SvNOK(sv) || (SvPOK(sv) && looks_like_number(sv))) {
                verify_limits(aTHX_ sv, f, 0, UINT32_MAX);
                UV uv = SvUV(sv);
                val->uint32_val = (uint32_t)uv;
                return true;
            }
            CROAK_WRONG_TYPE(sv, "an Unsigned Integer", f);
            return false;
        }
        case kUpb_FieldType_Int64:
        case kUpb_FieldType_SInt64:
        case kUpb_FieldType_SFixed64:
            verify_limits_64(aTHX_ sv, f, true);
            val->int64_val = PerlUpb_SVToI64(aTHX_ sv);
            return true;
        case kUpb_FieldType_UInt64:
        case kUpb_FieldType_Fixed64: {
            verify_limits_64(aTHX_ sv, f, false);
            val->uint64_val = PerlUpb_SVToU64(aTHX_ sv);
            return true;
        }
        case kUpb_FieldType_Enum:
            if (SvIOK(sv)) {
                val->int32_val = SvIV(sv);
                return true;
            } else if (SvPOK(sv)) {
                STRLEN len;
                const char *name = SvPVutf8(sv, len);
                const upb_EnumDef *edef = upb_FieldDef_EnumSubDef(f);
                if (!edef) croak("Missing EnumDef for field '%s'", upb_FieldDef_Name(f));

                const upb_EnumValueDef *ev = upb_EnumDef_FindValueByNameWithSize(edef, name, len);
                if (!ev) {
                    croak("Invalid enum name '%s' for field '%s'", name, upb_FieldDef_Name(f));
                }
                val->int32_val = upb_EnumValueDef_Number(ev);
                return true;
            } else {
                CROAK_WRONG_TYPE(sv, "an Integer or Enum Name", f);
            }
            return true;
        case kUpb_FieldType_Message:
        case kUpb_FieldType_Group: {
             const upb_MessageDef* target_mdef = upb_FieldDef_MessageSubDef(f);
             const upb_MiniTable* mt = upb_MessageDef_MiniTable(target_mdef);

             if (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV && !sv_isobject(sv)) {
                 // It's a plain HashRef, recursively create and populate message
                 upb_Message* dst_msg = upb_Message_New(mt, arena);
                 if (!dst_msg) croak("Arena allocation failed for submessage");

                 HV* hv = (HV*)SvRV(sv);
                 HE* he;
                 hv_iterinit(hv);
                 while ((he = hv_iternext(hv))) {
                     I32 klen;
                     const char *key = hv_iterkey(he, &klen);
                     SV *val_sv = hv_iterval(hv, he);

                     const upb_FieldDef *sub_f = upb_MessageDef_FindFieldByName(target_mdef, key);
                     if (!sub_f) {
                         croak("Field '%s' not found in message '%s'", key, upb_MessageDef_FullName(target_mdef));
                     }

                     upb_MessageValue sub_val;
                     if (PerlUpb_SvToUpb(aTHX_ val_sv, sub_f, &sub_val, arena)) {
                         upb_Message_SetFieldByDef(dst_msg, sub_f, sub_val, arena);
                     }
                 }
                 val->msg_val = dst_msg;
                 return true;
             }

             const upb_Message* src_msg = PerlUpb_Message_GetMsg(aTHX_ sv);
             if (!src_msg) CROAK_WRONG_TYPE(sv, "a Message object or HashRef", f);

             const upb_MessageDef* src_mdef = PerlUpb_Message_GetDef(aTHX_ sv);
             if (src_mdef != target_mdef) {
                 croak("Message type mismatch for field '%s': expected %s, got %s",
                       upb_FieldDef_Name(f), upb_MessageDef_FullName(target_mdef),
                       src_mdef ? upb_MessageDef_FullName(src_mdef) : "unknown");
             }

             upb_Message* dst_msg = upb_Message_New(mt, arena);
             if (!dst_msg) croak("Arena allocation failed for deep copy");
             if (!upb_Message_DeepCopy(dst_msg, src_msg, mt, arena)) {
                 croak("Deep copy of message failed");
             }
             val->msg_val = dst_msg;
             return true;
        }
        default:
            croak("Unknown upb field type: %d", type);
            return false;
    }
    return false;
}


bool PerlUpb_SvToUpb_Element(pTHX_ SV *sv, const upb_FieldDef *f, upb_MessageValue *val, upb_Arena *arena) {
    if (!f || !val || !arena) return false;
    return convert_singular_sv_to_upb(aTHX_ sv, f, val, arena);
}

// VPP-style Batch Conversion from SVs to raw C types (with full type/range/enum validation)
void PerlUpb_SvToUpb_BatchRaw(pTHX_ SV **src, upb_FieldType type, void *dst, size_t count, const upb_FieldDef *f, upb_Arena *arena) {
    size_t i = 0;
    switch (type) {
        case kUpb_FieldType_Bool: {
            bool *d = (bool*)dst;
            for (; i < count; i++) {
                if (!SvOK(src[i])) croak("Cannot convert undef to non-message type for field '%s'", upb_FieldDef_Name(f));
                d[i] = SvTRUE(src[i]);
            }
            break;
        }
        case kUpb_FieldType_Int32:
        case kUpb_FieldType_SInt32:
        case kUpb_FieldType_SFixed32: {
            int32_t *d = (int32_t*)dst;
            for (; i < count; i++) {
                SV* sv = src[i];
                if (!SvOK(sv)) croak("Cannot convert undef to non-message type for field '%s'", upb_FieldDef_Name(f));
                if (SvIOK(sv) || SvNOK(sv) || (SvPOK(sv) && looks_like_number(sv))) {
                    verify_limits(aTHX_ sv, f, INT32_MIN, INT32_MAX);
                    d[i] = (int32_t)SvIV(sv);
                } else {
                    CROAK_WRONG_TYPE(sv, "an Integer", f);
                }
            }
            break;
        }
        case kUpb_FieldType_Enum: {
            int32_t *d = (int32_t*)dst;
            for (; i < count; i++) {
                upb_MessageValue elem_val;
                if (!SvOK(src[i])) croak("Cannot convert undef to non-message type for field '%s'", upb_FieldDef_Name(f));
                convert_singular_sv_to_upb(aTHX_ src[i], f, &elem_val, arena);
                d[i] = elem_val.int32_val;
            }
            break;
        }
        case kUpb_FieldType_UInt32:
        case kUpb_FieldType_Fixed32: {
            uint32_t *d = (uint32_t*)dst;
            for (; i < count; i++) {
                SV* sv = src[i];
                if (!SvOK(sv)) croak("Cannot convert undef to non-message type for field '%s'", upb_FieldDef_Name(f));
                if (SvUOK(sv) || SvIOK(sv) || SvNOK(sv) || (SvPOK(sv) && looks_like_number(sv))) {
                    verify_limits(aTHX_ sv, f, 0, UINT32_MAX);
                    d[i] = (uint32_t)SvUV(sv);
                } else {
                    CROAK_WRONG_TYPE(sv, "an Unsigned Integer", f);
                }
            }
            break;
        }
        case kUpb_FieldType_Float: {
            float *d = (float*)dst;
            for (; i < count; i++) {
                SV* sv = src[i];
                if (!SvOK(sv)) croak("Cannot convert undef to non-message type for field '%s'", upb_FieldDef_Name(f));
                if (SvNOK(sv) || SvIOK(sv) || (SvPOK(sv) && looks_like_number(sv))) {
                    verify_limits(aTHX_ sv, f, -3.402823466e+38, 3.402823466e+38);
                    d[i] = (float)SvNV(sv);
                } else {
                    CROAK_WRONG_TYPE(sv, "a Number", f);
                }
            }
            break;
        }
        case kUpb_FieldType_Double: {
            double *d = (double*)dst;
            for (; i < count; i++) {
                SV* sv = src[i];
                if (!SvOK(sv)) croak("Cannot convert undef to non-message type for field '%s'", upb_FieldDef_Name(f));
                if (SvNOK(sv) || SvIOK(sv) || (SvPOK(sv) && looks_like_number(sv))) {
                    d[i] = (double)SvNV(sv);
                } else {
                    CROAK_WRONG_TYPE(sv, "a Number", f);
                }
            }
            break;
        }
        case kUpb_FieldType_Int64:
        case kUpb_FieldType_SInt64:
        case kUpb_FieldType_SFixed64: {
            int64_t *d = (int64_t*)dst;
            for (; i < count; i++) {
                SV* sv = src[i];
                if (!SvOK(sv)) croak("Cannot convert undef to non-message type for field '%s'", upb_FieldDef_Name(f));
                verify_limits_64(aTHX_ sv, f, true);
                d[i] = PerlUpb_SVToI64(aTHX_ sv);
            }
            break;
        }
        case kUpb_FieldType_UInt64:
        case kUpb_FieldType_Fixed64: {
            uint64_t *d = (uint64_t*)dst;
            for (; i < count; i++) {
                SV* sv = src[i];
                if (!SvOK(sv)) croak("Cannot convert undef to non-message type for field '%s'", upb_FieldDef_Name(f));
                verify_limits_64(aTHX_ sv, f, false);
                d[i] = PerlUpb_SVToU64(aTHX_ sv);
            }
            break;
        }
        default:
            croak("PerlUpb_SvToUpb_BatchRaw: Unsupported type %d for fast-path", type);
    }
}

bool PerlUpb_SvToUpb(pTHX_ SV *sv, const upb_FieldDef *f, upb_MessageValue *val, upb_Arena *arena) {
    if (!f || !val || !arena) return false;

    if (!SvOK(sv)) {
        croak("Cannot convert undef to non-message type for field '%s'", upb_FieldDef_Name(f));
        return false;
    }

    if (upb_FieldDef_IsRepeated(f)) {
        if (!SvROK(sv)) {
            CROAK_WRONG_TYPE(sv, "a Reference", f);
            return false;
        }

        if (upb_FieldDef_IsMap(f)) {
            if (SvTYPE(SvRV(sv)) != SVt_PVHV) {
                CROAK_WRONG_TYPE(sv, "a Hash Reference", f);
                return false;
            }
            HV* hv = (HV*)SvRV(sv);
            SV* tied_obj = NULL;
            MAGIC* mg = mg_find((SV*)hv, PERL_MAGIC_tied);
            if (mg) {
                tied_obj = SvTIED_obj((SV*)hv, mg);
                if (tied_obj && sv_derived_from(tied_obj, "Protobuf::Internal::Map")) {
                    upb_Map* src_map = PerlUpb_Map_GetMapPtr(aTHX_ tied_obj);
                    const upb_FieldDef* src_f = PerlUpb_Map_GetFieldDef(aTHX_ tied_obj);
                    if (src_map) {
                        if (upb_FieldDef_Type(src_f) != upb_FieldDef_Type(f)) {
                            croak("Type mismatch when copying map field");
                        }

                        const upb_MessageDef* entry_def = upb_FieldDef_MessageSubDef(f);
                        const upb_FieldDef* key_f = upb_MessageDef_FindFieldByNumber(entry_def, 1);
                        const upb_FieldDef* val_f = upb_MessageDef_FindFieldByNumber(entry_def, 2);

                        // Perform deep copy
                        upb_Map* dst_map = upb_Map_New(arena, upb_FieldDef_CType(key_f), upb_FieldDef_CType(val_f));
                        size_t iter = kUpb_Map_Begin;
                        upb_MessageValue k, v;
                        const upb_MiniTable* val_mt = upb_FieldDef_IsSubMessage(val_f) ? upb_MessageDef_MiniTable(upb_FieldDef_MessageSubDef(val_f)) : NULL;

                        while (upb_Map_Next(src_map, &k, &v, &iter)) {
                            if (val_mt) {
                                upb_Message* dst_v = upb_Message_New(val_mt, arena);
                                if (!dst_v) croak("Arena allocation failed for map value message");
                                if (!upb_Message_DeepCopy(dst_v, v.msg_val, val_mt, arena)) {
                                    croak("Deep copy of map value message failed");
                                }
                                v.msg_val = dst_v;
                            }
                            upb_Map_Set(dst_map, k, v, arena);
                        }
                        val->map_val = dst_map;
                        return true;
                    }
                }
            }

            // Fallback: iterate over Perl hash
            const upb_MessageDef* entry_def = upb_FieldDef_MessageSubDef(f);
            const upb_FieldDef* key_f = upb_MessageDef_FindFieldByNumber(entry_def, 1);
            const upb_FieldDef* val_f = upb_MessageDef_FindFieldByNumber(entry_def, 2);
            upb_Map* dst_map = upb_Map_New(arena, upb_FieldDef_CType(key_f), upb_FieldDef_CType(val_f));
            if (!dst_map) croak("Arena allocation failed for map");

            hv_iterinit(hv);
            HE* he;
            while ((he = hv_iternext(hv))) {
                SV* key_sv = hv_iterkeysv(he);
                SV* val_sv = hv_iterval(hv, he);
                bool did_enter = false;

                if (mg && (!val_sv || !SvOK(val_sv))) {
                    dSP; ENTER; SAVETMPS; PUSHMARK(SP);
                    did_enter = true;
                    XPUSHs(tied_obj); XPUSHs(sv_2mortal(newSVsv(key_sv))); PUTBACK;
                    call_method("FETCH", G_SCALAR);
                    SPAGAIN; val_sv = POPs; PUTBACK;
                }

                upb_MessageValue k, v;
                bool ok = convert_singular_sv_to_upb(aTHX_ key_sv, key_f, &k, arena) &&
                          convert_singular_sv_to_upb(aTHX_ val_sv, val_f, &v, arena);
                if (did_enter) { FREETMPS; LEAVE; }
                if (!ok) return false;
                upb_Map_Set(dst_map, k, v, arena);
            }
            val->map_val = dst_map;
            return true;
        }

        if (SvTYPE(SvRV(sv)) != SVt_PVAV) {
            CROAK_WRONG_TYPE(sv, "an Array Reference", f);
            return false;
        }
        AV *av = (AV*)SvRV(sv);
        SV* tied_obj = NULL;
        MAGIC* mg = mg_find((SV*)av, PERL_MAGIC_tied);

        if (mg) {
            tied_obj = SvTIED_obj((SV*)av, mg);
            if (tied_obj && sv_derived_from(tied_obj, "Protobuf::Internal::Repeated")) {
                upb_Array* src_arr = PerlUpb_Repeated_GetArray(aTHX_ tied_obj);
                const upb_FieldDef* src_f = PerlUpb_Repeated_GetFieldDef(aTHX_ tied_obj);

                if (src_arr) {
                    if (upb_FieldDef_Type(src_f) != upb_FieldDef_Type(f)) {
                        croak("Type mismatch when copying repeated field '%s': expected %d, got %d",
                              upb_FieldDef_Name(f), upb_FieldDef_Type(f), upb_FieldDef_Type(src_f));
                    }

                    size_t n = upb_Array_Size(src_arr);
                    upb_Array* dst_arr = upb_Array_New(arena, upb_FieldDef_CType(f));
                    if (!upb_Array_Resize(dst_arr, n, arena)) croak("Failed to resize destination array");

                    for (size_t i = 0; i < n; i++) {
                        upb_MessageValue item = upb_Array_Get(src_arr, i);
                        if (upb_FieldDef_IsSubMessage(f)) {
                            const upb_MessageDef* mdef = upb_FieldDef_MessageSubDef(f);
                            const upb_MiniTable* mt = upb_MessageDef_MiniTable(mdef);
                            upb_Message* dst_msg = upb_Message_New(mt, arena);
                            if (!dst_msg) croak("Arena allocation failed for repeated message element %zu", i);
                            if (!upb_Message_DeepCopy(dst_msg, item.msg_val, mt, arena)) {
                                croak("Failed to deep copy message element %zu", i);
                            }
                            item.msg_val = dst_msg;
                        }
                        upb_Array_Set(dst_arr, i, item);
                    }
                    val->array_val = dst_arr;
                    return true;
                }
            }
        }

        I32 max_idx = av_len(av);
        size_t num_elements = max_idx + 1;

        upb_CType ctype = upb_FieldDef_CType(f);
        if (!arena) {
            warn("PerlUpb_SvToUpb: arena is NULL but needed for repeated field '%s'\n", upb_FieldDef_Name(f));
            return false;
        }
        upb_Array *arr = upb_Array_New(arena, ctype);
        if (!arr) {
            croak("Failed to create upb_Array for field '%s'", upb_FieldDef_Name(f));
            return false;
        }

        if (!upb_Array_Resize(arr, num_elements, arena)) {
            croak("Failed to resize upb_Array for field '%s'", upb_FieldDef_Name(f));
            return false;
        }

        if (!mg && !upb_FieldDef_IsSubMessage(f) && upb_FieldDef_Type(f) != kUpb_FieldType_String && upb_FieldDef_Type(f) != kUpb_FieldType_Bytes) {
            SV **src = (SV**)safemalloc(num_elements * sizeof(SV*));
            for (size_t i = 0; i < num_elements; i++) {
                SV **svp = av_fetch(av, (I32)i, 0);
                src[i] = (svp) ? *svp : &PL_sv_undef;
            }
            void *dst = upb_Array_MutableDataPtr(arr);
            PerlUpb_SvToUpb_BatchRaw(aTHX_ src, upb_FieldDef_Type(f), dst, num_elements, f, arena);
            safefree(src);
        } else {
            for (I32 i = 0; i < (I32)num_elements; ++i) {
                SV **elem_sv_ptr = av_fetch(av, i, 0);
                SV *elem_sv = (elem_sv_ptr) ? *elem_sv_ptr : NULL;
                bool did_enter = false;

                if (mg && (!elem_sv || !SvOK(elem_sv))) {
                    dSP; ENTER; SAVETMPS; PUSHMARK(SP);
                    did_enter = true;
                    XPUSHs(tied_obj); XPUSHs(sv_2mortal(newSViv(i))); PUTBACK;
                    call_method("FETCH", G_SCALAR);
                    SPAGAIN; elem_sv = POPs; PUTBACK;
                }

                if (!elem_sv) {
                    if (did_enter) { FREETMPS; LEAVE; }
                    croak("Error fetching element %d from array for field '%s'", (int)i, upb_FieldDef_Name(f));
                    return false;
                }

                upb_MessageValue item_val;
                bool ok = convert_singular_sv_to_upb(aTHX_ elem_sv, f, &item_val, arena);
                if (did_enter) { FREETMPS; LEAVE; }
                if (!ok) return false;
                upb_Array_Set(arr, i, item_val);
            }
        }
        val->array_val = arr;
        return true;
    } else {
        return convert_singular_sv_to_upb(aTHX_ sv, f, val, arena);
    }
}

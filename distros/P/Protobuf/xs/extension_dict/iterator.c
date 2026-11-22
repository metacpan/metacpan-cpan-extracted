#define PERL_NO_GET_CONTEXT
#include <sys/types.h>
#include <setjmp.h>
#include <stdlib.h>

#include "xs/extension_dict/iterator.h"
#include "xs/extension_dict/dict.h"
#include "xs/protobuf/message.h"
#include "xs/descriptor/field.h"
#include "xs/descriptor/file.h"
#include "upb/reflection/message.h"

typedef struct {
    SV* message_sv;
    size_t iter;
} PerlUpb_ExtensionDictIterator;

static int extension_dict_iter_cleanup(pTHX_ SV* sv, MAGIC* mg) {
    PerlUpb_ExtensionDictIterator* iter = (PerlUpb_ExtensionDictIterator*)mg->mg_ptr;
    if (iter) {
        mg->mg_ptr = NULL;
        if (!PL_dirty && iter->message_sv) {
            SvREFCNT_dec(iter->message_sv);
        }
        safefree(iter);
    }
    return 0;
}

static MGVTBL extension_dict_iter_vtbl = {
    NULL, NULL, NULL, NULL, extension_dict_iter_cleanup
};

SV* PerlUpb_ExtensionDict_GetIterator(pTHX_ SV* dict_sv) {
    SV* message_sv = PerlUpb_ExtensionDict_GetMessageSV(aTHX_ dict_sv);
    if (!message_sv) return &PL_sv_undef;

    PerlUpb_ExtensionDictIterator* iter = (PerlUpb_ExtensionDictIterator*)safemalloc(sizeof(PerlUpb_ExtensionDictIterator));
    iter->message_sv = newSVsv(message_sv);
    iter->iter = kUpb_Message_Begin;

    SV* sv = newSViv(PTR2IV(iter));
    sv_magicext(sv, NULL, PERL_MAGIC_ext, &extension_dict_iter_vtbl, (const char*)iter, 0);
    SV* obj = newRV_noinc(sv);
    sv_bless(obj, gv_stashpv("Protobuf::ExtensionDictIterator", GV_ADD));
    return obj;
}

static PerlUpb_ExtensionDictIterator* GetIter(pTHX_ SV* sv) {
    if (!sv || !SvROK(sv) || !sv_derived_from(sv, "Protobuf::ExtensionDictIterator")) {
        return NULL;
    }
    MAGIC* mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &extension_dict_iter_vtbl);
    return (mg && mg->mg_ptr) ? (PerlUpb_ExtensionDictIterator*)mg->mg_ptr : NULL;
}

SV* PerlUpb_ExtensionDict_Iterator_Next(pTHX_ SV* self) {
    PerlUpb_ExtensionDictIterator* iter = GetIter(aTHX_ self);
    if (!iter) return &PL_sv_undef;

    const upb_Message* msg = PerlUpb_Message_GetMsg(aTHX_ iter->message_sv);
    if (!msg) return &PL_sv_undef;

    const upb_MessageDef* mdef = PerlUpb_Message_GetDef(aTHX_ iter->message_sv);
    const upb_DefPool* pool = upb_FileDef_Pool(upb_MessageDef_File(mdef));

    const upb_FieldDef* f;
    upb_MessageValue val;

    while (upb_Message_Next(msg, mdef, pool, &f, &val, &iter->iter)) {
        if (upb_FieldDef_IsExtension(f)) {
            return PerlUpb_FieldDef_GetWrapper(aTHX_ f);
        }
    }

    return &PL_sv_undef;
}

void PerlUpb_ExtensionDictIterator_Free(pTHX_ SV* sv) {
    if (PL_dirty || !sv || !SvROK(sv) || !sv_derived_from(sv, "Protobuf::ExtensionDictIterator")) return;
    MAGIC* mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &extension_dict_iter_vtbl);
    if (mg && mg->mg_ptr) {
        PerlUpb_ExtensionDictIterator* iter = (PerlUpb_ExtensionDictIterator*)mg->mg_ptr;
        mg->mg_ptr = NULL;
        if (iter->message_sv) SvREFCNT_dec(iter->message_sv);
        safefree(iter);
        sv_setiv(SvRV(sv), 0);
    }
}

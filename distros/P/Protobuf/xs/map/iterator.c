#define PERL_NO_GET_CONTEXT
#include <sys/types.h>
#include <setjmp.h>
#include <stdlib.h>

#include "xs/map/iterator.h"
#include "xs/map/map.h"
#include "xs/convert.h"
#include "upb/message/map.h"

typedef struct {
    SV* map_sv;
    size_t iter;
    upb_MessageValue key;
    upb_MessageValue val;
} PerlUpb_MapIterator;

static int map_iter_cleanup(pTHX_ SV* sv, MAGIC* mg) {
    PerlUpb_MapIterator* iter = (PerlUpb_MapIterator*)mg->mg_ptr;
    if (iter) {
        mg->mg_ptr = NULL;
        if (!PL_dirty && iter->map_sv) {
            SvREFCNT_dec(iter->map_sv);
        }
        safefree(iter);
    }
    return 0;
}

static MGVTBL map_iter_vtbl = {
    NULL, NULL, NULL, NULL, map_iter_cleanup
};

SV* PerlUpb_Map_GetIterator(pTHX_ SV* map_sv) {
    PerlUpb_MapIterator* iter = (PerlUpb_MapIterator*)safemalloc(sizeof(PerlUpb_MapIterator));
    memset(iter, 0, sizeof(PerlUpb_MapIterator));
    iter->map_sv = newSVsv(map_sv);
    iter->iter = kUpb_Map_Begin;

    SV* sv = newSViv(PTR2IV(iter));
    sv_magicext(sv, NULL, PERL_MAGIC_ext, &map_iter_vtbl, (const char*)iter, 0);
    SV* obj = newRV_noinc(sv);
    sv_bless(obj, gv_stashpv("Protobuf::Internal::MapIterator", GV_ADD));
    return obj;
}

static PerlUpb_MapIterator* GetIter(pTHX_ SV* sv) {
    if (!sv || !SvROK(sv) || !sv_derived_from(sv, "Protobuf::Internal::MapIterator")) {
        return NULL;
    }
    MAGIC* mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &map_iter_vtbl);
    return (mg && mg->mg_ptr) ? (PerlUpb_MapIterator*)mg->mg_ptr : NULL;
}

SV* PerlUpb_Map_Iterator_NextKey(pTHX_ SV* self) {
    PerlUpb_MapIterator* iter = GetIter(aTHX_ self);
    if (!iter) return &PL_sv_undef;

    upb_Map* map = PerlUpb_Map_GetMapPtr(aTHX_ iter->map_sv);
    if (!map) return &PL_sv_undef;

    if (upb_Map_Next(map, &iter->key, &iter->val, &iter->iter)) {
        const upb_FieldDef* f = PerlUpb_Map_GetFieldDef(aTHX_ iter->map_sv);
        const upb_MessageDef* entry_def = upb_FieldDef_MessageSubDef(f);
        const upb_FieldDef* key_f = upb_MessageDef_FindFieldByNumber(entry_def, 1);

        // Pass NULL for arena as keys are returned as new SVs
        return PerlUpb_UpbToSv_Element(aTHX_ &iter->key, key_f, NULL);
    }

    return &PL_sv_undef;
}

SV* PerlUpb_Map_Iterator_Value(pTHX_ SV* self) {
    PerlUpb_MapIterator* iter = GetIter(aTHX_ self);
    if (!iter) return &PL_sv_undef;

    const upb_FieldDef* f = PerlUpb_Map_GetFieldDef(aTHX_ iter->map_sv);
    const upb_MessageDef* entry_def = upb_FieldDef_MessageSubDef(f);
    const upb_FieldDef* val_f = upb_MessageDef_FindFieldByNumber(entry_def, 2);
    SV* arena_sv = PerlUpb_Map_GetArenaSV(aTHX_ iter->map_sv);

    return PerlUpb_UpbToSv_Element(aTHX_ &iter->val, val_f, arena_sv);
}

void PerlUpb_MapIterator_Free(pTHX_ SV* sv) {
    if (PL_dirty || !sv || !SvROK(sv) || !sv_derived_from(sv, "Protobuf::Internal::MapIterator")) return;
    MAGIC* mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &map_iter_vtbl);
    if (mg && mg->mg_ptr) {
        PerlUpb_MapIterator* iter = (PerlUpb_MapIterator*)mg->mg_ptr;
        mg->mg_ptr = NULL;
        if (iter->map_sv) SvREFCNT_dec(iter->map_sv);
        safefree(iter);
        sv_setiv(SvRV(sv), 0);
    }
}

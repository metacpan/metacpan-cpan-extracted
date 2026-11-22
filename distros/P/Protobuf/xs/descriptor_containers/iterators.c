#define PERL_NO_GET_CONTEXT
#include <sys/types.h>
#include <setjmp.h>
#include <stdlib.h>

#include "xs/descriptor_containers/iterators.h"
#include "xs/descriptor_containers/by_name_map.h"
#include "xs/descriptor_containers/by_number_map.h"

static int desc_map_iter_cleanup(pTHX_ SV* sv, MAGIC* mg) {
    PerlUpb_DescriptorMapIterator* iter = (PerlUpb_DescriptorMapIterator*)mg->mg_ptr;
    if (iter) {
        mg->mg_ptr = NULL;
        if (!PL_dirty && iter->container_sv) {
            SvREFCNT_dec(iter->container_sv);
        }
        safefree(iter);
    }
    return 0;
}

static MGVTBL desc_map_iter_vtbl = {
    NULL, NULL, NULL, NULL, desc_map_iter_cleanup
};

SV* PerlUpb_DescriptorMapIterator_New(pTHX_ SV* container_sv) {
    PerlUpb_DescriptorMapIterator* iter = (PerlUpb_DescriptorMapIterator*)safemalloc(sizeof(PerlUpb_DescriptorMapIterator));
    iter->container_sv = newSVsv(container_sv);
    iter->index = 0;

    SV* sv = newSViv(PTR2IV(iter));
    sv_magicext(sv, NULL, PERL_MAGIC_ext, &desc_map_iter_vtbl, (const char*)iter, 0);
    SV* obj = newRV_noinc(sv);
    sv_bless(obj, gv_stashpv("Protobuf::Internals::DescriptorMapIterator", GV_ADD));
    return obj;
}

PerlUpb_DescriptorMapIterator* PerlUpb_DescriptorMapIterator_Get(pTHX_ SV* sv) {
    if (!sv || !SvROK(sv) || !sv_derived_from(sv, "Protobuf::Internals::DescriptorMapIterator")) {
        return NULL;
    }
    MAGIC* mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &desc_map_iter_vtbl);
    return (mg && mg->mg_ptr) ? (PerlUpb_DescriptorMapIterator*)mg->mg_ptr : NULL;
}

SV* PerlUpb_DescriptorMapIterator_NextKey(pTHX_ SV* self) {
    PerlUpb_DescriptorMapIterator* iter = PerlUpb_DescriptorMapIterator_Get(aTHX_ self);
    if (!iter) return &PL_sv_undef;

    // Try ByNameMap first
    PerlUpb_ByNameMap* name_map = PerlUpb_ByNameMap_Get(aTHX_ iter->container_sv);
    if (name_map) {
        if (iter->index >= name_map->vtable->count(name_map->parent)) {
            return &PL_sv_undef;
        }
        return PerlUpb_ByNameMap_Key(aTHX_ iter->container_sv, iter->index++);
    }

    // Then ByNumberMap
    PerlUpb_ByNumberMap* num_map = PerlUpb_ByNumberMap_Get(aTHX_ iter->container_sv);
    if (num_map) {
        if (iter->index >= num_map->vtable->count(num_map->parent)) {
            return &PL_sv_undef;
        }
        return PerlUpb_ByNumberMap_Key(aTHX_ iter->container_sv, iter->index++);
    }

    return &PL_sv_undef;
}

// Similar for NextValue, but we don't increment index here
// The Perl layer would call NextKey, then NextValue for each 'each' iteration.
// Or we could have a 'Next' that returns both.
// For now, let's just make NextKey increment and have a separate GetValue for the CURRENT index.

SV* PerlUpb_DescriptorMapIterator_NextValue(pTHX_ SV* self) {
    PerlUpb_DescriptorMapIterator* iter = PerlUpb_DescriptorMapIterator_Get(aTHX_ self);
    if (!iter || iter->index == 0) return &PL_sv_undef;

    int current_index = iter->index - 1;

    PerlUpb_ByNameMap* name_map = PerlUpb_ByNameMap_Get(aTHX_ iter->container_sv);
    if (name_map) {
        return PerlUpb_ByNameMap_Value(aTHX_ iter->container_sv, current_index);
    }

    PerlUpb_ByNumberMap* num_map = PerlUpb_ByNumberMap_Get(aTHX_ iter->container_sv);
    if (num_map) {
        return PerlUpb_ByNumberMap_Value(aTHX_ iter->container_sv, current_index);
    }

    return &PL_sv_undef;
}

void PerlUpb_DescriptorMapIterator_Free(pTHX_ SV* sv) {
    if (PL_dirty || !sv || !SvROK(sv) || !sv_derived_from(sv, "Protobuf::Internals::DescriptorMapIterator")) return;
    MAGIC* mg = mg_findext(SvRV(sv), PERL_MAGIC_ext, &desc_map_iter_vtbl);
    if (mg && mg->mg_ptr) {
        PerlUpb_DescriptorMapIterator* iter = (PerlUpb_DescriptorMapIterator*)mg->mg_ptr;
        mg->mg_ptr = NULL;
        if (iter->container_sv) SvREFCNT_dec(iter->container_sv);
        safefree(iter);
        sv_setiv(SvRV(sv), 0);
    }
}

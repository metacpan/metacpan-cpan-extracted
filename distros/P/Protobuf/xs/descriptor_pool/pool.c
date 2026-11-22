#define PERL_NO_GET_CONTEXT
#include <sys/types.h>
#include <setjmp.h>
#include <stdlib.h>

#include "xs/descriptor_pool/pool.h"
#include "xs/protobuf/obj_cache.h"

typedef struct {
    upb_DefPool* pool;
    bool frozen;
    bool poisoned;
    bool owned;
} PerlUpb_DescriptorPool;

static upb_DefPool *generated_pool_ptr = NULL;

void* PerlUpb_DescriptorPool_CreateRaw(pTHX) {
    PerlUpb_DescriptorPool* p = (PerlUpb_DescriptorPool*)safemalloc(sizeof(PerlUpb_DescriptorPool));
    p->pool = upb_DefPool_New();
    p->frozen = false;
    p->poisoned = false;
    p->owned = true;
    if (!p->pool) {
        safefree(p);
        croak("Failed to create upb_DefPool");
    }
    return p;
}

void PerlUpb_DescriptorPool_DestroyRaw(pTHX_ void* ptr) {
    if (PL_dirty) return;
    PerlUpb_DescriptorPool* p = (PerlUpb_DescriptorPool*)ptr;
    if (p) {
        if (p->owned && p->pool && p->pool != generated_pool_ptr) {
            PerlUpb_ObjCache_Delete(aTHX_ p->pool);
            upb_DefPool_Free(p->pool);
        }
        safefree(p);
    }
}

static int pool_cleanup(pTHX_ SV* sv, MAGIC* mg) {
    if (PL_dirty) return 0;
    void* ptr = (void*)mg->mg_ptr;
    if (ptr) {
        mg->mg_ptr = NULL;
        PerlUpb_DescriptorPool_DestroyRaw(aTHX_ ptr);
    }
    return 0;
}

static MGVTBL pool_vtbl = {
    NULL, NULL, NULL, NULL, pool_cleanup
};

void PerlUpb_DescriptorPool_AttachMagic(pTHX_ SV* self, void* raw, bool owned) {
    if (!self || !SvROK(self) || !raw) return;
    SV* rv = SvRV(self);
    if (!rv || SvTYPE(rv) != SVt_PVHV) return;
    PerlUpb_DescriptorPool* p = (PerlUpb_DescriptorPool*)raw;
    p->owned = owned;
    MAGIC* mg = mg_findext(rv, PERL_MAGIC_ext, &pool_vtbl);
    if (mg) {
        mg->mg_ptr = (char*)raw;
    } else {
        sv_magicext(rv, NULL, PERL_MAGIC_ext, &pool_vtbl, (const char*)raw, 0);
    }
}

static inline PerlUpb_DescriptorPool* _get_wrapper_raw(pTHX_ SV* pool_sv) {
    if (!pool_sv || !SvROK(pool_sv) || !sv_isa(pool_sv, "Protobuf::DescriptorPool")) return NULL;
    SV* rv = SvRV(pool_sv);
    if (!rv || SvTYPE(rv) != SVt_PVHV) return NULL;
    MAGIC* mg = mg_findext(rv, PERL_MAGIC_ext, &pool_vtbl);
    if (!mg || !mg->mg_ptr) return NULL;
    return (PerlUpb_DescriptorPool*)mg->mg_ptr;
}

void PerlUpb_DescriptorPool_Freeze(pTHX_ SV* sv) {
    const upb_DefPool* pool = PerlUpb_DescriptorPool_GetPool(aTHX_ sv);
    if (pool) {
        PerlUpb_DescriptorPool* p = _get_wrapper_raw(aTHX_ sv);
        if (p) p->frozen = true;
    }
}

bool PerlUpb_DescriptorPool_IsFrozen(pTHX_ SV* sv) {
    const upb_DefPool* pool = PerlUpb_DescriptorPool_GetPool(aTHX_ sv);
    if (pool) {
        PerlUpb_DescriptorPool* p = _get_wrapper_raw(aTHX_ sv);
        return p ? p->frozen : false;
    }
    return false;
}

SV* PerlUpb_DescriptorPool_New(pTHX) {
    PerlUpb_DescriptorPool* raw = (PerlUpb_DescriptorPool*)PerlUpb_DescriptorPool_CreateRaw(aTHX);
    HV* hv = newHV();
    hv_store(hv, "_pool_ptr", 9, newSViv(PTR2IV(raw)), 0);
    sv_magicext((SV*)hv, NULL, PERL_MAGIC_ext, &pool_vtbl, (const char*)raw, 0);

    SV* obj = newRV_noinc((SV*)hv);
    sv_bless(obj, gv_stashpv("Protobuf::DescriptorPool", GV_ADD));

    PerlUpb_ObjCache_Add(aTHX_ raw->pool, obj);
    return obj;
}

SV* PerlUpb_DescriptorPool_GetWrapper(pTHX_ const upb_DefPool* pool) {
    if (!pool) return &PL_sv_undef;

    SV* cached = PerlUpb_ObjCache_Get(aTHX_ pool);
    if (cached) {
        return cached;
    }

    HV* hv = newHV();
    PerlUpb_DescriptorPool* p = (PerlUpb_DescriptorPool*)safemalloc(sizeof(PerlUpb_DescriptorPool));
    p->pool = (upb_DefPool*)pool;
    p->frozen = false;
    p->poisoned = false;
    p->owned = false;
    hv_store(hv, "_pool_ptr", 9, newSViv(PTR2IV(p)), 0);
    sv_magicext((SV*)hv, NULL, PERL_MAGIC_ext, &pool_vtbl, (const char*)p, 0);

    SV* obj = newRV_noinc((SV*)hv);
    sv_bless(obj, gv_stashpv("Protobuf::DescriptorPool", GV_ADD));

    PerlUpb_ObjCache_Add(aTHX_ pool, obj);
    return obj;
}

void PerlUpb_DescriptorPool_Poison(pTHX_ SV* pool_sv) {
    PerlUpb_DescriptorPool* p = _get_wrapper_raw(aTHX_ pool_sv);
    if (p) {
        p->poisoned = true;
    } else {
        croak("Failed to poison DescriptorPool: invalid wrapper object");
    }
}

upb_DefPool* PerlUpb_DescriptorPool_GetPool(pTHX_ SV* sv) {
    if (!sv || !SvROK(sv) || !sv_isa(sv, "Protobuf::DescriptorPool")) {
        croak("Argument is not a Protobuf::DescriptorPool object");
    }

    PerlUpb_DescriptorPool* p = _get_wrapper_raw(aTHX_ sv);
    if (!p) return NULL;
    if (p->poisoned) {
        croak("Integrity compromise: Pool used after failure");
    }
    return p->pool;
}

void PerlUpb_DescriptorPool_Free(pTHX_ SV* sv) {
    if (!sv || !SvROK(sv) || !sv_isa(sv, "Protobuf::DescriptorPool")) {
        return;
    }

    SV* rv = SvRV(sv);
    if (!rv || SvTYPE(rv) != SVt_PVHV) return;

    MAGIC* mg = mg_findext(rv, PERL_MAGIC_ext, &pool_vtbl);
    if (mg && mg->mg_ptr) {
        void* ptr = (void*)mg->mg_ptr;
        mg->mg_ptr = NULL;
        PerlUpb_DescriptorPool_DestroyRaw(aTHX_ ptr);
        SV** svp = hv_fetch((HV*)rv, "_pool_ptr", 9, 0);
        if (svp) sv_setiv(*svp, 0);
    }
}

const upb_DefPool* PerlUpb_DescriptorPool_GetPoolRaw(pTHX_ void* ptr) {
    PerlUpb_DescriptorPool* p = (PerlUpb_DescriptorPool*)ptr;
    return p ? p->pool : NULL;
}

#include "xs/descriptor/file.h"

int PerlUpb_DescriptorPool_FileCount(pTHX_ SV* sv) {
    // upb doesn't easily expose the number of files in a pool without iterating.
    // For now, return 0 or implement a basic tracking if needed.
    // Actually, in our TestHelpers, we only load one set.
    return 0;
}

SV* PerlUpb_DescriptorPool_GetFile(pTHX_ SV* sv, int index) {
    return &PL_sv_undef;
}

#include <unistd.h>

static pid_t generated_pool_pid = 0;

SV* PerlUpb_DescriptorPool_GeneratedPool(pTHX) {

    pid_t current_pid = getpid();
    if (generated_pool_pid != current_pid) {
        generated_pool_ptr = NULL;
        generated_pool_pid = current_pid;
    }
    if (!generated_pool_ptr) {
        SV* global_pool_sv = get_sv("Protobuf::DescriptorPool::_generated_pool_ptr", GV_ADD);
        if (SvIOK(global_pool_sv) && generated_pool_pid == current_pid) {
            generated_pool_ptr = INT2PTR(upb_DefPool*, SvIV(global_pool_sv));
        } else {
            generated_pool_ptr = upb_DefPool_New();
            sv_setiv(global_pool_sv, PTR2IV(generated_pool_ptr));
            sv_magicext(global_pool_sv, NULL, PERL_MAGIC_ext, NULL, (const char*)NULL, 0);
        }
    }
    return PerlUpb_DescriptorPool_GetWrapper(aTHX_ generated_pool_ptr);
}


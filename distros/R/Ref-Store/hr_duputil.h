#ifndef HR_DUPUTIL_H_
#define HR_DUPUTIL_H_
#include "hreg.h"
#undef NDEBUG
#include <assert.h>

enum {
    HRK_DUP_WEAK_ENCAP = 1 << 0,
    HRK_DUP_WEAK_VALUE = 1 << 1
};

#define HR_DUPKEY_OLD_LOOKUPS "__XS_OLD_LOOKUPS:"

#define HR_DUPKEY_KENCAP "__XS_KENCAP:"
#define HR_DUPKEY_AENCAP "__XS_AENCAP:"
#define HR_DUPKEY_VHASH  "__XS_V2VI:"

typedef struct {
    void *vhash;
    int flags;
} HR_Dup_Kinfo;

typedef struct {
    void *slookup;
    void *flookup;
    void *rlookup;
    void *alookup;
} HR_Dup_OldLookups;

typedef struct {
    void *vhash;
} HR_Dup_Vinfo;

#define mk_old_lookup_key(vname, table_addr) \
    char vname[256] = { '\0' }; \
    sprintf(vname, "%s%p", HR_DUPKEY_OLD_LOOKUPS, table_addr);

#define mk_di_key(vname, pfix, eptr) \
    char vname[256] = { '\0' }; \
    sprintf(vname, "%s@%p", pfix, eptr);
    
#define mk_vi_key(vname, vaddr) \
    char vname[256] = { '\0' }; \
    sprintf(vname, "%s%p", HR_DUPKEY_VHASH, vaddr);

static inline void
hr_dup_store_old_lookups(HV *ptr_map, HR_Table_t parent)
{

    mk_old_lookup_key(hkey, parent);
    HR_DEBUG("Storing: %s", hkey);
    if(hv_exists(ptr_map, hkey, strlen(hkey))) {
        return;
    }
    
    SV *ol_sv = newSV(sizeof(HR_Dup_OldLookups));
    HR_Dup_OldLookups *ol = (HR_Dup_OldLookups*)SvPVX(ol_sv);
    
    SV *slookup, *flookup, *rlookup, *alookup;
    
    get_hashes(parent,
               HR_HKEY_LOOKUP_SCALAR, &slookup,
               HR_HKEY_LOOKUP_REVERSE, &rlookup,
               HR_HKEY_LOOKUP_FORWARD, &flookup,
               HR_HKEY_LOOKUP_ATTR, &alookup,
               HR_HKEY_LOOKUP_NULL
    );
    
    ol->slookup = SvRV(slookup);
    ol->rlookup = SvRV(rlookup);
    ol->flookup = SvRV(flookup);
    ol->alookup = SvRV(alookup);
    
    hv_store(ptr_map, hkey, strlen(hkey), ol_sv, 0);
}

static inline HR_Dup_OldLookups*
hr_dup_get_old_lookups(HV *ptr_map, void *old_table)
{
    mk_old_lookup_key(hkey, old_table);
    HR_DEBUG("Fetching: %s", hkey);
    HR_DEBUG("Retrieving for %lu (%p)", old_table, old_table);
    SV **dupold_sv = hv_fetch(ptr_map, hkey, strlen(hkey), 0);
    assert(dupold_sv);
    return (HR_Dup_OldLookups*)SvPVX(*dupold_sv);
}


static inline HR_Dup_Kinfo*
hr_dup_store_kinfo(HV *ptr_map, char *kprefix, void *eptr, int size)
{
    if(!size) {
        size = sizeof(HR_Dup_Kinfo);
    }
    SV *stored_sv = newSV(size);
    HR_Dup_Kinfo *di = (HR_Dup_Kinfo*)SvPVX(stored_sv);
    mk_di_key(hkey, kprefix, eptr);
    hv_store(ptr_map, hkey, strlen(hkey), stored_sv, 0);
    return di;
}

static inline HR_Dup_Kinfo*
hr_dup_get_kinfo(HV *ptr_map, char *kprefix, void *old_eptr)
{
    mk_di_key(hkey, kprefix, old_eptr);
    SV **stored = hv_fetch(ptr_map, hkey, strlen(hkey), 0);
    assert(stored);
    return (HR_Dup_Kinfo*)SvPVX(*stored);
}

static inline HR_Dup_Vinfo*
hr_dup_get_vinfo(HV *ptr_map, void *vaddr, int create)
{
    mk_vi_key(hkey, vaddr);
    SV **stored = hv_fetch(ptr_map, hkey, strlen(hkey), create);
    
    if(!create) {
        if(!stored) {
            return NULL;
        }
    } else {
        assert(stored && *stored);
        if(SvTYPE(*stored) == SVt_NULL) {
            SvUPGRADE(*stored, SVt_PV);
            SvGROW( (*stored), sizeof(HR_Dup_Vinfo));
            ((HR_Dup_Vinfo*)SvPVX( (*stored)) )->vhash = NULL;
        }
    }
    return (HR_Dup_Vinfo*)SvPVX(*stored);
}

static inline SV*
hr_dup_newsv_for_oldsv(HV *ptr_map, void *oldptr, int copy)
{
    mk_ptr_string(old_s, oldptr);
    HR_DEBUG("Fetching for %lu (%p)", oldptr, oldptr);
    SV **ret = hv_fetch(ptr_map, old_s, strlen(old_s), 0);
    if(!ret) {
        HR_DEBUG("Couldn't fetch!");
        sv_dump((SV*)ptr_map);
    }
    assert(ret);
    if(copy) {
        return newSVsv(*ret);
    } else {
        return *ret;
    }
}

static inline void
hr_dup_store_rv(HV *ptr_map, SV *rv)
{
    assert(SvROK(rv));
    
    mk_ptr_string(sv_s, SvRV(rv));
    HR_DEBUG("Checking to see if %s is already stored", sv_s);
    if(!hv_exists(ptr_map, sv_s, strlen(sv_s))) {
        HR_DEBUG("It isn't!");
        SV *stored = newSVsv(rv);
        sv_rvweaken(stored);
        hv_store(ptr_map, sv_s, strlen(sv_s), stored, 0);
    }
}

#endif /*HR_DUPUTIL_H_*/
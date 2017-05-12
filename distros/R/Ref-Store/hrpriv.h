#ifndef HRPRIV_H_
#define HRPRIV_H_

#include "hreg.h"
#include "hrdefs.h"

#include <stdarg.h>

#define REF2HASH(ref) ((HV*)(SvRV(ref)))
#define REF2ARRAY(ref) (AV*)(SvRV(ref))

#define RV_Newtmp(vname, referrent) \
    vname = newRV_noinc((referrent));

#define RV_Freetmp(rv); \
    SvRV_set(rv, NULL); \
    SvROK_off(rv); \
    SvREFCNT_dec(rv);

#define stash_from_cache_nocheck(darry, stashtype) \
    ((HV*)SvRV((*(av_fetch(REF2ARRAY(darry), stashtype, 0)))))


typedef char* HR_BlessParams[2];
#define blessparam_init(bparam) bparam[0] = NULL
#define blessparam_setstash(bparam, stash) bparam[1] = stash
#define blessparam2chrp(bparam) (char*)(bparam)


HR_INLINE HV*
stash_from_cache_nocheck_S(SV *aref, int stashtype)
{
    HV *ret;
    SV **elem;
    
    elem = av_fetch(REF2ARRAY(aref), stashtype, 0);
    if(!elem) {
        die("Couldn't find stash!");
    }
    ret = (HV*)SvRV(*elem);
    return ret;
}

enum {
    VHASH_NO_CREATE = 0,
    VHASH_NO_DREF   = 1,
    VHASH_INIT_FULL = 2,
};

typedef char* HSpec[2];


enum {
    STORE_OPT_STRONG_KEY    = 1 << 0,
    STORE_OPT_STRONG_VALUE  = 1 << 1,
    STORE_OPT_O_CREAT       = 1 << 2
};
#define STORE_OPT_STRONG_ATTR (1 << 0)

/*This macro will convert string hash options into bitflags for the
 various store functions
*/

#define _chkopt(option_id, iter, optvar) \
    if(strcmp(HR_STROPT_ ## option_id, SvPV_nolen(ST(iter))) == 0 \
    && SvTRUE(ST(iter+1))) { \
        optvar |= STORE_OPT_ ## option_id; \
        HR_DEBUG("Found option %s", HR_STROPT_ ## option_id); \
        continue; \
    }

extern HSpec HR_LookupKeys[];

#define FAKE_REFCOUNT (1 << 16)
HR_INLINE U32
refcnt_ka_begin(SV *sv)
{
    U32 ret = SvREFCNT(sv);
    SvREFCNT(sv) = FAKE_REFCOUNT;
    return ret;
}

HR_INLINE void
refcnt_ka_end(SV *sv, U32 old_refcount)
{
    I32 effective_refcount = old_refcount + (SvREFCNT(sv) - FAKE_REFCOUNT);
    if(effective_refcount <= 0 && old_refcount > 0) {
        SvREFCNT(sv) = 1;
        SvREFCNT_dec(sv);
    } else {
        SvREFCNT(sv) = effective_refcount;
        if(effective_refcount != SvREFCNT(sv)) {
            die("Detected negative refcount!");
        }
    }
}


#define HR_PREFIX_DELIM "#"

#define LOOKUP_FIELDS_COMMON \
unsigned char prefix_len : 4;
#define HR_PREFIX_LEN_MAX 16

#ifndef HR_TABLE_ARRAY
typedef HV* HR_Table_t;
#else
typedef AV* HR_Table_t;
#endif

#define REF2TABLE(tbl) \
    ((HR_Table_t)SvRV(tbl))

HR_INLINE void
get_hashes(HR_Table_t table, ...)
{
    va_list ap;
    va_start(ap, table);
    SV **result;
    
    while(1) {
        int ltype = (int)va_arg(ap, int);
        if(!ltype) {
            break;
        }
        SV **hashptr = (SV**)va_arg(ap, SV**);
#ifdef HR_TABLE_ARRAY
        result = av_fetch(table, ltype, 0);
#else
        HSpec *kspec = (HSpec*)HR_LookupKeys[ltype-1];
        char *hkey = (*kspec)[0];
        int klen = (int)((*kspec)[1]);
        result = hv_fetch(table, hkey, klen, 0);
#endif
        if(!result) {
            *hashptr = NULL;
        } else {
            *hashptr = *result;
        }
    }
    va_end(ap);
}

#define new_hashval_ref(vsv, referrent) \
    SvUPGRADE(vsv, SVt_RV); \
    SvRV_set(vsv, referrent); \
    SvROK_on(vsv);

HR_INLINE SV*
get_vhash_from_rlookup(SV *rlookup, SV *vaddr, int create)
{
    HE* h_ent = hv_fetch_ent(REF2HASH(rlookup), vaddr, create, 0);
    SV *href;
    if(h_ent && (href = HeVAL(h_ent)) && SvROK(href)) {
        return href;
    }
    if(!create) {
        return NULL;
    }
    
    /*Create*/
    HV *referrent = newHV();
    new_hashval_ref(href, (SV*)referrent);
    
    if(create == VHASH_INIT_FULL) {
        HR_DEBUG("Adding DREF for HV=%p", SvRV(rlookup));
        SV *vref = NULL;
        RV_Newtmp(vref, ((SV*)(SvUV(vaddr))) );
        HR_Action rlookup_delete[] = {
            HR_DREF_FLDS_ptr_from_hv(SvRV(vref), rlookup ),
            HR_ACTION_LIST_TERMINATOR
        };
        HR_add_actions_real(vref, rlookup_delete);
        RV_Freetmp(vref);
    }
    
    return href;
}


/*This will insert a key object into the value's vhash.
 It will create the vhash if it does not exist
 It will use the existing rlookup, if found, or fetch it from the
 table using get_hashes().
*/

HR_INLINE int
insert_into_vhash(
    SV *vref,
    SV *lobj,
    char *kstring,
    HR_Table_t table,
    SV *rlookup
    )
{
    SV **stored;
    SV *vhash;
    SV *vaddr = newSVuv((UV)SvRV(vref));
    int created;
    
    if(!rlookup) {
        get_hashes(table, HR_HKEY_LOOKUP_REVERSE, &rlookup,
                   HR_HKEY_LOOKUP_NULL);
    }
    vhash = get_vhash_from_rlookup(rlookup, vaddr, VHASH_INIT_FULL);
    
    stored = hv_fetch(REF2HASH(vhash), kstring, strlen(kstring), 1);
    if(!SvROK(*stored)) {
        created = 1;
        HR_DEBUG("Creating new reverse entry..");
        new_hashval_ref(*stored, SvRV(lobj));
        SvREFCNT_inc(SvRV(lobj));
    } else {
        created = 0;
    }
    
    SvREFCNT_dec(vaddr);   
    return created;
}

HR_INLINE HV*
stash_from_pkgparam(char *arg)
{
    if(! (*arg) ) {
        HR_DEBUG("Special stash stored!");
        return (HV*)(((char**)arg)[1]);
    } else {
        HR_DEBUG("Just a normal string :(");
        return gv_stashpv(arg, 0);
    }
}

HR_INLINE SV*
mk_blessed_blob(char *pkg, int size)
{
    HR_DEBUG("New blob requested with size=%d", size);
    HV *stash = stash_from_pkgparam(pkg);
    SV *referrant = newSV(size);
    HR_DEBUG("Allocated block=%p", SvPVX(referrant));
    if(!stash) {
        die("Can't get stash!");
        SvREFCNT_dec(referrant);
        return NULL;
    }
    SV *self = newRV_noinc(referrant);
    sv_bless(self, stash);
    return self;
}


#endif /* HRPRIV_H_ */
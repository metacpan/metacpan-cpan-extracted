#include "hreg.h"
#include "hrdefs.h"
#include "hrpriv.h"
#include "hr_duputil.h"

#include <string.h>

HSpec HR_LookupKeys[] = {
    {HR_HKEY_SLOOKUP, (char*)sizeof(HR_HKEY_SLOOKUP)-1},
    {HR_HKEY_FLOOKUP, (char*)sizeof(HR_HKEY_FLOOKUP)-1},
    {HR_HKEY_RLOOKUP, (char*)sizeof(HR_HKEY_RLOOKUP)-1},
    {HR_HKEY_KTYPES, (char*)sizeof(HR_HKEY_KTYPES)-1},
    {HR_HKEY_ALOOKUP, (char*)sizeof(HR_HKEY_ALOOKUP)-1}
};

typedef struct
__attribute__((packed))
{
    LOOKUP_FIELDS_COMMON;
} hrk_simple;

typedef struct
__attribute__((packed))
{
    LOOKUP_FIELDS_COMMON;
    HR_Table_t  table;
    SV*         obj_ptr;
    void*       obj_paddr;
} hrk_encap;

static inline HV*
get_v_hashref(hrk_encap *ke, SV* value);

#define ketbl_from_ke(ke) (HR_Table_t)(ke->table)

#define keptr_from_sv(svp) \
    ((hrk_encap*)(SvPVX(svp)))

#define ksimple_from_sv(svp) \
    ((hrk_simple*)(SvPVX(svp)))

#define ksimple_strkey(ksp) \
    (char*)(((char*)(ksp))+sizeof(hrk_simple))

/*We find our information about ourselves here, and place it inside our
 private pointer table*/

static void k_encap_cleanup(SV *ksv, SV *_, HR_Action *action_list);
static void encap_destroy_hook(SV *encap_obj, SV *ksv, HR_Action *action_list);
static inline void k_encap_wire_actions(SV *ksv, SV *encap);

typedef char* _stashspec[2];

#define stashspec_ent(name) \
    { (char*)HR_STASH_ ## name, HR_PKG_ ## name }

void HRA_table_init(SV *self)
{
    AV *my_stashcache = newAV();
    HV *stash;
    
    _stashspec classlist[] = {
        stashspec_ent(KEY_SCALAR),
        stashspec_ent(KEY_ENCAP),
        stashspec_ent(ATTR_SCALAR),
        stashspec_ent(ATTR_ENCAP),
        { 0, 0 }
    };
    
    _stashspec *cspec;
    for(cspec = classlist; (*cspec)[1]; cspec++) {
        stash = gv_stashpv((*cspec)[1], 0);
        if(!stash) {
            die("Couldn't get stash!");
        }
        av_store(my_stashcache, (I32)((*cspec)[0]), newRV_inc((SV*)stash));
    }
    
    av_store((AV*)SvRV(self), HR_HKEY_LOOKUP_PRIVDATA, newRV_noinc(my_stashcache));
}

static void encap_destroy_hook(SV *encap_obj, SV *ksv, HR_Action *action_list)
{
    U32 old_refcount = refcnt_ka_begin(encap_obj);
    HR_DEBUG("Called!");
    SV *keyrv;
    RV_Newtmp(keyrv, ksv);
    
    HR_XS_del_action_ext(keyrv, &k_encap_cleanup, NULL,
                         HR_KEY_TYPE_NULL|HR_KEY_SFLAG_HASHREF_OPAQUE);
    k_encap_cleanup(ksv, NULL, NULL);
    refcnt_ka_end(encap_obj, old_refcount);
    RV_Freetmp(keyrv);
}

static void k_encap_cleanup(SV *ksv, SV *_, HR_Action *action_list)
{
    /*Find our forward entry from the stringified object pointer*/
    hrk_encap *ke = keptr_from_sv(ksv);
    HR_Table_t table = ketbl_from_ke(ke);    
    SV *scalar_lookup, *forward, *reverse;
    SV *encap_rv = ke->obj_ptr;
    SV *value = NULL;
    SV *vhash = NULL;
    
    SV **tmp_hashval = NULL;
    
    mk_ptr_string(obj_s, ke->obj_paddr);
    
    if(!table) {
        warn("Is table being destroyed?");
        goto GT_CLEANUP;
    }
    
    ke->obj_paddr = NULL;
    ke->obj_ptr = NULL;
    
    HR_DEBUG("obj_s=%s", obj_s);
    
    get_hashes(table,
               HR_HKEY_LOOKUP_REVERSE, &reverse,
               HR_HKEY_LOOKUP_FORWARD, &forward,
               HR_HKEY_LOOKUP_SCALAR, &scalar_lookup,
               HR_HKEY_LOOKUP_NULL
    );
    
    
    if(!(scalar_lookup && forward && reverse)) {
        die("Uhh...: (S=%p, F=%p, R=%p, REFCOUNT=%d", scalar_lookup, forward, reverse,
            SvREFCNT(table));
    }
    
    if(encap_rv && SvROK(encap_rv)) {
        HR_XS_del_action_ext(encap_rv, &encap_destroy_hook,
                             ksv, HR_KEY_TYPE_PTR|HR_KEY_SFLAG_HASHREF_OPAQUE);
    }
    
    tmp_hashval = hv_fetch( REF2HASH(forward), obj_s, strlen(obj_s), 0 );
    if(!tmp_hashval) {
        HR_DEBUG("Can't find stored value in forward table");
        goto GT_CLEANUP;
    } else {
        value = *tmp_hashval;
    }
    
    
    mk_ptr_string(value_s, SvRV(value));
    HR_DEBUG("value_s=%s", value_s);
    tmp_hashval = hv_fetch( REF2HASH(reverse), value_s, strlen(value_s), 0);
    
    if(tmp_hashval) {
        vhash = *tmp_hashval;
        HR_DEBUG("Deleting vfrom vhash %p", vhash);
        
        hv_delete( REF2HASH(vhash), obj_s, strlen(obj_s), G_DISCARD );
        
        /*Common value deletion operation*/
        if(!HvKEYS(REF2HASH(vhash))) {
            HR_DEBUG("Removing vhash");
            HR_PL_del_action_container(value, reverse);
            hv_delete( REF2HASH(reverse), value_s, strlen(value_s), G_DISCARD);
        } else {
            HR_DEBUG("Vhash still has %lu keys remaining", HvKEYS(REF2HASH(vhash)));
        }
    } else {
        HR_DEBUG("Can't find anything!");
    }
    
    hv_delete( REF2HASH(scalar_lookup), obj_s, strlen(obj_s), G_DISCARD );
    hv_delete( REF2HASH(forward), obj_s, strlen(obj_s), G_DISCARD );
    
    GT_CLEANUP:
    if(encap_rv) {
        SvREFCNT_dec(encap_rv);
    }
    HR_DEBUG("Returning...");
}

static inline void k_encap_wire_actions(SV *ksv, SV *encap)
{
    HR_Action key_actions[] = {
        HR_DREF_FLDS_arg_for_cfunc(SvRV(ksv), &k_encap_cleanup),
        HR_ACTION_LIST_TERMINATOR
    };
    HR_Action encap_actions[] = {
        HR_DREF_FLDS_arg_for_cfunc(SvRV(ksv), &encap_destroy_hook),
        HR_ACTION_LIST_TERMINATOR
    };
    
    HR_add_actions_real(ksv, key_actions);
    HR_add_actions_real(encap, encap_actions);
}

void HRXSK_encap_link_value(SV *self, SV *value)
{
    /*NOOP*/
}

void HRXSK_encap_weaken(SV *ksv_ref)
{
    hrk_encap *ke = keptr_from_sv(SvRV(ksv_ref));
    HR_DEBUG("Weakening encapsulated object reference");
    sv_rvweaken(ke->obj_ptr);
}

UV HRXSK_encap_kstring(SV* ksv_ref)
{
    hrk_encap *ke = keptr_from_sv(SvRV(ksv_ref));
    return (UV)SvRV(ke->obj_ptr);
}

SV *HRXSK_encap_getencap(SV *ksv_ref)
{
    hrk_encap *ke = keptr_from_sv(SvRV(ksv_ref));
    //die("Unsupported!");
    return newSVsv(ke->obj_ptr);
}

SV* HRXSK_encap_new(char *package, SV* object, SV *table, SV* forward, SV* scalar_lookup)
{    
    HR_DEBUG("Encap key");
    SV *ksv = mk_blessed_blob(package, sizeof(hrk_encap));
    
    if(!ksv) {
        die("couldn't create hrk_encap!");
        return NULL;
    }
    hrk_encap *keptr = keptr_from_sv(SvRV(ksv));
    keptr->obj_ptr = newRV_inc(SvRV(object));
    keptr->obj_paddr = (char*)SvRV(object);
    
    keptr->table = REF2TABLE(table);

#ifdef HR_CONSTRUCTOR_STORES_KEY
    mk_ptr_string(key_s, SvRV(object));
    HR_DEBUG("Have string key %s", key_s);
    HR_DEBUG("Scalar lookup: %p", scalar_lookup);
    
    SV *self_hval = newSVsv(ksv);
    sv_rvweaken(self_hval);
    hv_store( REF2HASH(scalar_lookup), key_s, strlen(key_s), self_hval, 0);
#endif

    k_encap_wire_actions(ksv, object);
    
    HR_DEBUG("Returning key %p", SvRV(ksv));
    return ksv;
}



static inline HV*
get_v_hashref(hrk_encap *ke, SV* value)
{
    HR_Table_t table = ke->table;
    SV *reverse;
    get_hashes(table,
               HR_HKEY_LOOKUP_REVERSE, &reverse,
               HR_HKEY_LOOKUP_NULL);
    
    if(!reverse) {
        return NULL;
    }
    
    HR_DEBUG("Have reverse!");
    mk_ptr_string(vstring, SvRV(value));
    SV **privhash = hv_fetch(REF2HASH(reverse), vstring, strlen(vstring), 0);
    if(privhash) {
        return (HV*)SvRV(*privhash);
    } else {
        HR_DEBUG("Can't get privhash from hv_fetch");
        return NULL;
    }
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/// Scalar Key Functions                                                     ///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

SV* HRXSK_new(char *package, char *key, SV *forward, SV *scalar_lookup)
{
    hrk_simple newkey;
    
    int keylen = strlen(key) + 1;
    int bloblen = keylen + sizeof(newkey);
    
    SV *ksv = mk_blessed_blob(package, bloblen);
    
    if(!ksv) {
        die("Couldn't create package!");
        return NULL;
    }
    
    /* blob: [key data] [key string] */
    char *blob = SvPVX(SvRV(ksv));
    char *key_offset = blob + sizeof(newkey);
    
    /*Initialize the blob*/
    Zero(blob, 1, hrk_simple);
    Copy(key, key_offset, keylen, char);
    
#ifdef HR_CONSTRUCTOR_STORES_KEY
    SV **scalar_entry = hv_store(REF2HASH(scalar_lookup),
                                 key, keylen-1,
                                 newSVsv(ksv), 0);
    if(!scalar_entry) {
        die("Couldn't add entry!");
    }
    sv_rvweaken(*scalar_entry);
#endif

    HR_Action actions[] = {
        HR_DREF_FLDS_Estr_from_hv(key_offset, scalar_lookup),
        HR_DREF_FLDS_Estr_from_hv(key_offset, forward),
        HR_ACTION_LIST_TERMINATOR
    };
        
    HR_add_actions_real(ksv, actions);
    return ksv;
}

char * HRXSK_kstring(SV *obj)
{
    char *blob = ksimple_from_sv(SvRV(obj));
    char *ret = ksimple_strkey(blob);
    HR_DEBUG("Requested key=%s", ret);
    return ret;
}

UV HRXSK_prefix_len(SV *obj)
{
    return (ksimple_from_sv(SvRV(obj)))->prefix_len;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/// Ref::Store API implementation (keys)                                 ///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
static inline SV* ukey2ikey(
    SV* self,
    SV* key,
    SV** existing, /*PP: Argument to $options{O_EXCL}: $expected*/
    int options)
{
    SV *slookup = NULL, *flookup = NULL;
    SV *kobj = NULL;
    SV *my_stashcache_ref = NULL;
    HE *stored_key = NULL;
    
    HR_BlessParams stash_params;
    int do_create = (options & STORE_OPT_O_CREAT);
    int key_is_ref = SvROK(key);
    SV *our_key = (key_is_ref) ? newSVuv(SvUV(key)) : key;    
    HE *stored_val = NULL;
    char *kstring_p = NULL;
    
    get_hashes(REF2TABLE(self),
               HR_HKEY_LOOKUP_SCALAR, &slookup,
               HR_HKEY_LOOKUP_PRIVDATA, &my_stashcache_ref,
               HR_HKEY_LOOKUP_FORWARD, &flookup,
               HR_HKEY_LOOKUP_NULL);
    
    HR_DEBUG("Using key %s", SvPV_nolen(our_key));
    
    /*PP: my $o = $self->scalar_lookup->{$ustr}; */
    stored_key = hv_fetch_ent(REF2HASH(slookup), our_key, do_create, 0);
    
    if(stored_key == NULL) {
        HR_DEBUG("No key found and no creation requested");
        goto GT_RET; /*No create requested*/
    }
    
    kobj = HeVAL(stored_key);
    if(SvROK(kobj)) {
        /*Have valid key, check if we have an existing pointer*/
        if(existing) {
            stored_val = hv_fetch_ent(REF2HASH(flookup), our_key, 0, 0);
            if(!stored_val) {
                die("Found orphaned key without value");
            }
            if(SvRV(HeVAL(stored_val)) != SvRV(*existing)) {
                die("Requested key ('%s') for value=%p, but existing key "
                    "already stores %p",
                    SvPV_nolen(our_key), SvRV(HeVAL(stored_val)), SvRV(*existing));
            }
            *existing = HeVAL(stored_val);
            HR_DEBUG("Have kobj=%p", SvRV(kobj));
        }
        goto GT_RET;
    }
    
    if(existing) {
        *existing = NULL;
    }
    /*New key creation*/
    blessparam_init(stash_params);
    if(key_is_ref) {
        blessparam_setstash(stash_params, stash_from_cache_nocheck(
            my_stashcache_ref, HR_STASH_KEY_ENCAP));
        
        kobj = HRXSK_encap_new(blessparam2chrp(stash_params),
                    key, self, flookup, slookup);
        if( (options & STORE_OPT_STRONG_KEY) == 0) {
            HRXSK_encap_weaken(kobj);
        }
    } else {
        blessparam_setstash(stash_params,stash_from_cache_nocheck(
            my_stashcache_ref, HR_STASH_KEY_SCALAR));
        
        kobj = HRXSK_new(blessparam2chrp(stash_params),
                SvPV_nolen(our_key), flookup, slookup);
        /*XS Simple key's weaken_encapsulated is nop*/
    }
    
#ifndef HR_CONSTRUCTOR_STORES_KEY
    HR_DEBUG("Upgrading placeholder");
    SvUPGRADE(HeVAL(stored_key), SVt_RV);
    SvRV_set(HeVAL(stored_key), SvRV(kobj));
    SvROK_on(HeVAL(stored_key));
    SvREFCNT_inc(SvRV(kobj));
    sv_rvweaken(HeVAL(stored_key));
#endif

    GT_RET:
    if(key_is_ref && our_key) {
        SvREFCNT_dec(our_key);
    }
    return kobj;
}



static inline void
store_helper(int *opt_p, SV **key_p, SV **vsv, char **prefix_p, int *prefix_len)
{
    dXSARGS;
    int opt_start = 3;
    char *key_s;
    
    if(!SvROK(*vsv)) {
        if(items < 3) {
            die("Value must be reference");
        }
        
        else {
            if(!SvROK(*key_p)) {
                *prefix_p = SvPV(*vsv, *prefix_len);
                if(!*prefix_p) {
                    die("Couldn't get string key?");
                }
                key_s = SvPV_nolen(*key_p);
                
                *key_p = newSVpvf("%s%s%s",
                    *prefix_p, HR_PREFIX_DELIM, key_s);
            } else {
                warn("Prefixed keys have no effect for object keys");
            }
            *vsv = ST(3);
            opt_start++;
        }
    }
    
    if( (items - opt_start) % 2 ) {
        die("Odd number of option hash arguments");
    }
    
    for(opt_start; opt_start < items; opt_start += 2) {
        _chkopt(STRONG_VALUE, opt_start, (*opt_p));
        _chkopt(STRONG_KEY, opt_start, (*opt_p));
    }
    XSRETURN(0);
}


void HRA_store_kt(SV *self, SV *key, SV *t, SV *value, ...)
{
    SV *kt_lookup;
    HE *key_res;
    
    get_hashes(REF2TABLE(self), HR_HKEY_LOOKUP_KT, &kt_lookup,
               HR_HKEY_LOOKUP_NULL);
    
    key_res = hv_fetch_ent(REF2HASH(kt_lookup), t, 0, 0);
    if(!key_res) {
        die("Couldn't fetch key for %s", SvPV_nolen(key));
    }
    /*Value is unused, and is popped off the stack..*/
    HRA_store_sk(self, key, HeVAL(key_res));
}

/*The third argument is only the value for the perl-facing store/store_sk
 functions. For store_kt, the value is actually the fourth argument, hence
 the handling by store_helper()
*/

void HRA_store_sk(SV *self, SV *key, SV *value, ...)
{
    SV *flookup = NULL,  *rlookup = NULL; //Lookup tables
    SV *kobj    = NULL, *kstring = NULL; // Key object and string
    SV *vstring = NULL; //Value refaddr
    SV *hval    = NULL; //reference to store in the forward hash
    SV *existing_ent = NULL; /* SV** to send/receive options for O_CREAT/O_EXCL*/
    SV *vhash; //Value's lookup references
    char *prefix = NULL;
    int prefix_len = 0;
    int key_is_ref = SvROK(key);
    int iopts = STORE_OPT_O_CREAT;
    
    store_helper(&iopts, &key, &value, &prefix, &prefix_len);
    existing_ent = value;
    
    kobj = ukey2ikey(self, key, &existing_ent, iopts);
    
    if(existing_ent) {
        HR_DEBUG("We're already stored");
        goto GT_CLEANUP;
    }
    
    vstring = newSVuv(SvUV(value));
    hval = newSVsv(value);
    
    /*Not stored yet*/
    if(key_is_ref) {
        kstring = newSVuv(SvUV(key));
        (ksimple_from_sv(SvRV(kobj)))->prefix_len = 0;
    } else {
        kstring = key;
        if(prefix_len) {
            if(prefix_len > HR_PREFIX_LEN_MAX) {
                die("Prefixes longer than %d chars unsupported", HR_PREFIX_LEN_MAX);
            } else {
                (ksimple_from_sv(SvRV(kobj)))->prefix_len = prefix_len;
            }
        }
    }
    
    get_hashes(REF2TABLE(self),
               HR_HKEY_LOOKUP_FORWARD, &flookup,
               HR_HKEY_LOOKUP_REVERSE, &rlookup,
               HR_HKEY_LOOKUP_NULL);
    /*Get value hashref*/
    vhash = get_vhash_from_rlookup(rlookup, vstring, 1);
    assert(vhash);
    hv_store_ent(REF2HASH(vhash), kstring, kobj, 0);
    
    HR_DEBUG("Storing FLOOKUP{%s} (SV=%p) (RV=%p)",
             SvPV_nolen(kstring), hval, SvRV(hval));
    
    hv_store_ent(REF2HASH(flookup), kstring, hval, 0);
    
    /*PP: dref_add_ptr*/
    HR_PL_add_action_ptr(hval, rlookup);
    
    /*PP: if(!$options{StrongValue}) { weaken($self->forward->kstring)}*/
    if( (iopts & STORE_OPT_STRONG_VALUE) == 0) {
        HR_DEBUG("Weakening value");
        sv_rvweaken(hval);
    }
    
    GT_CLEANUP:
    if(key_is_ref && kstring) {
        SvREFCNT_dec(kstring);
    }
    if(vstring) {
        SvREFCNT_dec(vstring);
    }
    if(prefix_len) {
        SvREFCNT_dec(key);
    }
}

SV *HRA_fetch_sk(SV *self, SV *key)
{
    SV *kobj = ukey2ikey(self, key, NULL, 0);
    SV *flookup;
    SV *ret = NULL;
    if(!kobj) {
        HR_DEBUG("Can't find key object!");
        return &PL_sv_undef;
    }
    int key_is_ref = SvROK(key);
    key = (key_is_ref) ? newSVuv(SvUV(key)) : key;
    get_hashes(REF2TABLE(self),
               HR_HKEY_LOOKUP_FORWARD, &flookup,
               HR_HKEY_LOOKUP_NULL);
    
    HE *res = hv_fetch_ent(REF2HASH(flookup), key, 0, 0);
    if(res) {
        HR_DEBUG("Got result for %p", key);
        ret = newSVsv(HeVAL(res));
    } else {
        HR_DEBUG("Nothing for %p", key);
    }
    HR_DEBUG("Refcount for key: %d", SvREFCNT(SvRV(kobj)));
    if(key_is_ref) {
        SvREFCNT_dec(key);
    }
    return ret;
}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/// iThread Duplication Handlers                                             ///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
void HRA_ithread_store_lookup_info(SV *self, HV *ptr_map)
{
    hr_dup_store_old_lookups(ptr_map, REF2TABLE(self));
}

void HRXSK_encap_ithread_predup(SV *self, SV *table, HV *ptr_map, SV *value)
{
    hrk_encap *ke = keptr_from_sv(SvRV(self));   
    HR_Dup_Kinfo *ki = hr_dup_store_kinfo(ptr_map, HR_DUPKEY_KENCAP,
                                          ke->obj_paddr, 0);
    
    if(SvWEAKREF(ke->obj_ptr)) {
        ki->flags = HRK_DUP_WEAK_ENCAP;
    } else {
        ki->flags = 0;
    }
    
    HV *vhash = get_v_hashref(ke, value);
    ki->vhash = vhash;
    
    hr_dup_store_rv(ptr_map, ke->obj_ptr);
}

void HRXSK_encap_ithread_postdup(SV *newself, SV *newtable, HV *ptr_map, UV old_table)
{
    hrk_encap *ke = keptr_from_sv(SvRV(newself));
    
    HR_Dup_OldLookups *old_lookups = hr_dup_get_old_lookups(ptr_map, ke->table);
    HR_Dup_Kinfo *ki = hr_dup_get_kinfo(ptr_map, HR_DUPKEY_KENCAP, ke->obj_paddr);
    
    HR_DEBUG("Old vhash was %p, old obj_paddr was %p", ki->vhash, ke->obj_paddr);
    
    SV *new_encap = hr_dup_newsv_for_oldsv(ptr_map, ke->obj_paddr, 0);    
    k_encap_wire_actions(newself, new_encap);
    ke->obj_paddr = SvRV(new_encap);
    ke->obj_ptr = newSVsv(new_encap);
    if(ki->flags & HRK_DUP_WEAK_ENCAP) {
        sv_rvweaken(ke->obj_ptr);
    }
    ke->table = SvRV(newtable);
    HR_DEBUG("Reassigned %p", SvRV(newtable));
}


/*Postdup for simple keys*/
void HRXSK_ithread_postdup(SV *newself, SV *newtable, HV *ptr_map, UV old_table)
{
    hrk_simple *ksp = ksimple_from_sv(SvRV(newself));
    
    char *key = ksimple_strkey(ksp);
    SV *slookup, *flookup;
    
    get_hashes(REF2TABLE(newtable),
               HR_HKEY_LOOKUP_SCALAR, &slookup,
               HR_HKEY_LOOKUP_FORWARD, &flookup,
               HR_HKEY_LOOKUP_NULL);
    
    HR_Action key_actions[] = {
        HR_DREF_FLDS_Estr_from_hv(key, slookup),
        HR_DREF_FLDS_Estr_from_hv(key, flookup),
        HR_ACTION_LIST_TERMINATOR
    };
    HR_add_actions_real(newself, key_actions);
}
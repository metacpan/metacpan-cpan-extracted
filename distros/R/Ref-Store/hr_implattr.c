////////////////////////////////////////////////////////////////////////////////
/// Ref::Store API implementation (attributes)                           ///
////////////////////////////////////////////////////////////////////////////////

#include "hreg.h"
#include "hrpriv.h"
#include "hrdefs.h"
#include "hr_duputil.h"

#include <string.h>
#include <stdlib.h>


#define ATTR_FIELDS_COMMON \
    LOOKUP_FIELDS_COMMON \
    SV *table; \
    HV *attrhash; \
    unsigned char encap;

typedef struct {
    ATTR_FIELDS_COMMON
} hrattr_simple;

typedef struct {
    ATTR_FIELDS_COMMON;
    SV *obj_rv;
    char *obj_paddr;
} hrattr_encap;

#define attr_parent_tbl(attr) (HR_Table_t)(attr->table)

#define attr_from_sv(sv) (hrattr_simple*)(SvPVX(sv))
/*Declare a function which will be our trigger and proxy deletion/checking
 of the hash*/

#define attr_strkey(aobj, sz) ((char*)(((char*)(aobj))+sz))

#define attr_getsize(attr)  \
    ((attr->encap) ? sizeof(hrattr_encap) : sizeof(hrattr_simple))

#define attr_encap_cast(attr) ((hrattr_encap*)attr)

static inline SV *attr_get(SV *self, SV *attr, char *t, int options);
static inline SV *attr_new_common(char *pkg, char *key, SV *table, int attrsize);

static void attr_destroy_trigger(SV *self, SV *encap_obj, HR_Action *action_list);
static void encap_attr_destroy_hook(SV *encap_obj, SV *attr_sv, HR_Action *action_list);

static inline SV* attr_simple_new(char *pkg, char *astr, SV *table);
static inline SV* attr_encap_new(char *pkg, char *astr, SV *encapped, SV *table);
static inline SV* attr_new_common(char *pkg, char *astr, SV *table, int attrsz);
static inline void attr_delete_from_vhash(SV *self, SV *value);
static inline void attr_delete_value_from_attrhash(SV *self, SV *value);

static inline SV*
attr_new_common(char *pkg, char *key, SV *table, int attrsize)
{
    int keylen = strlen(key) + 1;
    int bloblen = attrsize + keylen;
    SV *self = mk_blessed_blob(pkg, bloblen);
    hrattr_simple *attr = attr_from_sv(SvRV(self));
    char *key_offset = attr_strkey(attr, attrsize);
    Copy(key, key_offset, keylen, char);
    attr->table = SvRV(table);
    attr->attrhash = newHV();
    attr->encap = 0;
    
    HR_Action destroy_action[] = {
        HR_DREF_FLDS_arg_for_cfunc(SvRV(self), &attr_destroy_trigger),
        HR_ACTION_LIST_TERMINATOR
    };
    
    HR_add_actions_real(self, destroy_action);
    return self;
}

static inline SV
*attr_encap_new(char *pkg, char *key, SV *obj, SV *table)
{
    SV *self = attr_new_common(pkg, key, table, sizeof(hrattr_encap));
    hrattr_encap *attr = attr_encap_cast(attr_from_sv(SvRV(self)));
    attr->obj_rv = newSVsv(obj);
    attr->obj_paddr = (char*)SvRV(obj);
    attr->encap = 1;
    HR_Action encap_destroy_action[] = {
        HR_DREF_FLDS_arg_for_cfunc(SvRV(self), (SV*)&encap_attr_destroy_hook),
        HR_ACTION_LIST_TERMINATOR
    };
    HR_add_actions_real(obj, encap_destroy_action);
    return self;
}

static inline SV
*attr_simple_new(char *pkg, char *key, SV *table)
{
    return attr_new_common(pkg, key, table, sizeof(hrattr_simple));
}


SV  *HRXSATTR_get_hash(SV *self)
{
    hrattr_simple *attr = attr_from_sv(SvRV(self));
    if(attr->attrhash) {
        return newRV_inc((SV*)attr->attrhash);
    } else {
        return &PL_sv_undef;
    }
}

char *HRXSATTR_kstring(SV *self)
{
    hrattr_simple *attr = attr_from_sv(SvRV(self));
    char *ret = attr_strkey(attr, attr_getsize(attr));
    return ret;
}

SV *HRXSATTR_encap_ukey(SV *self)
{
    return newSVsv(attr_encap_cast(attr_from_sv(SvRV(self)))->obj_rv);
}

UV HRXSATTR_prefix_len(SV *self)
{
    return (attr_from_sv(SvRV(self)))->prefix_len;
}

static inline SV*
attr_get(SV *self, SV *attr, char *t, int options)
{
    char *attr_ustr = NULL, *attr_fullstr = NULL;
    char smallbuf[128] = { '\0' };
    char ptr_buf[128] = { '\0' };
    SV *kt_lookup, *attr_lookup;
    SV **kt_ent;
    SV *aobj = NULL;
    SV **a_ent;
    SV *my_stashcache_ref;
    
    HR_BlessParams stash_params;
    
    int attrlen     = 0;
    int on_heap     = 0;
    int prefix_len  = 0;
    
    get_hashes(REF2TABLE(self),
               HR_HKEY_LOOKUP_ATTR, &attr_lookup,
               HR_HKEY_LOOKUP_KT, &kt_lookup,
               HR_HKEY_LOOKUP_PRIVDATA, &my_stashcache_ref,
               HR_HKEY_LOOKUP_NULL
            );
    
    blessparam_init(stash_params);
    
    if(! (kt_ent = hv_fetch(REF2HASH(kt_lookup), t, strlen(t), 0))) {
        die("Couldn't determine keytype '%s'", t);
    }
    
    attrlen = strlen(SvPV_nolen(*kt_ent)) + 1;
    
    if(SvROK(attr)) {
        attrlen += sprintf(ptr_buf, "%lu", SvRV(attr));
        attr_ustr = ptr_buf;
    } else {
        attrlen += strlen(SvPV_nolen(attr));
        attr_ustr = SvPV_nolen(attr);
    }
    
    attrlen += sizeof(HR_PREFIX_DELIM) - 1;
    
    if(attrlen > 128) {
        on_heap = 1;
        Newx(attr_fullstr, attrlen, char);
    } else {
        attr_fullstr = smallbuf;
    }
    
    *attr_fullstr = '\0';
    
    sprintf(attr_fullstr, "%s%s%s", SvPV_nolen(*kt_ent), HR_PREFIX_DELIM, attr_ustr);
    HR_DEBUG("ATTRKEY=%s", attr_fullstr);
    
    a_ent = hv_fetch(REF2HASH(attr_lookup), attr_fullstr, attrlen-1, 0);
    if(!a_ent) {
        
        prefix_len = strlen(t);
        
        if( (options & STORE_OPT_O_CREAT) == 0) {
            HR_DEBUG("Could not locate attribute and O_CREAT not specified");
            goto GT_RET;
        } else if(SvROK(attr)) {
            blessparam_setstash(stash_params,
                stash_from_cache_nocheck(my_stashcache_ref, HR_STASH_ATTR_ENCAP));
            
            aobj = attr_encap_new(blessparam2chrp(stash_params),
                                  attr_fullstr, attr, self);
            if( (options & STORE_OPT_STRONG_KEY) == 0) {
                sv_rvweaken( ((hrattr_encap*)attr_from_sv(SvRV(aobj)))->obj_rv );
            }
        } else {
            blessparam_setstash(stash_params,
                stash_from_cache_nocheck(my_stashcache_ref,HR_STASH_ATTR_SCALAR));
            aobj = attr_simple_new(blessparam2chrp(stash_params), attr_fullstr, self);
        }
        
        a_ent = hv_store(REF2HASH(attr_lookup),
                         attr_fullstr, attrlen-1,
                         newSVsv(aobj), 0);
        
        /*Actual attribute entry is ALWAYS weak and is entirely dependent on vhash
         entries*/
        (attr_from_sv(SvRV(aobj)))->prefix_len = prefix_len;
        assert(a_ent);
        sv_rvweaken(*a_ent);
    } else {
        aobj = *a_ent;
    }
    
    GT_RET:
    if(on_heap) {
        Safefree(attr_fullstr);
    }
    HR_DEBUG("Returning %p", aobj);
    return aobj;
}

void HRA_store_a(SV *self, SV *attr, char *t, SV *value, ...)
{
    SV *vstring = newSVuv((UV)SvRV(value)); //reverse lookup key
    SV *aobj    = NULL; //primary attribute entry, from attr_lookup
    SV *vref    = NULL; //value's entry in attribute hash
    SV *attrhash_ref = NULL; //reference for attribute hash, for adding actions
    
    SV **a_r_ent = NULL; //lval-type HE for looking/storing attr in vhash
    char *astring = NULL;
    
    hrattr_simple *aptr; //our private attribute structure
    
    int options = STORE_OPT_O_CREAT;
    int i;
    
    dXSARGS;
    if ((items-4) % 2) {
        die("Expected hash options or nothing (got %d)", items-3);
    }
    for(i=4;i<items;i+=2) {
        _chkopt(STRONG_ATTR, i, options);
        _chkopt(STRONG_VALUE, i, options);
    }
    
    aobj = attr_get(self, attr, t, options);
    if(!aobj) {
        die("attr_get() failed to return anything");
    }
    
    aptr = attr_from_sv(SvRV(aobj));
    assert(SvROK(aobj));
    astring = attr_strkey(aptr, attr_getsize(aptr));
    
    if(!insert_into_vhash(value, aobj, astring, REF2TABLE(self), NULL)) {
        goto GT_RET; /*No new insertions*/
    }
    
    if(!HvKEYS(aptr->attrhash)) {
        /*First entry and we've already inserted our reverse entry*/
        SvREFCNT_dec(SvRV(aobj));
    }
    
    vref = newSVsv(value);
    if(hv_store_ent(aptr->attrhash, vstring, vref, 0)) {
        if( (options & STORE_OPT_STRONG_VALUE) == 0) {
            sv_rvweaken(vref);
        }
    } else {
        SvREFCNT_dec(vref);
    }
    
    RV_Newtmp(attrhash_ref, (SV*)aptr->attrhash);
    
    HR_Action v_actions[] = {
        HR_DREF_FLDS_ptr_from_hv(SvRV(value), attrhash_ref),
        HR_ACTION_LIST_TERMINATOR
    };
    
    HR_add_actions_real(value, v_actions);
        
    GT_RET:
    SvREFCNT_dec(vstring);
    if(attrhash_ref) {
        RV_Freetmp(attrhash_ref);
    }
    XSRETURN(0);
}

void HRA_fetch_a(SV *self, SV *attr, char *t)
{
    dXSARGS;
    SP -= 3;
    
    if(GIMME_V == G_VOID) {
        XSRETURN(0);
    }
    
    SV *aobj = attr_get(self, attr, t, 0);
    if(!aobj) {
        HR_DEBUG("Can't find attribute!");
        XSRETURN_EMPTY;
    } else {
        HR_DEBUG("Found aobj=%p", aobj);
    }
    hrattr_simple *aptr = attr_from_sv(SvRV(aobj));
    
    HR_DEBUG("Attrhash=%p", aptr->attrhash);
    int nkeys = hv_iterinit(aptr->attrhash);
    HR_DEBUG("We have %d keys", nkeys);
    if(GIMME_V == G_SCALAR) {
        HR_DEBUG("Scalar return value requested");
        XSRETURN_IV(nkeys);
    }
    HR_DEBUG("Will do some stack voodoo");
    EXTEND(sp, nkeys);
    HE *cur = hv_iternext(aptr->attrhash);
    for(; cur != NULL; cur = hv_iternext(aptr->attrhash))
    {
        XPUSHs(sv_mortalcopy(hv_iterval(aptr->attrhash, cur)));
    }
    PUTBACK;
}

SV* HRA_attr_get(SV *self, SV *attr, char *t)
{
    SV *ret = attr_get(self, attr, t, 0);
    if(ret) {
        ret = newSVsv(ret);
    } else {
        return &PL_sv_undef;
    }
}

void HRA_dissoc_a(SV *self, SV *attr, char *t, SV *value)
{
    SV *aobj = attr_get(self, attr, t, 0);
    if(!aobj) {
        return;
    }
    HR_DEBUG("Dissoc called");
    attr_delete_value_from_attrhash(aobj, value);
    attr_delete_from_vhash(aobj, value);
}

void HRA_unlink_a(SV *self, SV* attr, char *t)
{
    HR_DEBUG("UNLINK_ATTR");
    SV *aobj = attr_get(self, attr, t, 0);
    if(!aobj) {
        return;
    }
    attr_destroy_trigger(SvRV(aobj), NULL, NULL);
    HR_DEBUG("UNLINK_ATTR DONE");
}


static inline void attr_delete_from_vhash(SV *self, SV *value)
{
    hrattr_simple *attr = attr_from_sv(SvRV((self)));
    //UN_del_action(value, SvRV(self));
    SV *vaddr = newSVuv((UV)SvRV(value));
    SV *rlookup;
    SV *vhash;
    
    char *astr = attr_strkey(attr, attr_getsize(attr));
    
    get_hashes((HR_Table_t)attr_parent_tbl(attr),
               HR_HKEY_LOOKUP_REVERSE, &rlookup, HR_HKEY_LOOKUP_NULL);
    
    vhash = get_vhash_from_rlookup(rlookup, vaddr, 0);
    
    U32 old_refcount = refcnt_ka_begin(value);
    if(vhash) {
        HR_DEBUG("vhash has %d keys", HvKEYS(REF2HASH(vhash)));
        
        HR_DEBUG("Deleting '%s' from vhash=%p", astr, SvRV(vhash));
        hv_delete(REF2HASH(vhash), astr, strlen(astr), G_DISCARD);
        if(!HvKEYS(REF2HASH(vhash))) {
            HR_DEBUG("Vhash empty");
            HR_PL_del_action_container(value, rlookup);
            hv_delete_ent(REF2HASH(rlookup), vaddr, G_DISCARD, 0);
        } else {
            HR_DEBUG("Vhash still has %d keys", HvKEYS(REF2HASH(vhash)));
        }
    }
    refcnt_ka_end(value, old_refcount);
}

static inline void attr_delete_value_from_attrhash(SV *self, SV *value)
{
    hrattr_simple *attr = attr_from_sv(SvRV((self)));
    SV *vaddr = newSVuv((UV)SvRV(value));
    SV *attrhash_ref;
    RV_Newtmp(attrhash_ref, (SV*)attr->attrhash);
    
    HR_DEBUG("Deleting action vobj=%p ::  attrhash=%p",
             SvRV(value), SvRV(attrhash_ref));
    HR_PL_del_action_container(value, attrhash_ref);
    hv_delete_ent(attr->attrhash, vaddr, G_DISCARD, 0);
    
    RV_Freetmp(attrhash_ref);
    SvREFCNT_dec(vaddr);
    HR_DEBUG("Done!");
}

void HRXSATTR_unlink_value(SV *self, SV *value)
{
    attr_delete_value_from_attrhash(self, value);
    attr_delete_from_vhash(self, value);
}


/*This function is called when the attribute object is destroyed. This can
 happen in the following cases:
 
 All value entries have deleted us from their vhashes:
    * Entries in the attribute hash will be deleted at the end of this function.
    * Values are still alive, but their possibly weak references are undef'd,
        so we convert the stringified pointer into a real one
    * If encapsulated object is still alive, the obj_paddr field should be true,
        in which case, we delete actions tied to it, check the weakref to see
        if that is defined, and decrease its refcount
    
Encapsulated object has been deleted
    * Value entries may possibly still be alive, in which case we check if they
        need to have their vhashes deleted
    * Delete our actions from the encapsulated object
 */
 
/*First argument is the object, second is the argument */

static void encap_attr_destroy_hook(SV *encap_obj, SV *attr_sv, HR_Action *action_list)
{
    HR_DEBUG("Encap hook called. Attribute is %p", attr_sv);
    hrattr_encap *aencap = attr_encap_cast(attr_from_sv(attr_sv));
    aencap->obj_paddr = NULL;
    SvREFCNT_dec(aencap->obj_rv);
    aencap->obj_rv = NULL;
    
    SvREFCNT_inc(attr_sv);
    attr_destroy_trigger(attr_sv, NULL, NULL);
    SvREFCNT_dec(attr_sv);
}

static void attr_destroy_trigger(SV *self_sv, SV *encap_obj, HR_Action *action_list)
{
    HR_DEBUG("self_sv=%p", self_sv);
    
    HR_DEBUG("Attr destroy hook");
    HR_DEBUG("We are ATTR=%p", self_sv);
    //sv_dump(self_sv);
    hrattr_simple *attr = attr_from_sv(self_sv);
    HR_DEBUG("hrattr=%p", attr);
    HR_Table_t parent = attr_parent_tbl(attr);
    HR_DEBUG("Parent=%p", parent);
    SV *rlookup = NULL, *attr_lookup = NULL;
    
    if(SvREFCNT(parent)) {
        get_hashes(parent,
                   HR_HKEY_LOOKUP_REVERSE, &rlookup,
                   HR_HKEY_LOOKUP_ATTR, &attr_lookup,
                   HR_HKEY_LOOKUP_NULL);
        HR_DEBUG("rlookup=%p, attr_lookup=%p", rlookup, attr_lookup);
    } else {
        HR_DEBUG("Main lookup table being destroyed?");
        parent = NULL;
    }
    
    
    char *ktmp;
    int attrsz = attr_getsize(attr);
    SV *vtmp, *vhash;
    I32 tmplen;
    
    mk_ptr_string(oaddr, self_sv);
    int oaddr_len = strlen(oaddr);
    
    SV *attrhash_ref = NULL, *self_ref = NULL;
    RV_Newtmp( attrhash_ref, ((SV*)attr->attrhash) );
    RV_Newtmp( self_ref, self_sv );
    
    if(action_list) {
        while( (HR_nullify_action(action_list,
                                (SV*)&attr_destroy_trigger,
                                NULL,
                                HR_KEY_TYPE_NULL|HR_KEY_SFLAG_HASHREF_OPAQUE)
                == HR_ACTION_DELETED) );
        /*No body*/
    } else {
        HR_PL_del_action_container(self_ref, (SV*)&attr_destroy_trigger);
    }
    
    HR_DEBUG("Deleted self destroy hook");
    
    
    if(attr->encap) {
        hrattr_encap *aencap = (hrattr_encap*)attr;
        
        if(aencap->obj_paddr) {
            SV *encap_ref = NULL;
            RV_Newtmp(encap_ref, (SV*)aencap->obj_paddr);
            HR_PL_del_action_container(encap_ref,
                                 (SV*)&encap_attr_destroy_hook);
            RV_Freetmp(encap_ref);
            HR_DEBUG("Deleted encap destroy hook");
        }
        
        if(aencap->obj_rv) {
            SvREFCNT_dec( aencap->obj_rv );
        }

    }
    
    if(attr_lookup) {
        HR_DEBUG("Deleting our attr_lookup entry..");
        hv_delete(REF2HASH(attr_lookup),
                  attr_strkey(attr, attrsz),
                  strlen(attr_strkey(attr, attrsz)),
                  G_DISCARD);
        HR_DEBUG("attr_lookup entry deleted");
    }
    
    U32 old_refcount = refcnt_ka_begin(self_sv);
    I32 attrvals = hv_iterinit(attr->attrhash);
    HR_DEBUG("We have %d values", attrvals);
    
    while( (vtmp = hv_iternextsv(attr->attrhash, &ktmp, &tmplen)) ) {
        SV *vptr, *vref;
        sscanf(ktmp, "%lu", &vptr); /*Don't ask.. also, uses slightly less memory*/
        RV_Newtmp(vref, vptr);
        
        U32 old_v_refcount = refcnt_ka_begin(vptr);
        
        attr_delete_value_from_attrhash(self_ref, vref);
        if(SvROK(vref) && parent) {
            HR_DEBUG("Deleting vhash entry");
            attr_delete_from_vhash(self_ref, vref);
        } else {
            HR_DEBUG("Eh?");
        }
        RV_Freetmp(vref);
        
        refcnt_ka_end(vptr, old_v_refcount);
    }
    
    SvREFCNT_dec(attr->attrhash);
    RV_Freetmp(self_ref);
    RV_Freetmp(attrhash_ref);
    
    refcnt_ka_end(self_sv, old_refcount);
    HR_DEBUG("Attr destroy done");
}

void HRXSATTR_ithread_predup(SV *self, SV *table, HV *ptr_map)
{
    hrattr_simple *attr = attr_from_sv(SvRV(self));
    
    /*Make sure our attribute hash is visible to perl space*/
    SV *attrhash_ref;
    RV_Newtmp(attrhash_ref, (SV*)attr->attrhash);
    
    hr_dup_store_rv(ptr_map, attrhash_ref);
    
    RV_Freetmp(attrhash_ref);
    
    char *ktmp;
    I32 tmplen;
    SV *vtmp;
    SV *rlookup;
    
    get_hashes(REF2TABLE(table),
               HR_HKEY_LOOKUP_REVERSE, &rlookup,
               HR_HKEY_LOOKUP_NULL);
    
    hv_iterinit(attr->attrhash);
    while( (vtmp = hv_iternextsv(attr->attrhash, &ktmp, &tmplen))) {
        HR_Dup_Vinfo *vi = hr_dup_get_vinfo(ptr_map, SvRV(vtmp), 1);
        if(!vi->vhash) {
            SV *vaddr = newSVuv((UV)SvRV(vtmp));
            SV *vhash = get_vhash_from_rlookup(rlookup, vaddr, 0);
            vi->vhash = vhash;
            SvREFCNT_dec(vaddr);
        }
    }
    
    if(attr->encap) {
        hrattr_encap *aencap = attr_encap_cast(attr);
        
        hr_dup_store_rv(ptr_map, aencap->obj_rv);
        char *ai = (char*)hr_dup_store_kinfo(
            ptr_map, HR_DUPKEY_AENCAP, aencap->obj_paddr, 1);
        
        if(SvWEAKREF(aencap->obj_rv)) {
            *ai = HRK_DUP_WEAK_ENCAP;
        } else {
            *ai = 0;
        }
    }
}

void HRXSATTR_ithread_postdup(SV *newself, SV *newtable, HV *ptr_map)
{
    hrattr_simple *attr = attr_from_sv(SvRV(newself));
    
    HR_DEBUG("Fetching new attrhash_ref");
    
    SV *new_attrhash_ref = hr_dup_newsv_for_oldsv(ptr_map, attr->attrhash, 0);
    
    attr->attrhash = (HV*)SvRV(new_attrhash_ref);
    SvREFCNT_inc(attr->attrhash); /*Because the copy hash will soon be deleted*/
    
    attr->table = SvRV(newtable);
    
    HR_DEBUG("New attrhash: %p", attr->attrhash);
        
    /*Now do the equivalent of: my @keys = keys %attrhash; foreach my $key (@keys)*/
    int n_keys = hv_iterinit(attr->attrhash);
    
    if(n_keys) {
        char **keylist = NULL;
        char **klist_head = NULL;
        int tmp_len, i;
        HR_DEBUG("Have %d keys", n_keys);
        Newx(keylist, n_keys, char*);
        klist_head = keylist;
        
		while(hv_iternextsv(attr->attrhash, keylist++, &tmp_len));
        /*No body*/

        for(i=0, keylist = klist_head; i < n_keys; i++) {
            HR_DEBUG("Key: %s", keylist[i]);
            SV *stored = hv_delete(attr->attrhash, keylist[i], strlen(keylist[i]), 0);
            assert(stored);
            assert(SvROK(stored));

            mk_ptr_string(new_s, SvRV(stored));
            hv_store(attr->attrhash, new_s, strlen(new_s), stored, 0);
            HR_Action v_actions[] = {
                HR_DREF_FLDS_ptr_from_hv(SvRV(stored), new_attrhash_ref),
                HR_ACTION_LIST_TERMINATOR
            };
			HR_DEBUG("Will add new actions for value in attrhash");
            HR_add_actions_real(stored, v_actions);
        }
        Safefree(klist_head);
    }
    
    HR_Action attr_actions[] = {
        HR_DREF_FLDS_arg_for_cfunc(SvRV(newself), &attr_destroy_trigger),
        HR_ACTION_LIST_TERMINATOR
    };

	HR_DEBUG("Will add new actions for attribute object");
    HR_add_actions_real(newself, attr_actions);
    
    if(attr->encap) {
        hrattr_encap *aencap = attr_encap_cast(attr);
        SV *new_encap = hr_dup_newsv_for_oldsv(ptr_map, aencap->obj_paddr, 1);
        char *ainfo = (char*)hr_dup_get_kinfo(
                    ptr_map, HR_DUPKEY_AENCAP, aencap->obj_paddr);
        if(*ainfo == HRK_DUP_WEAK_ENCAP) {
            sv_rvweaken(new_encap);
        }
        HR_Action encap_actions[] = {
            HR_DREF_FLDS_arg_for_cfunc(SvRV(newself), (SV*)&encap_attr_destroy_hook),
            HR_ACTION_LIST_TERMINATOR
        };
		HR_DEBUG("Will add actions for new encapsulated object");
        HR_add_actions_real(new_encap, encap_actions);

        aencap->obj_rv = new_encap;
        aencap->obj_paddr = (char*)SvRV(new_encap);

        /*We also need to change our key string...*/
        char *oldstr = attr_strkey(aencap, sizeof(hrattr_encap));
        
        char *oldptr = strrchr(oldstr, HR_PREFIX_DELIM[0]);
        
        assert(oldptr);
        HR_DEBUG("Old attr string: %s", oldstr);
        oldptr++;
        *(oldptr) = '\0';
        mk_ptr_string(newptr, aencap->obj_paddr);
        SvGROW(SvRV(newself), sizeof(hrattr_encap)
                +strlen(oldstr)+strlen(newptr)+1);
        strcat(oldstr, newptr);
        HR_DEBUG("New string: %s", oldstr);
    }
    
}

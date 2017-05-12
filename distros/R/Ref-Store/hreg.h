#ifndef HREG_H_
#define HREG_H_

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdint.h>

/*#define HR_DEBUG*/

//#define HR_DEBUG

#ifndef HR_DEBUG
static int _hr_enable_debug = -1;
#define _hr_can_debug \
    (_hr_enable_debug >= 0 ? _hr_enable_debug : \
        (_hr_enable_debug = getenv("HR_DEBUG") ? 1 : 0))

#define HR_DEBUG(fmt, ...) if(_hr_can_debug) { \
    fprintf(stderr, "[%s:%d (%s)] " fmt "\n", \
        __FILE__, __LINE__, __func__, ## __VA_ARGS__); \
}
#endif

#define _hashref_eq(r1, r2) \
    (SvROK(r1) && SvROK(r2) && \
    SvRV(r1) == SvRV(r2))


#define _mg_action_list(mg) (HR_Action*)mg->mg_ptr

static inline void
_mk_ptr_string(char *str, size_t value)
{
/*Pirated from:
 http://code.google.com/p/stringencoders/
*/
    char* wstr=str;
    char aux;
    // Conversion. Number is reversed.
    
    do *wstr++ = (char)(48 + (value % 10)); while (value /= 10);
    *wstr='\0';
    
    // Reverse string
    wstr--;
    while (wstr > str)
        aux = *wstr, *wstr-- = *str, *str++ = aux;
}

//#define mk_ptr_string(vname, ptr) \
//    char vname[128] = { '\0' }; \
//    sprintf(vname, "%lu", ptr);

#define mk_ptr_string(vname, ptr) \
    char vname[128]; \
    _mk_ptr_string(vname, (size_t)ptr);

#ifdef __GNUC__
#define inline __inline__
#endif

#if __STDC__ && __STDC_VERSION__ <= 199409L && !defined __GNUC__
#warning "c89 mode and GCC not detected. Not using inline"
#define HR_INLINE static
#else
#define HR_INLINE static inline
#endif

#define HR_TABLE_ARRAY

/*Memory Stuff*/

//#define HR_PERL_MALLOC

#ifdef HR_PERL_MALLOC
#warning "Using Perl_malloc"
#undef Perl_malloc
#undef Perl_mfree

#define Newxz_Action(ptr) \
    ptr = Perl_malloc(sizeof(HR_Action)); \
    Zero(ptr, 1, HR_Action);

#define Newxz_Action_len(ptr, extra_len) \
    ptr = Perl_malloc(sizeof(HR_Action) + extra_len); \
    Zero(ptr, 1, HR_Action);

#define Resize_Action_tail(ptr, tail_len) \
    ptr = Perl_realloc(ptr, sizeof(HR_Action)+tail_len);

#define Free_Action(ptr) \
    Perl_mfree(ptr);

#else /*!HR_PERL_MALLOC*/
       
#define Newxz_Action(ptr) \
    Newxz(ptr, 1, HR_Action)

#define Free_Action(ptr) \
    Safefree(ptr);

#endif

/*action tail functions*/

#define action_is_tailed_nocheck(actionp) \
    ((actionp->flags & HR_FLAG_STR_NO_ALLOC) == 0)

#define action_is_tailed(actionp) \
    (actionp->ktype == HR_KEY_TYPE_STR && action_is_tailed_nocheck(actionp))

#define action_keystr(actionp) \
    (action_is_tailed_nocheck(actionp)) ? \
        (char*)(((char*)actionp)+sizeof(HR_Action)) : \
        actionp->key

#define action_keylen(actionp) \
    (action_is_tailed_nocheck(actionp)) ? \
        (size_t)(actionp->key) : \
        strlen(actionp->key)

#define HREG_API_INTERNAL

typedef enum {
    HR_ACTION_TYPE_NULL         = 0,
    HR_ACTION_TYPE_DEL_AV       = 1,
    HR_ACTION_TYPE_DEL_HV       = 2,
    HR_ACTION_TYPE_CALL_CV      = 3,
    HR_ACTION_TYPE_CALL_CFUNC   = 4
} HR_ActionType_t;

typedef enum {
    HR_KEY_TYPE_NULL            = 0,
    HR_KEY_TYPE_PTR             = 1,
    HR_KEY_TYPE_STR             = 2,
    
    
    /*Extended options for searching*/
    /*RV implies we should:
     1) check the flags to see if the stored key is an RV,
     2) compare the keys performing SvRV on the stored key,
        assume current search spec is already dereferenced
    */
    HR_KEY_STYPE_PTR_RV          = 100,
    /*Sometimes a container is opaque (like a C callback)*/
    HR_KEY_SFLAG_HASHREF_OPAQUE  = 0x2000
    
} HR_KeyType_t;

typedef enum {
    HR_ACTION_NOT_FOUND,    /*Action was not found in the list*/
    HR_ACTION_DELETED,      /*Deletion OK*/
    HR_ACTION_EMPTY         /*No more actions left in the table. Hint for unmagic*/
} HR_DeletionStatus_t;


enum {
    HR_FLAG_STR_NO_ALLOC        = 1 << 0, /*Do not copy/allocate/free string*/
    HR_FLAG_HASHREF_WEAKEN      = 1 << 1, /*Weaken hashref, assumes HASHREF_RV*/
    HR_FLAG_SV_REFCNT_DEC       = 1 << 2, /*Key is an SV whose REFCNT we should decrease*/
    HR_FLAG_PTR_NO_STRINGIFY    = 1 << 3, /*Do not stringify the pointer*/
    HR_FLAG_HASHREF_RV          = 1 << 4, /*hashref is a reference, not a plain SV*/
};

/*We re-use the STR_NO_ALLOC field for an SV flag, which is obviously a TYPE_PTR*/
#define HR_FLAG_SV_KEY (1<<0)

#define action_key_is_rv(aptr) ((aptr)->flags & HR_FLAG_SV_REFCNT_DEC)
#define action_container_is_sv(aptr) ((aptr->atype != HR_ACTION_TYPE_CALL_CFUNC))
#define action_container_is_rv(aptr) ((aptr->flags & (HR_FLAG_HASHREF_RV)))
typedef struct HR_Action HR_Action;
typedef void(*HR_ActionCallback)(void*,SV*,HR_Action*);

struct
__attribute__((__packed__))
HR_Action {
    HR_Action   *next;
    void        *key;       /*Key*/
    unsigned int atype : 3; /*Action type*/
    unsigned int ktype : 2; /*Key type*/
    SV          *hashref;   /*Container*/
    unsigned int flags : 5; /*Flags*/
};

/*This will clear an action's data fields, while keeping the next pointer
 for the linked list*/

#define action_clear(actionp) \
    Zero(((char**)actionp)+1, sizeof(HR_Action)-sizeof(HR_Action*), char);


#define HR_ACTION_LIST_TERMINATOR \
{ NULL, NULL, HR_KEY_TYPE_NULL, HR_ACTION_TYPE_NULL, 0, 0 }

/*Helper macros for common HR_Action specifications*/
#define HR_DREF_FLDS_ptr_from_hv(ptr, container) \
    { .ktype = HR_KEY_TYPE_PTR, .atype = HR_ACTION_TYPE_DEL_HV, \
      .key = (char*)(ptr), .hashref = container }

#define HR_DREF_FLDS_Nstr_from_hv(newstr, container) \
    { .ktype = HR_KEY_TYPE_STR, .atype = HR_ACTION_TYPE_DEL_HV, \
        .key = newstr, .hashref = container }

#define HR_DREF_FLDS_Estr_from_hv(estr, container) \
    { .ktype = HR_KEY_TYPE_STR, .atype = HR_ACTION_TYPE_DEL_HV, \
    .key = estr, .hashref = container, .flags = HR_FLAG_STR_NO_ALLOC }

#define HR_DREF_FLDS_arg_for_cfunc(arg, fptr) \
    { .ktype = HR_KEY_TYPE_PTR, .atype = HR_ACTION_TYPE_CALL_CFUNC, \
    .key = arg, .hashref = (SV*)fptr }

HREG_API_INTERNAL
void HR_add_action(HR_Action *action_list, HR_Action *new_action, int want_unique);

HREG_API_INTERNAL
void HR_trigger_and_free_actions(HR_Action *action_list, SV *object);

HREG_API_INTERNAL
HR_DeletionStatus_t
HR_del_action(HR_Action *action_list, SV *hashref, void *key, HR_KeyType_t ktype);

HREG_API_INTERNAL
HR_DeletionStatus_t
HR_nullify_action(HR_Action *action_list, SV *hashref, void *key, HR_KeyType_t ktype);

HREG_API_INTERNAL
HR_Action*
HR_free_action(HR_Action *action);
/*
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/// Perl Functions                                                           ///
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
*/
HREG_API_INTERNAL
void HR_add_actions_real(SV *objref, HR_Action *actions);

/*Perl API*/

void HR_PL_add_action_ptr(SV *objref, SV *hashref);
void HR_PL_add_action_str(SV *objref, SV *hashref, char *key);

void HR_PL_del_action_ptr(SV *object, SV *hashref, UV addr);
void HR_PL_del_action_str(SV *object, SV *hashref, char *str);
void HR_PL_del_action_container(SV *object, SV *hashref);
void HR_PL_del_action_sv(SV *object, SV *hashref, SV *keysv);


/*More extended deletion type..*/
void HR_XS_del_action_ext(SV *object, void *container,
						  void *arg, HR_KeyType_t ktype);


/*This is mainly for Ref::Destructor, and allows a more versatile, possibly
 slower, but safer specification of actions. Specifically, the target object
 will always be a reference (though it can be weakened)
*/

void HR_PL_add_action_ext(
    SV *objref, UV key, unsigned int atype, unsigned int ktype, SV *hashref,
    unsigned int flags);


/* H::R implementation */

SV*		HRXSK_new(char *package, char *key, SV *forward, SV *scalar_lookup);
char*	HRXSK_kstring(SV* self);
UV		HRXSK_prefix_len(SV *self);
void 	HRXSK_ithread_postdup(SV *newself, SV *newtable, HV *ptr_map, UV old_table);

SV* 	HRXSK_encap_new(char *package, SV *encapsulated_object,
                    SV *table, SV *forward, SV *scalar_lookup);
UV 		HRXSK_encap_kstring(SV *ksv_ref);
void 	HRXSK_encap_weaken(SV *ksv_ref);
void 	HRXSK_encap_link_value(SV *self, SV *value);
SV*  	HRXSK_encap_getencap(SV *self);


void 	HRXSATTR_unlink_value(SV *aobj, SV *value);
SV*  	HRXSATTR_get_hash(SV *aobj);
char*	HRXSATTR_kstring(SV *aobj);
UV		HRXSATTR_prefix_len(SV *aobj);
SV*		HRXSATTR_encap_ukey(SV *aobj);

void HRXSK_encap_ithread_predup(SV *self, SV *table, HV *ptr_map, SV *value);
void HRXSK_encap_ithread_postdup(SV *newself, SV *newtable, HV *ptr_map, UV old_table);

void HRXSATTR_ithread_predup(SV *self, SV *table, HV *ptr_map);
void HRXSATTR_ithread_postdup(SV *newself, SV *newtable, HV *ptr_map);

/*H::R API*/
void 	HRA_table_init(SV *self);
void 	HRA_store_sk(SV *hr, SV *ukey, SV *value, ...);
void 	HRA_store_kt(SV *hr, SV *ukey, SV *t, SV *value, ...);
SV* 	HRA_fetch_sk(SV *hr, SV *ukey); /*we manipulate perl's stack in this one*/

void 	HRA_store_a(SV *hr, SV *attr, char *t, SV *value, ...);
void  	HRA_fetch_a(SV *hr, SV *attr, char *t);
void 	HRA_dissoc_a(SV *hr, SV *attr, char *t, SV *value);
void 	HRA_unlink_a(SV *hr, SV *attr, char *t);
SV* 	HRA_attr_get(SV *hr, SV *attr, char *t); //Do we really need this?
void 	HRA_ithread_store_lookup_info(SV *self, HV *ptr_map);

#endif /*HREG_H_*/

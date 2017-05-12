#include <string.h>
#include <stdint.h>
#include "hreg.h"

HR_INLINE MAGIC* get_our_magic(SV* objref, int create);
HR_INLINE void free_our_magic(SV* objref);

static int hr_freehook(pTHX_ SV* target, MAGIC *mg);
static int hr_duphook(pTHX_ MAGIC *mg, CLONE_PARAMS *param);

static MGVTBL vtbl = {
	.svt_dup = &hr_duphook,
	.svt_free = &hr_freehook
};

#define OURMAGIC_infree(mg) (mg)->mg_private


static int
hr_freehook(pTHX_ SV* object, MAGIC *mg)
{
	if(PL_dirty) {
		HR_DEBUG("Not triggering during global destruction");
		return;
	}
	HR_DEBUG("FREEHOOK: mg=%p, obj=%p", mg, object);
	HR_DEBUG("Object refcount: %d", SvREFCNT(object));
	OURMAGIC_infree(mg) = 1;
	
#if (PERL_VERSION < 10) || (PERL_VERSION == 10 && PERL_SUBVERSION < 1)
#warning "Nasty SvMAGIC_set hack"
	SvMAGIC_set(object, mg);
#endif
    HR_trigger_and_free_actions(_mg_action_list(mg), object);
}

/*This is called for new threads, we initialize a new HR_Action list,
 because old lists would presumably reference variables of the parent thread*/
HR_INLINE int
hr_duphook(pTHX_ MAGIC *mg, CLONE_PARAMS *param)
{
	HR_DEBUG("Initializing new empty action list");
	Newxz_Action(mg->mg_ptr);
}

HR_INLINE MAGIC*
get_our_magic(SV* objref, int create)
{
	MAGIC *mg;
    HR_Action *action_list;
    SV *target;
    
    if(!SvROK(objref)) {
        die("Value=%p must be a reference type", objref);
    }
    
    target = SvRV(objref);
    
    objref = NULL; /*Don't use this anymore*/
    
	if(SvTYPE(target) < SVt_PVMG) {
		HR_DEBUG("Object=%p is not yet magical!", target);
		if(create) {
			goto GT_NEW_MAGIC;
		} else {
			HR_DEBUG("No magic found, but creation not requested");
			return NULL;
		}
	}
	
	HR_DEBUG("Will try to locate existing magic");
	mg = mg_find(target, PERL_MAGIC_ext);
	if(mg) {
		HR_DEBUG("Found initial mg=%p", mg);
	} else {
		HR_DEBUG("Can't find existing magic!");
	}
	for(; mg; mg = mg->mg_moremagic) {
		
		HR_DEBUG("Checking mg=%p", mg);
		if(mg->mg_virtual == &vtbl) {
			return mg;
		}
	}
	
	if(!create) {
		return NULL;
	}
	
	GT_NEW_MAGIC:
	HR_DEBUG("Creating new magic for %p", target);
	Newxz_Action(action_list);
	mg = sv_magicext(target, target, PERL_MAGIC_ext, &vtbl,
					 (const char*)action_list, 0);
	
	mg->mg_flags |= MGf_DUP;
	
    OURMAGIC_infree(mg) = 0;
	
	if(!mg) {
		die("Couldn't create magic!");
	} else {
		HR_DEBUG("Created mg=%p, alist=%p", mg, action_list);
	}
	return mg;
}

HR_INLINE void
free_our_magic(SV* target)
{
    MAGIC *mg_last = mg_find(target, PERL_MAGIC_ext);
    MAGIC *mg_cur = mg_last;
	HR_Action *action;
	
    for(;mg_cur; mg_last = mg_cur, mg_cur = mg_cur->mg_moremagic
        ) {
		if(mg_cur->mg_virtual == &vtbl) {
			break;
		}
	}
	
    if(!mg_cur) {
        return;
    }
    
    action = _mg_action_list(mg_cur);
    if(action) {
		HR_DEBUG("Found action=%p", action);
		while((action = HR_free_action(action)));
	}
    
    /*Check if this is the last magic on the variable*/
    GT_FREE_MAGIC:
	mg_cur->mg_virtual = NULL;
    if(mg_cur == mg_last) {
        /*First magic entry*/
        HR_DEBUG("Calling sv_unmagic(%p)", mg_cur->mg_obj);
        sv_unmagic(mg_cur->mg_obj, PERL_MAGIC_ext);
		HR_DEBUG("Done!");
    } else {
        mg_last->mg_moremagic = mg_cur->mg_moremagic;
		HR_DEBUG("About to Safefree(mg_cur=%p)", mg_cur);
		HR_DEBUG("Free=%p", mg_cur);
        Safefree(mg_cur);
    }    
}

HREG_API_INTERNAL void
HR_add_actions_real(SV* objref, HR_Action *actions)
{
    HR_DEBUG("Have objref=%p, action_list=%p", objref, actions);
    MAGIC *mg = get_our_magic(objref, 1);
    
    if(!actions) {
        die("Must have at least one action!");
    }
    
    while(actions->ktype) {
        if(!actions->hashref) {
            die("Must have hashref!");
        }
        HR_add_action(_mg_action_list(mg), actions, 1);
        actions++;
    }
}

void
HR_PL_add_actions(SV *objref, char *blob) {
    HR_add_actions_real(objref, (HR_Action*)blob);
}


HR_INLINE void
pl_del_action_common(SV *objref, SV *hashref,
										void *key, HR_KeyType_t ktype)
{
	MAGIC *mg = get_our_magic(objref, 0);
	int dv; /*Deletion status*/
    HR_DEBUG("DELETE: O=%p, SV=%p", objref, hashref);
	if(!mg) {
		return;
	}
	
	if(OURMAGIC_infree(mg)) {
		while(HR_nullify_action(
			_mg_action_list(mg), hashref, key, ktype) == HR_ACTION_DELETED);
		/*no body*/
		return;
	}
	
    dv = HR_ACTION_NOT_FOUND;
    while( (dv = HR_del_action(
			_mg_action_list(mg), hashref, key, ktype)) == HR_ACTION_DELETED );
    /*no body*/
    HR_DEBUG("Delete done");
	
    if(dv == HR_ACTION_EMPTY) {
        free_our_magic(SvRV(objref));
    }
}

#define gen_del_fn(suffix, argtype, ktype) \
	void HR_PL_del_action_ ## suffix(SV *obj, SV *ctr, argtype arg) { \
		pl_del_action_common(obj, ctr, (void*)arg, ktype); \
	}

gen_del_fn(ptr, UV, HR_KEY_TYPE_PTR);
gen_del_fn(str, char*, HR_KEY_TYPE_STR);
gen_del_fn(sv, SV*, HR_KEY_STYPE_PTR_RV);

#undef gen_del_fn

void HR_XS_del_action_ext(
	SV *object, void *container, void *arg, HR_KeyType_t ktype)
{
	pl_del_action_common(object, container, arg, ktype);
}


void HR_PL_del_action_container(SV *object, SV *hashref)
{
	pl_del_action_common(object, hashref, NULL, HR_KEY_TYPE_NULL);
}

void
HR_PL_add_action_str(SV *objref, SV *hashref, char *str)
{
	int action_type;
	
	int reftype = SvTYPE(SvRV(hashref));
	int keytype = HR_KEY_TYPE_STR;
	char *real_key = str;
	
	if(reftype == SVt_PVAV) {
		action_type = HR_ACTION_TYPE_DEL_AV;
		keytype = HR_KEY_TYPE_PTR;
		HR_DEBUG("Found Array (idx=%s)", str);
		sscanf(str, "%d", &real_key);
		HR_DEBUG("Extracted key=%d", real_key);
	} else if(reftype == SVt_PVHV) {
		action_type = HR_ACTION_TYPE_DEL_HV;
	} else {
		die("Unknown type %d for target", reftype);
	}
	HR_Action actions[] = {
		{
			.key = real_key,
			.hashref = hashref,
			.ktype = keytype,
			.atype = action_type
		},
		HR_ACTION_LIST_TERMINATOR
	};
	HR_add_actions_real(objref, actions);
}

void
HR_PL_add_action_ptr(SV* objref, SV *hashref)
{
	HR_Action actions[] = {
		HR_DREF_FLDS_ptr_from_hv(SvRV(objref), hashref),
		HR_ACTION_LIST_TERMINATOR
	};
	HR_add_actions_real(objref, actions);
}

void HR_PL_add_action_ext(
	SV *objref,
	UV key,
	unsigned int atype,
	unsigned int ktype,
	SV *hashref,
	unsigned int flags
	)
{
	
	flags |= HR_FLAG_HASHREF_RV;
	/*Turn off flags which make no sense coming from perl*/
	flags &= ( ~(HR_FLAG_STR_NO_ALLOC|HR_FLAG_SV_REFCNT_DEC) );
	
	if(ktype == HR_KEY_TYPE_STR) {
		key = (UV)SvPV_nolen((SV*)key);
	}
	
	HR_Action actions[] = {
		{
			.key = (char*)key,
			.atype = atype,
			.ktype = ktype,
			.hashref = hashref,
			.flags = flags
		},
		HR_ACTION_LIST_TERMINATOR
	};
	HR_add_actions_real(objref, actions);
}
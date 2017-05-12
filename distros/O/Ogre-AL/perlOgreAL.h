#ifndef _PERLOGREAL_H_
#define _PERLOGREAL_H_


#include "OgreAL.h"


// typedefs for deeply nested classes/enums
typedef OgreAL::Sound::Priority Priority;

// macros for typemap
// xxx: let me know if you have a better way to do this...
#define TMOGREAL_OUT(arg, var, pkg) sv_setref_pv(arg, "Ogre::AL::" #pkg, (void *) var);
#define TMOGREAL_IN(arg, var, type, package, func, pkg) \
if (sv_isobject(arg) && sv_derived_from(arg, "Ogre::AL::" #pkg)) { \
		var = (type) SvIV((SV *) SvRV(arg)); \
	} else { \
		croak(#package "::" #func "(): " #var " is not an Ogre::AL::" #pkg " object\n"); \
	}

#define TMOGRE_OUT(arg, var, pkg) sv_setref_pv(arg, "Ogre::" #pkg, (void *) var);
#define TMOGRE_IN(arg, var, type, package, func, pkg) \
if (sv_isobject(arg) && sv_derived_from(arg, "Ogre::" #pkg)) { \
		var = (type) SvIV((SV *) SvRV(arg)); \
	} else { \
		croak(#package "::" #func "(): " #var " is not an Ogre::" #pkg " object\n"); \
	}


// convenience macros (could I make these into functions?)
#define PLOGREAL_VEC_OR_REALS(f) \
if (items == 4) { \
		THIS -> f ((Real)SvNV(ST(1)), (Real)SvNV(ST(2)), (Real)SvNV(ST(3))); \
	} \
	else if (sv_isobject(ST(1)) && sv_derived_from(ST(1), "Ogre::Vector3")) { \
		Vector3 *vec = (Vector3 *) SvIV((SV *) SvRV(ST(1))); \
		THIS -> f (*vec); \
	}



// for C++
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif


// pp.h does #define NORMAL PL_op->op_next,
// which reaks havoc with Sound::NORMAL (that was DAMN HARD to figure out)
#ifdef NORMAL
#undef NORMAL
#endif


#endif  /* define _PERLOGREAL_H_ */

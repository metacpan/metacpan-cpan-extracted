#ifndef _PERLOGRE_H_
#define _PERLOGRE_H_


#include <Ogre.h>

// I'm not sure what version this changed...
#if OGRE_VERSION >= 0x010900
#include <Overlay/OgreBorderPanelOverlayElement.h>
#include <Overlay/OgrePanelOverlayElement.h>
#include <Overlay/OgreTextAreaOverlayElement.h>
#else
#include <OgreBorderPanelOverlayElement.h>
#include <OgrePanelOverlayElement.h>
#include <OgreTextAreaOverlayElement.h>
#endif

// typedefs for deeply nested classes
typedef Ogre::SceneQuery::WorldFragment WorldFragment;
typedef Ogre::ManualObject::ManualObjectSection ManualObjectSection;
// TODO: all the Overlay renaming.....


// typedef for handling Degree or Radian input parameters
typedef Ogre::Radian DegRad;

// typedefs for controllers, especially input params
typedef Ogre::Controller<Ogre::Real> ControllerReal;
typedef Ogre::ControllerValue<Ogre::Real> ControllerValueReal;
typedef Ogre::ControllerFunction<Ogre::Real> ControllerFunctionReal;


// macros for typemap
// xxx: let me know if you have a better way to do this...
#define TMOGRE_OUT(arg, var, pkg) sv_setref_pv(arg, "Ogre::" #pkg, (void *) var);
#define TMOGRE_IN(arg, var, type, package, func, pkg) \
if (sv_isobject(arg) && sv_derived_from(arg, "Ogre::" #pkg)) { \
		var = (type) SvIV((SV *) SvRV(arg)); \
	} else { \
		croak(#package "::" #func "(): " #var " is not an Ogre::" #pkg " object\n"); \
	}

// handle Degree, Radian, and Real args as Radian
#define TMOGRE_DEGRAD_IN(arg, var, package, func) \
Radian rad_ ## var; \
	if (sv_isobject(arg) && sv_derived_from(arg, "Ogre::Radian")) { \
		var = (Radian *) SvIV((SV *) SvRV(arg)); \
	} else if (sv_isobject(arg) && sv_derived_from(arg, "Ogre::Degree")) { \
		Degree * degptr_ ## var = (Degree *) SvIV((SV *) SvRV(arg)); \
		rad_ ## var = * degptr_ ## var; \
		var = &rad_ ## var; \
	} else if (looks_like_number(arg)) { \
		rad_ ## var = (Real)SvNV(arg); \
		var = &rad_ ## var; \
	} else { \
		croak(#package "::" #func "(): " #var " is not a Degree or Radian object or Real number\n"); \
	}

// handle ControllerValue input args
#define TMOGRE_CONTVAL_IN(arg, var) \
if (sv_isa(arg, "Ogre::ControllerValueReal")) { \
		var = (ControllerValueReal *) SvIV((SV *) SvRV(arg)); \
	} else { \
		var = new PerlOGREControllerValue(arg); \
	}

// handle ControllerFunction input args
#define TMOGRE_CONTFUNC_IN(arg, var) \
if (sv_isa(arg, "Ogre::ControllerFunctionReal")) { \
		var = (ControllerFunctionReal *) SvIV((SV *) SvRV(arg)); \
	} else { \
		var = new PerlOGREControllerFunction(arg); \
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


#endif  /* define _PERLOGRE_H_ */

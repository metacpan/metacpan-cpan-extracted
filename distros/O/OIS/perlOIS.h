#ifndef _PERLOIS_H_
#define _PERLOIS_H_

#include <OIS.h>


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


// macros for typemap
// xxx: let me know if you have a better way to do this...
#define TMOIS_OUT(arg, var, pkg) sv_setref_pv(arg, "OIS::" #pkg, (void *) var);
#define TMOIS_IN(arg, var, type, package, func, pkg) \
if (sv_isobject(arg) && sv_derived_from(arg, "OIS::" #pkg)) { \
		var = (type) SvIV((SV *) SvRV(arg)); \
	} else { \
		warn(#package "::" #func "():" #var " is not an OIS::" #pkg " object"); \
		XSRETURN_UNDEF; \
	}


#endif  /* _PERLOIS_H_ */

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#define ref2soft sv_rv2weak

MODULE = Softref		PACKAGE = Softref		


void
ref2soft(arg0)
	SV *	arg0

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <ctype.h>
#include <string.h>
#ifdef __cplusplus
}
#endif


MODULE = String::Strip		PACKAGE = String::Strip
		
PROTOTYPES: ENABLE

void
StripTSpace(arg)
     char *arg
CODE:
     char *pc;
     int i;

     if (!SvOK(ST(0)))
       XSRETURN_UNDEF;

     if (i = strlen(arg)) {
       for (pc = arg + i - 1; (pc >= arg) && *pc && isspace(*pc); --pc)
	 ;
       *++pc = 0;
     }
OUTPUT:
     arg

void
StripLSpace(arg)	
     char *arg
CODE:
     char *pcF, *pcR;
     int i;

     if (!SvOK(ST(0)))
       XSRETURN_UNDEF;

     if (i = strlen(arg)) {
       for (pcF = arg; *pcF && isspace(*pcF); pcF++)
         ;

       memmove(arg, pcF, i);
     }
OUTPUT:
     arg

void
StripLTSpace(arg)
     char *arg
CODE:
     char *pcF, *pcR;
     int i;

     if (!SvOK(ST(0)))
       XSRETURN_UNDEF;

     if (i = strlen(arg)) {
       for (pcR = arg + i - 1; (pcR > arg) && *pcR && isspace(*pcR); --pcR)
	 ;
       *++pcR = 0;

       if (arg < pcR) {
	 for (pcF = arg; *pcF && isspace(*pcF); pcF++)
	   ;

	     memmove(arg, pcF,i);
       }
     }
OUTPUT:
     arg

void
StripSpace(arg)
     char *arg
CODE:
     char *pcF, *pcR;
     if (!SvOK(ST(0)))
       XSRETURN_UNDEF;

     if (strlen(arg)) {
       for (pcF = pcR = arg; *pcR; pcR++)
	 if (!isspace(*pcR))
	   *pcF++ = *pcR;
       *pcF = 0;
     }
OUTPUT:
     arg


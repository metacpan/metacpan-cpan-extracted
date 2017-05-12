#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Sub::Caller     PACKAGE = Sub::Caller
PROTOTYPES: DISABLE


void
checkFunc(svFunc)
   SV *svFunc
PPCODE:
{
   if (SvROK(svFunc)){
      svFunc = SvRV(svFunc);
   }

   if (!(SvFLAGS(svFunc)&SVt_PVCV)){
      XSRETURN_UNDEF;
   }

   XSRETURN_PV(HvNAME(GvSTASH(CvGV(svFunc))));
}


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "stdlib.h"


MODULE = Sys::Load         PACKAGE = Sys::Load

void
getload()
PROTOTYPE:
PREINIT:
  double load[3];
  int i;
PPCODE:
  i = getloadavg(load, 3);
  if(i == -1)
    XSRETURN_EMPTY;
  else {
    XPUSHs(sv_2mortal(newSVnv(load[0])));
    XPUSHs(sv_2mortal(newSVnv(load[1])));
    XPUSHs(sv_2mortal(newSVnv(load[2])));
  }


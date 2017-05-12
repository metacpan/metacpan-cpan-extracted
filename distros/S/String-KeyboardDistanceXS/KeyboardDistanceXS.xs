#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "keyboardDistance.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

MODULE = String::KeyboardDistanceXS		PACKAGE = String::KeyboardDistanceXS		


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL

double
qwertyKeyboardDistance(left,right)
  PREINIT:
    STRLEN llen;
    STRLEN rlen;
  INPUT:
    SV* left
    SV* right
    char* pleft  = SvPV(left, llen);
    char* pright = SvPV(right,rlen);
  CODE:
    RETVAL = c_qwertyKeyboardDistance( pleft, llen, pright, rlen );
  OUTPUT:
    RETVAL

double
qwertyKeyboardDistanceMatch(left,right)
  PREINIT:
    STRLEN llen;
    STRLEN rlen;
  INPUT:
    SV* left
    SV* right
    char* pleft  = SvPV(left, llen);
    char* pright = SvPV(right,rlen);
  CODE:
    RETVAL = c_qwertyKeyboardDistanceMatch( pleft, llen, pright, rlen );
  OUTPUT:
    RETVAL

int
initQwertyMap()
  CODE:
    RETVAL = c_initQwertyMap();
  OUTPUT:
   RETVAL


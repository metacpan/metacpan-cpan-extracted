#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

#include <monetary.h>

MODULE = PHP::Strings		PACKAGE = PHP::Strings		

INCLUDE: const-xs.inc

char *
_strfmon( fmt, amount ) 
    char *fmt
    double amount
    INIT:
      int rv;
      int buflen = 4096;
    CODE:
      New(0, RETVAL, buflen, char);
      /* ssize_t strfmon(char *s, size_t max, const char *format, ...); */
      rv = strfmon( RETVAL, buflen, fmt, amount );
    OUTPUT:
      RETVAL

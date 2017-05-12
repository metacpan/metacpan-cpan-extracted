#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


MODULE = PeekPoke		PACKAGE = PeekPoke		

IV peek(p)
        IV p;
        CODE:
        {
          RETVAL = *(IV *)p;
        }
        OUTPUT:
        RETVAL

void poke(p, v)
        IV p;
        IV v;
        CODE:
        {
          *(IV *)p = v;
        }


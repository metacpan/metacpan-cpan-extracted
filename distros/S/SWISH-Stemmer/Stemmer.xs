#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "lib/stemmer.h"


MODULE = SWISH::Stemmer		PACKAGE = SWISH::Stemmer		

PROTOTYPES: DISABLE

char *
SwishStem(word)
     char *word
     CODE:
     RETVAL = (char*)SwishStem(word);
     OUTPUT:
     RETVAL

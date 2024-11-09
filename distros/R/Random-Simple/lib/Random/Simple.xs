#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <stdlib.h>         // rand()
#include <stdint.h>         // uint64_t

#include "pcg.h"

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

MODULE = Random::Simple  PACKAGE = Random::Simple
PROTOTYPES: ENABLE

 # XS code goes here

 # XS comments begin with " #" to avoid them being interpreted as pre-processor
 # directives

U32
rand32()

UV
rand64()

void
pcg32_seed(UV seed1, UV seed2)

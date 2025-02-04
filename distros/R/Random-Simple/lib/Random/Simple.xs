#define PERL_NO_GET_CONTEXT  // we'll define thread context if necessary (faster)
#include "EXTERN.h"          // globals/constant import locations
#include "perl.h"            // Perl symbols, structures and constants definition
#include "XSUB.h"            // xsubpp functions and macros
#include <stdlib.h>          // rand()
#include <stdint.h>          // uint64_t
#include "rand-common.h"

#include "pcg.h"

// Alernate PRNGs available
//#include "xorshiro.h"
//#include "xoroshiro128starstar.h"
//#include "splitmix64.h"
//
// Other PRGNs just need three functions _seed(S1,S2), _rand32(),
// and _rand64()

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

MODULE = Random::Simple  PACKAGE = Random::Simple
PROTOTYPES: ENABLE

 # XS code goes here

 # XS comments begin with " #" to avoid them being interpreted as pre-processor
 # directives

U32 _rand32()

UV _rand64()

UV _hash_mur3(UV seed1)

void _seed(UV seed1, UV seed2)

U32 _bounded_rand(UV range)

double _uint64_to_double(UV num)

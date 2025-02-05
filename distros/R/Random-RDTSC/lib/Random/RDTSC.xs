#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "rdtsc_rand.h"  // Include the header from the repo

MODULE = Random::RDTSC PACKAGE = Random::RDTSC

PROTOTYPES: DISABLE

UV
get_rdtsc()
    CODE:
        RETVAL = get_rdtsc();
    OUTPUT:
        RETVAL

UV
rdtsc_rand64()
    CODE:
        RETVAL = rdtsc_rand64();
    OUTPUT:
        RETVAL

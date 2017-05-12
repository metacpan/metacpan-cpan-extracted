#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "SOOT_RTXS.h"
#include "SOOT_RTXS_macros.h"

MODULE = SOOT        PACKAGE = SOOT::RTXS
PROTOTYPES: DISABLE

BOOT:
#ifdef USE_ITHREADS
_init_soot_rtxs_lock(&SOOT_RTXS_lock); /* cf. SOOT_RTXS.h */
#endif /* USE_ITHREADS */

void
END()
    PROTOTYPE:
    CODE:
        if (SOOT_RTXS_reverse_hashkeys) {
            SOOT_RTXS_HashTable_free(SOOT_RTXS_reverse_hashkeys);
        }

INCLUDE: ../RunTimeXS/SOOT_RTXS_scalar.xs

INCLUDE: ../RunTimeXS/SOOT_RTXS_array.xs


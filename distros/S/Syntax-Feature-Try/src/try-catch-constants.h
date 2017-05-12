#ifndef __TRY_CATCH_CONSTANTS__
#define __TRY_CATCH_CONSTANTS__

#include <perl.h>

/*** constants ***/

#define MAIN_PKG            "Syntax::Feature::Try"
#define HINTKEY_ENABLED     MAIN_PKG "/enabled"

static HV *internal_stash;
static SV *hintkey_enabled_sv;

#define setup_constants()   my_setup_constants(aTHX)
static void my_setup_constants(pTHX);

#endif /* __TRY_CATCH_CONSTANTS__ */

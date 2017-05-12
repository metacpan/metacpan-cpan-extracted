#include <perl.h>
#include "try-catch-constants.h"

static void my_setup_constants(pTHX) {
    internal_stash = gv_stashpv(MAIN_PKG, 0);

    hintkey_enabled_sv = newSVpvs_share(HINTKEY_ENABLED);
    newCONSTSUB(internal_stash, "HINTKEY_ENABLED",   hintkey_enabled_sv);
}

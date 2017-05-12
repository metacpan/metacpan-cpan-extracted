#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Salvation::UpdateGvFLAGS PACKAGE = Salvation::UpdateGvFLAGS

PROTOTYPES: DISABLED

void
toggle( sv, flag )
        SV * sv
        U32 flag
    CODE:
        GvFLAGS(sv) ^= flag;

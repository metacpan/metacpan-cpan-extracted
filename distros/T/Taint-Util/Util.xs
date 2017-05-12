#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Taint::Util PACKAGE = Taint::Util

void
tainted(SV *sv)
PPCODE:
    EXTEND(SP, 1);
    if (SvTAINTED(sv))
        PUSHs(&PL_sv_yes);
    else
        PUSHs(&PL_sv_no);

void
taint(...)
PREINIT:
    I32 i;
PPCODE:
    for (i = 0; i < items; ++i)
        if (!SvREADONLY(ST(i)))
            SvTAINTED_on(ST(i));

void
untaint(...)
PREINIT:
    I32 i;
PPCODE:
    for (i = 0; i < items; ++i)
        SvTAINTED_off(ST(i));

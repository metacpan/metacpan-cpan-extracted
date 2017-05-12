#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Perl::SVCount PACKAGE = Perl::SVCount PREFIX = psvc_

I32
psvc_sv_count()
    CODE:
        RETVAL = PL_sv_count;
    OUTPUT:
        RETVAL

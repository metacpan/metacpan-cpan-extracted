#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "xshelper.h"

MODULE = Foo PACKAGE = Foo

SV *
ok()
CODE:
    RETVAL = newSVpv( "ok", 0 );
OUTPUT:
    RETVAL

const char *
xs_version()
CODE:
    RETVAL = XS_VERSION;
OUTPUT:
    RETVAL

const char *
version()
CODE:
    RETVAL = VERSION;
OUTPUT:
    RETVAL
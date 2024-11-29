#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <mongoc/mongoc.h>
#define XS_BOTHVERSION_SETXSUBFN_POPMARK_BOOTCHECK 1

MODULE = Pongo::CheckVersion PACKAGE = Pongo::CheckVersion

bool
get_mongoc_check_version(required_major, required_minor, required_micro)
    int required_major;
    int required_minor;
    int required_micro;
    CODE:
        RETVAL = mongoc_check_version(required_major, required_minor, required_micro);
    OUTPUT:
        RETVAL

int
get_mongoc_major_version()
    CODE:
        RETVAL = mongoc_get_major_version();
    OUTPUT:
        RETVAL

int
get_mongoc_minor_version()
    CODE:
        RETVAL = mongoc_get_minor_version();
    OUTPUT:
        RETVAL

int
get_mongoc_micro_version()
    CODE:
        RETVAL = mongoc_get_micro_version();
    OUTPUT:
        RETVAL

const char *
get_mongoc_version()
    CODE:
        RETVAL = mongoc_get_version();
    OUTPUT:
        RETVAL
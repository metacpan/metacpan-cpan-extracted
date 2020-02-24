#!/usr/bin/perl -n

# types_h2xi.pl /usr/local/include/open62541/types_generated.h
#    >Open62541-types.xsh

use strict;
use warnings;

/#define\s+UA_TYPES_(\S+)\s+/
    or next;
print <<"XSINC"
UA_UInt16
TYPES_$1()
    CODE:
        RETVAL = UA_TYPES_$1;
    OUTPUT:
        RETVAL

XSINC

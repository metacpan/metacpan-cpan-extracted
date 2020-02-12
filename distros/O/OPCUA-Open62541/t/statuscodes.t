use strict;
use warnings;
use OPCUA::Open62541 ':statuscode';

use Test::More tests => 4;
use Test::NoWarnings;

ok(defined(OPCUA::Open62541::STATUSCODE_GOOD()), "name space");
is(STATUSCODE_GOOD, 0, "first");
is(STATUSCODE_BADMAXCONNECTIONSREACHED, 0x80B70000, "last");

# Check that the automatically generated Perl constants from defines
# work correctly.  Use samples to test.

use strict;
use warnings;
use OPCUA::Open62541 qw(:WRITEMASK VALUERANK_ANY);

use Test::More tests => 10;
use Test::Exception;
use Test::NoWarnings;

cmp_ok(OPCUA::Open62541::ACCESSLEVELMASK_READ, '==', 1,
    "accesslevelmask first");
cmp_ok(OPCUA::Open62541::ACCESSLEVELMASK_TIMESTAMPWRITE, '==', 64,
    "accesslevelmask last");
throws_ok { ACCESSLEVELMASK_READ() }
    (qr/Undefined subroutine &main::ACCESSLEVELMASK_READ called /,
    "accesslevelmask no import");

cmp_ok(OPCUA::Open62541::WRITEMASK_ACCESSLEVEL, '==', 1, "writemask full");
cmp_ok(WRITEMASK_ACCESSLEVEL, '==', 1, "writemask import");

cmp_ok(OPCUA::Open62541::VALUERANK_ANY, '==', -2, "valuerank full");
cmp_ok(VALUERANK_ANY, '==', -2, "valuerank import");
throws_ok { VALUERANK_SCALAR() }
    (qr/Undefined subroutine &main::VALUERANK_SCALAR called /,
    "valuerank no import");
throws_ok { OPCUA::Open62541->import('VALUERANK_NOEXIST') }
    (qr/"VALUERANK_NOEXIST" is not exported by the OPCUA::Open62541 module/,
    "valuerank no export");

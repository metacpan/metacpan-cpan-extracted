use strict;
use warnings;
use OPCUA::Open62541 ':statuscode';

use Test::More tests => 11;
use Test::NoWarnings;

ok(defined(OPCUA::Open62541::STATUSCODE_GOOD()), "name space");

is(STATUSCODE_GOOD, "Good", "first");
is(0+STATUSCODE_GOOD, 0, "first number");
is("".STATUSCODE_GOOD, "Good", "first string");
cmp_ok(STATUSCODE_GOOD, '==', 0, "first ==");
cmp_ok(STATUSCODE_GOOD, 'eq', "Good", "first eq");
like(STATUSCODE_GOOD, qr/Good/, "first regex");

is(0+STATUSCODE_BADMAXCONNECTIONSREACHED, 0x80B70000, "last number");

is(0+OPCUA::Open62541::STATUSCODE_UNKNOWN, 0xffffffff, "unknown number");
is("".OPCUA::Open62541::STATUSCODE_UNKNOWN, 0xffffffff, "unknown string");

use strict;
use warnings;
use OPCUA::Open62541 qw(:type :limit);

use Test::More tests => 84;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

ok(my $variant = OPCUA::Open62541::Variant->new(), "variant new");
no_leaks_ok { OPCUA::Open62541::Variant->new() } "variant new leak";
ok($variant->isEmpty(), "variant empty");
ok(!$variant->isScalar(), "variant not scalar");
ok(!defined($variant->getType()), "type undef");
ok(!defined($variant->getScalar()), "scalar undef");

no_leaks_ok { $variant->setScalar(1, TYPES_SBYTE) } "scalar set leak";
ok(!$variant->isEmpty(), "variant not empty");
no_leaks_ok { $variant->isEmpty() } "empty leak";
ok($variant->isScalar(), "variant scalar");
no_leaks_ok { $variant->isScalar() } "scalar leak";
ok(defined($variant->getType()), "type defined");
no_leaks_ok { $variant->getType() } "type get leak";
ok(defined($variant->getScalar()), "scalar defined");
no_leaks_ok { $variant->getScalar() } "scalar get leak";

warnings_like { $variant->setScalar(undef, TYPES_SBYTE) }
    (qr/Use of uninitialized value in subroutine entry/, "value undef warn");
no_leaks_ok {
    no warnings 'uninitialized';
    $variant->setScalar(undef, TYPES_SBYTE);
} "value undef leak";

warnings_like { $variant->setScalar(1, undef) }
    (qr/Use of uninitialized value in subroutine entry/, "type undef warn");
no_leaks_ok {
    no warnings 'uninitialized';
    $variant->setScalar(1, undef)
} "type undef leak";

warnings_like { $variant->setScalar("", TYPES_SBYTE) }
    (qr/Argument "" isn't numeric in subroutine entry/, "value string warn");
no_leaks_ok {
    no warnings 'numeric';
    $variant->setScalar("", TYPES_SBYTE);
} "value string leak";

warnings_like { $variant->setScalar(1, "") }
    (qr/Argument "" isn't numeric in subroutine entry/, "type string warn");
no_leaks_ok {
    no warnings 'numeric';
     $variant->setScalar(1, "")
} "type string leak";

eval { $variant->setScalar("", OPCUA::Open62541::TYPES_COUNT) };
ok($@, "scalar TYPES_COUNT");
like($@, qr/Unsigned value .* not below UA_TYPES_COUNT /, "not below COUNT");

throws_ok { $variant->setScalar("", -1) }
    (qr/Unsigned value .* not below UA_TYPES_COUNT /, "scalar type -1");
no_leaks_ok { eval { $variant->setScalar("", -1) } } "scalar type -1 leak";

$variant->setScalar(TRUE, TYPES_BOOLEAN);
is($variant->getScalar(), 1, "scalar TYPES_BOOLEAN TRUE");
$variant->setScalar(1, TYPES_BOOLEAN);
is($variant->getScalar(), 1, "scalar TYPES_BOOLEAN 1");
$variant->setScalar('1', TYPES_BOOLEAN);
is($variant->getScalar(), 1, "scalar TYPES_BOOLEAN '1'");
$variant->setScalar('foo', TYPES_BOOLEAN);
is($variant->getScalar(), 1, "scalar TYPES_BOOLEAN 'foo'");
$variant->setScalar(FALSE, TYPES_BOOLEAN);
is($variant->getScalar(), '', "scalar TYPES_BOOLEAN FALSE");
$variant->setScalar(undef, TYPES_BOOLEAN);
is($variant->getScalar(), '', "scalar TYPES_BOOLEAN undef");
$variant->setScalar(0, TYPES_BOOLEAN);
is($variant->getScalar(), '', "scalar TYPES_BOOLEAN 0");
$variant->setScalar('0', TYPES_BOOLEAN);
is($variant->getScalar(), '', "scalar TYPES_BOOLEAN '0'");
$variant->setScalar('', TYPES_BOOLEAN);
is($variant->getScalar(), '', "scalar TYPES_BOOLEAN ''");
ok($variant->hasScalarType(TYPES_BOOLEAN), "variant TYPES_BOOLEAN");
is($variant->getType(), TYPES_BOOLEAN, "type TYPES_BOOLEAN");

$variant->setScalar(0, TYPES_SBYTE);
is($variant->getScalar(), 0, "scalar TYPES_SBYTE 0");
$variant->setScalar(-128, TYPES_SBYTE);
is($variant->getScalar(), -128, "scalar TYPES_SBYTE -128");
$variant->setScalar(127, TYPES_SBYTE);
is($variant->getScalar(), 127, "scalar TYPES_SBYTE 127");
warnings_like { $variant->setScalar(-129, TYPES_SBYTE) }
    (qr/Integer value -129 less than UA_SBYTE_MIN /, "sbyte min" );
warnings_like { $variant->setScalar(128, TYPES_SBYTE) }
    (qr/Integer value 128 greater than UA_SBYTE_MAX /, "sbyte max" );
ok($variant->hasScalarType(TYPES_SBYTE), "variant TYPES_SBYTE");
is($variant->getType(), TYPES_SBYTE, "type TYPES_SBYTE");

$variant->setScalar(0, TYPES_BYTE);
is($variant->getScalar(), 0, "scalar TYPES_BYTE 0");
$variant->setScalar(255, TYPES_BYTE);
is($variant->getScalar(), 255, "scalar TYPES_BYTE 255");
warnings_like { $variant->setScalar(256, TYPES_BYTE) }
    (qr/Unsigned value 256 greater than UA_BYTE_MAX /, "byte max" );
ok($variant->hasScalarType(TYPES_BYTE), "variant TYPES_BYTE");
is($variant->getType(), TYPES_BYTE, "type TYPES_BYTE");

$variant->setScalar(0, TYPES_INT16);
is($variant->getScalar(), 0, "scalar TYPES_INT16 0");
$variant->setScalar(-0x8000, TYPES_INT16);
is($variant->getScalar(), -0x8000, "scalar TYPES_INT16 -0x8000");
$variant->setScalar(0x7fff, TYPES_INT16);
is($variant->getScalar(), 0x7fff, "scalar TYPES_INT16 0x7fff");
warnings_like { $variant->setScalar(-0x8001, TYPES_INT16) }
    (qr/Integer value -32769 less than UA_INT16_MIN /, "int16 min" );
warnings_like { $variant->setScalar(0x8000, TYPES_INT16) }
    (qr/Integer value 32768 greater than UA_INT16_MAX /, "int16 max" );
ok($variant->hasScalarType(TYPES_INT16), "variant TYPES_INT16");
is($variant->getType(), TYPES_INT16, "type TYPES_INT16");

$variant->setScalar(0, TYPES_UINT16);
is($variant->getScalar(), 0, "scalar TYPES_UINT16 0");
$variant->setScalar(0xffff, TYPES_UINT16);
is($variant->getScalar(), 0xffff, "scalar TYPES_UINT16 0xffff");
warnings_like { $variant->setScalar(0x10000, TYPES_UINT16) }
    (qr/Unsigned value 65536 greater than UA_UINT16_MAX /, "uint16 max" );
ok($variant->hasScalarType(TYPES_UINT16), "variant TYPES_UINT16");
is($variant->getType(), TYPES_UINT16, "type TYPES_UINT16");

$variant->setScalar(0, TYPES_INT32);
is($variant->getScalar(), 0, "scalar TYPES_INT32 0");
$variant->setScalar(-0x80000000, TYPES_INT32);
is($variant->getScalar(), -0x80000000, "scalar TYPES_INT32 -0x80000000");
$variant->setScalar(0x7fffffff, TYPES_INT32);
is($variant->getScalar(), 0x7fffffff, "scalar TYPES_INT32 0x7fffffff");
warnings_like { $variant->setScalar(-0x80000001, TYPES_INT32) }
    (qr/Integer value -2147483649 less than UA_INT32_MIN /, "int32 min" );
warnings_like { $variant->setScalar(0x80000000, TYPES_INT32) }
    (qr/Integer value 2147483648 greater than UA_INT32_MAX /, "int32 max" );
ok($variant->hasScalarType(TYPES_INT32), "variant TYPES_INT32");
is($variant->getType(), TYPES_INT32, "type TYPES_INT32");

$variant->setScalar(0, TYPES_UINT32);
is($variant->getScalar(), 0, "scalar TYPES_UINT32 0");
$variant->setScalar(0xffffffff, TYPES_UINT32);
is($variant->getScalar(), 0xffffffff, "scalar TYPES_UINT32 0xffffffff");
# XXX this only works for Perl on 64 bit platforms
warnings_like { $variant->setScalar(1<<32, TYPES_UINT32) }
    (qr/Unsigned value 4294967296 greater than UA_UINT32_MAX /, "uint32 max" );
ok($variant->hasScalarType(TYPES_UINT32), "variant TYPES_UINT32");
is($variant->getType(), TYPES_UINT32, "type TYPES_UINT32");

# XXX this only works for Perl on 64 bit platforms
$variant->setScalar(0, TYPES_INT64);
is($variant->getScalar(), 0, "scalar TYPES_INT64 0");
$variant->setScalar(-(1<<63), TYPES_INT64);
is($variant->getScalar(), -(1<<63), "scalar TYPES_INT64 -(1<<63)");
$variant->setScalar((1<<63)-1, TYPES_INT64);
is($variant->getScalar(), (1<<63)-1, "scalar TYPES_INT64 (1<<63)-1");
# no overflow possible
ok($variant->hasScalarType(TYPES_INT64), "variant TYPES_INT64");
is($variant->getType(), TYPES_INT64, "type TYPES_INT64");

$variant->setScalar(0, TYPES_UINT64);
is($variant->getScalar(), 0, "scalar TYPES_UINT64 0");
$variant->setScalar(18446744073709551615, TYPES_UINT64);
is($variant->getScalar(), 18446744073709551615,
    "scalar TYPES_UINT64 18446744073709551615");
# no overflow possible
ok($variant->hasScalarType(TYPES_UINT64), "variant TYPES_UINT64");
is($variant->getType(), TYPES_UINT64, "type TYPES_UINT64");

use strict;
use warnings;
use OPCUA::Open62541 qw(:type :limit);

use Test::More tests => 35;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

no_leaks_ok {
    my $variant = OPCUA::Open62541::Variant->new();
} "leak variant new";

my $variant = OPCUA::Open62541::Variant->new();
ok($variant, "variant new");
ok($variant->isEmpty(), "variant empty");
ok(!$variant->isScalar(), "variant not scalar");

$variant->setScalar(1, TYPES_SBYTE);
ok(!$variant->isEmpty(), "variant not empty");
ok($variant->isScalar(), "variant scalar");

warnings_like { $variant->setScalar(undef, TYPES_SBYTE) }
    (qr/Use of uninitialized value in subroutine entry/, "value undef warn");

warnings_like { $variant->setScalar(1, undef) }
    (qr/Use of uninitialized value in subroutine entry/, "type undef warn");

warnings_like { $variant->setScalar("", TYPES_SBYTE) }
    (qr/Argument "" isn't numeric in subroutine entry/, "value string warn");

warnings_like { $variant->setScalar(1, "") }
    (qr/Argument "" isn't numeric in subroutine entry/, "type string warn");

eval { $variant->setScalar("", TYPES_EVENTNOTIFICATIONLIST) };
ok($@, "scalar TYPES_EVENTNOTIFICATIONLIST");
like($@, qr/type EventNotificationList .* not implemented/, "not implemented");

eval { $variant->setScalar("", OPCUA::Open62541::TYPES_COUNT) };
ok($@, "scalar TYPES_COUNT");
like($@, qr/unsigned value .* not below UA_TYPES_COUNT /, "not below COUNT");

eval { $variant->setScalar("", -1) };
ok($@, "scalar type -1");
like($@, qr/unsigned value .* not below UA_TYPES_COUNT /, "not below -1");

$variant->setScalar(TRUE, TYPES_BOOLEAN);
$variant->setScalar(1, TYPES_BOOLEAN);
$variant->setScalar("1", TYPES_BOOLEAN);
$variant->setScalar("foo", TYPES_BOOLEAN);
$variant->setScalar(FALSE, TYPES_BOOLEAN);
$variant->setScalar(undef, TYPES_BOOLEAN);
$variant->setScalar(0, TYPES_BOOLEAN);
$variant->setScalar("0", TYPES_BOOLEAN);
$variant->setScalar("", TYPES_BOOLEAN);
ok($variant->hasScalarType(TYPES_BOOLEAN), "variant TYPES_BOOLEAN");

$variant->setScalar(0, TYPES_SBYTE);
$variant->setScalar(-128, TYPES_SBYTE);
$variant->setScalar(127, TYPES_SBYTE);
warnings_like { $variant->setScalar(-129, TYPES_SBYTE) }
    (qr/Integer value -129 less than UA_SBYTE_MIN /, "sbyte min" );
warnings_like { $variant->setScalar(128, TYPES_SBYTE) }
    (qr/Integer value 128 greater than UA_SBYTE_MAX /, "sbyte max" );
ok($variant->hasScalarType(TYPES_SBYTE), "variant TYPES_SBYTE");

$variant->setScalar(0, TYPES_BYTE);
$variant->setScalar(255, TYPES_BYTE);
warnings_like { $variant->setScalar(256, TYPES_BYTE) }
    (qr/Unsigned value 256 greater than UA_BYTE_MAX /, "byte max" );
ok($variant->hasScalarType(TYPES_BYTE), "variant TYPES_BYTE");

$variant->setScalar(0, TYPES_INT16);
$variant->setScalar(-0x8000, TYPES_INT16);
$variant->setScalar(0x7fff, TYPES_INT16);
warnings_like { $variant->setScalar(-0x8001, TYPES_INT16) }
    (qr/Integer value -32769 less than UA_INT16_MIN /, "int16 min" );
warnings_like { $variant->setScalar(0x8000, TYPES_INT16) }
    (qr/Integer value 32768 greater than UA_INT16_MAX /, "int16 max" );
ok($variant->hasScalarType(TYPES_INT16), "variant TYPES_INT16");

$variant->setScalar(0, TYPES_UINT16);
$variant->setScalar(0xffff, TYPES_UINT16);
warnings_like { $variant->setScalar(0x10000, TYPES_UINT16) }
    (qr/Unsigned value 65536 greater than UA_UINT16_MAX /, "uint16 max" );
ok($variant->hasScalarType(TYPES_UINT16), "variant TYPES_UINT16");

$variant->setScalar(0, TYPES_INT32);
$variant->setScalar(-0x80000000, TYPES_INT32);
$variant->setScalar(0x7fffffff, TYPES_INT32);
warnings_like { $variant->setScalar(-0x80000001, TYPES_INT32) }
    (qr/Integer value -2147483649 less than UA_INT32_MIN /, "int32 min" );
warnings_like { $variant->setScalar(0x80000000, TYPES_INT32) }
    (qr/Integer value 2147483648 greater than UA_INT32_MAX /, "int32 max" );
ok($variant->hasScalarType(TYPES_INT32), "variant TYPES_INT32");

$variant->setScalar(0, TYPES_UINT32);
$variant->setScalar(0xffffffff, TYPES_UINT32);
# XXX this only works for Perl on 64 bit platforms
warnings_like { $variant->setScalar(1<<32, TYPES_UINT32) }
    (qr/Unsigned value 4294967296 greater than UA_UINT32_MAX /, "uint32 max" );
ok($variant->hasScalarType(TYPES_UINT32), "variant TYPES_UINT32");

# XXX this only works for Perl on 64 bit platforms
$variant->setScalar(0, TYPES_INT64);
$variant->setScalar(-(1<<63), TYPES_INT64);
$variant->setScalar((1<<63)-1, TYPES_INT64);
# no overflow possible
ok($variant->hasScalarType(TYPES_INT64), "variant TYPES_INT64");

$variant->setScalar(0, TYPES_UINT64);
$variant->setScalar(18446744073709551615, TYPES_UINT64);
# no overflow possible
ok($variant->hasScalarType(TYPES_UINT64), "variant TYPES_UINT64");

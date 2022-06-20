use strict;
use warnings;
use OPCUA::Open62541 ':TYPES';

use Test::More tests => 115;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

ok(my $variant = OPCUA::Open62541::Variant->new(), "variant new");

no_leaks_ok { $variant->setScalar(1, TYPES_SBYTE) } "scalar leak";
is($variant->getScalar(), 1, "scalar");

warning_like { $variant->setScalar(undef, TYPES_SBYTE) }
    (qr/Use of uninitialized value in subroutine entry/, "value undef warn");
no_leaks_ok {
    no warnings 'uninitialized';
    $variant->setScalar(undef, TYPES_SBYTE);
} "value undef leak";

warning_like { $variant->setScalar(3, undef) }
    (qr/Use of uninitialized value in subroutine entry/, "type undef warn");
no_leaks_ok {
    no warnings 'uninitialized';
    $variant->setScalar(3, undef)
} "type undef leak";
is($variant->getScalar(), 1, "type undef");

warning_like { $variant->setScalar("", TYPES_SBYTE) }
    (qr/Argument "" isn't numeric in subroutine entry/, "value string warn");
no_leaks_ok {
    no warnings 'numeric';
    $variant->setScalar("", TYPES_SBYTE);
} "value string leak";
is($variant->getScalar(), 0, "value string");

warning_like { $variant->setScalar(2, "") }
    (qr/Argument "" isn't numeric in subroutine entry/, "type string warn");
no_leaks_ok {
    no warnings 'numeric';
     $variant->setScalar(2, "")
} "type string leak";
is($variant->getScalar(), 1, "type string");

throws_ok { $variant->setScalar("", OPCUA::Open62541::TYPES_COUNT) }
    (qr/Unsigned value .* not below UA_TYPES_COUNT /, "set below COUNT");
no_leaks_ok { eval {
    $variant->setScalar("", OPCUA::Open62541::TYPES_COUNT)
} } "set below COUNT leak";

throws_ok { $variant->setScalar("", -1) }
    (qr/Unsigned value .* not below UA_TYPES_COUNT /, "set type -1");
no_leaks_ok { eval { $variant->setScalar("", -1) } } "set type -1 leak";

$variant->setScalar(1, TYPES_SBYTE);
ok($variant->hasScalarType(TYPES_SBYTE), "has type");
no_leaks_ok { $variant->hasScalarType(TYPES_SBYTE) } "has type leak";
ok(!$variant->hasScalarType(TYPES_BYTE), "has type false");

throws_ok { $variant->hasScalarType(OPCUA::Open62541::TYPES_COUNT) }
    (qr/Unsigned value .* not below UA_TYPES_COUNT /, "has type below COUNT");
no_leaks_ok { eval {
    $variant->hasScalarType(OPCUA::Open62541::TYPES_COUNT)
} } "has type below COUNT leak";

throws_ok { $variant->hasScalarType(-1) }
    (qr/Unsigned value .* not below UA_TYPES_COUNT /, "has type -1");
no_leaks_ok { eval { $variant->hasScalarType(-1) } } "has type -1";

$variant->setScalar(OPCUA::Open62541::TRUE, TYPES_BOOLEAN);
is($variant->getScalar(), 1, "scalar TYPES_BOOLEAN TRUE");
$variant->setScalar(1, TYPES_BOOLEAN);
is($variant->getScalar(), 1, "scalar TYPES_BOOLEAN 1");
$variant->setScalar(2, TYPES_BOOLEAN);
is($variant->getScalar(), 1, "scalar TYPES_BOOLEAN 2");
$variant->setScalar('1', TYPES_BOOLEAN);
is($variant->getScalar(), 1, "scalar TYPES_BOOLEAN '1'");
$variant->setScalar('foo', TYPES_BOOLEAN);
is($variant->getScalar(), 1, "scalar TYPES_BOOLEAN 'foo'");
$variant->setScalar(OPCUA::Open62541::FALSE, TYPES_BOOLEAN);
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
throws_ok { $variant->setScalar(-129, TYPES_SBYTE) }
    (qr/Integer value -129 less than UA_SBYTE_MIN /, "sbyte min");
no_leaks_ok { eval { $variant->setScalar(-129, TYPES_SBYTE) } }
    "sbyte min leak";
throws_ok { $variant->setScalar(128, TYPES_SBYTE) }
    (qr/Integer value 128 greater than UA_SBYTE_MAX /, "sbyte max");
no_leaks_ok { eval { $variant->setScalar(128, TYPES_SBYTE) } }
    "sbyte max leak";
ok($variant->hasScalarType(TYPES_SBYTE), "variant TYPES_SBYTE");
is($variant->getType(), TYPES_SBYTE, "type TYPES_SBYTE");

$variant->setScalar(0, TYPES_BYTE);
is($variant->getScalar(), 0, "scalar TYPES_BYTE 0");
$variant->setScalar(255, TYPES_BYTE);
is($variant->getScalar(), 255, "scalar TYPES_BYTE 255");
throws_ok { $variant->setScalar(256, TYPES_BYTE) }
    (qr/Unsigned value 256 greater than UA_BYTE_MAX /, "byte max");
no_leaks_ok { eval { $variant->setScalar(256, TYPES_BYTE) } }
    "byte max leak";
ok($variant->hasScalarType(TYPES_BYTE), "variant TYPES_BYTE");
is($variant->getType(), TYPES_BYTE, "type TYPES_BYTE");

$variant->setScalar(0, TYPES_INT16);
is($variant->getScalar(), 0, "scalar TYPES_INT16 0");
$variant->setScalar(-0x8000, TYPES_INT16);
is($variant->getScalar(), -0x8000, "scalar TYPES_INT16 -0x8000");
$variant->setScalar(0x7fff, TYPES_INT16);
is($variant->getScalar(), 0x7fff, "scalar TYPES_INT16 0x7fff");
throws_ok { $variant->setScalar(-0x8001, TYPES_INT16) }
    (qr/Integer value -32769 less than UA_INT16_MIN /, "int16 min");
no_leaks_ok { eval { $variant->setScalar(-0x8001, TYPES_INT16) } }
    "int16 min leak";
throws_ok { $variant->setScalar(0x8000, TYPES_INT16) }
    (qr/Integer value 32768 greater than UA_INT16_MAX /, "int16 max");
no_leaks_ok { eval { $variant->setScalar(0x8000, TYPES_INT16) } }
    "int16 max leak";
ok($variant->hasScalarType(TYPES_INT16), "variant TYPES_INT16");
is($variant->getType(), TYPES_INT16, "type TYPES_INT16");

$variant->setScalar(0, TYPES_UINT16);
is($variant->getScalar(), 0, "scalar TYPES_UINT16 0");
$variant->setScalar(0xffff, TYPES_UINT16);
is($variant->getScalar(), 0xffff, "scalar TYPES_UINT16 0xffff");
throws_ok { $variant->setScalar(0x10000, TYPES_UINT16) }
    (qr/Unsigned value 65536 greater than UA_UINT16_MAX /, "uint16 max");
no_leaks_ok { eval { $variant->setScalar(0x10000, TYPES_UINT16) } }
    "uint16 max leak";
ok($variant->hasScalarType(TYPES_UINT16), "variant TYPES_UINT16");
is($variant->getType(), TYPES_UINT16, "type TYPES_UINT16");

$variant->setScalar(0, TYPES_INT32);
is($variant->getScalar(), 0, "scalar TYPES_INT32 0");
$variant->setScalar(-0x80000000, TYPES_INT32);
is($variant->getScalar(), -0x80000000, "scalar TYPES_INT32 -0x80000000");
$variant->setScalar(0x7fffffff, TYPES_INT32);
is($variant->getScalar(), 0x7fffffff, "scalar TYPES_INT32 0x7fffffff");
throws_ok { $variant->setScalar(-0x80000001, TYPES_INT32) }
    (qr/Integer value -2147483649 less than UA_INT32_MIN /, "int32 min");
no_leaks_ok { eval { $variant->setScalar(-0x80000001, TYPES_INT32) } }
    "int32 min leak";
throws_ok { $variant->setScalar(0x80000000, TYPES_INT32) }
    (qr/Integer value 2147483648 greater than UA_INT32_MAX /, "int32 max");
no_leaks_ok { eval { $variant->setScalar(0x80000000, TYPES_INT32) } }
    "int32 max leak";
ok($variant->hasScalarType(TYPES_INT32), "variant TYPES_INT32");
is($variant->getType(), TYPES_INT32, "type TYPES_INT32");

$variant->setScalar(0, TYPES_UINT32);
is($variant->getScalar(), 0, "scalar TYPES_UINT32 0");
$variant->setScalar(0xffffffff, TYPES_UINT32);
is($variant->getScalar(), 0xffffffff, "scalar TYPES_UINT32 0xffffffff");
# XXX this only works for Perl on 64 bit platforms
throws_ok { $variant->setScalar(1<<32, TYPES_UINT32) }
    (qr/Unsigned value 4294967296 greater than UA_UINT32_MAX /, "uint32 max");
no_leaks_ok { eval { $variant->setScalar(1<<32, TYPES_UINT32) } }
    "uint32 max leak";
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

$variant->setScalar(0, TYPES_FLOAT);
is($variant->getScalar(), 0, "scalar TYPES_FLOAT 0");
$variant->setScalar(1.17549435082229E-38, TYPES_FLOAT);
is($variant->getScalar(), 1.17549435082229E-38, "scalar TYPES_FLOAT MIN");
$variant->setScalar(3.4028230607371E+38, TYPES_FLOAT);
is($variant->getScalar(), 3.4028230607371E+38, "scalar TYPES_FLOAT MAX");
$variant->setScalar("Infinity", TYPES_FLOAT);
is($variant->getScalar(), "Inf", "scalar TYPES_FLOAT Inf");
$variant->setScalar("-Inf", TYPES_FLOAT);
is($variant->getScalar(), "-Inf", "scalar TYPES_FLOAT -Inf");
$variant->setScalar("NaN", TYPES_FLOAT);
is($variant->getScalar(), "NaN", "scalar TYPES_FLOAT NaN");

throws_ok { $variant->setScalar(-3.40282347E+38, TYPES_FLOAT) }
    (qr/Float value -3.402823e\+38 less than -3.402823e\+38 /,
    "TYPES_FLOAT min");
no_leaks_ok { eval { $variant->setScalar(-3.40282347E+38, TYPES_FLOAT) } }
    "TYPES_FLOAT min leak";
throws_ok { $variant->setScalar(3.40282347E+38, TYPES_FLOAT) }
    (qr/Float value 3.402823e\+38 greater than 3.402823e\+38 /,
    "TYPES_FLOAT max");
no_leaks_ok { eval { $variant->setScalar(3.40282347E+38, TYPES_FLOAT) } }
    "TYPES_FLOAT max leak";
ok($variant->hasScalarType(TYPES_FLOAT), "variant TYPES_FLOAT");
is($variant->getType(), TYPES_FLOAT, "type TYPES_FLOAT");

$variant->setScalar(0, TYPES_DOUBLE);
is($variant->getScalar(), 0, "scalar TYPES_DOUBLE 0");
$variant->setScalar(2.2250738585072014E-308, TYPES_DOUBLE);
is($variant->getScalar(), 2.2250738585072014E-308, "scalar TYPES_DOUBLE MIN");
$variant->setScalar(1.7976931348623157E+308, TYPES_DOUBLE);
is($variant->getScalar(), 1.7976931348623157E+308, "scalar TYPES_DOUBLE MAX");
# no overflow possible
ok($variant->hasScalarType(TYPES_DOUBLE), "variant TYPES_DOUBLE");
is($variant->getType(), TYPES_DOUBLE, "type TYPES_DOUBLE");

my $g;
{
    my $s = "foo";
    no_leaks_ok {
	my $v = OPCUA::Open62541::Variant->new();
	$v->setScalar($s, TYPES_STRING);
	$g = $v->getScalar();
    } "string leak variant";
}

no_leaks_ok {
    my $s = "foo";
    {
	my $v = OPCUA::Open62541::Variant->new();
	$v->setScalar($s, TYPES_STRING);
	$g = $v->getScalar();
    }
} "leak string variant";
is($g, "foo", "string variant get");

{
    my $v = OPCUA::Open62541::Variant->new();
    no_leaks_ok {
	my $s = "foo";
	$v->setScalar($s, TYPES_STRING);
    } "variant leak string";
    $g = $v->getScalar();
}

no_leaks_ok {
    my $v = OPCUA::Open62541::Variant->new();
    {
	my $s = "foo";
	$v->setScalar($s, TYPES_STRING);
    }
    $g = $v->getScalar();
} "leak variant string";
is($g, "foo", "variant string get");

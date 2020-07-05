use strict;
use warnings;
use OPCUA::Open62541 ':TYPES';

use Test::More tests => 54;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

ok(my $variant = OPCUA::Open62541::Variant->new(), "variant new");

no_leaks_ok { $variant->setArray(undef, TYPES_SBYTE) } "array undef leak";
ok(!defined($variant->getArray()), "array undef");

no_leaks_ok { $variant->setArray([], TYPES_SBYTE) } "array empty leak";
is_deeply($variant->getArray(), [], "array empty");

no_leaks_ok { $variant->setArray([1], TYPES_SBYTE) } "array one leak";
is_deeply($variant->getArray(), [1], "array one");

throws_ok { $variant->setArray("foo", TYPES_SBYTE) }
    (qr/Not an ARRAY reference /, "array string");
no_leaks_ok { eval {
    $variant->setArray("foo", TYPES_SBYTE)
} } "array string leak";

throws_ok { $variant->setArray(\"foo", TYPES_SBYTE) }
    (qr/Not an ARRAY reference /, "array scalar");
no_leaks_ok { eval {
    $variant->setArray(\"foo", TYPES_SBYTE)
} } "array scalar leak";

throws_ok { $variant->setArray({foo => "bar"}, TYPES_SBYTE) }
    (qr/Not an ARRAY reference /, "array hash");
no_leaks_ok { eval {
    $variant->setArray({foo => "bar"}, TYPES_SBYTE)
} } "array hash leak";

warning_like { $variant->setArray([3], undef) }
    (qr/Use of uninitialized value in subroutine entry/, "type undef warn");
no_leaks_ok {
    no warnings 'uninitialized';
    $variant->setArray([3], undef)
} "type undef leak";
is_deeply($variant->getArray(), [1], "type undef");

warning_like { $variant->setArray([""], TYPES_SBYTE) }
    (qr/Argument "" isn't numeric in subroutine entry/, "value string warn");
no_leaks_ok {
    no warnings 'numeric';
    $variant->setArray([""], TYPES_SBYTE);
} "value string leak";
is_deeply($variant->getArray(), [0], "value string");

warning_like { $variant->setArray([2], "") }
    (qr/Argument "" isn't numeric in subroutine entry/, "type string warn");
no_leaks_ok {
    no warnings 'numeric';
     $variant->setArray([2], "")
} "type string leak";
is_deeply($variant->getArray(), [1], "type string");

throws_ok { $variant->setArray([""], OPCUA::Open62541::TYPES_COUNT) }
    (qr/Unsigned value .* not below UA_TYPES_COUNT /, "set below COUNT");
no_leaks_ok { eval {
    $variant->setArray([""], OPCUA::Open62541::TYPES_COUNT)
} } "set below COUNT leak";

throws_ok { $variant->setArray("", -1) }
    (qr/Unsigned value .* not below UA_TYPES_COUNT /, "type -1");
no_leaks_ok { eval { $variant->setArray("", -1) } } "type -1 leak";

$variant->setArray([1], TYPES_SBYTE);
ok($variant->hasArrayType(TYPES_SBYTE), "has type");
no_leaks_ok { $variant->hasArrayType(TYPES_SBYTE) } "has type leak";
ok(!$variant->hasArrayType(TYPES_BYTE), "has type false");

throws_ok { $variant->hasArrayType(OPCUA::Open62541::TYPES_COUNT) }
    (qr/Unsigned value .* not below UA_TYPES_COUNT /, "has type below COUNT");
no_leaks_ok { eval {
    $variant->hasArrayType(OPCUA::Open62541::TYPES_COUNT)
} } "has type below COUNT leak";

throws_ok { $variant->hasArrayType(-1) }
    (qr/Unsigned value .* not below UA_TYPES_COUNT /, "has type -1");
no_leaks_ok { eval { $variant->hasArrayType(-1) } } "has type -1";

$variant->setArray([OPCUA::Open62541::TRUE, 1, 2, '1', 'foo',
    OPCUA::Open62541::FALSE, undef, 0, '0', ''], TYPES_BOOLEAN);
is_deeply($variant->getArray(), [(1) x 5, ('') x 5], "TYPES_BOOLEAN array");
ok($variant->hasArrayType(TYPES_BOOLEAN), "TYPES_BOOLEAN variant");
is($variant->getType(), TYPES_BOOLEAN, "TYPES_BOOLEAN type");

$variant->setArray([0, -128, 127], TYPES_SBYTE);
throws_ok { $variant->setArray([-129, 128], TYPES_SBYTE) }
    (qr/Integer value /, "TYPES_SBYTE croak");
no_leaks_ok { eval { $variant->setArray([-129, 128], TYPES_SBYTE) } }
    "TYPES_SBYTE leak";
is_deeply($variant->getArray(), [0, -128, 127], "TYPES_SBYTE array");
ok($variant->hasArrayType(TYPES_SBYTE), "TYPES_SBYTE variant");
is($variant->getType(), TYPES_SBYTE, "TYPES_SBYTE type");

$variant->setArray([0, 255], TYPES_BYTE);
throws_ok { $variant->setArray([256], TYPES_BYTE) }
    (qr/Unsigned value /, "TYPES_BYTE croak");
no_leaks_ok { eval { $variant->setArray([256], TYPES_BYTE) } }
    "TYPES_BYTE leak";
is_deeply($variant->getArray(), [0, 255], "TYPES_BYTE array");
ok($variant->hasArrayType(TYPES_BYTE), "TYPES_BYTE variant");
is($variant->getType(), TYPES_BYTE, "TYPES_BYTE type");

my @array = (0, 1, 2, 3, 4);
delete $array[2];
delete $array[4];
$variant->setArray(\@array, TYPES_BYTE);
is_deeply($variant->getArray(), [0, 1, 0, 3], "array delete");

my $g;
{
    my $s = "foo";
    no_leaks_ok {
	my $v = OPCUA::Open62541::Variant->new();
	$v->setArray([$s], TYPES_STRING);
	$g = $v->getArray();
    } "string leak variant";
}

no_leaks_ok {
    my $s = "foo";
    {
	my $v = OPCUA::Open62541::Variant->new();
	$v->setArray([$s], TYPES_STRING);
	$g = $v->getArray();
    }
} "leak string variant";
is_deeply($g, ["foo"], "string variant get");

{
    my $v = OPCUA::Open62541::Variant->new();
    no_leaks_ok {
	my $s = "foo";
	$v->setArray([$s], TYPES_STRING);
    } "variant leak string";
    $g = $v->getArray();
}

no_leaks_ok {
    my $v = OPCUA::Open62541::Variant->new();
    {
	my $s = "foo";
	$v->setArray([$s], TYPES_STRING);
    }
    $g = $v->getArray();
} "leak variant string";
is_deeply($g, ["foo"], "variant string get");

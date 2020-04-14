use strict;
use warnings;
use OPCUA::Open62541 'TYPES_SBYTE';

use Test::More tests => 38;
use Test::LeakTrace;
use Test::NoWarnings;

ok(my $variant = OPCUA::Open62541::Variant->new(), "variant new");
no_leaks_ok { OPCUA::Open62541::Variant->new() } "variant new leak";
ok($variant->isEmpty(), "variant is empty");
ok(!$variant->isScalar(), "variant is scalar");
ok(!defined($variant->getType()), "variant get type defined");
ok(!defined($variant->getScalar()), "variant get scalar defined");
ok(!defined($variant->getArray()), "variant get array defined");

no_leaks_ok { $variant->setScalar(1, TYPES_SBYTE) } "scalar set leak";
ok(!$variant->isEmpty(), "scalar is empty");
no_leaks_ok { $variant->isEmpty() } "scalar is empty leak";
ok($variant->isScalar(), "scalar is scalar");
no_leaks_ok { $variant->isScalar() } "scalar is scalar leak";
ok($variant->hasScalarType(TYPES_SBYTE), "scalar has scalar");
no_leaks_ok { $variant->hasScalarType(TYPES_SBYTE) } "scalar has scalar leak";
ok(!$variant->hasArrayType(TYPES_SBYTE), "scalar has array");
no_leaks_ok { $variant->hasArrayType(TYPES_SBYTE) } "scalar has array leak";
ok(defined($variant->getType()), "scalar get type defined");
no_leaks_ok { $variant->getType() } "scalar get type leak";
ok(defined($variant->getScalar()), "scalar get scalar defined");
no_leaks_ok { $variant->getScalar() } "scalar get scalar leak";
ok(!defined($variant->getArray()), "scalar get array undef");
no_leaks_ok { $variant->getArray() } "scalar get array leak";

no_leaks_ok { $variant->setArray([1], TYPES_SBYTE) } "array set leak";
ok(!$variant->isEmpty(), "array is empty");
no_leaks_ok { $variant->isEmpty() } "array is empty leak";
ok(!$variant->isScalar(), "array is scalar");
no_leaks_ok { $variant->isScalar() } "array is scalar leak";
ok(!$variant->hasScalarType(TYPES_SBYTE), "array has scalar");
no_leaks_ok { $variant->hasScalarType(TYPES_SBYTE) } "array has scalar leak";
ok($variant->hasArrayType(TYPES_SBYTE), "array has array");
no_leaks_ok { $variant->hasArrayType(TYPES_SBYTE) } "array has array leak";
ok(defined($variant->getType()), "array get type defined");
no_leaks_ok { $variant->getType() } "array get type leak";
ok(!defined($variant->getScalar()), "array get scalar defined");
no_leaks_ok { $variant->getScalar() } "array get scalar leak";
ok(defined($variant->getArray()), "array get array undef");
no_leaks_ok { $variant->getArray() } "array get array leak";

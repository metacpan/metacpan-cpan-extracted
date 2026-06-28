#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use Test::More tests => 66;

# Test loading Arena and Obj modules
use_ok('PDF::Make::Arena');
use_ok('PDF::Make::Obj');

# Test Arena creation
my $arena = PDF::Make::Arena->new();
isa_ok($arena, 'PDF::Make::Arena', 'Arena->new returns blessed reference');

# Test null object
my $null = $arena->null();
isa_ok($null, 'PDF::Make::Obj', 'null() returns Obj');
is($null->kind(), 0, 'null kind is 0');
ok($null->is_null(), 'null is_null returns true');
ok(!$null->is_bool(), 'null is_bool returns false');

# Test bool object
my $true_obj = $arena->bool(1);
isa_ok($true_obj, 'PDF::Make::Obj', 'bool(1) returns Obj');
is($true_obj->kind(), 1, 'bool kind is 1');
ok($true_obj->is_bool(), 'bool is_bool returns true');
ok(!$true_obj->is_null(), 'bool is_null returns false');
is($true_obj->value(), 1, 'bool(1) value is 1');

my $false_obj = $arena->bool(0);
ok(!$false_obj->value(), 'bool(0) value is false');

# Test int object
my $int = $arena->int(42);
isa_ok($int, 'PDF::Make::Obj', 'int(42) returns Obj');
is($int->kind(), 2, 'int kind is 2');
ok($int->is_int(), 'int is_int returns true');
ok(!$int->is_real(), 'int is_real returns false');
is($int->value(), 42, 'int(42) value is 42');

my $neg_int = $arena->int(-123);
is($neg_int->value(), -123, 'int(-123) value is -123');

# Test real object
my $real = $arena->real(3.14159);
isa_ok($real, 'PDF::Make::Obj', 'real(3.14159) returns Obj');
is($real->kind(), 3, 'real kind is 3');
ok($real->is_real(), 'real is_real returns true');
ok(!$real->is_int(), 'real is_int returns false');
ok(abs($real->value() - 3.14159) < 0.0001, 'real value approximately correct');

# Test name object
my $name = $arena->name("Type");
isa_ok($name, 'PDF::Make::Obj', 'name returns Obj');
is($name->kind(), 4, 'name kind is 4');
ok($name->is_name(), 'name is_name returns true');
ok(!$name->is_str(), 'name is_str returns false');
is($name->value(), 'Type', 'name value is Type');

# Test string object
my $str = $arena->str("Hello, PDF!");
isa_ok($str, 'PDF::Make::Obj', 'str returns Obj');
is($str->kind(), 5, 'string kind is 5');
ok($str->is_str(), 'str is_str returns true');
ok(!$str->is_name(), 'str is_name returns false');
is($str->value(), 'Hello, PDF!', 'str value correct');

# Test hexstr object
my $hexstr = $arena->hexstr("48656C6C6F");  # "Hello" in hex
isa_ok($hexstr, 'PDF::Make::Obj', 'hexstr returns Obj');
is($hexstr->kind(), 5, 'hexstr kind is 5 (same as string)');
ok($hexstr->is_str(), 'hexstr is_str returns true');

# Test array object
my $arr = $arena->array();
isa_ok($arr, 'PDF::Make::Obj', 'array() returns Obj');
is($arr->kind(), 6, 'array kind is 6');
ok($arr->is_array(), 'array is_array returns true');
ok(!$arr->is_dict(), 'array is_dict returns false');
is($arr->len(), 0, 'empty array has length 0');

# Test array push and access
$arr->push($arena->int(100));
$arr->push($arena->int(200));
$arr->push($arena->int(300));
is($arr->len(), 3, 'array length after push is 3');
is($arr->get(0)->value(), 100, 'array[0] is 100');
is($arr->get(1)->value(), 200, 'array[1] is 200');
is($arr->get(2)->value(), 300, 'array[2] is 300');

# Test dict object
my $dict = $arena->dict();
isa_ok($dict, 'PDF::Make::Obj', 'dict() returns Obj');
is($dict->kind(), 7, 'dict kind is 7');
ok($dict->is_dict(), 'dict is_dict returns true');
ok(!$dict->is_array(), 'dict is_array returns false');
is($dict->len(), 0, 'empty dict has length 0');

# Test dict set and get
$dict->set("Type", $arena->name("Page"));
$dict->set("Count", $arena->int(5));
is($dict->len(), 2, 'dict length after set is 2');
ok($dict->has("Type"), 'dict has Type');
ok($dict->has("Count"), 'dict has Count');
ok(!$dict->has("Missing"), 'dict does not have Missing');
is($dict->get("Type")->value(), 'Page', 'dict Type is Page');
is($dict->get("Count")->value(), 5, 'dict Count is 5');

# Test indirect object reference
my $ref = $arena->obj_ref(10, 0);
isa_ok($ref, 'PDF::Make::Obj', 'obj_ref returns Obj');
is($ref->kind(), 9, 'ref kind is 9');
ok($ref->is_indirect_ref(), 'ref is_indirect_ref returns true');
ok(!$ref->is_dict(), 'ref is_dict returns false');
is($ref->obj_ref_num(), 10, 'ref obj_ref_num is 10');
is($ref->obj_ref_gen(), 0, 'ref obj_ref_gen is 0');

# Test arena reset
$arena->reset();
pass('arena reset did not crash');

# Test arena object keeps children alive
SCOPE: {
    my $temp_arena = PDF::Make::Arena->new();
    my $child_obj = $temp_arena->int(999);
    is($child_obj->value(), 999, 'child object value correct');
    # $temp_arena should stay alive until $child_obj is destroyed
}
pass('arena scoping test passed');

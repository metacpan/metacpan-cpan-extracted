#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Object::Proto;

# Test clearer and predicate support

# Define class with clearer and predicate
Object::Proto::define('Person',
    'name:Str:required',
    'age:Int:clearer:predicate',
    'email:Str:clearer:predicate'
);

# Test 1: Predicate returns false when undefined
my $p = Person->new(name => "Alice");
ok(!$p->has_age, 'has_age returns false when undefined');
ok(!$p->has_email, 'has_email returns false when undefined');

# Test 2: Predicate returns true when defined
$p->age(30);
ok($p->has_age, 'has_age returns true when defined');
is($p->age, 30, 'age value is correct');

# Test 3: Clearer clears the value
$p->clear_age;
ok(!$p->has_age, 'has_age returns false after clear');
ok(!defined($p->age) || !$p->age, 'age is undefined after clear');

# Test 4: Can set value again after clearing
$p->age(25);
ok($p->has_age, 'has_age returns true after re-setting');
is($p->age, 25, 'age has new value');

# Test 5: Clearer returns self for chaining
my $ret = $p->clear_email;
isa_ok($ret, 'Person', 'clear_email returns self');

# Test 6: Email predicate and clearer work
$p->email('alice@example.com');
ok($p->has_email, 'has_email returns true');
is($p->email, 'alice@example.com', 'email value correct');

$p->clear_email;
ok(!$p->has_email, 'has_email false after clear');

# Test 7: Clearer with lazy attribute
our $build_count = 0;

package LazyWithClearer;

sub _build_data {
    $main::build_count++;
    return "built-data";
}

package main;

Object::Proto::define('LazyWithClearer',
    'data:Str:builder(_build_data):clearer:predicate'
);

my $lwc = LazyWithClearer->new();
is($build_count, 0, 'Builder not called at construction');
ok(!$lwc->has_data, 'has_data returns false before first access');

# Access triggers builder
my $data = $lwc->data;
is($build_count, 1, 'Builder called on first access');
is($data, 'built-data', 'Built value correct');
ok($lwc->has_data, 'has_data returns true after build');

# Clear resets the lazy attribute
$lwc->clear_data;
ok(!$lwc->has_data, 'has_data returns false after clear');
is($build_count, 1, 'Builder not called by clear');

# Re-access rebuilds
my $data2 = $lwc->data;
is($build_count, 2, 'Builder called again after clear');
is($data2, 'built-data', 'Rebuilt value correct');

# Test 8: Clearer on frozen object should fail
my $frozen = Person->new(name => "Frozen");
$frozen->age(40);
Object::Proto::freeze($frozen);

eval { $frozen->clear_age };
ok($@, 'Clearer on frozen object throws error');
like($@, qr/frozen|Cannot modify/i, 'Error mentions frozen');

# Test 9: Predicate only (no clearer)
Object::Proto::define('PredicateOnly',
    'value:Int:predicate'
);

my $po = PredicateOnly->new();
ok($po->can('has_value'), 'has_value method exists');
ok(!$po->can('clear_value'), 'clear_value method does not exist');
ok(!$po->has_value, 'has_value false initially');
$po->value(10);
ok($po->has_value, 'has_value true after set');

# Test 10: Clearer only (no predicate)
Object::Proto::define('ClearerOnly',
    'value:Int:clearer'
);

my $co = ClearerOnly->new();
ok($co->can('clear_value'), 'clear_value method exists');
ok(!$co->can('has_value'), 'has_value method does not exist');
$co->value(20);
is($co->value, 20, 'value is set');
$co->clear_value;
ok(!$co->value, 'value is cleared');

done_testing();

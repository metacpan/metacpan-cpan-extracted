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
    'data:Str:lazy:builder(_build_data):clearer:predicate'
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

# Test 11: Custom predicate and clearer names
Object::Proto::define('CustomNames',
    'attr:Str:clearer(reset_attr):predicate(attr_defined)'
);

my $cn = CustomNames->new();

# Custom predicate name works
ok($cn->can('attr_defined'), 'custom predicate method exists');
ok(!$cn->can('has_attr'), 'default predicate method does not exist');
ok(!$cn->attr_defined, 'custom predicate returns false initially');

$cn->attr('hello');
ok($cn->attr_defined, 'custom predicate returns true after set');
is($cn->attr, 'hello', 'attr value correct');

# Custom clearer name works
ok($cn->can('reset_attr'), 'custom clearer method exists');
ok(!$cn->can('clear_attr'), 'default clearer method does not exist');

my $ret2 = $cn->reset_attr;
isa_ok($ret2, 'CustomNames', 'custom clearer returns self');
ok(!$cn->attr_defined, 'predicate false after custom clearer');

# Test 12: Custom predicate only (no custom clearer)
Object::Proto::define('CustomPredicate',
    'data:Int:predicate(is_data_set)'
);

my $cp = CustomPredicate->new();
ok($cp->can('is_data_set'), 'custom predicate name works');
ok(!$cp->can('has_data'), 'default predicate name not created');
ok(!$cp->is_data_set, 'is_data_set false initially');
$cp->data(42);
ok($cp->is_data_set, 'is_data_set true after set');

# Test 13: Custom clearer only (no custom predicate)
Object::Proto::define('CustomClearer',
    'info:Str:clearer(wipe_info)'
);

my $cc = CustomClearer->new();
ok($cc->can('wipe_info'), 'custom clearer name works');
ok(!$cc->can('clear_info'), 'default clearer name not created');
$cc->info('secret');
is($cc->info, 'secret', 'info is set');
$cc->wipe_info;
ok(!defined($cc->info) || !$cc->info, 'info is cleared by wipe_info');

# Test 14: Custom names with lazy builder
our $custom_build_count = 0;

package LazyCustom;

sub init_cache {
    $main::custom_build_count++;
    return { items => [] };
}

package main;

Object::Proto::define('LazyCustom',
    'cache:HashRef:lazy:builder(init_cache):clearer(invalidate_cache):predicate(cache_loaded)'
);

my $lc = LazyCustom->new();
is($custom_build_count, 0, 'Custom builder not called at construction');
ok(!$lc->cache_loaded, 'cache_loaded returns false before access');

my $cache = $lc->cache;
is($custom_build_count, 1, 'Builder called on first access');
ok(ref($cache) eq 'HASH', 'Cache is a hashref');
ok($lc->cache_loaded, 'cache_loaded returns true after build');

$lc->invalidate_cache;
ok(!$lc->cache_loaded, 'cache_loaded false after invalidate_cache');
is($custom_build_count, 1, 'Builder not called by invalidation');

# Re-access rebuilds
$lc->cache;
is($custom_build_count, 2, 'Builder called again after invalidation');

done_testing();

#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Object::Proto;

# Test reader/writer support (Moo-style Java accessors)

# === Test 1: Basic reader and writer ===
Object::Proto::define('JavaStyle',
    'name:Str:reader(get_name):writer(set_name)'
);

my $obj = JavaStyle->new();

# Test writer
$obj->set_name("Alice");
pass('Writer method works');

# Test reader
is($obj->get_name, 'Alice', 'Reader method returns correct value');

# Default accessor still works too
is($obj->name, 'Alice', 'Default accessor still works for reading');
$obj->name("Bob");
is($obj->get_name, 'Bob', 'Default accessor still works for writing');

# === Test 2: Reader only ===
Object::Proto::define('ReaderOnly',
    'value:Int:reader(get_value)'
);

my $ro = ReaderOnly->new(value => 42);
is($ro->get_value, 42, 'Reader-only method works');
is($ro->value, 42, 'Default accessor works');

# Can still use default accessor to set
$ro->value(100);
is($ro->get_value, 100, 'Reader reflects value set via default accessor');

# === Test 3: Writer only ===
Object::Proto::define('WriterOnly',
    'data:Str:writer(set_data)'
);

my $wo = WriterOnly->new();
$wo->set_data("hello");
is($wo->data, 'hello', 'Value set via writer is readable via default accessor');

# === Test 4: Reader/writer with type checking ===
Object::Proto::define('TypedRW',
    'count:Int:reader(get_count):writer(set_count)'
);

my $trw = TypedRW->new();
$trw->set_count(10);
is($trw->get_count, 10, 'Typed writer sets value');

# Type checking on writer
eval { $trw->set_count("not a number") };
ok($@, 'Writer enforces type constraint');
like($@, qr/Type constraint failed/i, 'Error message mentions type');

# === Test 5: Reader/writer with trigger ===
our $trigger_count = 0;
our $last_value = undef;

package TriggerRW;

sub on_change {
    my ($self, $new_value) = @_;
    $main::trigger_count++;
    $main::last_value = $new_value;
}

package main;

Object::Proto::define('TriggerRW',
    'val:Int:writer(set_val):reader(get_val):trigger(on_change)'
);

$trigger_count = 0;
my $trg = TriggerRW->new(val => 5);
is($trigger_count, 1, 'Trigger fired during construction');

$trg->set_val(20);
is($trigger_count, 2, 'Trigger fired on writer call');
is($last_value, 20, 'Trigger received correct value');

is($trg->get_val, 20, 'Reader returns value after writer with trigger');

# === Test 6: Reader/writer with readonly ===
Object::Proto::define('ReadonlyRW',
    'id:Int:readonly:reader(get_id):writer(set_id)'
);

my $rorw = ReadonlyRW->new(id => 123);
is($rorw->get_id, 123, 'Reader works on readonly slot');

# Writer should fail on readonly
eval { $rorw->set_id(456) };
ok($@, 'Writer fails on readonly slot');
like($@, qr/readonly/i, 'Error mentions readonly');

# === Test 7: Reader with lazy builder ===
our $lazy_build_count = 0;

package LazyRW;

sub _build_computed {
    $main::lazy_build_count++;
    return "computed-value";
}

package main;

Object::Proto::define('LazyRW',
    'computed:Str:lazy:builder(_build_computed):reader(get_computed)'
);

$lazy_build_count = 0;
my $lrw = LazyRW->new();
is($lazy_build_count, 0, 'Builder not called at construction');

my $val = $lrw->get_computed;
is($lazy_build_count, 1, 'Builder called on reader access');
is($val, 'computed-value', 'Reader returns built value');

# === Test 8: Multiple reader/writer attributes ===
Object::Proto::define('MultiRW',
    'first:Str:reader(get_first):writer(set_first)',
    'second:Int:reader(get_second):writer(set_second)'
);

my $mrw = MultiRW->new();
$mrw->set_first("one");
$mrw->set_second(2);
is($mrw->get_first, 'one', 'First reader/writer works');
is($mrw->get_second, 2, 'Second reader/writer works');

# === Test 9: Reader/writer in inheritance ===
Object::Proto::define('ParentRW',
    'parent_attr:Str:reader(get_parent):writer(set_parent)'
);

Object::Proto::define('ChildRW',
    extends => 'ParentRW',
    'child_attr:Str:reader(get_child):writer(set_child)'
);

my $child = ChildRW->new();
$child->set_parent("parent-val");
$child->set_child("child-val");

is($child->get_parent, 'parent-val', 'Inherited reader works');
is($child->get_child, 'child-val', 'Child reader works');

# === Test 10: Reader/writer on frozen object ===
my $frozen = JavaStyle->new(name => "Frozen");
Object::Proto::freeze($frozen);

is($frozen->get_name, 'Frozen', 'Reader works on frozen object');

eval { $frozen->set_name("Changed") };
ok($@, 'Writer fails on frozen object');
like($@, qr/frozen/i, 'Error mentions frozen');

# === Test 11: Writer requires value ===
eval { $obj->set_name() };  # No argument to writer
ok($@, 'Writer without argument throws error');
like($@, qr/requires.*value/i, 'Error mentions value required');

done_testing();

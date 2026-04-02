#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# ==== Basic Type Checking ====

# Define class with typed slots
Object::Proto::define('TypedPerson',
    'name:Str',
    'age:Int',
    'score:Num',
    'active:Bool',
);

# Test valid values
my $p = new TypedPerson name => 'Alice', age => 30, score => 99.5, active => 1;
is($p->name, 'Alice', 'Str type accepts string');
is($p->age, 30, 'Int type accepts integer');
is($p->score, 99.5, 'Num type accepts number');
is($p->active, 1, 'Bool type accepts 1');

# Test type errors on setter
eval { $p->age('not a number') };
like($@, qr/Type constraint failed for 'age'/,
    'Int rejects non-numeric string');

eval { $p->score('text') };
like($@, qr/Type constraint failed for 'score'/,
    'Num rejects non-numeric string');

# Test type checking on construction
eval {
    new TypedPerson name => 'Bob', age => 'young', score => 1, active => 0
};
like($@, qr/Type constraint failed for 'age'/,
    'Constructor checks Int type');

# ==== Reference Types ====

Object::Proto::define('Container',
    'items:ArrayRef',
    'data:HashRef',
    'callback:CodeRef',
);

my $c = new Container
    items => [1, 2, 3],
    data => { key => 'value' },
    callback => sub { return 42 };

is_deeply($c->items, [1, 2, 3], 'ArrayRef accepts array reference');
is_deeply($c->data, {key => 'value'}, 'HashRef accepts hash reference');
is($c->callback->(), 42, 'CodeRef accepts code reference');

eval { $c->items({}) };
like($@, qr/Type constraint failed for 'items'/,
    'ArrayRef rejects hashref');

eval { $c->data([]) };
like($@, qr/Type constraint failed for 'data'/,
    'HashRef rejects arrayref');

eval { $c->callback('not a sub') };
like($@, qr/Type constraint failed for 'callback'/,
    'CodeRef rejects string');

# ==== Default Values ====

Object::Proto::define('WithDefaults',
    'name:Str:default(Anonymous)',
    'count:Int:default(0)',
    'rate:Num:default(1.5)',
);

my $d = new WithDefaults;
is($d->name, 'Anonymous', 'String default applied');
is($d->count, 0, 'Integer default applied');
is($d->rate, 1.5, 'Number default applied');

# Override defaults
my $d2 = new WithDefaults name => 'Custom', count => 10;
is($d2->name, 'Custom', 'Default overridden by named arg');
is($d2->count, 10, 'Default overridden by named arg');
is($d2->rate, 1.5, 'Unspecified uses default');

# ==== Required Slots ====

Object::Proto::define('WithRequired',
    'id:Str:required',
    'name:Str',
);

eval { new WithRequired name => 'Test' };
like($@, qr/Required slot 'id' not provided/,
    'Required slot croak on missing');

my $r = new WithRequired id => 'abc123', name => 'Test';
is($r->id, 'abc123', 'Required slot accepts value');

# ==== Readonly Slots ====

Object::Proto::define('WithReadonly',
    'id:Str:readonly',
    'name:Str',
);

my $ro = new WithReadonly id => 'fixed', name => 'Mutable';
is($ro->id, 'fixed', 'Readonly getter works');
is($ro->name, 'Mutable', 'Non-readonly getter works');

$ro->name('Changed');
is($ro->name, 'Changed', 'Non-readonly setter works');

eval { $ro->id('new value') };
like($@, qr/Cannot modify readonly slot/,
    'Readonly slot rejects set after construction');

# ==== Combined Features ====

Object::Proto::define('FullFeatured',
    'id:Str:required:readonly',
    'count:Int:default(0)',
    'tags:ArrayRef:default([])',
);

my $ff = new FullFeatured id => 'obj-1';
is($ff->id, 'obj-1', 'Required+readonly works');
is($ff->count, 0, 'Default applied');
is_deeply($ff->tags, [], 'Empty array default applied');

# Modify mutable slots
$ff->count(5);
is($ff->count, 5, 'Mutable slot modified');

# Push to tags
push @{$ff->tags}, 'new-tag';
is_deeply($ff->tags, ['new-tag'], 'ArrayRef default is mutable');

# Create another - should get fresh array
my $ff2 = new FullFeatured id => 'obj-2';
is_deeply($ff2->tags, [], 'New object gets fresh array default');

# ==== Built-in Type List ====

my $types = Object::Proto::list_types();
ok(grep { $_ eq 'Str' } @$types, 'Str in type list');
ok(grep { $_ eq 'Int' } @$types, 'Int in type list');
ok(grep { $_ eq 'Num' } @$types, 'Num in type list');
ok(grep { $_ eq 'Bool' } @$types, 'Bool in type list');
ok(grep { $_ eq 'ArrayRef' } @$types, 'ArrayRef in type list');
ok(grep { $_ eq 'HashRef' } @$types, 'HashRef in type list');
ok(grep { $_ eq 'CodeRef' } @$types, 'CodeRef in type list');

# ==== Type Registry ====

ok(Object::Proto::has_type('Str'), 'has_type returns true for built-in');
ok(Object::Proto::has_type('Int'), 'has_type returns true for built-in');
ok(!Object::Proto::has_type('NonExistent'), 'has_type returns false for unknown');

# Register a custom type
Object::Proto::register_type('PositiveInt', sub {
    my $val = shift;
    return $val =~ /^\d+$/ && $val > 0;
});

ok(Object::Proto::has_type('PositiveInt'), 'Custom type registered');

# Use custom type in class
Object::Proto::define('Counter',
    'value:PositiveInt',
);

my $cnt = new Counter value => 5;
is($cnt->value, 5, 'Custom type accepts valid value');

# Note: Custom Perl callback type validation works at define time
# but the callback invocation is in the setter

done_testing;

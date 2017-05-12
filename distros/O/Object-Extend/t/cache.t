#!/usr/bin/env perl

use strict;
use warnings;

use constant {
    FOO => { foo => sub { 'Foo' } },
    BAR => { bar => sub { 'Bar' } },
    BAZ => { baz => sub { 'Baz' } },
};

use Object::Extend qw(extend SINGLETON);
use Test::More tests => 42;

my $object = {};

bless $object;
extend $object, FOO;
isa_ok $object, __PACKAGE__;
isa_ok $object, SINGLETON;
can_ok $object, 'foo';
ok !$object->can('bar');
ok !$object->can('baz');
my $foo_eigenclass = ref($object);

bless $object;
extend $object, BAR;
isa_ok $object, __PACKAGE__;
isa_ok $object, SINGLETON;
can_ok $object, 'bar';
ok !$object->can('foo');
ok !$object->can('baz');
my $bar_eigenclass = ref($object);

bless $object;
extend $object, %{FOO()}, %{BAR()};
isa_ok $object, __PACKAGE__;
isa_ok $object, SINGLETON;
can_ok $object, 'foo';
can_ok $object, 'bar';
my $foo_bar_eigenclass = ref($object);

isnt $foo_eigenclass, $bar_eigenclass;
isnt $foo_eigenclass, $foo_bar_eigenclass;
isnt $bar_eigenclass, $foo_bar_eigenclass;

bless $object;
extend $object, FOO;
is ref($object), $foo_eigenclass;

bless $object;
extend $object, BAR;
is ref($object), $bar_eigenclass;

bless $object;
extend $object, %{FOO()}, %{BAR()};
is ref($object), $foo_bar_eigenclass;

bless $object;
extend $object, %{FOO()}, %{BAZ()};
isnt ref($object), $foo_eigenclass;
isnt ref($object), $bar_eigenclass;
isnt ref($object), $foo_bar_eigenclass;

bless $object;
extend $object, %{BAR()}, %{BAZ()};
isnt ref($object), $foo_eigenclass;
isnt ref($object), $bar_eigenclass;
isnt ref($object), $foo_bar_eigenclass;

bless $object;
extend $object, %{FOO()}, %{BAR()}, %{BAZ()};
isnt ref($object), $foo_eigenclass;
isnt ref($object), $bar_eigenclass;
isnt ref($object), $foo_bar_eigenclass;
my $foo_bar_baz_eigenclass = ref($object);

bless $object;
extend $object, %{FOO()}, %{BAR()}, %{BAZ()};
isnt ref($object), $foo_eigenclass;
isnt ref($object), $bar_eigenclass;
isnt ref($object), $foo_bar_eigenclass;
is ref($object), $foo_bar_baz_eigenclass;

# seperate calls create a chain, so foo-then-bar
# and foo-then-bar-then-baz create new eigenclasses
bless $object;
extend $object, FOO;
is ref($object), $foo_eigenclass;
extend $object, BAR;
isnt ref($object), $foo_bar_eigenclass;
my $foo_then_bar_eigenclass = ref($object);
extend $object, BAZ;
isnt ref($object), $foo_bar_baz_eigenclass;
my $foo_then_bar_then_baz_eigenclass = ref($object);

isnt $foo_bar_eigenclass, $foo_then_bar_eigenclass;
isnt $foo_bar_baz_eigenclass, $foo_then_bar_then_baz_eigenclass;
isnt $foo_then_bar_eigenclass, $foo_then_bar_then_baz_eigenclass;

bless $object;
extend $object, FOO;
is ref($object), $foo_eigenclass;
extend $object, BAR;
is ref($object), $foo_then_bar_eigenclass;
extend $object, BAZ;
is ref($object), $foo_then_bar_then_baz_eigenclass;

#!/usr/bin/env perl

use strict;
use warnings;

package Bar;

sub foo { 'Bar::foo' }
sub bar { 'Bar::bar' };

package main;

use constant {
    BAR => { bar => sub { 'bar' } },
    BAZ => { baz => sub { 'baz' } },
};

use Object::Extend qw(extend SINGLETON);
use Test::More tests => 40;

sub foo { 'main::foo' }

# if an object is reblessed into another class, then the singleton object
# should extend the new class and cease to extend the old class

# start with a normal class instance
my $object = bless {};
isa_ok $object, __PACKAGE__;
ok !$object->isa(SINGLETON);
can_ok $object, 'foo';
is $object->foo, 'main::foo';
ok !$object->can('bar');

# extend it with a bar method
extend $object => BAR;
my $old_eigenclass = ref($object);
isa_ok $object, __PACKAGE__;
isa_ok $object, SINGLETON;
can_ok $object, 'foo';
can_ok $object, 'bar';
is $object->foo, 'main::foo';
is $object->bar, 'bar';

# now rebless the object into a different class (Bar);
# there should be no traces of its brush with singleton
# status
bless $object, 'Bar';
isa_ok $object, 'Bar';
ok !$object->isa(__PACKAGE__);
ok !$object->isa(SINGLETON);
can_ok $object, 'foo';
can_ok $object, 'bar';
is $object->foo, 'Bar::foo';
is $object->bar, 'Bar::bar';

# make sure the singleton stuff still works if we
# bless the object back into its old eigenclass
bless $object, $old_eigenclass;
isa_ok $object, __PACKAGE__;
isa_ok $object, SINGLETON;
can_ok $object, 'foo';
can_ok $object, 'bar';
is $object->foo, 'main::foo';
is $object->bar, 'bar';

# now bless the object back into its new class
# and re-run the sanity checks for that class
bless $object, 'Bar';
isa_ok $object, 'Bar';
ok !$object->isa(__PACKAGE__);
ok !$object->isa(SINGLETON);
can_ok $object, 'foo';
can_ok $object, 'bar';
is $object->foo, 'Bar::foo';
is $object->bar, 'Bar::bar';

# finally, extend this instance of the
# new class and confirm that it
# behaves as a singleton instance of
# the new class
extend $object => %{BAR()}, %{BAZ()};
isa_ok $object, 'Bar';
ok !$object->isa(__PACKAGE__);
isa_ok $object, SINGLETON;
can_ok $object, 'foo';
can_ok $object, 'bar';
can_ok $object, 'baz';
is $object->foo, 'Bar::foo'; # preserved
is $object->bar, 'bar';      # overridden
is $object->baz, 'baz';      # new

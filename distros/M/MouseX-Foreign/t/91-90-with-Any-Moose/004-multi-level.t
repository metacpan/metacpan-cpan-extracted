#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 11;

package Foo;

sub new {
    my $class = shift;
    bless { foo => 'FOO' }, $class;
}

sub foo { shift->{foo} }

package Foo::Mouse;
use Mouse;
use Any::Moose 'X::NonMoose';
extends 'Foo';

has bar => (
    is      => 'ro',
    default => 'BAR',
);

package Foo::Mouse::Sub;
use Mouse;
extends 'Foo::Mouse';

has baz => (
    is      => 'ro',
    default => 'BAZ',
);

package main;
my $foo_moose = Foo::Mouse->new;
is($foo_moose->foo, 'FOO', 'Foo::Mouse::foo');
is($foo_moose->bar, 'BAR', 'Foo::Mouse::bar');
isnt(Foo::Mouse->meta->get_method('new'), undef,
     'Foo::Mouse gets its own constructor');

my $foo_moose_sub = Foo::Mouse::Sub->new;
is($foo_moose_sub->foo, 'FOO', 'Foo::Mouse::Sub::foo');
is($foo_moose_sub->bar, 'BAR', 'Foo::Mouse::Sub::bar');
is($foo_moose_sub->baz, 'BAZ', 'Foo::Mouse::Sub::baz');
is(Foo::Mouse::Sub->meta->get_method('new'), undef,
   'Foo::Mouse::Sub just uses the constructor for Foo::Mouse');

Foo::Mouse->meta->make_immutable;
Foo::Mouse::Sub->meta->make_immutable;

$foo_moose_sub = Foo::Mouse::Sub->new;
is($foo_moose_sub->foo, 'FOO', 'Foo::Mouse::Sub::foo (immutable)');
is($foo_moose_sub->bar, 'BAR', 'Foo::Mouse::Sub::bar (immutable)');
is($foo_moose_sub->baz, 'BAZ', 'Foo::Mouse::Sub::baz (immutable)');
isnt(Foo::Mouse::Sub->meta->get_method('new'), undef,
     'Foo::Mouse::Sub has an inlined constructor');

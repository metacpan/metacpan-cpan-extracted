#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 32;

package Foo;

sub new {
    my $class = shift;
    bless {@_}, $class;
}

sub foo { shift->{name} }

package Foo::Mouse;
use Mouse;
use Any::Moose 'X::NonMoose';
extends 'Foo';

has foo2 => (
    is => 'rw',
    isa => 'Str',
);

package Foo::Mouse::Sub;
use base 'Foo::Mouse';

package Bar;

sub new {
    my $class = shift;
    bless {name => $_[0]}, $class;
}

sub bar { shift->{name} }

package Bar::Mouse;
use Mouse;
use Any::Moose 'X::NonMoose';
extends 'Bar';

has bar2 => (
    is  => 'rw',
    isa => 'Str',
);

sub FOREIGNBUILDARGS {
    my $class = shift;
    my %args = @_;
    return $args{name};
}

package Bar::Mouse::Sub;
use base 'Bar::Mouse';

package main;
my $foo = Foo::Mouse::Sub->new(name => 'foomoosesub', foo2 => 'FOO2');
isa_ok($foo, 'Foo');
isa_ok($foo, 'Foo::Mouse');
is($foo->foo, 'foomoosesub', 'got name from nonmoose constructor');
is($foo->foo2, 'FOO2', 'got attribute value from moose constructor');
$foo = Foo::Mouse->new(name => 'foomoosesub', foo2 => 'FOO2');
isa_ok($foo, 'Foo');
isa_ok($foo, 'Foo::Mouse');
is($foo->foo, 'foomoosesub', 'got name from nonmoose constructor');
is($foo->foo2, 'FOO2', 'got attribute value from moose constructor');
Foo::Mouse->meta->make_immutable;
$foo = Foo::Mouse::Sub->new(name => 'foomoosesub', foo2 => 'FOO2');
isa_ok($foo, 'Foo');
isa_ok($foo, 'Foo::Mouse');
TODO: {
local $TODO = 'nonmoose-moose-nonmoose inheritance doesn\'t quite work';
is($foo->foo, 'foomoosesub', 'got name from nonmoose constructor (immutable)');
}
is($foo->foo2, 'FOO2', 'got attribute value from moose constructor (immutable)');
$foo = Foo::Mouse->new(name => 'foomoosesub', foo2 => 'FOO2');
isa_ok($foo, 'Foo');
isa_ok($foo, 'Foo::Mouse');
is($foo->foo, 'foomoosesub', 'got name from nonmoose constructor (immutable)');
is($foo->foo2, 'FOO2', 'got attribute value from moose constructor (immutable)');

my $bar = Bar::Mouse::Sub->new(name => 'barmoosesub', bar2 => 'BAR2');
isa_ok($bar, 'Bar');
isa_ok($bar, 'Bar::Mouse');
is($bar->bar, 'barmoosesub', 'got name from nonmoose constructor');
is($bar->bar2, 'BAR2', 'got attribute value from moose constructor');
$bar = Bar::Mouse->new(name => 'barmoosesub', bar2 => 'BAR2');
isa_ok($bar, 'Bar');
isa_ok($bar, 'Bar::Mouse');
is($bar->bar, 'barmoosesub', 'got name from nonmoose constructor');
is($bar->bar2, 'BAR2', 'got attribute value from moose constructor');
Bar::Mouse->meta->make_immutable;
$bar = Bar::Mouse::Sub->new(name => 'barmoosesub', bar2 => 'BAR2');
isa_ok($bar, 'Bar');
isa_ok($bar, 'Bar::Mouse');
TODO: {
local $TODO = 'nonmoose-moose-nonmoose inheritance doesn\'t quite work';
is($bar->bar, 'barmoosesub', 'got name from nonmoose constructor (immutable)');
}
is($bar->bar2, 'BAR2', 'got attribute value from moose constructor (immutable)');
$bar = Bar::Mouse->new(name => 'barmoosesub', bar2 => 'BAR2');
isa_ok($bar, 'Bar');
isa_ok($bar, 'Bar::Mouse');
is($bar->bar, 'barmoosesub', 'got name from nonmoose constructor (immutable)');
is($bar->bar2, 'BAR2', 'got attribute value from moose constructor (immutable)');

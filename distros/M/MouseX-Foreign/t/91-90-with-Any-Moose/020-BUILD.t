#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

package Foo;

sub new {
    my $class = shift;
    bless { foo => 'FOO' }, $class;
}

package Foo::Mouse;
use Mouse;
use Any::Moose 'X::NonMoose';
extends 'Foo';

has class => (
    is => 'rw',
);

has accum => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

sub BUILD {
    my $self = shift;
    $self->class(ref $self);
    $self->accum($self->accum . 'a');
}

package Foo::Mouse::Sub;
use Mouse;
extends 'Foo::Mouse';

has bar => (
    is => 'rw',
);

sub BUILD {
    my $self = shift;
    $self->bar('BAR');
    $self->accum($self->accum . 'b');
}

package main;
my $foo_moose = Foo::Mouse->new;
is($foo_moose->class, 'Foo::Mouse', 'BUILD method called properly');
is($foo_moose->accum, 'a', 'BUILD method called properly');

my $foo_moose_sub = Foo::Mouse::Sub->new;
is($foo_moose_sub->class, 'Foo::Mouse::Sub', 'parent BUILD method called');
is($foo_moose_sub->bar, 'BAR', 'child BUILD method called');
is($foo_moose_sub->accum, 'ab', 'BUILD methods called in the correct order');

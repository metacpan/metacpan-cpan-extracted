#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

package Foo;
use Moose;

sub foo {
    shift;
    return reverse @_;
}

sub bar {
    shift;
    return join '-', @_
}

package Foo::Sub;
use Moose;
use MooseX::Mangle;
extends 'Foo';

mangle_args foo => sub {
    shift;
    return map { uc } @_;
};

mangle_args bar => sub {
    my $self = shift;
    pop;
    return @_;
};

package main;
my $foo = Foo->new;
my $foosub = Foo::Sub->new;
is_deeply([$foo->foo(qw(a b c))], [qw(c b a)], 'unmodified method foo');
is($foo->bar(qw(a b c)), 'a-b-c', 'unmodified method bar');
is_deeply([$foosub->foo(qw(a b c))], [qw(C B A)], "foo's args are mangled");
is($foosub->bar(qw(a b c)), 'a-b', "bar's args are mangled");

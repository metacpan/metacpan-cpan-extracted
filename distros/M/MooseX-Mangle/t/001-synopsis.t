#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

package Foo;
use Moose;

sub foo { "FOO" }
sub bar { shift; join '-', @_ }

package Foo::Sub;
use Moose;
use MooseX::Mangle;
extends 'Foo';

mangle_return foo => sub {
    my $self = shift;
    my ($foo) = @_;
    return lc($foo) . 'BAR';
};

mangle_args bar => sub {
    my $self = shift;
    my ($a, $b, $c) = @_;
    return ($b, $c, $a);
};

package main;
my $foo = Foo->new;
my $foosub = Foo::Sub->new;
is($foo->foo, 'FOO', 'unmodified method foo');
is($foo->bar('a', 'b', 'c'), 'a-b-c', 'unmodified method bar');
is($foosub->foo, 'fooBAR', "foo's return is mangled");
is($foosub->bar('a', 'b', 'c'), 'b-c-a', "bar's args are mangled");

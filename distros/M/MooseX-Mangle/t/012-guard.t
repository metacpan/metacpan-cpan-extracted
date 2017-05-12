#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

package Foo;
use Moose;

sub foo {
    my $self = shift;
    my ($arg) = shift;
    die 'arg must be positive' if $arg < 0;
    return $arg;
}

package Foo::Sub;
use Moose;
use MooseX::Mangle;
extends 'Foo';

guard foo => sub {
    my $self = shift;
    my ($arg) = @_;
    return $arg >= 0;
};

package main;
my $foosub = Foo::Sub->new;
is($foosub->foo(2), 2, 'foo is called if guard succeeds');
lives_and { is($foosub->foo(-2), undef) } 'foo returns undef on guard failure';

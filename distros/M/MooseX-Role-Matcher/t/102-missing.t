#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

package Foo;
use Moose;
with 'MooseX::Role::Matcher';

has [qw/a b c/] => (
    is       => 'ro',
    isa      => 'Str',
);

package main;
my $foo = Foo->new;
my $matches = eval { $foo->match(d => 'bar') };
like($@, qr/^Foo has no method named d/,
     "match dies when trying to match against a non-existent method");
ok(!$matches,
   "and it doesn't match");

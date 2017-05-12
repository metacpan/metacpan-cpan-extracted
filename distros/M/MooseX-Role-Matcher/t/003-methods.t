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
    required => 1,
);

sub concat {
    my $self = shift;
    return $self->a . $self->b . $self->c;
}

package main;
my $foo = Foo->new(a => 'foo', b => 'bar', c => 'baz');
ok($foo->match(concat => 'foobarbaz'),
   'match handles methods as well as attributes');
ok($foo->match(a => qr/o/, concat => sub { length > 6 }),
   'match handles methods as well as attributes');

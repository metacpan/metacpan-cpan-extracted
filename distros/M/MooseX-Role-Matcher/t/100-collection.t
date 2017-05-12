#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use Test::Deep;

package Foo;
use Moose;
with 'MooseX::Role::Matcher';

has [qw/a b c/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

package FooCollection;
use Moose;

has foos => (
    is      => 'rw',
    isa     => 'ArrayRef[Foo]',
    default => sub { [] },
);

sub first_match {
    my $self = shift;
    Foo->first_match($self->foos, @_);
}

sub any_match {
    my $self = shift;
    Foo->any_match($self->foos, @_);
}

sub all_match {
    my $self = shift;
    Foo->all_match($self->foos, @_);
}

sub grep_matches {
    my $self = shift;
    Foo->grep_matches($self->foos, @_);
}

package main;
my $foos = FooCollection->new;
my $foo1 = Foo->new(a => 'foo',  b => 'bar', c => 'baz');
my $foo2 = Foo->new(a => '',     b => '3',   c => 'foobar');
my $foo3 = Foo->new(a => 'blah', b => 'abc', c => 'foo');
push @{ $foos->foos }, $foo1;
push @{ $foos->foos }, $foo2;
push @{ $foos->foos }, $foo3;
is($foos->first_match(a => ''), $foo2,
   'first_match works');
ok(!$foos->any_match(b => qr/z/),
   'any_match works');
ok($foos->all_match(c => qr/[^bf]/),
   'all_match works');
cmp_deeply([$foos->grep_matches(c => qr/o/)], set(shallow($foo2), shallow($foo3)),
          'grep_matches works');

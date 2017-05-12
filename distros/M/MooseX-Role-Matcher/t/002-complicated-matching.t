#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

package Foo;
use Moose;
with 'MooseX::Role::Matcher';

has [qw/a b c/] => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

package main;
my $foo = Foo->new(a => 'foo', b => 'bar', c => 'baz');
ok($foo->match(a => [qr/o/, sub { length == 4 }]),
   'arrayref matching works');
ok($foo->match(a => [qr/b/, sub { length == 3 }]),
   'arrayref matching works');
ok(!$foo->match(a => [qr/b/, sub { length == 4 }]),
   'arrayref matching works');
ok($foo->match('!a' => 'bar', b => 'bar', '!c' => 'bar'),
   'negated matching works');
ok(!$foo->match(a => 'foo', '!b' => 'bar'),
   'negated matching works');

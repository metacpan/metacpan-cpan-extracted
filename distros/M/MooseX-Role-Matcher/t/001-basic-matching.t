#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 9;

package Foo;
use Moose;
with 'MooseX::Role::Matcher' => { allow_missing_methods => 1 };

has [qw/a b c/] => (
    is       => 'ro',
    isa      => 'Str',
);

package main;
my $foo = Foo->new(a => 'foo', b => 'bar', c => 'baz');
ok($foo->match(a => 'foo', b => 'bar', c => 'baz'),
   'string matching works');
ok($foo->match(a => qr/o/),
   'regex matching works');
ok($foo->match(b => sub { length == 3 }),
   'subroutine matching works');
ok($foo->match(a => 'foo', b => qr/a/, c => sub { substr($_, 2) eq 'z' }),
   'combined matching works');
$foo = Foo->new(a => 'foo');
ok($foo->match(b => sub { !$_ }),
   'subroutine matching against undef works');
ok($foo->match(a => 'foo', b => undef),
   'matching against undef works');
ok($foo->match(a => 'foo', d => undef),
   'matching against undef works even when the method doesn\'t exist');
ok(!$foo->match(a => undef),
   'matching undef against a method with a value fails');
ok(!$foo->match(b => 'foo'),
   'matching against a method with an undef value fails');

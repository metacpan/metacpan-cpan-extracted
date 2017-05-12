#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

package Foo;

sub new { bless {}, shift }
sub foo { 'Foo' }
sub bar { 'Foo' }
sub baz { ref(shift) }

package Foo::Mouse;
use Mouse;
use Any::Moose 'X::NonMoose';
extends 'Foo';

sub bar { 'Foo::Mouse' }

package main;

my $foo_moose = Foo::Mouse->new;
is($foo_moose->foo, 'Foo', 'Foo::Mouse->foo');
is($foo_moose->bar, 'Foo::Mouse', 'Foo::Mouse->bar');
is($foo_moose->baz, 'Foo::Mouse', 'Foo::Mouse->baz');

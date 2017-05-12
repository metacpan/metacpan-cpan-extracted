#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

package Foo;

sub new { bless {}, shift }

package Foo::Mouse;
use Mouse -traits => 'MouseX::Foreign::Meta::Role::Class';
extends 'Foo';

package main;
ok(Foo::Mouse->meta->has_method('new'),
   'using only the metaclass trait still installs the constructor');
isa_ok(Foo::Mouse->new, 'Mouse::Object');
isa_ok(Foo::Mouse->new, 'Foo');
my $method = Foo::Mouse->meta->get_method('new');
Foo::Mouse->meta->make_immutable;
{ local $TODO = "method object semantics is different from Moose's";
is(Foo::Mouse->meta->get_method('new'), $method,
   'inlining doesn\'t happen when the constructor trait isn\'t used');
}

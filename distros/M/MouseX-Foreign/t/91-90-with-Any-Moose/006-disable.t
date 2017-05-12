#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

package Foo;

sub new {
    my $class = shift;
    bless {}, $class;
}

package Foo::Mouse;
use Mouse;
use Any::Moose 'X::NonMoose';
extends 'Foo';

package Foo::Mouse2;
use Mouse;
use Any::Moose 'X::NonMoose';
extends 'Foo';

package main;

ok(Foo::Mouse->meta->has_method('new'), 'Foo::Mouse has a constructor');
my $method = Foo::Mouse->meta->get_method('new');
Foo::Mouse->meta->make_immutable;
isnt($method->body, Foo::Mouse->meta->get_method('new')->body,
     'make_immutable replaced the constructor with an inlined version');

my $method2 = Foo::Mouse2->meta->get_method('new');
Foo::Mouse2->meta->make_immutable(inline_constructor => 0);
is($method2->body, Foo::Mouse2->meta->get_method('new')->body,
   'make_immutable doesn\'t replace the constructor if we ask it not to');

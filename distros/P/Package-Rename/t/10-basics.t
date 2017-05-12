#!perl -T

use strict;
use warnings;
use Package::Rename qw/rename_package/;
use Test::More tests => 12;

package Foo;

sub foo {
	return 42;
}

package Quz::Bar;

sub bar {
	return 2012;
}

package main;

ok(keys %{*Foo::}, "Foo is defined");
ok(!keys %{*Bar::}, "Bar is not defined");

ok(Foo->can('foo'), "Foo has method foo");
ok(!Bar->can('foo'), "Bar does not have method foo");

rename_package('Foo', 'Bar');

ok(!keys %{*Foo::}, "Foo is not defined");
ok(keys %{*Bar::}, "Bar is defined");

ok(!Foo->can('foo'), "Foo does not have method foo");
ok(Bar->can('foo'), "Bar has method foo");


ok(Quz::Bar->can('bar'), 'Quz::Bar has method bar');
ok(!Quz::Baz->can('bar'), 'Quz::Baz doesn\'t have method bar');

rename_package('Quz::Bar', 'Quz::Baz');

ok(!Quz::Bar->can('bar'), 'Quz::Bar doesn\'t have method bar');
ok(Quz::Baz->can('bar'), 'Quz::Baz has method bar');

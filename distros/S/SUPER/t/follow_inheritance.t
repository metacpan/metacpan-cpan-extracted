#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
}

use lib '../lib';

use strict;
use Test::More tests => 6;

my $module = 'SUPER';
use_ok( $module ) or exit;

package Foo;

sub go_nowhere
{
	my $self = shift;
	return $self->SUPER();
}

sub foo
{
	return __PACKAGE__;
}

package Bar;

@Bar::ISA = 'Foo';

sub foo
{
	return [ $_[0]->SUPER(), __PACKAGE__ ];
}

package Baz;

@Baz::ISA = 'Bar';

sub foo
{
	my $self = shift;
	$self->SUPER();
}

package Quux;

@Quux::ISA = 'Foo';
*Quux::foo = \&Baz::foo;
*Quux::foo = 1;

package Qaax;

@Qaax::ISA = 'Quux';

package main;

my $baz = bless [], 'Quux';
is( $baz->foo(), 'Foo',
	'SUPER() should respect current, not compile-time @ISA' );

*Quux::foo = \&Bar::foo;
is_deeply( $baz->foo(), [ 'Foo', 'Bar' ], '... even when reset' );
is_deeply( Quux->foo(), [ 'Foo', 'Bar' ], '... for class calls too' );
is( Foo->go_nowhere(), (), 'SUPER() and should go nowhere with nowhere to go' );

my $q   = bless {}, 'Qaax';
is_deeply( $q->foo(), [ 'Foo', 'Bar' ], 'mu' );

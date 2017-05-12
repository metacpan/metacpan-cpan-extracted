use strict;

package Salvation::_t03_09::Aux;

our $VALUE1 = 1;
our $VALUE2 = 2;
our $VALUE3 = 3;

our $STAGE  = 0;

package Salvation::_t03_09::System;

use Moose;

extends 'Salvation::System';

sub BUILD
{
	my $self = shift;

	$self -> Service( 'Service01' );
}

sub output
{
	my ( undef, $states ) = @_;

	return $states;
}

no Moose;

package Salvation::_t03_09::System::Services::Service01;

use Moose;

extends 'Salvation::Service';

use Scalar::Util 'weaken';

sub BUILD
{
	my $self = shift;

	$self -> Hook( [ $Salvation::_t03_09::Aux::VALUE1, 'First' ] );

	$self -> Call( 'first' );
}

no Moose;

package Salvation::_t03_09::System::Services::Service01::Defaults::C;

use Moose;

extends 'Salvation::Service::Controller';

sub first
{
	&Test::More::fail();
}

no Moose;

package Salvation::_t03_09::System::Services::Service01::Hooks::First::1;

use Moose;

extends 'Salvation::Service::Hook';

sub BUILD
{
	my $self = shift;

	$self -> Hook( [ $Salvation::_t03_09::Aux::VALUE2, 'Second' ] );

	$self -> Call( 'second' );
}

no Moose;

package Salvation::_t03_09::System::Services::Service01::Hooks::First::1::Defaults::C;

use Moose;

extends 'Salvation::Service::Controller';

sub first
{
	&Test::More::fail();
}

sub second
{
	&Test::More::fail();
}

no Moose;

package Salvation::_t03_09::System::Services::Service01::Hooks::First::1::Hooks::Second::2;

use Moose;

extends 'Salvation::Service::Hook';

sub BUILD
{
	my $self = shift;

	$self -> Hook( [ $Salvation::_t03_09::Aux::VALUE3, 'Third' ] );

	$self -> Call( 'third' );
}

no Moose;

package Salvation::_t03_09::System::Services::Service01::Hooks::First::1::Hooks::Second::2::Defaults::C;

use Moose;

extends 'Salvation::Service::Controller';

sub first
{
	&Test::More::fail();
}

sub second
{
	&Test::More::fail();
}

sub third
{
	&Test::More::fail();
}

no Moose;

package Salvation::_t03_09::System::Services::Service01::Hooks::First::1::Hooks::Second::2::Hooks::Third::3;

use Moose;

extends 'Salvation::Service::Hook';

sub BUILD
{
	my $self = shift;

	$self -> Call( 'fourth' );
}

no Moose;

package Salvation::_t03_09::System::Services::Service01::Hooks::First::1::Hooks::Second::2::Hooks::Third::3::Defaults::C;

use Moose;

extends 'Salvation::Service::Controller';

sub first
{
	&Test::More::is( ++$Salvation::_t03_09::Aux::STAGE, 1 );
}

sub second
{
	&Test::More::is( ++$Salvation::_t03_09::Aux::STAGE, 2 );
}

sub third
{
	&Test::More::is( ++$Salvation::_t03_09::Aux::STAGE, 3 );
}

sub fourth
{
	&Test::More::is( ++$Salvation::_t03_09::Aux::STAGE, 4 );
}

no Moose;

package main;

use Test::More tests => 12;

use Scalar::Util 'blessed';

my $o = new_ok( 'Salvation::_t03_09::System' );

isa_ok( $o, 'Salvation::System' );

my $states = $o -> start();

isa_ok( $states, 'ARRAY' );

my $service_class = sprintf( '%s::Services::Service01', ref( $o ) );

is_deeply( $o -> __loaded_services(), [ $service_class ] );

my $state = $states -> [ 0 ];

isa_ok( $state, 'HASH' );

my $service = $state -> { 'service' };

ok( !blessed( $service ) );
is( $service, $service_class );
isa_ok( $service, 'Salvation::Service' );


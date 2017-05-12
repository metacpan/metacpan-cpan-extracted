use strict;

package Salvation::_t03_02::Aux;

our $VALUE1 = 1;
our $VALUE2 = 2;
our $VALUE3 = 3;

package Salvation::_t03_02::System;

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

package Salvation::_t03_02::System::Services::Service01;

use Moose;

extends 'Salvation::Service';

sub BUILD
{
	my $self = shift;

	$self -> Hook(
		[ $Salvation::_t03_02::Aux::VALUE1, 'First' ],
		[ $Salvation::_t03_02::Aux::VALUE2, 'Second' ],
		[ $Salvation::_t03_02::Aux::VALUE3, 'Third' ]
	);
}

sub main
{
	my $self = shift;

	&Test::More::isa_ok( $self -> view(), sprintf( '%s::Defaults::V', ref( $self ) ) );
	&Test::More::isa_ok( $self -> view(), 'Salvation::Service::View' );

	&Test::More::isa_ok( $self -> model(), sprintf( '%s::Hooks::First::1::Second::2::Third::3::Defaults::M', ref( $self ) ) );
	&Test::More::ok( not( $self -> model() -> isa( sprintf( '%s::Defaults::M', ref( $self ) ) ) ) );
	&Test::More::isa_ok( $self -> model(), 'Salvation::Service::Model' );

	&Test::More::isa_ok( $self -> controller(), sprintf( '%s::Defaults::C', ref( $self ) ) );
	&Test::More::isa_ok( $self -> controller(), 'Salvation::Service::Controller' );

	&Test::More::isa_ok( $self -> output_processor(), sprintf( '%s::Defaults::OutputProcessor', ref( $self ) ) );
	&Test::More::isa_ok( $self -> output_processor(), 'Salvation::Service::OutputProcessor' );

	&Test::More::isa_ok( $self -> hook(), sprintf( '%s::Hooks::First::1::Second::2::Third::3', ref( $self ) ) );
	&Test::More::isa_ok( $self -> hook(), 'Salvation::Service::Hook' );
}

no Moose;

package Salvation::_t03_02::System::Services::Service01::Defaults::M;

use Moose;

extends 'Salvation::Service::Model';

no Moose;

package Salvation::_t03_02::System::Services::Service01::Defaults::V;

use Moose;

extends 'Salvation::Service::View';

no Moose;

package Salvation::_t03_02::System::Services::Service01::Defaults::C;

use Moose;

extends 'Salvation::Service::Controller';

no Moose;

package Salvation::_t03_02::System::Services::Service01::Defaults::OutputProcessor;

use Moose;

extends 'Salvation::Service::OutputProcessor';

no Moose;

package Salvation::_t03_02::System::Services::Service01::Hooks::First::1::Second::2::Third::3;

use Moose;

extends 'Salvation::Service::Hook';

no Moose;

package Salvation::_t03_02::System::Services::Service01::Hooks::First::1::Second::2::Third::3::Defaults::M;

use Moose;

extends 'Salvation::Service::Model';

no Moose;

package main;

use Test::More tests => 19;

use Scalar::Util 'blessed';

my $o = new_ok( 'Salvation::_t03_02::System' );

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


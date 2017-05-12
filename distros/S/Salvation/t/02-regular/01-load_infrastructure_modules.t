use strict;

package Salvation::_t02_01::System;

use Moose;

extends 'Salvation::System';

sub BUILD
{
	my $self = shift;

	$self -> Service( 'Service01' );
}

sub main
{
	my $self = shift;

	&Test::More::isa_ok( $self -> storage(), 'Salvation::SharedStorage' );
}

sub output
{
	my ( undef, $states ) = @_;

	return $states;
}

no Moose;

package Salvation::_t02_01::System::Services::Service01;

use Moose;

extends 'Salvation::Service';

sub main
{
	my $self = shift;

	&Test::More::isa_ok( $self -> dataset(), sprintf( '%s::DataSet', ref( $self ) ) );
	&Test::More::isa_ok( $self -> dataset(), 'Salvation::Service::DataSet' );

	&Test::More::isa_ok( $self -> view(), sprintf( '%s::Defaults::V', ref( $self ) ) );
	&Test::More::isa_ok( $self -> view(), 'Salvation::Service::View' );

	&Test::More::isa_ok( $self -> model(), sprintf( '%s::Defaults::M', ref( $self ) ) );
	&Test::More::isa_ok( $self -> model(), 'Salvation::Service::Model' );

	&Test::More::isa_ok( $self -> controller(), sprintf( '%s::Defaults::C', ref( $self ) ) );
	&Test::More::isa_ok( $self -> controller(), 'Salvation::Service::Controller' );

	&Test::More::isa_ok( $self -> output_processor(), sprintf( '%s::Defaults::OutputProcessor', ref( $self ) ) );
	&Test::More::isa_ok( $self -> output_processor(), 'Salvation::Service::OutputProcessor' );

	&Test::More::isa_ok( $self -> storage(), 'Salvation::SharedStorage' );

	&Test::More::isa_ok( $self -> state(), 'Salvation::Service::State' );

	&Test::More::isa_ok( $self -> system(), 'Salvation::_t02_01::System' );
	&Test::More::isa_ok( $self -> system(), 'Salvation::System' );

	&Test::More::isnt( $self -> storage(), $self -> system() -> storage() );

	&Test::More::is( $self -> view() -> service(), $self );
	&Test::More::is( $self -> model() -> service(), $self );
	&Test::More::is( $self -> controller() -> service(), $self );
	&Test::More::is( $self -> dataset() -> service(), $self );

	&Test::More::is( $self -> output_processor() -> system(), $self -> system() );
}

no Moose;

package Salvation::_t02_01::System::Services::Service01::Defaults::M;

use Moose;

extends 'Salvation::Service::Model';

no Moose;

package Salvation::_t02_01::System::Services::Service01::Defaults::V;

use Moose;

extends 'Salvation::Service::View';

no Moose;

package Salvation::_t02_01::System::Services::Service01::Defaults::C;

use Moose;

extends 'Salvation::Service::Controller';

no Moose;

package Salvation::_t02_01::System::Services::Service01::DataSet;

use Moose;

extends 'Salvation::Service::DataSet';

no Moose;

package Salvation::_t02_01::System::Services::Service01::Defaults::OutputProcessor;

use Moose;

extends 'Salvation::Service::OutputProcessor';

no Moose;

package main;

use Test::More tests => 29;

use Scalar::Util 'blessed';

my $o = new_ok( 'Salvation::_t02_01::System' );

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


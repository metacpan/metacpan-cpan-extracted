use strict;

package Salvation::_t02_03::System;

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

package Salvation::_t02_03::System::Services::Service01;

use Moose;

extends 'Salvation::Service';

sub main
{
	my $self = shift;
	my @data = ();

	&Test::More::isa_ok( $self -> dataset(), sprintf( '%s::DataSet', ref( $self ) ) );
	&Test::More::isa_ok( $self -> dataset(), 'Salvation::Service::DataSet' );

	while( my $row = $self -> dataset() -> fetch() )
	{
		push @data, $row;
	}

	&Test::More::isa_ok( $self -> state(), 'Salvation::Service::State' );

	$self -> state() -> output( \@data );
}

no Moose;

package Salvation::_t02_03::System::Services::Service01::DataSet;

use Moose;

extends 'Salvation::Service::DataSet';

sub main
{
	return [ 'dummy' ];
}

no Moose;

package main;

use Test::More tests => 15;

use Scalar::Util 'blessed';

my $o = new_ok( 'Salvation::_t02_03::System' );

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

my $ostate = $state -> { 'state' };

ok( blessed $ostate );
isa_ok( $ostate, 'Salvation::Service::State' );

my $output = $ostate -> output();

isa_ok( $output, 'ARRAY' );
is_deeply( $output, [ 'dummy' ] );


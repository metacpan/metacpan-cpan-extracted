use strict;

package Salvation::_t02_07_01::System;

use Moose;

use Scalar::Util 'blessed';

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

sub on_service_error
{
	&Test::More::fail();
}

sub on_service_thrown_error
{
	my ( $self, $data ) = @_;

	&Test::More::isa_ok( $self, __PACKAGE__ );
	&Test::More::isa_ok( $self, 'Salvation::System' );

	&Test::More::isa_ok( $data, 'HASH' );

	my ( $err, $service, $instance ) = delete @$data{ '$@', 'service', 'instance' };

	&Test::More::is( scalar( keys( %$data ) ), 0 );

	&Test::More::isa_ok( $err, 'ARRAY' );
	&Test::More::is( $err -> [ 0 ], 'engine testing' );

	&Test::More::ok( !blessed( $service ) );
	&Test::More::is( $service, 'Salvation::_t02_07_01::System::Services::Service01' );
	&Test::More::isa_ok( $service, 'Salvation::Service' );

	&Test::More::ok( blessed $instance );
	&Test::More::isa_ok( $instance, 'Salvation::_t02_07_01::System::Services::Service01' );
	&Test::More::isa_ok( $instance, 'Salvation::Service' );
}

no Moose;

package Salvation::_t02_07_01::System::Services::Service01;

use Moose;

extends 'Salvation::Service';

sub main
{
	my $self = shift;

	$self -> throw( 'engine testing' );

	&Test::More::fail();

	return;
}

no Moose;

package main;

use Test::More tests => 17;

use Scalar::Util 'blessed';

my $o = new_ok( 'Salvation::_t02_07_01::System' );

isa_ok( $o, 'Salvation::System' );

my $states = $o -> start();

isa_ok( $states, 'ARRAY' );

my $service_class = sprintf( '%s::Services::Service01', ref( $o ) );

is_deeply( $o -> __loaded_services(), [ $service_class ] );

is( scalar( @$states ), 0 );


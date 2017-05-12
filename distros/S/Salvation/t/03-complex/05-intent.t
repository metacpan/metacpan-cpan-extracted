use strict;

package Salvation::_t03_05::System;

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

package Salvation::_t03_05::System::Services::Service01;

use Moose;

extends 'Salvation::Service';

sub init
{
	&Test::More::fail();
}

sub main
{
	&Test::More::fail();
}

sub start
{
	my ( $self, @rest ) = @_;

	my $intent  = $self -> intent( 'Salvation::_t03_05::System::Services::Service02' );

	&Test::More::isa_ok( $intent, 'Salvation::Service::Intent' );

	my $service = $intent -> service();

	&Test::More::isa_ok( $service, 'Salvation::_t03_05::System::Services::Service02' );
	&Test::More::isa_ok( $service, 'Salvation::Service' );

	&Test::More::is( $intent -> can( $_ ), $service -> can( $_ ), sprintf( q|Intent's method %s came from service|, $_ ) )
		for 'start', 'init', 'main', 'model', 'view', 'controller', 'output_processor';

	&Test::More::isnt( $intent -> can( $_ ), $service -> can( $_ ), sprintf( q|Intent's method %s is different from the one of service|, $_ ) )
		for 'args', 'dataset', 'storage', 'system', 'state';

	&Test::More::is( $intent -> $_(), $service -> $_(), sprintf( q|Intent's method %s returned the same value as the one of service|, $_ ) )
		for 'args', 'dataset', 'storage', 'system', 'state';

	&Test::More::is( $intent -> $_(), $self -> $_(), sprintf( q|Intent's method %s returned the same value as the one of caller|, $_ ) )
		for 'args', 'dataset', 'storage', 'system', 'state';

	return $intent -> start();
}

no Moose;

package Salvation::_t03_05::System::Services::Service02;

use Moose;

extends 'Salvation::Service';

sub main
{
	my $self = shift;

	$self -> state() -> output( 'engine testing' );
}

no Moose;

package main;

use Test::More tests => ( 14 + ( 1 * 7 ) + ( 3 * 5 ) );

use Scalar::Util 'blessed';

my $o = new_ok( 'Salvation::_t03_05::System' );

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

is( $ostate -> output(), 'engine testing' );


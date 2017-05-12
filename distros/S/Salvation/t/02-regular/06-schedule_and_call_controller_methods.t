use strict;

package Salvation::_t02_06::Aux;

our $STAGE = 0;

package Salvation::_t02_06::System;

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

package Salvation::_t02_06::System::Services::Service01;

use Moose;

extends 'Salvation::Service';

sub BUILD
{
	my $self = shift;

	$self -> Call( $_ ) for 'first', 'second', 'third';
}

no Moose;

package Salvation::_t02_06::System::Services::Service01::Defaults::C;

use Moose;

extends 'Salvation::Service::Controller';

sub init
{
	&Test::More::is( ++$Salvation::_t02_06::Aux::STAGE, 1 );
}

sub first
{
	&Test::More::is( ++$Salvation::_t02_06::Aux::STAGE, 2 );
}

sub second
{
	&Test::More::is( ++$Salvation::_t02_06::Aux::STAGE, 3 );
}

sub third
{
	&Test::More::is( ++$Salvation::_t02_06::Aux::STAGE, 4 );
}

sub main
{
	&Test::More::is( ++$Salvation::_t02_06::Aux::STAGE, 5 );
}

no Moose;

package main;

use Test::More tests => 13;

use Scalar::Util 'blessed';

my $o = new_ok( 'Salvation::_t02_06::System' );

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

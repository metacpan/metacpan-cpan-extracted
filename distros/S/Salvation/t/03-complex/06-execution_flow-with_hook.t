use strict;

package Salvation::_t03_06::Aux;

our $STAGE = 0;

package Salvation::_t03_06::System;

use Moose;

extends 'Salvation::System';

sub BUILD
{
	my $self = shift;

	$self -> Service( 'Service01' );
}

sub main
{
	&Test::More::is( ++$Salvation::_t03_06::Aux::STAGE, 1 );
}

sub output
{
	my ( undef, $states ) = @_;

	return $states;
}

no Moose;

package Salvation::_t03_06::System::Services::Service01;

use Moose;

extends 'Salvation::Service';

sub BUILD
{
	my $self = shift;

	$self -> Hook( [ 1, 'Something' ] );
}

sub init
{
	&Test::More::is( ++$Salvation::_t03_06::Aux::STAGE, 3 );
}

after '__run_controller_methods' => sub
{
	&Test::More::is( ++$Salvation::_t03_06::Aux::STAGE, 6 );
};

sub main
{
	&Test::More::is( ++$Salvation::_t03_06::Aux::STAGE, 8 );
}

no Moose;

package Salvation::_t03_06::System::Services::Service01::Defaults::V;

use Moose;

extends 'Salvation::Service::View';

sub main
{
	return [ sub{} ];
}

after 'process' => sub
{
	&Test::More::is( ++$Salvation::_t03_06::Aux::STAGE, 12 );
};

no Moose;

package Salvation::_t03_06::System::Services::Service01::Defaults::C;

use Moose;

extends 'Salvation::Service::Controller';

sub init
{
	&Test::More::is( ++$Salvation::_t03_06::Aux::STAGE, 5 );
}

sub main
{
	&Test::More::is( ++$Salvation::_t03_06::Aux::STAGE, 10 );
}

sub before_view_processing
{
	&Test::More::is( ++$Salvation::_t03_06::Aux::STAGE, 11 );
}

sub after_view_processing
{
	&Test::More::is( ++$Salvation::_t03_06::Aux::STAGE, 13 );
}

no Moose;

package Salvation::_t03_06::System::Services::Service01::DataSet;

use Moose;

extends 'Salvation::Service::DataSet';

sub main
{
	return [ 'dummy' ];
}

no Moose;

package Salvation::_t03_06::System::Services::Service01::Hooks::Something::1;

use Moose;

extends 'Salvation::Service::Hook';

before 'init' => sub
{
	&Test::More::is( ++$Salvation::_t03_06::Aux::STAGE, 2 );
};

before 'main' => sub
{
	&Test::More::is( ++$Salvation::_t03_06::Aux::STAGE, 7 );
};

after 'init' => sub
{
	&Test::More::is( ++$Salvation::_t03_06::Aux::STAGE, 4 );
};

after 'main' => sub
{
	&Test::More::is( ++$Salvation::_t03_06::Aux::STAGE, 9 );
};

no Moose;

package main;

use Test::More tests => 21;

use Scalar::Util 'blessed';

my $o = new_ok( 'Salvation::_t03_06::System' );

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


use strict;

package Salvation::_t03_08::Aux;

our $VALUE1 = 1;
our $VALUE2 = 2;
our $VALUE3 = 3;

our $SERVICE = undef;

package Salvation::_t03_08::System;

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

package Salvation::_t03_08::System::Services::Service01;

use Moose;

extends 'Salvation::Service';

use Scalar::Util 'weaken';

sub BUILD
{
	my $self = shift;

	$self -> Hook( [ $Salvation::_t03_08::Aux::VALUE1, 'First' ] );
}

sub init
{
	my $self = shift;

	weaken( $Salvation::_t03_08::Aux::SERVICE = $self );
}

sub main
{
	&Test::More::ok( 1 );
}

no Moose;

package Salvation::_t03_08::System::Services::Service01::Hooks::First::1;

use Moose;

extends 'Salvation::Service::Hook';

sub BUILD
{
	my $self = shift;

	$self -> Hook( [ $Salvation::_t03_08::Aux::VALUE2, 'Second' ] );
}

no Moose;

package Salvation::_t03_08::System::Services::Service01::Hooks::First::1::Hooks::Second::2;

use Moose;

extends 'Salvation::Service::Hook';

sub BUILD
{
	my $self = shift;

	$self -> Hook( [ $Salvation::_t03_08::Aux::VALUE3, 'Third' ] );
}

no Moose;

package Salvation::_t03_08::System::Services::Service01::Hooks::First::1::Hooks::Second::2::Hooks::Third::3;

use Moose;

extends 'Salvation::Service::Hook';

sub main
{
	my $hook    = shift;
	my $service = $Salvation::_t03_08::Aux::SERVICE;

	&Test::More::isa_ok( $hook, 'Salvation::_t03_08::System::Services::Service01::Hooks::First::1::Hooks::Second::2::Hooks::Third::3' );
	&Test::More::isa_ok( $service, 'Salvation::_t03_08::System::Services::Service01' );

	&Test::More::is( $service, $hook -> __associated_service() );

	&Test::More::isa_ok( $hook -> __parent_link(), 'Salvation::_t03_08::System::Services::Service01::Hooks::First::1::Hooks::Second::2' );
	&Test::More::is( $service, $hook -> __parent_link() -> __associated_service() );

	&Test::More::isa_ok( $hook -> __parent_link() -> __parent_link(), 'Salvation::_t03_08::System::Services::Service01::Hooks::First::1' );
	&Test::More::is( $service, $hook -> __parent_link() -> __parent_link() -> __associated_service() );

	&Test::More::ok( not( defined $hook -> __parent_link() -> __parent_link() -> __parent_link() ) );

	$hook -> SUPER::main( @_ );
}

no Moose;

package main;

use Test::More tests => 17;

use Scalar::Util 'blessed';

my $o = new_ok( 'Salvation::_t03_08::System' );

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


use strict;

package Salvation::_t01_02::System;

use Moose;

extends 'Salvation::System';

sub BUILD
{
	my $self = shift;

	$self -> Service( sprintf( 'Service%.2d', $_ ) ) for 1 .. 3;
}

sub output
{
	my ( undef, $states ) = @_;

	return $states;
}

no Moose;

package Salvation::_t01_02::System::Services::Service01;

use Moose;

extends 'Salvation::Service';

no Moose;

package Salvation::_t01_02::System::Services::Service02;

use Moose;

extends 'Salvation::Service';

no Moose;

package Salvation::_t01_02::System::Services::Service03;

use Moose;

extends 'Salvation::Service';

no Moose;

package main;

use Test::More tests => ( 4 + ( 4 * 3 ) );

use Scalar::Util 'blessed';

my $o = new_ok( 'Salvation::_t01_02::System' );

isa_ok( $o, 'Salvation::System' );

my $states = $o -> start();

isa_ok( $states, 'ARRAY' );

my @service_classes = ( map{ sprintf( '%s::Services::Service%.2d', ref( $o ), $_ ) } ( 1 .. 3 ) );

is_deeply( $o -> __loaded_services(), \@service_classes );

for( my $i = 0; $i < scalar( @service_classes ); ++$i )
{
	my $state = $states -> [ $i ];

	isa_ok( $state, 'HASH' );

	my $service = $state -> { 'service' };

	ok( !blessed( $service ) );
	is( $service, $service_classes[ $i ] );
	isa_ok( $service, 'Salvation::Service' );
}


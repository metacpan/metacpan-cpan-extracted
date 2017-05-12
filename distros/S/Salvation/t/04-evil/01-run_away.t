use strict;

package Salvation::_t04_01::Aux;

our $STAGE = 0;

package Salvation::_t04_01::System;

use Moose;

extends 'Salvation::System';

use Scalar::Util 'blessed';

sub BUILD
{
	my $self = shift;

	$self -> Service( $_ ) for 'Service01', 'Service02';
}

sub on_service_controller_method_error
{
	my ( $self, $data ) = @_;

	if( blessed( my $e = $data -> { '$@' } ) )
	{
		if( $e -> isa( 'SomeException' ) )
		{
			&Test::More::ok( 1 );

			$self -> Fatal( $e );

			$self -> stop();
		}
	}
}

no Moose;

package Salvation::_t04_01::System::Services::Service01;

use Moose;

extends 'Salvation::Service';

sub BUILD
{
	my $self = shift;

	$self -> Call( $_ ) for 'something', 'other';
}

no Moose;

package Salvation::_t04_01::System::Services::Service01::Defaults::C;

use Moose;

extends 'Salvation::Service::Controller';

sub something
{
	&Test::More::ok( 1 );

	die SomeException -> new( str => q|Hey! Ima leaving!| );
}

sub other
{
	&Test::More::fail();
}

no Moose;

package SomeException;

use Moose;

has 'str'	=> ( is => 'rw', isa => 'Str', required => 1 );

no Moose;

package Salvation::_t04_01::System::Services::Service02;

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

no Moose;

package main;

use Test::More tests => 6;

use Scalar::Util 'blessed';

my $o = new_ok( 'Salvation::_t04_01::System' );

isa_ok( $o, 'Salvation::System' );

eval{ $o -> start() };

my $e = $@;

isa_ok( $e, 'SomeException' );

is( $e -> str(), q|Hey! Ima leaving!| );


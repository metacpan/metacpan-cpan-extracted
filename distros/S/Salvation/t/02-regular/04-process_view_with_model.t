use strict;

package Salvation::_t02_04::System;

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

package Salvation::_t02_04::System::Services::Service01;

use Moose;

extends 'Salvation::Service';

no Moose;

package Salvation::_t02_04::System::Services::Service01::Defaults::M;

use Moose;

extends 'Salvation::Service::Model';

sub static_thing
{
	my ( $self, $row ) = @_;

	&Test::More::is_deeply( $row, \'dummy' );

	return 'Y SO STATIC?';
}

sub __something
{
	my ( $self, $row, $column ) = @_;

	&Test::More::is_deeply( $row, \'dummy' );

	return $column;
}

sub and_now_some
{
	my ( $self, $row ) = @_;

	&Test::More::is_deeply( $row, \'funny' );

	return ( 'return value', 'can include some title for the column' );
}

sub and_now_manipulation
{
	my ( $self, $row ) = @_;

	&Test::More::is_deeply( $row, \'dummy' );

	$$row =~ tr/dm/fn/;

	&Test::More::is_deeply( $row, \'funny' );

	return $$row;
}

no Moose;

package Salvation::_t02_04::System::Services::Service01::Defaults::V;

use Moose;

extends 'Salvation::Service::View';

sub main
{
	return [
		static    => [ 'thing' ],
		something => [ 'default_handler_will_be_called_here' ],
		and_now   => [ 'manipulation', 'some' ]
	];
}

no Moose;

package Salvation::_t02_04::System::Services::Service01::DataSet;

use Moose;

extends 'Salvation::Service::DataSet';

sub main
{
	my $dummy = 'dummy';

	return [ \$dummy ];
}

no Moose;

package main;

use Test::More tests => 56;

use Scalar::Util 'blessed';

my $o = new_ok( 'Salvation::_t02_04::System' );

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

my $stack = $ostate -> view_output();

isa_ok( $stack, 'Salvation::Service::View::Stack' );

isa_ok( $stack -> frames(), 'ARRAY' );

is( scalar( @{ $stack -> frames() } ), 3 );

isa_ok( $stack -> frames() -> [ $_ ], 'Salvation::Service::View::Stack::Frame::List' ) for 0 .. 2;

{
	my $list = $stack -> frames() -> [ 0 ];

	is( $list -> fname(), 'static' );

	is( scalar( @{ $list -> data() } ), 1 );

	isa_ok( scalar( $list -> data_by_name( 'thing' ) ), 'ARRAY' );
	isa_ok( ( $list -> data_by_name( 'thing' ) )[ 0 ], 'Salvation::Service::View::Stack::Frame' );

	my $node = $list -> data_by_name( 'thing' ) -> [ 0 ];

	isa_ok( $node, 'Salvation::Service::View::Stack::Frame' );

	is( $node -> cap(), '[FIELD_THING]' );
	is( $node -> data(), 'Y SO STATIC?' );
	is( $node -> ftype(), 'static' );
	is( $node -> fname(), 'thing' );
}

{
	my $list = $stack -> frames() -> [ 1 ];

	is( $list -> fname(), 'something' );

	is( scalar( @{ $list -> data() } ), 1 );

	isa_ok( scalar( $list -> data_by_name( 'default_handler_will_be_called_here' ) ), 'ARRAY' );
	isa_ok( ( $list -> data_by_name( 'default_handler_will_be_called_here' ) )[ 0 ], 'Salvation::Service::View::Stack::Frame' );

	my $node = $list -> data_by_name( 'default_handler_will_be_called_here' ) -> [ 0 ];

	isa_ok( $node, 'Salvation::Service::View::Stack::Frame' );

	is( $node -> cap(), '[FIELD_DEFAULT_HANDLER_WILL_BE_CALLED_HERE]' );
	is( $node -> data(), 'default_handler_will_be_called_here' );
	is( $node -> ftype(), 'something' );
	is( $node -> fname(), 'default_handler_will_be_called_here' );
}

{
	my $list = $stack -> frames() -> [ 2 ];

	is( $list -> fname(), 'and_now' );

	is( scalar( @{ $list -> data() } ), 2 );

	isa_ok( scalar( $list -> data_by_name( $_ ) ), 'ARRAY' ) for 'manipulation', 'some';
	isa_ok( ( $list -> data_by_name( $_ ) )[ 0 ], 'Salvation::Service::View::Stack::Frame' ) for 'manipulation', 'some';

	{
		my $node = $list -> data() -> [ 0 ];

		isa_ok( $node, 'Salvation::Service::View::Stack::Frame' );

		is( $node -> cap(), '[FIELD_MANIPULATION]' );
		is( $node -> data(), 'funny' );
		is( $node -> ftype(), 'and_now' );
		is( $node -> fname(), 'manipulation' );
	}

	{
		my $node = $list -> data() -> [ 1 ];

		isa_ok( $node, 'Salvation::Service::View::Stack::Frame' );

		is( $node -> cap(), 'can include some title for the column' );
		is( $node -> data(), 'return value' );
		is( $node -> ftype(), 'and_now' );
		is( $node -> fname(), 'some' );
	}
}


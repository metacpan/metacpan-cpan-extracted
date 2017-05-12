use strict;

package Salvation::MacroProcessor::_t00_02_01::Class;

use Moose;

use Salvation::MacroProcessor;

has 'attribute'	=> ( is => 'rw', isa => 'Any' );

smp_add_description 'attribute' => (
	postfilter => sub
	{
		my ( $object, $value ) = @_;

		&Test::More::isa_ok( $object, 'Salvation::MacroProcessor::_t00_02_01::Class', 'object' );
		&Test::More::is( $value, 'stub', 'value is ok' );

		return ( ( $object -> attribute() eq $value ) ? 1 : 0 );
	}
);

no Moose;

package main;

use Test::More tests => 3;

my $description = Salvation::MacroProcessor::_t00_02_01::Class -> meta() -> smp_find_description_by_name( 'attribute' );

is( $description -> postfilter( Salvation::MacroProcessor::_t00_02_01::Class -> new( attribute => 'stub' ), 'stub' ), 1 );


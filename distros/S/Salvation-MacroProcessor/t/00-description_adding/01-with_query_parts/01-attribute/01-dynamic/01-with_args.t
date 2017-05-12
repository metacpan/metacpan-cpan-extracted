use strict;

package Salvation::MacroProcessor::_t00_01_01_01_01::Class;

use Moose;

use Salvation::MacroProcessor;

has 'attribute'	=> ( is => 'rw', isa => 'Any' );

smp_add_description 'attribute' => (
	query => sub
	{
		my $value = shift;

		return [
			column => $value
		];
	}
);

no Moose;

package main;

use Test::More tests => 1;

my $description = Salvation::MacroProcessor::_t00_01_01_01_01::Class -> meta() -> smp_find_description_by_name( 'attribute' );

is_deeply( $description -> query( 'value' ), [ column => 'value' ] );


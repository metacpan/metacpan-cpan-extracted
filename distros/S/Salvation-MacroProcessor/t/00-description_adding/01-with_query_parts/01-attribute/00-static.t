use strict;

package Salvation::MacroProcessor::_t00_01_01_00::Class;

use Moose;

use Salvation::MacroProcessor;

has 'attribute'	=> ( is => 'rw', isa => 'Any' );

smp_add_description 'attribute' => (
	query => [
		column => 'value'
	]
);

no Moose;

package main;

use Test::More tests => 1;

my $description = Salvation::MacroProcessor::_t00_01_01_00::Class -> meta() -> smp_find_description_by_name( 'attribute' );

is_deeply( $description -> query(), [ column => 'value' ] );


use strict;

package Salvation::MacroProcessor::_t00_01_00_00::Class;

use Moose;

use Salvation::MacroProcessor;

sub method { 'stub' }

smp_add_description 'method' => (
	query => [
		column => 'value'
	]
);

no Moose;

package main;

use Test::More tests => 1;

my $description = Salvation::MacroProcessor::_t00_01_00_00::Class -> meta() -> smp_find_description_by_name( 'method' );

is_deeply( $description -> query(), [ column => 'value' ] );


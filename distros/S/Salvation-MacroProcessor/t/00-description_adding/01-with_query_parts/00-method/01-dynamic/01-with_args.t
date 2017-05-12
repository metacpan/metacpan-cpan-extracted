use strict;

package Salvation::MacroProcessor::_t00_01_00_01_01::Class;

use Moose;

use Salvation::MacroProcessor;

sub method { 'stub' }

smp_add_description 'method' => (
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

my $description = Salvation::MacroProcessor::_t00_01_00_01_01::Class -> meta() -> smp_find_description_by_name( 'method' );

is_deeply( $description -> query( 'value' ), [ column => 'value' ] );


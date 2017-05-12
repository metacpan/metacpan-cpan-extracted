use strict;

package Salvation::MacroProcessor::_t00_02_00::Class;

use Moose;

use Salvation::MacroProcessor;

sub method { 'stub' }

smp_add_description 'method' => (
	postfilter => sub
	{
		my ( $object, $value ) = @_;

		&Test::More::isa_ok( $object, 'Salvation::MacroProcessor::_t00_02_00::Class', 'object' );
		&Test::More::is( $value, 'stub', 'value is ok' );

		return ( ( $object -> method() eq $value ) ? 1 : 0 );
	}
);

no Moose;

package main;

use Test::More tests => 3;

my $description = Salvation::MacroProcessor::_t00_02_00::Class -> meta() -> smp_find_description_by_name( 'method' );

is( $description -> postfilter( Salvation::MacroProcessor::_t00_02_00::Class -> new(), 'stub' ), 1 );


use strict;

package Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t00_01_01_01_02::Class;

use Moose;

extends 'Salvation::MacroProcessor::Hooks';

sub query_from_attribute
{
	my ( $self, $description, $attr, $value ) = @_;

	&Test::More::isa_ok( $self, 'Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t00_01_01_01_02::Class', 'hook' );
	&Test::More::isa_ok( $description, 'Salvation::MacroProcessor::MethodDescription', 'description' );
	&Test::More::isa_ok( $attr, 'Moose::Meta::Attribute', 'attribute' );

	&Test::More::is( $description -> method(), 'attribute', 'method name is ok' );
	&Test::More::is( $description -> attr(), $attr, 'corresponsing Moose::Meta::Attribute of description is ok' );

	&Test::More::is( $attr -> name(), 'attribute', 'attribute name is ok' );

	return (
		$attr -> name() => $value
	);
}

no Moose;

package Salvation::MacroProcessor::_t00_01_01_01_02::Class;

use Moose;

use Salvation::MacroProcessor;

has 'attribute'	=> ( is => 'rw', isa => 'Any' );

smp_add_description 'attribute';

no Moose;

package main;

use Test::More tests => 7;

my $description = Salvation::MacroProcessor::_t00_01_01_01_02::Class -> meta() -> smp_find_description_by_name( 'attribute' );

$INC{ 'Salvation/MacroProcessor/Hooks/Salvation/MacroProcessor/_t00_01_01_01_02/Class.pm' } = 1;

is_deeply( $description -> query( 'value' ), [ attribute => 'value' ] );


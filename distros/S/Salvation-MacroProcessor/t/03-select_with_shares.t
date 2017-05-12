use strict;

package Salvation::MacroProcessor::_t03::AUX;

our $COUNTER = 0;

package Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t03::Iterator;

use Moose;

with 'Salvation::MacroProcessor::Iterator::Compliance';

sub next
{
	&Test::More::ok( 1, 'gonna return some object' );

	return Salvation::MacroProcessor::_t03::Class -> new(
		attribute => 'OH HAI'
	);
}

sub first { shift -> next() }
sub last { shift -> next() }
sub seek {}
sub count { 1 }
sub to_start {}
sub to_end {}
sub __position {}
sub prev { shift -> next() }

no Moose;

package Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t03::Class;

use Moose;

extends 'Salvation::MacroProcessor::Hooks';

sub select
{
	my ( $self, $spec ) = @_;

	&Test::More::isa_ok( $self, 'Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t03::Class', 'hook' );
	&Test::More::isa_ok( $spec, 'Salvation::MacroProcessor::Spec', 'spec' );

	&Test::More::is_deeply( $spec -> query(), [
		method1_column => {
			value => 'value1',
			some_named_column => 1,
			some_other_named_column => 2
		},
		method2_column => {
			value => 'value2',
			some_named_column => 1,
			some_other_named_column => 2
		}
	], 'query parts are ok' );

	return Salvation::MacroProcessor::Iterator -> new(
		iterator => Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t03::Iterator -> new(),
		postfilter => sub{ $spec -> __postfilter_each( shift ) }
	);
}

no Moose;

package Salvation::MacroProcessor::_t03::Class;

use Moose;

use Salvation::MacroProcessor;


has 'attribute' => ( is => 'rw', isa => 'Any' );

sub method1 { 'stub' }

sub method2 { 'stub' }


smp_add_share some_name => sub
{
	&Test::More::ok( 1, 'this code will be called only once' );

	return ++$Salvation::MacroProcessor::_t03::AUX::COUNTER;
};

smp_add_share some_other_name => sub
{
	&Test::More::ok( 1, 'this code will also be called only once' );

	return ++$Salvation::MacroProcessor::_t03::AUX::COUNTER;
};

foreach my $num ( 1 .. 2 )
{
	smp_add_description sprintf( 'method%d', $num ) => (
		required_shares => [ 'some_name', 'some_other_name' ],
		query => sub
		{
			my ( $shares, $value ) = @_;

			&Test::More::isa_ok( $shares, 'HASH', q|shares' storage| );

			return [
				sprintf( 'method%d_column', $num ) => {
					value => $value,
					some_named_column => $shares -> { 'some_name' } -> [ 0 ],
					some_other_named_column => $shares -> { 'some_other_name' } -> [ 0 ]
				}
			];
		}
	);
}


no Moose;

package main;

use Salvation::MacroProcessor::Spec ();

use Test::More tests => 11;

$INC{ 'Salvation/MacroProcessor/Hooks/Salvation/MacroProcessor/_t03/Class.pm' } = 1;

my $iterator = Salvation::MacroProcessor::Spec
	-> parse_and_new(
		'Salvation::MacroProcessor::_t03::Class' => [
			[ method1 => 'value1' ],
			[ method2 => 'value2' ]
		]
	)
	-> select()
;

isa_ok( $iterator, 'Salvation::MacroProcessor::Iterator', 'iterator' );

my $object = $iterator -> first();

isa_ok( $object, 'Salvation::MacroProcessor::_t03::Class', 'result' );

is( $object -> attribute(), 'OH HAI', 'OH HAI' );


use strict;

package Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t01::Iterator;

use Moose;

with 'Salvation::MacroProcessor::Iterator::Compliance';

sub next
{
	&Test::More::ok( 1, 'gonna return some object' );

	return Salvation::MacroProcessor::_t01::Class -> new(
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

package Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t01::Class;

use Moose;

extends 'Salvation::MacroProcessor::Hooks';

sub query_from_attribute
{
	my ( undef, undef, $attr, $value ) = @_;

	return (
		$attr -> name() => $value
	);
}

sub select
{
	my ( $self, $spec ) = @_;

	&Test::More::isa_ok( $self, 'Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t01::Class', 'hook' );
	&Test::More::isa_ok( $spec, 'Salvation::MacroProcessor::Spec', 'spec' );

	&Test::More::is_deeply( $spec -> query(), [
		method_column => [ 'value' ],
		method_additions => 'something',
		attribute_column => 'eulav_rehto',
		autogen_attribute => { a => 1, b => 2 },
		asd => 'qwe'
	], 'query parts are ok' );

	return Salvation::MacroProcessor::Iterator -> new(
		iterator => Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t01::Iterator -> new(),
		postfilter => sub{ $spec -> __postfilter_each( shift ) }
	);
}

no Moose;

package Salvation::MacroProcessor::_t01::Class;

use Moose;

use Salvation::MacroProcessor;


sub method { 'stub' }

has 'attribute'	=> ( is => 'rw', isa => 'Any' );

has 'autogen_attribute'	=> ( is => 'rw', isa => 'Any' );

sub method_w_postfilter;

sub method_w_postfilter_and_query_parts;

sub unused_method;


smp_add_description 'unused_method' => (
	query => sub
	{
		&Test::More::fail();

		return [];
	}
);

smp_add_description 'method' => (
	query => sub
	{
		my $value = shift;

		return [
			method_column => $value,
			method_additions => 'something'
		];
	}
);

smp_add_description 'attribute' => (
	query => sub
	{
		my $value = shift;

		return [
			attribute_column => join( '', reverse split( //, $value ) ) # :3
		];
	}
);

smp_add_description 'autogen_attribute';

smp_add_description 'method_w_postfilter' => (
	postfilter => sub
	{
		my ( $object, $value ) = @_;

		&Test::More::isa_ok( $object, 'Salvation::MacroProcessor::_t01::Class', 'object' );
		&Test::More::is( $value, 'this_value_should_be_checked_by_postfilter', 'value of method_w_postfilter is ok' );

		return 1;
	}
);

smp_add_description 'method_w_postfilter_and_query_parts' => (
	query => [
		asd => 'qwe'
	],
	postfilter => sub
	{
		my ( $object, $value ) = @_;

		&Test::More::isa_ok( $object, 'Salvation::MacroProcessor::_t01::Class', 'object' );
		&Test::More::is( $value, 'this_value_should_also_be_checked_by_postfilter', 'value of method_w_postfilter_and_query_parts is ok' );

		return 1;
	}
);

no Moose;

package main;

use Salvation::MacroProcessor::Spec ();

use Test::More tests => 11;

$INC{ 'Salvation/MacroProcessor/Hooks/Salvation/MacroProcessor/_t01/Class.pm' } = 1;

my $iterator = Salvation::MacroProcessor::Spec
	-> parse_and_new(
		'Salvation::MacroProcessor::_t01::Class' => [
			[ method => [ 'value' ] ],
			[ attribute => 'other_value' ],
			[ autogen_attribute => { a => 1, b => 2 } ],
			[ method_w_postfilter => 'this_value_should_be_checked_by_postfilter' ],
			[ method_w_postfilter_and_query_parts => 'this_value_should_also_be_checked_by_postfilter' ]
		]
	)
	-> select()
;

isa_ok( $iterator, 'Salvation::MacroProcessor::Iterator', 'iterator' );

my $object = $iterator -> first();

isa_ok( $object, 'Salvation::MacroProcessor::_t01::Class', 'result' );

is( $object -> attribute(), 'OH HAI', 'OH HAI' );


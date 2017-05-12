use strict;

package Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t06::Iterator;

use Moose;

with 'Salvation::MacroProcessor::Iterator::Compliance';

sub next
{
	&Test::More::ok( 1, 'gonna return some object' );

	return Salvation::MacroProcessor::_t06::Class6 -> new(
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

package Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t06::Class6;

use Moose;

extends 'Salvation::MacroProcessor::Hooks';

sub select
{
	my ( $self, $spec ) = @_;

	&Test::More::isa_ok( $self, 'Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t06::Class6', 'hook' );
	&Test::More::isa_ok( $spec, 'Salvation::MacroProcessor::Spec', 'spec' );

	&Test::More::is_deeply( $spec -> query(), [

		method4_column => 'nearest description it is',
		foreign_share2_value_for_connector => 'share2_value',
		foreign_connected_query_parts => [
			method1_column => 'static_value',
			method2_column => [ 'share1_storage', 'some value for foreign_method2', [ 'something', 'is', 'here' ] ],
			method3_column => [ 'share1_storage', 'some value for foreign_method2', [ 'something', 'is', 'here' ] ],
			method3_second_column => 'share2_value',
			self_connected_query_parts => [
				attribute_column => 'value for self_attribute',
				method1_column => 'static_value'
			]
		]

	], 'query parts are ok' );

	return Salvation::MacroProcessor::Iterator -> new(
		iterator => Salvation::MacroProcessor::Hooks::Salvation::MacroProcessor::_t06::Iterator -> new(),
		postfilter => sub{ $spec -> __postfilter_each( shift ) }
	);
}

no Moose;

package Salvation::MacroProcessor::_t06::Class1;

use Moose;

use Salvation::MacroProcessor;


has 'attribute' => ( is => 'rw', isa => 'Any' );

sub method1 { 'stub' }

sub method2 { 'stub' }

sub method3 { 'stub' }


smp_add_description method1 => (
	query => [
		method1_column => 'static_value'
	]
);

smp_add_share share1 => sub
{
	return [ 'share1_storage' ];
};

smp_add_description method2 => (
	required_shares => [ 'share1' ],
	query => sub
	{
		my ( $shares, $value ) = @_;

		my $shared_value = $shares -> { 'share1' } -> [ 0 ];

		push @$shared_value, $value;

		return [
			method2_column => $shared_value
		];
	}
);

with 'Salvation::MacroProcessor::_t06::Role1';

no Moose;

package Salvation::MacroProcessor::_t06::Role1;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_add_share share2 => sub
{
	return 'share2_value';
};

smp_add_description method3 => (
	required_shares => [ 'share1', 'share2' ],
	query => sub
	{
		my ( $shares, $value ) = @_;

		my $shared_value = $shares -> { 'share1' } -> [ 0 ];

		push @$shared_value, $value;

		return [
			method3_column => $shared_value,
			method3_second_column => $shares -> { 'share2' } -> [ 0 ]
		];
	}
);

no Moose::Role;

package Salvation::MacroProcessor::_t06::Class2;

use Moose;

use Salvation::MacroProcessor;

extends 'Salvation::MacroProcessor::_t06::Class1';

with 'Salvation::MacroProcessor::_t06::Role2';

with 'Salvation::MacroProcessor::_t06::Role3';

no Moose;

package Salvation::MacroProcessor::_t06::Role2;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_add_description attribute => (
	query => sub
	{
		my $value = shift;

		return [
			attribute_column => $value
		];
	}
);

no Moose::Role;

package Salvation::MacroProcessor::_t06::Role3;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_import_shares
	class  => 'Salvation::MacroProcessor::_t06::Class2',
	prefix => 'self_'
;

smp_add_connector self_connector => (
	code => sub
	{
		my $query = shift;

		return [
			self_connected_query_parts => $query
		];
	}
);

smp_import_descriptions
	class     => 'Salvation::MacroProcessor::_t06::Class2',
	prefix    => 'self_',
	connector => 'self_connector'
;

no Moose::Role;

package Salvation::MacroProcessor::_t06::Class3;

use Moose;

use Salvation::MacroProcessor;

extends 'Salvation::MacroProcessor::_t06::Class2';

no Moose;

package Salvation::MacroProcessor::_t06::Class4;

use Moose;

use Salvation::MacroProcessor;

smp_import_shares
	class  => 'Salvation::MacroProcessor::_t06::Class3',
	prefix => 'foreign_'
;

smp_add_share foreign_connector_storage => sub
{
	return [];
};

smp_add_connector foreign_connector => (
	required_shares => [ 'foreign_share2', 'foreign_connector_storage' ],
	code => sub
	{
		my ( $shares, $query ) = @_;

		my $storage = $shares -> { 'foreign_connector_storage' } -> [ 0 ];

		push @$storage, @$query;

		return [
			foreign_share2_value_for_connector => $shares -> { 'foreign_share2' } -> [ 0 ],
			foreign_connected_query_parts => $storage
		];
	}
);

smp_import_descriptions
	class     => 'Salvation::MacroProcessor::_t06::Class3',
	prefix    => 'foreign_',
	connector => 'foreign_connector'
;

sub method4;

smp_add_description method4 => (
	query => sub
	{
		my $value = shift;

		return [
			method4_column => $value
		];
	}
);

has 'attribute' => ( is => 'rw', isa => 'Any' );

no Moose;

package Salvation::MacroProcessor::_t06::Class5;

use Moose;

use Salvation::MacroProcessor;

extends 'Salvation::MacroProcessor::_t06::Class4';

no Moose;

package Salvation::MacroProcessor::_t06::Class6;

use Moose;

use Salvation::MacroProcessor;

extends 'Salvation::MacroProcessor::_t06::Class5';

no Moose;

package main;

use Salvation::MacroProcessor::Spec ();

use Test::More tests => 7;

$INC{ 'Salvation/MacroProcessor/Hooks/Salvation/MacroProcessor/_t06/Class6.pm' } = 1;

my $iterator = Salvation::MacroProcessor::Spec
	-> parse_and_new(
		'Salvation::MacroProcessor::_t06::Class6' => [
			[ foreign_method1 => 1 ],
			[ foreign_method2 => 'some value for foreign_method2' ],
			[ foreign_method3 => [ 'something', 'is', 'here' ] ],
			[ foreign_self_attribute => 'value for self_attribute' ],
			[ foreign_self_method1 => -1 ],
			[ method4 => 'nearest description it is' ]
		]
	)
	-> select()
;

isa_ok( $iterator, 'Salvation::MacroProcessor::Iterator', 'iterator' );

my $object = $iterator -> first();

isa_ok( $object, 'Salvation::MacroProcessor::_t06::Class6', 'result' );

is( $object -> attribute(), 'OH HAI', 'OH HAI' );


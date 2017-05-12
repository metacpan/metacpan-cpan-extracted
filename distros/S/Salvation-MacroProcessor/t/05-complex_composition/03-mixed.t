use strict;

package Salvation::MacroProcessor::_t05_03::Role::Inner;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_add_description 'method';

no Moose::Role;

package Salvation::MacroProcessor::_t05_03::Role::Outer1;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_add_share some_name => sub
{
	&Test::More::ok( 1, 'shared value getter is called' );

	return;
};

no Moose::Role;

package Salvation::MacroProcessor::_t05_03::Role::Outer2;

use Moose::Role;

with 'Salvation::MacroProcessor::_t05_03::Role::Inner';

no Moose::Role;

package Salvation::MacroProcessor::_t05_03::Class1;

use Moose;

use Salvation::MacroProcessor;

sub method;

with
	'Salvation::MacroProcessor::_t05_03::Role::Outer1',
	'Salvation::MacroProcessor::_t05_03::Role::Outer2';

no Moose;

package Salvation::MacroProcessor::_t05_03::Class2;

use Moose;

use Salvation::MacroProcessor;

extends 'Salvation::MacroProcessor::_t05_03::Class1';

no Moose;

package Salvation::MacroProcessor::_t05_03::Class3;

use Moose;

use Salvation::MacroProcessor;

with 'Salvation::MacroProcessor::_t05_03::Role::Outer3';

with 'Salvation::MacroProcessor::_t05_03::Role::Outer4';

no Moose;

package Salvation::MacroProcessor::_t05_03::Role::Outer3;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_add_connector stub_connector => (
	code => sub
	{
		&Test::More::ok( 1, 'stub_connector code is called' );

		return;
	}
);

smp_import_shares
	class => 'Salvation::MacroProcessor::_t05_03::Class2'
;

smp_import_descriptions
	class     => 'Salvation::MacroProcessor::_t05_03::Class2',
	connector => 'stub_connector'
;

no Moose::Role;

package Salvation::MacroProcessor::_t05_03::Role::Outer4;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_add_connector self_connector => (
	code => sub
	{
		&Test::More::ok( 1, 'self_connector code is called' );

		return;
	}
);

smp_import_shares
	class  => 'Salvation::MacroProcessor::_t05_03::Class3',
	prefix => 'self_'
;

smp_import_descriptions
	class     => 'Salvation::MacroProcessor::_t05_03::Class3',
	prefix    => 'self_',
	connector => 'self_connector'
;

no Moose::Role;

package Salvation::MacroProcessor::_t05_03::Class4;

use Moose;

use Salvation::MacroProcessor;

extends 'Salvation::MacroProcessor::_t05_03::Class3';

no Moose;

package main;

use Test::More tests => 8;

my $class = 'Salvation::MacroProcessor::_t05_03::Class4';

foreach my $share_name ( ( 'some_name', 'self_some_name' ) )
{
	subtest sprintf( 'shares: %s', $share_name ) => sub
	{
		plan tests => 2;

		my $share = $class -> meta() -> smp_find_share_by_name( $share_name );

		isa_ok( $share, 'CODE', 'shared value getter' );

		$share -> ();
	};
}

foreach my $description_name ( ( 'method', 'self_method' ) )
{
	subtest sprintf( 'descriptions: %s', $description_name ) => sub
	{
		plan tests => 2;

		my $description = $class -> meta() -> smp_find_description_by_name( $description_name );

		isa_ok( $description, 'Salvation::MacroProcessor::MethodDescription', 'description' );

		is( $description -> associated_meta(), $class -> meta(), 'metaclass of description is ok' );
	};
}

foreach my $connector_name ( ( 'self_connector', 'stub_connector' ) )
{
	subtest sprintf( 'connectors: %s', $connector_name ) => sub
	{
		plan tests => 3;

		my $connector = $class -> meta() -> smp_find_connector_by_name( $connector_name );

		isa_ok( $connector, 'Salvation::MacroProcessor::Connector', 'connector' );
		is( $connector -> associated_meta(), $class -> meta(), 'connector associated meta is ok' );

		$connector -> code() -> ();
	};
}

{
	my $description = $class -> meta() -> smp_find_description_by_name( 'method' );

	is_deeply( $description -> connector_chain(), [
		[ 'Salvation::MacroProcessor::_t05_03::Class3', 'stub_connector' ]
	], 'connector chain of "method" is ok' );
}

{
	my $description = $class -> meta() -> smp_find_description_by_name( 'self_method' );

	is_deeply( $description -> connector_chain(), [
		[ 'Salvation::MacroProcessor::_t05_03::Class3', 'stub_connector' ],
		[ 'Salvation::MacroProcessor::_t05_03::Class3', 'self_connector' ]
	], 'connector chain of "self_method" is ok' );
}


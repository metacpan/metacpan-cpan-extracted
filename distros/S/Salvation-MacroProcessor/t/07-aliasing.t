use strict;

package Salvation::MacroProcessor::_t07::Role1;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_add_description 'method';

smp_add_alias m => 'method';

no Moose::Role;

package Salvation::MacroProcessor::_t07::Class1;

use Moose;

use Salvation::MacroProcessor;

with 'Salvation::MacroProcessor::_t07::Role1';

sub method;

no Moose;

package Salvation::MacroProcessor::_t07::Role2;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_add_connector 'Class1 connector' => (
	code => sub
	{
		return shift;
	}
);

smp_import_descriptions
	class => 'Salvation::MacroProcessor::_t07::Class1',
	prefix => 'i1_',
	connector => 'Class1 connector'
;

no Moose::Role;

package Salvation::MacroProcessor::_t07::Class2;

use Moose;

use Salvation::MacroProcessor;

with 'Salvation::MacroProcessor::_t07::Role2';

no Moose;

package Salvation::MacroProcessor::_t07::Role3;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_add_connector 'Class2 connector' => (
	code => sub
	{
		return shift;
	}
);

smp_import_descriptions
	class => 'Salvation::MacroProcessor::_t07::Class2',
	prefix => 'i2_',
	connector => 'Class2 connector'
;

smp_add_alias im => 'i2_i1_method';

no Moose::Role;

package Salvation::MacroProcessor::_t07::Class3;

use Moose;

use Salvation::MacroProcessor;

with 'Salvation::MacroProcessor::_t07::Role3';

no Moose;

package main;

use Test::More tests => 2;


subtest 'Salvation::MacroProcessor::_t07::Class1' => sub
{
	plan tests => 2;

	my $d = Salvation::MacroProcessor::_t07::Class1 -> meta() -> smp_find_description_by_name( 'method' );

	ok( defined( $d ), 'description is present' );

	is( $d, Salvation::MacroProcessor::_t07::Class1 -> meta() -> smp_find_description_by_name( 'm' ), 'alias is good' );
};

subtest 'Salvation::MacroProcessor::_t07::Class3' => sub
{
	plan tests => 3;

	my $d = Salvation::MacroProcessor::_t07::Class3 -> meta() -> smp_find_description_by_name( 'i2_i1_method' );

	ok( defined( $d ), 'description is present' );

	is( $d, Salvation::MacroProcessor::_t07::Class3 -> meta() -> smp_find_description_by_name( 'im' ), 'alias is good' );

	subtest 'imported alias' => sub
	{
		plan tests => 3;

		my $id = Salvation::MacroProcessor::_t07::Class3 -> meta() -> smp_find_description_by_name( 'i2_i1_m' );

		is( $id -> orig_method(), $d -> orig_method(), 'imported alias is a description for the same method as imported description' );
		is( $id -> associated_meta(), $d -> associated_meta(), 'imported alias has the same associated meta as imported description' );

		isnt( $id, $d, q|imported alias isn't the same object as imported description - should it really be like that?| );
	};
};



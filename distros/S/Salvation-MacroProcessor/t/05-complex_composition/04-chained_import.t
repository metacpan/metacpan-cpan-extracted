use strict;

package Salvation::MacroProcessor::_t05_04::Role1;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_add_description 'method';

no Moose::Role;

package Salvation::MacroProcessor::_t05_04::Class1;

use Moose;

use Salvation::MacroProcessor;

with 'Salvation::MacroProcessor::_t05_04::Role1';

sub method;

no Moose;

package Salvation::MacroProcessor::_t05_04::Role2;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_add_connector 'Class1 connector' => (
	code => sub
	{
		return shift;
	}
);

smp_import_descriptions
	class => 'Salvation::MacroProcessor::_t05_04::Class1',
	prefix => 'i1_',
	connector => 'Class1 connector'
;

no Moose::Role;

package Salvation::MacroProcessor::_t05_04::Class2;

use Moose;

use Salvation::MacroProcessor;

with 'Salvation::MacroProcessor::_t05_04::Role2';

no Moose;

package Salvation::MacroProcessor::_t05_04::Role3;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_add_connector 'Class2 connector' => (
	code => sub
	{
		return shift;
	}
);

smp_import_descriptions
	class => 'Salvation::MacroProcessor::_t05_04::Class2',
	prefix => 'i2_',
	connector => 'Class2 connector'
;

no Moose::Role;

package Salvation::MacroProcessor::_t05_04::Class3;

use Moose;

use Salvation::MacroProcessor;

with 'Salvation::MacroProcessor::_t05_04::Role3';

no Moose;

package main;

use Test::More;


my @classes = (
	'Salvation::MacroProcessor::_t05_04::Class3',
	'Salvation::MacroProcessor::_t05_04::Class2',
	'Salvation::MacroProcessor::_t05_04::Class1'
);

my @imported = ( 1, 1, 0 );
my @method   = ( 'i2_i1_method', 'i1_method', 'method' );

plan tests => scalar( @classes );

foreach my $class ( @classes )
{
	subtest $class => sub
	{
		plan tests => 4;

		my $d = $class -> meta() -> smp_find_description_by_name( shift( @method ) );

		ok( defined( $d ), 'description is present' ); return unless $d;

		is( $d -> associated_meta() -> name(), 'Salvation::MacroProcessor::_t05_04::Class1', 'associated_meta is Salvation::MacroProcessor::_t05_04::Class1' );

		ok( not( defined $d -> previously_associated_meta() ), 'description has no previously associated meta' );

		is( $d -> __imported(), shift( @imported ), '"__imported" flag is correct' );
	};
}



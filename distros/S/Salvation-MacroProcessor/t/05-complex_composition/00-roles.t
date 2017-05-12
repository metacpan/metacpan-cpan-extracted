use strict;

package Salvation::MacroProcessor::_t05_00::Role;

use Moose::Role;

use Salvation::MacroProcessor::ForRoles;

smp_add_share some_name => sub
{
	&Test::More::ok( 1, 'shared value getter is called' );

	return;
};

smp_add_description 'method';

no Moose::Role;

package Salvation::MacroProcessor::_t05_00::Class;

use Moose;

use Salvation::MacroProcessor;

with 'Salvation::MacroProcessor::_t05_00::Role';

sub method;

no Moose;

package main;

use Test::More tests => 2;

foreach my $class ( (
	'Salvation::MacroProcessor::_t05_00::Role',
	'Salvation::MacroProcessor::_t05_00::Class'
) )
{
	subtest $class => sub
	{
		plan tests => 4;

		{
			my $share = $class -> meta() -> smp_find_share_by_name( 'some_name' );

			isa_ok( $share, 'CODE', 'shared value getter' );

			$share -> ();
		}

		{
			my $description = $class -> meta() -> smp_find_description_by_name( 'method' );

			isa_ok( $description, 'Salvation::MacroProcessor::MethodDescription', 'description' );

			is( $description -> associated_meta(), $class -> meta(), 'metaclass of description is ok' );
		}
	};
}


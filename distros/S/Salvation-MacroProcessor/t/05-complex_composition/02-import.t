use strict;

package Salvation::MacroProcessor::_t05_02::Class1;

use Moose;

use Salvation::MacroProcessor;

sub method;

smp_add_share some_name => sub
{
	&Test::More::ok( 1, 'shared value getter is called' );

	return;
};

smp_add_description 'method';

no Moose;

package Salvation::MacroProcessor::_t05_02::Class2;

use Moose;

use Salvation::MacroProcessor;

smp_import_shares
	class => 'Salvation::MacroProcessor::_t05_02::Class1'
;

smp_add_connector 'stub_connector' => (
	code => sub
	{
		return shift;
	}
);

smp_import_descriptions
	class => 'Salvation::MacroProcessor::_t05_02::Class1',
	connector => 'stub_connector'
;

no Moose;

package main;

use Test::More tests => 2;

foreach my $spec ( (
	[ ( 'Salvation::MacroProcessor::_t05_02::Class1' )x2 ],
	[ ( map{ sprintf( 'Salvation::MacroProcessor::_t05_02::Class%d', $_ ) } ( 2, 1 ) ) ]
) )
{
	my ( $class, $class_for_meta ) = @$spec;

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

			is( $description -> associated_meta(), $class_for_meta -> meta(), 'metaclass of description is ok' );
		}
	};
}


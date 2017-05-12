use strict;

package Salvation::MacroProcessor::_t05_01::Class1;

use Moose;

use Salvation::MacroProcessor;

sub method;

smp_add_share some_name => sub
{
	&Test::More::ok( 1, 'shared value getter is called' );

	return;
};

smp_add_description 'method';

smp_add_connector some_connector => (
	code => sub
	{
		&Test::More::ok( 1, 'connector code is called' );

		return;
	}
);

no Moose;

package Salvation::MacroProcessor::_t05_01::Class2;

use Moose;

use Salvation::MacroProcessor;

extends 'Salvation::MacroProcessor::_t05_01::Class1';

no Moose;

package main;

use Test::More tests => 2;

{
	my $class = 'Salvation::MacroProcessor::_t05_01::Class1';

	subtest $class => sub
	{
		plan tests => 11;

		{
			my $share = $class -> meta() -> smp_find_share_by_name( 'some_name' );

			isa_ok( $share, 'CODE', 'shared value getter' );

			$share -> ();
		}

		{
			my $description = $class -> meta() -> smp_find_description_by_name( 'method' );

			isa_ok( $description, 'Salvation::MacroProcessor::MethodDescription', 'description' );

			is( $description -> associated_meta(), $class -> meta(), 'metaclass of description is ok' );
			ok( not( $description -> has_previously_associated_meta() ), 'description has no previous metaclass' );
			ok( not( defined $description -> inherited_description() ), 'description is not inherited' );
		}

		{
			my $connector = $class -> meta() -> smp_find_connector_by_name( 'some_connector' );

			isa_ok( $connector, 'Salvation::MacroProcessor::Connector', 'connector' );

			is( $connector -> associated_meta(), $class -> meta(), 'metaclass of connector is ok' );
			ok( not( $connector -> has_previously_associated_meta() ), 'connector has no previous metaclass' );
			ok( not( defined $connector -> inherited_connector() ), 'connector is not inherited' );

			$connector -> code() -> ();
		}
	};
}

{
	my $child_class    = 'Salvation::MacroProcessor::_t05_01::Class2';
	my $ancestor_class = 'Salvation::MacroProcessor::_t05_01::Class1';

	subtest $child_class => sub
	{
		plan tests => 13;

		{
			my $share = $child_class -> meta() -> smp_find_share_by_name( 'some_name' );

			isa_ok( $share, 'CODE', 'shared value getter' );

			$share -> ();
		}

		{
			my $description = $child_class -> meta() -> smp_find_description_by_name( 'method' );

			isa_ok( $description, 'Salvation::MacroProcessor::MethodDescription', 'description' );

			is( $description -> associated_meta(), $child_class -> meta(), 'metaclass of description is ok' );
			is( $description -> previously_associated_meta(), $ancestor_class -> meta(), 'description has proper previous metaclass' );

			my $ancestor_description = $ancestor_class -> meta() -> smp_find_description_by_name( 'method' );

			isa_ok( $ancestor_description, 'Salvation::MacroProcessor::MethodDescription', 'ancestor description' );

			is( $description -> inherited_description(), $ancestor_description, 'description is properly inherited' );
		}

		{
			my $connector = $child_class -> meta() -> smp_find_connector_by_name( 'some_connector' );

			isa_ok( $connector, 'Salvation::MacroProcessor::Connector', 'connector' );

			is( $connector -> associated_meta(), $child_class -> meta(), 'metaclass of connector is ok' );
			is( $connector -> previously_associated_meta(), $ancestor_class -> meta(), 'connector has proper previous metaclass' );

			my $ancestor_connector = $ancestor_class -> meta() -> smp_find_connector_by_name( 'some_connector' );

			isa_ok( $ancestor_connector, 'Salvation::MacroProcessor::Connector', 'ancestor connector' );

			is( $connector -> inherited_connector(), $ancestor_connector, 'connector is properly inherited' );

			$connector -> code() -> ();
		}
	};
}


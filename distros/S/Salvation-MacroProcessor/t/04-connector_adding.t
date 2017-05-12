use strict;

package Salvation::MacroProcessor::_t04::Class;

use Moose;

use Salvation::MacroProcessor;

smp_add_connector some_name => (
	code => sub
	{
		&Test::More::ok( 1, 'connector code called' );

		return;
	}
);

no Moose;

package main;

use Test::More tests => 5;

my $connector = Salvation::MacroProcessor::_t04::Class -> meta() -> smp_find_connector_by_name( 'some_name' );

isa_ok( $connector, 'Salvation::MacroProcessor::Connector', 'connector' );

is( $connector -> name(), 'some_name', 'connector name is ok' );
is( $connector -> associated_meta(), Salvation::MacroProcessor::_t04::Class -> meta(), 'connector associated metaclass is ok' );

my $code = $connector -> code();

isa_ok( $code, 'CODE', 'connector code' );

$code -> ();


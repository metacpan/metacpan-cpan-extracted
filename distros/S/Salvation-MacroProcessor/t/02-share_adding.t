use strict;

package Salvation::MacroProcessor::_t02::Class;

use Moose;

use Salvation::MacroProcessor;

sub method { 'stub' }

smp_add_share some_name => sub
{
	&Test::More::ok( 1, 'gonna return some shared value' );

	return ( 1, [ 2, { 3 => 4 } ], 'five' );
};

smp_add_description 'method' => (
	required_shares => [ 'some_name' ],
	query => sub
	{
		my ( $shares, $value ) = @_;

		&Test::More::isa_ok( $shares, 'HASH', q|shares' storage| );

		&Test::More::is_deeply( $shares -> { 'some_name' }, [ 1, [ 2, { 3 => 4 } ], 'five' ], 'shared value is here' );

		return [
			something => $value
		];
	}
);

no Moose;

package main;

use Test::More tests => 5;

my $share = Salvation::MacroProcessor::_t02::Class -> meta() -> smp_find_share_by_name( 'some_name' );

isa_ok( $share, 'CODE', 'shared value getter' );

my $shared_value = [ $share -> () ];

my $description = Salvation::MacroProcessor::_t02::Class -> meta() -> smp_find_description_by_name( 'method' );

is_deeply( $description -> query( { some_name => $shared_value }, 'value' ), [ something => 'value' ] );


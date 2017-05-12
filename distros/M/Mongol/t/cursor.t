#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Moose;

use MongoDB;

use Mongol::Test qw( check_mongod );

my $mongo = check_mongod();

require_ok( 'Mongol::Models::Person' );
isa_ok( 'Mongol::Models::Person', 'Mongol::Model' );

does_ok( 'Mongol::Models::Person', 'Mongol::Roles::Core' );
has_attribute_ok( 'Mongol::Models::Person', 'id' );
has_attribute_ok( 'Mongol::Models::Person', 'first_name' );
has_attribute_ok( 'Mongol::Models::Person', 'last_name' );
has_attribute_ok( 'Mongol::Models::Person', 'age' );

can_ok( 'Mongol::Models::Person', qw( save drop find ) );

require_ok( 'Mongol' );
can_ok( 'Mongol', qw( map_entities ) );

Mongol->map_entities( $mongo,
	'Mongol::Models::Person' => 'test.people',
);

Mongol::Models::Person->drop();

foreach my $index ( 1 .. 50 ) {
	my $item = Mongol::Models::Person->new(
		{
			id => $index,
			first_name => 'Tony',
			last_name => 'Stark',
			age => $index % 5,
		}
	);

	$item->save();
}

my $cursor = Mongol::Models::Person->find( { age => 0 } );
isa_ok( $cursor, 'Mongol::Cursor' );
can_ok( $cursor, qw( all has_next next ) );

my $index = 1;
while( my $person = $cursor->next() ) {
	isa_ok( $person, 'Mongol::Models::Person' );

	my $value = $index++ * 5;
	is( $person->id(), $value, sprintf( 'Match on value: %d', $value ) );
}

my @people = Mongol::Models::Person->find( { age => 1 } )
	->all();
is( scalar( @people ), 10, 'Counts match' );

Mongol::Models::Person->drop();

done_testing();

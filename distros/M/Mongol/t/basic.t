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

# NOTE: "class_has" does not register an normal attribute.
# This is why I need to check it this way ...
can_ok( 'Mongol::Models::Person', qw(
		collection
		find find_one count retrieve exists
		save delete
		drop
	)
);

require_ok( 'Mongol' );
can_ok( 'Mongol', qw( map_entities ) );

Mongol->map_entities( $mongo,
	'Mongol::Models::Person' => 'test.people',
);

# We start with a clean collection
Mongol::Models::Person->drop();

my $person = Mongol::Models::Person->new(
	{
		first_name => 'Bruce',
		last_name => 'Banner',
		age => 36,
	}
);
isa_ok( $person, 'Mongol::Models::Person' );
has_attribute_ok( $person, 'id' );
has_attribute_ok( $person, 'first_name' );
has_attribute_ok( $person, 'last_name' );
has_attribute_ok( $person, 'age' );

$person->save();
isa_ok( $person->id(), 'MongoDB::OID' );

$person->age( 37 );
$person->save();

# Two save calls in a row but only one record ...
is( Mongol::Models::Person->count(), 1, 'Count should be 1' );

my $clone = Mongol::Models::Person->retrieve( $person->id() );
is_deeply( $clone, $person, 'Objects match' );

$person->remove();
is( Mongol::Models::Person->count(), 0, 'Count should be 0' );

Mongol::Models::Person->drop();

done_testing();

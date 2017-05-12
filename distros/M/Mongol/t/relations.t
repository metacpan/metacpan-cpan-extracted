#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Moose;

use MongoDB;

use Mongol;
use Mongol::Test qw( check_mongod );

my $mongo = check_mongod();

Mongol->map_entities( $mongo,
	'Mongol::Models::Parent' => 'test.parents',
	'Mongol::Models::Child' => 'test.children',
);

require_ok( 'Mongol::Models::Parent' );
require_ok( 'Mongol::Models::Child' );

Mongol::Models::Parent->drop();
Mongol::Models::Child->drop();

my $parent = Mongol::Models::Parent->new( { name => 'Parent' } );

isa_ok( $parent, 'Mongol::Model' );
does_ok( $parent, 'Mongol::Roles::Core' );
does_ok( $parent, 'Mongol::Roles::Relations' );

can_ok( $parent, qw( save add_child get_children get_child remove_children ) );
$parent->save();

$parent->add_child(
	{
		id => $_,
		name => sprintf( 'Child %d', $_ ),
	}
) foreach ( 1 .. 10 );

my @children = $parent->get_children()
	->all();

is( scalar( @children ), 10, 'Count ok' );
is_deeply(
	[ map { $_->id() } @children ],
	[ 1 .. 10 ],
	'Ids match!'
);

my $first = $parent->get_child( 1 );
isa_ok( $first, 'Mongol::Models::Child' );
can_ok( $first, qw( get_parent ) );
is( $first->id(), 1, 'First record found' );

is_deeply( $first->get_parent(), $parent, 'Parent ok' );

$parent->remove_children();
@children = $parent->get_children()
	->all();

is_deeply( \@children, [], 'Removed children' );

done_testing();

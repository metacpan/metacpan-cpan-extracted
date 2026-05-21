use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok "TUI::Objects::Collection";
}

# Test TCollection function
is( TCollection, 'TUI::Objects::Collection', 
  'TCollection returns correct package name' );

# Test new method
my $collection = TCollection->new( limit => 10, delta => 5 );
isa_ok( $collection, TCollection,
  'new() creates an object of correct class' );

# Test at method
my $item1 = \'item1';
$collection->atInsert( 0, $item1 );
is( $collection->at( 0 ), $item1, 'at() returns the correct item' );

# Test atRemove method
$collection->atInsert( 1, 'item2' );
$collection->atRemove( 0 );
is( $collection->at( 0 ), 'item2', 'atRemove() removes the correct item' );

# Test atFree method
$collection->atInsert( 0, 'item3' );
$collection->atFree( 0 );
is( $collection->{count}, 1, 'atFree() frees the correct item' );

# Test atInsert method
$collection->atInsert( 0, 'item4' );
is( $collection->at( 0 ), 'item4', 'atInsert() inserts the correct item' );

# Test atPut method
$collection->atPut( 0, 'item5' );
is( $collection->at( 0 ), 'item5', 'atPut() puts the correct item' );

# Test remove method
$collection->remove( 'item5' );
is( $collection->{count}, 1, 'remove() removes the correct item' );

# Test removeAll method
$collection->removeAll();
is( $collection->{count}, 0, 'removeAll() removes all items' );

# Test free method
$collection->atInsert( 0, 'item6' );
$collection->free( 'item6' );
is( $collection->{count}, 0, 'free() frees the correct item' );

# Test freeAll method
$collection->atInsert( 0, 'item7' );
$collection->atInsert( 1, 'item8' );
$collection->freeAll();
is( $collection->{count}, 0, 'freeAll() frees all items' );

# Test indexOf method
$collection->atInsert( 0, 'item9' );
is( $collection->indexOf( 'item9' ), 0, 'indexOf() returns the correct index' );

# Test insert method
$collection->insert( 'item10' );
is( $collection->at( 1 ), 'item10', 'insert() inserts the correct item' );

# Test firstThat method
my $first = $collection->firstThat( sub { $_ eq 'item9' }, undef );
is( $first, 'item9', 'firstThat() returns the correct item' );

# Test lastThat method
my $last = $collection->lastThat( sub { $_ eq 'item10' }, undef );
is( $last, 'item10', 'lastThat() returns the correct item' );

# Test forEach method
my @results;
$collection->forEach( sub { push @results, $_ }, undef );
is_deeply( \@results, [ 'item9', 'item10' ],
  'forEach() applies the action to all items' );

# Test pack method
$collection->atInsert( 2, undef );
$collection->pack();
is( $collection->{count}, 2, 'pack() removes undefined items' );

# Test setLimit method
$collection->setLimit( 5 );
is( $collection->{limit}, 5, 'setLimit() sets the correct limit' );

# Test error method
throws_ok { $collection->error( 1, 0 ) } qr/Error code: \d+, Info: 0/,
  'error() throws the correct error';

# Test shutDown method
$collection->shutDown();
is( $collection->{count}, 0, 'shutDown() shuts down the collection' );

done_testing();

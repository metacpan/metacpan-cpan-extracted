use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok "TUI::Objects::SortedCollection";
}

# Mock subclass to implement compare method
{
  package MySortedCollection;
  use TUI::toolkit;
  extends 'TUI::Objects::SortedCollection';

  sub compare {
    no warnings 'uninitialized';
    my ( $self, $key1, $key2 ) = @_;
    return "$key1" cmp "$key2";
  }
  $INC{"MySortedCollection.pm"} = 1;
}

use_ok 'MySortedCollection';

# Test new method
my $sorted_collection = MySortedCollection->new( limit => 10, delta => 5 );
isa_ok( 
  $sorted_collection, 'MySortedCollection',
  'new() creates an object of correct class' 
);

# Test insert method
$sorted_collection->insert( 'item1' );
$sorted_collection->insert( 'item3' );
$sorted_collection->insert( 'item2' );
is( $sorted_collection->at( 0 ), 'item1', 'insert() inserts item1 correctly' );
is( $sorted_collection->at( 1 ), 'item2', 'insert() inserts item2 correctly' );
is( $sorted_collection->at( 2 ), 'item3', 'insert() inserts item3 correctly' );

# Test indexOf method
is(
  $sorted_collection->indexOf( 'item2' ), 1,
  'indexOf() returns the correct index for item2'
);
is(
  $sorted_collection->indexOf( 'item4' ), -1,
  'indexOf() returns -1 for non-existent item'
);

# Test search method
my $index;
ok(
  $sorted_collection->search( 'item2', \$index ), 
  'search() finds item2'
);
is( 
  $index, 1, 
  'search() returns the correct index for item2'
);
ok( 
  !$sorted_collection->search( 'item4', \$index ),
  'search() does not find non-existent item'
);
my $next = $sorted_collection->{count};
is( 
  $index, $next,
  'search() returns the correct insertion index for non-existent item' 
);

# Test keyOf method
is( 
  $sorted_collection->keyOf( 'item1' ), 'item1',
  'keyOf() returns the correct key'
);

# Test duplicates
$sorted_collection->{duplicates} = 1;
$sorted_collection->insert( 'item2' );
is(
  $sorted_collection->at( 2 ), 'item2',
  'insert() allows duplicates when duplicates is true'
);

done_testing();

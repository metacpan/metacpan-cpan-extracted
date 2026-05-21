use strict;
use warnings;

use Test::More;
use Test::Exception;

BEGIN {
  use_ok 'TUI::StdDlg::DirEntry';
  use_ok 'TUI::StdDlg::DirCollection';
}

my $collection;

lives_ok {
  $collection = TUI::StdDlg::DirCollection->new;
} 'TDirCollection->new() lives';

isa_ok(
  $collection,
  TDirCollection(),
  'Collection object has correct class'
);

my $e1 = new_TDirEntry( 'Root', '/' );
my $e2 = new_TDirEntry( 'Home', '/home' );

lives_ok {
  $collection->insert( $e1 );
  $collection->insert( $e2 );
} 'Entries inserted into collection';

is(
  $collection->at( 0 ),
  $e1,
  'at(0) returns first entry'
);

is(
  $collection->at( 1 ),
  $e2,
  'at(1) returns second entry'
);

is(
  $collection->indexOf( $e2 ),
  1,
  'indexOf() returns correct index'
);

lives_ok {
  $collection->remove( $e1 );
} 'remove() lives';

dies_ok {
  $collection->indexOf( $e1 ),
} 'Removed entry is no longer in collection';

done_testing

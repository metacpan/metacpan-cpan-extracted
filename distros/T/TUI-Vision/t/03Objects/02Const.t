use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Objects::Const', qw(
    ccNotFound 
    maxCollectionSize
  );
}

is( ccNotFound, -1, 'ccNotFound is -1' );
is(
  maxCollectionSize,
  int( ( ~0 - 16 ) / length( pack( 'P', 0 ) ) ),
  'maxCollectionSize is calculated correctly' 
);

done_testing();

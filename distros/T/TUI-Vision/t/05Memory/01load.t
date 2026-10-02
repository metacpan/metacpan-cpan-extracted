use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Memory', qw( $maxHeapSize );
}

ok( defined $maxHeapSize, '$maxHeapSize is defined' );

done_testing();

use 5.010;
use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok 'TUI::Help::HelpIndex';
}

subtest 'add and position' => sub {
  my $index = THelpIndex->new();

  is( $index->position(0), -1, 'empty index has no recorded position' );

  $index->add( 2, 200 );
  is( $index->position(2), 200, 'position for context 2' );
  is( $index->position(1), -1, 'unused context has no position' );

  $index->add( 2, 250 );
  is( $index->position(2), 250, 'existing position is replaced' );
};

subtest 'grow index' => sub {
  my $index = THelpIndex->new();

  $index->add( 9, 900 );
  is( $index->size, 10, 'context 9 fits in the first ten slots' );

  $index->add( 10, 910 );
  is( $index->size, 20, 'capacity boundary allocates another ten slots' );
  is( $index->position(9), 900, 'growth preserves earlier positions' );
  is( $index->position(10), 910, 'records the new position' );
  is( $index->position(19), -1, 'trailing allocated slot contains -1' );
  is( $index->position(20), -1, 'context beyond index has no position' );
};

done_testing;

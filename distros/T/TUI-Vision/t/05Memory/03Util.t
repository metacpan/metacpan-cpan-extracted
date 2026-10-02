use strict;
use warnings;

use Test::More;
use Scalar::Util qw( weaken );

BEGIN {
  use_ok 'TUI::Memory', qw(
    $maxHeapSize

    initMemory
    doneMemory
    lowMemory
    memAlloc
    newCache
    disposeCache
    getBufferSize
    setBufferSize
  );
}

subtest 'initial state' => sub {
  initMemory();
  is( lowMemory(), !!0, 'lowMemory' );
  doneMemory();
};

subtest 'buffer allocation' => sub {
  my $p = memAlloc( 10 );
  isa_ok $p, 'HASH';
  is( getBufferSize( $p ), 10, 'bufferSize' );
  ok( setBufferSize( $p, 20 ), 'resize' );
  is( getBufferSize( $p ), 20, 'resized' );
};

subtest 'cache released at end of scope' => sub {
  my $weak;
  {
    my $p = memAlloc( 10 );
    $weak = $p;
    weaken( $weak );
  }
  ok( !defined $weak, 'cache released' );
};

subtest 'cache reclaim' => sub {
  $maxHeapSize = 100;
  my $p;
  newCache( $p, 20 );
  $p->{$_} = $_
    for 1 .. 150;
  is( scalar keys %$p, 150, 'initial cache size' );
  is( lowMemory(), !!0, 'no reclaimable cache left' );
  is( scalar keys %$p, 20, 'trimmed to minimum' );
};

subtest 'cache already below minimum' => sub {
  $maxHeapSize = 100;
  my $p;
  newCache( $p, 20 );
  $p->{$_} = $_
    for 1 .. 5;
  is( lowMemory(), !!0, 'not low memory' );
  is( scalar keys %$p, 5, 'cache unchanged' );
};

subtest '$maxBufMem limit' => sub {
  $maxHeapSize = 100;
  my $p;
  newCache( $p, 20 );
  ok( setBufferSize( $p, $maxHeapSize ), 'largest valid buffer size' );
  is( getBufferSize( $p ), $maxHeapSize, 'size updated' );
  ok( !setBufferSize( $p, $maxHeapSize + 1 ), 'size above limit rejected' );
};

subtest 'overall backend test' => sub {
  $maxHeapSize = 100;
  my $p;
  newCache( $p, 20 );
  $p->{$_} = $_
    for 1 .. 150;
  is( scalar keys %$p, 150, 'initial cache size' );
  lowMemory();
  is( scalar keys %$p, 20, 'trimmed to minimum' );
  disposeCache( $p );
  is( $p, undef, 'cache disposed' );
};

done_testing();

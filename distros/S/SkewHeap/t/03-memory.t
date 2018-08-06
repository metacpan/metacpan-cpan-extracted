use ExtUtils::testlib;
use Test2::V0;
use Test::LeakTrace qw(no_leaks_ok);
use List::Util qw(shuffle);
use SkewHeap;

my @values = 1 .. 3;
my @shuffled = shuffle @values;

no_leaks_ok { my $heap = skewheap{ $a <=> $b } } 'ctor';

no_leaks_ok {
  my $heap = skewheap{ $a <=> $b };
  $heap->put(@shuffled);
} 'put';

no_leaks_ok {
  my $heap = skewheap{ $a <=> $b };
  $heap->put(@shuffled);

  while ($heap->size > 0) {
    my $value = $heap->take;
  }
} 'take';

no_leaks_ok {
  my $heap = skewheap{ $a <=> $b };
  $heap->put(42);
  my $v = $heap->top;
} 'top';

no_leaks_ok {
  my $heap = skewheap{ $a <=> $b };
  $heap->put(42);
  my $i = $heap->size;
} 'size';

no_leaks_ok {
  my $heap_a = skewheap{ $a <=> $b };
  my $heap_b = skewheap{ $a <=> $b };
  $heap_a->put(1..5);
  $heap_b->put(6..10);
  my $heap_c = $heap_a->merge($heap_b);
} 'merge';

no_leaks_ok {
  my $heap = skewheap{ $a <=> $b };
  $heap->put(@shuffled);

  foreach (@shuffled) {
    my $item = $heap->take;
    my $top  = $heap->top;
    my $size = $heap->size;
  }
} 'combined';

done_testing;

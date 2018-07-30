use ExtUtils::testlib;
use Test2::V0;
use Test::LeakTrace qw(no_leaks_ok);
use List::Util qw(shuffle);
use SkewHeap;

my $cmp = sub{ $a <=> $b };
my @values = 0 .. 20;
my @shuffled = shuffle @values;

no_leaks_ok { my $heap = SkewHeap->new($cmp) } 'ctor';

no_leaks_ok {
  my $heap = SkewHeap->new($cmp);
  $heap->put(@shuffled);
} 'put';

no_leaks_ok {
  my $heap = SkewHeap->new($cmp);
  $heap->put(@shuffled);
  local $_ = $heap->take while $heap->size > 0;
} 'take';

no_leaks_ok {
  my $heap = SkewHeap->new($cmp);
  $heap->put(42);
  my $v = $heap->top;
} 'top';

no_leaks_ok {
  my $heap = SkewHeap->new($cmp);
  $heap->put(42);
  my $i = $heap->size;
} 'size';

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

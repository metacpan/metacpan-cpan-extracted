use ExtUtils::testlib;
use Test2::V0;
use List::Util qw(shuffle);
use SkewHeap;

my $cmp = sub{ $a <=> $b };
my @values = 0 .. 20;
my @shuffled = shuffle @values;

ok(SkewHeap->new($cmp), 'ctor');
ok(SkewHeap->new(sub{ $a <=> $b }), 'ctor w/ anon sub');

ok my $heap = skewheap{ $a <=> $b }, 'sugar ctor';

is $heap->put(@shuffled), scalar(@shuffled), "put";

foreach my $v (@values) {
  is my $got = $heap->take, $v, "take $v";

  if ($heap->size == 0) {
    is $heap->top, U, 'top';
  } else {
    ok $got < $heap->top, 'top';
  }
}

foreach my $v (@values) {
  $heap->put($v);
}

foreach my $v (@values) {
  is my $got = $heap->take, $v, "take $v";

  if ($heap->size == 0) {
    is $heap->top, U, 'top';
  } else {
    ok $got < $heap->top, 'top';
  }
}

done_testing;

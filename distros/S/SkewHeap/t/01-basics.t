use ExtUtils::testlib;
use Test2::V0;
use List::Util qw(shuffle);
use SkewHeap;

my $cmp = sub{ $a <=> $b };
my @values = 1 .. 20;
my @shuffled = shuffle @values;

ok(SkewHeap->new($cmp), 'ctor w/ sub ref');
ok(SkewHeap->new(sub{ $a <=> $b }), 'ctor w/ anon sub');

ok my $heap = skewheap{ $a <=> $b }, 'sugar ctor';

is $heap->put(@shuffled), scalar(@shuffled), "put";

=cut
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

subtest 'to_array' => sub{
  $heap->put(@shuffled);
  is $heap->size, scalar(@shuffled), 'number of items in heap';

  my $items = $heap->to_array;

  is scalar( @$items ), scalar(@shuffled), 'number of items in list';
  is $heap->size, scalar(@shuffled), 'number of items in heap';

  undef $items;
  subtest 'gc list leaves heap intact' => sub{
    is $heap->size, scalar( @shuffled ), 'size';

    foreach my $v (@values) {
      is my $got = $heap->take, $v, "take $v";

      if ($heap->size == 0) {
        is $heap->top, U, 'top';
      } else {
        ok $got < $heap->top, 'top';
      }
    }
  };
};
=cut

done_testing;

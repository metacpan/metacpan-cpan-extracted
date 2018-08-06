use ExtUtils::testlib;
use Test2::V0;
use List::Util qw(shuffle);
use SkewHeap;

my $count = 10;

my $h1 = skewheap{ $a <=> $b };
my $h2 = skewheap{ $a <=> $b };

foreach (1 .. $count) {
  if ($_ % 2 == 0) {
    $h1->put($_);
  } else {
    $h2->put($_);
  }
}

ok my $h3 = $h1->merge($h2), 'merge';

is $h3->size, $count, 'size';

foreach my $i (1 .. $count) {
  my $v = $h3->take;
  is $v, $i, "take $i";
}

is $h1->size, 5, 'merged heap retains size';
is $h2->size, 5, 'merged heap retains size';

done_testing;

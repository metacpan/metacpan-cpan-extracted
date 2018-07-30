use ExtUtils::testlib;
use Test2::V0;
use List::Util qw(shuffle);
use SkewHeap;

my $cmp = sub{ $a <=> $b };
my @values = 0 .. 20;
my @shuffled = shuffle @values;

my $h1 = SkewHeap->new($cmp);
my $h2 = SkewHeap->new($cmp);

foreach (1 .. 10) {
  if ($_ % 2 == 0) {
    $h1->put($_);
  } else {
    $h2->put($_);
  }
}

is $h1->merge($h2), 10, 'merge';
is $h1->size, 10, 'size';

foreach my $i (1 .. 10) {
  is $h1->take, $i, "take $i";
}

is $h2->size, 0, 'merged heap is empty';

done_testing;

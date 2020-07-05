use strict;
use warnings;

use Benchmark qw(:all);
use List::Util qw(shuffle);
use POSIX qw(floor);
use SkewHeap::PP;
use SkewHeap;

for my $size (50000, 100000, 500000) {
  my $count = floor(100000000000 / $size);
  my $item  = floor($size / 2);
  my @items = shuffle(0..$size);

  my $pp = skew(sub{ $_[0] <=> $_[1] });
  skew_put($pp, @items);

  my $oo = SkewHeap::PP->new(sub{ $_[0] <=> $_[1] });
  $oo->put(@items);

  my $xs = skewheap(sub{ $a <=> $b });
  $xs->put(@items);

  print "\n";
  print "------------------------------------------------------------------------------\n";
  print "- put($item) and take() 1 item with heap containing $size nodes ($count x times)\n";
  print "------------------------------------------------------------------------------\n";

  cmpthese($count, {
    'xs' => sub{ $xs->put($item); my $t = $xs->take(); },
    'pp' => sub{ skew_put($pp, $item); my $t = skew_take($pp); },
    'oo' => sub{ $oo->put($item); my $t = $oo->take(); },
  });
}

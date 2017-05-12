
use Test::More tests => 9;
BEGIN { use_ok('Set::IntervalTree') };

use strict;
use warnings;

my $tree = Set::IntervalTree->new;
$tree->insert("A",1,2);
$tree->insert("B",2,3);
$tree->insert("C",6,10);
$tree->insert("D",4,12);

is($tree->fetch_nearest_up(2), "D");
is($tree->fetch_nearest_up(5), "C");
is($tree->fetch_nearest_up(1), "B");
is($tree->fetch_nearest_up(7), undef);
is($tree->fetch_nearest_down(7), "B");
is($tree->fetch_nearest_down(3), "B");
is($tree->fetch_nearest_down(11), "C");
is($tree->fetch_nearest_down(1), undef);

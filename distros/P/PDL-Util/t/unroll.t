use strict;
use warnings;

use PDL;
use Test::More tests => 2;

use_ok('PDL::Util', 'unroll');

my $array = [
 [[1,2],
  [3,4]],
 [[5,6],
  [7,8]],
 [[9,10],
  [11,12]]
];
my $pdl = pdl $array;

is_deeply( unroll($pdl), $array, "back convert 3d");


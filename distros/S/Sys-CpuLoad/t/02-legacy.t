use Test::More;
use Test::Deep;
use Test::Warnings;

use Scalar::Util 'looks_like_number';

use Sys::CpuLoad ();

my @load = Sys::CpuLoad::load();

cmp_deeply
  \@load,
  [ (code(\&looks_like_number)) x 3 ], 'load';

diag "@load";

done_testing;

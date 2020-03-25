use Test::Most;

use Sys::CpuLoad ();

my @load = Sys::CpuLoad::load();

cmp_deeply
  \@load,
  [ (re(qr/^\d(\.\d+)?(e[\-\+]\d+)?$/)) x 3 ], 'load';

diag "@load";

done_testing;

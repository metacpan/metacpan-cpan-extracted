use Test::Most;

use_ok 'Sys::CpuLoad', 'load';

my @load = load();

cmp_deeply
  \@load,
  [ (re(qr/^\d(\.\d+)?(e[\-\+]\d+)?$/)) x 3 ], 'load';

diag "@load";

done_testing;

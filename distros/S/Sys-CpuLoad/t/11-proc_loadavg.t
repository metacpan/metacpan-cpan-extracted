use Test::More;
use Test::Deep;
use Test::Warnings;

use Scalar::Util 'looks_like_number';

plan skip_all => "no /proc/loadavg"
   unless -r "/proc/loadavg";

use_ok 'Sys::CpuLoad', 'proc_loadavg', 'load';

my @load = proc_loadavg();

cmp_deeply
  \@load,
  [ (code(\&looks_like_number)) x 3 ], 'load';

diag "@load";

no warnings 'once';

$Sys::CpuLoad::LOAD = 'proc_loadavg';

@load = load();

cmp_deeply
  \@load,
  [ (code(\&looks_like_number)) x 3 ], 'load';

diag "@load";

done_testing;

use Test::More;
use Test::Deep;
use Test::Warnings;

use File::Which qw/ which /;
use Scalar::Util 'looks_like_number';

my $path = which("w");

plan skip_all => "no w found"
    unless $path && -x $path;

use_ok 'Sys::CpuLoad', 'uptime';

no warnings 'once';

$Sys::CpuLoad::UPTIME = $path;

my @load = uptime();

cmp_deeply
  \@load,
  [ (code(\&looks_like_number)) x 3 ], 'load';

diag "@load";

done_testing;

use Test::More;
use Test::Deep;
use Test::Warnings;

use Scalar::Util 'looks_like_number';

my $os = lc $^O;

plan skip_all => $os
    if $os !~ /^(darwin|dragonfly|(free|net|open)bsd|linux|solaris|sunos)$/;

use_ok 'Sys::CpuLoad', qw( getloadavg load );

my @load = getloadavg();

cmp_deeply
  \@load,
  [ (code(\&looks_like_number)) x 3 ], 'load';

diag "@load";

no warnings 'once';

$Sys::CpuLoad::LOAD = 'getloadavg';

@load = load();

cmp_deeply
  \@load,
  [ (code(\&looks_like_number)) x 3 ], 'load';

diag "@load";

done_testing;

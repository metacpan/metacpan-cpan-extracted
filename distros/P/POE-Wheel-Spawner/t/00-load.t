use 5.006;
use strict;
use warnings FATAL   => 'all';
use Test::More tests => 2;

my $n = "POE::Wheel::Spawner";
use_ok($n);

my $v  = version->declare("0.03.2");
my $_v = eval '$' . $n . '::VERSION';
is($_v, $v, "$n version is $v");

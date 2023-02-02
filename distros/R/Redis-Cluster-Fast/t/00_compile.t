use strict;
use warnings FATAL => 'all';
use Test::More 0.98;

use_ok $_ for qw(
    Redis::Cluster::Fast
);

done_testing;


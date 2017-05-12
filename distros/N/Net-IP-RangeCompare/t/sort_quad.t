

use strict;
use warnings;
use lib qw(../lib lib);
use Test::More tests =>2;
use Net::IP::RangeCompare qw(:HELPER);

my ($first,$last)=sort sort_quad qw(10.0.0.1 10.0.0.10);
ok($first eq '10.0.0.1');
ok($last eq '10.0.0.10');

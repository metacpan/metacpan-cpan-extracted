

use strict;
use warnings;
use lib qw(../lib lib);
use Test::More tests =>1;
use Net::IP::RangeCompare qw(:HELPER);

my @sorted=sort sort_notations qw(10/24 10/22 9/8 8-11);
my $cmp=join ', ',@sorted;
ok($cmp eq '8-11, 9/8, 10/24, 10/22');

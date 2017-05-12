use strict;
use warnings;

use Test::More tests => 6;

use Sweet::Now;

my $now = Sweet::Now->new;

ok $now->dd =~ m/\d\d/;
ok $now->mm =~ m/\d\d/;
ok $now->yyyy =~ m/\d\d\d\d/;
ok $now->yyyymmdd =~ m/\d\d\d\d\d\d/;
ok $now->yyyymmddhhmiss =~ m/\d\d\d\d\d\d\d\d\d\d\d\d/;
ok $now->hhmiss =~ m/\d\d\d\d\d\d/;


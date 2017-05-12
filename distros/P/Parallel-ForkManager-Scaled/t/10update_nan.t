#!/usr/bin/env perl
use strict;
use warnings;
use lib 't';
use PMSTestHelper;

use Test::More;

use Parallel::ForkManager::Scaled;

plan tests => 3;

my $pm = Parallel::ForkManager::Scaled->new;
ok(defined $pm, 'constructor');

#
# Sleep to make sure we have enough time to get a result
# from $pm->update_stats_pct (get_cpu_percents() in libstatgrab)
#
sleep 1;
$pm->update_stats_pct;
ok($pm->idle ne 'NaN', 'NaN #1');

#
# Now don't sleep so that libstatgrab will return a NaN for idle
# which $pm->update_stats_pct should be checking for and handling
# such that we don't get a NaN (it won't update the stats)
#
$pm->update_stats_pct;
ok($pm->idle ne 'NaN', 'NaN #2');

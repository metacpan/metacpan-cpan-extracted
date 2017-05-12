# -*- mode: perl -*-
#
# $Id: 25scheck.t,v 1.1 1999/12/18 03:29:50 tai Exp $
#

use Test;

BEGIN { plan tests => 3 }

use Time::Local;
use Schedule::Match qw(scheck rcheck uthash isleap expand localtime);

@time = localtime;

$this_schedule = {
    t_mh => '0',
    t_hd => '0',
    t_dm => '1',
    t_my => '*',
    t_yt => $time[5] + 1900 + 1, # next year
    t_dw => '*',
    t_wm => '*',
    t_om => '*',
};

## today's date and time, but every year
$that_schedule = {
    t_mh => '0',
    t_hd => '0',
    t_dm => '1',
    t_my => '*/1',
    t_yt => $time[5] + 1900 + 1, # next year
    t_dw => '*',
    t_wm => '*',
    t_om => '*',
};

## get first 3 crashes (should be Jan/Mar/May 1st, 00:00 of next year)
@when = scheck($this_schedule, $that_schedule, 1, 3);

## check and see if they happen on expected date and time
ok($when[0], timelocal(0, 0, 0, 1, 0, $time[5] + 1));
ok($when[1], timelocal(0, 0, 0, 1, 2, $time[5] + 1));
ok($when[2], timelocal(0, 0, 0, 1, 4, $time[5] + 1));

exit(0);

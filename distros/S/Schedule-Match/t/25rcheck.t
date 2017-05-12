# -*- mode: perl -*-
#
# $Id: 25rcheck.t,v 1.1 1999/12/18 03:29:50 tai Exp $
#

use Test;

BEGIN { plan tests => 3 }

use Time::Local;
use Schedule::Match qw(scheck rcheck uthash isleap expand localtime);

@time = localtime;

$this_schedule = {
    life => 3600,
    t_mh => '0',
    t_hd => '0',
    t_dm => '2',
    t_my => '0-2',
    t_yt => $time[5] + 1 + 1900, # next year
    t_dw => '*',
    t_wm => '*',
    t_om => '*',
};

$that_schedule = {
    life => 3600 * 25,
    t_mh => '0',
    t_hd => '0',
    t_dm => '1',
    t_my => '0-2',
    t_yt => $time[5] + 1 + 1900, # next year
    t_dw => '*',
    t_wm => '*',
    t_om => '*',
};

@when = rcheck($this_schedule, $that_schedule, 1, 3);

ok($when[0], timelocal(0, 0, 0, 2, 0, $time[5] + 1));
ok($when[1], timelocal(0, 0, 0, 2, 1, $time[5] + 1));
ok($when[2], timelocal(0, 0, 0, 2, 2, $time[5] + 1));

exit(0);

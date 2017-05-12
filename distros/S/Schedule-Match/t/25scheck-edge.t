# -*- mode: perl -*-
#
# $Id: 25scheck-edge.t,v 1.1 1999/12/18 03:29:50 tai Exp $
#

use Test;

BEGIN { plan tests => 1 }

use Time::Local;
use Schedule::Match qw(scheck rcheck uthash isleap expand localtime);

@time = localtime;

$this_schedule = {
    life => 3600,
    t_mh => $time[1],
    t_hd => $time[2],
    t_dm => $time[3],
    t_my => $time[4],
    t_yt => $time[5] + 1 + 1900,
    t_dw => '*',
    t_wm => '*',
    t_om => '*',
};

$when = scheck($this_schedule, $this_schedule, 1, 1);

ok($when, timelocal(0, $time[1], $time[2], $time[3], $time[4], $time[5] + 1));

exit(0);

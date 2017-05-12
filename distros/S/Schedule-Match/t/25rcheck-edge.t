# -*- mode: perl -*-
#
# $Id: 25rcheck-edge.t,v 1.1 1999/12/18 03:29:50 tai Exp $
#

use Test;

BEGIN { plan tests => 3 }

use Time::Local;
use Schedule::Match qw(scheck rcheck uthash isleap expand localtime);

@time = localtime;

$base_schedule = {
    life => 3600,
    t_mh => '0',
    t_hd => '1',
    t_dm => '1',
    t_my => '0',
    t_yt => $time[5] + 1 + 1900,
    t_dw => '*',
    t_wm => '*',
    t_om => '*',
};

$back_schedule = { %{$base_schedule} };
$back_schedule->{t_hd} = '0';

$fore_schedule = { %{$base_schedule} };
$fore_schedule->{t_hd} = '2';

$when[0] = rcheck($base_schedule, $back_schedule, 1, 1);
$when[1] = rcheck($base_schedule, $base_schedule, 1, 1);
$when[2] = rcheck($base_schedule, $fore_schedule, 1, 1);

ok($when[0], timelocal(0, 0, 1, 1, 0, $time[5] + 1));
ok($when[1], timelocal(0, 0, 1, 1, 0, $time[5] + 1));
ok($when[2], timelocal(0, 0, 2, 1, 0, $time[5] + 1));

exit(0);

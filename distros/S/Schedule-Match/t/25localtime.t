# -*- mode: perl -*-
#
# $Id: 25localtime.t,v 1.1 1999/12/18 03:29:50 tai Exp $
#

use Test;

BEGIN { plan tests => 3 }

use Schedule::Match qw(scheck rcheck uthash isleap expand localtime);

$time = time;

ok(scalar(CORE::localtime($time)), scalar(localtime($time)));

@time = localtime($time);
@core = CORE::localtime($time);

ok($time[0], $core[0]);
ok($time[8], $core[8]);

exit(0);

# -*- mode: perl -*-
#
# $Id: 25isleap.t,v 1.1 1999/12/18 03:29:50 tai Exp $
#

use Test;

BEGIN { plan tests => 1 }

use Schedule::Match qw(scheck rcheck uthash isleap expand localtime);

for (1996..2004) {
    $list .= isleap($_) ? "1" : "0";
}

ok($list, "100010001");

exit(0);

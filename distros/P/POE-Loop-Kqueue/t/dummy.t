# $Id: dummy.t,v 1.1 2005/03/14 14:17:22 godegisel Exp $
use strict;
use Test::More tests => 1;

eval "use POE qw(Loop::Kqueue);";

ok(!$@);

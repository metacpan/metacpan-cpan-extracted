# $Id: 20compile.t 533 2006-05-29 17:26:34Z nicolaw $

chdir('t') if -d 't';
use lib qw(./lib ../lib);
use Test::More tests => 2;

use_ok('Proc::DaemonLite');
require_ok('Proc::DaemonLite');

1;


# $Id: 20compile.t 976 2007-03-04 20:47:36Z nicolaw $

chdir('t') if -d 't';
use lib qw(./lib ../lib);
use Test::More tests => 2;

use_ok('Parse::DMIDecode');
require_ok('Parse::DMIDecode');

1;


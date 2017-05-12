use strict;
use warnings;

use Test::More tests => 2;
use Test::Deep 'all';

ok(defined &all);
ok(! defined &any);


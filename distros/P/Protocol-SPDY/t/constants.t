use strict;
use warnings;

use Test::More tests => 3;
use Protocol::SPDY::Constants ':all';

ok(FLAG_FIN, 'have FIN flag');
ok(FLAG_COMPRESS, 'have COMPRESS flag');
ok(HEADER_LENGTH > 0, 'have nonzero header length');
done_testing;

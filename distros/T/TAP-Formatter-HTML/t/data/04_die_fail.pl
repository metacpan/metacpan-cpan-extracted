use strict;
use warnings;

use Test::More tests => 3;

ok(1, 'im ok');
is(1, 1, 'one is one');
like('abc', qr/b/, 'contains b');

die "this is an error test, not some horrible error";

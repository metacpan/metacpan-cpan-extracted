use strict;
use warnings;

use Test::More 'no_plan';

ok(1, 'im ok');
is(1, 1, 'one is one');
like('abc', qr/b/, 'contains b');

{
    is(1, 2, 'one is two?');
    like('abc', qr/d/, 'contains d?');
}

{
    ok(2, 'youre ok');
    fail('dont run me');
}

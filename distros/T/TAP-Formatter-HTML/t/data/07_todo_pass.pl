use strict;
use warnings;

use Test::More tests => 7;

ok(1, 'im ok');
is(1, 1, 'one is one');
like('abc', qr/b/, 'contains b');

TODO: {
    local $TODO = 'just cant get these working?';
    is(1, 1, 'one is one!');
    like('abc', qr/c/, 'contains c?');
}

TODO: {
    todo_skip 'to the loo', 2;
    ok(2, 'youre ok');
    fail('dont run me');
}

use strict;
use warnings;

use Test::More tests => 2;

TODO: {
    todo_skip 'to the loo', 2;
    ok(2, 'youre ok');
    fail('dont run me');
}

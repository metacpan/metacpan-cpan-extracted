use strict;
use warnings;

use Test::More 'no_plan';

# don't define a SKIP label
{
    skip 'to the loo', 2;
    ok(2, 'youre ok');
    fail('dont run me');
}

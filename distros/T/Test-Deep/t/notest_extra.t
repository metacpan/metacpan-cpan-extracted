use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Test::Deep::NoTest;

ok(eq_deeply([], []), "got eq_deeply");
ok(! eq_deeply({}, []), "eq_deeply works");

done_testing;

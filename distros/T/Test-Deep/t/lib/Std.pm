use strict;
use warnings;

use Test::Tester;
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use Test::Deep;

Test::Deep::builder(Test::Tester::capture());

END { done_testing; }

1;

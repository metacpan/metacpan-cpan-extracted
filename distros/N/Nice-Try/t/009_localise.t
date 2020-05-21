# -*- perl -*-

use strict;
use warnings;

use Test::More qw( no_plan );

use Nice::Try;

# Credits to Steve Scaffidi for his test suit

# try/catch localises $@
{
    eval { die "oopsie" };
    like( $@, qr/^oopsie at /, '$@ before try/catch' );

    try { die "another failure" } catch {}

    like( $@, qr/^oopsie at /, '$@ after try/catch' );
}

done_testing;

#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# `no Punk::AsyncAwait` hands the keywords back, through Future::AsyncAwait's
# own unimport, so a file can turn them on for one block of code only.

BEGIN {
    plan skip_all => 'Future::AsyncAwait required'
        unless eval { require Future::AsyncAwait; 1 };
    plan skip_all => 'perl 5.16 required for Future::AsyncAwait'
        if $] < 5.016;
}

use Punk::AsyncAwait;
BEGIN { ok($^H{'Future::AsyncAwait/async'}, 'use turns the async keyword on') }
no Punk::AsyncAwait;
BEGIN { ok(!$^H{'Future::AsyncAwait/async'}, 'and no turns it off again') }

done_testing;

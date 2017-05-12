use strict;
use warnings;
use Test::More tests => 15;

use_ok("SWISH::Filter");

ok( my $filter = SWISH::Filter->new, "new Filter" );

SKIP: {

    if ( !$ENV{TEST_FILTER} ) {
        skip "set TEST_FILTER to run binary tests", 13;
    }

    for my $file (<t/test*>) {

        diag($file);
        ok( my $doc = $filter->convert( document => $file ),
            "convert $file" );

    }

}

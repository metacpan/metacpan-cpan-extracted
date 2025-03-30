use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;
use Test::Pod::Coverage::TrustMe;

use lib 't/corpus';

MISSING_FUNCS: {
    test_out( "not ok 1 - Privates fails" );
    test_fail(+6);
    test_diag( "         got: ' 60%'" );
    test_diag( "    expected: '100%'" );
    test_diag( "Naked subroutines:" );
    test_diag( "    INTERNAL_DOODAD" );
    test_diag( "    INTERNAL_THING" );
    pod_coverage_ok( "Privates", "Privates fails" );
    test_test( "Should fail at 60%" );
}

SPECIFIED_PRIVATES: {
    test_out( "ok 1 - Privates works w/a custom PC object" );
    pod_coverage_ok(
        "Privates",
        { also_private => [ qr/^[A-Z_]+$/ ], },
        "Privates works w/a custom PC object"
    );
    test_test( "Trying to pass PC object" );
}

SPECIFIED_PRIVATES_NAKED: {
    pod_coverage_ok(
        "Privates",
        { also_private => [ qr/^[A-Z_]+$/ ], },
    );
}

done_testing;

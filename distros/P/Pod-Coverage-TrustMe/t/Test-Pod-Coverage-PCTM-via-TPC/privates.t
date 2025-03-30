use strict;
use warnings;
use Test::Needs qw(Test::Pod::Coverage);

use Test::More;
use Test::Builder::Tester;
use Test::Pod::Coverage;

use lib 't/corpus';

MISSING_FUNCS: {
    test_out( "not ok 1 - Privates fails" );
    test_fail(+4);
    test_diag( "Coverage for Privates is 60.0%, with 2 naked subroutines:" );
    test_diag( "\tINTERNAL_DOODAD" );
    test_diag( "\tINTERNAL_THING" );
    pod_coverage_ok( "Privates", { coverage_class => 'Pod::Coverage::TrustMe' }, "Privates fails" );
    test_test( "Should fail at 60%" );
}

SPECIFIED_PRIVATES: {
    test_out( "ok 1 - Privates works w/a custom PC object" );
    pod_coverage_ok(
        "Privates",
        {
          coverage_class => 'Pod::Coverage::TrustMe',
          also_private => [ qr/^[A-Z_]+$/ ],
        },
        "Privates works w/a custom PC object"
    );
    test_test( "Trying to pass PC object" );
}

SPECIFIED_PRIVATES_NAKED: {
    pod_coverage_ok(
        "Privates",
        {
          coverage_class => 'Pod::Coverage::TrustMe',
          also_private => [ qr/^[A-Z_]+$/ ],
        },
    );
}

done_testing;

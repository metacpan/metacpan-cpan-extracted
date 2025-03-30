use strict;
use warnings;
use Test::Needs qw(Test::Pod::Coverage);

use Test::More;
use Test::Builder::Tester;
use Test::Pod::Coverage;

use lib 't/corpus';

NO_VERBOSE: {
    local $ENV{HARNESS_VERBOSE} = 0;
    test_out( "ok 1 - Checking NoSymbols" );
    pod_coverage_ok( "NoSymbols", { coverage_class => 'Pod::Coverage::TrustMe' }, "Checking NoSymbols" );
    test_test( "Handles files with no symbols" );
}

VERBOSE: {
    local $ENV{HARNESS_VERBOSE} = 1;
    test_out( "ok 1 - Checking NoSymbols" );
    test_diag( "NoSymbols: no public symbols defined" );
    pod_coverage_ok( "NoSymbols", { coverage_class => 'Pod::Coverage::TrustMe' }, "Checking NoSymbols" );
    test_test( "Handles files with no symbols" );
}

done_testing;

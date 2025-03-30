use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;
use Test::Pod::Coverage::TrustMe;

use lib 't/corpus';

test_out( "not ok 1 - Checking NoPod" );
test_fail(+7);
test_diag( "         got: '  0%'" );
test_diag( "    expected: '100%'" );
test_diag( "Naked subroutines:" );
test_diag( "    bar" );
test_diag( "    baz" );
test_diag( "    foo" );
pod_coverage_ok( "NoPod", "Checking NoPod" );
test_test( "Handles files with no pod at all" );

done_testing;

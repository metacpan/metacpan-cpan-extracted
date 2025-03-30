use strict;
use warnings;
use Test::Needs qw(Test::Pod::Coverage);

use Test::More;
use Test::Builder::Tester;
use Test::Pod::Coverage;

use lib 't/corpus';

test_out( "not ok 1 - Checking NoPod" );
test_fail(+5);
test_diag( "Coverage for NoPod is 0.0%, with 3 naked subroutines:" );
test_diag( "\tbar" );
test_diag( "\tbaz" );
test_diag( "\tfoo" );
pod_coverage_ok( "NoPod", { coverage_class => 'Pod::Coverage::TrustMe' }, "Checking NoPod" );
test_test( "Handles files with no pod at all" );

done_testing;

use strict;
use warnings;
use Test::Needs qw(Pod::Coverage);

use Test::More;
use Test::Builder::Tester;
use Test::Pod::Coverage::TrustMe;

use lib 't/corpus';

test_out( "not ok 1 - Checking NoPod" );
test_fail(+2);
test_diag( "NoPod: couldn't find pod" );
pod_coverage_ok( "NoPod", { coverage_class => 'Pod::Coverage' }, "Checking NoPod" );
test_test( "Handles files with no pod at all" );

done_testing;

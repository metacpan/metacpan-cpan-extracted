use strict;
use warnings;
use Test::Needs qw(Pod::Coverage);

use Test::More;
use Test::Builder::Tester;
use Test::Pod::Coverage::TrustMe;

use lib 't/corpus';

OPTIONAL_MESSAGE: {
    test_out( "ok 1 - Pod coverage on CoveredFile" );
    pod_coverage_ok( "CoveredFile", { coverage_class => 'Pod::Coverage' } );
    test_test( "CoveredFile runs under T:B:T" );
}

done_testing;

use strict;
use warnings;

use Test::More;
use Test::Builder::Tester;
use Test::Pod::Coverage::TrustMe;

use lib 't/corpus';

pod_coverage_ok( "CoveredFile", "CoveredFile is OK" );

# Now try it under T:B:T
test_out( "ok 1 - CoveredFile is still OK" );
pod_coverage_ok( "CoveredFile", "CoveredFile is still OK" );
test_test( "CoveredFile runs under T:B:T" );

test_out( "ok 1 - Pod coverage on CoveredFile" );
pod_coverage_ok( "CoveredFile" );
test_test( "CoveredFile runs under T:B:T" );

done_testing;

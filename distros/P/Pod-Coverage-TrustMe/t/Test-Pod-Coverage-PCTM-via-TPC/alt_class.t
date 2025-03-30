use strict;
use warnings;
use Test::Needs qw(Test::Pod::Coverage);

use Test::More;
use Test::Builder::Tester;
use Test::Pod::Coverage;

use lib 't/corpus';

# CoveredByParent requires TrustMe's parent checking
test_out( "ok 1 - Checking CoveredByParent" );
pod_coverage_ok(
  "CoveredByParent",
  { coverage_class => 'Pod::Coverage::TrustMe' },
  "Checking CoveredByParent",
);

test_test( "allows alternate Pod::Coverage class" );

done_testing;

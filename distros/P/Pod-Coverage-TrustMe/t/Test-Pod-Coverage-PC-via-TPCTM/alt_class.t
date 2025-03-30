use strict;
use warnings;
use Test::Needs qw(Pod::Coverage::CountParents);

use Test::More;
use Test::Builder::Tester;
use Test::Pod::Coverage::TrustMe;

use lib 't/corpus';

# CoveredByParent requires CountParents parent checking
test_out( "ok 1 - Checking CoveredByParent" );
pod_coverage_ok(
  "CoveredByParent",
  { coverage_class => 'Pod::Coverage::CountParents' },
  "Checking CoveredByParent",
);

test_test( "allows alternate coverage class" );

done_testing;

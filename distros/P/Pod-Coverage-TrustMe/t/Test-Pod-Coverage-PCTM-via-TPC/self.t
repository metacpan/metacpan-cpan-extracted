use strict;
use warnings;
use Test::Needs qw(Test::Pod::Coverage);

use Test::More;
use Test::Builder::Tester;
use Test::Pod::Coverage;

use lib 't/corpus';

pod_coverage_ok( "Test::Pod::Coverage", { coverage_class => 'Pod::Coverage::TrustMe' }, "T:P:C itself is OK" );

done_testing;

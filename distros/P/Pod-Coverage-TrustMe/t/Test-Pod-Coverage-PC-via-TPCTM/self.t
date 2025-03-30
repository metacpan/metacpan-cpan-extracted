use strict;
use warnings;
use Test::Needs qw(Pod::Coverage);

use Test::More;
use Test::Builder::Tester;
use Test::Pod::Coverage::TrustMe;

use lib 't/corpus';

pod_coverage_ok( "Test::Pod::Coverage::TrustMe", { coverage_class => 'Pod::Coverage' }, "T:P:C itself is OK" );

done_testing;

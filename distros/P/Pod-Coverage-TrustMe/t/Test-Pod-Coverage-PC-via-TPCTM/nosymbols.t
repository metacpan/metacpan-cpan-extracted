use strict;
use warnings;
use Test::Needs qw(Pod::Coverage);

use Test::More;
use Test::Builder::Tester;
use Test::Pod::Coverage::TrustMe;

use lib 't/corpus';

test_out( "ok 1 - Checking NoSymbols" );
test_out( "# NoSymbols: no public symbols defined" );
pod_coverage_ok( "NoSymbols", { coverage_class => 'Pod::Coverage' }, "Checking NoSymbols" );
test_test( "Handles files with no symbols" );

done_testing;

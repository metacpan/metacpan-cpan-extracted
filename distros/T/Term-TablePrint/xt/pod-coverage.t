use 5.010000;
use strict;
use warnings;
use Test::More;

use Test::Pod::Coverage;
use Pod::Coverage;

plan tests => 1;
pod_coverage_ok( 'Term::TablePrint' );
#all_pod_coverage_ok( { private => [ qr/^[A-Z]/, qr/^_/ ] });

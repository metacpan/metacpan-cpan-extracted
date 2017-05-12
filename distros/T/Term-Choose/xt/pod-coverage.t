use 5.010000;
use strict;
use warnings;
use Test::More;

use Test::Pod::Coverage;
use Pod::Coverage;

use lib 'lib';
use Term::Choose;

#all_pod_coverage_ok();

plan tests => 1;
pod_coverage_ok( 'Term::Choose' );

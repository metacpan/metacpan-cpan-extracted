use 5.010000;
use strict;
use warnings;
use Test::More;

use Test::Pod::Coverage;
use Pod::Coverage;

all_pod_coverage_ok( { private => [ qr/^\p{Lu}/, qr/^_/ ] });

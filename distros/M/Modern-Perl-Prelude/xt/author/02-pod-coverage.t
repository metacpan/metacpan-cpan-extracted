use v5.30;
use strict;
use warnings;

use Test::More;

eval {
    require Test::Pod::Coverage;
    Test::Pod::Coverage->import;
    1;
} or plan skip_all => 'Test::Pod::Coverage is required for author tests';

all_pod_coverage_ok();
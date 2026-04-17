use strict;
use warnings;
use Test::More;

eval {
    require Test::Pod::Coverage;
    Test::Pod::Coverage->import;
    1;
} or plan skip_all => 'Test::Pod::Coverage not installed';

all_pod_coverage_ok();

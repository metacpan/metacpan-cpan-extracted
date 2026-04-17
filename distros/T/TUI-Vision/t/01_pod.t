use strict;
use warnings;
use Test::More;

eval {
    require Test::Pod;
    Test::Pod->import;
    1;
} or plan skip_all => 'Test::Pod not installed';

all_pod_files_ok();

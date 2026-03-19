use v5.30;
use strict;
use warnings;

use Test::More;

eval {
    require Test::Pod;
    Test::Pod->import;
    1;
} or plan skip_all => 'Test::Pod is required for author tests';

all_pod_files_ok();
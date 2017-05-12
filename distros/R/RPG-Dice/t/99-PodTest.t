use strict;
use warnings;
use Test::More;
eval "use Test::Pod";
plan skip_all => "Test::Pod required for testign POD" if $@;
all_pod_files_ok();


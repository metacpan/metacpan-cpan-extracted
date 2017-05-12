#perl -T 

use strict;
use Test::More;
eval "use Test::Pod 1.18";
plan skip_all => "Test::Pod 1.18 required for testing POD" if $@;
plan skip_all => "perl < 5.8 doesn't like utf-8 encoded PODs" if $] < 5.008;

all_pod_files_ok(all_pod_files("."));

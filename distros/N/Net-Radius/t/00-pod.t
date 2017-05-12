
# 00-pod.t: Verify all the POD documentation

use strict;
use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => 'Test::Pod is not available' if $@;
all_pod_files_ok();


# $Id: 10pod.t 533 2006-05-29 17:26:34Z nicolaw $

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

1;


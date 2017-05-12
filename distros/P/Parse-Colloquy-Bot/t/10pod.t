# $Id: 10pod.t 459 2006-05-19 19:26:42Z nicolaw $

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

1;


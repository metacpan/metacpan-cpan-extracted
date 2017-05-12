#!perl -T
# $RedRiver: pod.t,v 1.1 2007/02/23 22:05:17 andrew Exp $

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();

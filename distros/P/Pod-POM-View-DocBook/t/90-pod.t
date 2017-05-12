#!/usr/bin/perl
# $Id: 90-pod.t 4092 2009-02-24 17:46:48Z andrew $

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
eval "use Test::Pod";

if ($@) {
    plan skip_all => "Test::Pod not installed";
} else {
    all_pod_files_ok();
}

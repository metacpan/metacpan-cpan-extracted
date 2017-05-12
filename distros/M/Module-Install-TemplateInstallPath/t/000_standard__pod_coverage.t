#!/proj/axaf/ots/pkgs/perl-5.12/x86_64-linux_debian-5.0/bin/perl -w

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all =>
    "Test::Pod::Coverage required for testing POD coverage" if $@;
all_pod_coverage_ok();
    

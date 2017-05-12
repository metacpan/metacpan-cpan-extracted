#!/proj/axaf/ots/pkgs/perl-5.12/x86_64-linux_debian-5.0/bin/perl -w

use strict;
use warnings;

use Test::More;
eval "use Test::Pod";
plan skip_all => "Test::Pod required for testing POD" if $@;
all_pod_files_ok();
    

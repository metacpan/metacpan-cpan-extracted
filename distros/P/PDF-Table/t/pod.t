#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

my $min_ver = 1.52; # was 1.00, for Test::Pod
# Windows: SET AUTHOR_TESTING=1

BEGIN {
  unless ($ENV{'AUTHOR_TESTING'}) {
    print qq{1..0 # SKIP Test::Pod, for testing by the author\n};
    exit
  }
}

eval "use Test::Pod $min_ver";
plan skip_all => "Test::Pod $min_ver required for testing POD" if $@;
all_pod_files_ok();

1;

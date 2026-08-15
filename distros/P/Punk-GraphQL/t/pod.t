#!perl
use 5.024;
use strict;
use warnings;
use Test::More;

unless ($ENV{RELEASE_TESTING}) {
    plan skip_all => 'Author test; set RELEASE_TESTING to run';
}

my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();

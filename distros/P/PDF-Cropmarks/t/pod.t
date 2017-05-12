#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

plan skip_all => "release testing only" unless $ENV{RELEASE_TESTING};

all_pod_files_ok();

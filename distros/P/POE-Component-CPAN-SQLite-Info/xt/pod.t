#!perl -T

use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval {
    require Test::Pod;
    die
        if Test::Pod->VERSION < $min_tp;
    Test::Pod->import();
};
plan skip_all => "Test::Pod $min_tp required for testing POD($@)" if $@;

all_pod_files_ok();

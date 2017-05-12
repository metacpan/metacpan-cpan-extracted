#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::Most;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTOMATED_TESTING} );

# Ensure a recent version of Test::Pod
my $min_version = 1.22;
eval "use Test::Pod $min_version";
plan skip_all => "Test::Pod $min_version required for testing POD" if $@;
all_pod_files_ok();

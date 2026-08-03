#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

# the sources are checked directly as the script is installed via
# INST_SCRIPT, so it never shows up under blib for the default check
all_pod_files_ok( all_pod_files( 'lib', 'src_bin' ) );

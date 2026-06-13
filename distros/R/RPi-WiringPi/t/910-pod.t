use strict;
use warnings;

use lib 't/';

use RPiTest;
use Test::More;

unless ( $ENV{RPI_RELEASE_TESTING} ) {
    plan( skip_all => "Author test: RPI_RELEASE_TESTING not set" );
}

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

rpi_running_test(__FILE__);

all_pod_files_ok();

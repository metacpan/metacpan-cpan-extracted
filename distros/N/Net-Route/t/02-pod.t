#!perl -T

use strict;
use warnings;
use Test::More;

if ( !$ENV{'AUTHOR_TEST'} && !$ENV{'AUTHOR_TEST_NET_ROUTE'} )
{
    plan( skip_all => 'This test is only run when AUTHOR_TEST is set' );
}

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();

#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN
{
    plan skip_all => "Author tests not required for installation" unless $ENV{RELEASE_TESTING};

    # ensure a recent version of Test::Pod
    my $min_tp = 1.41;
    eval "use Test::Pod $min_tp";
    plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;
}

all_pod_files_ok();

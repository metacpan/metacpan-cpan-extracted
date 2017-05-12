#!/usr/bin/perl -w

use lib 't/lib';
use Test::Mite;
use Test::Compile;

tests compile => sub {
    # Work around Test::Compile's tendency to 'use' modules.
    # Mite.pm won't stand for that.
    local $ENV{TEST_COMPILE} = 1;

    for my $file (all_pm_files("lib")) {
        pm_file_ok($file) or BAIL_OUT("Failed to compile: $@");
    }
};

done_testing;

#!/usr/bin/perl -w

use lib 't/lib';
use Test::Mite;
use Test::Compile;

tests compile => sub {
    # Work around Test::Compile's tendency to 'use' modules.
    # Mite.pm won't stand for that.
    local $ENV{TEST_COMPILE} = 1;

    my $fail = 0;
    for my $file (all_pm_files("lib")) {
        if (not pm_file_ok $file) {
            diag "Error: $@";
            ++$fail;
        }
    }
    BAIL_OUT("Failed to compile") if $fail;
};

done_testing;

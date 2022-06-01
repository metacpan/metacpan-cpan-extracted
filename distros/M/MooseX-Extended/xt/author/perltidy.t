#!/usr/bin/env perl

use Test::Most;

eval { require Test::PerlTidy; 1 } or do {
    my $error = $@;
    my $msg   = 'Test::PerlTidy required to test if the code is tidy';
    plan( skip_all => $msg );
};

Test::PerlTidy::run_tests(
    path       => 'lib',
    perltidyrc => 'xt/perltidyrc',
);

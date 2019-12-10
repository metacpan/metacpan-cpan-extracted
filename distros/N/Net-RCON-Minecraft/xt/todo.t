#!perl

use Test::More;
use File::Find;
use strict;

eval "use Test::Fixme";
plan skip_all => "Test::Fixme required to test for forgotten FIX"."MEs" if $@;

run_tests(
    where           => [ qw<bin lib t> ],
    match           => qr/\b(?:F[I]XME|T[O]DO|X[X]X)\b/,
    filename_match  => qr!\.(pm|pod)$!,
    skip_all        => $ENV{SKIP_TEST_FIXME},
);

done_testing();

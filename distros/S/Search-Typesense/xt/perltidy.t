#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec ();
use Test::PerlTidy qw( run_tests );

my $perltidyrc = File::Spec->catfile('.perltidyrc');

run_tests(
    exclude => [
        qr/xt/, qr/Build\.PL/, qr/Makefile\.PL/, 'Search-Typesense-*',
        '.build'
    ],
    perltidyrc => $perltidyrc
);

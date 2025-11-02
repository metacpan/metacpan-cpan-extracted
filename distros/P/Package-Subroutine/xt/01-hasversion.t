#!/usr/bin/perl

# Test that all modules have a version number
use Test2::V0;

use Test::Version 1.001001 qw( version_all_ok ), {
    is_strict   => 0,
    has_version => 1,
    consistent  => 0,
    ignore_unindexable => 0,
};


# Don't run tests during end-user installs
skip_all('Author tests not required for installation')
	unless ( $ENV{RELEASE_TESTING} or $ENV{AUTOMATED_TESTING} );

plan(4);

version_all_ok();

1;

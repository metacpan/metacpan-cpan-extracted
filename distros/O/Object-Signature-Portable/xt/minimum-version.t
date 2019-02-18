#!/usr/bin/env perl

use Test::More;
unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

use Test::MinimumVersion;
all_minimum_version_ok('v5.10.0');

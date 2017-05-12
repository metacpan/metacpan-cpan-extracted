#! perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'Set AUTHOR_TEST to run this test'
    unless $ENV{AUTHOR_TEST};
plan skip_all => "Test::ConsistentVersion required for checking versions"
    unless eval "use Test::ConsistentVersion; 1";

Test::ConsistentVersion::check_consistent_versions(no_readme => 1, no_pod =>1);


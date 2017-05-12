#!perl -T

use strict;
use warnings;
use Test::More;

unless ( $ENV{AUTHOR_TESTS} ) {
    plan(skip_all => 'Author test. Set $ENV{AUTHOR_TESTS} to a true value to run.');
}

eval "use Test::CheckManifest 0.9";
plan skip_all => "Test::CheckManifest 0.9 required" if $@;
ok_manifest();

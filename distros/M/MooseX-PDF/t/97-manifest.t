#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::Most;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

my $min_version = 0.9;
eval "use Test::CheckManifest $min_version";
plan skip_all => "Test::CheckManifest $min_version required" if $@;

ok_manifest();

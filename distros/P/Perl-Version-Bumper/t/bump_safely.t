use v5.10;
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use List::Util qw( min );
use Perl::Version::Bumper qw( stable_version );

# t/lib
use lib path(__FILE__)->parent->child('lib')->stringify;
use TestFunctions;

test_dir(
    callback => 'bump_safely',
    dir      => 'bump_safely',
    stop_at  => min(             # stop at the earliest stable between those:
        stable_version,                         # - supported by the perl binary
        Perl::Version::Bumper->feature_version, # - supported by the module
    ),
);

done_testing;

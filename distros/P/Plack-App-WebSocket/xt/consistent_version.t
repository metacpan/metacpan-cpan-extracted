use strict;
use warnings;
use Test::More;
use Test::ConsistentVersion;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

Test::ConsistentVersion::check_consistent_versions(
    no_pod => 1, no_readme => 1
);
done_testing;

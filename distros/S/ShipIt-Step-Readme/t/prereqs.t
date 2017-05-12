use strict;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

eval "use Test::Prereq"; # don't use Test::Prereq::Build, doesn't work
plan skip_all => "Test::Prereq required to test dependencies" if $@;
prereq_ok();
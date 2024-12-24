use v5.10;
use strict;
use warnings;
use Test2::V0;
use Path::Tiny;
use Perl::Version::Bumper;

# t/lib
use lib path(__FILE__)->parent->child('lib')->stringify;
use TestFunctions;

test_dir(
    callback => 'bump',
    dir      => 'bump',
);

done_testing;

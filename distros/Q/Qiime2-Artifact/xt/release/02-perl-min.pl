use strict;
use warnings;
use Test::More;
eval "use Test::MinimumVersion 0.101082";
plan skip_all => "Test::MinimumVersion 0.101082 required to test minimum Perl version" if $@;
all_minimum_version_ok('5.18');

use strict;
use warnings;
use Test::More;


plan skip_all => "Author tests" unless $ENV{AUTHOR_MODE};
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
    unless eval "use Test::Pod::Coverage; 1";

all_pod_coverage_ok();

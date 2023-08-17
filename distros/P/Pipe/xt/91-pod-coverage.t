use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
#all_pod_coverage_ok();
plan tests => 1;
pod_coverage_ok('Pipe');
#plan skip_all => 'add later';

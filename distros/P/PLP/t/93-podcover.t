use strict;
use warnings;
use lib 'lib';

use Test::More;
eval 'use Test::Pod::Coverage';
plan skip_all => "Test::Pod::Coverage required for testing POD coverage" if $@;

plan tests => 1;
pod_coverage_ok($_, {nonwhitespace => 1, private => ['exit']}, $_) for 'PLP::Functions';

# Other modules can be assumed either private (Tie::*),
# simple includes (Backend::* - generally only accessed by constructor),
# or both (Fields - defying Coverage because it just exports variables).


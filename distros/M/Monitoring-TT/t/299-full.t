use strict;
use warnings;
use Test::More;

eval "use Test::Cmd";
plan skip_all => 'Test::Cmd required' if $@;
plan tests    => 12;

use lib('t');
use TestUtils;

TestUtils::test_montt('t/data/299-full');

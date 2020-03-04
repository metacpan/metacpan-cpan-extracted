use strict;
use warnings;

use Test::More;
use Test::MinimumVersion;
all_minimum_version_ok( qq{5.008003} , { skip => ['t/026-named-captures.t'] });

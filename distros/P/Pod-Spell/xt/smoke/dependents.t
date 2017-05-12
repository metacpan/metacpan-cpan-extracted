use strict;
use warnings;

use Test::DependentModules qw( test_all_dependents );

test_all_dependents('Pod::Spell');

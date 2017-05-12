use strict;
use warnings;

use Test::More 'no_plan';
use Test::CheckChanges order => 'first';

Test::CheckChanges::ok_changes();

ok(1, "bob");


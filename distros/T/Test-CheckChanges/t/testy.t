use strict;
use warnings;

use Test::More tests => 2;
use Test::CheckChanges order => 'first';

Test::CheckChanges::ok_changes();

ok(1, "bob");


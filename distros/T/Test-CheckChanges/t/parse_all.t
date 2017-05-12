
use strict;

use Test::More;
use Test::CheckChanges;

ok_changes(
    base => 'examples/mixxed'
);

is("@Test::CheckChanges::not_found", "v0.0.0 v0.0_1 0.0.2 v6.0.0 7.0.0 8.0_0 v8.0_0 0.7", "parser");

done_testing();

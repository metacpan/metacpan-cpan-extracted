# -*- cperl -*-
use Test::More tests => 7;

use strict;
use PHP::Include;

include_php_vars( "t/loh.php" );

is ($x => 42, 'load complete');

ok(@list, 'Array defined');

is(scalar(@list) => 4, "List with four elements");

is(ref($list[1]), 'HASH' => "Hash reference at position 1");
is(ref($list[2]), 'HASH' => "Hash reference at position 2");

is($list[1]{baa} => 'bee' => "check position [1]->{baa}");
is($list[2]{4} => 5       => "check position [2]->{4}");

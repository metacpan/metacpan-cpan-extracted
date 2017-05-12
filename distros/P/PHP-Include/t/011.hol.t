# -*- cperl -*-
use Test::More tests => 9;

use strict;
use PHP::Include;

include_php_vars( "t/hol.php" );

is ($x => 42, 'load complete');

ok(%hash1, 'Hash defined');

ok(exists($hash1{a}), 'Key "a" exists');
ok(exists($hash1{b}), 'Key "b" exists');
ok(exists($hash1{c}), 'Key "c" exists');

is(ref($hash1{b}) => 'ARRAY', 'Value for "b" is array reference');
is(ref($hash1{c}) => 'ARRAY', 'Value for "c" is array reference');

is($hash1{b}[2] => 'bii', 'Check value on {b}->[2]');
is($hash1{c}[2] => 3, 'Check value on {c}->[2]');

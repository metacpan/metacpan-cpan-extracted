# -*- cperl -*-
use Test::More tests => 9;

use strict;
use PHP::Include;

include_php_vars( "t/hoh.php" );

is ($x => 42, 'load complete');

ok(%hash1, 'Hash defined');

ok(exists($hash1{a}), 'Key "a" exists');
ok(exists($hash1{b}), 'Key "b" exists');
ok(exists($hash1{c}), 'Key "c" exists');

is(ref($hash1{b}) => 'HASH', 'Value for "b" is hash reference');
is(ref($hash1{c}) => 'HASH', 'Value for "c" is hash reference');

is($hash1{b}{baa} => 'bee', 'Check value on {b}->{baa}');
is($hash1{c}{1}   => 2    , 'Check value on {c}{1}');

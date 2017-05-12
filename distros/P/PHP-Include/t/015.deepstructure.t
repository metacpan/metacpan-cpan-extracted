# -*- cperl -*-
use Test::More tests => 11;
use strict;
use PHP::Include;

include_php_vars( "t/deepstructure.php" );

is ($x => 42, 'load complete');           #1
ok(%structure, 'Hash defined');           #2

ok(exists($structure{names}) => 'Key "names" exists');  #3
ok(exists($structure{ages})  => 'Key "ages" exists');   #4

is(ref($structure{names}) => 'HASH',  'Value for "names" is hash reference');    #5
is(ref($structure{ages})  => 'ARRAY', 'Value for "ages" is an array reference'); #6

is(ref($structure{names}{a}) => 'ARRAY', 'Value for {names}{a} is array ref');  #7
is(ref($structure{names}{b}) => 'ARRAY', 'Value for {names}{b} is array ref');  #8

is_deeply($structure{names}{a} => [qw.alberto antonio.], '{names}{a}'); #9
is_deeply($structure{names}{b} => [qw.burro brain.],     '{names}{b}'); #10

is_deeply($structure{ages} => [10, 20, 30, 40], '{ages}'); #11

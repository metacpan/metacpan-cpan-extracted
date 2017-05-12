#!perl
use strict;
use warnings;

use Test::More 'no_plan';
BEGIN { use_ok('Syntax::Keyword::Gather') };

ok eq_array(
   [gather { take $_ for 1..10; take 99 }],
   [1..10, 99],
), 'basic gather works' ;
ok eq_array(
   [gather { take $_ for 1..10; take 99 unless gathered }],
   [1..10],
), 'gathered works in boolean context (true)';
ok eq_array(
   [gather { take 99 unless gathered }],
   [99],
), 'gathered works in boolean context (false)';

ok eq_array(
   [gather { take $_ for 1..10; pop @{+gathered} }],
   [1..9]
), 'gathered allows modification of underlying data';

ok(!eval{ take 'two' }, 'take does not work without gather');
ok(!eval{ gathered }, 'gathered does not work without gather');

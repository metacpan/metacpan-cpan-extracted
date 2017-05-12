# -*- cperl -*-
use Test::More tests => 3;

use strict;
use PHP::Include;

include_php_vars( "t/lol.php" );

is ($x => 42, 'load complete');

ok(@list, 'Array defined');

is_deeply(\@list, ['a',[qw.baa bee bii boo buu.],[1,2,3,4,5],69], "Array is correct");

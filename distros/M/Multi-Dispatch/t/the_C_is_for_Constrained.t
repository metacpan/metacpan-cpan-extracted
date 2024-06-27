use 5.022;
use warnings;
use strict;

use Test::More;
plan tests => 3;

use Multi::Dispatch;

multi foo  ($x                 , $y                ) { return '??' }
multi foo  ($x :where({$x > 0}), $y                ) { return '+?' }
multi foo  ($x :where({$x > 0}), $y :where({$y<0}) ) { return '+-' }

is foo(+1, -1), '+-' => 'foo(+-)';
is foo(+1, +1), '+?' => 'foo(++)';
is foo(-1, -1), '??' => 'foo(--)';

done_testing();




use 5.022;
use warnings;
use strict;

use Test::More;
plan tests => 2;

use Multi::Dispatch;

multi foo         ($x, $y)     { 'x/y'   }
multi foo         ($x, $y, @z) { 'x/y/z' }
multi foo :before (@any)       { 'before ' . &next::variant  }

is foo(1,2),   'before x/y'    => 'before x/y';
is foo(1,2,3), 'before x/y/z'  => 'before x/y/z';

done_testing();


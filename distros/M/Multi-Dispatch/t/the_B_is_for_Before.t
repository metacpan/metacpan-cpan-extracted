use 5.022;
use warnings;
use strict;

use Test::More;
plan tests => 3;

use Multi::Dispatch;

multi foo :before ($x                  ) { return 'before ' . &next::variant }
multi foo         ($x :where({$x > 0}) ) { return 'positive' }
multi foo         ($x :where({$x < 0}) ) { return 'negative' }
multi foo         ($x                  ) { return 'zero' }

is foo(1),  'before positive' => 'foo(1)';
is foo(-1), 'before negative' => 'foo(-1)';
is foo(0),  'before zero'     => 'foo(0)';



done_testing();



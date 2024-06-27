use 5.022;
use warnings;
use strict;

use Test::More;
plan tests => 4;

use Multi::Dispatch;

multi foo  ($r1 = 'null'           )    { return $r1 }
multi foo  ($r1                    )    { return 'r' }
multi foo  ($r1, $r2='d2'          )    { return 'rd' }
multi foo  ($r1, $r2='d2', $r3='d3')    { return 'rdd' }

is foo(1,2,3), 'rdd'   => 'rdd';
is foo(1,2),   'rd'    => 'rd';
is foo(1),     'r'     => 'r';
is foo(),      'null'  => 'null';

done_testing();







use 5.022;
use warnings;
use strict;

use Test::More;
plan tests => 4;

use Multi::Dispatch;

multi foo  ($r1='d1', $r2='d2', $r3='d3')    { return 'ddd' }
multi foo  ($r1,      $r2='d2', $r3='d3')    { return 'rdd' }
multi foo  ($r1,      $r2,      $r3='d3')    { return 'rrd' }
multi foo  ($r1,      $r2,      $r3)         { return 'rrr' }

is foo(1,2,3), 'rrr'  =>  'rrr';
is foo(1,2),   'rrd'  =>  'rrd';
is foo(1),     'rdd'  =>  'rdd';
is foo(),      'ddd'  =>  'ddd';

done_testing();






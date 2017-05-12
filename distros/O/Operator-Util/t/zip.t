#!perl
use strict;
use warnings;
use Test::More tests => 8;
use Operator::Util qw( zip zipwith );

# zip
is_deeply [zip ['a','b'], [1,2]], ['a',1,'b',2], 'zip() produces expected result';

# zipwith
is_deeply [zipwith '**',  [1,2,3],   [2,4]  ], [1,16],      'zipwith(**) works';
is_deeply [zipwith '.',   ['a','b'], [1,2]  ], ['a1','b2'], 'zipwith(.) produces expected result';
is_deeply [zipwith '*',   [1,2],     [3,4]  ], [3,8],       'zipwith(*) works';
is_deeply [zipwith '<=>', [1,2],     [3,2,0]], [-1, 0],     'zipwith(<=>) works';

# tests for non-list arguments
is_deeply [zipwith '*', 1, [3,4]], [3], 'zipwith(*) works with scalar left side';
is_deeply [zipwith '*', [1,2], 3], [3], 'zipwith(*) works with scalar right side';
is_deeply [zipwith '*', 1, 3],     [3], 'zipwith(*) works with scalar both sides';

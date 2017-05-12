use Test::More;
use strict;
use warnings;
BEGIN { use_ok 'syntax', 'qn' }


is_deeply [ qn{1,2,3}   ], [ '1,2,3' ], 'single';
is_deeply [ qn {1,2,3}  ], [ '1,2,3' ], 'wide single';
is_deeply [ qn  {1,2,3} ], [ '1,2,3' ], 'wider single';

is_deeply [
    qn {
        1
        1 2
        1 2 3
        mary  had a l i t t l e lamb         !  
    }
],
[ '1', '1 2', '1 2 3', 'mary  had a l i t t l e lamb         !' ],
'little lamb';

my @f = qn {

    1
    1 2
    
    1 2 3 4

};
is_deeply \@f, [ '', '1', '1 2', '', '1 2 3 4', '', ], 'holey smokes';

my @g = qn { 2 4 6 };
is_deeply \@g, [ '2 4 6', ], 'evens';

my @h = qn {};
is_deeply \@h, [], 'empty';

my @i = qn {
};
is_deeply \@i, [], 'shallow';

my @j = qn {
    1
    2
};
is_deeply \@j, ['1','2'], 'empty';

my $k = qn{
1
2
3};
is $k, '3', 'scalar';

my @m = qn{
    this (is( a) test)
};
is_deeply \@m, [ 'this (is( a) test)' ], 'nested';

my @n = qn{ this (is( a) test)};
is_deeply \@n, [ 'this (is( a) test)' ], 'nested one line';

my $var = 'VAR';

is_deeply [ qn{1,$var,3}   ], [ '1,$var,3' ], 'single var';
is_deeply [ qn {1,$var,3}  ], [ '1,$var,3' ], 'wide single var';
is_deeply [ qn  {1,$var,3} ], [ '1,$var,3' ], 'wider single var';

done_testing;


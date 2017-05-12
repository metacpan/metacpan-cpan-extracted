use Test::More;
use strict;
use warnings;
BEGIN { use_ok 'syntax', 'qqn' }


is_deeply [ qqn(1,2,3)   ], [ '1,2,3' ], 'single';
is_deeply [ qqn (1,2,3)  ], [ '1,2,3' ], 'wide single';
is_deeply [ qqn  (1,2,3) ], [ '1,2,3' ], 'wider single';

is_deeply [
    qqn (
        1
        1 2
        1 2 3
        mary  had a l i t t l e lamb         !  
    )
],
[ '1', '1 2', '1 2 3', 'mary  had a l i t t l e lamb         !' ],
'little lamb';

my @f = qqn (

    1
    1 2
    
    1 2 3 4

);
is_deeply( \@f, [ '', '1', '1 2', '', '1 2 3 4', '', ], 'holey smokes' );

my @g = qqn ( 2 4 6 );
is_deeply( \@g, [ '2 4 6', ], 'evens' );

my @h = qqn ();
is_deeply( \@h, [], 'empty' );

my @i = qqn (
);
is_deeply( \@i, [], 'shallow' );

my @j = qqn (
    1
    2
);
is_deeply( \@j, ['1','2'], 'empty' );

my $k = qqn(
1
2
3);
is $k, '3', 'scalar';

my @m = qqn(
    this (is( a) test)
);
is_deeply \@m, [ 'this (is( a) test)' ], 'nested';

my @n = qqn( this (is( a) test));
is_deeply \@n, [ 'this (is( a) test)' ], 'nested one line';

my $var = 'VAR';

is_deeply [ qqn(1,$var,3)   ], [ '1,VAR,3' ], 'single var';
is_deeply [ qqn (1,$var,3)  ], [ '1,VAR,3' ], 'wide single var';
is_deeply [ qqn  (1,$var,3) ], [ '1,VAR,3' ], 'wider single var';

done_testing;


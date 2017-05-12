#!perl
use strict;
use warnings;
use Test::More tests => 79;
use Operator::Util qw( reduce );

{
    my @array = (5, -3, 7, 0, 1, -9);
    my $sum   = 5 + -3 + 7 + 0 + 1 + -9; # laziness :)

    is reduce('+',   \@array ), $sum,    'reduce(+) works';
    is reduce('*',   [1,2,3] ), 1*2*3,   'reduce(*) works';
    is reduce('-',   [1,2,3] ), 1-2-3,   'reduce(-) works';
    is reduce('/',   [12,4,3]), 12/4/3,  'reduce(/) works';
    is reduce('**',  [2,2,3] ), 2**2**3, 'reduce(**) works';
    is reduce('%',   [13,7,4]), 13%7%4,  'reduce(%) works';

    is_deeply [reduce '+', \@array, triangle=>2], [5,2,9,9,10,1], 'triangle reduce(+) works';
    is_deeply [reduce '-', [1,2,3], triangle=>1], [1,-1,-4],      'triangle reduce(-) works';
}

is reduce('.', [qw<a b c d>]), 'abcd', 'reduce(.) works';
is_deeply [reduce '.', [qw<a b c d>], triangle=>1], [qw<a ab abc abcd>], 'triangle reduce(.) works';

ok  reduce('<',  [1,2,3,4]), 'reduce(<) works (1)';
ok !reduce('<',  [1,3,2,4]), 'reduce(<) works (2)';
ok  reduce('>',  [4,3,2,1]), 'reduce(>) works (1)';
ok !reduce('>',  [4,2,3,1]), 'reduce(>) works (2)';
ok  reduce('==', [4,4,4]  ), 'reduce(==) works (1)';
ok !reduce('==', [4,5,4]  ), 'reduce(==) works (2)';
ok  reduce('!=', [4,5,6]  ), 'reduce(!=) works (1)';
ok !reduce('!=', [4,4,4]  ), 'reduce(!=) works (2)';

ok  reduce('eq', [qw<a a a a>]), 'reduce(eq) basic sanity (positive)';
ok !reduce('eq', [qw<a a b a>]), 'reduce(eq) basic sanity (negative)';
ok  reduce('ne', [qw<a b c a>]), 'reduce(ne) basic sanity (positive)';
ok !reduce('ne', [qw<a a b c>]), 'reduce(ne) basic sanity (negative)';
ok  reduce('lt', [qw<a b c e>]), 'reduce(lt) basic sanity (positive)';
ok !reduce('lt', [qw<a a c e>]), 'reduce(lt) basic sanity (negative)';

{
    my $a = 1;
    my $b = 2;

    ok  reduce('==', [1,1,1,1]), 'reduce(==) with literals';
    ok  reduce('==', [$a,$a,$a]), 'reduce(==) with vars (positive)';
    ok !reduce('==', [$a,$a,2]),  'reduce(==) with vars (negative)';
    ok  reduce('!=', [$a,$b,$a]), 'reduce(!=) basic sanity (positive)';
    ok !reduce('!=', [$a,$b,$b]), 'reduce(!=) basic sanity (negative)';

    is_deeply [reduce '<', [1,2,3,4], triangle=>1], [1,1,1,1],   'triangle reduce(<) works (1)';
    is_deeply [reduce '<', [1,3,2,4], triangle=>1], [1,1,'',''], 'triangle reduce(<) works (2)';
    is_deeply [reduce '>', [4,3,2,1], triangle=>1], [1,1,1,1],   'triangle reduce(>) works (1)';
    is_deeply [reduce '>', [4,2,3,1], triangle=>1], [1,1,'',''], 'triangle reduce(>) works (2)';
    is_deeply [reduce '==', [4,4,4],  triangle=>1], [1,1,1],     'triangle reduce(==) works (1)';
    is_deeply [reduce '==', [4,5,4],  triangle=>1], [1,'',''],   'triangle reduce(==) works (2)';
    is_deeply [reduce '!=', [4,5,6],  triangle=>1], [1,1,1],     'triangle reduce(!=) works (1)';
    is_deeply [reduce '!=', [4,5,5],  triangle=>1], [1,1,''],    'triangle reduce(!=) works (2)';
}

is_deeply [reduce '**', [1,2,3],  triangle=>1], [3,8,1],   'triangle reduce(**) (right assoc) works (1)';
is_deeply [reduce '**', [3,2,0],  triangle=>1], [0,1,3],   'triangle reduce(**) (right assoc) works (2)';

{
    my @array = (undef, undef, 3, undef, 5);
    is reduce('||', \@array), 3, 'reduce(||) works';
    is reduce('or', \@array), 3, 'reduce(or) works';
}

{
    my @array = (undef, undef, undef, 3, undef, 5);
    is reduce('||', \@array), 3, 'reduce(||) works';
    is reduce('or', \@array), 3, 'reduce(or) works';

    # undef as well as [//] should work too, but testing it like
    # this would presumably emit warnings when we have them.
    is_deeply [reduce '||', [0,0,3,4,5], triangle=>1], [0,0,3,3,3], 'triangle reduce(||) works';
}

{
    my @array = (undef, undef, 0, 3, undef, 5);
    my @array1 = (2, 3, 4);
    ok !reduce('&&',  \@array ),    "reduce(&&) works with 1 false";
    is  reduce('&&',  \@array1), 4, "reduce(&&) works";
    ok !reduce('and', \@array ),    "reduce(and) works with 1 false";
    is  reduce('and', \@array1), 4, "reduce(and) works";
}

TODO: {
    local $TODO = 'reduce(,) NYI';
    is scalar reduce(',', [5,-3,7,0,1,-9]), 6, 'reduce(,) returns a list';
}

is reduce('*'), 1, 'reduce(*) with no operands returns 1';
is reduce('+'), 0, 'reduce(+) with no operands returns 0';

is reduce('*', 41),                   41,          'reduce(*, 41) returns 41';
is reduce('*', 42),                   42,          'reduce(*, 42) returns 42';
is reduce('*', 42, triangle=>1),      42,          'triangle reduce(*, 42) returns 42';
is reduce('.', 'towel'),              'towel',     'reduce(., "towel") returns "towel"';
is reduce('.', 'washcloth'),          'washcloth', 'reduce(., "washcloth") returns "washcloth"';
is reduce('.', 'towel', triangle=>1), 'towel',     'triangle reduce(., "towel") returns "towel"';

is reduce('<', 42),                   1,           'reduce(<, 42) returns true';
is reduce('<', 42, triangle=>1),      1,           'triangle reduce(<, 42) returns true';

TODO: {
    local $TODO = 'reduce(xor) NYI';
    ok !reduce('xor', [0,42]  ), 'reduce(xor) works (one of two true)';
    ok !reduce('xor', [42,0]  ), 'reduce(xor) works (one of two true)';
    ok  reduce('xor', [1,42]  ), 'reduce(xor) works (two true)';
    ok  reduce('xor', [0,0]   ), 'reduce(xor) works (two false)';
    ok !reduce('xor', [0,0,0] ), 'reduce(xor) works (three false)';
    ok !reduce('xor', [5,9,17]), 'reduce(xor) works (three true)';

    is reduce('xor', [5, 9,  0]), (5 xor 9 xor  0), 'reduce(xor) mix 1';
    is reduce('xor', [5, 0, 17]), (5 xor 0 xor 17), 'reduce(xor) mix 2';
    is reduce('xor', [0, 9, 17]), (0 xor 9 xor 17), 'reduce(xor) mix 3';
    is reduce('xor', [5, 0,  0]), (5 xor 0 xor  0), 'reduce(xor) mix 4';
    is reduce('xor', [0, 9,  0]), (0 xor 9 xor  0), 'reduce(xor) mix 5';
    is reduce('xor', [0, 0, 17]), (0 xor 0 xor 17), 'reduce(xor) mix 6';
}

# Perl 5.10 operators
SKIP: {
    skip 'Perl 5.10 required', 8 if $] < 5.010;

    # smart-match operator
    ok  reduce('~~', [qw<a a a a>]), 'reduce(~~) basic sanity (positive)';
    ok !reduce('~~', [qw<a a b a>]), 'reduce(~~) basic sanity (negative)';

    # defined-or operator
    is reduce('//', [undef, undef, 3, undef, 5]), 3, 'reduce(//) works';
    is reduce('//', [0, 0, 3, 0, 5]),             0, 'reduce(//) works';

    is reduce('~~'),       1, 'zero-argument reduce(~~)';
    is reduce('~~', 'a'),  1, 'single-argument reduce(~~)';
    is reduce('//'),       0, 'zero-argument reduce(//)';
    is reduce('//', 10),  10, 'single-argument reduce(//)';
}

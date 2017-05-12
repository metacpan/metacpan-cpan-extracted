#!perl
use strict;
use warnings;
use Test::More tests => 166;
use Operator::Util qw( hyper );

# binary infix
my @r;
my @e;
{
    @r = hyper '+', [1,2,3], [2,4,6];
    @e = (3,6,9);
    is_deeply \@r, \@e, 'hyper(+) two arrays';

    @r = hyper '-', [1,2,3], [2,4,6];
    @e = (-1,-2,-3);
    is_deeply \@r, \@e, 'hyper(-) two arrays';

    @r = hyper '*', [1,2,3], [2,4,6];
    @e = (2,8,18);
    is_deeply \@r, \@e, 'hyper(*) two arrays';

    @r = hyper 'x', [1,2,3], [3,2,1];
    @e = (111,22,3);
    is_deeply \@r, \@e, 'hyper(x) two arrays';

    @r = hyper '/', [20,40,60], [2,5,10];
    @e = (10,8,6);
    is_deeply \@r, \@e, 'hyper(/) two arrays';
}

{ # unary postfix
    my @r = (1,2,3);
    hyper 'postfix:++', \@r;
    my @e = (2,3,4);
    is_deeply \@r, \@e, 'hyper auto increment an array';
};

{ # unary prefix
    my @r;
    @r = hyper 'prefix:-', [3,2,1];
    my @e = (-3,-2,-1);
    is_deeply \@r, \@e, 'hyper op on assignment/pipeline';
};

{ # dimension upgrade
    my @r;
    @r = hyper '+', [1,2,3], 1, dwim_right=>1;
    my @e = (2,3,4);
    is_deeply \@r, \@e, 'auto dimension upgrade on rhs notation';

    @r = hyper '*', 2, [10,20,30], dwim_left=>1;
    @e = (20,40,60);
    is_deeply \@r, \@e, 'auto dimension upgrade on lhs notation';
}

{ # extension
    @r = hyper '.', [1,2,3,4], [qw<A B C D E>], dwim_right=>1;
    @e = qw<1A 2B 3C 4D>;
    is_deeply \@r, \@e, "list-level element truncate on rhs";

    @r = hyper '.', [1,2,3,4,5], [qw<A B C D>], dwim_left=>1;
    @e =  qw<1A 2B 3C 4D>;
    is_deeply \@r, \@e, "list-level element truncate on lhs";

    @r = hyper '.', [1,2,3,4], [qw<A B C>], dwim_right=>1; 
    @e = qw<1A 2B 3C 4A>;
    is_deeply \@r, \@e, "list-level element extension on rhs";

    @r = hyper '.', [1,2,3], [qw<A B C D>], dwim_left=>1;
    @e =  qw<1A 2B 3C 1D>;
    is_deeply \@r, \@e, "list-level element extension on lhs";

    @r = hyper '.', [1,2,3,4], [qw<A B>], dwim_right=>1;
    @e = qw<1A 2B 3A 4B>;
    is_deeply \@r, \@e, "list-level element extension on rhs";

    @r = hyper '.', [1,2], [qw<A B C D>], dwim_left=>1;
    @e =  qw<1A 2B 1C 2D>;
    is_deeply \@r, \@e, "list-level element extension on lhs";

    @r = hyper '.', [1,2,3,4], ['A'], dwim_right=>1;
    @e = qw<1A 2A 3A 4A>;
    is_deeply \@r, \@e, "list-level element extension on rhs";

    @r = hyper '.', [1,], [qw<A B C D>], dwim_left=>1;
    @e = qw<1A 1B 1C 1D>;
    is_deeply \@r, \@e, "list-level element extension on lhs";

    @r = hyper '.', [1,2,3,4], 'A', dwim_right=>1;
    @e = qw<1A 2A 3A 4A>;
    is_deeply \@r, \@e, "scalar element extension on rhs";

    @r = hyper '.', 1, [qw<A B C D>], dwim_left=>1;
    @e = qw<1A 1B 1C 1D>;
    is_deeply \@r, \@e, "scalar element extension on lhs";
};

{
    my (@r, @e);
    @r = hyper 'prefix:++', [1,4,9];
    @e = (2,5,10);
    is_deeply \@r, \@e, "operator call on integer list elements";
};

{ # distribution for unary prefix
    my @r;
    @r = hyper 'prefix:-', [[1, 2], [3, [4, 5]]];
    my @e = ([-1, -2], [-3, [-4, -5]]);
    is_deeply \@r, \@e, "distribution for unary prefix";
};

{ # distribution for unary postfix autoincrement
    my @r;
    @r = ([1, 2], [3, [4, 5]]);
    hyper 'postfix:++', \@r;
    my @e = ([2, 3], [4, [5, 6]]);
    is_deeply \@r, \@e, "distribution for unary postfix autoincr";
};

TODO: { # distribution for binary infix
    local $TODO = 'hyper distribution NYI';

    my @r;
    @r = hyper '+', [1, 2, [3, 4]], [4, 5, [6, 7]];
    my @e = (5, 7, [9, 11]);
    is_deeply \@r, \@e, "distribution for binary infix, same shape";

    @r = hyper '+', [1, 2, [3, 4]], [5, 6, 7], dwim_right=>1;
    @e = (6, 8, [10, 11]);
    is_deeply \@r, \@e, "distribution for binary infix, dimension upgrade";

    @r = hyper '+', [[1, 2], 3], [4, [5, 6]], dwim=>1;
    @e = ([5, 6], [8, 9]);
    is_deeply \@r, \@e, "distribution for binary infix, S03 cross-upgrade";
}

{ # regression test, ensure that hyper works on arrays
    my @r1;
    my @r2;
    my @e1 = (2,4,6);
    my @a  = (1,2,3);
    @r1 = hyper '+', \@a, \@a;
    is_deeply \@r1, \@e1, "hyper works on variables, too.";
}
{
    my @a  = (1,2,3);
    my @e2 = (2,3,4);
    my @r2 = hyper '+', \@a, 1, dwim_right=>1;
    is_deeply \@r2, \@e2, "hyper op and correctly promotes scalars";
};

# mixed hyper and reduce metaops -
# this unveils a spec bug as << recurses into arrays and [+] never gets applied,
# so we disable the entire chunk for now.
TODO: {
    local $TODO = 'hyper distribution NYI';
    is_deeply [hyper '[+]', [[1,2,3], [4,5,6]]], [6,15], "mixed hyper and reduce metaop ([+]<<) works";
}

{ # hyper dereferencing
    my @array = (
        { key => 'val' },
        { key => 'val' },
        { key => 'val' },
    );

    my $full = join '', hyper 'postcircumfix:{}', \@array, 'key', dwim_right=>1;
    is $full, 'valvalval', 'hyper-dereference an array';

    my $part = join '', hyper 'postcircumfix:{}', [@array[0,1]], 'key', dwim_right=>1;
    is $part, 'valval', 'hyper-dereference an array slice';
}

# test hypers on hashes
{
    my %a = (a => 1, b => 2, c => 3);
    my %b = (a => 5, b => 6, c => 7);
    my %c = (a => 1, b => 2);
    my %d = (a => 5, b => 6);

    my %r;
    %r = hyper '+', \%a, \%b;
    is scalar keys %r, 3, 'hash - >>+<< result has right number of keys (same keys)';
    is $r{a},          6, 'hash - correct result form >>+<< (same keys)';
    is $r{b},          8, 'hash - correct result form >>+<< (same keys)';
    is $r{c},         10, 'hash - correct result form >>+<< (same keys)';

    %r = hyper '+', \%a, \%d;
    is scalar keys %r, 3, 'hash - »+« result has right number of keys (union test)';
    is $r{a},          6, 'hash - correct result form »+« (union test)';
    is $r{b},          8, 'hash - correct result form »+« (union test)';
    is $r{c},          3, 'hash - correct result form »+« (union test)';

    %r = hyper '+', \%c, \%b;
    is scalar keys %r, 3, 'hash - >>+<< result has right number of keys (union test)';
    is $r{a},          6, 'hash - correct result form >>+<< (union test)';
    is $r{b},          8, 'hash - correct result form >>+<< (union test)';
    is $r{c},          7, 'hash - correct result form >>+<< (union test)';

    %r = hyper '+', \%a, \%b, dwim=>1;
    is scalar keys %r, 3, 'hash - <<+>> result has right number of keys (same keys)';
    is $r{a},          6, 'hash - correct result form <<+>> (same scalar keys)';
    is $r{b},          8, 'hash - correct result form <<+>> (same scalar keys)';
    is $r{c},         10, 'hash - correct result form <<+>> (same scalar keys)';

    %r = hyper '+', \%a, \%d, dwim=>1;
    is scalar keys %r, 2, 'hash - <<+>> result has right number of keys (intersection test)';
    is $r{a},          6, 'hash - correct result form <<scalar keys >> (intersection test)';
    is $r{b},          8, 'hash - correct result form <<scalar keys >> (intersection test)';

    %r = hyper '+', \%c, \%b, dwim=>1;
    is scalar keys %r, 2, 'hash - <<+>> result has right number of keys (intersection test)';
    is $r{a},          6, 'hash - correct result form <<scalar keys >> (intersection test)';
    is $r{b},          8, 'hash - correct result form <<scalar keys >> (intersection test)';

    %r = hyper '+', \%a, \%c, dwim_right=>1;
    is scalar keys %r, 3, 'hash - >>+>> result has right number of keys';
    is $r{a},           2, 'hash - correct result from >>scalar keys >>';
    is $r{b},           4, 'hash - correct result from >>scalar keys >>';
    is $r{c},           3, 'hash - correct result from >>scalar keys >>';

    %r = hyper '+', \%c, \%b, dwim_right=>1;
    is scalar keys %r, 2, 'hash - >>+>> result has right number of keys';
    is $r{a},           6, 'hash - correct result from >>scalar keys >>';
    is $r{b},           8, 'hash - correct result from >>scalar keys >>';

    %r = hyper '+', \%c, \%a, dwim_left=>1;
    is scalar keys %r, 3, 'hash - <<+<< result has right number of keys';
    is $r{a},           2, 'hash - correct result from <<scalar keys <<';
    is $r{b},           4, 'hash - correct result from <<scalar keys <<';
    is $r{c},           3, 'hash - correct result from <<scalar keys <<';

    %r = hyper '+', \%b, \%c, dwim_left=>1;
    is scalar keys %r, 2, 'hash - <<+<< result has right number of keys';
    is $r{a},          6, 'hash - correct result from <<scalar keys <<';
    is $r{b},          8, 'hash - correct result from <<scalar keys <<';
}

{
    my %a = (a => 1, b => 2, c => 3);
    my %r = hyper 'prefix:-', \%a;
    is scalar keys %r, 3, 'hash - -<< result has right number of keys';
    is $r{a},         -1, 'hash - correct result from -<<';
    is $r{b},         -2, 'hash - correct result from -<<';
    is $r{c},         -3, 'hash - correct result from -<<';

    %r = hyper 'prefix:--', \%a;
    is scalar keys %r, 3, 'hash - --<< result has right number of keys';
    is $r{a},          0, 'hash - correct result from --<<';
    is $r{b},          1, 'hash - correct result from --<<';
    is $r{c},          2, 'hash - correct result from --<<';
    is scalar keys %a, 3, 'hash - --<< result has right number of keys';
    is $a{a},          0, 'hash - correct result from --<<';
    is $a{b},          1, 'hash - correct result from --<<';
    is $a{c},          2, 'hash - correct result from --<<';

    %r = hyper 'postfix:++', \%a;
    is scalar keys %r, 3, 'hash - >>++ result has right number of keys';
    is $r{a},          0, 'hash - correct result from >>++';
    is $r{b},          1, 'hash - correct result from >>++';
    is $r{c},          2, 'hash - correct result from >>++';
    is scalar keys %a, 3, 'hash - >>++ result has right number of keys';
    is $a{a},          1, 'hash - correct result from >>++';
    is $a{b},          2, 'hash - correct result from >>++';
    is $a{c},          3, 'hash - correct result from >>++';
}

{
    my %a = (a => 1, b => 2, c => 3);

    my %r = hyper '*', \%a, 4, dwim_right=>1;
    is scalar keys %r, 3, 'hash - >>*>> result has right number of keys';
    is $r{a},          4, 'hash - correct result from >>*>>';
    is $r{b},          8, 'hash - correct result from >>*>>';
    is $r{c},         12, 'hash - correct result from >>*>>';

    %r = hyper '**', 2, \%a, dwim_left=>1;
    is scalar keys %r, 3, 'hash - <<**<< result has right number of keys';
    is $r{a},          2, 'hash - correct result from <<**<<';
    is $r{b},          4, 'hash - correct result from <<**<<';
    is $r{c},          8, 'hash - correct result from <<**<<';

    %r = hyper '*', \%a, 4, dwim=>1;
    is scalar keys %r, 3, 'hash - <<*>> result has right number of keys';
    is $r{a},          4, 'hash - correct result from <<*>>';
    is $r{b},          8, 'hash - correct result from <<*>>';
    is $r{c},         12, 'hash - correct result from <<*>>';

    %r = hyper '**', 2, \%a, dwim=>1;
    is scalar keys %r, 3, 'hash - <<**>> result has right number of keys';
    is $r{a},          2, 'hash - correct result from <<**>>';
    is $r{b},          4, 'hash - correct result from <<**>>';
    is $r{c},          8, 'hash - correct result from <<**>>';
}

TODO: {
    local $TODO = 'need an object to test';
    my %a = (a => 1, b => -2, c => 3);
    my %r = eval { hyper '->', \%a, 'abs', dwim_right=>1 };
    is scalar keys %r, 3, 'hash - >>.abs result has right number of keys';
    is $r{a},          1, 'hash - correct result from >>.abs';
    is $r{b},          2, 'hash - correct result from >>.abs';
    is $r{c},          3, 'hash - correct result from >>.abs';
}

SKIP: {
    skip 'hyper distribution NYI', 29;
    my @a = (1, { a => 2, b => 3 }, 4);
    my @b = qw<a b c>;
    my @c = ('z', { a => 'y', b => 'x' }, 'w');
    my @d = 'a'..'f';

    my @r = hyper '.', \@a, \@b, dwim=>1;
    is scalar @r,   3, 'hash in array - result array is the correct length';
    is $r[0],    "1a", 'hash in array - correct result from <<~>>';
    is $r[1]{a}, "2b", 'hash in array - correct result from <<~>>';
    is $r[1]{b}, "3b", 'hash in array - correct result from <<~>>';
    is $r[2],    "4c", 'hash in array - correct result from <<~>>';

    @r = hyper '.', \@a, \@c;
    is scalar @r,   3, 'hash in array - result array is the correct length';
    is $r[0],    "1z", 'hash in array - correct result from >>~<<';
    is $r[1]{a}, "2y", 'hash in array - correct result from >>~<<';
    is $r[1]{b}, "3x", 'hash in array - correct result from >>~<<';
    is $r[2],    "4w", 'hash in array - correct result from >>~<<';

    @r = hyper '.', \@a, \@d, dwim_right=>1;
    is scalar @r,   3, 'hash in array - result array is the correct length';
    is $r[0],    "1a", 'hash in array - correct result from >>~>>';
    is $r[1]{a}, "2b", 'hash in array - correct result from >>~>>';
    is $r[1]{b}, "3b", 'hash in array - correct result from >>~>>';
    is $r[2],    "4c", 'hash in array - correct result from >>~>>';

    TODO: {
        local $TODO = 'R meta-operator NYI';
        @r = hyper 'R.', \@d, \@a, dwim_left=>1;
        is scalar @r,   3, 'hash in array - result array is the correct length';
        is $r[0],    "1a", 'hash in array - correct result from <<R~<<';
        is $r[1]{a}, "2b", 'hash in array - correct result from <<R~<<';
        is $r[1]{b}, "3b", 'hash in array - correct result from <<R~<<';
        is $r[2],    "4c", 'hash in array - correct result from <<R~<<';
    }

    @r = hyper '.', \@a, \@d, dwim=>1;
    is scalar @r,   6, 'hash in array - result array is the correct length';
    is $r[0],    "1a", 'hash in array - correct result from <<~>>';
    is $r[1]{a}, "2b", 'hash in array - correct result from <<~>>';
    is $r[1]{b}, "3b", 'hash in array - correct result from <<~>>';
    is $r[2],    "4c", 'hash in array - correct result from <<~>>';
    is $r[3],    "1d", 'hash in array - correct result from <<~>>';
    is $r[4]{a}, "2e", 'hash in array - correct result from <<~>>';
    is $r[4]{b}, "3e", 'hash in array - correct result from <<~>>';
    is $r[5],    "4f", 'hash in array - correct result from <<~>>';
}

{
    my @a = (1, { a => 2, b => 3 }, 4);
    my @r = hyper 'prefix:-', \@a;
    is scalar @r, 3, 'hash in array - result array is the correct length';
    is $r[0],    -1, 'hash in array - correct result from -<<';
    is $r[1]{a}, -2, 'hash in array - correct result from -<<';
    is $r[1]{b}, -3, 'hash in array - correct result from -<<';
    is $r[2],    -4, 'hash in array - correct result from -<<';

    @r = hyper 'prefix:++', \@a;
    is scalar @r, 3, 'hash in array - result array is the correct length';
    is $r[0],     2, 'hash in array - correct result from ++<<';
    is $r[1]{a},  3, 'hash in array - correct result from ++<<';
    is $r[1]{b},  4, 'hash in array - correct result from ++<<';
    is $r[2],     5, 'hash in array - correct result from ++<<';

    @r = hyper 'postfix:--', \@a;
    is scalar @r, 3, 'hash in array - result array is the correct length';
    is $r[0],     2, 'hash in array - correct result from ++<<';
    is $r[1]{a},  3, 'hash in array - correct result from ++<<';
    is $r[1]{b},  4, 'hash in array - correct result from ++<<';
    is $r[2],     5, 'hash in array - correct result from ++<<';
    is scalar @a, 3, 'hash in array - result array is the correct length';
    is $a[0],     1, 'hash in array - correct result from ++<<';
    is $a[1]{a},  2, 'hash in array - correct result from ++<<';
    is $a[1]{b},  3, 'hash in array - correct result from ++<<';
    is $a[2],     4, 'hash in array - correct result from ++<<';
}

# Test for 'my @a = <a b c> »~» "z";' wrongly
# setting @a to [['az', 'bz', 'cz']].
{
    my @a = hyper '.', [qw<a b c>], 'z', dwim_right=>1;
    is "$a[0], $a[1], $a[2]", 'az, bz, cz', "dwimmy hyper doesn't return an itemized list";
}

{
    is_deeply [hyper 'prefix:-', [1..3]], [-1,-2,-3], 'ranges and hyper ops mix';
}

# Parsing hyper-subtraction
{
    is_deeply [hyper '-', [9,8],       [1,2,3,4], dwim_left =>1], [8,6,6,4],  '<<-<<';
    is_deeply [hyper '-', [9,8,10,12], [1,2],     dwim_right=>1], [8,6,9,10], '>>->>';
    is_deeply [hyper '-', [9,8],       [1,2]                   ], [8,6],      '>>-<<';
    is_deeply [hyper '-', [9,8],       [1,2,5],   dwim=>1      ], [8,6,4],    '<<->>';
}

# @array »+=»
# Hyper assignment operators
{
    my @array = (3, 8, 2, 9, 3, 8);
    @r = hyper '+=', \@array, [1, 2, 3, 4, 5, 6];
    @e = (4, 10, 5, 13, 8, 14);
    is_deeply \@r,     \@e, '»+=« returns the right value';
    is_deeply \@array, \@e, '»+=« changes its lvalue';

    @array = (3, 8, 2, 9, 3, 8);
    @r = hyper '*=', \@array, [1, 2, 3], dwim_right=>1;
    @e = (3, 16, 6, 9, 6, 24);
    is_deeply \@r,     \@e, '»*=» returns the right value';
    is_deeply \@array, \@e, '»*=» changes its lvalue';

    my $a = 'apple';
    my $b = 'blueberry';
    my $c = 'cherry';
    @r = hyper '.=', [$a, $b, $c], [qw<pie tart>], dwim_right=>1;
    @e = qw<applepie blueberrytart cherrypie>;
    is_deeply \@r, \@e, '».=» with list of scalars on the left returns the right value';
}

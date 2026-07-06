#!perl
use 5.038;
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => "the ?| operator requires perl 5.38+ (have $])"
        unless "$]" >= 5.038;
}

use Syntax::Infix::ConditionalSplice;

plan tests => 12;

# --- include when true, omit when false ------------------------------------
is_deeply([ 'a', 1 ?| '-v', 'b' ], [qw/a -v b/], 'true condition splices the element in');
is_deeply([ 'a', 0 ?| '-v', 'b' ], [qw/a b/],     'false condition splices nothing');

# --- the condition can be a comparison, no parens (prec looser than >) ------
my $n = 5;
is_deeply([ 'a', $n > 3 ?| 'big', 'b' ], [qw/a big b/], 'bare comparison condition');
is_deeply([ 'a', $n > 9 ?| 'big', 'b' ], [qw/a b/],     'false comparison condition');

# --- a parenthesised right-hand side splices several elements ---------------
my $jobs = 4;
is_deeply([ 'run', $jobs > 1 ?| ('-j', $jobs), 'end' ], [qw/run -j 4 end/],
    'parenthesised RHS splices a whole sub-list');

# --- short-circuit: RHS is not evaluated when the condition is false --------
my $calls = 0;
my $gen = sub { $calls++; return ('x') };
my @t = ( 1 ?| $gen->() );
is($calls, 1, 'RHS evaluated when condition true');
is_deeply(\@t, ['x'], 'true: value from RHS');
my @f = ( 0 ?| $gen->() );
is($calls, 1, 'RHS NOT evaluated when condition false (short-circuit)');
is_deeply(\@f, [], 'false: empty list');

# --- context awareness -----------------------------------------------------
my $s_true  = ( 1 ?| ('b') );      # scalar ctx: last value of the list
my $s_false = ( 0 ?| ('b') );      # scalar ctx: undef
is($s_true,  'b',   'scalar context, true  -> last value');
is($s_false, undef, 'scalar context, false -> undef');

# --- several conditional elements in one list ------------------------------
my ($verbose, $quiet) = (1, 0);
is_deeply(
    [ 'prog', $verbose ?| '--verbose', $quiet ?| '--quiet', 'file' ],
    [qw/prog --verbose file/],
    'multiple conditional elements in one list',
);

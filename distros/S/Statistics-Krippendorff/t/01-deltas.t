#!/usr/bin/perl
use warnings;
use strict;

use Statistics::Krippendorff;

use Test2::V0;
plan 16;

my $sk = 'Statistics::Krippendorff'->new(units => []);

is $sk->delta_nominal('a', 'a'), 0, 'nominal a-a';
is $sk->delta_nominal('a', 'b'), 1, 'nominal a-b';

is $sk->delta_jaccard('a', 'a'), 0, 'a a';
is $sk->delta_jaccard('a', 'b'), 1, 'a b';

is $sk->delta_jaccard('a', 'a,b'), 0.5, 'a ab';
is $sk->delta_jaccard('a', 'b,a'), 0.5, 'a ba';
is $sk->delta_jaccard('a,b', 'a'), 0.5, 'ab a';
is $sk->delta_jaccard('b,a', 'a'), 0.5, 'ba a';

is $sk->delta_jaccard('a,b', 'c,d'), 1, 'ab cd';
is $sk->delta_jaccard('a,b', 'a,b'), 0, 'ab ab';
is $sk->delta_jaccard('a,b', 'b,a'), 0, 'ab ba';
is $sk->delta_jaccard('a,b', 'a,c'), 2/3, 'ab ac';
is $sk->delta_jaccard('a,b', 'c,a'), 2/3, 'ab ca';
is $sk->delta_jaccard('b,a', 'c,a'), 2/3, 'ba ca';
is $sk->delta_jaccard('b,a', 'a,c'), 2/3, 'ba ac';

is $sk->delta_jaccard('a,b,c', 'b,c,d,e'), 3/5, 'abc bcde';

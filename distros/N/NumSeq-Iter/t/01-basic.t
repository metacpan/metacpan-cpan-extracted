#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use NumSeq::Iter qw(numseq_iter);

sub iter_vals {
    my $iter = shift;
    my @vals;
    while (defined(my $val = $iter->())) { push @vals, $val }
    \@vals;
}

sub iter_vals_some {
    my $iter = shift;
    my @vals;
    while (defined(my $val = $iter->())) { push @vals, $val; last if @vals >= 6 }
    \@vals;
}

subtest intrange_iter => sub {
    dies_ok { numseq_iter('') } 'empty';
    dies_ok { numseq_iter('a') } 'not a number';
    dies_ok { numseq_iter('1,') } 'dangling comma';
    dies_ok { numseq_iter(',1') } 'starts with comma';
    dies_ok { numseq_iter('1,,2') } 'multiple comma';
    dies_ok { numseq_iter('1,2,...') } 'not enough number before ellipsis';
    dies_ok { numseq_iter('1,2,3,...10') } 'missing comma before last number';
    dies_ok { numseq_iter('1,2,3,...,10,11') } 'too many numbers after ellipsis';
    dies_ok { numseq_iter('2,3,5,...,100') } 'unknown pattern';

    is_deeply(iter_vals(numseq_iter('1')), [1]);
    is_deeply(iter_vals(numseq_iter('1,3,2')), [1,3,2]);
    is_deeply(iter_vals(numseq_iter('1, 3 , 2')), [1,3,2]);
    # arithmetic
    is_deeply(iter_vals_some(numseq_iter('1,2,3,...')), [1,2,3,4,5,6]);
    is_deeply(iter_vals_some(numseq_iter('3, 2, 1, ...')), [3,2,1,0,-1,-2]);
    is_deeply(iter_vals_some(numseq_iter('1,1,1,...')), [1,1,1,1,1,1]);
    is_deeply(iter_vals_some(numseq_iter('1,1,1,...,Inf')), [1,1,1,1,1,1]);
    is_deeply(iter_vals_some(numseq_iter('1,1,1,...,-Inf')), [1,1,1]);
    is_deeply(iter_vals(numseq_iter('1,3,5,...,11')), [1,3,5,7,9,11]);
    is_deeply(iter_vals(numseq_iter('1,3,5,...,10')), [1,3,5,7,9]);
    is_deeply(iter_vals(numseq_iter('5,3,1,...,-5')), [5,3,1,-1,-3,-5]);
    is_deeply(iter_vals(numseq_iter('5,3,1,...,-4')), [5,3,1,-1,-3]);
    # geometric
    is_deeply(iter_vals_some(numseq_iter('1,2,4,...')), [1,2,4,8,16,32]);
    is_deeply(iter_vals_some(numseq_iter('64, 32, 16, ...')), [64,32,16,8,4,2]);
    is_deeply(iter_vals(numseq_iter('1,3,9,...,81')), [1,3,9,27,81]);
    is_deeply(iter_vals(numseq_iter('1,3,9,...,100')), [1,3,9,27,81]);
    is_deeply(iter_vals(numseq_iter('81,27,9,...,1')), [81,27,9,3,1]);
    is_deeply(iter_vals(numseq_iter('81,27,9,...,2')), [81,27,9,3]);
};

done_testing;

#!perl

use strict;
use warnings;
use Test::More 0.98;

use Seq::Iter qw(seq_iter);

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

subtest seq_iter => sub {
    is_deeply(iter_vals_some(seq_iter(1,1,sub{ $_[2][0]+$_[2][1] })), [1,1,2,3,5,8]);
};

done_testing;

#!perl

use strict;
use warnings;
use Test::More 0.98;

use Str::Iter qw(str_iter);

subtest str_iter => sub {
    subtest "basic" => sub {
        my $iter = str_iter("abc012");
        my @res; while (defined(my $char = $iter->())) { push @res, $char }
        is_deeply(\@res, [qw/a b c 0 1 2/]);
    };

    subtest "opt: n=2" => sub {
        my $iter = str_iter("abc0123", 2);
        my @res; while (defined(my $substr = $iter->())) { push @res, $substr }
        is_deeply(\@res, [qw/ab c0 12 3/]);
    };
};

done_testing;

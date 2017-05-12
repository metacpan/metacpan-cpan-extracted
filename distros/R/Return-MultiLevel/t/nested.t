#!perl

use Test::More tests => 1;

use warnings FATAL => 'all';
use strict;

use Return::MultiLevel qw(with_return);

my @r;
for my $i (1 .. 10) {
    push @r, with_return {
        my ($ret_outer) = @_;
        100 + with_return {
            my ($ret_inner) = @_;
            sub {
                ($i % 2 ? $ret_outer : $ret_inner)->($i);
                'bzzt1'
            }->();
            'bzzt2'
        }
    };
}

is_deeply \@r, [1, 102, 3, 104, 5, 106, 7, 108, 9, 110];

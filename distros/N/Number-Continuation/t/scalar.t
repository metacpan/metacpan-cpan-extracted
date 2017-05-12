#!/usr/bin/perl

use strict;
use warnings;

use Number::Continuation qw(continuation);
use Test::More tests => 4;

my @sets = ([ '1 2 6 7 8 9 10 22 34 56 87 88 89 90 120 121 132',
              '1-2, 6-10, 22, 34, 56, 87-90, 120-121, 132' ],
            [ '500 515 516 520 521 523 8 9 10 1 2 3 5 4 3',
              '500, 515-516, 520-521, 523, 8-10, 1-3, 5-3' ],
            [ '1000 2004 2000 1999 1998 -1 3 4 5 27 38 39',
              '1000, 2004, 2000-1998, -1, 3-5, 27, 38-39'  ]);

foreach my $set (@sets) {
    my $got = continuation($set->[0]);
    my $expected = $set->[1];
    is($got, $expected);
}

my $opts = { delimiter => '[]', range => '=>', separator => ';' };

is(continuation('1 2 3 6 7 8 9 12 13', $opts), '[1=>3]; [6=>9]; [12=>13]');

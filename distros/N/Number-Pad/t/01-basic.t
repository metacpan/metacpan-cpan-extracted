#!perl

use 5.010;
use strict;
use warnings;
use Test2::Bundle::More;

use Number::Pad qw(
                      pad_numbers
              );

subtest "pad_numbers" => sub {
    my $numbers = [
        "1",
        "-20",
        "3.1",
        "-400.56",
        "5e1",
        "6.78e02",
        "-7.8e-10",
        "Inf",
        "NaN",
    ];

    is_deeply(pad_numbers($numbers), [
        "   1    ",
        " -20    ",
        "   3.1  ",
        "-400.56 ",
        "   5e1  ",
        "6.78e02 ",
        "-7.8e-10",
        " Inf    ",
        " NaN    ",
    ]);
    is_deeply(pad_numbers($numbers, 12), [
        #123456789012
        "       1    ",
        "     -20    ",
        "       3.1  ",
        "    -400.56 ",
        "       5e1  ",
        "    6.78e02 ",
        "    -7.8e-10",
        "     Inf    ",
        "     NaN    ",
    ]);
    # XXX test which
    # XXX test truncate
};

DONE_TESTING:
done_testing;

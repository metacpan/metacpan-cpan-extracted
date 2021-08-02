#!perl -T

use 5.010;
use strict;
use warnings;
use Test2::Bundle::More;

use String::Pad qw(
                      pad
              );

subtest "pad" => sub {
    is(pad("1234", 4), "1234");
    is(pad("1234", 6), "1234  ", "right");
    is(pad("1234", 6, "l"), "  1234", "left");
    is(pad("1234", 6, "c"), " 1234 ", "center");
    is(pad("1234", 6, "c", "x"), "x1234x", "padchar");
    is(pad("1234", 1), "1234", "trunc=0");
    is(pad("1234", 1, undef, undef, 1), "1", "trunc=1");

    subtest "multiple strings" => sub {
        is_deeply(pad(["1234", "12", "12345"]), ["1234 ", "12   ", "12345"]);
        is_deeply(pad(["1234", "12", "12345"], 6), ["1234  ", "12    ", "12345 "]);
        is_deeply(pad(["1234", "12", "12345"], 2, undef, undef, 1), ["12", "12", "12"]);
    };
};

DONE_TESTING:
done_testing;

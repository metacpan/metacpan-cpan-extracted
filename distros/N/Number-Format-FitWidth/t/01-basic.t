#!perl

use 5.010;
use strict;
use warnings;
use Test2::Bundle::More;

use Number::Format::FitWidth qw(
                      format_fitwidth
              );

subtest "format_fitwidth" => sub {
    subtest "basics" => sub {
        is_deeply([format_fitwidth(1, 10, 100)], ["  1", " 10", "100"]);
    };
    subtest "zero_prefix option" => sub {
        is_deeply([format_fitwidth({zero_prefix=>1}, 1, 10, 100)], ["001", "010", "100"]);
    };
    subtest "max option" => sub {
        is_deeply([format_fitwidth({max=>9999}, 2)], ["   2"]);
    };
};

DONE_TESTING:
done_testing;

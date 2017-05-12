#!perl -T

use 5.010;
use strict;
use warnings;

use Number::Format::Metric qw(format_metric);
use Test::More 0.98;

BEGIN {
    use POSIX qw();
    $ENV{LC_ALL} = "C";
    POSIX::setlocale(&POSIX::LC_ALL, "C");
}

subtest format_metric => sub {
    is(format_metric(1.23    , {precision=>1}       ), "1.2"   , "precision 1");
    is(format_metric(1.23    , {precision=>3}       ), "1.230" , "precision 2");
    is(format_metric(1.23e3  , {base=>10}           ), "1.2ki" , "base 10 1");
    is(format_metric(1.23e9  , {base=> 2}           ), "1.1G"  , "base 2 1");
    is(format_metric(1.23e3  , {base=>10, i_mark=>0}), "1.2k"  , "i_mark=0");
    is(format_metric(1.23e-1 , {base=>10}           ), "123.0m", "number smaller than 1 1");
    is(format_metric(-1.23e-2, {base=>10}           ), "-12.3m", "number smaller than 1 1");
};

DONE_TESTING:
done_testing();

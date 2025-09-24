#!perl -T

use 5.010;
use strict;
use utf8;
use warnings;
use Test::More 0.98;

use Number::Format::Metric qw(format_metric);

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

    # uppercase_k option
    is(format_metric(1.23e3  , {base=>10, uppercase_k=>1}), "1.2Ki");

    # latin_only option
    is(format_metric(1.23e-6 , {base=>10}               ), "1.2μ");
    is(format_metric(1.23e-6 , {base=>10, latin_only=>1}), "1.2mc");

    # additional_prefix option
    is(format_metric(1.23e-6 , {base=>10, latin_only=>1, additional_prefix=>"g"}), "1.2mcg");
};

DONE_TESTING:
done_testing();

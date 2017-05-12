#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use String::PerlQuote qw(
                            double_quote
                            single_quote
                          );

subtest "double_quote" => sub {
    is(double_quote("a"),    '"a"');
    is(double_quote("a\n"),  '"a\\n"');
    is(double_quote('"'),    '"\\""');
    is(double_quote('$foo'), '"\\$foo"');
};

subtest "single_quote" => sub {
    is(single_quote("a\"'\$\\"), qq('a"\\'\$\\\\'));
    is(single_quote("a\nb"), q('a
b'));
};

DONE_TESTING:
done_testing();

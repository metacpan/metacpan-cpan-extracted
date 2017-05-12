#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

subtest 'opt: log' => sub {
    test_wrap(
        name => 'log=1 (default)',
        wrap_args => {sub => sub {}, meta => {v=>1.1}},
        posttest => sub {
            my ($wrap_res, $call_res) = @_;
            my $meta = $wrap_res->[2]{meta};
            ok($meta->{"x.perinci.sub.wrapper.logs"}, "wrap log produced");
        },
    );
    test_wrap(
        name => 'log=0',
        wrap_args => {sub => sub {}, meta => {v=>1.1}, log=>0},
        posttest => sub {
            my ($wrap_res, $call_res) = @_;
            my $meta = $wrap_res->[2]{meta};
            ok(!$meta->{"x.perinci.sub.wrapper.logs"}, "wrap log not produced");
        },
    );
};

DONE_TESTING:
done_testing;

#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

test_wrap(
    name => 'internal properties are ignored',
    wrap_args => {sub=>{}, meta=>{v=>1.1, _foo=>1}},
);

subtest 'double wrapping' => sub {
    my $meta;
    test_wrap(
        name => 'wrap 1',
        wrap_args => {sub=>{}, meta=>{v=>1.1}},
        posttest => sub {
            my ($wrap_res, $call_res) = @_;
            $meta = $wrap_res->[2]{meta};
            my $log = $meta->{"x.perinci.sub.wrapper.logs"};
            ok($log->[-1]{normalize_schema}, "normalize_schema is by default 1");
            ok($log->[-1]{validate_args}   , "validate_args is by default 1");
            ok($log->[-1]{validate_result} , "validate_result is by default 1");
        },
    );
    test_wrap(
        name => 'second wrapping',
        wrap_args => {sub=>{}, meta=>$meta},
        posttest => sub {
            my ($wrap_res, $call_res) = @_;
            $meta = $wrap_res->[2]{meta};
            my $log = $meta->{"x.perinci.sub.wrapper.logs"};
            is(~~@$log, 2, "there are two log entries");
            ok(!$log->[-1]{normalize_schema}, "normalize_schema is by default 0");
            ok(!$log->[-1]{validate_args}   , "validate_args is by default 0");
            ok(!$log->[-1]{validate_result} , "validate_result is by default 0");
        },
    );
};

subtest "meta attribute 'x.perinci.sub.wrapper.disable_validate_args'" => sub {
    test_wrap(
        name => "meta attribute 'x.perinci.sub.wrapper.disable_validate_args' is consulted",
        wrap_args => {sub=>{}, meta=>{v=>1.1, 'x.perinci.sub.wrapper.disable_validate_args'=>1}},
        posttest => sub {
            my ($wrap_res, $call_res) = @_;
            my $meta = $wrap_res->[2]{meta};
            my $log = $meta->{"x.perinci.sub.wrapper.logs"};
            ok(!$log->[-1]{validate_args}, "validate_args is 0");
        },
    );
};

subtest "meta attribute 'x.perinci.sub.wrapper.disable_validate_result'" => sub {
    my $meta;
    test_wrap(
        name => "meta attribute 'x.perinci.sub.wrapper.disable_validate_result' is consulted",
        wrap_args => {sub=>{}, meta=>{v=>1.1, 'x.perinci.sub.wrapper.disable_validate_result'=>1}},
        posttest => sub {
            my ($wrap_res, $call_res) = @_;
            $meta = $wrap_res->[2]{meta};
            my $log = $meta->{"x.perinci.sub.wrapper.logs"};
            ok(!$log->[-1]{validate_result}, "validate_result is 0");
        },
    );
};

# XXX test function returns result metadata stream=>1 (even though result/stream => 0)

DONE_TESTING:
done_testing;

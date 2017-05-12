#!perl

use 5.010;
use strict;
use warnings;

use Perinci::Sub::Wrapper qw(wrap_sub);
use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

my ($sub, $meta);

# return status code s and message m
$sub = sub {
    my %args=@_;
    return [$args{s}, $args{m} // "default message"];
};
$meta = {v=>1.1, args=>{s=>{}, m=>{}}};

test_wrap(
    name        => 'no exit_on_error',
    wrap_args   => {sub => $sub, meta => $meta,
                    convert=>{}},
    wrap_status => 200,
    call_argsr  => [s=>404],
    call_status => 404,
);

test_wrap(
    name        => 'success',
    wrap_args   => {sub => $sub, meta => $meta,
                    convert=>{exit_on_error=>1}},
    wrap_status => 200,
    call_argsr  => [s=>404],
    call_argsr  => [s=>200],
    call_status => 200,
);

# XXX fudged. we need to trap CORE::exit()
#test_wrap(
#    name        => 'dies',
#    wrap_args   => {sub => $sub, meta => $meta,
#                    convert=>{exit_on_error=>1}},
#    wrap_status => 200,
#    call_argsr  => [s=>404],
#    call_dies   => 1,
#);

test_wrap(
    name        => 'success_statuses #1',
    wrap_args   => {sub => $sub, meta => $meta,
                    convert=>{exit_on_error=>{success_statuses=>qr/^404$/}}},
    wrap_status => 200,
    call_argsr  => [s=>404],
    call_status => 404,
);

# XXX fudged
#test_wrap(
#    name        => 'success_statuses #2',
#    wrap_args   => {sub => $sub, meta => $meta, debug=>1,
#                    convert=>{exit_on_error=>{success_statuses=>qr/^404$/}}},
#    wrap_status => 200,
#    call_argsr  => [s=>200],
#    call_dies   => 1,
#);

test_wrap(
    name        =>
        'cannot be used with result_naked=1',
    wrap_args   => {sub => $sub, meta => $meta, debug=>1,
                    convert=>{result_naked=>1, exit_on_error=>1}},
    wrap_dies   => 1,
);

DONE_TESTING:
done_testing();

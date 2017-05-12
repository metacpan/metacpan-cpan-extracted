#!perl

use 5.010;
use strict;
use warnings;

use List::Util qw(sum);
use Perinci::Sub::Wrapper qw(wrap_sub);
use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

my ($sub, $meta);

$sub = sub {sleep 2;[200,"OK"]};
$meta = {v=>1.1};
test_wrap(
    name => 'no timeout',
    wrap_args => {sub => $sub, meta => $meta},
    wrap_status => 200,
    call_argsr => [],
    call_status => 200,
);
test_wrap(
    name => 'timed out',
    wrap_args => {sub => $sub, meta => $meta, convert=>{timeout=>1}},
    wrap_status => 200,
    call_argsr => [],
    call_status => 504,
);
test_wrap(
    name => 'not timed out',
    wrap_args => {sub => $sub, meta => $meta, convert=>{timeout=>3}},
    wrap_status => 200,
    call_argsr => [],
    call_status => 200,
);

done_testing();

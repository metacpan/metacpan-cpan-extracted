#!perl

use 5.010001;
use strict;
use warnings;

use Perinci::Sub::Wrapper qw(wrap_sub);
use Test::More 0.98;
use Test::Perinci::Sub::Wrapper qw(test_wrap);

my ($sub, $meta);
my $n;

# dies n times before succeeding
$sub = sub {
    my %args = @_;
    [200, "OK",
     join("",
          "a=", ($args{a}//""), "\n",
          "b=", ($args{b}//""), "\n",
      )];
 };
$meta = {v=>1.1, args=>{a=>{}, b=>{}}};

test_wrap(
    name => 'no hide_args, a recognized',
    wrap_args => {sub => $sub, meta => $meta},
    wrap_status => 200,
    call_argsr => [a=>1],
    call_res => [200, "OK", "a=1\nb=\n"],
);

test_wrap(
    name => 'no hide_args, b recognized',
    wrap_args => {sub => $sub, meta => $meta},
    wrap_status => 200,
    call_argsr => [a=>1, b=>2],
    call_res => [200, "OK", "a=1\nb=2\n"],
);

test_wrap(
    name => 'with hide_args, a recognized',
    wrap_args => {sub => $sub, meta => $meta, convert => {hide_args=>['b']}},
    wrap_status => 200,
    call_argsr => [a=>1],
    call_res => [200, "OK", "a=1\nb=\n"],
);

test_wrap(
    name => 'with hide_args, b not recognized',
    wrap_args => {sub => $sub, meta => $meta, convert => {hide_args=>['b']}},
    wrap_status => 200,
    call_argsr => [a=>1, b=>2],
    call_status => 400,
);

DONE_TESTING:
done_testing;

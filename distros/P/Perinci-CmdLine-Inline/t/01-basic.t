#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Perinci::CmdLine qw(pericmd_run_ok);

pericmd_run_ok(
    name       => "args_as=array unsupported",
    class      => "Perinci::CmdLine::Inline",
    gen_args   => {url=>'/Perinci/Examples/test_args_as_array'},
    gen_status => 501,
);
pericmd_run_ok(
    name       => "args_as=arrayref unsupported",
    class      => "Perinci::CmdLine::Inline",
    gen_args   => {url => '/Perinci/Examples/test_args_as_arrayref'},
    gen_status => 501,
);

pericmd_run_ok(
    name              => "args_as=hashref ok",
    class             => "Perinci::CmdLine::Inline",
    gen_args          => {url => '/Perinci/Examples/test_args_as_hashref'},
    inline_run_filter => 0,
    argv              => [qw/--a0 abc --json/],
    stdout_like       => qr/"a0":\s*"abc"/s,
);

pericmd_run_ok(
    name              => "opt:log=1",
    class             => "Perinci::CmdLine::Inline",
    gen_args          => {url=>'/Perinci/Examples/Tiny/noop', log=>1},
    inline_run_filter => 0,
    argv              => [qw/--trace/],
);

done_testing;

# XXX test option pack_deps

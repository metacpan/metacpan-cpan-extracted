#!/usr/bin/perl -w
# vim: set ft=perl:

# Tests generic init_rcfiles method; separate parse_rcfile tests

use strict;

use Test::More;
use Shell::Base;
use FindBin qw($Bin);
use File::Spec::Functions qw(catfile);

my ($sh, $rc, @rc, $tmp);

plan tests => 13;

use_ok("Shell::Base");

$rc = -d "t" ? catfile($Bin, 'shellrc') : catfile($Bin, 't', 'shellrc');
$sh = Shell::Base->new(RCFILES => [ $rc ]);
@rc = @{$sh->args("RCFILES")};

ok($sh, "Object with RCFILES defined");
is(@rc, 1, "RCFILES defined: '@rc'");
is($tmp = $sh->config("name"), "John Smith", "RC access: name => '$tmp'");
is($tmp = $sh->config("phone"), "6175551212", "RC access: phone => '$tmp'");
is($tmp = $sh->config("date_format"), "%Y/%m/%d", "RC access: date_format => '$tmp'");
is($tmp = $sh->config("lemon"), "meringue", "RC access: lemon => '$tmp'");
is($tmp = $sh->config("foo"), 1, "RC access: foo => '$tmp'");
is($tmp = $sh->config("bar"), 0, "RC access: bar => '$tmp'");
is($tmp = $sh->config("baz"), "quux", "RC access: baz => '$tmp'");
is($tmp = $sh->config("quote"), "Holy shit w00t!", "RC access: quote => '$tmp'");
is($tmp = $sh->config("spacetest"), "hello,  world  and  all  that", "RC access: spacetest => '$tmp'");
is($tmp = $sh->config("quoted"), '"Hello, world"', "RC access: quoted => '$tmp'");

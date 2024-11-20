#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Module::ScanDeps;

my $libs = <<'EOF';
    "/1//foo/bar",
    '/2/foo/bar',
    "C:\\3\\foo\\bar",
    q"/4/foo/bar",
    qq"/5/foo/bar",
    q:/6/foo/bar:,
    qq:/7/foo/bar:,
    q/\/8\/foo\/bar/,
    qq/\\9\/foo\/bar/,
    q[/10/foo/bar],
    qq(/11/foo/bar),
    q[/12/foo/bar],
    qq(/13/foo/bar),
    q[/14/foo/bar(1)],
    ("/15/foo", '/16/bar', q/17quux/),
    qw(fred barnie),
    qw/wilma pebbles betty bamm-bamm/,
EOF

my @expected = eval "($libs)";
plan tests => scalar @expected;

#diag("---\n$libs---");
#diag("@expected");

while ((my $got, $libs) = Module::ScanDeps::_parse_libs($libs))
{
    is $got, shift @expected;
}


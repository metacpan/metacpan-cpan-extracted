#!perl -T

use strict;
use warnings;

use Struct::Path::PerlStyle qw(str2path);
use Test::More tests => 26;

eval { str2path('(lonesome_bareword_treated_as_string)')->[0]->() };
like($@, qr/^Failed to eval hook /, "lonesome_bareword_treated_as_string");

eval { str2path('(several unregistered barewords)') };
like($@, qr/^Failed to eval hook /, "several unregistered barewords");

eval { str2path("('foo' eq 'bar' ne)")->[0]->() };
like($@, qr/^Failed to eval hook ''foo' eq 'bar' ne': syntax error/);

eval { str2path("(\$_ =~ 'foo' 'bar')")->[0]->() };
like($@, qr/^Failed to eval hook '\$_ =~ 'foo' 'bar'': syntax error/);

eval { str2path("(exit 42)")->[0]->() };
like($@, qr/^Failed to eval hook 'exit 42': 'exit' trapped by operation mask/);

eval { str2path("(use Socket)")->[0]->() };
like($@, qr/^Failed to eval hook 'use Socket': 'require' trapped by operation mask/);

eval { str2path("(open FH, '>', 'filename')")->[0]->() };
like($@, qr/^Failed to eval hook 'open FH, '>', 'filename'': 'open' trapped by operation mask/);

eval { str2path("(print 'Hi there!')")->[0]->() };
like($@, qr/^Failed to eval hook 'print 'Hi there!'': 'print' trapped by operation mask/);

eval { str2path('(warn "aaaa")')->[0]->() };
like($@, qr/^Failed to eval hook 'warn "aaaa"': 'warn' trapped by operation mask/);

eval { str2path("(=> 0)")->[0]->() };
like($@, qr/^Failed to eval hook '=> 0': syntax error/, 'unsupported implicit operator');

my $ret = eval { str2path('(die "aaaa"; return "wooo")')->[0]->() };
is($ret, undef, "die()'s message ignored");

is(
    str2path('("simple value returned")')->[0]->(),
    'simple value returned'
);

ok(
    str2path('[0][1]($_ =~ /ar/)')->[2]->([[0],[1]], [\"foo",\"bar"]),
    "explicit match"
);

ok(
    ! str2path("[0][1](m(^ar))")->[2]->([[0],[1]], [\"foo",\"bar"]),
    "implicit match against regexp"
);

ok(
    str2path('[0][1](=~ /ar/)')->[2]->([[0],[1]], [\"foo",\"bar"]),
    "implicit match with operator"
);

ok(
    str2path('[0][1](=~ "ar")')->[2]->([[0],[1]], [\"foo",\"bar"]),
    "implicit match with operator against string"
);

ok(
    str2path("(not m/b/)")->[0]->([[1]], [\undef]),
    "match against undef"
);

ok(
    str2path('[0][1]($_ eq "b")')->[2]->([[0],[1]], [\"a",\"b"]),
    "eq must return true value here"
);

ok(
    str2path('[0][1](eq "b")')->[2]->([[0],[1]], [\"a",\"b"]),
    "eq must return true value here (implicit values for operator)"
);

ok(
    ! str2path('[0][1]($_ eq "a")')->[2]->([[0],[1]], [\"a",\"b"]),
    "eq must return false value here"
);

ok(
    str2path('($_ ne "b")')->[0]->([[1]], [\undef]),
    "ne test"
);

ok(
    str2path('(ne "b")')->[0]->([[1]], [\undef]),
    "implicit ne test"
);

ok(
    ! str2path('(defined)')->[0]->([[1]], [\undef]),
    "'defined' must return false value"
);

ok(
    str2path("(not defined)")->[0]->([[1]], [\undef]),
    "negate defined's false value"
);

ok(
    str2path("(! defined)")->[0]->([[1]], [\undef]),
    "negate defined's false value"
);

ok(
    str2path("(!defined)")->[0]->([[1]], [\undef]),
    "negate defined's false value"
);


#!/usr/bin/perl -T
use strict;

use Test::More tests => 74;
use Taint::Util;

# untainted
my $s = 420;
ok !tainted($s) => "fresh scalar untainted";

# taint
taint($s); ok tainted($s) => "tainted my scalar";

# untaint
untaint($s); ok !tainted($s) => "untainted my scalar";

# taint again
taint($s); ok tainted($s) => "tainted my scalar again";

# taint/untaint never return true
ok !untaint($s) => "return value of untaint";
ok !taint($s) => "return value of taint";
ok !untaint($s) => "return value of untaint";

#
# Constant tainting
#
ok !tainted("goood") => "constant not tainted";
{
    local $@;
    eval { taint("bewbs") };
    my $err = $@; chomp $err; # Don't put \n in TAP output
    ok(!$@, "We don't attempt to taint constants");
}

#
# Multiple arguments
#

my ($a, $b, $c) = qw(a b c);
ok !tainted($a) => "fresh scalar \$a untainted";
ok !tainted($b) => "fresh scalar \$b untainted";
ok !tainted($c) => "fresh scalar \$c untainted";

taint($a, $b, $c);

ok tainted($a) => "scalar \$a tainted";
ok tainted($b) => "scalar \$b tainted";
ok tainted($c) => "scalar \$c tainted";

untaint($a, $b, $c);

ok !tainted($a) => "scalar \$a untainted";
ok !tainted($b) => "scalar \$a untainted";
ok !tainted($c) => "scalar \$a untainted";

#
# Taint/untaint array elements
#

my @elem = ($a, $b, $c);
ok !tainted($_) => "array elem untainted" for @elem;

taint(@elem);
ok tainted($_) => "array elem tainted" for @elem;

untaint(@elem);
ok !tainted($_) => "array elem tainted" for @elem;

#
# Hash keys can't be tainted
#

my %hv = qw(a b c d);

taint(%hv);
ok tainted($_) => "Hash value $_ tainted" for values %hv;
ok !tainted($_) => "Hash key $_ untainted" for keys %hv;

#
# Tainting references
#

my $sv = 420;
my $sr = \$sv;
my $ar = [ qw(a o e u) ];
my $hr = { qw(a o e u) };
my $cr = sub { "tainted?" };
my $gr = \*STDIN;
my $ov = bless [ qw(tainted magic) ] => "Mushrooms";

ok !tainted($_) => "$_ untainted" for ($sv, $sr, $ar, $hr);

taint($sv, $sr, $ar, $hr);
ok tainted($_) => "$_ tainted" for ($sv, $sr, $ar, $hr);

untaint($sv, $sr, $ar, $hr);
ok !tainted($_) => "$_ untainted" for ($sv, $sr, $ar, $hr);

# SCALAR
taint($sr);
ok tainted($sr) => "SCALAR tainted...";
ok !tainted($sv) => "...but not its value";
ok !tainted($$sr) => "...but not its value";
untaint($sr);
ok !tainted($sr) => "SCALAR untainted";

# ARRAY - Taint its elements but not it
taint(@$ar[0..3]);
ok !tainted($ar) => "ARRAY untainted";
ok tainted($_) => "ARRAY element $_ tainted" for @$ar;
untaint(@$ar[0..3]);
ok !tainted($_) => "ARRAY element $_ untainted" for @$ar;

# CODE
ok !tainted($cr) => "CODE untainted";
taint($cr);
ok tainted($cr) => "CODE tainted";
ok tainted("$cr") => '"CODE" tainted';
ok !tainted($cr->()) => 'CODE->() untainted';


# GLOB
ok !tainted(*$gr) => "*STDIN untainted";
taint(*STDIN);
ok tainted(*$gr) => "*STDIN tainted";

# Blessed objects
ok !tainted($ov) => "object untainted";
taint($ov);
ok tainted($ov) => "object tainted";

#
# Tainted file handles, a tainted handle does not taint its lines
#

ok !tainted(*DATA) => "*DATA untainted";
taint(*DATA);
ok tainted(*DATA) => "*DATA tainted";

while (<DATA>) {
    chomp;
    like $_, qr/^ba[xyz]$/ => "DATA line $_";
    ok !tainted($_) => "DATA line $_ untainted";
}

#
# qr// returns a blessed object which is tainted
#

taint(my $str = "bewbs");
ok tainted($str) => "New scalar tainted";

if ($] < 5.008) {
  SKIP: {
    skip "qr// tainted is known to fail on 5.6.2 and below" => 1;
  }
} else {
    my $re = qr/$str/;
    ok tainted($re) => "qr// tainted";
}

__DATA__
bax
bay
baz

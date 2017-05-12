#!perl -T

use strict;
use warnings;

use Test::More tests => 17;

use Sub::Nary;

my $sn = Sub::Nary->new();

my ($x, $y, @a, %h);

sub ret12 {
 if ($x) {
  return 1
 } else {
  return 1, 2
 }
}

sub ret12b {
 if ($x) {
  return 1
 }
 return 1, 2
}

sub ret12c {
 if (@a) {
  return 1, 2
 }
}

sub ret1l { $x ? 1 : @_ }

sub ret1234 {
 if ($x) {
  return 1, 2
 } elsif ($h{foo}) {
  return 3, @a[4, 5];
 } elsif (@a) {
  return @h{qw/a b c/}, $y
 }
}

sub retinif1 {
 if (return 1, 2) {
  return 1, 2, 3
 } else {
  return @_[0 .. 3]
 }
}

sub retinif2 {
 if (do { return 2, 3 if $x }) {
  return 4, 5, 6;
 }
}

my @tests = (
 [ \&ret12,                    { 1 => 0.5, 2 => 0.5 } ],
 [ \&ret12b,                   { 1 => 0.5, 2 => 0.5 } ],
 [ \&ret12c,                   { 1 => 0.5, 2 => 0.5 } ],
 [ sub { 1, ret12 },           { 2 => 0.5, 3 => 0.5 } ],
 [ sub { 1, do { ret12, 3 } }, { 3 => 0.5, 4 => 0.5 } ],
 [ sub { @_[ret12()] },        { 1 => 0.5, 2 => 0.5 } ],

 [ sub { ret12, ret12 },    { 2 => 0.25, 3 => 0.5, 4 => 0.25 } ],
 [ sub { ret12, 0, ret12 }, { 3 => 0.25, 4 => 0.5, 5 => 0.25 } ],
 [ sub { ret12, @a },       { list => 1 } ],
 [ sub { %h, ret12 },       { list => 1 } ],

 [ sub { if ($y) { ret12 } else { ret12 } }, { 1 => 0.5, 2 => 0.5 } ],

 [ \&ret1l,                     { 1 => 0.5, list => 0.5 } ],
 [ sub { $_[0], ret1l },        { 2 => 0.5, list => 0.5 } ],
 [ sub { ret1l, ret1l, ret1l }, { 3 => 0.125, list => 0.875 } ],

 [ \&ret1234, { 2 => 0.5, 3 => 0.25, 4 => 0.125, 1 => 0.125 } ],

 [ \&retinif1, { 2 => 1 } ],
 [ \&retinif2, { 2 => 0.5, 3 => 0.25, 1 => 0.25 } ],
);

my $i = 1;
for (@tests) {
 my $r = $sn->nary($_->[0]);
 my $exp = ref $_->[1] ? $_->[1] : { $_->[1] => 1 };
 is_deeply($r, $exp, 'branch test ' . $i);
 ++$i;
}


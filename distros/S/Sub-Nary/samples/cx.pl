#!/usr/bin/env perl

use strict;
use warnings;

use lib qw{blib/lib blib/arch};
use B::Deparse;
use B::Concise;
use Sub::Nary;

my ($x, $y, @z, %h);

sub wat {
 wantarray ? (1, 2) : 1;
}

sub wut {
 my $u = wat 3;
 if ($x) {
  return wat(1), wat(1), wat(1), wat(1);
 } elsif ($y) {
  sub { qr/wat/ }, %h;
 } elsif (@z) {
  { wat => 1 }
 } elsif (@_) {
  return $x, $y;
 } else {
  1, $x, 4;
 }
}

sub foo {
 if ($x) {
  return 1;
 } else {
  return 2, 3;
 }
}

sub wut2 {
 if ($x) {
 } elsif ($y) {
  sub { qr/wat/ }, %h;
 } elsif (@z) {
  return [ ];
 }
}

sub rr {
 return return;
}

sub forr {
 return 1, 2 for 1 .. 4;
}

sub ifr {
 if (return 1, 2) {
  return 1, 2, 3
 }
 return @_[0 .. 3]
}

my $code = \&wut;

my $bd = B::Deparse->new();
print STDERR $bd->coderef2text($code), "\n";

B::Concise::walk_output(\*STDERR);
B::Concise::concise_subref('basic', $code, 'cx_test');

my $sn = Sub::Nary->new();
my $cx = $sn->nary($code);
use Data::Dumper;
print STDERR Dumper($cx);

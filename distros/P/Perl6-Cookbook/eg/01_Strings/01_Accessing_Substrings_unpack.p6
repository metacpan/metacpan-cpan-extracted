#!/usr/bin/perl6
use v6;

my $s = 'The black cat climbed the green tree';

my $z = unpack("A2", $s);
$z.say;                    # Th

my ($x, $y) = unpack("A2 x2 A5", $s);
$x.say;                                  # Th
$y.say;                                  # black

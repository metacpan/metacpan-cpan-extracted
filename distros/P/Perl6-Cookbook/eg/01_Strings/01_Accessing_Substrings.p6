#!/usr/bin/perl6
use v6;

my $s = 'The black cat climbed the green tree';

my $z;
$z = substr $s, 4, 5;                   # $z = black
$z.say;

$z = substr $s, 4, -11;                 # $z = black cat climbed the 
$z.say;
$z = substr $s, 14;                     # $z = climbed the green tree
$z.say;
$z = substr $s, -4;                     # $z = tree
$z.say;
$z = substr $s, -4, 2;                  # $z = tr
$z.say;

# This does not sem to work in Perl 6
# TODO what is the replacement?
# substr can also change the string
#$z = substr $s, 14, 7, "jumped from";
#$z.say;                                 # $z = climbed
#$s.say;                                 # $s = The black cat jumped from the green tree

# TODO: see also unpack for faster extraction

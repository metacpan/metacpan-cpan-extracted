#!/usr/bin/perl

use strict;
use warnings;
use Digest::MD5;

my $string = shift @ARGV || 'testing';
my $hash = Digest::MD5::md5($string);

my $ceiling = 1 << 16;
warn $ceiling;
my ($hue,$sat) = unpack( 'S S', $hash);

my $h = ($hue/$ceiling)*360;
my $s = ( ($sat/$ceiling) / 2 )+ 0.5;


print $h,$/;
print $s,$/;

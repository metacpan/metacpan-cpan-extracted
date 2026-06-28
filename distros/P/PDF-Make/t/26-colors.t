#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 18;

BEGIN { use_ok('PDF::Make::Color') }

# sRGB color space
my $srgb = PDF::Make::Color->srgb;
ok($srgb, 'sRGB created');
is($srgb->components, 3, 'sRGB has 3 components');

# Spot color
my $spot = PDF::Make::Color->separation('PANTONE 185 C', 0, 0.81, 0.69, 0);
ok($spot, 'separation created');
is($spot->name, 'PANTONE 185 C', 'spot name');
is($spot->components, 1, 'spot has 1 component');

# RGB to CMYK conversion
my ($c, $m, $y, $k) = PDF::Make::Color->rgb_to_cmyk(1.0, 0, 0);
is($c, 0, 'red C=0');
is($m, 1, 'red M=1');
is($y, 1, 'red Y=1');
is($k, 0, 'red K=0');

# CMYK to RGB
my ($r, $g, $b) = PDF::Make::Color->cmyk_to_rgb(0, 0, 0, 0);
is($r, 1, 'white R=1');
is($g, 1, 'white G=1');
is($b, 1, 'white B=1');

# Black
($r, $g, $b) = PDF::Make::Color->cmyk_to_rgb(0, 0, 0, 1);
is($r, 0, 'black R=0');

# Hex to RGB
($r, $g, $b) = PDF::Make::Color->hex_to_rgb('#ff0000');
is($r, 1, 'hex red R=1');
is($g, 0, 'hex red G=0');

($r, $g, $b) = PDF::Make::Color->hex_to_rgb('#3498db');
ok(abs($r - 0.204) < 0.01, 'hex blue R~0.204');
ok(abs($g - 0.596) < 0.01, 'hex blue G~0.596');

done_testing;

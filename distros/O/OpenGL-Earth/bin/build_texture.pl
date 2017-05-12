#!/usr/bin/env perl
#
# Used to build binary data suitable to feed to OpenGL
# texture functions. Supply a bmp/jpeg/whatever your local
# Imager can read, and get back a .texture file.
#
# $Id$

BEGIN { $| = 1 }

use strict;
use warnings;
use Imager;

if (! @ARGV) {
    die "Usage: $0 <file.(jpg|bmp|png)>\n";
}

my $scanline;
my $tex = q{};
my $pic = Imager->new();

print "Reading bitmap...\n";


$pic->read(file=>$ARGV[0])
    or die "Can't read texture bitmap!\n";

print "Reading scanlines... ";

my $tex_w = $pic->getwidth();
my $tex_h = $pic->getheight();

my $perc = 0;

# Read bitmap image one scanline at a time
for (my $y = $tex_h - 1; $y >= 0; $y--) {
    $scanline = $pic->getscanline( y => $y );
    $tex .= $scanline;
    $perc = int (100 * ($tex_h - 1 - $y) / $tex_h);
    print "$perc%   \r";
}

print "\rTexture built.\n";

open my $texf, '>', $ARGV[0] . '.texture';
binmode $texf;
print $texf $tex;
close $texf;


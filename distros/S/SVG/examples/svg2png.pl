#!/usr/bin/perl
use strict;
use warnings;

use Image::LibRSVG;

my ($in, $out) = @ARGV;
if (not $out) {
	die <<"END_USAGE";
Converting svg file to png file:

Usage: $0 file.svg  file.png
END_USAGE
}

my $rsvg = Image::LibRSVG->new();
$rsvg->convert( $in, $out );


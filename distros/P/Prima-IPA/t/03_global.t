#! /usr/bin/perl
# $Id$

use strict;
use warnings;

use Prima::noX11;
use Prima::IPA qw(Global);

use Test::More tests => 5;

my $i = Prima::Image-> create(
	width    => 5,
	height   => 5,
	type     => im::Byte,
	lineSize => 5,
	data     => 
		"\0\0\0\0\0" .
		"\0\xff\xff\xff\0" .
		"\0\xff\x00\xff\0" . # <-- hole
		"\0\xff\xff\xff\0" .
		"\0\0\0\0\0" 
);

# 1
my $h = fill_holes( $i);
ok( $h-> pixel( 2,2) > 0, 'fill holes');

# 2
my $c = identify_contours( $h);
my $C = join(':', (1, 3, 2, 3, 3, 3, 3, 2, 3, 1, 2, 1, 1, 1, 1, 2, 1, 3));
ok(( $c and 1 == @$c and join(':', @{$c->[0]}) eq $C), 'identify contours');

# 3
$c = area_filter( $h, minArea => 1);
ok( $h-> data eq $c-> data, 'area under-filter');

# 4
$c = area_filter( $h, minArea => 110);
ok( $h-> data ne $c-> data, 'area over-filter');

# 5
# 1st pass fft, cut high bands
$i-> size( 8,8);
$i-> type( im::Double);
$i = fft(fft( $i),inverse => 1);
# 2nd pass fft, now compare
$c = fft(fft( $i),inverse => 1);
$i-> type(im::Byte);
$c-> type(im::Byte);
ok( $i-> data eq $c-> data, 'FFT');

1;

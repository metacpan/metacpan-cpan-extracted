#! /usr/bin/perl
# $Id$

use strict;
use warnings;

use Prima::noX11;
use Prima::IPA qw(Morphology);

use Test::More tests => 4;

my $i = Prima::Image-> create(
	width    => 5,
	height   => 5,
	type     => im::Byte,
	lineSize => 5,
	data     => 
		"\0\0\0\0\0" .
		"\0\xff\xff\xff\0" .
		"\0\xff\xff\xff\0" . 
		"\0\xff\xff\xff\0" .
		"\0\0\0\0\0"
);

my $e = erode( $i, neighborhood => 8 );
ok( $e-> data ne $i-> data, 'erode');

my $d = dilate( $e, neighborhood => 8 );
ok( $d-> data eq $i-> data, 'dilate');

my $r = reconstruct( $i, $e);
ok( $r-> data eq $i-> data, 'reconstruct');

$d = thinning( $i);
ok( $d-> data eq $e-> data, 'thinning');

#! /usr/bin/perl
# $Id$

use strict;
use warnings;

use Prima::noX11;
use Prima::IPA qw(Geometry);

use Test::More tests => 8;

my $i = Prima::Image-> create(
	width    => 4,
	height   => 4,
	type     => im::Byte,
	lineSize => 4,
	data     => 
		"\0\0\0\xff" .
		"\0\0\xff\x0" .
		"\0\xff\0\0" .
		"\0\xff\0\0" 
);

# 1
my $r = rotate90( $i, 0);
ok( $r-> data ne $i-> data);

# 2
$r = rotate90( $r, 1);
ok( $r-> data eq $i-> data);

# 3
$r = rotate180( $i);
ok( $r-> data ne $i-> data);

# 4
$r = rotate180( $r);
ok( $r-> data eq $i-> data);

# 5
$r = mirror( $i, type => 1);
ok( $r-> data ne $i-> data);

# 6
$r = mirror( $r, type => 1);
ok( $r-> data eq $i-> data);

# 7
$r = mirror( $i, type => 2);
ok( $r-> data ne $i-> data);

# 8
$r = mirror( $r, type => 2);
ok( $r-> data eq $i-> data);

1;

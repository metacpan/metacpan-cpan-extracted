#! /usr/bin/perl
# $Id$

use strict;
use warnings;

use Prima::noX11;
use Prima::IPA qw(Local);

use Test::More tests => 3;

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

#1
$i = median(median($i));
my $j = $i-> dup;
$j-> pixel(2,2,0);
ok( (($i-> pixel(2,2) > 0) and ($j-> data !~ /[^\0]/)), 'median');

#2
$i = gaussian( 5, 0.01);
$i-> type(im::Byte);
$j = $i-> dup;
$j-> pixel(2,2,0);
ok( (($i-> pixel(2,2) > 0) and ($j-> data !~ /[^\0]/)), 'gaussian');

# 3
$i-> set(
	lineSize => 5,
	data     => 
		"\x00\x00\x00\x00\x00" .
		"\x00\x10\x30\x10\x00" .
		"\x00\x30\xff\x30\x00" .
		"\x00\x10\x30\x10\x00" .
		"\x00\x00\x00\x00\x00" 
);
$i = nms($i);
$j = $i-> dup;
$j-> pixel(2,2,0);
ok( (($i-> pixel(2,2) > 0) and ($j-> data !~ /[^\0]/)), 'non-maxima suppression');

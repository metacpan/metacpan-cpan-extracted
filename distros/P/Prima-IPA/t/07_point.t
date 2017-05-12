#! /usr/bin/perl
# $Id$

use strict;
use warnings;

use Prima::noX11;
use Prima::IPA qw(Point);
use Test::More tests => 7;

my $i = Prima::Image-> create(
	width    => 4,
	height   => 1,
	type     => im::Byte,
	lineSize => 4,
	data     => "\x4f\xff\x00\x00",
);

ok( threshold( $i, minvalue => 0x50)-> data eq "\x00\xff\x00\x00", 'threshold');
ok( threshold( $i, maxvalue => 0x50)-> data eq "\xff\x00\xff\xff", 'threshold');
ok( remap( $i, lookup =>[1,(0)x(254),2])-> data eq "\x00\x02\x01\x01", 'remap');

my $ones = $i-> dup; 
$ones-> data("\1\1\1\1");

ok( subtract( $i, $ones, 
	conversionType => Prima::IPA::conversionTrunc
)-> data eq "\x4e\xfe\x00\x00", 'subtract');

ok( combine ( 
	images         => [ $i, $ones ], 
	conversionType => Prima::IPA::conversionTrunc, 
	combineType    => Prima::IPA::combineSum,
)-> data eq "\x50\xff\x01\x01", 'combine');

ok( ab( $i, 0.5, 1.0)-> data eq "\x28\x80\x01\x01", 'ab');

$i-> type(im::Double);
ok( log( exp( $i))-> data eq $i-> data, 'log/exp');


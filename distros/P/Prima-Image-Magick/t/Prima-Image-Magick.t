# $Id: Prima-Image-Magick.t,v 1.4 2012/01/03 16:45:33 dk Exp $
use strict;
use Test::More tests => 18;

eval {
	use Prima::noX11;
	require Prima;
};

ok(not($@), 'require Prima'); warn $@ if $@;

eval {
	require Prima::Image::Magick;
};
ok(not($@), 'require Prima::Image::Magick'); warn $@ if $@;

use Prima::Image::Magick qw(:all);

my $i = Prima::Image-> new( 
	width => 4, 
	height => 4, 
	type => im::Byte,
	data => 
		'*** '.
		'*  *'.
		'*** '.
		'*   '
);

sub try
{
	my ( $i, $type, $typedesc, $typecmp) = @_;

	$i = $i-> dup;
	$i-> type( $type);

	my $m;
	eval {
		$m = prima_to_magick( $i);
	};
	ok(( not($@) and $m and ref($m) eq 'Image::Magick'), "prima_to_magick $typedesc"); 

	warn $@ if $@;
	
	my $j;
	eval {
		$j = magick_to_prima( $m);
	};
	ok(( not($@) and $j and ref($j) eq 'Prima::Image'), "magick_to_prima $typedesc"); 
	warn $@ if $@;

	$i-> type( $typecmp) if $typecmp;
	$j-> type( $i-> type);
	$j-> resample( $i-> rangeLo, $i-> rangeHi, 0.0, 255.0) if $typecmp;
	ok( $j-> data eq $i-> data, "conversion ok $typedesc");
}

try( $i, im::Byte,   'Byte');
try( $i, im::RGB,    'RGB');
try( $i, im::BW,     '1-bit');

$i-> type(im::Double);
$i-> resample( $i-> rangeLo, $i-> rangeHi, 0.0, 255.0);

try( $i, im::Double, 'double', im::Double);
try( $i, im::Float, 'float', im::Float);

my $k = $i-> dup;
$i-> Emboss;
ok( $i-> data ne $k-> data, "inplace conversion");

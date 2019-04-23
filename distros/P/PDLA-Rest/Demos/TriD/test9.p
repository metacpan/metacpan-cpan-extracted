use blib;
use Carp;

# $SIG{__DIE__} = sub {die Carp::longmess(@_);};

use PDLA;
use PDLA::Graphics::TriD;
use PDLA::IO::Pic;
use PDLA::Graphics::TriD::Polygonize;


$orig = PDLA->pdl(0,0,0)->float;

sub func1 {
	my($x,$y,$z) = map {$_[0]->slice("($_)")} 0..2;
	$r = $x**2 + 1.5*$y**2 + 0.3 * $z**2 + 5*($x**2-$y)**2;
	$res = ($r - 1) *  -1;
#	print $res;
	return $res;
}

$x = PDLA::Graphics::TriD::StupidPolygonize::stupidpolygonize($orig,
	5, 50, 10,\&func1)  ;

# print $x;
imag3d $x,{Lines => 0, Smooth => 1};

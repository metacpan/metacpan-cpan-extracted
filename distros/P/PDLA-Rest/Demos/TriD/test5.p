
use blib;
use Carp;

$SIG{__DIE__} = sub {die Carp::longmess(@_);};

use PDLA;
use PDLA::Graphics::TriD;
use PDLA::Graphics::TriD::Image;
use PDLA::IO::Pic;

use PDLA::Graphics::TriD::Graph;
use PDLA::Graphics::OpenGL;

$g = new PDLA::Graphics::TriD::Graph();
$g->default_axes();

$a = PDLA->zeroes(3,1000);
random($a->inplace);

$g->add_dataseries(new PDLA::Graphics::TriD::Points($a,$a),"pts");
$g->bind_default("pts");

$b = PDLA->zeroes(3,30,30);
axisvalues($b->slice("(0)"));
axisvalues($b->slice("(1)")->xchg(0,1));

$b /= 30;

random($b->slice("(2)")->inplace);

($tmp = $b->slice("(2)")) /= 5; $tmp += 2;

$c = PDLA->zeroes(3,30,30);
random($c->inplace);

$g->add_dataseries(new PDLA::Graphics::TriD::SLattice($b,$c),"slat");
$g->bind_default("slat");

# $g->add_dataseries(new PDLA::Graphics::TriD::Lattice($b,(PDLA->pdl(0,0,0)->dummy(1)->dummy(1))),
# 	"blat");
# $g->bind_default("blat");

$g->add_dataseries(new PDLA::Graphics::TriD::SCLattice($b+1,$c->slice(":,0:-2,0:-2")),
	"slat2");
$g->bind_default("slat2");

$g->scalethings();

$win = PDLA::Graphics::TriD::get_current_window();
$win->clear_objects();
$win->add_object($g);

$win->twiddle();



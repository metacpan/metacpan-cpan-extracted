use blib;
use Carp;

$SIG{__DIE__} = sub {die Carp::longmess(@_);};

use PDLA;
use PDLA::Graphics::TriD;
use PDLA::Graphics::TriD::Image;
use PDLA::IO::Pic;

$PDLA::Graphics::TriD::verbose=0;

$win = PDLA::Graphics::TriD::get_current_window();
$vp = $win->new_viewport(0,0,1,1);

# Here we show an 8-dimensional (!!!!!) RGB image to test Image.pm

$r = zeroes(4,5,6,7,2,2,2,2)+0.1;
$g = zeroes(4,5,6,7,2,2,2,2);
$b = zeroes(4,5,6,7,2,2,2,2);

($tmp = $r->slice(":,:,2,2")) .= 1;
($tmp = $r->slice(":,:,:,1")) .= 0.5;
($tmp = $g->slice("2,:,1,2")) .= 1;
($tmp = $b->slice("2,3,1,:")) .= 1;

$vp->clear_objects();
$vp->add_object(new PDLA::Graphics::TriD::Image([$r,$g,$b]));
$win->twiddle();


package Tcl::pTk::Photo;

our ($VERSION) = ('1.00');

use Tcl::pTk;

use base  qw(Tcl::pTk::Image);

Construct Tcl::pTk::Image 'Photo';

sub Tk_image { 'photo' }

# These method should be autoloaded in Tcl::pTk::Widget, so we don't need to explicitly call out here
#Tcl::pTk::Methods('blank','copy','data','formats','get','put','read',
#           'redither','transparency','write');

use Tcl::pTk::Submethods (
    'transparency'  => [qw/get set/],
);

1;
__END__

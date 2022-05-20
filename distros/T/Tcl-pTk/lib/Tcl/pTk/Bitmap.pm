package Tcl::pTk::Bitmap;

our ($VERSION) = ('1.09');

use warnings;
use strict;

require Tcl::pTk;
require Tcl::pTk::Image;

use base  qw(Tcl::pTk::Image);
Construct Tcl::pTk::Image 'Bitmap';
sub Tk_image { 'bitmap' }
1;
__END__

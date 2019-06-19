package Tcl::pTk::Toplevel;

our ($VERSION) = ('1.00');

# Simple Toplevel package.
#  Split-out from the Tcl::pTk::Widget package for compatibility with
#   'use base (Tcl::pTk::Toplevel)' statements used in perl/tk
#

use Tcl::pTk::Widget();
use Tcl::pTk::Wm();

@Tcl::pTk::Toplevel::ISA = qw(Tcl::pTk::Wm Tcl::pTk::Widget);


sub Populate
{
 my ($cw,$arg) = @_;
 $cw->SUPER::Populate($arg);
 $cw->ConfigSpecs('-title',['METHOD',undef,undef,$cw->class]);
}

# Method to return the containerName of the widget
#   Any subclasses of this widget can call containerName to get the correct
#   container widget for the subwidget
sub containerName{
        return 'Toplevel';
}


1;


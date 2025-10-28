use strict;
use Tcl::Tk;

my $int = new Tcl::Tk;

use Tcl::Tk::Tkwidget::treectrl;
Tcl::Tk::Tkwidget::treectrl::init($int);

$int->source('../demos/demo.tcl');
$int->focus('.');
$int->MainLoop;


use strict;
use Tcl::Tk;

my $int = new Tcl::Tk;

use Tcl::Tk::Tkwidget::Tix;
Tcl::Tk::Tkwidget::Tix::init($int);

$int->source('demos/tixwidgets.tcl');
$int->focus('.');
$int->MainLoop;


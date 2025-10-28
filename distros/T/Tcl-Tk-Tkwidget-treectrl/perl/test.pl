use Test::More tests=>1;
use strict;
use Tcl::Tk;

my $int = new Tcl::Tk;
use Tcl::Tk::Tkwidget::treectrl;

$int->SetVar('::treectrl_library','library');

Tcl::Tk::Tkwidget::treectrl::Treectrl_Init($int);

#print "ret=".$int->packageRequireTreectrl('2.4.2') . ".\n";
$int->source('../tests/all.tcl');

ok(1);

done_testing();

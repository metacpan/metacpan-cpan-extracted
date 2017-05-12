#use Tk;
use Tcl::pTk;

use Test;
plan tests => 1;

my $mw = MainWindow->new();


my $label = $mw->Label(-text => 'MoveToplevelWindow Test')->pack();

$mw->update;

my $geom = $mw->geometry();

#print "geom = $geom\n";

my ($w,$h,$x,$y) = $geom =~ /(\d+)x(\d+)\+(\d+)\+(\d+)/;



foreach (1..50){
	$mw->MoveToplevelWindow($x++, $y++);
	$mw->after(25);
	$mw->update;
}

foreach (1..50){
	$mw->MoveToplevelWindow($x--, $y--);
	$mw->after(25);
	$mw->update;
}

ok(1);

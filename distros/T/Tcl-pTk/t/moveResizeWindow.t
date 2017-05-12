#use Tk;
use Tcl::pTk;

use Test;

plan test => 1;

my $mw = MainWindow->new();


my $label = $mw->Label(-text => 'MoveResizeWindow Test')->pack();

$mw->update;

my $geom = $mw->geometry();

#print "geom = $geom\n";

my ($w,$h,$x,$y) = $geom =~ /(\d+)x(\d+)\+(\d+)\+(\d+)/;

$mw->after(1000);

$mw->MoveResizeWindow($x+=100, $y+=100, $w+=100, $h+=100);
$mw->update;
$mw->after(1000);

$mw->MoveResizeWindow($x+=100, $y+=100, $w+=100, $h+=100);
$mw->update;
$mw->after(1000);

$mw->MoveResizeWindow($x-=100, $y-=100, $w-=100, $h-=100);
$mw->update;
$mw->after(1000);

$mw->MoveResizeWindow($x-=100, $y-=100, $w-=100, $h-=100);
$mw->update;
$mw->after(1000);

ok(1);

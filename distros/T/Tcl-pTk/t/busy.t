# Test of Busy / UnBusy operation
use strict;
use Tcl::pTk;
#use Tk;
use Test;
plan tests => 1;

my $mw = MainWindow->new;

$mw->Label(-text => "Label1")->pack;
$mw->Label(-text => "Label2")->pack;
$mw->Button(-text => "Label3")->pack;
$mw->Entry(-text => "Label4")->pack;

$mw->after(1000, sub{ $mw->Busy() });

$mw->after(4000, sub{ $mw->Unbusy() });

$mw->after( 7000, sub{ $mw->destroy}); # close everything


MainLoop;
			
ok(1, 1, "Busy");


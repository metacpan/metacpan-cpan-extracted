# Test of iconimage method. This method is implemented in Tcl as the iconphoto method,
#  which only exists in Tcl/Tk >= 8.5
use warnings;
use strict;

use Tcl::pTk;

use Test;

my $top = MainWindow->new();

# Skip if Tcl/Tk version is < 8.5
if( $top->interp->Eval('package vcompare $tk_version 8.5') == -1 ){
    print "1..0 # Skipped: iconimage only works for Tcl/Tk >= 8.5\n";
    $top->destroy;
    exit;
}

plan tests => 1;

my $icon = $top->Photo(-file =>  Tcl::pTk->findINC("icon.gif"));

$top->iconimage($icon);

$top->idletasks;
(@ARGV) ? MainLoop : $top->destroy;

ok(1);


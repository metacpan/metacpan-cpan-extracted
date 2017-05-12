# DirTree, display directory tree.

use strict;
use Test;
use Tcl::pTk;

use Tcl::pTk::DirTree;

my $top = MainWindow->new;

# This will skip if Tix not present
my $retVal = $top->interp->pkg_require('Tix');

unless( $retVal){
	plan tests => 1;
        skip("Tix Tcl package not available", 1);
        exit;
}

plan tests => 1;

my $dl  = $top->Scrolled('DirTree')->pack(-expand => 1 , -fill => 'both');

$top->after(1000,sub{$top->destroy});

MainLoop;

ok(1);

# DirTree, display directory tree.

use Tcl::pTk;
use Tcl::pTk::DirTree;
my $top = MainWindow->new;
my $dl  = $top->Scrolled('DirTree')->pack(-expand => 1 , -fill => 'both');
MainLoop;

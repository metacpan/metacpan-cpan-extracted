# This a check of frame widget creation with different combinations of the -foreground and Name options
#   The -foreground option for Frame is only valid for perl/tk syntax. This test cases checks to see
#  if Tcl::pTk is compatible.

use Tcl::pTk;
#use Tk;
use Test;

plan tests => 1;

my $TOP = MainWindow->new();


my $frame = $TOP->Frame(Name => 'dude', -borderwidth => 10, -foreground => 'black')->pack;
my $frame2 = $TOP->Frame(-borderwidth => 10, -foreground => 'black')->pack;
my $frame3 = $TOP->Frame(-foreground => 'black')->pack;
my $frame4 = $TOP->Frame(Name => 'dude2')->pack;

$frame->configure(-foreground => 'black');

$frame->Label(-text => "This is a label")->pack();

ok(1, 1, "Frame Widget Creation");






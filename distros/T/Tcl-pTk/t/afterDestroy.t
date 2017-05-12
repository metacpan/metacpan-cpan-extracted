#
# Script to check the destruction of after callbacks after a window is destroyed

#use Tk;
use Tcl::pTk;
use Test;
plan tests=>1;

$| = 1;

my $A = 0;  # This will be 1 if the callback fired after the widget was deleted.

my $mw = MainWindow->new(-title => 'First Window');

my $button0 = $mw->Button(-text => 'Simple Button')->pack();


my $top = $mw->Toplevel(-title => 'Second Window');
my $button1 = $top->Button(-text => 'Simple Button 2')->pack();

$top->after(1000, sub{ $A = 1; #print "Toplevel After Callback\n"
                        });

$mw->after(500, sub{ $top->destroy });


$mw->after(1500, sub{ $mw->destroy });

MainLoop;

ok($A, 0, "After Callback Destruction");

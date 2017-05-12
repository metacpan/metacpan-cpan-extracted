# Balloon, pop up help window when mouse lingers over widget.

use Tcl::pTk;
#use Tk;
#use English;
use Carp;

use Test;
plan tests => 2;


my $top = MainWindow->new;

my $menubar = $top->Frame(qw/-relief raised -background DarkGreen -bd 2/);
$menubar->pack(-side => 'top', -fill => 'x');


# create the widgets to be explained
my $mb = $menubar->Menubutton(-relief => 'raised',
			  -text => 'Menu button')->pack(-side => 'left');
                          

# Check that cget works for something other than -menu                          
my $menubg = $mb->cget(-bg);
ok(defined($menubg));
#print "Menubg = $menubg\n";


# Set the menu of the menubutton to something else
#   then check to see if we are adding items to this non-default menu
my($menu) = $mb->Menu(-tearoff => 0);
$mb->configure(-menu => $menu);

my $mbMenu = $mb->cget(-menu);
#print "Menub menu = $mbMenu\n";

$mb->command(-label => 'command1');
$mb->command(-label => 'command2');

my $last = $mbMenu->index('last');

ok( $last, 1, 'Unexpected number of menu entries');

#MainLoop;



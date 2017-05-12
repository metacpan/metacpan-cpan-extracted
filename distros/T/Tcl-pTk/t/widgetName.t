# Test of using the Name option for different widgets
#
#

use Tcl::pTk;
#require Tcl::pTk::Menu;
#require Tcl::pTk::Menu::Item;
#use Tk;
#use English;
use Carp;

use Test;
plan tests => 2;

# Force stack trace for any errors
#local $SIG{__DIE__} = \&Carp::confess;


my $toplevel = MainWindow->new;
my $TOP = $toplevel;

my $menubar = $toplevel->Menu(-type => 'menubar', -tearoff => 0);

my $button = $TOP->Button(Name => 'Hey dudeA');    
#print "button pathname = ".($button->PathName)."\n";

# Check the pathname
my $pathname = $button->PathName();
my $widgetOnly = $pathname;
$widgetOnly =~ s/\.//;
$widgetOnly =~ s/\d+//;
ok( $widgetOnly, 'hey_dudeA');

my $menu = $menubar->Menu(Name => 'Hey dude', -tearoff => 0);

$pathname = $menu->PathName();
#print "menu pathname = ".($menu->PathName)."\n";
$widgetOnly = $pathname;
$widgetOnly =~ s/\.menu\d+\.//;
$widgetOnly =~ s/\d+//;
ok( $widgetOnly, 'hey_dude');


MainLoop if(@ARGV); # For debugging, stay in the mainloop if anything on the commandline



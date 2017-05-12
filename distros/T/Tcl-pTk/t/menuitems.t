# Menu Item Tests
#
#

use Tcl::pTk;
#require Tcl::pTk::Menu;
#require Tcl::pTk::Menu::Item;
#use Tk;
#use English;
use Carp;

use Test;
plan tests => 14;

# Force stack trace for any errors
#local $SIG{__DIE__} = \&Carp::confess;

my $lmsg = "";

my $top = MainWindow->new;

# create the widgets to be explained
my $mb = $top->Menubutton(-relief => 'raised',
                -text => 'Menu button')->pack;

my $menuclass = ref($mb->menu);
#print "menu class = $menuclass\n";

############# Menubutton Tests ########################
# check the classnames of the items created from the menubutton
my $cb = $mb->checkbutton(-label => 'checkbutton',
                 -variable => \$xxx);
#print "Checkbutton = $cb\n";
ok(ref($cb), $menuclass."::Checkbutton", "Checkbutton classname");


my $rb = $mb->radiobutton(-label => 'radiobutton');
#print "radiobutton = $rb\n";
ok(ref($rb), $menuclass."::Radiobutton", "Radiobutton classname");

my $cm = $mb->command(-label => 'command');
#print "command = $cm\n";
ok(ref($cm), $menuclass."::Button", "Command classname");

my $cas = $mb->cascade(-label => 'cascade entry');
#print "cascasde = $cas\n";
ok(ref($cas), $menuclass."::Cascade", "Cascade classname");

my $sep = $mb->separator();
#print "cascasde = $cas\n";
ok(ref($sep), $menuclass."::Separator", "Separator classname");

# Check that cget/configure works on items
my $label = $rb->cget(-label);
#print "radiobutton label = '$label'\n";
ok($label, 'radiobutton', "Radiobutton cget call");

$rb->configure(-label => 'Radiobutton2');
$label = $rb->cget(-label);
#print "radiobutton label = '$label'\n";
ok($label, 'Radiobutton2', "Radiobutton cget call2");

############# Menu Tests ########################
# check the classnames of the items created from the menubutton
$mb = $top->Menu();
$cb = $mb->checkbutton(-label => 'checkbutton',
                 -variable => \$xxx);
#print "Checkbutton = $cb\n";
ok(ref($cb), $menuclass."::Checkbutton", "Checkbutton classname");


$rb = $mb->radiobutton(-label => 'radiobutton');
#print "radiobutton = $rb\n";
ok(ref($rb), $menuclass."::Radiobutton", "Radiobutton classname");

$cm = $mb->command(-label => 'command');
#print "command = $cm\n";
ok(ref($cm), $menuclass."::Button", "Command classname");

$cas = $mb->cascade(-label => 'cascade entry');
#print "cascasde = $cas\n";
ok(ref($cas), $menuclass."::Cascade", "Cascade classname");

$sep = $mb->separator();
#print "cascasde = $cas\n";
ok(ref($sep), $menuclass."::Separator", "Separator classname");

# Check that cget/configure works on items
$label = $rb->cget(-label);
#print "radiobutton label = '$label'\n";
ok($label, 'radiobutton', "Radiobutton cget call");

$rb->configure(-label => 'Radiobutton2');
$label = $rb->cget(-label);
#print "radiobutton label = '$label'\n";
ok($label, 'Radiobutton2', "Radiobutton cget call2");

$top->after(500, sub{ $top->destroy}) unless(@ARGV); # For debugging, stay in the mainloop if anything on the commandline

MainLoop;



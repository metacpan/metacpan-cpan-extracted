# This is a test of the BrowseEntry widget, a standard perl/tk megawidget


#use Tcl::pTk;
use strict;
use Test;

#
#  Simple use of Tcl::pTk::TkHijack and TkFacelift with a BrowseEntry
#  Putting this at the top of a simple perl/tk script is all that needs to be done
#   to make it work with Tcl::pTk

use Tcl::pTk::TkHijack;
use Tcl::pTk::Facelift;


use Tk;
use Tk::BrowseEntry;


$| = 1;

my $top = MainWindow->new();

# This will skip if Tile widgets not available
my $tclVersion = $top->tclVersion;
unless( $tclVersion > 8.4 ){
        plan tests => 1;
        skip("Tile Tests on Tcl version < 8.5", 1);
        exit;
}
 
# This will skip if Tix not present
my $retVal = $top->interp->pkg_require('Tix');

unless( $retVal){
	plan tests => 1;
        skip("Tix Tcl package not available", 1);
        exit;
}

plan tests => 3;


my $option;

my $be = $top->BrowseEntry(-variable => \$option )->pack(-side => 'right');
$be->insert('end',qw(one two three four));


$be->pack(-side => 'top', -fill => 'x', -expand => 1);


ok(1, 1, "BrowseEntry Widget Creation");
   
my @choice2 = $be->get( qw/0 end/);
ok(@choice2, 4, "get returns list context");

# Do some ttkBrowseEntry-specific calls. These should work if hijack and
#  facelift has replaced Tk::BrowseEntry with a Tcl::pTk::ttkBrowseEntry
$be->set('two');
my $choice = $be->choiceget();
ok($choice, 'two', "ttkBrowseEntry subsitution check");

$top->after(1000,sub{$top->destroy});

MainLoop;

#print "Option = $option\n" if (defined($option));





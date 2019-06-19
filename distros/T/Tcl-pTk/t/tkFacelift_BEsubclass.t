# This is a empty subclass test of the BrowseEntry widget with Facelift

use warnings;
use strict;
use Test;



############# Empty subclass test ####################

package Tcl::pTk::Browse2;


use base qw/Tcl::pTk::BrowseEntry/;


Construct Tcl::pTk::Widget 'Browse2';


1;

############################################################


package main;

use Tcl::pTk;

use Tcl::pTk::Facelift;

$| = 1;

my $top = MainWindow->new();

# This will skip if Tile widgets not available
my $tclVersion = $top->tclVersion;
unless( $tclVersion > 8.4 ){
    print "1..0 # Skipped: Tile Tests on Tcl version < 8.5\n";
    exit;
}
 
# This will skip if Tix not present
my $retVal = $top->interp->pkg_require('Tix');

unless( $retVal){
    print "1..0 # Skipped: Tix Tcl package not available\n";
    exit;
}

plan tests => 2;


my $option;


my $be = $top->BrowseEntry(-variable => \$option )->pack(-side => 'right');
$be->insert('end',qw(one two three four));

#print "be = ".ref($be)."\n";

$be->pack(-side => 'top', -fill => 'x', -expand => 1);
my @components0 = $be->children();
#print "'".join("', '", @components0)."'\n";

# A Face-lifted browseentry should have only 1 component
ok(scalar(@components0), 1, "Facelifted BrowseEntry Components = 1");



my $be2 = $top->Browse2(-variable => \$option )->pack(-side => 'right');
$be2->insert('end',qw(one two three four));

#print "be2 = ".ref($be2)."\n";
my @components = $be2->children();
#print join(", ", @components)."\n";

# A Face-lifted browseentry-subclass should also have only 2 components
ok(scalar(@components), 1, "Facelifted BrowseEntry Subclass Components = 1");

$be2->pack(-side => 'top', -fill => 'x', -expand => 1);


MainLoop if(@ARGV); # For debugging only, enter the mainloop if args supplied on the command line



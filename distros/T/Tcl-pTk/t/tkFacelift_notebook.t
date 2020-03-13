# Notebook, selectable pages.

use warnings;
use strict;
use Test;

#
#  Simple use of Tcl::pTk::TkHijack and TkFacelift with a NoteBook
#  Putting this at the top of a simple perl/tk script is all that needs to be done
#   to make it work with Tcl::pTk

use Tcl::pTk::TkHijack;
use Tcl::pTk::Facelift;

#use Tcl::pTk;
use Tk;
use Tk::NoteBook;

my $top = MainWindow->new();

# This will skip if Tile widgets not available
unless ($Tcl::pTk::_Tile_available) {
    print "1..0 # Skipped: Tile unavailable\n";
    $top->destroy;
    exit;
}
 
plan tests => 13;


my $name = "Rajappa Iyer";
my $email = "rsi\@netcom.com";
my $os = "Linux";

use vars qw($top);




my $n;
# The current example uses a DialogBox, but you could just
# as easily not use one... replace the following by
# $n = $top->NoteBook(-ipadx => 6, -ipady => 6);
# Of course, then you'd have to take care of the OK and Cancel
# buttons yourself. :-)
$n = $top->NoteBook(-ipadx => 6, -ipady => 6);

my $address_p = $n->add("address", -label => "Address", -underline => 0);
my $pref_p = $n->add("pref", -label => "Preferences", -underline => 0);

$address_p->LabEntry(-label => "Name:             ",
     -labelPack => [-side => "left", -anchor => "w"],
     -width => 20,
     -textvariable => \$name)->pack(-side => "top", -anchor => "nw");
$address_p->LabEntry(-label => "Email Address:",
     -labelPack => [-side => "left", -anchor => "w"],
     -width => 50,
     -textvariable => \$email)->pack(-side => "top", -anchor => "nw");
$pref_p->LabEntry(-label => "Operating System:",
     -labelPack => [-side => "left"],
     -width => 15,
     -textvariable => \$os)->pack(-side => "top", -anchor => "nw");
$n->pack(-expand => "yes",
         -fill => "both",
         -padx => 5, -pady => 5,
         -side => "top");

# Check pages
my @pages = $n->pages;
#print "pages ".join(",", @pages)."\n";
ok( join(",", @pages), 'address,pref', "pages method check");

@pages = $n->info('pages');
#print "pages ".join(",", @pages)."\n";
ok( join(",", @pages), 'address,pref', "info(pages) method check");

$top->update;

# Raised widget should be the first one added
my $raised = $n->raised;
ok( $raised, "address", "raised method check");

my $focus = $n->info('focus');
#print "pages ".join(",", @pages)."\n";
ok( $focus, 'address', "info(focus) method check");

$focus = $n->info('focusnext');
#print "pages ".join(",", @pages)."\n";
ok( $focus, 'pref', "info(focusnext) method check");

$focus = $n->info('focusprev');
#print "pages ".join(",", @pages)."\n";
ok( $focus, 'pref', "info(focusprev) method check");

$focus = $n->info('active');
#print "pages ".join(",", @pages)."\n";
ok( $focus, 'address', "info(active) method check");

if ($n->_identify_unavailable) {
    skip 'identify method requires Tcl/Tk 8.5.9 or later, '
       . 'or Tile 0.8.4.0 for Tcl/Tk 8.4';
} else {
    my $identify = $top->windowingsystem ne 'aqua'
      ? $n->identify(10,10)
      : $n->identify(230,20) # tabs are centered on macOS aqua
    ;
    #print "pages ".join(",", @pages)."\n";
    ok( $identify, 'address', "identify method check");
}

# Raised widget should be the first one added
$n->raise('pref');
$raised = $n->raised;
ok( $raised, "pref", "raise method check");

$n->pageconfigure('pref', -state => 'disabled');
my $pagestate = $n->pagecget('pref', -state );
ok( $pagestate, 'disabled', "pageconfigure method check");
$n->pageconfigure('pref', -state => 'normal');

my $pagewidget = $n->page_widget("address");
ok( ref($pagewidget), ref($address_p), "pagewidget method check");

 
# delete a tab
$n->delete('address');
@pages = $n->pages;
#print "pages ".join(",", @pages)."\n";
ok( join(",", @pages), 'pref', "delete method check");

$top->after(2000, 
        sub{
                my $itab = $n->add("imageTab", -image => $n->Getimage("folder"));
                $itab->LabEntry(-label => "FolderName:             ",
                     -labelPack => [-side => "left", -anchor => "w"],
                     -width => 20,
                     )->pack(-side => "top", -anchor => "nw");
                     ok(1);
        }
        );
                    

$top->after(3000,
        sub{
               $top->destroy;
        });

MainLoop;



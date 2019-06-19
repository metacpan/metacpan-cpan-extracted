#  Simple use of Tcl::pTk::TkHijack and TkFacelift
#  Putting this at the top of a simple perl/tk script is all that needs to be done
#   to make it work with Tcl::pTk

use warnings;
use strict;
use Tcl::pTk::TkHijack;
use Tcl::pTk::Facelift;

use Tk;
use Tk::Tree;

use Test;

my $top = MainWindow->new( -title => "Hijack Test" );

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

plan tests => 1;

#my $tree = $top->Scrolled( qw/Tree -separator \ -exportselection 1 
#                           -scrollbars osoe / );

my $tree = $top->Tree( qw/ -separator \  /);
$tree->pack( qw/-expand yes -fill both -padx 10 -pady 10 -side top/ );

my @directories = qw( C: C:\Dos C:\Windows C:\Windows\System );

foreach my $d (@directories) {
    my $text = (split( /\\/, $d ))[-1]; 
    $tree->add( $d, -text => $text, -image => $tree->Getimage("folder") );
}

$tree->configure( -command => sub { print "@_\n" } );

# The tree is fully expanded by default.
$tree->autosetmode();
my @bindtags = $tree->bindtags();
#print "bindtags = ".join(", ", @bindtags)."\n";

my $ok = $top->Button( qw/-text Ok -underline 0 -width 6/,
                       -command => sub { exit } );
my $cancel = $top->Button( qw/-text Cancel -underline 0 -width 6/,
                           -command => sub { exit } );

$ok->pack(     qw/-side left  -padx 10 -pady 10/ );
$cancel->pack( qw/-side right -padx 10 -pady 10/ );

$top->after(1000,sub{$top->destroy});

MainLoop();

ok(1);

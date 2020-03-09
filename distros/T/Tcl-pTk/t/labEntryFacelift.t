# slide.pl

use warnings;
use strict;

use Tcl::pTk;
use Tcl::pTk::LabEntry;
use Tcl::pTk::Facelift;
use Test;




my $top = MainWindow->new();

# This will skip if Tile widgets not available
unless( $Tcl::pTk::_Tile_available ){
    print "1..0 # Skipped: Tile unavailable\n";
    exit;
}
       

plan tests => 1;

my $entry = "data here";

my $LabEntry = $top->LabEntry(
    -textvariable => \$entry,
    -label => 'Bogus',
    -labelFont=>"Courier 12", # Additional options for testing full functionality
    -labelForeground=>'blue',
    -labelPack => [-side => 'left']);

$LabEntry->pack(-side => 'top', -pady => 2, -anchor => 'w', -fill => 'x', -expand => 1);

$top->idletasks;
(@ARGV) ? MainLoop : $top->destroy; # go away, unless something on command line (debug mode)


ok(1, 1, "LabEntry Facelift Widget Creation");



# slide.pl


use Tcl::pTk;
use Tcl::pTk::LabEntry;
use Tcl::pTk::Facelift;
use Test;
use strict;




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

       

plan tests => 1;

my $entry = "data here";

my $LabEntry = $top->LabEntry(
    -textvariable => \$entry,
    -label => 'Bogus',
    -labelFont=>"Courier 12", # Additional options for testing full functionality
    -labelForeground=>'blue',
    -labelPack => [-side => 'left']);

$LabEntry->pack(-side => 'top', -pady => 2, -anchor => 'w', -fill => 'x', -expand => 1);


$top->after(100,sub{$top->destroy}) unless(@ARGV); # go away, unless something on command line (debug mode)

MainLoop;


ok(1, 1, "LabEntry Facelift Widget Creation");



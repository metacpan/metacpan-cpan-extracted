# slide.pl


use Tcl::pTk;
use Tcl::pTk::LabEntry;
use Test;
use strict;

plan tests => 1;



my $top = MainWindow->new();

my $entry = "data here";

my $LabEntry = $top->LabEntry(
    -textvariable => \$entry,
    -label => 'Bogus',
    -labelFont=>"Courier 12", # Additional options for testing full functionality
    -labelForeground=>'blue',
    -labelPack => [-side => 'left']);

$LabEntry->pack(-side => 'top', -pady => 2, -anchor => 'w', -fill => 'x', -expand => 1);


# Update text by updating variable
$top->after(1000, sub{ $entry = "More Data Here"});

$top->after(2000,sub{$top->destroy});

MainLoop;


ok(1, 1, "LabEntry Widget Creation");



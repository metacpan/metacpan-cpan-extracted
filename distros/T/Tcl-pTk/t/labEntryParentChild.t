# This is a test of parent/child widget relationships in a
#  megawidget (the LabEntry widget)


use Tcl::pTk;
use Tcl::pTk::BrowseEntry;
#use Tk;
#use Tk::BrowseEntry;
use strict;
use Test;

plan tests => 4;

$| = 1;

my $debug = shift @ARGV; # enter 1 on the command line for debug messages

my $top = MainWindow->new();


my $label = $top->Label();

my $labEntry = $top->LabEntry( -label => 'labentry')->pack();

# Get the entry subwidget:
my $LE_entry = $labEntry->Subwidget('entry'); # Entry subwidget

# The following label method should cause a Label to be created as a child 
#  of the delegated DEFAULT entry widget, NOT created as a parent of the LabEntry.
$label = $labEntry->Label();

print "label id = ".$label->PathName."\n" if($debug);
print "top children = ".join(", ", map $_->PathName, $top->children)."\n" if($debug);
print "labEntry children = ".join(", ", map $_->PathName, $labEntry->children)."\n" if($debug);
print "LabEntry Entry subwidget id = ".$LE_entry->PathName."\n" if($debug);


# Parent of label should be Entry
my $labelParent = $label->parent();
ok($labelParent, $LE_entry, "Unexpected parent of label");
print "labelParent = ".$label->parent()->PathName."\n" if($debug);

# Unlike the above label, the label subwidget of the labEntry should be a child
#   of the labEntry, NOT the Entry widget. This is achieved in the Tcl::pTk::Frame code
#  by calling $labEntry->Tcl::pTk::Label, instead of calling $labEntry->Label.
my $LElabel = $labEntry->Subwidget('label');
my $LElabelParent = $LElabel->parent();
ok($LElabelParent, $labEntry, "Unexpected parent of LElabel");
print "labelParent = ".$LElabelParent->PathName."\n" if($debug);
print "labEntry label = ".$LElabel->PathName."\n" if($debug);

# Packslaves should Not get delegated to the Default (entry) widget
my @slaves = $labEntry->packSlaves();
print "LabEntry pack slaves = ".join(", ", @slaves)."\n" if($debug);
ok(scalar(@slaves), 2, "Unexpected number of pack slaves");

# Packslaves should all be widget refs (not just pathnames)
my @widgetRefs = grep ref($_), @slaves;
ok( scalar(@widgetRefs), 2 , "Check for widget refs return from packSlaves");

MainLoop if($debug);



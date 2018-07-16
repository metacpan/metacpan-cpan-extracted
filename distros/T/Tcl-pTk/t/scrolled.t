#!/usr/local/bin/perl -w

use Tcl::pTk;

#use Tk;
use strict;
use Test;

plan tests => 2;

my $debug = shift @ARGV; # enter 1 on the command line for debug messages


my @data = map "Line".$_, (1..20);
my $TOP = MainWindow->new();
# $top->optionAdd('*Scrollbar.width' => '3.5m');


my $lb  = $TOP->Scrolled('Listbox', -width => 20);
$lb->insert('end',@data);
$lb->pack(-side => 'left', -expand => 1, -fill => 'both'  );

# Check to see if a widget created from the scrolled widget
#   is created as a child of the real widget 
my $realLB = $lb->Subwidget('scrolled');
my $label = $lb->Label();
my $labelParent = $label->parent();
print "scrolled widget id = ".$lb->PathName()."\n" if($debug);
print "ListBox id = ".$realLB->PathName()."\n"  if($debug);
print "label id = ".$label->PathName."\n" if($debug);
print "label Parent = ".$labelParent->PathName()."\n" if($debug);

ok($labelParent, $realLB, "Unexpected parent of label");


$TOP->after(1000,sub{$TOP->destroy});

ok(1, 1, "Scrolled Widget Creation");


MainLoop();

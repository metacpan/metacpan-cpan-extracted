# This test checks to see if loading a library (in this case 'tix') happens for
#   different tcl interpreters.

use warnings;
use strict;
use Tcl::pTk;
use Data::Dumper;
use Test;


#### Create a Mainwindow (and a interpreter) and create an Hlist ####
###   Creating an hlist will cause the tix library to load for this interp ###
my $mw = MainWindow->new;
$|=1;

# This will skip if Tix not present
my $retVal = $mw->interp->pkg_require('Tix');

unless( $retVal){
    print "1..0 # Skipped: Tix Tcl package not available\n";
    exit;
}

plan tests => 1;

my $hl = $mw->HList( -separator => '.', -width => 25,
                        -drawbranch => 1,
                        -selectmode => 'extended', -columns => 2,
                        -indent => 10);


$hl->pack(-expand => 1, -fill => 'both');

my @list = qw(one two three);

my $i = 0;
foreach my $item (@list)
 {
  $hl->add($item, -itemtype => 'text', -text => $item, -data => {});
  my $subitem;
  foreach $subitem (@list)
   {
    $hl->addchild($item, -itemtype => 'text', -text => $subitem, -data => []);
   }
 }

$mw->after(1000, sub{ $mw->destroy});

MainLoop;

#### Create another Mainwindow (and a interpreter) and create an Hlist ####
###   Creating an hlist will cause the tix library to load for this interp ###

$mw = MainWindow->new;


#$hl = $mw->Scrolled('HList', -separator => '.', -width => 25,
$hl = $mw->HList( -separator => '.', -width => 25,
                        -drawbranch => 1,
                        -selectmode => 'extended', -columns => 2,
                        -indent => 10);


$hl->pack(-expand => 1, -fill => 'both');

@list = qw(one two three);

$i = 0;
foreach my $item (@list)
 {
  $hl->add($item, -itemtype => 'text', -text => $item, -data => {});
  my $subitem;
  foreach $subitem (@list)
   {
    $hl->addchild($item, -itemtype => 'text', -text => $subitem, -data => []);
   }
 }

$mw->after(1000, sub{ $mw->destroy});

MainLoop;

ok(1);  # If we got this far, the test passed

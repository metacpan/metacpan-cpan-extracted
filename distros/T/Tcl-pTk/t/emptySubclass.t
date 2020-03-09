# This is a empty subclass test of the BrowseEntry widget

use warnings;
use strict;

use Test;
plan tests => 1;


############# Empty subclass test ####################

package Tcl::pTk::Browse2;


use base qw/Tcl::pTk::BrowseEntry/;


Construct Tcl::pTk::Widget 'Browse2';


1;

############################################################


package main;

use Tcl::pTk;


$| = 1;

my $top = MainWindow->new();

my $option;

my $be = $top->Browse2(-variable => \$option )->pack(-side => 'right');
$be->insert('end',qw(one two three four));


$be->pack(-side => 'top', -fill => 'x', -expand => 1);

$top->idletasks;
(@ARGV) ? MainLoop : $top->destroy;

ok(1, 1, "Empty SubWidget Widget Creation");
   

print "# Option = $option\n" if (defined($option));



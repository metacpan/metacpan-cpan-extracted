# This is a test of the BrowseEntry widget, a standard perl/tk megawidget

use warnings;
use strict;
use Tcl::pTk;
use Test;
use Tcl::pTk::BrowseEntry;

plan tests => 2;

$| = 1;

my $top = MainWindow->new();

my $option;

my $be = $top->BrowseEntry(-variable => \$option )->pack(-side => 'right');
$be->insert('end',qw(one two three four));


$be->pack(-side => 'top', -fill => 'x', -expand => 1);

$top->idletasks;
ok(1, 1, "BrowseEntry Widget Creation");
   
my @choice2 = $be->get( qw/0 end/);
ok(@choice2, 4, "get returns list context");

(@ARGV) ? MainLoop : $top->destroy;

print "# Option = $option\n" if (defined($option));

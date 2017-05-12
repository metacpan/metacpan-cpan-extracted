# xevent.pl

use strict;
use Test;
use Tcl::pTk;  

plan tests => 1;

my $textVar = "Initial Value";

my $TOP = MainWindow->new();

    my(@relief) = qw/-relief sunken/;
    my(@pl) = qw/-side top -padx 10 -pady 5 -fill x -expand 1/;
    my $e1 = $TOP->Entry(@relief, -textvariable => \$textVar)->pack(@pl);
    my $e2 = $TOP->Entry(@relief)->pack(@pl);
    my $e3 = $TOP->Entry(@relief)->pack(@pl);

    $e2->insert('end', 'This entry contains a long value, much too long to fit in the window at one time, so long in fact that you\'ll have to scan or scroll to see the end.');


my $e = $e1->XEvent();

my $x = $e->x();
my $y = $e->y();
#print "x/y = $x/$y\n";
    
$TOP->after(1000,sub{$TOP->destroy});

ok(1, 1, "XEvent usage");


MainLoop;

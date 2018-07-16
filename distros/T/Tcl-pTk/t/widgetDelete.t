#!/usr/local/bin/perl -w

# Test Case that checks for widgets getting destroyed if WIDGET_CLEANUP active)
#   
use Test;
plan tests => 1;

use Tcl::pTk;

my $destroyed;

unless( Tcl::pTk::WIDGET_CLEANUP ){
        skip("Widget Cleanup not enabled", 1);
        exit;
}

$| = 1; # Pipes Hot
my $top = MainWindow->new;


my $label = $top->Label(-text => "Mainwindow")->pack();
{
        my $toplevel = $top->Toplevel();
        
        my $button = $toplevel->Button( -text => "Exit", -command => 
                sub{ $toplevel->destroy;
                     })->pack;	
        
        $toplevel->after(1000, 
                sub{ $toplevel->destroy;
                ok( $destroyed, 1, "Buttons Properly Destroyed");
                }); # delete after 1 second

}
$top->after(2000, sub{ $top->destroy});


MainLoop;

sub Tcl::pTk::Button::DESTROY{
        my $self = shift;
        $destroyed = 1;
        #print "In destroy\n";
 }

        


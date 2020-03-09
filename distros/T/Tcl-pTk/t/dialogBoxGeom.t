# Test Case that demonstrates the dialog placement problem with DialogBox
#   For dual monitor cases on windows 7 with primary screen right and secondary screen left,
#   running this case should put the dialog at the center of the current screen (right screen),
#   however it actually makes a very large X screen value and places the dialog well off the 
#   right of the screen.

use warnings;
use strict;

#use Tk;
#use Tk::Dialog;

use Tcl::pTk;
use Test;

use Tcl::pTk::widgets qw/DialogBox/; # Test the widgets package for loading modules
#use Tk::widgets qw/DialogBox/; # Test the widgets package for loading modules

plan tests => 2;

my $top = MainWindow->new(-title => 'Dialog Test');


 my $t = $top->DialogBox(
        -title          => "Test Dialog Box",
#        -text           => "This is a test dialog",
        -default_button => 'OK',
        -buttons        => ['OK'],
    );
 
$t->add( 'Label', -text => 'This is a test of the DialogBox widget')->pack();

my $okbutton = $t->Subwidget('B_OK');

$top->after(2000, sub{
   my $geom = $top->geometry();
    #print "top geometry = $geom\n";
    #print "Top vrootX = ".$top->vrootx()."\n";

    
   $t->Show();
   $geom = $t->geometry();
   # print "dialog geometry = '$geom'\n";
    $geom =~ /^(\d+)x(\d+)\+(\d+)\+(\d+)/;
    my ($w, $h, $x, $y) = ($1, $2, $3, $4); 

    # Get screen width and height
    my $rw = $top->screenwidth;
    my $rh = $top->screenheight;
    
    # Check to see if x/y dialog is within screen width
    if( $rw < $x ){
            ok(0);
    }
    else{
            ok(1);
    }

    if( $rh < $y ){
            ok(0);
    }
    else{
            ok(1);
    }
            
    #print "x/y = $x, $y\n";
    
    

   
});

$t->after(4000, sub{    $okbutton->invoke(); }        );

$t->after(5000, sub{    $top->destroy }        );

MainLoop;





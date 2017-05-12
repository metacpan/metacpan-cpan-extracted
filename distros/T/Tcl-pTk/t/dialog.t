
#use Tk;
#use Tk::Dialog;

use strict;
use Tcl::pTk;
use Tcl::pTk::Dialog;


use Test;
plan tests => 1;


my $top = MainWindow->new(-title => 'Dialog Test');


 my $t = $top->Dialog(
        -title          => "Test Dialog Box",
        -text           => "This is a test of the Dialog widget",
        -default_button => 'OK',
        -buttons        => ['OK'],
    );
 
#$t->add( 'Label', -text => 'This is a test of the DialogBox widget')->pack();

my $okbutton = $t->Subwidget('B_OK');

# This seems to be required for the events to be reliabily registered for this test case outside of a MainLoop
foreach (1..10){
        $top->update();
        $top->idletasks();
}


$t->repeat(100,
        sub{
                if( ! $t->ismapped ){
                        $top->update;
                        $top->idletasks;
                }
                else{
                        $okbutton->invoke();
                }
        }
        );


 $t->Show();

ok(1);



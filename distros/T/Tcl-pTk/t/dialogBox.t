
#use Tk;
#use Tk::Dialog;

use strict;
use Tcl::pTk;
use Test;

use Tcl::pTk::widgets qw/DialogBox/; # Test the widgets package for loading modules

plan tests => 1;

my $top = MainWindow->new(-title => 'Dialog Test');


 my $t = $top->DialogBox(
        -title          => "Test Dialog Box",
#        -text           => "This is a test dialog",
        -default_button => 'OK',
        -buttons        => ['OK'],
    );
 
$t->add( 'Label', -text => 'This is a test of the DialogBox widget')->pack();

my $okbutton = $t->Subwidget('B_OK');

$t->after(2000, 
        sub{
                
                $okbutton->invoke();
        }
        );

 $t->Show();

ok(1);



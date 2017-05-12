
#use Tk;
#use Tk::Dialog;

use strict;
use Tcl::pTk;
use Test;

$Tcl::pTk::DEBUG = 1;

plan tests => 1;

my $top = MainWindow->new(-title => 'MessageBox Test');


# We use a convoluted way of exiting here without interaction, because
#  of different behavior on win32 vs linux
$top->after(1000, 
        sub{
                if( $^O !~ /mswin/i ){
                        ok(1); 
                        exit(); # No using $top->destroy here, because we get grab error messages on linux
                                #  But if we use this on windows, we get crashes.

                }
                else{
                        $top->destroy(); # This works without errors on windows
                }
        }
);


my $ans = $top->messageBox(-icon    => 'warning',
                           -title => 'MessageBox Test',
                            -type => 'YesNoCancel', -default => 'Yes',
                            -message =>
"MessageBox Test");



ok(1);

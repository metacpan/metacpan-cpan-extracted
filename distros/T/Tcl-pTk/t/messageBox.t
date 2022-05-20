
#use Tk;
#use Tk::Dialog;

use warnings;
use strict;
use Tcl::pTk;
use Test;

$Tcl::pTk::DEBUG = 1;

plan tests => 1;

my $top = MainWindow->new(-title => 'MessageBox Test');

if ($top->windowingsystem eq 'aqua') {
        skip('See https://github.com/chrstphrchvz/perl-tcl-ptk/issues/25');
        $top->idletasks;
        $top->destroy;
        exit;
}

# We use a convoluted way of exiting here without interaction, because
#  of different behavior on win32 vs X11
$top->after(1000, 
        sub{
                if( $top->windowingsystem eq 'x11' ){
                        # No using $top->destroy here, because we get grab error messages on X11
                        my $msgbox = $top->interp->widget(
                                '.__tk__messagebox',  # implementation detail; see msgbox.tcl
                                'Tcl::pTk::Toplevel',
                        );
                        $msgbox->destroy;
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

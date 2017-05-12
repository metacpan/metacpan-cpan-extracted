# ProgressBar - display various progress bars.

use strict;
use Tcl::pTk;
use Tcl::pTk::ProgressBar;
#use Tk::Scale;

use Test;

plan test => 1;

my $mw = MainWindow->new;

my $status_var = 0;

my($fromv,$tov) = (0,100);
my $res = 0;
my $blks = 10;
 
$mw->ProgressBar(
    -borderwidth => 2,
    -relief => 'sunken',
    -width => 20,
    -padx => 2,
    -pady => 2,
    -variable => \$status_var,
    -colors => [0 => 'green', 50 => 'yellow' , 80 => 'red'],
    -resolution => $res,
    -blocks => $blks,
    -anchor => 'n',
    -from => $fromv,
    -to => $tov
)->pack(
    -padx => 10,
    -pady => 10,
    -side => 'top',
    -fill => 'y',
    -expand => 1
);


$mw->repeat(100, sub{
                $status_var+=10;
                if( $status_var > 100){
                        $mw->destroy;
                }
});

MainLoop;

ok(1);

# Test to make sure configure with no-args returns a 2-d array (or nothing) for
#   a large set of widgets

use warnings;
use strict;

use Tcl::pTk;
use Tcl::pTk::widgets('TextUndo');
use Test;

plan tests => 20;

my $mw = MainWindow->new;
$|=1;

my @widgets = ( qw/ Button Checkbutton  Entry  LabelFrame Label 
        Listbox Message Menu Menubutton Panedwindow Radiobutton Text 
         Scale TextUndo  Frame Scrollbar  Canvas   HList TList NoteBook/);

my $skip;
# See if Tix is present
my $tixFound = $mw->interp->pkg_require('Tix');

foreach my $widgetName (@widgets){
        
        # Check to see if we need to skip Tix widgets
        $skip = 0; # Need to skip 
        if( $widgetName =~ m/^(HList|NoteBook|TList)$/ and not $tixFound ){
                $skip = "$widgetName: Tix package unavailable";
        }
 
        if( $skip ){
                skip($skip);
                next;
        }
        
        my $widget = $mw->$widgetName();
        
        my @configure = $widget->configure();
        
       
        if( @configure == 0 or ref($configure[0])){
                ok(1);  # "Widget $widget configure");
        }
        else{
                ok( 0, 1,   "$widgetName configure doesn't return 2D Array");
        }
}

(@ARGV) ? MainLoop : $mw->destroy;

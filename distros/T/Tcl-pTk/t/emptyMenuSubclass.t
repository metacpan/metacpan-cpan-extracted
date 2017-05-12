# Test to see if a subclass of a auto-loaded widget (Menu) can be created without
#   creating an instance of the auto-loaded widget first


use strict;

use Tcl::pTk;

use Test;

plan tests => 2;

my $mw = MainWindow->new();


my $label = $mw->Button2(-text => 'Button')->pack();

#my $menu = $mw->Menu();
my $popup = $mw->Menu2('-tearoff' => 0);

# -bg option is here to check the translation of -bg to -background in the menu code
$popup->command('-label' => 'Plot Options...', -bg => 'white' );

$popup->command('-label' => 'Label Point' );
$popup->separator;
$popup->command('-label' => 'Dump Data...');

$popup->command('-label' => 'Print...');

my @popconfig = $popup->configure(-popover);
ok( $popconfig[0] eq '-popover'); # check for proper return value from config

$label->bind('<ButtonPress-3>', 
        sub{
                $popup->Popup(-popover => 'cursor', '-popanchor' => 'nw');
        }
        );


$mw->after(2000,sub{$mw->destroy}) unless (@ARGV); # Persist if any args supplied, for debugging


MainLoop;

ok(1);



BEGIN{
        
#### Empty Menu Subclass #####
package Tcl::pTk::Menu2;

@Tcl::pTk::Menu2::ISA = (qw/ Tcl::pTk::Derived Tcl::pTk::Menu/);

Construct Tcl::pTk::Widget 'Menu2';

#### Empty Button Subclass #####
package Tcl::pTk::Button2;

@Tcl::pTk::Button2::ISA = (qw/ Tcl::pTk::Derived Tcl::pTk::Button/);

Construct Tcl::pTk::Widget 'Button2';

}

# Test case that checks for menubar paths correctly refer to the cloned menus that Tk creates
#  when a Menu widget is turned into a menubar. This is needed so that event bindings work correctly
#  on menubar menus.
#  Cloned menus have '#' in the path name.


use Tcl::pTk;
use Test;

plan test => 6;


#################### Empty Subclass of a Toplevel ################
#  Used to check to see if menubars are still ID'ed correctly
#    This is modeled after the WidgetDemo.pm in the demos directory


package dummyToplevel;

use base  'Tcl::pTk::Toplevel';
Construct Tcl::pTk::Widget 'dummyToplevel';


sub Populate {
    my($self, $args) = @_;
    

    $self->SUPER::Populate($args);

    my $demo_frame = $self->Frame;

    $self->Delegates('Construct' => $demo_frame);
    
    return $self;

} # end Populate

################## End of Empty Subclass of a Toplevel ########

package main;

#use Tk;

my $mw;
$mw = MainWindow->new();

$| = 1;

my $menubar = $mw->Menu(-tearoff => 0, -type => 'menubar');

# Path before menu is made part of the toplevel should have no '#' in it.
my $path = $menubar->path;

ok($path, '.menu02');


$mw->configure(-menu => $menubar);

# Path after menu is made part of the toplevel (i.e. cloned by tk) should have a '#' in it.
$path = $menubar->path;

ok($path, '.#menu02');


## Now try with a toplevel ###
my $toplevel = $mw->Toplevel;
$menubar = $toplevel->Menu(-tearoff => 0, -type => 'menubar');

# Path before menu is made part of the toplevel should have no '#' in it.
$path = $menubar->path;

ok($path, '.top03.menu04');

$toplevel->configure(-menu => $menubar);

# Path after menu is made part of the toplevel (i.e. cloned by tk) should have a '#' in it.
$path = $menubar->path;

ok($path, '.top03.#top03#menu04');


######### Now try with a toplevel subclass ############3

$toplevel = $mw->dummyToplevel;
$menubar = $toplevel->Menu(-tearoff => 0, -type => 'menubar');

# Path before menu is made part of the toplevel should have no '#' in it.
$path = $menubar->path;

ok($path, '.top05.f06.menu07');

$toplevel->configure(-menu => $menubar);

# Path after menu is made part of the toplevel (i.e. cloned by tk) should have a '#' in it.
$path = $menubar->path;

ok($path, '.top05.#top05#f06#menu07');








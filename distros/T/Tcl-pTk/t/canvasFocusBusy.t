use warnings;
use strict;

use Test;

BEGIN{ plan tests => 1}

# Test to check for a bug where Tcl::pTk was getting the focus wrong (i.e. not like perl/tk)
#  when a canvas widget was pop-ed up and CanvasFocus was called on it, while Busy was active in another
#  window. 
#  Expected behavior: Canvas should have the focus after button is pressed and Unbusy is called.
#    Behavior before bug fix: Button window had the focus and the Canvas was hidden behind the button window.


#use Tk;
use Tcl::pTk;



my $window = MainWindow->new;
my $button = $window->Button( -text => "Press Me")->pack;

my $focusAfterCanvCreate; # Focus after canvas create. Should be the Canvas;

# Create button and make it create a canvas when pressed. Canvas gets the focus after canvas
#  creation. Button is made Busy during canvas creation and made Unbusy after creation.
$button->configure(        -command =>  sub {
               $button->Busy;
                my $toplevel = $window->Toplevel();

		my $c = $toplevel->Canvas( );
		$c->CanvasFocus;

		$c->pack(-expand => 1, -fill => 'both');

               $button->Unbusy;
               
                $focusAfterCanvCreate = ref($window->focusCurrent);
		#print "focus = $focusAfterCanvCreate\n";


        }
        );

$window->focusForce; # workaround for Tk Aqua 8.5.9

# Invoke the button to start the test case
$window->after(1000, sub{
                $button->invoke();
});

# Check for proper focus
$window->after(2000, sub{
                
                ok($focusAfterCanvCreate, '/Canvas/', "Canvas Object Doesn't have the focus");
                $window->destroy;
});
                
MainLoop;


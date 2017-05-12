# This test case checks to see if pTk doesn't get stuck in a second mainloop.
#   There is a global variable in Tcl::pTk called $inMainLoop that prevents this from happening.
#   Multiple mainloops are encountered in the widget demos when calling up demos like browseentry.pl


use strict;
use Test;
use Tcl::pTk;  

plan tests => 1;

my $passedMainLoop;

my $TOP = MainWindow->new();


# This sets up a second mainloop, similar to loading a standalone script like
#   the widgetTclpTk demo does
$TOP->afterIdle(
	sub{ 

		MainLoop;


		$passedMainLoop = 1;
	}
);

$TOP->afterIdle(

	sub{ 
			ok($passedMainLoop, 1, "Got passed second mainloop");
			$TOP->destroy
 }
);


MainLoop;		


    


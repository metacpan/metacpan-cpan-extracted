# This is the same as multipleMainWindow1, but it destroys the mainwindow in reverse order
#


use Tcl::pTk;
use Test;

plan tests=>2;

my $window1Destroyed;
my $window1 = MainWindow->new;
my $button1 = $window1->Button(-text => 'Window1', 
	-command => 
	sub{
		$window1->destroy;
		$window1Destroyed = 1;
       }
)->pack;

my $wid = $Tcl::pTk::Wpath;

my $window2Destroyed;
my $window2 = MainWindow->new;

my $button2 = $window2->Button(-text => 'Window2', 
	-command => 
	sub{
		$window2->destroy;
		$window2Destroyed = 1;
       }
)->pack;


$window2->afterIdle(sub{ $button1->invoke }); 
$window2->afterIdle(sub{ $button2->invoke }); 

MainLoop;

ok($window1Destroyed, 1);
ok($window2Destroyed, 1);



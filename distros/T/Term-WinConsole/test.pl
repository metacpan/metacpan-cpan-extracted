# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 20 };
use Term::WinConsole;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.


ok($con = Term::WinConsole->new('HELLO',80,25,1,1,'~',1));
ok($con->home());
ok($con->gotoCR(1,1));
ok($index = $con->setWindow('Login',5,5,55,5,1,1,'.'));
ok($con->setActiveWin($index));
ok($con->setWinColor('light red on_black'));
ok($con->resetColor);
ok($con->home);
ok($con->gotoCR(1,2));
ok($con->doCR);
ok($index = $con->setWindow('Connected',7,7,50,6,1,1,'_'));
ok($con->setActiveWin($index));
ok($con->setWinColor('light green on_black'));
ok($con->resetColor);
ok($con->home);
ok($con->setActiveWin(1));
ok($con->setWinTitle('Disconnected'));
ok($con->home);
ok(!defined($con->showWindow));


# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SigAction-SetCallBack.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('SigAction::SetCallBack') };

sub my_hup {return 'HUP'}
sub my_int {return 'INT'}

ok(SigAction::SetCallBack->sig_registry('HUP','my_hup') == 1, 'sig_registry 1');
ok(SigAction::SetCallBack->sig_registry('INT','my_int') == 1, 'sig_registry 2');


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


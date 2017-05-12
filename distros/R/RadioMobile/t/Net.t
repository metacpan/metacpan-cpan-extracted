# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl RadioMobile.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('RadioMobile::Net') };

my $s = new RadioMobile::Net;
$s->reset(14);
is($s->maxfx,148, 'Check maxfx value after reset');
is($s->name,'Net 14','Check name value after reset');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


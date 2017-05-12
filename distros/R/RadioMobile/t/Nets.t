# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl RadioMobile.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('RadioMobile::Nets') };

my $s = new RadioMobile::Nets;
$s->reset(10);
is($s->at(0)->name,'Net  1','Check name value for first element');
is($s->at(9)->name,'Net 10','Check name value for the tenth element');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


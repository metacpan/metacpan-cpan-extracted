# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-RDEP.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;

BEGIN { use_ok('Net::RDEP') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $r = Net::RDEP->new();
ok(defined($r), 'new() works');

$r->Username('joeuser');
is($r->Username, 'joeuser', 'setting parameters works');

# unfortunately, cannot really connect since I don't have a server, user, password
# to use.  The best I can do is test the module's set/gets.

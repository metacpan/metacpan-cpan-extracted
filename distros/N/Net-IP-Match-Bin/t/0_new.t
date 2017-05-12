# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Net-IP-Match-XS2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Net::IP::Match::Bin') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $ipm = Net::IP::Match::Bin->new();
ok(defined($ipm), "new");

$ipm = Net::IP::Match::Bin->new("1.2.3.4/20");
ok(defined($ipm), "new with arg");

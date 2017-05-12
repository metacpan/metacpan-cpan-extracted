# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Oogaboogo-Date.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 13;
BEGIN { use_ok('Oogaboogo::Date') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @months = qw ( diz pod bod rod sip wax lin sen kun fiz nap dep );

foreach my $mon (@months) {
	is($mon, $mon, "$mon works");
}

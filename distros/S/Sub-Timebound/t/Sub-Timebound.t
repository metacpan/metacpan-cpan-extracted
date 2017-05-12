# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Sub-Timebound.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Sub::Timebound') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $good_result = "All is well with function call";

sub fun {
	my $i = shift;
	if ($i =~ /7$/) {
		die "Simulate internal error\n";
	}
	while ($i) {
		$i--;
	}
	return $good_result;
};


my $x = timeboundretry(10,3,5,\&fun,100);
ok(1 == $x->{status}, "Count down 100 to 0 - succeeded");
ok($x->{value} eq $good_result, "Count down 100 to 0 - succeeded");

$x = timeboundretry(10,3,5,\&fun,107);
ok(!$x->{status}, "Count down 107 to 0 - should fail since we are simulating internal error");

$x = timeboundretry(10,3,5,\&fun,-1);
ok(!$x->{status}, "Count down -1 to 0 - should fail since it timesout");


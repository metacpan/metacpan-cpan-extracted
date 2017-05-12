use Test::More tests => 2;
use Net::Jaiku;

SKIP: {
	skip "Please set environment variables JAIKU_USER and JAIKU_KEY to run these tests", 2
		unless $ENV{JAIKU_USER} && $ENV{JAIKU_KEY};

	$jaiku = Net::Jaiku->new(
		username => $ENV{JAIKU_USER},
		userkey  => $ENV{JAIKU_KEY}
	);

	my $test_line = 'Testing Net::Jaiku '.$Net::Jaiku::VERSION;
	ok( $jaiku->setPresence(message => $test_line) );

	diag("Waiting 2 seconds before retrieving");
	sleep 2;

	my $rv = $jaiku->getMyPresence;
	ok( $rv->title eq $test_line );

}

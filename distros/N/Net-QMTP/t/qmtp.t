# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::QMTP;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $i;


#
# test 2; object creation
#
my $qmtp = Net::QMTP->new('server.example.org', 
				DeferConnect	=> 1,
			);
if ($qmtp and ref($qmtp) eq "Net::QMTP") {
	print "ok 2\n";
} else {
	print "not ok 2\n";
}


#
# test 3; check server
#
$i = $qmtp->server();

if ($i and $i eq "server.example.org") {
	print "ok 3\n";
} else {
	print "not ok 3\n";
}


#
# test 4; set and check sender
#
$qmtp->sender('sender@example.org');
$i = $qmtp->sender();

if ($i and $i eq 'sender@example.org') {
	print "ok 4\n";
} else {
	print "not ok 4\n";
}


#
# test 5; do something stupid; call disconnect() even though we're not
#   connected
#
$i = $qmtp->disconnect();

if (!defined($i)) {
	print "ok 5\n";
} else {
	print "not ok 5\n";
}


#
# test 6; set and check recipients
#
$qmtp->recipient('foo@example.org');
$qmtp->recipient('bar@example.org');
$i = $qmtp->recipient();

my($foo, $bar);

TEST_SIX: {
	# $i defined?
	if (!defined($i)) {
		print "not ok 6\n";
		last TEST_SIX;
	}

	# look through list; should get back both addrs we put in
	# and nothing else
	foreach (@{ $i }) {
		if ($_ eq 'bar@example.org') {

			$bar = 1;	

		} elsif ($_ eq 'foo@example.org') {

			$foo = 1;

		} else {
			print "not ok 6\n";
			last TEST_SIX;
		}
	}

	# got both of 'em?
	if ($foo and $bar) {
		print "ok 6\n";
	} else {
		print "not ok 6\n";
	}
}


#
# test 7: clear envelope data
#
$qmtp->new_envelope();

TEST_SEVEN: {
	$i = $qmtp->sender();
	if (defined($i)) {
		print "not ok 7\n";
		last TEST_SEVEN;
	}

	$i = $qmtp->recipient();
	if (scalar( @{ $i } )) {
		print "not ok 7\n";
		last TEST_SEVEN;
	}

	print "ok 7\n";
}

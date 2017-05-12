# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..16\n"; }
END {print "could not load Net::Connection::Sniffer\nnot ok 1\n" unless $loaded;}

use Net::Connection::Sniffer qw(:constants);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

## test 2	check constant values
my %cons = qw(
	INITIALIZE      0
	SEND_dns        1
	SEND_listen     2
	INIT_wFD        3
	RECV_dns        4
	PRINT_dumptxt   5
	CLOSE_wFD       6
	WAS_PURGE       7
	TERMINATE	8
	END_RUN         0
	LISTEN_MSG      1
	DNS_NEEDED      2
	DUMP_REQUEST    3
	DNS_RECEIVE     4
	PURGE           5
);

local *exc;
foreach (sort keys %cons) {
  *exc = $_;
  my $rv = &{*exc};
  print "got: $rv, exp: $cons{$_}\t$_\nnot "
	unless $rv == $cons{$_};
  &ok;
}

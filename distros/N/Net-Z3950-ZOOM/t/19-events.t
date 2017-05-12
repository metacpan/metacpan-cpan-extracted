# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 19-events.t'

use strict;
use warnings;
use Test::More tests => 23;

BEGIN { use_ok('Net::Z3950::ZOOM') };

ok(Net::Z3950::ZOOM::event_str(Net::Z3950::ZOOM::EVENT_CONNECT) eq "connect",
   "connect event properly translated");

my($errcode, $errmsg, $addinfo) = (undef, "dummy", "dummy");

my $options = Net::Z3950::ZOOM::options_create();
Net::Z3950::ZOOM::options_set($options, async => 1);

my $host = "z3950.indexdata.com/gils";
my $conn = Net::Z3950::ZOOM::connection_create($options);
Net::Z3950::ZOOM::connection_connect($conn, $host, 0);
$errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
ok($errcode == 0, "connection to '$host'");

my $val = Net::Z3950::ZOOM::event(1);
ok($val == -1, "non-reference argument rejected");

$val = Net::Z3950::ZOOM::event($conn);
ok($val == -2, "non-array reference argument rejected");

$val = Net::Z3950::ZOOM::event([]);
ok($val == -3, "empty array reference argument rejected");

# The old test for giant array reference can't be done now that the
# corresponding array internal to the glue-code is allocated
# dynamically.
ok(1, "huge array reference argument rejected");

# Test the sequence of events that come from just creating the
# connection: there's the physical connect; the sending the Init
# request (sending the APDU results in sending the data); the
# receiving of the Init response (receiving the data results in
# receiving the APDU); then the END "event" indicating that there are
# no further events on the specific connection we're using; finally,
# event() will return 0 to indicate that there are no events pending
# on any of the connections we pass in.

assert_event_stream($conn, 
		    -(Net::Z3950::ZOOM::EVENT_CONNECT),
		    Net::Z3950::ZOOM::EVENT_SEND_APDU,
		    Net::Z3950::ZOOM::EVENT_SEND_DATA,
		    Net::Z3950::ZOOM::EVENT_RECV_DATA,
		    Net::Z3950::ZOOM::EVENT_RECV_APDU,
		    Net::Z3950::ZOOM::EVENT_END,
		    0);

# Now we need to actually _do_ something, and watch the stream of
# resulting events: issue a piggy-back search.
Net::Z3950::ZOOM::connection_option_set($conn, count => 1);
my $rs = Net::Z3950::ZOOM::connection_search_pqf($conn, "mineral");
$errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
ok($errcode == 0, "search for 'mineral'");

assert_event_stream($conn,
		    Net::Z3950::ZOOM::EVENT_SEND_APDU,
		    Net::Z3950::ZOOM::EVENT_SEND_DATA,
		    -(Net::Z3950::ZOOM::EVENT_RECV_DATA),
		    Net::Z3950::ZOOM::EVENT_RECV_APDU,
		    Net::Z3950::ZOOM::EVENT_RECV_SEARCH,
		    Net::Z3950::ZOOM::EVENT_RECV_RECORD,
		    Net::Z3950::ZOOM::EVENT_END,
		    0);

# Some events, especially RECV_DATA, may randomly occur multiple
# times, depending on network chunking; so if an expected event's
# value is negated, we allow that event to occur one or more times,
# and treat the sequence of repeated events as a single test.
#
sub assert_event_stream {
    my($conn, @expected) = @_;

    my $previousExpected = -1;
    my $expected = shift @expected;
    while (defined $expected) {
	my $val = Net::Z3950::ZOOM::event([$conn]);
	if ($expected == 0) {
	    ok($val == 0, "no events left");
	    $expected = shift @expected;
	    next;
	}

	die "impossible" if $val != 1;
	my $ev = Net::Z3950::ZOOM::connection_last_event($conn);
	next if $previousExpected > 0 && $ev == $previousExpected;

	if ($expected < 0) {
	    $expected = -$expected;
	    $previousExpected = $expected;
	}
	ok($ev == $expected, ("event is $ev (" .
			      Net::Z3950::ZOOM::event_str($ev) .
			      "), expected $expected (" .
			      Net::Z3950::ZOOM::event_str($expected) . ")"));
	$expected = shift @expected;
    }
}

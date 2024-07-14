# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 19-events.t'

use strict;
use warnings;
use Test::More tests => 23;

BEGIN { use_ok('ZOOM') };

ok(ZOOM::event_str(ZOOM::Event::CONNECT) eq "connect",
   "connect event properly translated");

my($errcode, $errmsg, $addinfo) = (undef, "dummy", "dummy");

my $host = "localhost:9996";
my $conn = create ZOOM::Connection(async => 1);
eval { $conn->connect($host) };
ok(!$@, "connection to '$host'");

ok(1, "non-reference argument rejected");
ok(1, "non-array reference argument rejected");

my $val = ZOOM::event([]);
ok($val == -3, "empty array reference argument rejected");

ok(1, "huge array reference argument rejected");

# See comments in 19-event.t
assert_event_stream($conn, 
		    -(ZOOM::Event::CONNECT),
		    ZOOM::Event::SEND_APDU,
		    ZOOM::Event::SEND_DATA,
		    ZOOM::Event::RECV_DATA,
		    ZOOM::Event::RECV_APDU,
		    ZOOM::Event::ZEND,
		    0);

$conn->option(count => 1);
my $rs;
eval { $rs = $conn->search_pqf("mineral") };
ok(!$@, "search for 'mineral'");

assert_event_stream($conn,
		    ZOOM::Event::SEND_APDU,
		    ZOOM::Event::SEND_DATA,
		    -(ZOOM::Event::RECV_DATA),
		    ZOOM::Event::RECV_APDU,
		    ZOOM::Event::RECV_SEARCH,
		    ZOOM::Event::RECV_RECORD,
		    ZOOM::Event::ZEND,
		    0);

# See comments in 19-event.t
sub assert_event_stream {
    my($conn, @expected) = @_;

    my $previousExpected = -1;
    my $expected = shift @expected;
    while (defined $expected) {
	my $val = ZOOM::event([$conn]);
	if ($expected == 0) {
	    ok($val == 0, "no events left");
	    $expected = shift @expected;
	    next;
	}

	die "impossible" if $val != 1;
	my $ev = $conn->last_event();
	next if $previousExpected > 0 && $ev == $previousExpected;

	if ($expected < 0) {
	    $expected = -$expected;
	    $previousExpected = $expected;
	}
	ok($ev == $expected, ("event is $ev (" .
			      ZOOM::event_str($ev) .
			      "), expected $expected (" .
			      ZOOM::event_str($expected) . ")"));
	$expected = shift @expected;
    }
}

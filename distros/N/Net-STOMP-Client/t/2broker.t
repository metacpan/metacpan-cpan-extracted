#!perl

use strict;
use warnings;
use Test::More;

use Net::STOMP::Client;

#
# we try to connect to a real broker over STOMP so we need some information:
#  - PNSCT_URI: STOMP server URI (mandatory)
#  - PNSCT_AUTH: authentication to use (optional)
#  - PNSCT_LOGIN: user name to use (optional)
#  - PNSCT_PASSCODE: password to use (optional)
#  - PNSCT_DESTINATION: destination to send/receive messages (optional)
#
# FWIW: PNSCT = Perl Net-STOMP-Client Test
#

unless ($ENV{PNSCT_URI}) {
    plan skip_all => "A STOMP broker is required for this test, see $0";
}
if ($ENV{PNSCT_DESTINATION}) {
    plan tests => 18;
} else {
    plan tests => 10;
}

use constant TIMEOUT => 10;

our($stomp);

# test new+connect

sub test_connect () {
    my(%option);

    %option = ();
    $option{uri} = $ENV{PNSCT_URI};
    $option{auth} = $ENV{PNSCT_AUTH} if $ENV{PNSCT_AUTH};
    $stomp = Net::STOMP::Client->new(%option);
    ok($stomp, "new");
    ok(!$stomp->session(), "new -> no session");

    %option = ();
    $option{login}    = $ENV{PNSCT_LOGIN}    if defined($ENV{PNSCT_LOGIN});
    $option{passcode} = $ENV{PNSCT_PASSCODE} if defined($ENV{PNSCT_PASSCODE});
    $stomp->connect(%option);
    ok($stomp->session(), "connect");
    is(scalar($stomp->receipts()), 0, "connect -> no receipts");
}

# test disconnect

sub test_disconnect () {
    my(%option);

    %option = ();
    $stomp->disconnect(%option);
    ok(!$stomp->session(), "disconnect");
}

# test begin+abort, with receipts

sub test_noop () {
    my(%option, $tid);

    $tid = $stomp->uuid();
    ok($tid, "uuid");

    %option = ();
    $option{transaction} = $tid;
    $option{receipt} = $stomp->uuid();
    $stomp->begin(%option);
    is(scalar($stomp->receipts()), 1, "begin -> one receipt");

    %option = ();
    $option{timeout} = TIMEOUT;
    $stomp->wait_for_receipts(%option);
    is(scalar($stomp->receipts()), 0, "wait_for_receipts -> no receipts");

    %option = ();
    $option{transaction} = $tid;
    $option{receipt} = $stomp->uuid();
    $stomp->abort(%option);
    is(scalar($stomp->receipts()), 1, "abort -> one receipt");

    %option = ();
    $option{timeout} = TIMEOUT;
    $stomp->wait_for_receipts(%option);
    is(scalar($stomp->receipts()), 0, "wait_for_receipts -> no receipts");
}

# test subscribe+send+unsubscribe, without receipts

sub test_loopback () {
    my(%option, $count, $frame, $subid);

    # use a unique subscription id
    $subid = $stomp->uuid();

    # count the messages
    $count = 0;
    $stomp->message_callback(sub {
	my($self, $frame) = @_;

	$count++;
	return(1);
    });

    %option = ();
    $option{id} = $subid;
    $option{destination} = $ENV{PNSCT_DESTINATION};
    $stomp->subscribe(%option);
    ok(1, "subscribe");

    %option = ();
    $option{destination} = $ENV{PNSCT_DESTINATION};
    $option{foo} = "bar";
    $option{body} = "hello world";
    $stomp->send(%option);
    ok(1, "send");

    %option = ();
    $option{timeout} = TIMEOUT;
    $option{callback} = sub {
	my($self, $frame) = @_;

	return($frame) if $frame->command() eq "MESSAGE";
	return(0);
    };
    $frame = $stomp->wait_for_frames(%option);
    ok($frame, "receive");
  SKIP: {
      unless ($frame) {
	  diag("did not receive a frame back... skipping some tests...");
	  skip("", 3);
      }
      is($count, 1, "count");
      is($frame->header("foo"), "bar", "header");
      is($frame->body(), "hello world", "body");
    }

    %option = ();
    $option{id} = $subid;
    $stomp->unsubscribe(%option);
    ok(1, "unsubscribe");

    is(scalar($stomp->receipts()), 0, "loopback test -> no receipts");
}

#
# just do it
#

test_connect();
test_loopback() if $ENV{PNSCT_DESTINATION};
test_noop();
test_disconnect();

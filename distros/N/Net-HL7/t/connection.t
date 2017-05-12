BEGIN {
    unshift(@INC, "./lib");
}

require 5.004_05;
use Test::More tests => 7;
use_ok("Net::HL7::Message");
use_ok("Net::HL7::Connection");
use_ok("Net::HL7::Daemon");
use_ok("Net::HL7::Segments::MSH");

my $msg  = new Net::HL7::Message();
$msg->addSegment(new Net::HL7::Segments::MSH());

my $seg1 = new Net::HL7::Segment("PID");

$seg1->setField(3, "XXX");

$msg->addSegment($seg1);

# Starting daemon, listening will happen in a separate thread
my $d = new Net::HL7::Daemon(LocalPort => 12011);

$pid = fork();

if (! $pid) {

    while (my $client = $d->accept()) {
	my $clientMsg = $client->getRequest();
	
	if (not defined $clientMsg) {
	    exit;
	}
	
	my $msh = $clientMsg->getSegmentByIndex(0);
	
	$client->sendAck();
	last;
    }

    $d->close();
    exit;
} 

$conn = new Net::HL7::Connection("localhost", 12011);

ok($conn, "Trying to connect") or diag ("Couldn't connect, no further tests!");

$conn || exit -1;

$resp = $conn->send($msg);

ok($conn, "Sending message") or diag ("Couldn't get response no further tests!");

$resp || exit -1;

$msh = $resp->getSegmentByIndex(0);

ok($msh->getField(9) eq "ACK", "Checking ACK field");

$conn->close();

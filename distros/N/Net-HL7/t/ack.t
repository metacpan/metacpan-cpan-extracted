BEGIN {
	unshift(@INC, "./lib");
}

require 5.004_05;
use Test::More tests => 16;
use_ok("Net::HL7::Message");
use_ok("Net::HL7::Segment");
use_ok("Net::HL7::Messages::ACK");
use_ok("Net::HL7::Segments::MSH");


my $msg = new Net::HL7::Message();
$msg->addSegment(new Net::HL7::Segments::MSH());

my $msh = $msg->getSegmentByIndex(0);
$msh->setField(15, "AL");
$msh->setField(16, "NE");

my $ack = new Net::HL7::Messages::ACK($msg);

ok($ack->getSegmentByIndex(1)->getField(1) eq "CA", "Error code is CA");

$msh->setField(15, "");
$ack = new Net::HL7::Messages::ACK($msg);

ok($ack->getSegmentByIndex(1)->getField(1) eq "CA", "Error code is CA");

$msh->setField(16, "");
$ack = new Net::HL7::Messages::ACK($msg);

ok($ack->getSegmentByIndex(1)->getField(1) eq "AA", "Error code is AA");

$ack->setAckCode("E");

ok($ack->getSegmentByIndex(1)->getField(1) eq "AE", "Error code is AE");

$ack->setAckCode("CR");

ok($ack->getSegmentByIndex(1)->getField(1) eq "CR", "Error code is CR");

$ack->setAckCode("CR", "XX");

ok($ack->getSegmentByIndex(1)->getField(3) eq "XX", "Set message and code");


$msg = new Net::HL7::Message();
$msg->addSegment(new Net::HL7::Segments::MSH());
$msh = $msg->getSegmentByIndex(0);

$msh->setField(16, "NE");
$msh->setField(11, "P");
$msh->setField(12, "2.4");
$msh->setField(15, "NE");

$ack = new Net::HL7::Messages::ACK($msg);

ok($ack->getSegmentByIndex(0)->getField(11) eq "P", "Field 11 is P");
ok($ack->getSegmentByIndex(0)->getField(12) eq "2.4", "Field 12 is 2.4");
ok($ack->getSegmentByIndex(0)->getField(15) eq "NE", "Field 15 is NE");
ok($ack->getSegmentByIndex(0)->getField(16) eq "NE", "Field 16 is NE");

$ack = new Net::HL7::Messages::ACK($msg);
$ack->setErrorMessage("Some error");

ok($ack->getSegmentByIndex(1)->getField(3) eq "Some error", "Setting error message");
ok($ack->getSegmentByIndex(1)->getField(1) eq "CE", "Code CE after setting message");

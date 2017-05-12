# This -*- perl -*- code tests loop-avoidance and matching of the messages

# $Id: rtt.t,v 1.2 2003/01/14 20:32:35 lem Exp $

use Queue::Dir;
use SMS::Handler;
use Net::SMPP 1.04;
use SMS::Handler::Ping;
use Storable (fd_retrieve);

BEGIN {
    our @PDU_keys = ( qw(
			 source_addr_ton
			 source_addr_npi
			 source_addr
			 dest_addr_ton
			 dest_addr_npi
			 destination_addr
			 short_message)
		      );
};

use Test::More tests => 10;

sub _build_pdu {
    my $pdu = new Net::SMPP::PDU;
    $pdu->$_(31415) for @PDU_keys;
    return $pdu;
}

my $pdu = _build_pdu;

END {
    rmdir "test$$";
};

mkdir "test$$";

my $q = new Queue::Dir
    (
     -paths => [ "test$$" ],
     -promiscuous => 1,
     );

my $ping = new SMS::Handler::Ping 
    (
     queue => $q,
     dest => '1.2.3456',
     );

ok(defined $ping, "Creation of a simple object");

				# Now send it the SMS

my $ret = $ping->handle($pdu);

ok($ret == SMS_STOP | SMS_DEQUEUE, "Succesful handling of the SMS");

if (my $fh = $q->visit)
{
    my $cpdu = fd_retrieve($fh);
    ok($cpdu, "Stored message seems OK");
    ok($cpdu->dest_addr_ton == 1, "Dest TON ok");
    ok($cpdu->dest_addr_npi == 2, "Dest NPI ok");
    ok($cpdu->destination_addr == 3456, "Dest ADDR ok");
    $q->done;
}

while(my $qid = $q->next) 
{
    $q->done($qid);
}

				# Test loop avoidance

$ping = new SMS::Handler::Ping 
    (
     queue => $q,
     dest => '1.2.3456',
     message => '31415',
     );

$ret = $ping->handle($pdu);

ok($ret == SMS_STOP | SMS_DEQUEUE, "Succesful handling of the SMS");

my $fh = $q->visit;

ok(! defined $fh, "No message produced on loop condition");
ok(! defined $fh, "No message produced on loop condition");
ok(! defined $fh, "No message produced on loop condition");

$q->next;

while(my $qid = $q->next) 
{
    $q->done($qid);
}



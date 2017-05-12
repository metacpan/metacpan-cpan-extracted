# This -*- perl -*- code tests the AUTOLOAD magic used to have all calls
# to funny functions ending up in the handle method.

# $Id: ping.t,v 1.4 2003/01/14 20:32:35 lem Exp $

use Queue::Dir;
use SMS::Handler;
use Net::SMPP 1.04;
use SMS::Handler::Ping;
use Storable qw(fd_retrieve);

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

use Test::More tests => 28 + (grep { /dest/; } @PDU_keys);

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

#$Queue::Dir::Debug = 1;

my $ping = new SMS::Handler::Ping 
    (
     queue => $q,
     );

ok(defined $ping, "Creation of a simple object");

				# Now send it the SMS

my $ret = $ping->handle($pdu);

ok($ret == SMS_STOP | SMS_DEQUEUE, "Succesful handling of the SMS");

$q->next;

while(my $qid = $q->next) 
{
    $q->done($qid);
}

				# Queue should be empty here

$ping = new SMS::Handler::Ping 
    (
     queue => $q,
     addr => '31415.31415.31415',
     );
    
ok(defined $ping, "Creation of an object with a phone number");

$ret = $ping->handle($pdu);

ok($ret == SMS_STOP | SMS_DEQUEUE, "Succesful handling of the SMS w/phone");

$q->next;

while(my $qid = $q->next) 
{
    $q->done($qid);
}

$ping = new SMS::Handler::Ping 
    (
     queue => $q,
     addr => '1.2.3',
     );
    
ok(defined $ping, "Creation of an object with a phone number");

$pdu->{dest_addr_ton} = 1;
$pdu->{dest_addr_npi} = 2;
$pdu->{destination_addr} = 3;

$pdu->{source_addr_ton} = 4;
$pdu->{source_addr_npi} = 5;
$pdu->{source_addr} = 6;

$pdu->{short_message} = "Hello World!";

$ret = $ping->handle($pdu);

ok($ret == SMS_STOP | SMS_DEQUEUE, "Succesful handling of the SMS w/phone");

my $fh = $q->visit("r");
my $cpdu = fd_retrieve($fh);
ok(defined $cpdu, "Read stored SMS properly");
$fh->close;

ok($cpdu->dest_addr_ton == 4, "correct dest_addr_ton");
ok($cpdu->dest_addr_npi == 5, "correct dest_addr_npi");
ok($cpdu->destination_addr == 6, "correct destination_addr");

ok($cpdu->source_addr_ton == 1, "correct source_addr_ton");
ok($cpdu->source_addr_npi == 2, "correct source_addr_npi");
ok($cpdu->source_addr == 3, "correct source_addr");
    
ok($cpdu->short_message eq "Pong", "Correct response message");

$q->next;

while(my $qid = $q->next) 
{
    $q->done($qid);
}

$ping = new SMS::Handler::Ping 
    (
     queue => $q,
     message => 'Bye World',
     addr => '1.2.3',
     );
    
ok(defined $ping, "Creation of an object with a phone number");

$pdu->{dest_addr_ton} = 1;
$pdu->{dest_addr_npi} = 2;
$pdu->{destination_addr} = 3;

$pdu->{source_addr_ton} = 4;
$pdu->{source_addr_npi} = 5;
$pdu->{source_addr} = 6;

$pdu->{short_message} = "Hello World!";

$ret = $ping->handle($pdu);

ok($ret == SMS_STOP | SMS_DEQUEUE, "Succesful handling of the SMS w/phone");

$fh = $q->visit("r");
$cpdu = fd_retrieve($fh);
ok(defined $cpdu, "Read stored SMS properly");
$fh->close;

ok($cpdu->dest_addr_ton == 4, "correct dest_addr_ton");
ok($cpdu->dest_addr_npi == 5, "correct dest_addr_npi");
ok($cpdu->destination_addr == 6, "correct destination_addr");

ok($cpdu->source_addr_ton == 1, "correct source_addr_ton");
ok($cpdu->source_addr_npi == 2, "correct source_addr_npi");
ok($cpdu->source_addr == 3, "correct source_addr");
    
ok($cpdu->short_message eq "Bye World", "Correct response message");

$q->next;

while(my $qid = $q->next) 
{
    $q->done($qid);
}

for my $key (grep /dest/, @PDU_keys)
{
    $pdu = _build_pdu;
    $pdu->$key('31337');
    $ret = $ping->handle($pdu);
    ok($ret == SMS_CONTINUE, 
       "Succesful handling of the SMS w/wrong dest $key");
}

while(my $qid = $q->next) 
{
    $q->done($qid);
}

while(my $qid = $q->next) 
{
    $q->done($qid);
}

				# Queue should be empty here

SKIP: {

    skip "Params::Validate is unreliable under this version of Perl", 4
	unless $] > 5.006;

    $ping = undef;

    eval {
	$ping = new SMS::Handler::Ping 
	    (
	     queue => $q,
	     addr => '.31415.31415',
	     );
    };
    
    ok(!defined $ping, "Creation of an object without TON");
    
    eval {
	$ping = new SMS::Handler::Ping 
	    (
	     queue => $q,
	     addr => '31415..31415',
	     );
    };
    
    ok(!defined $ping, "Creation of an object without NPI");
    
    eval {
	$ping = new SMS::Handler::Ping 
	    (
	     queue => $q,
	     addr => '31415.31415.',
	     );
    };
    
    ok(!defined $ping, "Creation of an object without ADDRESS");
    
    eval {
	$ping = new SMS::Handler::Ping 
	    (
	     queue => $q,
	     addr => '...',
	     );
    };
    
    ok(!defined $ping, "Creation of an object with garbage");
}


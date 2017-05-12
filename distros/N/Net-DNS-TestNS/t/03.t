# Before `make install' is performed this script should be runnable with  -*-perl-*-
# `make test'. After `make install' it should work as `perl 1.t'


# This is exactly the same test config as t/1.t except that it uses
# the new config file format.

#########################

use Data::Dumper;


use Test::More tests => 24;
BEGIN { use_ok('Net::DNS::TestNS') };

print "BASE VERSION: ". $Net::DNS::Resolver::Base::VERSION ."\n";

ok ($server=Net::DNS::TestNS->new("t/testconf5.xml",{
	Verbose => 1,
  }	),
	"Server object created");



ok (my $res=Net::DNS::Resolver->new(nameservers => ['127.0.0.1'],
				    port => 5354,
				    recurse => 0,
				    igntc => 1,
				    ignqrid => 1,
				    ),

"Resolver object created");

$res->print;

ok ($server->verbose, "Verbose is being set");
$server->verbose(0);
ok  (!$server->verbose, "Verbose is toggled off");
$server->verbose(1);
ok  ($server->verbose, "Verbose is toggled on");
$server->verbose(0); # Otherwise the test script will be confused
$server->run;

my $packet=$res->send("bla.foo","TXT");
#print "----------  RECEIVED ------------------\n";
#$packet->print;
#print "---------------------------------------\n";


ok ($packet->header->aa, "aa bit set on the answer");
ok (! $packet->header->ad, "ad bit not set on the answer");

ok (! $packet->header->ra, "ra bit not set on the answer");
ok (! $packet->header->qr, "qr bit not set on the answer");

is ( $packet->header->id, 1234, "Header ID properly modified");

is ( $packet->header->ancount, 1, "ancount properly modified");
is ( $packet->header->nscount, 1, "nscount properly modified");

undef $packet;


$packet=$res->send("raw.foo","TXT");

ok ($packet->header->cd, "cd bit set on the answer");

is ( $packet->header->id, 3456, "Header ID properly modified");
is (($packet->question)[0]->qname,"trigger.foo","Proper QNAME");
is (($packet->answer)[0]->address,"10.0.0.1","Proper RDATA");
is (($packet->answer)[0]->name,"trigger.foo","Proper ownername");


undef $packet;


$packet=$res->send("opt.foo","TXT");


is (($packet->answer)[0]->txtdata, "THE OPT FOO QUERY", "proper answer");
is (($packet->additional)[0]->class(), 4059, "Size set to 4059 in EDNS0");
is (($packet->additional)[0]->ednsflags(),0x8000, "DO bit in EDNS0 OPT set");


undef $packet;


$packet=$res->send("opt2.foo","TXT");


is (($packet->answer)[0]->txtdata, "THE OPT2 FOO QUERY", "proper answer");
is (($packet->additional)[0]->class(), 1059, "Size set to 1059 in EDNS0");
is (sprintf("0x%04x",($packet->additional)[0]->ednsflags()),sprintf("0x%04x",0x12ab), "Flags set to something weird");

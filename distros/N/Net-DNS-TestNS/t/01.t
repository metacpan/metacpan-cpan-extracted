# Before `make install' is performed this script should be runnable with  -*-perl-*-
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Data::Dumper;


use Test::More tests => 23;
BEGIN { use_ok('Net::DNS::TestNS') };



ok ($server=Net::DNS::TestNS->new("t/testconf.xml",{
	Verbose => 1,
  }	),
	"Server object created");



ok (my $res=Net::DNS::Resolver->new(nameservers => ['127.0.0.1'],
				    port => 5354,
				    recurse => 0
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

my $packet=$res->send("bla.foo","ANY");
ok ($packet->header->aa, "aa bit set on the answer");
ok (! $packet->header->ad, "ad bit not set on the answer");

ok (! $packet->header->ra, "ra bit not set on the answer");
ok ($packet->header->rcode eq "FORMERR", "FORMERR");
ok ($packet->answer == 0, "Empty answer section");
ok ($packet->authority == 0, "Empty  authority section");
ok ($packet->additional == 0, "Empty additional section");


undef $packet;

my $packet2=$res->send("bla.foo","TXT");


my $check=[
	   Net::DNS::RR->new('bla.foo. 3600	IN	TXT	"TEXT"'),
	   Net::DNS::RR->new('bla.foo.		3600	IN	TXT	"Other text" ')
	   ];




is ($check->[0]->string,($packet2->answer)[0]->string,"First Answer RR equals");
is ($check->[1]->string,($packet2->answer)[1]->string,"Second Answer RR equals");


#NXDOMAIN but two answers...

$res->debug(1);
$res->port(5355);

my $packet3=$res->send("bla.foo","TXT");

ok (!$packet3->header->aa, "aa bit not set on the answer");
ok ( $packet3->header->ad, "ad bit set on the answer");
ok ( $packet3->header->ra, "ra bit set on the answer");



$check=[
	 Net::DNS::RR->new('bla.foo. 3600	IN	TXT	"TEXT"'),
Net::DNS::RR->new('bla.foo.		3600	IN	TXT	"From port 5355" ')
	   ];


is ($packet3->header->rcode,"NXDOMAIN", "RCODE set to NXDOMAIN");
is ($check->[0]->string,($packet3->answer)[0]->string,"First Answer RR equals");
is ($check->[1]->string,($packet3->answer)[1]->string,"Second Answer RR equals");



$server->medea;

is ( Net::DNS::TestNS->new("t/testconf3.xml",{
	Verbose => 1,
 }	), 0,"Broken config file failed object creation");
		
is ( $Net::DNS::TestNS::errorcondition, "Could not open t/broken during preporcessing", "Errorcondition set appropriatly");	





#$id$

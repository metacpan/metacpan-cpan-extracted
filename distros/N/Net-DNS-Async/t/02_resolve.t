use strict;
use warnings;
use blib;
use Data::Dumper;

use Test::More tests => 300;

use Net::DNS::Async;

my $c = new Net::DNS::Async();
for my $i (1..20) {
	for my $s (qw(google demon yahoo microsoft)) {
		$c->add(sub { cb($s, $i, @_) }, "www.$s.com", 'A');
	}
	$c->add(sub { cb('__nxd__', $i, @_) }, "nx$i.__nxd__.com", 'A');
}
$c->done();

sub cb {
	my ($s, $i, $res) = @_;
	ok(defined $res, "Received $s $i");
	my @q = $res->question;
	my @a = $res->answer;
	like($q[0]->qname, qr/\.com$/, "Question was a .com");
	if ($q[0]->qname =~ /__nxd__/) {
		is($res->header->rcode, "NXDOMAIN", "Got an nxdomain");
	}
	else {
		like($a[0]->string, qr/\bIN\b/, "Got an INET response");
	}
}

use Data::Dumper;

use Test;
BEGIN { plan tests => 1 };

use lib "lib/";
use Net::DNS::Dynamic::Proxyserver;

use Net::DNS::Resolver;

$SIG{CHLD} = 'IGNORE';

my $port = int(rand(9999)) + 10000;

my $proxy = Net::DNS::Dynamic::Proxyserver->new( host => '127.0.0.1', port => $port );

my $pid = fork();

unless ($pid) {

	$proxy->run();
	exit;
}

my $res = Net::DNS::Resolver->new(
	nameservers => [ '127.0.0.1' ],
	port		=> $port,
	recurse     => 1,
	debug       => 0,
);

my $search = $res->search('www.perl.org', 'A');

ok($search->isa('Net::DNS::Packet'));

kill 3, $pid;


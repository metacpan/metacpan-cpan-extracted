use Data::Dumper;

use Test::More tests => 6;

use lib "../lib/";
use Net::DNS::Dynamic::Adfilter;
use Net::DNS::Resolver;

$SIG{CHLD} = 'IGNORE';

my $host = '127.0.0.1';
my $port = int(rand(9999)) + 10000;
my $forwarders = [ '8.8.8.8', '8.8.4.4' ];

my $adfilter = Net::DNS::Dynamic::Adfilter->new( host => $host, port => $port, nameservers => $forwarders );

ok( defined $adfilter );
ok( $adfilter->isa('Net::DNS::Dynamic::Adfilter'));
ok( $adfilter->{host} eq $host );
ok( $adfilter->{port} == $port );
ok( $adfilter->{forwarders} ~~ $forwarders );

my $pid = fork() unless $^O =~ /32/;

unless ($pid) {

	ok( $adfilter->run() );
	exit;
}

my $res = Net::DNS::Resolver->new(
	nameservers => [ $host ],
	port        => $port,
	recurse     => 1,
	debug       => 0,
);

my $search = $res->search('www.perl.org', 'A');

ok($search->isa('Net::DNS::Packet'));

kill 3, $pid;

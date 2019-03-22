# $Id: 01-resolver.t 1729 2019-01-28 09:45:47Z willem $	-*-perl-*-

use strict;
use Test::More tests => 22;

use Net::DNS::Resolver;
use Net::DNS::Resolver::Recurse;

my @NOIP = qw(:: 0.0.0.0);

{					## sabotage socket code

	package IO::Socket::INET;
	sub new { }			## stub

	package IO::Socket::IP;
	sub new { }			## stub
}


my $resolver = Net::DNS::Resolver->new( retrans => 0, retry => 0 );


$resolver->defnames(0);			## exercise query()
ok( !$resolver->query(''), '$resolver->query() without defnames' );

$resolver->defnames(1);
ok( !$resolver->query(''), '$resolver->query() with defnames' );


$resolver->dnsrch(0);			## exercise search()
ok( !$resolver->search('name'), '$resolver->search() without dnsrch' );

$resolver->dnsrch(1);
$resolver->ndots(1);
ok( !$resolver->search('name'),	       '$resolver->search() simple name' );
ok( !$resolver->search('name.domain'), '$resolver->search() dotted name' );

$resolver->ndots(2);
ok( !$resolver->search(''), '$resolver->search() with ndots > 1' );


my $query = new Net::DNS::Packet('.');	## exercise _accept_reply()
my $reply = new Net::DNS::Packet('.');
$reply->header->qr(1);

ok( !$resolver->_accept_reply(undef), '_accept_reply()	no reply' );

ok( !$resolver->_accept_reply($query), '_accept_reply()	qr not set' );

ok( !$resolver->_accept_reply( $reply, $query ), '_accept_reply()	id mismatch' );

ok( $resolver->_accept_reply( $reply, $reply ), '_accept_reply()	id match' );
ok( $resolver->_accept_reply( $reply, undef ),	'_accept_reply()	query absent/undefined' );

is( scalar( Net::DNS::Resolver::Base::_cname_addr( undef, undef ) ), 0, '_cname_addr()	no reply packet' );


$resolver->nameservers();		## exercise UDP failure path
ok( !$resolver->send('.'), 'no UDP nameservers' );

$resolver->nameservers(@NOIP);
ok( !$resolver->send('.'),   '$resolver->send	UDP socket error' );
ok( !$resolver->bgsend('.'), '$resolver->bgsend UDP socket error' );


$resolver->usevc(1);			## exercise TCP failure path
$resolver->nameservers();
ok( !$resolver->send('.'), 'no TCP nameservers' );

$resolver->nameservers(@NOIP);
ok( !$resolver->send('.'),	  '$resolver->send   TCP socket error' );
ok( !$resolver->bgsend('.'),	  '$resolver->bgsend TCP socket error' );
ok( !scalar( $resolver->axfr() ), '$resolver->axfr   TCP socket error' );


my $res = Net::DNS::Resolver::Recurse->new();
$res->hints(@NOIP);
ok( !$res->send( 'www.net-dns.org', 'A' ), 'fail if no usable hint' );

$res->nameservers(@NOIP);
ok( !$res->send( 'www.net-dns.org', 'A' ), 'fail if no reachable server' );


my $warning;
local $SIG{__WARN__} = sub { ($warning) = split /\n/, "@_\n" };

$resolver->nameserver('bogus.example.com.');
ok( $warning, "unresolved nameserver warning\t[$warning]" );


eval {					## exercise warning for make_query_packet()
	local *STDERR;
	my $filename = '01-resolver.tmp';
	open( STDERR, ">$filename" ) || die "Could not open $filename for writing";
	$resolver->make_query_packet('example.com');		# carp
	$resolver->make_query_packet('example.com');		# silent
	close(STDERR);
	unlink($filename);
};


exit;

__END__


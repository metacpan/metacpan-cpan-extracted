# $Id: 08-IPv4.t 1740 2019-04-04 14:45:31Z willem $ -*-perl-*-

use strict;
use Test::More;

BEGIN {
	local @INC = ( @INC, qw(t) );
	require NonFatal;
}

use Net::DNS;
use IO::Select;

my $debug = 0;

my @hints = new Net::DNS::Resolver()->_hints;

my $NOIP = qw(0.0.0.0);

my @nsdname = qw(
		ns.net-dns.org
		mcvax.nlnet.nl
		ns.nlnetlabs.nl
		);


exit( plan skip_all => 'Online tests disabled.' ) if -e 't/online.disabled';
exit( plan skip_all => 'Online tests disabled.' ) unless -e 't/online.enabled';


eval {
	my $resolver = new Net::DNS::Resolver( igntc => 1 );
	exit plan skip_all => 'No nameservers' unless $resolver->nameservers;

	my $reply = $resolver->send(qw(. NS IN)) || die;

	my @ns = grep $_->type eq 'NS', $reply->answer, $reply->authority;
	exit plan skip_all => 'Local nameserver broken' unless scalar @ns;

	1;
} || exit( plan skip_all => 'Non-responding local nameserver' );


eval {
	my $resolver = new Net::DNS::Resolver( nameservers => [@hints] );
	$resolver->force_v4(1);
	exit plan skip_all => 'No IPv4 transport' unless $resolver->nameservers;

	my $reply = $resolver->send(qw(. NS IN)) || die;
	my $from = $reply->from();

	my @ns = grep $_->type eq 'NS', $reply->answer, $reply->authority;
	exit plan skip_all => "Unexpected response from $from" unless scalar @ns;

	exit plan skip_all => "Non-authoritative response from $from" unless $reply->header->aa;

	1;
} || exit( plan skip_all => 'Unable to reach global root nameservers' );


my $IP = eval {
	my $resolver = new Net::DNS::Resolver();
	$resolver->nameservers(@nsdname);
	$resolver->force_v4(1);
	[$resolver->nameservers()];
};
exit( plan skip_all => 'Unable to resolve nameserver name' ) unless scalar @$IP;

diag join( "\n\t", 'will use nameservers', @$IP ) if $debug;

Net::DNS::Resolver->debug($debug);


plan tests => 68;

NonFatalBegin();


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP, defnames => 1, dnsrch => 1, ndots => 2 );
	$resolver->searchlist(qw(nx.net-dns.org net-dns.org));

	ok( !$resolver->query('ns'),		'$resolver->query( simple name, ... )' );
	ok( $resolver->query('ns.net-dns.org'), '$resolver->query( dotted name, ... )' );
	ok( $resolver->search('ns'),		'$resolver->search( simple name, ... )' );
	ok( $resolver->search('net-dns.org'),	'$resolver->search( dotted name, ... )' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );

	my $packet = new Net::DNS::Packet(qw(net-dns.org SOA IN));
	ok( $resolver->send($packet), '$resolver->send(...)	UDP' );

	$packet->edns->option( PADDING => ( 'OPTION-LENGTH' => 500 ) );	   # force TCP

	ok( $resolver->send($packet), '$resolver->send(...)	TCP' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->dnssec(1);
	$resolver->udppacketsize(513);

	$resolver->igntc(1);
	my $udp = $resolver->send(qw(net-dns.org DNSKEY IN));
	ok( $udp && $udp->header->tc, '$resolver->send(...)	truncated UDP reply' );

	$resolver->igntc(0);
	my $retry = $resolver->send(qw(net-dns.org DNSKEY IN));
	ok( $retry && !$retry->header->tc, '$resolver->send(...)	automatic TCP retry' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->igntc(0);

	my $packet = new Net::DNS::Packet(qw(net-dns.org SOA IN));

	my $udp = $resolver->bgsend($packet);
	ok( $udp, '$resolver->bgsend(...)	UDP' );
	while ( $resolver->bgbusy($udp) ) { sleep 1; }
	ok( $resolver->bgread($udp), '$resolver->bgread($udp)' );

	$packet->edns->option( PADDING => ( 'OPTION-LENGTH' => 500 ) );	   # force TCP

	my $tcp = $resolver->bgsend($packet);
	ok( $tcp, '$resolver->bgsend(...)	TCP' );
	while ( $resolver->bgbusy($tcp) ) { sleep 1; }
	ok( $resolver->bgread($tcp), '$resolver->bgread($tcp)' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->dnssec(1);
	$resolver->udppacketsize(513);
	$resolver->igntc(1);

	my $handle = $resolver->bgsend(qw(net-dns.org DNSKEY IN));
	ok( $handle, '$resolver->bgsend(...)	truncated UDP' );
	my $packet = $resolver->bgread($handle);
	ok( $packet && $packet->header->tc, '$resolver->bgread($udp)	ignore UDP truncation' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->dnssec(1);
	$resolver->udppacketsize(513);
	$resolver->igntc(0);

	my $handle = $resolver->bgsend(qw(net-dns.org DNSKEY IN));
	ok( $handle, '$resolver->bgsend(...)	truncated UDP' );
	my $packet = $resolver->bgread($handle);
	ok( $packet && !$packet->header->tc, '$resolver->bgread($tcp)	background TCP retry' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->dnssec(1);
	$resolver->udppacketsize(513);
	$resolver->igntc(0);

	my $handle = $resolver->bgsend(qw(net-dns.org DNSKEY IN));
	$resolver->nameserver();				# no nameservers
	my $packet = $resolver->bgread($handle);
	ok( $packet && $packet->header->tc, '$resolver->bgread($udp)	background TCP fail' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->persistent_udp(1);

	my $handle = $resolver->bgsend(qw(net-dns.org SOA IN));
	ok( $handle, '$resolver->bgsend(...)	persistent UDP' );
	my $bgread = $resolver->bgread($handle);
	ok( $bgread, '$resolver->bgread($udp)' );
	my $test = $resolver->bgsend(qw(net-dns.org SOA IN));
	ok( $test, '$resolver->bgsend(...)	persistent UDP' );
	is( $test, $handle, 'same UDP socket object used' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->persistent_tcp(1);
	$resolver->usevc(1);

	my $handle = $resolver->bgsend(qw(net-dns.org SOA IN));
	ok( $handle, '$resolver->bgsend(...)	persistent TCP' );
	my $bgread = $resolver->bgread($handle);
	ok( $bgread, '$resolver->bgread($tcp)' );
	my $test = $resolver->bgsend(qw(net-dns.org SOA IN));
	ok( $test, '$resolver->bgsend(...)	persistent TCP' );
	is( $test, $handle, 'same TCP socket object used' );
	eval { close($handle) };
	my $recover = $resolver->bgsend(qw(net-dns.org SOA IN));
	ok( $recover, 'connection recovered after close' );
}


SKIP: {
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->domain('net-dns.org');
	eval { $resolver->tsig( $resolver->query(qw(tsig-md5 KEY))->answer ) };
	skip( 'automatic TSIG tests', 3 ) if $@;

	$resolver->igntc(1);

	my $udp = $resolver->send(qw(net-dns.org SOA IN));
	ok( $udp, '$resolver->send(...)	UDP + automatic TSIG' );

	$resolver->usevc(1);

	my $tcp = $resolver->send(qw(net-dns.org SOA IN));
	ok( $tcp, '$resolver->send(...)	TCP + automatic TSIG' );

	my $bgread;
	foreach my $ip (@$IP) {
		$resolver->nameserver($ip);
		my $handle = $resolver->bgsend(qw(net-dns.org SOA IN));
		last if $bgread = $resolver->bgread($handle);
	}
	ok( $bgread, '$resolver->bgsend/read	TCP + automatic TSIG' );
}


SKIP: {
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->igntc(1);

	eval { $resolver->tsig( 'MD5.example', 'MD5keyMD5keyMD5keyMD5keyMD5=' ) };
	skip( 'failed TSIG tests', 3 ) if $@;

	my $udp = $resolver->send(qw(net-dns.org SOA IN));
	ok( !$udp, '$resolver->send(...)	UDP + failed TSIG' );

	$resolver->usevc(1);

	my $tcp = $resolver->send(qw(net-dns.org SOA IN));
	ok( !$tcp, '$resolver->send(...)	TCP + failed TSIG' );

	my $handle = $resolver->bgsend(qw(net-dns.org SOA IN));
	my $bgread = $resolver->bgread($handle);
	ok( !$bgread, '$resolver->bgsend/read	TCP + failed TSIG' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );

	my $udp = $resolver->query(qw(bogus.net-dns.org A IN));
	ok( !$udp, '$resolver->query() nonexistent name	UDP' );

	$resolver->usevc(1);

	my $tcp = $resolver->query(qw(bogus.net-dns.org A IN));
	ok( !$tcp, '$resolver->query() nonexistent name	TCP' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	my $update = new Net::DNS::Update(qw(example.com));
	ok( $resolver->send($update), '$resolver->send($update) UDP' );
	$resolver->usevc(1);
	ok( $resolver->send($update), '$resolver->send($update) TCP' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );

	my $mx = 'mx2.t.net-dns.org';
	my @rr = rr( $resolver, $mx, 'MX' );

	is( scalar(@rr), 2, 'Net::DNS::rr() works with specified resolver' );
	is( scalar rr( $resolver, $mx, 'MX' ), 2, 'Net::DNS::rr() works in scalar context' );
	is( scalar rr( $mx, 'MX' ), 2, 'Net::DNS::rr() works with default resolver' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );

	my $mx = 'mx2.t.net-dns.org';
	my @mx = mx( $resolver, $mx );

	is( scalar(@mx), 2, 'Net::DNS::mx() works with specified resolver' );

	# some people seem to use mx() in scalar context
	is( scalar mx( $resolver, $mx ), 2, 'Net::DNS::mx() works in scalar context' );

	is( scalar mx($mx), 2, 'Net::DNS::mx() works with default resolver' );

	is( scalar mx('bogus.t.net-dns.org'), 0, "Net::DNS::mx() works for bogus name" );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->tcp_timeout(10);

	my @zone = $resolver->axfr('net-dns.org');
	ok( scalar(@zone), '$resolver->axfr() returns entire zone in list context' );

	my @notauth = $resolver->axfr('bogus.net-dns.org');
	my $notauth = $resolver->errorstring;
	ok( !scalar(@notauth), "mismatched zone\t[$notauth]" );

	my $iterator = $resolver->axfr('net-dns.org');
	ok( ref($iterator), '$resolver->axfr() returns iterator in scalar context' );

	my $soa = eval { $iterator->() };
	is( ref($soa), 'Net::DNS::RR::SOA', '$iterator->() returns initial SOA RR' );

	my $i;
	eval {
		return unless $soa;
		$soa->serial(undef);				# force SOA mismatch
		while ( $iterator->() ) { $i++; }
	};
	my ($exception) = split /\n/, "$@\n";
	ok( $i, '$iterator->() iterates through remaining RRs' );
	ok( !eval { $iterator->() }, '$iterator->() returns undef after last RR' );
	ok( $exception, "iterator exception\t[$exception]" );
}


SKIP: {
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->domain('net-dns.org');
	eval { $resolver->tsig( $resolver->query(qw(tsig-md5 KEY))->answer ) };
	skip( 'TSIG AXFR tests', 4 ) if $@;
	$resolver->tcp_timeout(10);

	my @zone = $resolver->axfr();
	ok( scalar(@zone), '$resolver->axfr() with TSIG verify' );

	my @notauth = $resolver->axfr('bogus.net-dns.org');
	my $notauth = $resolver->errorstring;
	ok( !scalar(@notauth), "mismatched zone\t[$notauth]" );

	eval { $resolver->tsig( 'MD5.example', 'MD5keyMD5keyMD5keyMD5keyMD5=' ) };
	my @unverifiable = $resolver->axfr();
	my $errorstring	 = $resolver->errorstring;
	ok( !scalar(@unverifiable), "mismatched key\t[$errorstring]" );

	eval { $resolver->tsig(undef) };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "undefined TSIG\t[$exception]" );
}


SKIP: {
	my $resolver = Net::DNS::Resolver->new( nameservers => $NOIP );
	eval { $resolver->tsig( 'MD5.example', 'MD5keyMD5keyMD5keyMD5keyMD5=' ) };
	skip( 'TSIG AXFR tests', 2 ) if $@;

	my $query = new Net::DNS::Packet(qw(. SOA IN));
	ok( $resolver->bgsend($query), '$resolver->bgsend() + automatic TSIG' );
	ok( $resolver->bgsend($query), '$resolver->bgsend() + existing TSIG' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	$resolver->nameserver('cname.t.net-dns.org');
	ok( scalar( $resolver->nameservers ), 'resolve nameserver cname' );
}


{					## exercise exceptions in _axfr_next()
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->domain('net-dns.org');
	eval { $resolver->tsig( $resolver->query(qw(tsig-md5 KEY))->answer ) };
	$resolver->tcp_timeout(10);

	{
		my $select = new IO::Select();
		eval { $resolver->_axfr_next($select); };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "TCP time out\t[$exception]" );
	}

	{
		my $packet = new Net::DNS::Packet(qw(net-dns.org SOA));
		my $socket = $resolver->_bgsend_tcp( $packet, $packet->data );
		my $select = new IO::Select($socket);
		while ( $resolver->bgbusy($socket) ) { sleep 1 }
		my $discarded = '';	## [size][id][status]	[qdcount]...
		$socket->recv( $discarded, 6 ) if $socket;
		eval { $resolver->_axfr_next($select); };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "corrupt data\t[$exception]" );
	}

SKIP: {
		my $packet = $resolver->_make_query_packet(qw(net-dns.org SOA));
		my $socket = $resolver->_bgsend_tcp( $packet, $packet->data );
		my $tsigrr = $packet->sigrr;
		skip( 'verify fail', 1 ) unless $tsigrr;

		my $select = new IO::Select($socket);
		eval { $resolver->_axfr_next( $select, $tsigrr ); };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "verify fail\t[$exception]" );
	}
}


{					## exercise error paths in _send_???()
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP, retry => 1 );
	my $packet = new Net::DNS::Packet(qw(net-dns.org SOA));

	my $mismatch = new Net::DNS::Packet(qw(net-dns.org SOA));
	ok( !$resolver->_send_tcp( $mismatch, $packet->data ), '_send_tcp()	id mismatch' );
	ok( !$resolver->_send_udp( $mismatch, $packet->data ), '_send_udp()	id mismatch' );
}


{					## exercise error path in bgbusy() and _bgread()
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP, udp_timeout => 0 );

	ok( !$resolver->bgread(undef), '_bgread()	undefined handle' );

	my $packet = $resolver->_make_query_packet(qw(net-dns.org SOA));
	my $second = $resolver->_make_query_packet(qw(net-dns.org SOA));
	my $handle = $resolver->_bgsend_udp( $packet, $second->data );
	ok( !$resolver->bgread($handle), '_bgread()	no reply' );

	ok( !$resolver->bgread( ref($handle)->new ), '_bgread()	timeout' );

	my $socket = $resolver->_bgsend_udp( $packet, $second->data );
	delete ${*$socket}{net_dns_bg};
	while ( $resolver->bgbusy($socket) ) { sleep 1 }
	ok( !$resolver->bgbusy($socket), 'bgbusy()	SpamAssassin workaround' );
}


{					## exercise error path in _read_tcp()
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->tcp_timeout(10);

	my $packet = $resolver->_make_query_packet(qw(net-dns.org SOA));
	my $socket = $resolver->_bgsend_tcp( $packet, $packet->data );
	while ( $resolver->bgbusy($socket) ) { sleep 1 }

	my $discard = '';
	$socket->recv( $discard, 1 ) if $socket;		# discard first octet
	$socket->blocking(0);
	ok( !$resolver->_bgread($socket), '_read_tcp()	incomplete data' );
}


{					## exercise Net::DNS::Extlang query
	ok( Net::DNS::RR->new('. MD'), 'Net::DNS::Extlang query' );
}


NonFatalEnd();

exit;

__END__


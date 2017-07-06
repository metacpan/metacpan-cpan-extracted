# $Id: 08-IPv6.t 1567 2017-05-19 09:52:52Z willem $ -*-perl-*-

use strict;
use Test::More;

BEGIN {
	local @INC = ( @INC, qw(t) );
	require NonFatal;
}

use Net::DNS;
use IO::Select;

my $debug = 0;

my @hints = qw(
		2001:503:ba3e::2:30
		2001:500:84::b
		2001:500:2::c
		2001:500:2d::d
		2001:500:a8::e
		2001:500:2f::f
		2001:500:12::d0d
		2001:500:1::53
		2001:7fe::53
		2001:503:c27::2:30
		2001:7fd::1
		2001:500:9f::42
		2001:dc3::35
		);


exit( plan skip_all => 'Online tests disabled.' ) if -e 't/online.disabled';
exit( plan skip_all => 'Online tests disabled.' ) unless -e 't/online.enabled';

exit( plan skip_all => 'IPv6 tests disabled.' ) if -e 't/IPv6.disabled';
exit( plan skip_all => 'IPv6 tests disabled.' ) unless -e 't/IPv6.enabled';


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
	exit plan skip_all => 'No IPv6 transport' unless $resolver->nameservers;

	my $reply = $resolver->send(qw(. NS IN)) || die;
	my $from = $reply->answerfrom();

	my @ns = grep $_->type eq 'NS', $reply->answer, $reply->authority;
	exit plan skip_all => "Unexpected response from $from" unless scalar @ns;

	exit plan skip_all => "Non-authoritative response from $from" unless $reply->header->aa;

	1;
} || exit( plan skip_all => 'Unable to reach global root nameservers' );


my $IP = eval {
	my @nsdname  = qw(ns.net-dns.org mcvax.nlnet.nl ns.nlnetlabs.nl);
	my $resolver = new Net::DNS::Resolver();
	$resolver->nameservers(@nsdname);
	$resolver->force_v6(1);

	my @ip = $resolver->nameservers();
	scalar(@ip) ? [@ip] : undef;
} || exit( plan skip_all => 'Unable to resolve nameserver name' );

my $NOIP = '::';

diag join( "\n\t", 'will use nameservers', @$IP ) if $debug;

Net::DNS::Resolver->debug($debug);


plan tests => 91;

NonFatalBegin();


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );

	my $udp = $resolver->send(qw(net-dns.org SOA IN));
	ok( $udp, '$resolver->send(...)	UDP' );

	$resolver->usevc(1);

	my $tcp = $resolver->send(qw(net-dns.org SOA IN));
	ok( $tcp, '$resolver->send(...)	TCP' );
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

	my $udp = $resolver->bgsend(qw(net-dns.org SOA IN));
	ok( $udp, '$resolver->bgsend(...)	UDP' );
	while ( $resolver->bgbusy($udp) ) { sleep 1; }
	ok( $resolver->bgisready($udp), '$resolver->bgisready($udp)' );
	ok( $resolver->bgread($udp),	'$resolver->bgread($udp)' );

	$resolver->usevc(1);

	my $tcp = $resolver->bgsend(qw(net-dns.org SOA IN));
	ok( $tcp, '$resolver->bgsend(...)	TCP' );
	while ( $resolver->bgbusy($tcp) ) { sleep 1; }
	ok( $resolver->bgread($tcp), '$resolver->bgread($tcp)' );

	ok( !$resolver->bgbusy(undef), '!$resolver->bgbusy(undef)' );
	ok( !$resolver->bgread(undef), '!$resolver->bgread(undef)' );

	$resolver->udp_timeout(0);
	ok( !$resolver->bgread( ref($udp)->new ), '!$resolver->bgread(Socket->new)' );
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
	$resolver->nameserver($NOIP);
	my $packet = $resolver->bgread($handle);
	ok( $packet && $packet->header->tc, '$resolver->bgread($udp)	background TCP fail' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );

	my $handle = $resolver->bgsend(qw(net-dns.org SOA IN));
	delete ${*$handle}{net_dns_bg};
	my $bgread = $resolver->bgread($handle);
	ok( $bgread, '$resolver->bgread($udp)	workaround for SpamAssassin' );
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


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->srcaddr($NOIP);
	$resolver->srcport(2345);

	my $udp = $resolver->bgsend(qw(net-dns.org SOA IN));
	ok( $udp, '$resolver->bgsend(...)	specify UDP local address & port' );

	$resolver->usevc(1);

	my $tcp = $resolver->bgsend(qw(net-dns.org SOA IN));
	ok( $tcp, '$resolver->bgsend(...)	specify TCP local address & port' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->srcport(-1);

	my $udp = $resolver->send(qw(net-dns.org SOA IN));
	ok( !$udp, '$resolver->send(...)	specify bad UDP source port' );

	$resolver->usevc(1);

	my $tcp = $resolver->send(qw(net-dns.org SOA IN));
	ok( !$tcp, '$resolver->send(...)	specify bad TCP source port' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->srcport(-1);

	my $udp = $resolver->bgsend(qw(net-dns.org SOA IN));
	ok( !$udp, '$resolver->bgsend(...)	specify bad UDP source port' );

	$resolver->usevc(1);

	my $tcp = $resolver->bgsend(qw(net-dns.org SOA IN));
	ok( !$tcp, '$resolver->bgsend(...)	specify bad TCP source port' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->domain('net-dns.org');
	eval { $resolver->tsig( $resolver->query(qw(tsig-md5 KEY))->answer ) };
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


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->igntc(1);

	eval { $resolver->tsig( 'MD5.example', 'MD5keyMD5keyMD5keyMD5keyMD5=' ) };

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
	my $resolver = Net::DNS::Resolver->new();
	$resolver->retrans(0);
	$resolver->retry(0);

	my @query = ( undef, qw(SOA IN) );
	ok( $resolver->query(@query),  '$resolver->query( undef, ... ) defaults to "." ' );
	ok( $resolver->search(@query), '$resolver->search( undef, ... ) defaults to "." ' );

	$resolver->defnames(0);
	$resolver->dnsrch(0);
	ok( $resolver->search(@query), '$resolver->search() without dnsrch & defnames' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	$resolver->searchlist('net');

	my @query = (qw(us SOA IN));
	ok( $resolver->query(@query),  '$resolver->query( name, ... )' );
	ok( $resolver->search(@query), '$resolver->search( name, ... )' );

	$resolver->defnames(0);
	$resolver->dnsrch(0);
	ok( $resolver->query(@query),  '$resolver->query() without defnames' );
	ok( $resolver->search(@query), '$resolver->search() without dnsrch' );
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
	my $resolver = Net::DNS::Resolver->new( nameservers => $NOIP );
	$resolver->retrans(0);
	$resolver->retry(0);
	$resolver->tcp_timeout(0);

	my @query = (qw(:: SOA IN));
	my $query = new Net::DNS::Packet(@query);
	ok( !$resolver->query(@query),	'$resolver->query() failure' );
	ok( !$resolver->search(@query), '$resolver->search() failure' );

	$query->edns->option( 65001, pack 'x500' );		# pad to force TCP
	ok( !$resolver->send($query),	'$resolver->send() failure' );
	ok( !$resolver->bgsend($query), '$resolver->bgsend() failure' );
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

	my $axfr_start = $resolver->axfr_start('net-dns.org');
	ok( $axfr_start, '$resolver->axfr_start()	(historical)' );
	ok( eval { $resolver->axfr_next() }, '$resolver->axfr_next()	(historical)' );
	ok( $resolver->answerfrom(), '$resolver->answerfrom() works' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->domain('net-dns.org');
	eval { $resolver->tsig( $resolver->query(qw(tsig-md5 KEY))->answer ) };
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

	$resolver->srcport(-1);
	my @badsocket = $resolver->axfr();
	my $badsocket = $resolver->errorstring;
	ok( !scalar(@badsocket), "bad AXFR socket\t[$badsocket]" );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $NOIP );
	eval { $resolver->tsig( 'MD5.example', 'MD5keyMD5keyMD5keyMD5keyMD5=' ) };

	my $query = new Net::DNS::Packet(qw(. SOA IN));
	ok( $resolver->bgsend($query), '$resolver->bgsend() + automatic TSIG' );
	ok( $resolver->bgsend($query), '$resolver->bgsend() + existing TSIG' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	$resolver->nameservers();
	ok( !$resolver->send(qw(. NS)), 'no nameservers' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	$resolver->nameserver('cname.t.net-dns.org');
	ok( scalar( $resolver->nameservers ), 'resolve nameserver cname' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	my @warnings;
	local $SIG{__WARN__} = sub { push( @warnings, "@_" ); };
	my $ns = 'bogus.example.com.';
	my @ip = $resolver->nameserver($ns);

	my ($warning) = split /\n/, "@warnings\n";
	ok( $warning, "unresolved nameserver warning\t[$warning]" )
			|| diag "\tnon-existent '$ns' resolved: @ip";
}


{					## exercise exceptions in _axfr_next()
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->domain('net-dns.org');
	eval { $resolver->tsig( $resolver->query(qw(tsig-md5 KEY))->answer ) };
	$resolver->tcp_timeout(10);

	{
		my $select = new IO::Select();
		eval { $resolver->_axfr_next($select); };
		my $exception = $1 if $@ =~ /^(.+)\n/;
		ok( $exception ||= '', "TCP time out\t[$exception]" );
	}

	{
		my $packet = $resolver->_make_query_packet(qw(net-dns.org SOA));
		my $socket = $resolver->_bgsend_tcp( $packet, $packet->data );
		my $select = new IO::Select($socket);
		while ( $resolver->bgbusy($socket) ) { sleep 1 }
		my $discarded = '';	## [size][id][status]	[qdcount]...
		$socket->recv( $discarded, 6 );
		eval { $resolver->_axfr_next($select); };
		my $exception = $1 if $@ =~ /^(.+)\n/;
		ok( $exception ||= '', "corrupt data\t[$exception]" );
	}

	{
		my $packet = $resolver->_make_query_packet(qw(net-dns.org SOA));
		my $socket = $resolver->_bgsend_tcp( $packet, $packet->data );
		my $select = new IO::Select($socket);
		eval { $resolver->_axfr_next( $select, $packet->sigrr ); };
		my $exception = $1 if $@ =~ /^(.+)\n/;
		ok( $exception ||= '', "verify fail\t[$exception]" );
	}
}


{					## exercise error paths in _send_???() and bgbusy()
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	my $packet = $resolver->_make_query_packet(qw(net-dns.org SOA));

	my $mismatch = $resolver->_make_query_packet(qw(net-dns.org SOA));
	ok( !$resolver->_send_tcp( $mismatch, $packet->data ), '_send_tcp()	id mismatch' );
	ok( !$resolver->_send_udp( $mismatch, $packet->data ), '_send_udp()	id mismatch' );
	my $handle = $resolver->_bgsend_udp( $mismatch, $packet->data );
	ok( !$resolver->bgread($handle), 'bgbusy()	id mismatch' );
}


{					## exercise error paths in _decode_reply()
	my $resolver = Net::DNS::Resolver->new( nameservers => $NOIP );

	my $corrupt = '';
	ok( !$resolver->_decode_reply( \$corrupt ), '_decode_reply()	corrupt reply' );

	my $query = new Net::DNS::Packet(qw(net-dns.org SOA IN));
	my $qdata = $query->data;
	ok( !$resolver->_decode_reply( \$qdata ), '_decode_reply()	qr not set' );

	my $reply = new Net::DNS::Packet(qw(net-dns.org SOA IN));
	$reply->header->qr(1);
	my $rdata = $reply->data;
	ok( !$resolver->_decode_reply( \$rdata, $query ), '_decode_reply()	id mismatch' );
}


{					## exercise error path in _read_tcp()
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->tcp_timeout(10);

	my $packet = $resolver->_make_query_packet(qw(net-dns.org SOA));
	my $socket = $resolver->_bgsend_tcp( $packet, $packet->data );
	my $select = new IO::Select($socket);
	while ( $resolver->bgbusy($socket) ) { sleep 1 }

	my $size_buf = '';
	$socket->recv( $size_buf, 2 );
	my ($size) = unpack 'n*', $size_buf;
	my $discarded = '';		## data dependent: last 16 bits must not all be zero
	$socket->recv( $discarded, $size - 2 ) if $size;

	ok( !$resolver->_bgread($socket), '_read_tcp()	corrupt data' );
}


NonFatalEnd();

exit;

__END__


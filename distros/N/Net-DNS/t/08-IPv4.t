#!/usr/bin/perl
# $Id: 08-IPv4.t 2017 2025-06-27 13:48:03Z willem $ -*-perl-*-
#

use strict;
use warnings;
use Test::More;
use TestToolkit;

use Net::DNS;
use IO::Select;

my $debug = 0;

my @hints = Net::DNS::Resolver->new()->_hints;

my $NOIP = qw(0.0.0.0);

my @nsdname = qw(
		ns.net-dns.org
		ns.nlnetlabs.nl
		);


exit( plan skip_all => 'Online tests disabled.' ) if -e 't/online.disabled';
exit( plan skip_all => 'Online tests disabled.' ) unless -e 't/online.enabled';


eval {
	my $resolver = Net::DNS::Resolver->new( igntc => 1 );
	exit plan skip_all => 'No nameservers' unless $resolver->nameservers;

	my $reply = $resolver->send(qw(. NS IN)) || die $resolver->errorstring;

	my @ns = grep { $_->type eq 'NS' } $reply->answer, $reply->authority;
	exit plan skip_all => 'Local nameserver broken' unless scalar @ns;

	1;
} || exit( plan skip_all => "Non-responding local nameserver: $@" );


eval {
	my $resolver = Net::DNS::Resolver->new( nameservers => [@hints] );
	$resolver->force_v4(1);
	exit plan skip_all => 'No IPv4 transport' unless $resolver->nameservers;

	my $reply = $resolver->send(qw(. NS IN)) || die $resolver->errorstring;
	my $from  = $reply->from();

	my @ns = grep { $_->type eq 'NS' } $reply->answer, $reply->authority;
	exit plan skip_all => "Unexpected response from $from" unless scalar @ns;

	exit plan skip_all => "Non-authoritative response from $from" unless $reply->header->aa;

	1;
} || exit( plan skip_all => $@ || 'Cannot reach global root' );


my $IP = eval {
	my $resolver = Net::DNS::Resolver->new();
	$resolver->nameservers(@nsdname);
	$resolver->force_v4(1);
	[$resolver->nameservers()];
} || [];
exit( plan skip_all => 'Unable to resolve nameserver name' ) unless scalar @$IP;

diag join( "\n\t", 'will use nameservers', @$IP ) if $debug;

Net::DNS::Resolver->debug($debug);


plan tests => 62;

NonFatalBegin();


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP, dnsrch => 1 );

	ok( $resolver->search('ns.net-dns.org.'),  '$resolver->search(ns.net-dns.org.)' );
	ok( !$resolver->search('nx.net-dns.org.'), '$resolver->search(nx.net-dns.org.)' );

	my $packet = Net::DNS::Packet->new(qw(net-dns.org SOA IN));
	ok( $resolver->send($packet), '$resolver->send(...)	UDP' );

	$packet->edns->option( PADDING => ( 'OPTION-LENGTH' => 500 ) );	   # force TCP
	delete $packet->{id};
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

	my $packet = Net::DNS::Packet->new(qw(net-dns.org SOA IN));

	my $udp = $resolver->bgsend($packet);
	ok( $udp, '$resolver->bgsend(...)	UDP' );
	while ( $resolver->bgbusy($udp) ) { sleep 1; }
	ok( $resolver->bgread($udp), '$resolver->bgread($udp)' );

	$packet->edns->option( PADDING => ( 'OPTION-LENGTH' => 500 ) );	   # force TCP
	delete $packet->{id};
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
	my $udp	   = $handle;
	my $packet = $resolver->bgread($handle);
	isnt( $handle, $udp, '$resolver->bgbusy($udp)	handle changed to TCP' );
	ok( $packet && !$packet->header->tc, '$resolver->bgread($udp)	background TCP retry' );
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


my $tsig_key = eval {
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->domain('net-dns.org');
	my @answer = $resolver->query(qw(tsig-md5 KEY))->answer;
	shift @answer;
};

my $bad_key = Net::DNS::RR->new('MD5.example KEY 512 3 157 MD5keyMD5keyMD5keyMD5keyMD5=');


SKIP: {
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	eval { $resolver->tsig($tsig_key) };
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

	eval { $resolver->tsig($bad_key) };
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
	my $update   = Net::DNS::Update->new(qw(example.com));
	ok( $resolver->send($update), '$resolver->send($update) UDP' );
	$resolver->usevc(1);
	delete $update->{id};
	ok( $resolver->send($update), '$resolver->send($update) TCP' );
}


{
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );

	my $mx = 'mx2.t.net-dns.org';
	my @rr = rr( $resolver, $mx, 'MX' );

	is( scalar(@rr),		       2, 'Net::DNS::rr() works with specified resolver' );
	is( scalar rr( $resolver, $mx, 'MX' ), 2, 'Net::DNS::rr() works in scalar context' );
	is( scalar rr( $mx, 'MX' ),	       2, 'Net::DNS::rr() works with default resolver' );
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


SKIP: {
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->tcp_timeout(10);

	my @zone = $resolver->axfr('net-dns.org');
	ok( scalar(@zone), '$resolver->axfr() returns entire zone in list context' );

	my @notauth = $resolver->axfr('bogus.net-dns.org');
	my $notauth = $resolver->errorstring;
	ok( !scalar(@notauth), "mismatched zone\t[$notauth]" );

	my $iterator = $resolver->axfr('net-dns.org');
	ok( ref($iterator), '$resolver->axfr() returns iterator in scalar context' );
	skip( 'AXFR iterator tests', 4 ) unless $iterator;

	my $soa = $iterator->();
	is( ref($soa), 'Net::DNS::RR::SOA', '$iterator->() returns initial SOA RR' );

	my $iterations;
	$soa->serial(undef) if $soa;				# force SOA mismatch
	exception( 'mismatched SOA serial', sub { $iterations++ while $iterator->() } );

	ok( $iterations, '$iterator->() iterates through remaining RRs' );
	is( $iterator->(), undef, '$iterator->() returns undef after last RR' );
}


SKIP: {
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->domain('net-dns.org');
	eval { $resolver->tsig($tsig_key) };
	skip( 'TSIG AXFR tests', 4 ) if $@;
	$resolver->tcp_timeout(10);

	my @zone = $resolver->axfr();
	ok( scalar(@zone), '$resolver->axfr() with TSIG verify' );

	my @notauth = $resolver->axfr('bogus.net-dns.org');
	my $notauth = $resolver->errorstring;
	ok( !scalar(@notauth), "mismatched zone\t[$notauth]" );

	eval { $resolver->tsig($bad_key) };
	skip( 'AXFR failure reporting', 2 ) if $@;
	my @unverifiable = $resolver->axfr();
	my $errorstring	 = $resolver->errorstring;
	ok( !scalar(@unverifiable), "mismatched key\t[$errorstring]" );
}


SKIP: {
	my $resolver = Net::DNS::Resolver->new( nameservers => $NOIP );
	eval { $resolver->tsig($tsig_key) };
	skip( 'TSIG bgsend tests', 2 ) if $@;

	my $query = Net::DNS::Packet->new(qw(. SOA IN));
	ok( $resolver->bgsend($query), '$resolver->bgsend() + automatic TSIG' );
	delete $query->{id};
	ok( $resolver->bgsend($query), '$resolver->bgsend() + existing TSIG' );
}


{
	my $resolver = Net::DNS::Resolver->new();
	$resolver->nameserver('cname.t.net-dns.org');
	ok( scalar( $resolver->nameservers ), 'resolve nameserver cname' );
}


{					## exercise error paths in _axfr_next()
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->tcp_timeout(10);
	exception( 'TCP time out', sub { $resolver->_axfr_next( IO::Select->new ) } );

	my $packet = Net::DNS::Packet->new(qw(net-dns.org SOA));
	my $socket = $resolver->_bgsend_tcp( $packet, $packet->encode );
	my $select = IO::Select->new($socket);
	while ( $resolver->bgbusy($socket) ) { sleep 1 }
	my $discarded = '';		## [size][id][status]	[qdcount]...
	$socket->recv( $discarded, 6 ) if $socket;
	exception( 'corrupt data', sub { $resolver->_axfr_next($select) } );
}


SKIP: {
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP );
	$resolver->domain('net-dns.org');
	eval { $resolver->tsig($tsig_key) };
	$resolver->tcp_timeout(10);

	my $packet = $resolver->_make_query_packet(qw(net-dns.org SOA));
	my $socket = $resolver->_bgsend_tcp( $packet, $packet->encode );
	my $tsigrr = $packet->sigrr;
	skip( 'verify fail', 1 ) unless $tsigrr;

	my $select = IO::Select->new($socket);
	exception( 'verify fail', sub { $resolver->_axfr_next( $select, $tsigrr ) } );
}


{					## exercise error paths in _send_udp et al
	my $resolver = Net::DNS::Resolver->new( nameservers => $IP, retry => 1 );
	my $original = Net::DNS::Packet->new(qw(net-dns.org SOA));
	my $mismatch = Net::DNS::Packet->new(qw(net-dns.org SOA));
	$original->encode;
	ok( !$resolver->_send_tcp( $original, $mismatch->encode ), '_send_tcp()	id mismatch' );
	ok( !$resolver->_send_udp( $original, $mismatch->encode ), '_send_udp()	id mismatch' );
	my $handle = $resolver->_bgsend_udp( $original, $mismatch->encode );
	$resolver->udp_timeout(1);
	ok( !$resolver->bgread($handle),	     'bgread()	id mismatch' );
	ok( !$resolver->bgread( ref($handle)->new ), 'bgread()	timeout' );
}


NonFatalEnd();

exit;

__END__


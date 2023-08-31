#!/usr/bin/perl
# $Id: 01-resolver.t 1934 2023-08-25 12:14:08Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 35;
use TestToolkit;

use Net::DNS::Resolver;
use Net::DNS::Resolver::Recurse;

{					## off-line dry tests

	package Net::DNS::Resolver;
	sub _create_tcp_socket {return}	## stub
	sub _create_udp_socket {return}	## stub
}


my @NOIP = qw(:: 0.0.0.0);

my $resolver = Net::DNS::Resolver->new( retrans => 0, retry => 0 );

$resolver->nameservers(@NOIP);

my $recursive = Net::DNS::Resolver::Recurse->new( retrans => 0, retry => 0 );


foreach (@NOIP) {			## exercise IPv4/IPv6 LocalAddr selection
	Net::DNS::Resolver::Base::_create_tcp_socket( $resolver, $_ );
	Net::DNS::Resolver::Base::_create_udp_socket( $resolver, $_ );
}


$resolver->defnames(0);			## exercise query()
ok( !$resolver->query(''), '$resolver->query() without defnames' );

$resolver->defnames(1);
ok( !$resolver->query(''), '$resolver->query() with defnames' );


$resolver->dnsrch(0);			## exercise search()
ok( !$resolver->search('name'), '$resolver->search() without dnsrch' );

$resolver->dnsrch(1);
$resolver->ndots(1);
$resolver->searchlist(qw(a.example. b.example.));
ok( !$resolver->search('name'),		'$resolver->search() simple name' );
ok( !$resolver->search('name.domain'),	'$resolver->search() dotted name' );
ok( !$resolver->search('name.domain.'), '$resolver->search() absolute name' );
ok( !$resolver->search(''),		'$resolver->search() root label' );


my $query = Net::DNS::Packet->new('.');	## exercise _accept_reply()
my $reply = Net::DNS::Packet->new('.');
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
ok( !$resolver->send('.'),   '$resolver->send	TCP socket error' );
ok( !$resolver->bgsend('.'), '$resolver->bgsend TCP socket error' );
ok( !$resolver->axfr('.'),   '$resolver->axfr	TCP socket error' );


$recursive->hints(@NOIP);
ok( !$recursive->send( 'www.net-dns.org', 'A' ), 'fail if no usable hint' );

$recursive->nameservers(@NOIP);
ok( !$recursive->send( 'www.net-dns.org', 'A' ), 'fail if no reachable server' );


is( $resolver->DESTROY, undef, 'DESTROY() exists to placate pre-5.18 AUTOLOAD' );
exception( 'AUTOLOAD: unrecognised method', sub { $resolver->unknown() } );

exception( 'new( config_file => ... )', sub { Net::DNS::Resolver->new( config_file => 'nonexist.txt' ) } );

exception( 'unresolved nameserver warning',   sub { $resolver->nameserver('bogus.example.com.') } );
exception( 'unspecified axfr() zone name',    sub { $resolver->axfr(undef) } );
exception( 'deprecated axfr_start() method',  sub { $resolver->axfr_start('net-dns.org') } );
exception( 'deprecated axfr_next() method',   sub { $resolver->axfr_next() } );
exception( 'deprecated query_dorecursion()',  sub { $recursive->query_dorecursion( 'www.net-dns.org', 'A' ) } );
exception( 'deprecated recursion_callback()', sub { $recursive->recursion_callback(undef) } );
exception( 'deprecated bgisready() method',   sub { $resolver->bgisready(undef) } );

my $deprecated = sub { $resolver->make_query_packet('example.com') };
exception( 'deprecated make_query_packet()', $deprecated );
noexception( 'no repeated deprecation warning', $deprecated );


SKIP: {
	skip( 'Unable to emulate SpamAssassin socket usage', 1 ) if $^O eq 'MSWin32';
	my $handle = \*DATA;		## exercise SpamAssassin's use of plain sockets
	ok( !$resolver->bgbusy($handle), 'bgbusy():	SpamAssassin workaround' );
}

exit;

__DATA__
arbitrary


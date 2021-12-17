#!/usr/bin/perl
# $Id: 01-resolver.t 1847 2021-08-11 10:02:44Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 29;

use Net::DNS::Resolver;
use Net::DNS::Resolver::Recurse;


my @NOIP = qw(:: 0.0.0.0);

my $resolver = Net::DNS::Resolver->new( retrans => 0, retry => 0 );

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
ok( !$resolver->send('.'),	  '$resolver->send   TCP socket error' );
ok( !$resolver->bgsend('.'),	  '$resolver->bgsend TCP socket error' );
ok( !scalar( $resolver->axfr() ), '$resolver->axfr   TCP socket error' );


$recursive->hints(@NOIP);
ok( !$recursive->send( 'www.net-dns.org', 'A' ), 'fail if no usable hint' );

$recursive->nameservers(@NOIP);
ok( !$recursive->send( 'www.net-dns.org', 'A' ), 'fail if no reachable server' );


sub warning {
	my ( $test, $method ) = @_;
	local $SIG{__WARN__} = sub { die @_ };
	eval {&$method};
	my ($warning) = split /\n/, "$@\n";
	ok( $warning, "$test\t[$warning]" );
	eval {&$method};
}

warning( 'unresolved nameserver warning', sub { $resolver->nameserver('bogus.example.com.') } );

warning( 'deprecated bgisready() method', sub { $resolver->bgisready(undef) } );

warning( 'deprecated axfr_start() method', sub { $resolver->axfr_start('net-dns.org') } );

warning('deprecated axfr_next() method',
	sub {
		$resolver->{axfr_iter} = sub { };
		$resolver->axfr_next();
	} );

warning( 'deprecated query_dorecursion()', sub { $recursive->query_dorecursion( 'www.net-dns.org', 'A' ) } );

warning('deprecated recursion_callback()',
	sub {
		$recursive->recursion_callback( sub { } );
	} );

warning( 'deprecated make_query_packet()', sub { $resolver->make_query_packet('example.com') } );

exit;


package Net::DNS::Resolver;		## off-line dry test
sub _create_tcp_socket {return}		## stub
sub _create_udp_socket {return}		## stub


__END__


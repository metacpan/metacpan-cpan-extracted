#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 3;

use Net::DNS;
use Net::DNS::Resolver::Unbound;


my $resolver = Net::DNS::Resolver::Unbound->new(
	defnames    => 1,
	dnsrch	    => 1,
	debug_level => 0
	);


ok( $resolver->send('ns.net-dns.org.'), '$resolver->send(ns.net-dns.org.)' );


$resolver->domain('net-dns.org');
ok( $resolver->query('ns'), '$resolver->query(ns)' );


$resolver->searchlist( 'nxd.net-dns.org', 'net-dns.org' );
ok( $resolver->search('ns'), '$resolver->search(ns)' );


exit;


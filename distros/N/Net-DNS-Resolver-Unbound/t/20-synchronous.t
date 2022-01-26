#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 7;

use Net::DNS::Resolver::Unbound;


my $resolver = Net::DNS::Resolver::Unbound->new(
	defnames    => 1,
	dnsrch	    => 1,
	searchlist  => ['net-dns.org', 'nxd.net-dns.org'],
	debug_level => 0
	);

ok( $resolver, 'create new resolver instance' );


ok( $resolver->send('ns.net-dns.org.'), '$resolver->send(ns.net-dns.org.)' );
is( $resolver->errorstring, '', 'empty $resolver->errorstring' );

ok( $resolver->query('ns'), '$resolver->query(ns)' );
is( $resolver->errorstring, '', 'empty $resolver->errorstring' );

ok( $resolver->search('ns'), '$resolver->search(ns)' );
is( $resolver->errorstring, '', 'empty $resolver->errorstring' );


exit;


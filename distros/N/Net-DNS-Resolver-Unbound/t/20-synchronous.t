#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More;

use Net::DNS::Resolver::Unbound;

my $resolver = Net::DNS::Resolver::Unbound->new(
	defnames    => 1,
	dnsrch	    => 1,
	debug_level => 0
	);

plan skip_all => 'no local nameserver' unless $resolver->nameservers;
plan tests    => 4;

my ( $name, $domain ) = qw(ns net-dns.org);

ok( $resolver->send("$name.$domain"), "resolver->send('$name.$domain')" );


$resolver->domain($domain);
ok( $resolver->query($name), "resolver->query('$name')" );


$resolver->searchlist( "nxd.$domain", $domain );
ok( $resolver->search($name), "resolver->search('$name')" );


my $packet = Net::DNS::Packet->new("$name.$domain");
ok( $resolver->send($packet), 'resolver->search( $packet )' );


exit;


#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More;

use Net::DNS::Resolver::Unbound;

my $resolver = Net::DNS::Resolver::Unbound->new( debug_level => 0 );

plan skip_all => 'no local nameserver' unless $resolver->nameservers;
plan tests    => 5;


my $fqdn = 'ns.net-dns.org.';

for ( my $handle = $resolver->bgsend($fqdn) ) {
	ok( $handle, "resolver->bgsend('$fqdn')" );

	sleep 1 if $resolver->bgbusy($handle);

	ok( !$handle->err,		'handle->err empty' );
	ok( $resolver->bgread($handle), 'reselver->bgread(handle)' );
}


my $packet = Net::DNS::Packet->new($fqdn);
for ( my $handle = $resolver->bgsend($packet) ) {
	my $reply = $resolver->bgread($handle);
	ok( $handle, "resolver->bgsend(packet)" );
	ok( $reply,  'reselver->bgread(handle)' );
}


exit;


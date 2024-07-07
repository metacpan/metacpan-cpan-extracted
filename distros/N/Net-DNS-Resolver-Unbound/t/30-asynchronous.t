#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More;

use Net::DNS::Resolver::Unbound;

my $resolver = Net::DNS::Resolver::Unbound->new( debug_level => 0 );

plan skip_all => 'no local nameserver' unless $resolver->nameserver;
plan tests    => 7;


my $fqdn = 'www.net-dns.org.';

for ( my $handle = $resolver->bgsend($fqdn) ) {
	ok( $handle, "resolver->bgsend('$fqdn')" );
	my $reply = $resolver->bgread($handle);
	ok( $reply,	   'resolver->bgread(handle)' );
	ok( !$handle->err, 'handle->err empty' );
}


my $packet = $resolver->_make_query_packet($fqdn);
for ( my $handle = $resolver->bgsend($packet) ) {
	ok( $handle, "resolver->bgsend(packet)" );
	my $reply = $resolver->bgread($handle);
	ok( $reply,	   'resolver->bgread(handle)' );
	ok( !$handle->err, 'handle->err empty' );
	is( $reply->header->id, $packet->header->id, 'reply ID matches query packet' );
}


exit;


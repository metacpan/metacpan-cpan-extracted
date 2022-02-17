#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More;

use Net::DNS;
use Net::DNS::Resolver::Unbound;

my $resolver = Net::DNS::Resolver::Unbound->new( debug_level => 0 );

plan skip_all => 'no local nameserver' unless $resolver->nameservers;
plan tests    => 2;


my $handle = $resolver->bgsend('ns.net-dns.org.');
ok( $handle, '$resolver->bgsend(ns.net-dns.org.)' );

sleep 1 if $resolver->bgbusy($handle);

my $reply = $resolver->bgread($handle);
ok( $reply, '$reselver->bgread($handle)' );


exit;


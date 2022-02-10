#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 2;

use Net::DNS;
use Net::DNS::Resolver::Unbound;


my $resolver = Net::DNS::Resolver::Unbound->new( debug_level => 0 );

my $handle = $resolver->bgsend('ns.net-dns.org.');
ok( $handle, '$resolver->bgsend(ns.net-dns.org.)' );

sleep 1 if $resolver->bgbusy($handle);

my $reply = $resolver->bgread($handle);
ok( $reply, '$reselver->bgread($handle)' );


exit;


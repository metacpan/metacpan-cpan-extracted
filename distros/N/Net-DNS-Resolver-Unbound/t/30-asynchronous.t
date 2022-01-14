#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 3;

use Net::DNS::Resolver::Unbound;

BEGIN {
	local @INC = ( @INC, qw(t) );
	require NonFatal;
}

NonFatalBegin();


my $resolver = Net::DNS::Resolver::Unbound->new( debug_level => 0 );
ok( $resolver, 'create new resolver instance' );


my $handle = $resolver->bgsend('ns.net-dns.org.');
ok( $handle, '$resolver->bgsend(ns.net-dns.org.)' );

sleep 1 if $resolver->bgbusy($handle);

my $reply = $resolver->bgread($handle);
ok( $reply, '$reselver->bgread($handle)' );


NonFatalEnd();

exit;


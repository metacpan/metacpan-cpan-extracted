#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 6;

use Net::DNS;
use Net::DNS::Resolver::Unbound;


my $resolver = Net::DNS::Resolver::Unbound->new();


sub handle_state {
	my ( $async_id, $err, @result ) = @_;
	my $handle;
	$handle = Net::DNS::Resolver::libunbound::emulate_wait($async_id)	   if defined $async_id;
	$handle = Net::DNS::Resolver::libunbound::emulate_error( $async_id, $err ) if defined $err;

	$resolver->bgbusy($handle);
	return $resolver->bgread($handle);
}


is( handle_state(), undef, 'handle undefined' );

is( handle_state(1), undef, 'awaiting callback' );

is( handle_state( 1, 0 ),     undef, 'NULL result' );
is( $resolver->errorstring(), undef, 'errorstring undefined' );

is( handle_state( 1, -99 ),   undef,	       'callback error' );
is( $resolver->errorstring(), 'unknown error', 'unknown error' );


exit;

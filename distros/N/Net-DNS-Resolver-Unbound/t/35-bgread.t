#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 15;

use Net::DNS;
use Net::DNS::Resolver::Unbound;

my $resolver = Net::DNS::Resolver::Unbound->new();


for ( my $handle = undef ) {
	ok( !$resolver->bgbusy($handle), 'not bgbusy' );
	is( $resolver->bgread($handle), undef, 'undefined bgread' );
}


for ( my $handle = Net::DNS::Resolver::libunbound::emulate_wait(123) ) {
	ok( $handle->waiting(),		'handle->waiting' );
	ok( $resolver->bgbusy($handle), 'bgbusy' );
	is( $resolver->bgread($handle), undef, 'undefined bgread' );
	is( $handle->async_id(),	123,   'handle->async_id' );
	is( $handle->result(),		undef, 'no handle->result' );
	ok( !$handle->err(), 'no handle->err' );
}


for ( my $handle = Net::DNS::Resolver::libunbound::emulate_callback( 123, -99 ) ) {
	ok( !$handle->waiting(),	 'not handle->waiting' );
	ok( !$resolver->bgbusy($handle), 'not bgbusy' );
	is( $resolver->bgread($handle), undef, 'undefined bgread' );
	is( $handle->async_id(),	123,   'handle->async_id' );
	is( $handle->result(),		undef, 'no handle->result' );
	ok( $handle->err(), 'handle->err' );
	like( $resolver->errorstring(), '/-99/', 'unknown error' );
}


exit;

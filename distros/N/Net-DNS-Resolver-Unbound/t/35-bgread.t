#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 13;

use Net::DNS;
use Net::DNS::Resolver::Unbound;

my $resolver = Net::DNS::Resolver::Unbound->new();


for ( my $handle = undef ) {
	ok( !$resolver->bgbusy($handle), 'not bgbusy' );
	is( $resolver->bgread($handle), undef, 'undefined bgread' );
}


for ( my $handle = Net::DNS::Resolver::libunbound::emulate_wait(123) ) {
	is( $handle->async_id(), 123,	'handle->async_id' );
	is( $handle->err(),	 0,	'no handle->err' );
	is( $handle->result(),	 undef, 'no handle->result' );
	ok( $resolver->bgbusy($handle), 'bgbusy' );
	is( $resolver->bgread($handle), undef, 'undefined bgread' );
}


for ( my $handle = Net::DNS::Resolver::libunbound::emulate_error( 123, -99 ) ) {
	is( $handle->async_id(), 123,	'handle->async_id' );
	is( $handle->err(),	 -99,	'handle->err' );
	is( $handle->result(),	 undef, 'no handle->result' );
	ok( !$resolver->bgbusy($handle), 'not bgbusy' );
	is( $resolver->bgread($handle), undef,		 'undefined bgread' );
	is( $resolver->errorstring(),	'unknown error', 'unknown error' );
}


exit;

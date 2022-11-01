#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More;

use Net::DNS::Resolver::Unbound;

plan tests => 14;


my $resolver = Net::DNS::Resolver::Unbound->new();

for ( my $handle = undef ) {
	ok( !$resolver->bgbusy($handle), 'not bgbusy' );
	is( $resolver->bgread($handle), undef, 'undefined bgread' );
}

my $id	= 123;
my $err = -99;

for ( my $handle = Net::DNS::Resolver::libunbound::emulate_wait($id) ) {
	ok( $handle->waiting(),		'handle->waiting' );
	ok( $resolver->bgbusy($handle), 'bgbusy' );
	ok( !$handle->err(),		'no handle->err' );
	is( $handle->query_id(), $id,	'handle->query_id' );
	is( $handle->result(),	 undef, 'no handle->result' );
}


for ( my $handle = Net::DNS::Resolver::libunbound::emulate_callback( $id, $err ) ) {
	ok( !$handle->waiting(),	 'not handle->waiting' );
	ok( !$resolver->bgbusy($handle), 'not bgbusy' );
	ok( $handle->err(),		 'handle->err' );
	is( $handle->query_id(),	$id,   'handle->query_id' );
	is( $handle->result(),		undef, 'no handle->result' );
	is( $resolver->bgread($handle), undef, 'undefined bgread' );
	like( $resolver->errorstring(), "/$err/", 'unknown error' );
}


exit;

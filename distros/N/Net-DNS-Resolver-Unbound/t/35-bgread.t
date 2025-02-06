#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More;

use Net::DNS::Resolver::Unbound;

my $resolver = Net::DNS::Resolver::Unbound->new();

plan skip_all => 'resolver not loaded' unless $resolver;
plan tests    => 12;


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
	ok( !$handle->result(),		'no handle->result' );
}


for ( my $handle = Net::DNS::Resolver::libunbound::emulate_callback( $id, $err ) ) {
	ok( !$handle->waiting(),	 'not handle->waiting' );
	ok( !$resolver->bgbusy($handle), 'not bgbusy' );
	ok( $handle->err(),		 'handle->err' );
	ok( !$handle->result(),		 'no handle->result' );
	is( $resolver->bgread($handle), undef, 'undefined bgread' );
	my $errorstring = $resolver->errorstring;
	like( $errorstring, "/$err/", "errorstring: [$errorstring]" );
}


exit;

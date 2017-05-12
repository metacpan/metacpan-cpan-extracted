#
#
use strict;
use warnings;
use lib 'inc';
use Test::More;
use Test::HTTP::Server;
BEGIN {
	eval 'use EV';
	plan skip_all => "EV is required for this test" if $@;
}
use Net::Curl::Simple;
use Net::Curl::Simple::Async qw(EV);

my $server = Test::HTTP::Server->new;
plan skip_all => "Could not run http server\n" unless $server;
plan tests => 18;

alarm 5;

my $got = 0;
Net::Curl::Simple->new->get( $server->uri, sub {
	my $curl = shift;
	$got = 1;

	ok( defined $curl->code, 'finish callback called' );
	cmp_ok( $curl->code, '==', 0, 'downloaded successfully' );
	ok( ! $curl->{in_use}, 'handle released' );
	is( ref $curl->{headers}, 'ARRAY', 'got array of headers' );
	is( ref $curl->{body}, '', 'got body scalar' );
	cmp_ok( scalar $curl->headers, '>', 3, 'got at least 3 headers' );
	cmp_ok( length $curl->content, '==', 26, 'got some body' );
	isnt( $curl->{referer}, '', 'referer updarted' );

	$curl->get( '/repeat', \&finish2 );
} );

sub finish2
{
	my $curl = shift;
	$got = 2;

	ok( defined $curl->code, 'finish callback called' );
	cmp_ok( $curl->code, '==', 0, 'downloaded successfully' );
	ok( ! $curl->{in_use}, 'handle released' );
	is( ref $curl->{headers}, 'ARRAY', 'got array of headers' );
	is( ref $curl->{body}, '', 'got body scalar' );
	cmp_ok( scalar $curl->headers, '>', 3, 'got at least 3 headers' );
	cmp_ok( length $curl->content, '>', 1000, 'got some body' );
	isnt( $curl->{referer}, '', 'referer updarted' );
}

is( $got, 0, 'request did not block' );

1 while Net::Curl::Simple->join;

is( $got, 2, 'performed both requests' );

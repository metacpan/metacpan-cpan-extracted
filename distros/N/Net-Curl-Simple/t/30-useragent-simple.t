#
#
use strict;
use warnings;
use lib 'inc';
use Test::More;
use Test::HTTP::Server;
use Net::Curl::Simple::UserAgent;

my $server = Test::HTTP::Server->new;
plan skip_all => "Could not run http server\n" unless $server;
plan tests => 18;

alarm 5;

my $ua = Net::Curl::Simple::UserAgent->new();
my $got = 0;
my $curl = $ua->curl;
$curl->get( $server->uri, sub {
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
} );

$curl->join;

is( $got, 1, 'request did block' );

$ua->curl->get( $server->uri . 'repeat', \&finish2 );
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

Net::Curl::Simple->join;

is( $got, 2, 'performed both requests' );

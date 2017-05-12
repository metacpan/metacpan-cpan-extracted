#
#
use strict;
use warnings;
use lib 'inc';
use Test::More;
use Test::HTTP::Server;
use Net::Curl::Simple;

my $server = Test::HTTP::Server->new;
plan skip_all => "Could not run http server\n" unless $server;
plan tests => 16;

alarm 5;

my $curl = Net::Curl::Simple->new();
$curl->get( $server->uri . "repeat" );

ok( defined $curl->code, 'finish callback called' );
cmp_ok( $curl->code, '==', 0, 'downloaded successfully' );
ok( ! $curl->{in_use}, 'handle released' );
is( ref $curl->{headers}, 'ARRAY', 'got array of headers' );
is( ref $curl->{body}, '', 'got body scalar' );
cmp_ok( scalar $curl->headers, '>', 3, 'got at least 3 headers' );
cmp_ok( length $curl->content, '>', 1000, 'got some body' );
isnt( $curl->{referer}, '', 'referer updarted' );

$curl->{code} = undef;
$curl->get( '/repeat/1000' );

ok( defined $curl->code, 'finish callback called' );
cmp_ok( $curl->code, '==', 0, 'downloaded successfully' );
ok( ! $curl->{in_use}, 'handle released' );
is( ref $curl->{headers}, 'ARRAY', 'got array of headers' );
is( ref $curl->{body}, '', 'got body scalar' );
cmp_ok( scalar $curl->headers, '>', 3, 'got at least 3 headers' );
cmp_ok( length $curl->content, '==', 1000, 'got some body' );
isnt( $curl->{referer}, '', 'referer updarted' );


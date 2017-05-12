use strict;
use warnings;
use lib 't';

use Mojolicious::Lite;
use Test::Mojo;

use Mojolicious::Plugin::DigestAuth::Util 'parse_header';
use Test::More tests => 13;
use TestHelper;

my $url = '/';
get $url => create_action(expires => 1);

my $t = Test::Mojo->new;     
$t->get_ok($url)
  ->status_is(401);

my $headers = build_auth_request($t->tx);
$t->get_ok($url, $headers)
  ->status_is(200);

# Let nonce expire 
sleep(2);

$t->get_ok($url, $headers)
  ->status_is(401)
  ->header_like('WWW-Authenticate', qr/stale=true/);

# Authenticate with new nonce
$headers = parse_header($t->tx->res->headers->www_authenticate);   
$t->get_ok($url, build_auth_request($t->tx, %$headers))
 ->status_is(200);
 
# Try with a bad nonce
my $good_nonce = $headers->{nonce};
$headers->{nonce} = '-> __bad_nonce__';
$t->get_ok($url, build_auth_request($t->tx, %$headers))
  ->status_is(401);

# Try again with the good one
$headers->{nonce} = $good_nonce;
$t->get_ok($url, build_auth_request($t->tx, %$headers))
  ->status_is(200);

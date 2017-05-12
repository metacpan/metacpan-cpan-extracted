#!/usr/bin/env perl
# Check creation of request and decoding response
use warnings;
use strict;

use lib 'lib', '../lib';
use Test::More tests => 16;
use Data::Dumper;

use Net::OAuth2::Profile::WebServer;

my $id     = 'my-id';
my $secret = 'my-secret';
my $base   = 'http://my-site/a/b';
my $ct_urlenc = 'application/x-www-form-urlencoded';
my $ct_json   = 'application/json';

use_ok('Net::OAuth2::Profile::WebServer');
my $auth = Net::OAuth2::Profile::WebServer->new
  ( client_id     => $id
  , client_secret => $secret
  );

isa_ok($auth, 'Net::OAuth2::Profile::WebServer');

### BUILD REQUEST

my @params = (c => 1, d => 2);
my $req1 = $auth->build_request(GET => $base, \@params);
isa_ok($req1, 'HTTP::Request', 'created request GET @params');
like($req1->uri->as_string, qr!^http://my-site/a/b\?(?:c\=1\&d\=2|d\=2\&c\=1)!);

my $req2 = $auth->build_request(GET => $base, {@params});  #params random order
isa_ok($req2, 'HTTP::Request', 'created request GET %params');
my $uri2 = $req2->uri;
my %p2   = $uri2->query_form;
cmp_ok(scalar keys %p2, '==', 2);
is($p2{c}, 1);
is($p2{d}, 2);

my $req3 = $auth->build_request(POST => $base, \@params);
isa_ok($req3, 'HTTP::Request', 'created request POST @params');
is($req3->uri->as_string, 'http://my-site/a/b');
ok($req3->content eq 'c=1&d=2' || $req3->content eq 'd=2&c=1', 'content');
is($req3->content_type, $ct_urlenc, 'content-type');

### DECODE RESPONSE

my $resp1 = HTTP::Response->new
  ( 200, 'OK'
  , [ Content_Type => $ct_urlenc ]
  , 'e=3&f=4'
  );

my $r1 = join ';', $auth->params_from_response($resp1, 'test1');
is($r1, 'e;3;f;4', 'response 1, url-enc');

my $resp2 = HTTP::Response->new
  ( 200, 'OK'
  , [ Content_Type => $ct_json ]
  , '{ "g": 5, "h": 6 }'
  );

my %r2 = $auth->params_from_response($resp2, 'test2');
cmp_ok(scalar keys %r2, '==', 2, 'response 2, json');
is($r2{g}, 5);
is($r2{h}, 6);

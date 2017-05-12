#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
  plan( tests=>4 );
  use_ok 'Net::HTTPS::Any', 'https_post';
};

#200
my($content, $response, %headers) = https_post(
  { 'host' => 'accounts.google.com',
    'port' => 443,
    'path' => '/ServiceLogin',
    'args' => { 'posted' => 'data' },
  },
  'net_https_any_test' => 1,
);

#like($response, qr/^HTTP\/[\d\.]+\s+200/i, 'Received 200 (OK) response');
like($response, qr/^200/i, 'Received 200 (OK) response');

ok( length($content), 'Received content' );

#404

my($content2, $response2, %headers2) = https_post(
  { 'host' => 'www.google.com',
    'port' => 443,
    'path' => '/notfound.html',
    'args' => { 'length' => 'required' },
  },
  'net_https_any_test' => 1,
);

#like($response2, qr/^HTTP\/[\d\.]+\s+404/i, 'Received 404 (Not Found) response');
like($response2, qr/^404/i, 'Received 404 (Not Found) response');

